import json
import os
import sqlite3
import threading
import time
import uuid
from datetime import datetime, timezone

from flask import Flask, jsonify, request
import paho.mqtt.client as mqtt

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")
ALLOWED_ACTIONS = {
    "update_full",
    "update_os",
    "update_repo",
    "run_install",
    "restart_services",
    "reboot",
}
ALLOWED_WHEN = {"immediate", "nightly"}


def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def utc_now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def db_connect(db_path):
    conn = sqlite3.connect(db_path, timeout=5)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    return conn


def init_db(db_path):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = db_connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS kiosks (
            kiosk_id TEXT PRIMARY KEY,
            location TEXT,
            last_seen TEXT,
            ip TEXT,
            os_version TEXT,
            git_sha TEXT,
            services_json TEXT,
            last_update_json TEXT
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS commands (
            cmd_id TEXT PRIMARY KEY,
            kiosk_id TEXT,
            action TEXT,
            when_mode TEXT,
            args_json TEXT,
            status TEXT,
            started_at TEXT,
            finished_at TEXT,
            output TEXT
        )
        """
    )
    conn.commit()
    conn.close()


def upsert_kiosk(db_path, payload):
    conn = db_connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO kiosks (kiosk_id, location, last_seen, ip, os_version, git_sha, services_json, last_update_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(kiosk_id) DO UPDATE SET
            location=excluded.location,
            last_seen=excluded.last_seen,
            ip=excluded.ip,
            os_version=excluded.os_version,
            git_sha=excluded.git_sha,
            services_json=excluded.services_json,
            last_update_json=excluded.last_update_json
        """,
        (
            payload.get("kiosk_id"),
            payload.get("location"),
            payload.get("last_seen"),
            payload.get("ip"),
            payload.get("os_version"),
            payload.get("git_sha"),
            json.dumps(payload.get("services", {})),
            json.dumps(payload.get("last_update", {})),
        ),
    )
    conn.commit()
    conn.close()


def insert_command(db_path, cmd_id, kiosk_id, action, when_mode, args):
    conn = db_connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO commands (cmd_id, kiosk_id, action, when_mode, args_json, status, started_at, finished_at, output)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (cmd_id, kiosk_id, action, when_mode, json.dumps(args or {}), "queued", None, None, None),
    )
    conn.commit()
    conn.close()


def update_command_result(db_path, payload):
    conn = db_connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        UPDATE commands
        SET status=?, started_at=?, finished_at=?, output=?
        WHERE cmd_id=?
        """,
        (
            payload.get("status"),
            payload.get("started_at"),
            payload.get("finished_at"),
            payload.get("output"),
            payload.get("cmd_id"),
        ),
    )
    conn.commit()
    conn.close()


def make_mqtt_client(cfg, db_path):
    def on_connect(client, userdata, flags, rc, _properties=None):
        if rc == 0:
            client.subscribe("kiosk/+/status")
            client.subscribe("kiosk/+/reply")
        else:
            print(f"MQTT connect failed: {rc}")

    def on_message(client, userdata, msg):
        try:
            payload = json.loads(msg.payload.decode("utf-8"))
        except json.JSONDecodeError:
            return

        if msg.topic.endswith("/status"):
            if not payload.get("kiosk_id"):
                print("Ignoring heartbeat without kiosk_id")
                return
            if "last_seen" not in payload:
                payload["last_seen"] = utc_now_iso()
            upsert_kiosk(db_path, payload)
        elif msg.topic.endswith("/reply"):
            if not payload.get("cmd_id"):
                print("Ignoring reply without cmd_id")
                return
            update_command_result(db_path, payload)

    client = mqtt.Client()
    client.tls_set(
        ca_certs=cfg["mqtt"]["ca_cert"],
        certfile=cfg["mqtt"]["client_cert"],
        keyfile=cfg["mqtt"]["client_key"],
    )
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(cfg["mqtt"]["host"], cfg["mqtt"]["port"], 60)
    return client


def create_app():
    cfg = load_config()
    db_path = os.path.abspath(os.path.join(BASE_DIR, cfg["db_path"]))
    init_db(db_path)

    mqtt_client = make_mqtt_client(cfg, db_path)

    thread = threading.Thread(target=mqtt_client.loop_forever, daemon=True)
    thread.start()

    app = Flask(__name__)

    @app.get("/api/kiosks")
    def list_kiosks():
        conn = db_connect(db_path)
        cur = conn.cursor()
        cur.execute(
            "SELECT kiosk_id, location, last_seen, ip, os_version, git_sha FROM kiosks ORDER BY kiosk_id"
        )
        rows = cur.fetchall()
        conn.close()
        kiosks = [
            {
                "kiosk_id": r[0],
                "location": r[1],
                "last_seen": r[2],
                "ip": r[3],
                "os_version": r[4],
                "git_sha": r[5],
            }
            for r in rows
        ]
        return jsonify(kiosks)

    @app.get("/api/kiosks/<kiosk_id>/history")
    def kiosk_history(kiosk_id):
        conn = db_connect(db_path)
        cur = conn.cursor()
        cur.execute(
            """
            SELECT cmd_id, action, when_mode, status, started_at, finished_at, output
            FROM commands WHERE kiosk_id=? ORDER BY rowid DESC LIMIT 50
            """,
            (kiosk_id,),
        )
        rows = cur.fetchall()
        conn.close()
        history = [
            {
                "cmd_id": r[0],
                "action": r[1],
                "when": r[2],
                "status": r[3],
                "started_at": r[4],
                "finished_at": r[5],
                "output": r[6],
            }
            for r in rows
        ]
        return jsonify(history)

    @app.post("/api/command")
    def issue_command():
        data = request.get_json(silent=True)
        if data is None:
            return jsonify({"error": "invalid_json"}), 400
        if not isinstance(data, dict):
            return jsonify({"error": "invalid_json"}), 400
        kiosk_id = data.get("kiosk_id")
        action = data.get("action")
        when_mode = data.get("when", "immediate")
        args = data.get("args", {})
        if not kiosk_id or not action:
            return jsonify({"error": "kiosk_id and action are required"}), 400
        if not isinstance(args, dict):
            return jsonify({"error": "args must be an object"}), 400
        if action not in ALLOWED_ACTIONS:
            return jsonify({"error": "invalid_action"}), 400
        if when_mode not in ALLOWED_WHEN:
            return jsonify({"error": "invalid_when"}), 400
        if any(ch in kiosk_id for ch in ("/", "+", "#")):
            return jsonify({"error": "invalid_kiosk_id"}), 400

        cmd_id = str(uuid.uuid4())
        payload = {
            "cmd_id": cmd_id,
            "action": action,
            "when": when_mode,
            "args": args,
        }
        insert_command(db_path, cmd_id, kiosk_id, action, when_mode, args)
        info = mqtt_client.publish(
            f"kiosk/{kiosk_id}/cmd", json.dumps(payload), qos=1
        )
        if info.rc != mqtt.MQTT_ERR_SUCCESS:
            update_command_result(
                db_path,
                {
                    "cmd_id": cmd_id,
                    "status": "failed",
                    "started_at": utc_now_iso(),
                    "finished_at": utc_now_iso(),
                    "output": f"publish_failed_rc_{info.rc}",
                },
            )
            return jsonify({"error": "publish_failed", "cmd_id": cmd_id}), 502
        return jsonify({"cmd_id": cmd_id})

    return app, cfg


if __name__ == "__main__":
    app, cfg = create_app()
    app.run(host=cfg["http"]["host"], port=cfg["http"]["port"], debug=False)

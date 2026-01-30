#!/usr/bin/env python3
import argparse
import json
import logging
import os
import socket
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone

import paho.mqtt.client as mqtt


DEFAULT_CONFIG_PATH = "/etc/kiosk-agent/config.json"
DEFAULT_QUEUE_PATH = "/var/lib/kiosk-agent/queue.json"
DEFAULT_LOG_PATH = "/var/lib/kiosk-agent/agent.log"
DEFAULT_LAST_UPDATE_PATH = "/var/lib/kiosk-agent/last_update.json"
DEFAULT_RUN_LOCK_PATH = "/var/lib/kiosk-agent/run.lock"
ALLOWED_ACTIONS = {
    "update_full",
    "update_os",
    "update_repo",
    "run_install",
    "restart_services",
    "reboot",
}


def utc_now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default
    except json.JSONDecodeError:
        return default


def atomic_write_json(path, data):
    tmp_path = f"{path}.tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, path)


def ensure_parent_dir(path):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def setup_logging(log_path):
    ensure_parent_dir(log_path)
    logger = logging.getLogger("kiosk-agent")
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        "%(asctime)s %(levelname)s %(message)s", "%Y-%m-%dT%H:%M:%SZ"
    )
    formatter.converter = time.gmtime

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    file_handler = logging.FileHandler(log_path)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    return logger


def get_uptime_seconds():
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as f:
            return int(float(f.read().split()[0]))
    except Exception:
        return 0


def get_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "unknown"


def get_git_sha(repo_path):
    if not repo_path:
        return "unknown"
    try:
        result = subprocess.run(
            ["git", "-C", repo_path, "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip() or "unknown"
    except Exception:
        return "unknown"


def get_os_version():
    try:
        with open("/etc/os-release", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    return line.split("=", 1)[1].strip().strip('"')
    except Exception:
        pass
    return "unknown"


def get_disk_usage(path="/"):
    try:
        stat = os.statvfs(path)
        total = stat.f_frsize * stat.f_blocks
        free = stat.f_frsize * stat.f_bavail
        used = total - free
        return {"path": path, "total_bytes": total, "used_bytes": used, "free_bytes": free}
    except Exception:
        return {"path": path, "total_bytes": 0, "used_bytes": 0, "free_bytes": 0}


def get_mem_usage():
    total = 0
    available = 0
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    total = int(line.split()[1]) * 1024
                elif line.startswith("MemAvailable:"):
                    available = int(line.split()[1]) * 1024
        used = max(total - available, 0)
        return {"total_bytes": total, "used_bytes": used, "available_bytes": available}
    except Exception:
        return {"total_bytes": 0, "used_bytes": 0, "available_bytes": 0}


def get_load_avg():
    try:
        with open("/proc/loadavg", "r", encoding="utf-8") as f:
            parts = f.read().strip().split()
        return {"1m": float(parts[0]), "5m": float(parts[1]), "15m": float(parts[2])}
    except Exception:
        return {"1m": 0.0, "5m": 0.0, "15m": 0.0}


def get_block_device_for_path(path):
    try:
        st = os.stat(path)
        dev = st.st_dev
        major = os.major(dev)
        minor = os.minor(dev)
        return major, minor
    except Exception:
        return None, None


def get_disk_io(path="/"):
    major, minor = get_block_device_for_path(path)
    if major is None:
        return {"path": path, "reads": 0, "writes": 0, "read_bytes": 0, "write_bytes": 0}
    try:
        with open("/proc/diskstats", "r", encoding="utf-8") as f:
            for line in f:
                parts = line.split()
                if len(parts) < 14:
                    continue
                if int(parts[0]) == major and int(parts[1]) == minor:
                    reads = int(parts[3])
                    read_sectors = int(parts[5])
                    writes = int(parts[7])
                    write_sectors = int(parts[9])
                    # Linux reports 512-byte sectors in /proc/diskstats
                    return {
                        "path": path,
                        "reads": reads,
                        "writes": writes,
                        "read_bytes": read_sectors * 512,
                        "write_bytes": write_sectors * 512,
                    }
    except Exception:
        pass
    return {"path": path, "reads": 0, "writes": 0, "read_bytes": 0, "write_bytes": 0}


def get_service_status(services):
    status = {}
    for service in services:
        service = str(service)
        if not service:
            continue
        status_val = "unknown"
        try:
            result = subprocess.run(
                ["systemctl", "--user", "is-active", service],
                capture_output=True,
                text=True,
            )
            status_val = result.stdout.strip() or result.stderr.strip() or "unknown"
        except Exception:
            pass
        if status_val in ("unknown", ""):
            try:
                result = subprocess.run(
                    ["systemctl", "is-active", service],
                    capture_output=True,
                    text=True,
                )
                status_val = result.stdout.strip() or result.stderr.strip() or "unknown"
            except Exception:
                status_val = "unknown"
        status[service] = status_val
    return status


def acquire_lock(lock_path):
    import fcntl

    ensure_parent_dir(lock_path)
    lock_file = open(lock_path, "a+", encoding="utf-8")
    fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
    return lock_file


def load_queue(queue_path, lock_path):
    lock_file = acquire_lock(lock_path)
    try:
        queue = load_json(queue_path, [])
        if not isinstance(queue, list):
            queue = []
        return queue
    finally:
        lock_file.close()


def save_queue(queue_path, lock_path, queue):
    lock_file = acquire_lock(lock_path)
    try:
        ensure_parent_dir(queue_path)
        atomic_write_json(queue_path, queue)
    finally:
        lock_file.close()


def append_queue(queue_path, lock_path, item):
    lock_file = acquire_lock(lock_path)
    try:
        queue = load_json(queue_path, [])
        if not isinstance(queue, list):
            queue = []
        queue.append(item)
        ensure_parent_dir(queue_path)
        atomic_write_json(queue_path, queue)
    finally:
        lock_file.close()


def pop_all_queue(queue_path, lock_path):
    lock_file = acquire_lock(lock_path)
    try:
        queue = load_json(queue_path, [])
        if not isinstance(queue, list):
            queue = []
        ensure_parent_dir(queue_path)
        atomic_write_json(queue_path, [])
        return queue
    finally:
        lock_file.close()


def append_queue_list(queue_path, lock_path, items):
    if not items:
        return
    lock_file = acquire_lock(lock_path)
    try:
        queue = load_json(queue_path, [])
        if not isinstance(queue, list):
            queue = []
        queue.extend(items)
        ensure_parent_dir(queue_path)
        atomic_write_json(queue_path, queue)
    finally:
        lock_file.close()


def tail_text(text, max_bytes=4096):
    data = text.encode("utf-8", errors="ignore")
    if len(data) <= max_bytes:
        return text
    return data[-max_bytes:].decode("utf-8", errors="ignore")


def run_action(action, update_runner_path, timeout_sec, logger, env=None):
    started_at = utc_now_iso()
    try:
        result = subprocess.run(
            [update_runner_path, action],
            capture_output=True,
            text=True,
            timeout=timeout_sec,
            env=env,
        )
        output = (result.stdout or "") + (result.stderr or "")
        status = "success" if result.returncode == 0 else "failed"
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") + (exc.stderr or "")
        status = "failed"
    except FileNotFoundError as exc:
        output = f"update_runner_not_found: {exc}"
        status = "failed"
    except Exception as exc:
        output = f"update_runner_error: {exc}"
        status = "failed"
    finished_at = utc_now_iso()
    logger.info("Action %s finished with %s", action, status)
    return {
        "status": status,
        "started_at": started_at,
        "finished_at": finished_at,
        "output": tail_text(output),
    }


class KioskAgent:
    def __init__(self, config_path):
        self.config_path = config_path
        self.config = load_json(config_path, {})
        if not self.config:
            raise RuntimeError(f"Config not found or invalid: {config_path}")
        self.kiosk_id = self.config["kiosk_id"]
        self.location = self.config.get("location", "")
        self.topic_prefix = self.config.get("topic_prefix", "kiosk")
        self.queue_path = self.config.get("queue_path", DEFAULT_QUEUE_PATH)
        self.lock_path = f"{self.queue_path}.lock"
        self.log_path = self.config.get("log_path", DEFAULT_LOG_PATH)
        self.last_update_path = self.config.get(
            "last_update_path", DEFAULT_LAST_UPDATE_PATH
        )
        self.run_lock_path = self.config.get("run_lock_path", DEFAULT_RUN_LOCK_PATH)
        self.update_runner_path = self.config.get("update_runner_path")
        self.update_timeout_sec = int(self.config.get("update_timeout_sec", 1800))
        self.heartbeat_interval_sec = int(
            self.config.get("heartbeat_interval_sec", 45)
        )
        self.repo_path = self.config.get("repo_path", "")
        self.services = self.config.get("services", [])

        self.status_topic = f"{self.topic_prefix}/{self.kiosk_id}/status"
        self.cmd_topic = f"{self.topic_prefix}/{self.kiosk_id}/cmd"
        self.reply_topic = f"{self.topic_prefix}/{self.kiosk_id}/reply"

        self.logger = setup_logging(self.log_path)
        self.client = mqtt.Client(client_id=f"{self.kiosk_id}-agent")
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect
        self._connect_mqtt()

    def _connect_mqtt(self):
        tls_ca = self.config["tls_ca"]
        tls_cert = self.config["tls_cert"]
        tls_key = self.config["tls_key"]
        self.client.tls_set(
            ca_certs=tls_ca,
            certfile=tls_cert,
            keyfile=tls_key,
        )
        if self.config.get("tls_insecure", False):
            self.client.tls_insecure_set(True)
        host = self.config["broker_host"]
        port = int(self.config.get("broker_port", 8883))
        keepalive = int(self.config.get("mqtt_keepalive", 60))
        self.client.connect(host, port, keepalive=keepalive)

    def on_connect(self, client, userdata, flags, rc, properties=None):
        if rc == 0:
            self.logger.info("Connected to MQTT")
            client.subscribe(self.cmd_topic)
        else:
            self.logger.error("MQTT connection failed: %s", rc)

    def on_disconnect(self, client, userdata, rc, properties=None):
        self.logger.warning("Disconnected from MQTT: %s", rc)

    def on_message(self, client, userdata, msg):
        try:
            payload = json.loads(msg.payload.decode("utf-8"))
        except json.JSONDecodeError:
            self.logger.warning("Invalid JSON command payload")
            return
        if not all(key in payload for key in ("cmd_id", "action", "when", "args")):
            self.logger.warning("Missing required fields in command payload")
            return
        when = payload.get("when")
        if when == "immediate":
            threading.Thread(
                target=self.execute_command, args=(payload,), daemon=True
            ).start()
        elif when == "nightly":
            append_queue(self.queue_path, self.lock_path, payload)
            self.logger.info("Queued command %s", payload.get("cmd_id"))
        else:
            self.logger.warning("Unknown command schedule: %s", when)

    def build_heartbeat(self):
        last_update = load_json(self.last_update_path, {})
        payload = {
            "kiosk_id": self.kiosk_id,
            "location": self.location,
            "last_seen": utc_now_iso(),
            "uptime_sec": get_uptime_seconds(),
            "ip": get_ip(),
            "git_sha": get_git_sha(self.repo_path),
            "os_version": get_os_version(),
            "disk": get_disk_usage("/"),
            "disk_io": get_disk_io("/"),
            "memory": get_mem_usage(),
            "load_avg": get_load_avg(),
            "services": get_service_status(self.services),
            "last_update": last_update or {"status": "unknown", "ts": "unknown"},
        }
        return payload

    def publish_heartbeat(self):
        payload = self.build_heartbeat()
        self.client.publish(self.status_topic, json.dumps(payload), qos=1)

    def heartbeat_loop(self):
        while True:
            try:
                self.publish_heartbeat()
            except Exception as exc:
                self.logger.error("Heartbeat failed: %s", exc)
            time.sleep(self.heartbeat_interval_sec)

    def execute_command(self, payload):
        cmd_id = payload["cmd_id"]
        action = payload["action"]
        args = payload.get("args") or {}
        if args:
            self.logger.info("Ignoring args for cmd %s: %s", cmd_id, args)
        if action not in ALLOWED_ACTIONS:
            self.logger.error("Unknown action %s for cmd %s", action, cmd_id)
            reply = {
                "cmd_id": cmd_id,
                "status": "failed",
                "started_at": utc_now_iso(),
                "finished_at": utc_now_iso(),
                "output": f"Unknown action: {action}",
            }
            self.client.publish(self.reply_topic, json.dumps(reply), qos=1)
            return
        if not self.update_runner_path:
            self.logger.error("update_runner_path not configured")
            reply = {
                "cmd_id": cmd_id,
                "status": "failed",
                "started_at": utc_now_iso(),
                "finished_at": utc_now_iso(),
                "output": "update_runner_path not configured",
            }
            self.client.publish(self.reply_topic, json.dumps(reply), qos=1)
            return
        if not os.path.isfile(self.update_runner_path):
            self.logger.error("update_runner_path not found: %s", self.update_runner_path)
            reply = {
                "cmd_id": cmd_id,
                "status": "failed",
                "started_at": utc_now_iso(),
                "finished_at": utc_now_iso(),
                "output": f"update_runner_path not found: {self.update_runner_path}",
            }
            self.client.publish(self.reply_topic, json.dumps(reply), qos=1)
            return
        lock_file = acquire_lock(self.run_lock_path)
        try:
            env = os.environ.copy()
            if self.repo_path:
                env["KIOSK_REPO_PATH"] = self.repo_path
            result = run_action(
                action,
                self.update_runner_path,
                self.update_timeout_sec,
                self.logger,
                env=env,
            )
            reply = {
                "cmd_id": cmd_id,
                "status": result["status"],
                "started_at": result["started_at"],
                "finished_at": result["finished_at"],
                "output": result["output"],
            }
            atomic_write_json(
                self.last_update_path,
                {"status": result["status"], "ts": result["finished_at"]},
            )
            self.client.publish(self.reply_topic, json.dumps(reply), qos=1)
        finally:
            lock_file.close()

    def run_queue(self):
        queue = pop_all_queue(self.queue_path, self.lock_path)
        if not queue:
            self.logger.info("Queue empty")
            return
        self.logger.info("Running %s queued commands", len(queue))
        remaining = []
        for item in queue:
            try:
                self.execute_command(item)
            except Exception as exc:
                self.logger.error("Command failed: %s", exc)
                remaining.append(item)
        append_queue_list(self.queue_path, self.lock_path, remaining)

    def run(self):
        self.client.loop_start()
        thread = threading.Thread(target=self.heartbeat_loop, daemon=True)
        thread.start()
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Shutting down")


def main():
    parser = argparse.ArgumentParser(description="Kiosk agent")
    parser.add_argument(
        "--config",
        default=os.getenv("KIOSK_AGENT_CONFIG", DEFAULT_CONFIG_PATH),
    )
    parser.add_argument("--run-queue", action="store_true")
    args = parser.parse_args()

    agent = KioskAgent(args.config)
    if args.run_queue:
        agent.run_queue()
    else:
        agent.run()


if __name__ == "__main__":
    main()

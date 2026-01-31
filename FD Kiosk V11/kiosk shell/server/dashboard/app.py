import json
import os
from urllib.parse import urljoin

import requests
from flask import Flask, Response, jsonify, render_template, request

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")


def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def make_controller_url(base_url, path):
    return urljoin(base_url.rstrip("/") + "/", path.lstrip("/"))


def proxy_request(method, url, **kwargs):
    try:
        resp = requests.request(method, url, timeout=10, **kwargs)
    except requests.RequestException as exc:
        return jsonify({"error": "controller_unreachable", "detail": str(exc)}), 502

    if resp.headers.get("content-type", "").startswith("application/json"):
        return Response(resp.content, status=resp.status_code, content_type="application/json")

    return Response(resp.content, status=resp.status_code)


def create_app():
    cfg = load_config()
    controller_base = cfg["controller"]["base_url"]

    app = Flask(__name__)

    @app.get("/")
    def index():
        return render_template("index.html", controller_base=controller_base)

    @app.get("/kiosk/<kiosk_id>")
    def kiosk_detail(kiosk_id):
        return render_template("kiosk.html", kiosk_id=kiosk_id, controller_base=controller_base)

    @app.get("/api/kiosks")
    def api_kiosks():
        url = make_controller_url(controller_base, "/api/kiosks")
        return proxy_request("GET", url)

    @app.get("/api/kiosks/<kiosk_id>/history")
    def api_kiosk_history(kiosk_id):
        url = make_controller_url(controller_base, f"/api/kiosks/{kiosk_id}/history")
        return proxy_request("GET", url)

    @app.post("/api/command")
    def api_command():
        url = make_controller_url(controller_base, "/api/command")
        payload = request.get_json(force=True, silent=True) or {}
        return proxy_request("POST", url, json=payload)

    return app, cfg


if __name__ == "__main__":
    app, cfg = create_app()
    host = cfg["http"]["host"]
    port = cfg["http"]["port"]
    app.run(host=host, port=port, debug=False)

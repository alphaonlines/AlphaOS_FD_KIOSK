#!/usr/bin/env python3
"""
Version 10.0 GTK overlay UI:
- Toggle button swaps PRIMARY_URL/SECONDARY_URL
- Back sends Alt+Left
- xvkbd on-screen keyboard with auto-show via AT-SPI focus events
"""
import os
import subprocess
import threading

import gi
import requests

gi.require_version("Gtk", "3.0")
gi.require_version("Atspi", "2.0")
from gi.repository import Atspi, Gdk, Gtk, GLib

# Ensure xdotool can see the display when run under systemd
os.environ.setdefault("DISPLAY", ":0")

PRIMARY_URL = os.environ.get("PRIMARY_URL", "https://furnituredistributors.net")
SECONDARY_URL = os.environ.get("SECONDARY_URL", "https://alphaonlines.org/pages/aj-test")
BROWSER = os.environ.get("BROWSER", "chromium").lower()
STATE_FILE = os.environ.get("KIOSK_STATE_FILE", "/tmp/kiosk-current-url.txt")
DEBUG_PORT = int(os.environ.get("DEBUG_PORT", "9222"))


def read_state(default=PRIMARY_URL):
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as fh:
            val = fh.read().strip()
            if val:
                return val
    except FileNotFoundError:
        pass
    return default


def write_state(url: str) -> None:
    try:
        with open(STATE_FILE, "w", encoding="utf-8") as fh:
            fh.write(url)
    except OSError:
        pass


def target_for_toggle():
    url = read_state().lower()
    if url.startswith(SECONDARY_URL.lower()) or "alphaonline" in url or "aj-test" in url:
        return PRIMARY_URL
    return SECONDARY_URL


def toggle():
    target = target_for_toggle()
    try:
        requests.put(f"http://127.0.0.1:{DEBUG_PORT}/json/new?{target}", timeout=2)
        write_state(target)
    except Exception:
        pass


def go_back():
    subprocess.run(["xdotool", "key", "Alt_L+Left"], check=False)


# Keyboard management (xvkbd)
keyboard_process = None
autoshow_suppressed = False
last_focus_editable = False


def toggle_keyboard():
    global autoshow_suppressed
    if keyboard_process and keyboard_process.poll() is None:
        stop_keyboard()
        if last_focus_editable:
            autoshow_suppressed = True
    else:
        autoshow_suppressed = False
        start_keyboard()


def start_keyboard():
    global keyboard_process
    if keyboard_process and keyboard_process.poll() is None:
        return
    try:
        keyboard_process = subprocess.Popen(
            [
                "xvkbd",
                "-geometry",
                "1200x600+360+560",
                "-xrm",
                "xvkbd*Font: 9x15bold",
                "-xrm",
                "xvkbd.name: KioskKeyboard",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        threading.Timer(1.0, set_keyboard_always_on_top).start()
    except FileNotFoundError:
        pass


def stop_keyboard():
    global keyboard_process
    if keyboard_process and keyboard_process.poll() is None:
        keyboard_process.terminate()
        try:
            keyboard_process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            keyboard_process.kill()
    keyboard_process = None


def set_keyboard_always_on_top():
    """Set xvkbd window to always stay on top."""
    try:
        result = subprocess.run(
            ["wmctrl", "-l", "-x"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        for line in result.stdout.split("\n"):
            if "xvkbd" in line.lower() or "KioskKeyboard" in line:
                window_id = line.split()[0]
                subprocess.run(
                    ["wmctrl", "-ir", window_id, "-b", "add,above"],
                    check=False,
                    timeout=5,
                )
                break
    except Exception:
        pass


def is_editable(obj):
    try:
        state = obj.get_state_set()
        if state and state.contains(Atspi.StateType.EDITABLE):
            return True
    except Exception:
        pass
    try:
        role = obj.get_role()
        if role in (
            Atspi.Role.ENTRY,
            Atspi.Role.PASSWORD_TEXT,
            Atspi.Role.TEXT,
            Atspi.Role.PARAGRAPH,
            Atspi.Role.DOCUMENT_TEXT,
        ):
            return True
    except Exception:
        pass
    return False


def on_focus_event(event):
    global autoshow_suppressed, last_focus_editable
    try:
        focused = bool(event.detail1)
    except Exception:
        focused = False
    if not focused:
        return
    obj = event.source
    editable = is_editable(obj)
    last_focus_editable = editable
    if editable:
        if not autoshow_suppressed:
            start_keyboard()
    else:
        autoshow_suppressed = False
        stop_keyboard()


def start_focus_monitor():
    try:
        Atspi.init()
        listener = Atspi.EventListener.new(on_focus_event)
        listener.register("object:state-changed:focused")
    except Exception:
        pass


def apply_css():
    css = b"""
    .kiosk-window {
      background-color: #1c1c1c;
    }
    button.kiosk-button {
      background: #2f2f2f;
      color: #ffffff;
      border: none;
      border-radius: 0;
      font-weight: bold;
      font-family: Sans;
    }
    button.kiosk-toggle {
      font-size: 12px;
    }
    button.kiosk-back {
      font-size: 12px;
    }
    button.kiosk-keyboard {
      font-size: 16px;
    }
    """
    provider = Gtk.CssProvider()
    provider.load_from_data(css)
    screen = Gdk.Screen.get_default()
    if screen:
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )


class OverlayApp:
    def __init__(self):
        apply_css()
        screen = Gdk.Screen.get_default()
        if screen is None:
            raise RuntimeError("No display available for GTK")
        self.screen_width = screen.get_width()
        self.screen_height = screen.get_height()

        start_focus_monitor()

        self.toggle_button, self.toggle_window = self._make_toggle_window()
        self._make_back_window()

        GLib.timeout_add(800, self.update_toggle_text)

    def _make_window(self, label, on_click, width, height, x, y, style_class):
        win = Gtk.Window()
        win.set_decorated(False)
        win.set_keep_above(True)
        win.set_resizable(False)
        win.set_skip_taskbar_hint(True)
        win.set_skip_pager_hint(True)
        win.set_type_hint(Gdk.WindowTypeHint.DOCK)
        win.set_app_paintable(True)
        win.get_style_context().add_class("kiosk-window")

        btn = Gtk.Button(label=label)
        btn.get_style_context().add_class("kiosk-button")
        btn.get_style_context().add_class(style_class)
        btn.connect("clicked", lambda *_: on_click())
        win.add(btn)

        win.set_default_size(width, height)
        win.show_all()
        win.move(x, y)
        return btn, win

    def _make_toggle_window(self):
        width, height = 220, 50
        x, y = 10, self.screen_height - 60
        return self._make_window("Toggle", toggle, width, height, x, y, "kiosk-toggle")

    def _make_back_window(self):
        width, height = 120, 45
        x, y = 10, 10
        self._make_window("← Back", go_back, width, height, x, y, "kiosk-back")


    def update_toggle_text(self):
        target = target_for_toggle().lower()
        label = "Furniture Distributors" if target.startswith(PRIMARY_URL.lower()) else "AlphaPulse"
        self.toggle_button.set_label(label)
        return True

    def run(self):
        try:
            self.toggle_window.connect("destroy", Gtk.main_quit)
            Gtk.main()
        finally:
            stop_keyboard()


if __name__ == "__main__":
    write_state(read_state())
    OverlayApp().run()

#!/usr/bin/env python3
"""
Version 7.4 streamlined overlays:
- Toggle button swaps PRIMARY_URL/SECONDARY_URL
- Back sends Alt+Left
- Scroll buttons removed (native scrolling works well)
"""
import os
import subprocess
import tkinter as tk
from pathlib import Path

import requests

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
    except:
        pass


def go_back():
    subprocess.run(["xdotool", "key", "Alt_L+Left"], check=False)





class OverlayApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.overrideredirect(True)
        self.root.attributes("-topmost", True)
        self.root.configure(bg="#1c1c1c")
        self.root.withdraw()

        self.toggle_button = self._make_toggle_window()
        self._make_back_window()

        self.update_toggle_text()

    def _make_toggle_window(self):
        win = tk.Toplevel(self.root)
        win.overrideredirect(True)
        win.attributes("-topmost", True)
        win.configure(bg="#1c1c1c")
        btn = tk.Button(
            win,
            text="Toggle",
            command=toggle,
            fg="#ffffff",
            bg="#2f2f2f",
            bd=0,
            padx=12,
            pady=6,
            activebackground="#444444",
            font=("Arial", 10, "bold"),
        )
        btn.pack(fill="both", expand=True)
        win.update_idletasks()
        height = win.winfo_screenheight()
        win.geometry(f"220x50+10+{height-60}")
        return btn

    def _make_back_window(self):
        win = tk.Toplevel(self.root)
        win.overrideredirect(True)
        win.attributes("-topmost", True)
        win.configure(bg="#1c1c1c")
        btn = tk.Button(
            win,
            text="← Back",
            command=go_back,
            fg="#ffffff",
            bg="#2f2f2f",
            bd=0,
            padx=10,
            pady=4,
            activebackground="#444444",
            font=("Arial", 10, "bold"),
        )
        btn.pack(fill="both", expand=True)
        win.geometry("120x45+10+10")



    def update_toggle_text(self):
        target = target_for_toggle().lower()
        label = "Furniture Distributors" if target.startswith(PRIMARY_URL.lower()) else "AlphaPulse"
        self.toggle_button.config(text=label)
        self.root.after(800, self.update_toggle_text)

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    write_state(read_state())
    OverlayApp().run()
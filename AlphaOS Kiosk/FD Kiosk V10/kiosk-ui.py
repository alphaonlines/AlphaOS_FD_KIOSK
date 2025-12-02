#!/usr/bin/env python3
"""
Version 10.0 with integrated xvkbd keyboard:
- Toggle button swaps PRIMARY_URL/SECONDARY_URL
- Back sends Alt+Left
- External xvkbd keyboard with 9x15bold font
- Keyboard toggle button at top-right
- Scroll buttons removed (native scrolling works well)
"""
import os
import subprocess
import tkinter as tk
from pathlib import Path
import signal
import threading

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


# Keyboard management
keyboard_process = None

def toggle_keyboard():
    global keyboard_process
    if keyboard_process and keyboard_process.poll() is None:
        stop_keyboard()
    else:
        start_keyboard()

def start_keyboard():
    global keyboard_process
    try:
        # Position keyboard at bottom center of screen with 3X size
        # Screen: 1920x1080, Keyboard: 1200x600 (3X default)
        # Centered horizontally: (1920-1200)/2 = 360px from left
        # Bottom positioned: 1080-600-20 = 460px from top (20px margin)
        keyboard_process = subprocess.Popen([
            "xvkbd", 
            "-geometry", "1200x600+360+460",
            # Bold bitmap font for excellent visibility with 3X scaling
            "-xrm", "xvkbd*Font: 9x15bold",
            # Set window name for easier identification
            "-xrm", "xvkbd.name: KioskKeyboard"
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL)
        
        # Wait for window to appear, then set always-on-top
        threading.Timer(1.0, set_keyboard_always_on_top).start()
        
    except FileNotFoundError:
        # xvkbd not installed, show error or silently fail
        pass

def set_keyboard_always_on_top():
    """Set xvkbd window to always stay on top"""
    try:
        # Find the xvkbd window by name or class
        result = subprocess.run(
            ["wmctrl", "-l", "-x"], 
            capture_output=True, text=True, timeout=5
        )
        
        # Look for xvkbd window
        for line in result.stdout.split('\n'):
            if 'xvkbd' in line.lower() or 'KioskKeyboard' in line:
                window_id = line.split()[0]
                # Set window to "above" state (always on top)
                subprocess.run([
                    "wmctrl", "-ir", window_id, "-b", "add,above"
                ], check=False, timeout=5)
                break
    except Exception:
        # If anything fails, keyboard will still work without always-on-top
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




class OverlayApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.overrideredirect(True)
        self.root.attributes("-topmost", True)
        self.root.configure(bg="#1c1c1c")
        self.root.withdraw()

        self.toggle_button = self._make_toggle_window()
        self._make_back_window()
        self._make_keyboard_window()

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

    def _make_keyboard_window(self):
        win = tk.Toplevel(self.root)
        win.overrideredirect(True)
        win.attributes("-topmost", True)
        win.configure(bg="#1c1c1c")
        btn = tk.Button(
            win,
            text="⌨",
            command=toggle_keyboard,
            fg="#ffffff",
            bg="#2f2f2f",
            bd=0,
            padx=8,
            pady=4,
            activebackground="#444444",
            font=("Arial", 12, "bold"),
        )
        btn.pack(fill="both", expand=True)
        # Position at top-right corner
        width = win.winfo_screenwidth()
        win.geometry(f"80x45+{width-90}+10")



    def update_toggle_text(self):
        target = target_for_toggle().lower()
        label = "Furniture Distributors" if target.startswith(PRIMARY_URL.lower()) else "AlphaPulse"
        self.toggle_button.config(text=label)
        self.root.after(800, self.update_toggle_text)

    def run(self):
        try:
            self.root.mainloop()
        finally:
            # Clean up keyboard process on exit
            stop_keyboard()


if __name__ == "__main__":
    write_state(read_state())
    OverlayApp().run()
#!/usr/bin/env python3
"""
TGMacro for macOS — sick dark UI
Setup: pip3 install pyobjc-framework-Quartz pynput customtkinter
"""

import threading
import time
import customtkinter as ctk
from Quartz import (
    CGEventCreateKeyboardEvent, CGEventPost,
    kCGSessionEventTap, CGEventSourceCreate,
    kCGEventSourceStateHIDSystemState,
)
from pynput import mouse

# ── Quartz setup ──────────────────────────────────────────────────────────────
source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState)

KEY_CODES = {
    'a':0,'s':1,'d':2,'f':3,'h':4,'g':5,'z':6,'x':7,'c':8,'v':9,
    'b':11,'q':12,'w':13,'e':14,'r':15,'y':16,'t':17,'1':18,'2':19,
    '3':20,'4':21,'6':22,'5':23,'=':24,'9':25,'7':26,'-':27,'8':28,
    '0':29,'o':31,'u':32,'i':34,'p':35,'l':37,'j':38,'k':40,'n':45,
    'm':46,' ':49,
}

def press_key(keycode):
    CGEventPost(kCGSessionEventTap, CGEventCreateKeyboardEvent(source, keycode, True))
    CGEventPost(kCGSessionEventTap, CGEventCreateKeyboardEvent(source, keycode, False))

# ── App state ─────────────────────────────────────────────────────────────────
running = False
lock = threading.Lock()
presses_count = 0

def spam_loop(delay, keys):
    global presses_count
    idx = 0
    next_time = time.perf_counter()
    while True:
        with lock:
            if not running: break
        press_key(keys[idx % len(keys)])
        presses_count += 1
        idx += 1
        next_time += delay
        remaining = next_time - time.perf_counter()
        if remaining > 0.002:
            time.sleep(remaining - 0.001)
        while time.perf_counter() < next_time:
            pass

# ── UI ────────────────────────────────────────────────────────────────────────
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("dark-blue")

ACCENT   = "#00FF88"
ACCENT2  = "#00CCFF"
BG       = "#0A0A0F"
SURFACE  = "#12121A"
SURFACE2 = "#1A1A26"
BORDER   = "#2A2A3A"
TEXT     = "#E8E8F0"
MUTED    = "#6B6B8A"

class MacroApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("MACRO")
        self.geometry("360x560")
        self.resizable(False, False)
        self.configure(fg_color=BG)
        self._setup_ui()
        self._start_mouse_listener()
        self._tick()

    def _setup_ui(self):
        # ── Header ──
        hdr = ctk.CTkFrame(self, fg_color=SURFACE, corner_radius=0, height=64)
        hdr.pack(fill="x")
        hdr.pack_propagate(False)

        ctk.CTkLabel(hdr, text="⬡  MACRO", font=("Courier New", 20, "bold"),
                     text_color=ACCENT).place(relx=0.5, rely=0.5, anchor="center")

        # ── Status card ──
        status_card = ctk.CTkFrame(self, fg_color=SURFACE2, corner_radius=16,
                                   border_width=1, border_color=BORDER)
        status_card.pack(fill="x", padx=20, pady=(20, 0))

        inner = ctk.CTkFrame(status_card, fg_color="transparent")
        inner.pack(pady=20, padx=20, fill="x")

        # Dot + label
        dot_row = ctk.CTkFrame(inner, fg_color="transparent")
        dot_row.pack(anchor="center")
        self.dot = ctk.CTkLabel(dot_row, text="●", font=("Courier New", 22),
                                text_color=MUTED)
        self.dot.pack(side="left", padx=(0, 8))
        self.status_label = ctk.CTkLabel(dot_row, text="INACTIVE",
                                         font=("Courier New", 14, "bold"),
                                         text_color=MUTED)
        self.status_label.pack(side="left")

        # Counter
        self.counter_label = ctk.CTkLabel(inner, text="0 presses",
                                          font=("Courier New", 11),
                                          text_color=MUTED)
        self.counter_label.pack(pady=(6, 0))

        # Toggle button
        self.toggle_btn = ctk.CTkButton(
            inner, text="MIDDLE CLICK  ·  TOGGLE",
            font=("Courier New", 11, "bold"),
            fg_color=SURFACE, hover_color=SURFACE2,
            border_width=1, border_color=BORDER,
            text_color=MUTED, corner_radius=8, height=32,
            command=self.toggle
        )
        self.toggle_btn.pack(fill="x", pady=(14, 0))

        # ── Speed section ──
        speed_card = ctk.CTkFrame(self, fg_color=SURFACE2, corner_radius=16,
                                  border_width=1, border_color=BORDER)
        speed_card.pack(fill="x", padx=20, pady=16)

        speed_inner = ctk.CTkFrame(speed_card, fg_color="transparent")
        speed_inner.pack(padx=20, pady=18, fill="x")

        top_row = ctk.CTkFrame(speed_inner, fg_color="transparent")
        top_row.pack(fill="x")
        ctk.CTkLabel(top_row, text="SPEED", font=("Courier New", 11, "bold"),
                     text_color=MUTED).pack(side="left")
        self.speed_val = ctk.CTkLabel(top_row, text="33 /sec",
                                      font=("Courier New", 11, "bold"),
                                      text_color=ACCENT)
        self.speed_val.pack(side="right")

        self.slider = ctk.CTkSlider(speed_inner, from_=5, to=200,
                                    number_of_steps=195,
                                    button_color=ACCENT, button_hover_color=ACCENT2,
                                    progress_color=ACCENT, fg_color=BORDER,
                                    command=self._on_slider)
        self.slider.set(33)
        self.slider.pack(fill="x", pady=(10, 0))

        # ── Keys section ──
        keys_card = ctk.CTkFrame(self, fg_color=SURFACE2, corner_radius=16,
                                 border_width=1, border_color=BORDER)
        keys_card.pack(fill="x", padx=20)

        keys_inner = ctk.CTkFrame(keys_card, fg_color="transparent")
        keys_inner.pack(padx=20, pady=18, fill="x")

        ctk.CTkLabel(keys_inner, text="KEYS TO SPAM",
                     font=("Courier New", 11, "bold"), text_color=MUTED).pack(anchor="w")

        self.keys_entry = ctk.CTkEntry(
            keys_inner, placeholder_text="e.g. i o",
            font=("Courier New", 14), fg_color=SURFACE,
            border_color=BORDER, text_color=TEXT,
            corner_radius=8, height=40
        )
        self.keys_entry.insert(0, "i o")
        self.keys_entry.pack(fill="x", pady=(10, 0))

        ctk.CTkLabel(keys_inner, text="separate keys with spaces",
                     font=("Courier New", 10), text_color=MUTED).pack(anchor="w", pady=(4,0))

        # ── Footer ──
        ctk.CTkLabel(self, text="middle click · toggle  //  game mode disabled = must",
                     font=("Courier New", 9), text_color=MUTED).pack(side="bottom", pady=12)

    def _on_slider(self, val):
        pps = int(val)
        self.speed_val.configure(text=f"{pps} /sec")

    def _get_delay(self):
        return 1.0 / max(1, int(self.slider.get()))

    def _get_keys(self):
        raw = self.keys_entry.get().strip().lower().split()
        codes = []
        for k in raw:
            if k in KEY_CODES:
                codes.append(KEY_CODES[k])
        return codes if codes else [KEY_CODES['i'], KEY_CODES['o']]

    def toggle(self):
        global running
        with lock:
            running = not running
            state = running
        if state:
            delay = self._get_delay()
            keys = self._get_keys()
            threading.Thread(target=spam_loop, args=(delay, keys), daemon=True).start()
        self._update_status(state)

    def _update_status(self, state):
        if state:
            self.status_label.configure(text="ACTIVE", text_color=ACCENT)
            self.dot.configure(text_color=ACCENT)
            self.toggle_btn.configure(border_color=ACCENT, text_color=ACCENT)
        else:
            self.status_label.configure(text="INACTIVE", text_color=MUTED)
            self.dot.configure(text_color=MUTED)
            self.toggle_btn.configure(border_color=BORDER, text_color=MUTED)

    def _tick(self):
        self.counter_label.configure(text=f"{presses_count:,} presses")
        # Pulse dot when active
        if running:
            current = self.dot.cget("text_color")
            self.dot.configure(text_color=ACCENT if current == MUTED else MUTED)
        self.after(400, self._tick)

    def _start_mouse_listener(self):
        def on_click(x, y, button, pressed):
            if button == mouse.Button.middle and pressed:
                self.after(0, self.toggle)
        t = mouse.Listener(on_click=on_click)
        t.daemon = True
        t.start()

if __name__ == "__main__":
    app = MacroApp()
    app.mainloop()

#!/usr/bin/env python3
"""
machood_daemon.py — headless macro engine
Communicates with the Swift UI over a Unix domain socket at /tmp/machood.sock
Protocol: newline-delimited JSON  { "cmd": "...", ...params }
Responses: newline-delimited JSON { "event": "...", ...data }

Setup: pip3 install pyobjc-framework-Quartz pynput
Run:   python3 machood_daemon.py
"""

import threading, time, json, os, socket, sys

# ── Quartz ────────────────────────────────────────────────────────────────────
from Quartz import (
    CGEventCreateKeyboardEvent, CGEventPost,
    kCGSessionEventTap, CGEventSourceCreate, kCGEventSourceStateHIDSystemState,
    CGEventCreateScrollWheelEvent, kCGScrollEventUnitPixel,
    CGEventGetIntegerValueField, kCGKeyboardEventKeycode,
    CGEventTapCreate, kCGHIDEventTap, kCGHeadInsertEventTap,
    kCGEventTapOptionListenOnly, CGEventMaskBit, kCGEventKeyDown,
    CFMachPortCreateRunLoopSource, CFRunLoopGetCurrent,
    CFRunLoopAddSource, kCFRunLoopDefaultMode, CGEventTapEnable,
)
from pynput import mouse

source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState)

KEY_CODES = {
    'a':0,'s':1,'d':2,'f':3,'h':4,'g':5,'z':6,'x':7,'c':8,'v':9,
    'b':11,'q':12,'w':13,'e':14,'r':15,'y':16,'t':17,'1':18,'2':19,
    '3':20,'4':21,'6':22,'5':23,'=':24,'9':25,'7':26,'-':27,'8':28,
    '0':29,'o':31,'u':32,'i':34,'p':35,'l':37,'j':38,'k':40,'n':45,
    'm':46,' ':49,'tab':48,'enter':36,'esc':53,'backspace':51,
    'capslock':57,'shift':56,'ctrl':59,'alt':58,'cmd':55,
    'up':126,'down':125,'left':123,'right':124,
    'f1':122,'f2':120,'f3':99,'f4':118,'f5':96,'f6':97,
    'scrollup':'SCROLL_UP','scrolldown':'SCROLL_DOWN',
}
KEY_DISPLAY = {
    'tab':'Tab','enter':'Return','esc':'Esc','backspace':'⌫',
    'capslock':'Caps','shift':'⇧','ctrl':'⌃','alt':'⌥','cmd':'⌘',
    'up':'↑','down':'↓','left':'←','right':'→',
    'scrollup':'Scroll ↑','scrolldown':'Scroll ↓',' ':'Space',
}

def press_key_or_scroll(key_id):
    if key_id == 'SCROLL_UP':
        CGEventPost(kCGSessionEventTap, CGEventCreateScrollWheelEvent(source, kCGScrollEventUnitPixel, 1, -20))
    elif key_id == 'SCROLL_DOWN':
        CGEventPost(kCGSessionEventTap, CGEventCreateScrollWheelEvent(source, kCGScrollEventUnitPixel, 1, 20))
    elif isinstance(key_id, int):
        CGEventPost(kCGSessionEventTap, CGEventCreateKeyboardEvent(source, key_id, True))
        CGEventPost(kCGSessionEventTap, CGEventCreateKeyboardEvent(source, key_id, False))

# ── Macro state ───────────────────────────────────────────────────────────────
running       = False
lock          = threading.Lock()
presses_count = 0

def spam_loop(delay, keys):
    global presses_count
    idx, nxt = 0, time.perf_counter()
    while True:
        with lock:
            if not running: break
        press_key_or_scroll(keys[idx % len(keys)])
        presses_count += 1; idx += 1
        nxt += delay
        rem = nxt - time.perf_counter()
        if rem > 0.002: time.sleep(rem - 0.001)
        while time.perf_counter() < nxt: pass

# ── Config ────────────────────────────────────────────────────────────────────
CONFIG_PATH = os.path.expanduser("~/.machood_config.json")

def load_config():
    d = {"hotkey":"middle_mouse","hotkey_display":"Middle Click","speed":33,
         "key_sequence":[{"name":"i","id":KEY_CODES["i"]},{"name":"o","id":KEY_CODES["o"]}]}
    try:
        with open(CONFIG_PATH) as f: d.update(json.load(f))
    except: pass
    return d

def save_config(c):
    try:
        with open(CONFIG_PATH,"w") as f: json.dump(c,f,indent=2)
    except: pass

# ── App state ─────────────────────────────────────────────────────────────────
config           = load_config()
hotkey           = config.get("hotkey","middle_mouse")
hotkey_display   = config.get("hotkey_display","Middle Click")
key_sequence     = config.get("key_sequence",[])
recording_hotkey = False
recording_key    = False

# Active client sockets for broadcasting events
clients     = []
clients_lock = threading.Lock()

def broadcast(msg: dict):
    line = (json.dumps(msg) + "\n").encode()
    with clients_lock:
        dead = []
        for c in clients:
            try: c.sendall(line)
            except: dead.append(c)
        for c in dead: clients.remove(c)

# ── Macro control ─────────────────────────────────────────────────────────────
def do_toggle():
    global running
    with lock:
        running = not running
        state = running
    if state:
        delay = 1.0 / max(1, config.get("speed", 33))
        ids   = [e["id"] for e in key_sequence if isinstance(e.get("id"), int)] \
                or [KEY_CODES["i"], KEY_CODES["o"]]
        threading.Thread(target=spam_loop, args=(delay, ids), daemon=True).start()
    broadcast({"event":"status","running":state,"presses":presses_count})

# ── Input listeners ───────────────────────────────────────────────────────────
def start_listeners():
    global hotkey, hotkey_display, recording_hotkey, recording_key

    def on_click(x, y, button, pressed):
        global hotkey, hotkey_display, recording_hotkey, recording_key
        if not pressed: return
        if recording_hotkey:
            hk = f"mouse_{button.name}"
            d  = {"middle":"Middle Click","left":"Left Click","right":"Right Click"}.get(
                     button.name, f"Mouse {button.name}")
            recording_hotkey = False
            hotkey, hotkey_display = hk, d
            config.update({"hotkey":hk,"hotkey_display":d}); save_config(config)
            broadcast({"event":"hotkey_set","hotkey":hk,"display":d}); return
        if recording_key:
            recording_key = False
            name = {"left":"left_click","right":"right_click"}.get(button.name)
            if name:
                key_sequence.append({"name":name,"id":"LEFT_CLICK" if name=="left_click" else "RIGHT_CLICK"})
                config["key_sequence"] = key_sequence; save_config(config)
                broadcast({"event":"key_added","name":name,"display":name.replace("_"," ").title()})
            return
        if hotkey == f"mouse_{button.name}": do_toggle(); return
        if button == mouse.Button.middle and hotkey == "middle_mouse": do_toggle()

    def on_scroll(x, y, dx, dy):
        global recording_key
        if not recording_key: return
        recording_key = False
        name = "scrollup" if dy > 0 else "scrolldown"
        key_sequence.append({"name":name,"id":KEY_CODES[name]})
        config["key_sequence"] = key_sequence; save_config(config)
        d = KEY_DISPLAY.get(name, name)
        broadcast({"event":"key_added","name":name,"display":d})

    ml = mouse.Listener(on_click=on_click, on_scroll=on_scroll)
    ml.daemon = True; ml.start()

    def _qcb(proxy, etype, event, ref):
        global hotkey, hotkey_display, recording_hotkey, recording_key
        try:
            kc   = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode)
            name = next((k for k,v in KEY_CODES.items() if v==kc), None)
            if recording_hotkey:
                recording_hotkey = False
                d  = KEY_DISPLAY.get(name, name.upper() if name else str(kc))
                hk = f"keycode_{kc}"
                hotkey, hotkey_display = hk, d
                config.update({"hotkey":hk,"hotkey_display":d}); save_config(config)
                broadcast({"event":"hotkey_set","hotkey":hk,"display":d}); return event
            if recording_key and name and name in KEY_CODES:
                recording_key = False
                kid = KEY_CODES[name]
                key_sequence.append({"name":name,"id":kid})
                config["key_sequence"] = key_sequence; save_config(config)
                d = KEY_DISPLAY.get(name, name.upper())
                broadcast({"event":"key_added","name":name,"display":d}); return event
            if hotkey == f"keycode_{kc}": do_toggle()
        except: pass
        return event

    from CoreFoundation import CFRunLoopRun
    def _tap():
        tap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap,
                               kCGEventTapOptionListenOnly,
                               CGEventMaskBit(kCGEventKeyDown), _qcb, None)
        if tap is None: return
        src = CFMachPortCreateRunLoopSource(None, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, kCFRunLoopDefaultMode)
        CGEventTapEnable(tap, True); CFRunLoopRun()
    threading.Thread(target=_tap, daemon=True).start()

# ── Ticker — broadcast press count every 0.5s when running ───────────────────
def ticker():
    while True:
        time.sleep(0.5)
        if running:
            broadcast({"event":"tick","presses":presses_count,"running":running})

# ── Command dispatcher ────────────────────────────────────────────────────────
def handle_cmd(cmd: dict, conn):
    global recording_hotkey, recording_key, key_sequence, hotkey, hotkey_display

    c = cmd.get("cmd","")

    if c == "get_state":
        conn.sendall((json.dumps({
            "event": "state",
            "running": running,
            "presses": presses_count,
            "speed": config.get("speed", 33),
            "hotkey_display": hotkey_display,
            "key_sequence": [
                {"name": e["name"],
                 "display": KEY_DISPLAY.get(e["name"], e["name"].upper())}
                for e in key_sequence
            ],
        }) + "\n").encode())

    elif c == "toggle":
        do_toggle()

    elif c == "set_speed":
        v = max(5, min(200, int(cmd.get("value", 33))))
        config["speed"] = v; save_config(config)
        broadcast({"event":"speed","value":v})

    elif c == "record_key":
        recording_key = True
        broadcast({"event":"recording_key"})

    elif c == "record_hotkey":
        recording_hotkey = True
        broadcast({"event":"recording_hotkey"})

    elif c == "reset_hotkey":
        hotkey, hotkey_display = "middle_mouse", "Middle Click"
        config.update({"hotkey":hotkey,"hotkey_display":hotkey_display})
        save_config(config)
        broadcast({"event":"hotkey_set","hotkey":hotkey,"display":hotkey_display})

    elif c == "remove_key":
        name = cmd.get("name","")
        key_sequence = [e for e in key_sequence if e["name"] != name]
        config["key_sequence"] = key_sequence; save_config(config)
        broadcast({"event":"sequence_updated","key_sequence":[
            {"name":e["name"],"display":KEY_DISPLAY.get(e["name"],e["name"].upper())}
            for e in key_sequence
        ]})

# ── Socket server ─────────────────────────────────────────────────────────────
SOCKET_PATH = "/tmp/machood.sock"

def serve():
    if os.path.exists(SOCKET_PATH): os.unlink(SOCKET_PATH)
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(SOCKET_PATH); srv.listen(8)
    print(f"machood daemon listening on {SOCKET_PATH}", flush=True)

    while True:
        conn, _ = srv.accept()
        def _handle(conn=conn):
            with clients_lock: clients.append(conn)
            buf = b""
            try:
                while True:
                    data = conn.recv(4096)
                    if not data: break
                    buf += data
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        if line.strip():
                            try:
                                handle_cmd(json.loads(line), conn)
                            except Exception as e:
                                print(f"cmd error: {e}", flush=True)
            except: pass
            finally:
                with clients_lock:
                    if conn in clients: clients.remove(conn)
                conn.close()
        threading.Thread(target=_handle, daemon=True).start()

if __name__ == "__main__":
    start_listeners()
    threading.Thread(target=ticker, daemon=True).start()
    serve()   # blocks

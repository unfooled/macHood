import Foundation

struct KeyEntry: Identifiable, Decodable {
    let id      = UUID()
    let name:    String
    let display: String
    enum CodingKeys: String, CodingKey { case name, display }
}

@MainActor
class DaemonConnection: ObservableObject {

    @Published var isRunning       = false
    @Published var presses         = 0
    @Published var speed           = 33
    @Published var hotkeyDisplay   = "Middle Click"
    @Published var keySequence:      [KeyEntry] = []
    @Published var isConnected     = false
    @Published var recordingKey    = false
    @Published var recordingHotkey = false
    @Published var lastAdded:        String? = nil

    private var fileHandle: FileHandle?
    private var buffer     = Data()
    private var retryTimer: Timer?
    private let socketPath = "/tmp/machood.sock"

    func start() { connect() }

    // ── Connect via raw POSIX, then wrap in FileHandle ────────────────────────
    private func connect() {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { scheduleRetry(); return }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            socketPath.withCString {
                _ = strcpy(UnsafeMutableRawPointer(ptr)
                    .assumingMemoryBound(to: CChar.self), $0)
            }
        }

        let ok = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        } == 0

        guard ok else { Darwin.close(fd); scheduleRetry(); return }

        let fh = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        fileHandle  = fh
        isConnected = true

        // Read on a background thread, dispatch results to main
        fh.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                // EOF — connection closed
                DispatchQueue.main.async { self?.handleDisconnect() }
                return
            }
            DispatchQueue.main.async { self?.ingest(data) }
        }

        send(["cmd": "get_state"])
    }

    private func handleDisconnect() {
        fileHandle?.readabilityHandler = nil
        fileHandle = nil
        scheduleRetry()
    }

    private func scheduleRetry() {
        isConnected = false
        fileHandle?.readabilityHandler = nil
        fileHandle = nil
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.connect() }
        }
    }

    // ── Parse incoming newline-delimited JSON ─────────────────────────────────
    private func ingest(_ data: Data) {
        buffer.append(data)
        while let nl = buffer.firstIndex(of: UInt8(ascii: "\n")) {
            let line = buffer[buffer.startIndex..<nl]
            buffer.removeSubrange(buffer.startIndex...nl)
            guard !line.isEmpty,
                  let msg = try? JSONSerialization.jsonObject(with: line) as? [String: Any]
            else { continue }
            handle(msg)
        }
    }

    private func handle(_ msg: [String: Any]) {
        switch msg["event"] as? String ?? "" {
        case "state":
            isRunning     = msg["running"]        as? Bool   ?? false
            presses       = msg["presses"]        as? Int    ?? 0
            speed         = msg["speed"]          as? Int    ?? 33
            hotkeyDisplay = msg["hotkey_display"] as? String ?? hotkeyDisplay
            keySequence   = parseKeys(msg["key_sequence"])
        case "status":
            isRunning = msg["running"] as? Bool ?? false
            presses   = msg["presses"] as? Int  ?? presses
        case "tick":
            presses   = msg["presses"] as? Int  ?? presses
            isRunning = msg["running"] as? Bool ?? false
        case "speed":
            speed = msg["value"] as? Int ?? speed
        case "hotkey_set":
            hotkeyDisplay   = msg["display"] as? String ?? hotkeyDisplay
            recordingHotkey = false
        case "recording_key":    recordingKey    = true
        case "recording_hotkey": recordingHotkey = true
        case "key_added":
            recordingKey = false
            lastAdded    = msg["display"] as? String
            send(["cmd": "get_state"])
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { self.lastAdded = nil }
            }
        case "sequence_updated":
            keySequence = parseKeys(msg["key_sequence"])
        default: break
        }
    }

    private func parseKeys(_ raw: Any?) -> [KeyEntry] {
        guard let arr = raw as? [[String: Any]] else { return [] }
        return arr.compactMap { d in
            guard let n = d["name"] as? String,
                  let disp = d["display"] as? String else { return nil }
            return KeyEntry(name: n, display: disp)
        }
    }

    // ── Write ─────────────────────────────────────────────────────────────────
    func send(_ dict: [String: Any]) {
        guard let fh = fileHandle,
              let data = try? JSONSerialization.data(withJSONObject: dict),
              let line = String(data: data, encoding: .utf8)
        else { return }
        let bytes = Data((line + "\n").utf8)
        do { try fh.write(contentsOf: bytes) }
        catch { handleDisconnect() }
    }

    func toggle()               { send(["cmd": "toggle"]) }
    func setSpeed(_ v: Int)     { send(["cmd": "set_speed", "value": v]) }
    func recordKey()            { send(["cmd": "record_key"]) }
    func recordHotkey()         { send(["cmd": "record_hotkey"]) }
    func resetHotkey()          { send(["cmd": "reset_hotkey"]) }
    func removeKey(_ n: String) { send(["cmd": "remove_key", "name": n]) }
}

import SwiftUI

// ── Tokens ────────────────────────────────────────────────────────────────────
extension Color {
    static let rcAccent    = Color(red: 1,    green: 0.388, blue: 0.388)
    static let rcAccent2   = Color(red: 1,    green: 0.541, blue: 0.396)
    static let rcGreen     = Color(red: 0.290, green: 0.871, blue: 0.502)
    static let rcSurface   = Color.white.opacity(0.10)
    static let rcSurfaceHi = Color.white.opacity(0.18)
    static let rcBorder    = Color.white.opacity(0.15)
    static let rcBorderHi  = Color.white.opacity(0.20)
    static let rcText      = Color.white
    static let rcText2     = Color.white.opacity(0.60)
    static let rcMuted     = Color.white.opacity(0.35)
    static let rcDim       = Color.white.opacity(0.20)
}

// ── Tab enum ──────────────────────────────────────────────────────────────────
enum Tab: String, CaseIterable {
    case macro    = "Macro"
    case settings = "Settings"
}

// ── Root view ─────────────────────────────────────────────────────────────────
struct ContentView: View {
    @EnvironmentObject var daemon: DaemonConnection
    @State private var tab: Tab = .macro

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.05).opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderBar()
                Divider().background(Color.rcBorder)
                TabStrip(selected: $tab)
                Divider().background(Color.rcBorder)

                ZStack {
                    if tab == .macro    { MacroView() }
                    if tab == .settings { SettingsView() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider().background(Color.rcBorder)
                FooterBar()
            }
        }
        .background(Color.clear)
        .environmentObject(daemon)
    }
}

// ── Header ────────────────────────────────────────────────────────────────────
struct HeaderBar: View {
    @EnvironmentObject var daemon: DaemonConnection

    var body: some View {
        HStack(spacing: 10) {
            Text("⚡")
                .font(.system(size: 22))
                .foregroundColor(.rcAccent)

            Text("machood")
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundColor(.rcText)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(daemon.isRunning ? Color.rcGreen : Color.rcMuted)
                    .frame(width: 7, height: 7)
                    .animation(.easeInOut(duration: 0.3), value: daemon.isRunning)

                Text(daemon.isRunning ? "active" : "inactive")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(daemon.isRunning ? .rcGreen : .rcMuted)
                    .animation(.easeInOut(duration: 0.2), value: daemon.isRunning)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                daemon.isRunning ? Color.rcGreen.opacity(0.15) : Color.rcSurface,
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(
                    daemon.isRunning ? Color.rcGreen.opacity(0.4) : Color.rcBorder,
                    lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.25), value: daemon.isRunning)
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
    }
}

// ── Tab strip ─────────────────────────────────────────────────────────────────
struct TabStrip: View {
    @Binding var selected: Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button(action: { withAnimation(.easeOut(duration: 0.15)) { selected = t } }) {
                    Text(t.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(selected == t ? .rcText : .rcMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            selected == t ? Color.rcSurfaceHi : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }
}

// ── Footer ────────────────────────────────────────────────────────────────────
struct FooterBar: View {
    @EnvironmentObject var daemon: DaemonConnection

    var body: some View {
        HStack {
            Text("\(daemon.presses.formatted()) presses")
                .font(.system(size: 11))
                .foregroundColor(.rcDim)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(daemon.isConnected ? Color.rcGreen.opacity(0.7) : Color.red.opacity(0.6))
                    .frame(width: 5, height: 5)
                Text(daemon.isConnected ? "daemon connected" : "connecting…")
                    .font(.system(size: 11))
                    .foregroundColor(.rcDim)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 32)
    }
}

// ── Macro tab ─────────────────────────────────────────────────────────────────
struct MacroView: View {
    @EnvironmentObject var daemon: DaemonConnection
    @State private var sliderValue: Double = 33

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                SectionLabel("Action")
                ToggleRow()
                    .environmentObject(daemon)

                RCDivider()

                SectionLabel("Speed")
                GlassCard {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Keypresses / second")
                                .font(.system(size: 13))
                                .foregroundColor(.rcText2)
                            Spacer()
                            Text("\(Int(sliderValue))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.rcAccent)
                        }
                        Slider(value: $sliderValue, in: 5...200, step: 1)
                            .tint(.rcAccent)
                            .onChange(of: sliderValue) { v in
                                daemon.setSpeed(Int(v))
                            }
                    }
                    .padding(16)
                }
                .onAppear { sliderValue = Double(daemon.speed) }
                .onChange(of: daemon.speed) { v in sliderValue = Double(v) }

                RCDivider()

                SectionLabel("Key Sequence")
                KeySequenceCard()
                    .environmentObject(daemon)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }
}

struct ToggleRow: View {
    @EnvironmentObject var daemon: DaemonConnection
    @State private var hovered = false

    var body: some View {
        Button(action: { daemon.toggle() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            daemon.isRunning
                                ? Color.rcGreen.opacity(0.18)
                                : Color.rcAccent.opacity(0.15)
                        )
                        .frame(width: 38, height: 38)
                    Text("⚡")
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Toggle Macro")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(daemon.isRunning ? .rcGreen : .rcText)
                    Text("Trigger: \(daemon.hotkeyDisplay)")
                        .font(.system(size: 11))
                        .foregroundColor(.rcText2)
                }

                Spacer()

                KbdChip(daemon.hotkeyDisplay)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                hovered
                    ? (daemon.isRunning ? Color.rcGreen.opacity(0.12) : Color.rcSurfaceHi)
                    : (daemon.isRunning ? Color.rcGreen.opacity(0.08) : Color.rcSurface),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        daemon.isRunning ? Color.rcGreen.opacity(0.35) : Color.rcBorder,
                        lineWidth: 1
                    )
            )
            .animation(.easeOut(duration: 0.2), value: daemon.isRunning)
            .animation(.easeOut(duration: 0.12), value: hovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

struct KeySequenceCard: View {
    @EnvironmentObject var daemon: DaemonConnection

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Keys pressed in order")
                        .font(.system(size: 13))
                        .foregroundColor(.rcText2)
                    Spacer()
                    Button(action: { daemon.recordKey() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Add")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(daemon.recordingKey ? .rcAccent2 : .rcAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.rcAccent.opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.rcAccent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                if daemon.recordingKey {
                    HStack(spacing: 6) {
                        Circle().fill(Color.rcAccent).frame(width:6,height:6)
                            .opacity(0.8)
                        Text("Press any key, scroll, or mouse button…")
                            .font(.system(size: 11))
                            .foregroundColor(.rcAccent2)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let added = daemon.lastAdded {
                    Text("Added: \(added)")
                        .font(.system(size: 11))
                        .foregroundColor(.rcGreen)
                        .transition(.opacity)
                }

                if daemon.keySequence.isEmpty {
                    Text("No keys added — tap + Add to start")
                        .font(.system(size: 12))
                        .foregroundColor(.rcMuted)
                        .padding(.vertical, 4)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(daemon.keySequence) { key in
                            KeySequenceChip(key: key)
                                .environmentObject(daemon)
                        }
                    }
                }
            }
            .padding(16)
            .animation(.easeOut(duration: 0.2), value: daemon.recordingKey)
            .animation(.easeOut(duration: 0.2), value: daemon.lastAdded)
        }
    }
}

struct KeySequenceChip: View {
    let key: KeyEntry
    @EnvironmentObject var daemon: DaemonConnection
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 5) {
            Text(key.display)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.rcText2)
            Button(action: { daemon.removeKey(key.name) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.rcMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.rcSurfaceHi, in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7)
            .stroke(hovered ? Color.rcBorderHi : Color.rcBorder, lineWidth: 1))
        .onHover { hovered = $0 }
    }
}

// ── Settings tab ──────────────────────────────────────────────────────────────
struct SettingsView: View {
    @EnvironmentObject var daemon: DaemonConnection

    private let inputTypes: [(String,String,String)] = [
        ("keyboard","Regular keys",    "a–z, 0–9, space"),
        ("gearshape","Modifier keys",  "⇧ ⌃ ⌥ ⌘"),
        ("f.cursive","Function keys",  "F1 – F6"),
        ("arrow.up.and.down","Arrow keys","↑ ↓ ← →"),
        ("scroll","Scroll wheel",      "Up / Down"),
        ("cursorarrow.click.2","Mouse buttons","Left / Right / Middle"),
        ("escape","Special keys",      "Caps, Tab, Enter, Esc"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                SectionLabel("Toggle Hotkey")
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Current binding")
                                .font(.system(size: 13))
                                .foregroundColor(.rcText2)
                            Spacer()
                            KbdChip(daemon.hotkeyDisplay)
                        }

                        Divider().background(Color.rcBorder)

                        HStack(spacing: 8) {
                            Button(action: { daemon.recordHotkey() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: daemon.recordingHotkey ? "waveform" : "record.circle")
                                        .font(.system(size: 12))
                                    Text(daemon.recordingHotkey ? "Listening…" : "Record Hotkey")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(daemon.recordingHotkey ? .rcAccent2 : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    daemon.recordingHotkey
                                        ? Color.rcSurfaceHi
                                        : Color.rcAccent,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.2), value: daemon.recordingHotkey)

                            Button(action: { daemon.resetHotkey() }) {
                                Text("Reset")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.rcMuted)
                                    .frame(width: 64)
                                    .padding(.vertical, 8)
                                    .background(Color.rcSurface,
                                                in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.rcBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        if daemon.recordingHotkey {
                            HStack(spacing: 6) {
                                Circle().fill(Color.rcAccent).frame(width:6,height:6)
                                Text("Press any key or mouse button…")
                                    .font(.system(size: 11))
                                    .foregroundColor(.rcAccent2)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // ── Quit disclaimer ───────────────────────────────────
                        Divider().background(Color.rcBorder)

                        HStack(spacing: 8) {
                            Image(systemName: "power")
                                .font(.system(size: 11))
                                .foregroundColor(.rcMuted)
                            Text("Press ")
                                .font(.system(size: 12))
                                .foregroundColor(.rcText2)
                            + Text("⌘Q")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.rcAccent)
                            + Text(" to fully quit MacHood")
                                .font(.system(size: 12))
                                .foregroundColor(.rcText2)
                            Spacer()
                        }
                    }
                    .padding(16)
                    .animation(.easeOut(duration: 0.2), value: daemon.recordingHotkey)
                }

                RCDivider()

                SectionLabel("Supported Inputs")
                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(Array(inputTypes.enumerated()), id: \.offset) { i, row in
                            HStack(spacing: 10) {
                                Image(systemName: row.0)
                                    .font(.system(size: 13))
                                    .foregroundColor(.rcMuted)
                                    .frame(width: 22)
                                Text(row.1)
                                    .font(.system(size: 13))
                                    .foregroundColor(.rcText2)
                                Spacer()
                                Text(row.2)
                                    .font(.system(size: 11))
                                    .foregroundColor(.rcMuted)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 42)
                            if i < inputTypes.count - 1 {
                                Divider().background(Color.rcBorder).padding(.horizontal, 12)
                            }
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }
}

// ── Shared components ─────────────────────────────────────────────────────────

struct GlassCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .background(Color.rcSurface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.rcBorder, lineWidth: 1))
    }
}

struct KbdChip: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.rcText2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.rcSurface, in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(Color.rcBorder, lineWidth: 1))
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.rcMuted)
            .padding(.horizontal, 4)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

struct RCDivider: View {
    var body: some View {
        Divider().background(Color.rcBorder).padding(.vertical, 4)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxW && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}

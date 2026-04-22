#if os(macOS)
import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: CircleState

    private var seedBinding: Binding<Color> {
        Binding(
            get: { state.palette.seed },
            set: { state.palette = Palette(color: $0) }
        )
    }

    var body: some View {
        Form {
            Picker("Animation", selection: $state.meditationAnimation) {
                ForEach(AnimationKind.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            Section("Palette") {
                ColorPicker("Seed Color", selection: seedBinding, supportsOpacity: false)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        ForEach(Palette.presets, id: \.name) { p in
                            Button {
                                state.palette = p
                            } label: {
                                Circle()
                                    .fill(p.seed)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Circle().strokeBorder(
                                            state.palette == p ? Color.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                    )
                                    .shadow(color: p.seed.opacity(0.7), radius: 4)
                            }
                            .buttonStyle(.plain)
                            .help(p.name ?? "")
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
#endif

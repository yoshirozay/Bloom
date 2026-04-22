import SwiftUI
import Combine

enum Avatar: String {
    case circle, robot, meditation
}

final class CircleState: ObservableObject {
    @Published var position: CGPoint = CGPoint(x: 400, y: 300)
    @Published var isDragging: Bool = false

    @Published var avatar: Avatar = CircleState.loadAvatar() {
        didSet { UserDefaults.standard.set(avatar.rawValue, forKey: "avatar") }
    }

    @Published var meditationShape: ShapeKind = CircleState.load(key: "meditationShape",
                                                                 default: .flower) {
        didSet { UserDefaults.standard.set(meditationShape.rawValue, forKey: "meditationShape") }
    }

    @Published var meditationAnimation: AnimationKind = CircleState.load(key: "meditationAnimation",
                                                                         default: .coherent) {
        didSet { UserDefaults.standard.set(meditationAnimation.rawValue, forKey: "meditationAnimation") }
    }

    @Published var palette: Palette = CircleState.loadPalette() {
        didSet {
            if let data = try? JSONEncoder().encode(palette) {
                UserDefaults.standard.set(data, forKey: "palette")
            }
        }
    }

    let radius: CGFloat = 90

    private static func loadAvatar() -> Avatar {
        // The app is always in meditation mode — no user-facing picker.
        // Old saved values (.circle / .robot / "breath") get normalized here.
        return .meditation
    }

    private static func load<T: RawRepresentable>(key: String, default fallback: T) -> T
        where T.RawValue == String {
        if let raw = UserDefaults.standard.string(forKey: key),
           let v = T(rawValue: raw) { return v }
        return fallback
    }

    private static func loadPalette() -> Palette {
        if let data = UserDefaults.standard.data(forKey: "palette"),
           let p = try? JSONDecoder().decode(Palette.self, from: data) {
            return p
        }
        return .default
    }
}

#if os(iOS)
import SwiftUI

/// Development harness for iterating on animations in the iOS simulator.
/// Pixel's real product is macOS-only (overlay/menu-bar app). This iOS target
/// just hosts the shared animation views full-screen so we can iterate visually.
@main
struct PixelDevApp: App {
    @StateObject private var state: CircleState = {
        let s = CircleState()
        s.avatar = .meditation
        s.meditationShape = .flower
        s.meditationAnimation = .coherent
        return s
    }()

    var body: some Scene {
        WindowGroup {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    ContentView(state: state)
                }
                .onAppear {
                    state.position = CGPoint(x: geo.size.width / 2,
                                             y: geo.size.height / 2)
                }
            }
        }
    }
}
#endif

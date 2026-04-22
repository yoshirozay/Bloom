import SwiftUI
import SceneKit

private let petalColors: [Color] = [
    .cyan, .pink, .yellow, .green, .orange, .purple, .blue, .mint
]

struct ContentView: View {
    @ObservedObject var state: CircleState
    @State private var dragStart: CGPoint?
    @State private var burstSpread: CGFloat = 0   // 0 → 1 controls outward offset
    @State private var burstGlow: CGFloat = 0     // 0 → 1 → 0 envelope for scale/opacity
    @State private var burstRotation: Double = 0  // radians, advances each tap
    @State private var circlePulse: CGFloat = 1.0 // main circle bounce
    private let avatarScene = AvatarLoader.shared

    var body: some View {
        let size = state.radius * 2
        let circleVisualSize = size * 0.5

        ZStack {
            ZStack {
                switch state.avatar {
                case .circle:
                    // Click-burst circle
                    ForEach(Array(petalColors.enumerated()), id: \.offset) { idx, color in
                        let baseAngle = Double(idx) * 2 * .pi / Double(petalColors.count)
                        let angle = baseAngle + burstRotation
                        Circle()
                            .fill(color)
                            .frame(width: 22, height: 22)
                            .shadow(color: color, radius: 8)
                            .offset(
                                x: CGFloat(cos(angle)) * 140 * burstSpread,
                                y: CGFloat(sin(angle)) * 140 * burstSpread
                            )
                            .scaleEffect(0.3 + burstGlow * 1.0)
                            .opacity(Double(burstGlow))
                            .allowsHitTesting(false)
                    }
                    Circle()
                        .fill(Color.cyan.opacity(0.9))
                        .frame(width: circleVisualSize, height: circleVisualSize)
                        .shadow(color: .cyan, radius: 15)
                        .scaleEffect(circlePulse)
                        .allowsHitTesting(false)

                case .meditation:
                    MeditationCanvas(shape: state.meditationShape,
                                     animation: state.meditationAnimation,
                                     palette: state.palette)
                        .scaleEffect(0.5)
                        .allowsHitTesting(false)

                case .robot:
                    AvatarView(avatarScene: avatarScene)
                        .allowsHitTesting(false)
                }

                Circle()
                    .fill(Color.clear)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                if dragStart == nil {
                                    dragStart = state.position
                                    state.isDragging = true
                                }
                                let origin = dragStart ?? state.position
                                var t = Transaction()
                                t.disablesAnimations = true
                                withTransaction(t) {
                                    state.position = CGPoint(
                                        x: origin.x + value.translation.width,
                                        y: origin.y + value.translation.height
                                    )
                                }
                            }
                            .onEnded { value in
                                let moved = hypot(value.translation.width, value.translation.height)
                                let wasTap = moved < 5
                                dragStart = nil
                                state.isDragging = false
                                if wasTap && state.avatar == .circle {
                                    triggerBurst()
                                }
                            }
                    )
            }
            .frame(width: size, height: size)
            .position(state.position)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private func triggerBurst() {
        // Reset petal offsets instantly (invisible already) so this tap starts clean
        burstSpread = 0
        burstGlow = 0
        burstRotation += .pi * 0.4  // rotate a bit each click for variety

        // Outward drift — slow and continuous over 1.1s
        withAnimation(.easeOut(duration: 1.1)) {
            burstSpread = 1.0
        }
        // Fade-in fast (so petals pop just as they clear the center)
        withAnimation(.easeOut(duration: 0.22)) {
            burstGlow = 1.0
        }
        // Fade-out starting 0.35s in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeIn(duration: 0.7)) {
                burstGlow = 0
            }
        }
        // After total animation completes, snap offset back (invisible at this point)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            burstSpread = 0
        }

        // Main circle: squish then bounce back
        withAnimation(.easeOut(duration: 0.1)) {
            circlePulse = 0.7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                circlePulse = 1.0
            }
        }
    }
}

struct AvatarScene {
    let scene: SCNScene
    let cameraNode: SCNNode
}

enum AvatarLoader {
    static let shared: AvatarScene? = load()

    static func load() -> AvatarScene? {
        guard let url = Bundle.main.url(forResource: "robot", withExtension: "usdz"),
              let loaded = try? SCNScene(url: url, options: nil) else {
            NSLog("AvatarLoader: USDZ not found or failed to load")
            return nil
        }

        let scene = SCNScene()
        #if os(macOS)
        scene.background.contents = NSColor.clear
        #else
        scene.background.contents = UIColor.clear
        #endif

        let modelRoot = SCNNode()
        for child in loaded.rootNode.childNodes {
            modelRoot.addChildNode(child)
            NSLog("AvatarLoader child: name=%@ childCount=%d", child.name ?? "?", child.childNodes.count)
        }
        scene.rootNode.addChildNode(modelRoot)

        let (minVec, maxVec) = modelRoot.boundingBox
        NSLog("AvatarLoader bbox min=(%.3f,%.3f,%.3f) max=(%.3f,%.3f,%.3f)",
              minVec.x, minVec.y, minVec.z, maxVec.x, maxVec.y, maxVec.z)
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        let extent = SCNVector3(
            maxVec.x - minVec.x,
            maxVec.y - minVec.y,
            maxVec.z - minVec.z
        )
        let maxDim = max(extent.x, max(extent.y, extent.z))
        let distance = maxDim * 2.2

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 40
        camera.zNear = 0.01
        camera.zFar = Double(maxDim) * 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(center.x, center.y, center.z + distance)
        cameraNode.look(at: center)
        scene.rootNode.addChildNode(cameraNode)

        return AvatarScene(scene: scene, cameraNode: cameraNode)
    }
}

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct AvatarView: PlatformViewRepresentable {
    let avatarScene: AvatarScene?

    private func makeSCNView() -> SCNView {
        let view = SCNView()
        #if os(macOS)
        view.backgroundColor = NSColor.clear
        #else
        view.backgroundColor = UIColor.clear
        #endif
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        view.isPlaying = true
        if let a = avatarScene {
            view.scene = a.scene
            view.pointOfView = a.cameraNode
        }
        return view
    }

    #if os(macOS)
    func makeNSView(context: Context) -> SCNView { makeSCNView() }
    func updateNSView(_ nsView: SCNView, context: Context) {}
    #else
    func makeUIView(context: Context) -> SCNView { makeSCNView() }
    func updateUIView(_ uiView: SCNView, context: Context) {}
    #endif
}

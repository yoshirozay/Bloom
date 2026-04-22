import SwiftUI

/// Layered organic flower: 3 rings of detailed leaves + central glowing orb + dust.
/// Drives all motion from the supplied `AnimationKind.phase(at:offset:)`.
struct FlowerShape: View {
    let animation: AnimationKind
    let palette: Palette

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let main = animation.phase(at: t)

            ZStack {
                atmosphereParticles(t: t)
                // Three layers of 8 leaves each, offset by π/12 (15°) apart so
                // all 24 leaves occupy unique evenly-spaced angular positions.
                // Every angle has exactly one leaf → uniform silhouette, no
                // single layer "poking out".
                petalLayer(t: t, count: 8, offsetAngle: 0,
                           radius: 10, petalSize: CGSize(width: 130, height: 250),
                           opacity: 0.18, colorShift: 4)
                petalLayer(t: t, count: 8, offsetAngle: .pi / 12,
                           radius: 30, petalSize: CGSize(width: 120, height: 220),
                           opacity: 0.35, colorShift: 0)
                petalLayer(t: t, count: 8, offsetAngle: .pi / 6,
                           radius: 45, petalSize: CGSize(width: 95, height: 180),
                           opacity: 0.55, colorShift: 2)
                orb(phase: main)
            }
            .scaleEffect(0.95 + CGFloat(main) * 0.10)
            .rotation3DEffect(.degrees(15 + sin(t * 0.08) * 3),
                              axis: (x: 1, y: 0.15, z: 0),
                              perspective: 0.5)
        }
    }

    // MARK: - Orb

    private func orb(phase: Double) -> some View {
        let baseSize: CGFloat = 110
        let size = baseSize + CGFloat(phase) * 30
        return Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: palette.core.opacity(0.88), location: 0.0),
                        .init(color: palette.seed.opacity(0.58), location: 0.32),
                        .init(color: palette.seed.opacity(0.22), location: 0.72),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: .center,
                    startRadius: 4,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 3)
            // Inverted glow: brighter on exhale (small), dimmer on inhale (big).
            .shadow(color: palette.seed.opacity(0.45 + (1 - phase) * 0.30),
                    radius: 40 + CGFloat(1 - phase) * 20)
            .shadow(color: palette.seed.opacity(0.25 + (1 - phase) * 0.25),
                    radius: 90 + CGFloat(1 - phase) * 35)
            .shadow(color: palette.seed.opacity(0.12 + (1 - phase) * 0.20),
                    radius: 140 + CGFloat(1 - phase) * 40)
    }

    // MARK: - Petal layers

    private func petalLayer(t: Double, count: Int, offsetAngle: Double,
                            radius: CGFloat, petalSize: CGSize,
                            opacity: Double, colorShift: Int) -> some View {
        let slowSpin = t * 0.06
        return ForEach(0..<count, id: \.self) { i in
            petal(index: i, count: count, t: t,
                  slowSpin: slowSpin, offsetAngle: offsetAngle,
                  radius: radius, petalSize: petalSize,
                  layerOpacity: opacity, colorShift: colorShift)
        }
    }

    private func petal(index i: Int, count: Int, t: Double,
                       slowSpin: Double, offsetAngle: Double,
                       radius: CGFloat, petalSize: CGSize,
                       layerOpacity: Double, colorShift: Int) -> some View {
        let angle = Double(i) * 2 * .pi / Double(count) + slowSpin + offsetAngle
        // Stagger each petal's phase so they breathe slightly out of sync.
        let phaseOffset = Double(i) * 0.14
        let localPhase = animation.phase(at: t, offset: phaseOffset)

        let bloom = CGFloat(localPhase) * 40
        let r = radius + bloom
        let scale = 0.65 + CGFloat(localPhase) * 0.70
        let color = palette.petals[(i + colorShift) % palette.petals.count]
        let dx = CGFloat(cos(angle)) * r
        let dy = CGFloat(sin(angle)) * r
        let rotJitter = sin(Double(i + colorShift) * 7.3) * (.pi / 22)
        let emphasize = ((i + colorShift) % 3) == 0

        return DetailedLeaf(color: color, layerOpacity: layerOpacity,
                            emphasizeVeins: emphasize)
            .frame(width: petalSize.width, height: petalSize.height)
            .scaleEffect(scale)
            .rotationEffect(.radians(angle + .pi / 2 + rotJitter))
            .offset(x: dx, y: dy)
            .opacity(0.55 + localPhase * 0.45)
    }

    // MARK: - Floating atmosphere particles

    private func atmosphereParticles(t: Double) -> some View {
        ForEach(0..<8, id: \.self) { i in
            particle(index: i, t: t)
        }
    }

    private func particle(index i: Int, t: Double) -> some View {
        let seed = Double(i) * 1.618
        let baseAngle = seed * 2 * .pi
        let driftSpeed = 0.06 + (seed.truncatingRemainder(dividingBy: 1)) * 0.04
        let radiusRange: CGFloat = 90 + CGFloat((seed.truncatingRemainder(dividingBy: 1)) * 160)
        let angle = baseAngle + t * driftSpeed
        let radius = radiusRange + CGFloat(sin(t * 0.3 + seed * 2) * 20)
        let dx = CGFloat(cos(angle)) * radius
        let dy = CGFloat(sin(angle)) * radius
        let twinkle = (sin(t * 0.6 + seed * 3) + 1) / 2
        let size: CGFloat = 1.2 + CGFloat((seed.truncatingRemainder(dividingBy: 2)) * 1.5)
        let alpha = 0.12 + twinkle * 0.32

        return Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .shadow(color: palette.seed.opacity(0.6), radius: 3)
            .blur(radius: 1.2)
            .opacity(alpha)
            .offset(x: dx, y: dy)
    }
}

// MARK: - Leaf primitives

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width
            let h = rect.height
            p.move(to: CGPoint(x: w * 0.5, y: h))
            p.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                       control1: CGPoint(x: w * 1.02, y: h * 0.70),
                       control2: CGPoint(x: w * 0.58, y: h * 0.03))
            p.addCurve(to: CGPoint(x: w * 0.5, y: h),
                       control1: CGPoint(x: w * 0.42, y: h * 0.03),
                       control2: CGPoint(x: w * -0.02, y: h * 0.70))
            p.closeSubpath()
        }
    }
}

struct LeafVeins: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width
            let h = rect.height
            p.move(to: CGPoint(x: w * 0.5, y: h * 0.96))
            p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.08))
            let yPositions: [CGFloat] = [0.75, 0.55, 0.35]
            for y in yPositions {
                let sy = h * y
                let ty = h * (y - 0.12)
                p.move(to: CGPoint(x: w * 0.5, y: sy))
                p.addQuadCurve(to: CGPoint(x: w * 0.82, y: ty),
                               control: CGPoint(x: w * 0.70, y: sy - h * 0.02))
                p.move(to: CGPoint(x: w * 0.5, y: sy))
                p.addQuadCurve(to: CGPoint(x: w * 0.18, y: ty),
                               control: CGPoint(x: w * 0.30, y: sy - h * 0.02))
            }
        }
    }
}

struct DetailedLeaf: View {
    let color: Color
    let layerOpacity: Double
    var emphasizeVeins: Bool = false

    var body: some View {
        ZStack {
            LeafShape()
                .fill(color.opacity(layerOpacity * 0.9))
                .blur(radius: 6)
            LeafShape()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(layerOpacity * 1.1),
                            color.opacity(layerOpacity * 0.55),
                            color.opacity(layerOpacity * 0.25),
                            .clear
                        ],
                        startPoint: .bottom, endPoint: .top)
                )
            LeafVeins()
                .stroke(Color.white.opacity(layerOpacity * (emphasizeVeins ? 0.6 : 0.3)),
                        lineWidth: emphasizeVeins ? 0.9 : 0.5)
            LeafShape()
                .stroke(color.opacity(layerOpacity * 0.7), lineWidth: 0.6)
        }
        // Fade the stem end (bottom) to transparent so the leaves' base
        // points don't show as defined edges where they overlap at the center.
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.18),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .bottom, endPoint: .top
            )
        )
        .drawingGroup()
    }
}

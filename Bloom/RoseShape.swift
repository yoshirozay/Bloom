import SwiftUI

/// Six polar rose curves (r = cos(k·θ)) stacked at different k values
/// and palette colors, with additive blend mode so overlaps mix like light.
struct RoseShape: View {
    let animation: AnimationKind
    let palette: Palette

    /// Each rose: petal multiplier k, stroke width, rotation speed (rad/s), size fraction.
    private let roses: [(k: Double, lineWidth: CGFloat, speed: Double, scale: CGFloat)] = [
        (3, 2.4, 0.08, 0.55),
        (5, 2.0, -0.055, 0.70),
        (7, 1.6, 0.065, 0.85),
        (4, 2.2, -0.045, 0.62),
        (6, 1.8, 0.075, 0.78),
        (8, 1.4, -0.035, 0.95),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let mainPhase = animation.phase(at: t)

            ZStack {
                ambientGlow()
                roseLayers(t: t)
                coreGlow(phase: mainPhase)
            }
            .compositingGroup()   // required so plusLighter composes across all children
            .rotation3DEffect(.degrees(12 + sin(t * 0.06) * 2.5),
                              axis: (x: 0.8, y: 0.2, z: 0),
                              perspective: 0.5)
        }
    }

    // MARK: - Layers

    private func ambientGlow() -> some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.seed.opacity(0.18), location: 0.0),
                    .init(color: palette.seed.opacity(0.08), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center, startRadius: 20, endRadius: 300
            ))
            .frame(width: 600, height: 600)
            .blur(radius: 30)
            .blendMode(.plusLighter)
    }

    private func roseLayers(t: Double) -> some View {
        ForEach(0..<roses.count, id: \.self) { i in
            roseLayer(index: i, t: t)
        }
    }

    private func roseLayer(index i: Int, t: Double) -> some View {
        let rose = roses[i]
        let color = palette.petals[i % palette.petals.count]
        let rotation = t * rose.speed
        let localPhase = animation.phase(at: t, offset: Double(i) * 0.3)
        let breathScale = 0.86 + CGFloat(localPhase) * 0.26
        let baseSize: CGFloat = 280 * rose.scale

        return RoseCurve(k: rose.k)
            .stroke(
                AngularGradient(
                    gradient: Gradient(stops: [
                        .init(color: color.opacity(0.9), location: 0.0),
                        .init(color: color.opacity(0.5), location: 0.3),
                        .init(color: color.opacity(0.95), location: 0.5),
                        .init(color: color.opacity(0.5), location: 0.7),
                        .init(color: color.opacity(0.9), location: 1.0)
                    ]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: rose.lineWidth, lineCap: .round, lineJoin: .round)
            )
            .frame(width: baseSize, height: baseSize)
            .shadow(color: color.opacity(0.6), radius: 8)
            .rotationEffect(.radians(rotation))
            .scaleEffect(breathScale)
            .blendMode(.plusLighter)
    }

    private func coreGlow(phase: Double) -> some View {
        let size: CGFloat = 55 + CGFloat(phase) * 10
        return Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.core.opacity(0.85), location: 0.0),
                    .init(color: palette.seed.opacity(0.45), location: 0.45),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center, startRadius: 2, endRadius: size / 2
            ))
            .frame(width: size, height: size)
            .blur(radius: 2)
            .blendMode(.plusLighter)
    }
}

// MARK: - Polar rose curve shape

/// r = cos(k · θ) — for integer k: even → 2k petals, odd → k petals.
struct RoseCurve: Shape {
    let k: Double

    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let maxR = min(rect.width, rect.height) / 2
            // Enough samples for a visually smooth curve at our scale.
            let steps = 720
            for i in 0...steps {
                let theta = Double(i) / Double(steps) * 2 * .pi
                let r = maxR * CGFloat(cos(k * theta))
                let x = center.x + r * CGFloat(cos(theta))
                let y = center.y + r * CGFloat(sin(theta))
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

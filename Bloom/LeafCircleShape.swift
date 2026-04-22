import SwiftUI

/// A circle made of leaves: 24 leaves spaced evenly around a circle's
/// circumference, each oriented tangent to the circle (tip following the
/// direction of travel) rather than radiating outward. Result reads as a
/// wreath/ring — visually distinct from Flower despite sharing leaf DNA.
///
/// Math:
///   - Leaf i sits at angle θ_i = i · 2π/N on the circle of radius R
///   - Leaf rotation = θ_i + π (so the tip points along the tangent)
///   - The whole ring rotates slowly (~4 minutes per full revolution)
struct LeafCircleShape: View {
    let animation: AnimationKind
    let palette: Palette

    private let leafCount = 24
    private let baseRadius: CGFloat = 125

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let mainPhase = animation.phase(at: t)

            ZStack {
                ambientGlow()
                ForEach(0..<leafCount, id: \.self) { i in
                    leafAt(index: i, t: t, mainPhase: mainPhase)
                }
            }
            // Gentle whole-ring rotation — about one turn every 4 minutes.
            .rotationEffect(.radians(t * 0.025))
            .rotation3DEffect(.degrees(12 + sin(t * 0.05) * 2.5),
                              axis: (x: 1, y: 0.15, z: 0),
                              perspective: 0.5)
        }
    }

    // MARK: - Leaf

    private func leafAt(index i: Int, t: Double, mainPhase: Double) -> some View {
        let angle = Double(i) * 2 * .pi / Double(leafCount)

        // Per-leaf stagger so the ring breathes with a subtle wave.
        let phaseOffset = Double(i) * 0.05
        let localPhase = animation.phase(at: t, offset: phaseOffset)

        let r = baseRadius + CGFloat(mainPhase) * 22
        let dx = CGFloat(cos(angle)) * r
        let dy = CGFloat(sin(angle)) * r

        // Tangent-direction rotation — leaves lie along the ring's path.
        let tangentRotation = angle + .pi

        let color = palette.petals[i % palette.petals.count]
        let leafScale: CGFloat = 0.88 + CGFloat(localPhase) * 0.20
        let opacity = 0.55 + localPhase * 0.40

        return DetailedLeaf(color: color,
                            layerOpacity: 0.55,
                            emphasizeVeins: i % 3 == 0)
            .frame(width: 38, height: 90)
            .scaleEffect(leafScale)
            .rotationEffect(.radians(tangentRotation))
            .offset(x: dx, y: dy)
            .opacity(opacity)
    }

    private func ambientGlow() -> some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.seed.opacity(0.13), location: 0),
                    .init(color: palette.seed.opacity(0.05), location: 0.5),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 30, endRadius: 280
            ))
            .frame(width: 560, height: 560)
            .blur(radius: 28)
    }
}

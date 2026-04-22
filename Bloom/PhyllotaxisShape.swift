import SwiftUI

/// Phyllotaxis: leaves arranged at the golden angle (~137.507°) with radial
/// distance = c · √i. This is the exact pattern nature uses for sunflower
/// seeds, pinecones, and pineapples — emerges from pure number theory (a
/// consequence of the golden ratio being the "most irrational" number, so
/// no two leaves end up at coincident angles).
///
/// Same leaf shape as Flower — this preset shares Flower's DNA but
/// re-arranges the elements into a mathematical spiral rather than concentric
/// rings. Inner leaves are smaller, outer larger, overlapping enough that
/// translucent fills compound where they meet.
struct PhyllotaxisShape: View {
    let animation: AnimationKind
    let palette: Palette

    /// Golden angle in radians ≈ 2.39996 rad ≈ 137.507°.
    private let goldenAngle: Double = .pi * (3 - sqrt(5.0))

    /// Number of leaves in the spiral. Fibonacci, drastically fewer than
    /// a full seed head so each leaf is individually visible along its spiral.
    private let leafCount = 13

    /// Radial spacing constant (points per √i step) — chosen so the
    /// outermost leaf sits at ~150pt radius, matching Flower's scale.
    private let spacing: CGFloat = 42

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
            .rotation3DEffect(.degrees(12 + sin(t * 0.05) * 2.5),
                              axis: (x: 0.8, y: 0.2, z: 0),
                              perspective: 0.5)
        }
    }

    // MARK: - Leaf

    private func leafAt(index i: Int, t: Double, mainPhase: Double) -> some View {
        // Start from i=1 so no leaf sits at the exact center of the spiral.
        let idx = i + 1
        let angle = Double(idx) * goldenAngle
        let baseRadius = spacing * sqrt(CGFloat(idx))

        // Phase ripple: outer leaves lag slightly.
        let phaseOffset = Double(i) * 0.06
        let localPhase = animation.phase(at: t, offset: phaseOffset)

        // Whole spiral breathes in/out.
        let spiralScale: CGFloat = 0.88 + CGFloat(mainPhase) * 0.20
        let r = baseRadius * spiralScale

        // Leaves all the same size (matching Flower's mid-layer feel).
        let leafScale: CGFloat = 0.85 + CGFloat(localPhase) * 0.25

        // Slow whole-spiral rotation.
        let slowSpin = t * 0.04
        let positionAngle = angle + slowSpin

        let dx = CGFloat(cos(positionAngle)) * r
        let dy = CGFloat(sin(positionAngle)) * r

        let color = palette.petals[i % palette.petals.count]
        let opacity = 0.55 + localPhase * 0.4

        // Reuse DetailedLeaf + Flower's mid-layer dimensions — same DNA,
        // same visual weight as each individual flower leaf.
        return DetailedLeaf(color: color,
                            layerOpacity: 0.55,
                            emphasizeVeins: i % 3 == 0)
            .frame(width: 120, height: 220)
            .scaleEffect(leafScale)
            .rotationEffect(.radians(positionAngle + .pi / 2))  // tip points outward
            .offset(x: dx, y: dy)
            .opacity(opacity)
    }

    private func ambientGlow() -> some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.seed.opacity(0.14), location: 0),
                    .init(color: palette.seed.opacity(0.05), location: 0.5),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 30, endRadius: 280
            ))
            .frame(width: 560, height: 560)
            .blur(radius: 28)
    }
}

import SwiftUI

/// S-path: the circle's "circumference" unrolled and re-curved into a vertical S.
/// Leaves sit along the S path, each rotated to align with the tangent direction.
/// Breath phase propagates up the path (wave travels from bottom to top and back)
/// — matches "goes up, hits the top, comes back down the same way."
///
/// Math:
///   - x(s) = A · sin((2s − 1)·π)       horizontal sway
///   - y(s) = (0.5 − s) · H             vertical, bottom (s=0) to top (s=1)
///   - Tangent: (dx/ds, dy/ds) = (2πA · cos((2s−1)π), −H)
///   - Leaf rotation = tangentAngle + π/2 (aligns leaf tip with forward direction)
struct LeafSShape: View {
    let animation: AnimationKind
    let palette: Palette

    private let leafCount = 18
    private let amplitude: CGFloat = 70     // horizontal sway
    private let pathHeight: CGFloat = 380   // total vertical extent

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ambientGlow()
                ForEach(0..<leafCount, id: \.self) { i in
                    leafAt(index: i, t: t)
                }
            }
            // Slight forward tilt (top of S leans away from viewer) — the
            // "faces the sky" perspective.
            .rotation3DEffect(.degrees(14 + sin(t * 0.05) * 2),
                              axis: (x: 1, y: 0.1, z: 0),
                              perspective: 0.5)
        }
    }

    // MARK: - Leaf

    /// How much of the path the leaf group occupies at any moment (as a
    /// fraction of total path length).
    private let segmentLength: Double = 0.5

    private func leafAt(index i: Int, t: Double) -> some View {
        let mainPhase = animation.phase(at: t)
        // Tiny per-leaf phase offset so neighbors aren't perfectly rigid.
        let phaseOffset = Double(i) * 0.03
        let localPhase = animation.phase(at: t, offset: phaseOffset)

        // Leaf's base position within the segment: spread evenly from 0 to segmentLength.
        let baseSInSegment = Double(i) / Double(leafCount - 1) * segmentLength

        // The whole segment slides up the path as we inhale, back down on exhale.
        // travelRange = 1 − segmentLength, so the segment sweeps the full path.
        let travelRange = 1.0 - segmentLength
        let s = baseSInSegment + mainPhase * travelRange

        // S-curve position at current s (recomputed every frame as the leaf moves).
        let x = Double(amplitude) * sin((2 * s - 1) * .pi)
        let y = (0.5 - s) * Double(pathHeight)

        // Tangent at the CURRENT s — leaf rotates as it travels, aligning with
        // the local path direction.
        let dxds = Double(amplitude) * cos((2 * s - 1) * .pi) * 2 * .pi
        let dyds = -Double(pathHeight)
        let tangentAngle = atan2(dyds, dxds)
        let leafRotation = .pi / 2 + tangentAngle

        let color = palette.petals[i % palette.petals.count]
        // Subtle secondary breathing on top of the travel motion.
        let leafScale: CGFloat = 0.92 + CGFloat(localPhase) * 0.12
        let opacity = 0.72 + localPhase * 0.22

        return DetailedLeaf(color: color,
                            layerOpacity: 0.55,
                            emphasizeVeins: i % 3 == 0)
            .frame(width: 38, height: 90)
            .scaleEffect(leafScale)
            .rotationEffect(.radians(leafRotation))
            .offset(x: CGFloat(x), y: CGFloat(y))
            .opacity(opacity)
    }

    private func ambientGlow() -> some View {
        // Elongated vertical glow matching the S's footprint.
        Ellipse()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.seed.opacity(0.12), location: 0),
                    .init(color: palette.seed.opacity(0.04), location: 0.55),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 20, endRadius: 280
            ))
            .frame(width: 320, height: 520)
            .blur(radius: 26)
    }
}

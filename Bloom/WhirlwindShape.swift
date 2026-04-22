import SwiftUI

/// Whirlwind: leaves scatter outward on inhale, collapse on exhale.
/// Each leaf spirals as it moves out (position follows a spiral path), and
/// each rotates on its own axis continuously — like autumn leaves in wind.
/// Math:
///   • Radial position r = minR + localPhase · (maxR − minR)
///   • Spiral twist: angle = baseAngle + localPhase · twistAmount
///   • Self-rotation: t · spinSpeed (independent of breath, for wind feel)
struct WhirlwindShape: View {
    let animation: AnimationKind
    let palette: Palette

    private let leafCount = 14
    private let minRadius: CGFloat = 15
    private let maxRadius: CGFloat = 160
    private let twistAmount: Double = 1.2     // radians of spiral twist at full scatter

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let mainPhase = animation.phase(at: t)

            ZStack {
                atmosphere()
                ForEach(0..<leafCount, id: \.self) { i in
                    leaf(index: i, t: t)
                }
                centerOrb(phase: mainPhase)
            }
        }
    }

    // MARK: - Atmosphere

    private func atmosphere() -> some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.seed.opacity(0.15), location: 0),
                    .init(color: palette.seed.opacity(0.05), location: 0.5),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 20, endRadius: 220
            ))
            .frame(width: 440, height: 440)
            .blur(radius: 24)
    }

    // MARK: - Leaves

    private func leaf(index i: Int, t: Double) -> some View {
        let angleStep = 2 * .pi / Double(leafCount)
        let baseAngle = Double(i) * angleStep

        // Staggered per-leaf breath so they don't scatter as a rigid ring.
        let phaseOffset = Double(i) * 0.1
        let localPhase = animation.phase(at: t, offset: phaseOffset)

        let r = minRadius + CGFloat(localPhase) * (maxRadius - minRadius)
        let spiralAngle = baseAngle + localPhase * twistAmount
        let dx = CGFloat(cos(spiralAngle)) * r
        let dy = CGFloat(sin(spiralAngle)) * r

        // Continuous wind-like spin, independent of breath — this is what makes
        // it feel like wind rather than a breathing flower.
        let spinSpeed = 0.45 + Double(i) * 0.025
        let selfRotation = t * spinSpeed + Double(i) * 0.7

        let scale = 0.55 + CGFloat(localPhase) * 0.55
        let alpha = 0.18 + localPhase * 0.78
        let color = palette.petals[i % palette.petals.count]

        return LeafShape()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.85), color.opacity(0.35), .clear],
                    startPoint: .bottom, endPoint: .top
                )
            )
            .frame(width: 18, height: 58)
            .shadow(color: color.opacity(0.7), radius: 5)
            .blur(radius: 0.6)
            .rotationEffect(.radians(selfRotation))
            .offset(x: dx, y: dy)
            .scaleEffect(scale)
            .opacity(alpha)
    }

    // MARK: - Center orb

    private func centerOrb(phase: Double) -> some View {
        let baseSize: CGFloat = 55
        return Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.core.opacity(0.85), location: 0.0),
                    .init(color: palette.seed.opacity(0.45), location: 0.45),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center, startRadius: 2, endRadius: baseSize / 2
            ))
            .frame(width: baseSize, height: baseSize)
            .blur(radius: 2)
            // Orb is brightest when leaves are close (exhale). As they scatter,
            // it fades — inversion of the flower, gives whirlwind its own rhythm.
            .opacity(1 - phase * 0.55)
            .shadow(color: palette.seed.opacity(0.5 + (1 - phase) * 0.3),
                    radius: 25 + CGFloat(1 - phase) * 15)
    }
}

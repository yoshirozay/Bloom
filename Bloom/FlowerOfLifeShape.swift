import SwiftUI

/// Flower of Life: 19 overlapping circles in a hexagonal lattice — the
/// defining sacred geometry pattern. Each circle has a translucent gradient
/// fill + a hue-cycling angular-gradient stroke; overlapping circles
/// compound colors at their vesica piscis intersections (the heart of
/// the pattern's visual depth). Breath ripples outward from the center.
///
/// Lattice math: every circle has radius R and centers are spaced R apart
/// in a hex lattice, so every circle passes through the center of each
/// adjacent circle. This is the algebraic property that defines the shape.
struct FlowerOfLifeShape: View {
    let animation: AnimationKind
    let palette: Palette

    /// Radius of each individual circle (points).
    private let circleR: CGFloat = 42

    /// 19 hex-lattice center positions, in units of circleR.
    /// Order starts at the center and spirals outward so the breath ripple
    /// (phase offset = distance from center) lights the center first.
    private var lattice: [CGPoint] {
        let s = CGFloat(sqrt(3.0) / 2)  // vertical row spacing in units
        return [
            // Center
            CGPoint(x: 0, y: 0),
            // Inner ring (Seed of Life): 6 circles at distance 1
            CGPoint(x:  1, y: 0),
            CGPoint(x:  0.5, y: -s),
            CGPoint(x: -0.5, y: -s),
            CGPoint(x: -1, y: 0),
            CGPoint(x: -0.5, y:  s),
            CGPoint(x:  0.5, y:  s),
            // Second ring (12 circles) — in the standard 19-circle FoL.
            CGPoint(x:  2, y: 0),
            CGPoint(x:  1.5, y: -s),
            CGPoint(x:  1, y: -2*s),
            CGPoint(x:  0, y: -2*s),
            CGPoint(x: -1, y: -2*s),
            CGPoint(x: -1.5, y: -s),
            CGPoint(x: -2, y: 0),
            CGPoint(x: -1.5, y:  s),
            CGPoint(x: -1, y:  2*s),
            CGPoint(x:  0, y:  2*s),
            CGPoint(x:  1, y:  2*s),
            CGPoint(x:  1.5, y:  s),
        ]
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let mainPhase = animation.phase(at: t)

            ZStack {
                ambientGlow()
                ForEach(0..<lattice.count, id: \.self) { i in
                    circleLayer(index: i, t: t)
                }
                coreGlow(phase: mainPhase)
            }
            .compositingGroup()
            .rotation3DEffect(.degrees(10 + sin(t * 0.05) * 2),
                              axis: (x: 0.7, y: 0.2, z: 0),
                              perspective: 0.5)
        }
    }

    // MARK: - Circle layer

    private func circleLayer(index i: Int, t: Double) -> some View {
        let pos = lattice[i]
        let distFromCenter = sqrt(Double(pos.x * pos.x + pos.y * pos.y))
        // Breath ripples outward: center leads, outer lags. ~0.25s per ring.
        let phaseOffset = distFromCenter * 0.4
        let localPhase = animation.phase(at: t, offset: phaseOffset)

        let color = palette.petals[i % palette.petals.count]
        let breathScale = 0.93 + CGFloat(localPhase) * 0.12
        let breathOpacity = 0.75 + localPhase * 0.25

        return ZStack {
            // Translucent fill (Flower DNA — layers compound when overlapping)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: color.opacity(0.28), location: 0.0),
                            .init(color: color.opacity(0.10), location: 0.65),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .center, startRadius: 2, endRadius: circleR
                    )
                )
            // Hue-cycling stroke (reference DNA)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: hueCycle()),
                        center: .center
                    ),
                    lineWidth: 1.3
                )
        }
        .frame(width: circleR * 2, height: circleR * 2)
        .offset(x: pos.x * circleR, y: pos.y * circleR)
        .scaleEffect(breathScale)
        .opacity(breathOpacity)
        .shadow(color: color.opacity(0.55), radius: 4)
        .shadow(color: color.opacity(0.20), radius: 12)
        .blendMode(.plusLighter)
    }

    // MARK: - Supporting layers

    private func ambientGlow() -> some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.seed.opacity(0.15), location: 0),
                    .init(color: palette.seed.opacity(0.05), location: 0.5),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 30, endRadius: 280
            ))
            .frame(width: 560, height: 560)
            .blur(radius: 28)
            .blendMode(.plusLighter)
    }

    private func coreGlow(phase: Double) -> some View {
        let size: CGFloat = 24 + CGFloat(phase) * 8
        return Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.core.opacity(0.8), location: 0),
                    .init(color: palette.seed.opacity(0.35), location: 0.5),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 1, endRadius: size / 2
            ))
            .frame(width: size, height: size)
            .blur(radius: 1)
            .blendMode(.plusLighter)
    }

    private func hueCycle() -> [Color] {
        var c = palette.petals
        if let first = c.first { c.append(first) }
        return c
    }
}

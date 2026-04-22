import SwiftUI

/// Morphing Polygon: 4 stacked translucent polygons, each smoothly morphing
/// between a low and high vertex count as the breath phase evolves.
/// Overlapping translucent fills compound colors where they intersect
/// (additive blend), creating depth through layering — the "Flower vibe"
/// applied to pure geometry.
///
/// The morph math interpolates the *radius function* of a regular polygon
/// at each angle θ, producing a truly continuous transformation (not a
/// cross-fade). At t=0 you see sidesA; at t=1 you see sidesB.
struct MorphingPolygonShape: View {
    let animation: AnimationKind
    let palette: Palette

    /// Each layer has its own morph range, size, rotation, and amplitude of
    /// breath response — the breath propagates through layers differently.
    /// (minSides, maxSides, radius, rotationOffset, rotationSpeed,
    ///  colorIdx, scaleAmplitude, phaseOffset)
    private let layers: [(lo: Int, hi: Int, radius: CGFloat, baseRot: Double,
                          speed: Double, colorIdx: Int, scaleAmp: CGFloat, phaseOffset: Double)] = [
        (3,  9, 90,  0,          0.04,  0, 0.25, 0.00),
        (4, 10, 125, .pi / 8,   -0.030, 2, 0.12, 0.20),
        (5, 11, 160, .pi / 6,    0.025, 3, 0.08, 0.40),
        (6, 12, 200, .pi / 12,  -0.020, 5, 0.15, 0.60),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let mainPhase = animation.phase(at: t)

            ZStack {
                ambientGlow()
                ForEach(0..<layers.count, id: \.self) { i in
                    polygonLayer(index: i, t: t)
                }
                coreGlow(phase: mainPhase)
            }
            .compositingGroup()   // required so plusLighter composes across children
        }
    }

    // MARK: - Layers

    private func polygonLayer(index i: Int, t: Double) -> some View {
        let layer = layers[i]
        let localPhase = animation.phase(at: t, offset: layer.phaseOffset)
        let rotation = layer.baseRot + t * layer.speed
        // Per-layer breath amplitude — different layers respond differently.
        let breathScale: CGFloat = 1.0 + (CGFloat(localPhase) - 0.5) * layer.scaleAmp * 2
        // Base color drives the glow hue for this layer.
        let baseColor = palette.petals[layer.colorIdx % palette.petals.count]

        let shape = MorphingPolygon(sidesA: Double(layer.lo),
                                    sidesB: Double(layer.hi),
                                    t: localPhase)

        return ZStack {
            // Subtle translucent fill (the Flower layering DNA)
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            baseColor.opacity(0.28),
                            baseColor.opacity(0.12),
                            baseColor.opacity(0.04)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            // Hue-cycling stroke (the reference image DNA)
            shape
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: hueCycle()),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(width: layer.radius * 2, height: layer.radius * 2)
        .rotationEffect(.radians(rotation))
        .scaleEffect(breathScale)
        // Glow stack: tight bright bloom + wider soft atmosphere
        .shadow(color: baseColor.opacity(0.6), radius: 4)
        .shadow(color: baseColor.opacity(0.25), radius: 16)
        .blendMode(.plusLighter)
    }

    /// Full palette sweep as an angular gradient ring — same colors cycle
    /// continuously around each polygon's perimeter, meaning hue shifts
    /// through the palette as you trace around the stroke.
    private func hueCycle() -> [Color] {
        var colors = palette.petals
        // Close the loop so the gradient doesn't have a visible seam.
        if let first = colors.first { colors.append(first) }
        return colors
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
            .blendMode(.plusLighter)
    }

    private func coreGlow(phase: Double) -> some View {
        let size: CGFloat = 50 + CGFloat(phase) * 12
        return Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.core.opacity(0.82), location: 0),
                    .init(color: palette.seed.opacity(0.35), location: 0.5),
                    .init(color: .clear, location: 1)
                ]),
                center: .center, startRadius: 2, endRadius: size / 2
            ))
            .frame(width: size, height: size)
            .blur(radius: 2)
            .blendMode(.plusLighter)
    }
}

// MARK: - Shape

/// Smooth morph between two regular polygons via radius-function interpolation.
/// For each angle θ, we compute r_A(θ) and r_B(θ) — the radii of each polygon
/// at that angle — and lerp by `t`. The boundary sweeps through every
/// intermediate form continuously; no cross-fade, no ghosting.
struct MorphingPolygon: Shape {
    let sidesA: Double   // integer at animation endpoints
    let sidesB: Double
    let t: Double        // 0..1 interpolation

    func path(in rect: CGRect) -> Path {
        Path { p in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let R = Double(min(rect.width, rect.height) / 2)
            let steps = 360

            for i in 0...steps {
                let theta = Double(i) / Double(steps) * 2 * .pi
                let rA = R * regularPolygonRadius(theta: theta, sides: sidesA)
                let rB = R * regularPolygonRadius(theta: theta, sides: sidesB)
                let r = rA * (1 - t) + rB * t
                let x = center.x + CGFloat(r * cos(theta))
                let y = center.y + CGFloat(r * sin(theta))
                if i == 0 {
                    p.move(to: CGPoint(x: x, y: y))
                } else {
                    p.addLine(to: CGPoint(x: x, y: y))
                }
            }
            p.closeSubpath()
        }
    }

    /// Radius of a regular polygon with `sides` sides at angle θ (normalized so
    /// the circumradius = 1). `sides` must be >= 3 for the formula to be valid.
    private func regularPolygonRadius(theta: Double, sides: Double) -> Double {
        let halfSideAngle = .pi / sides
        let period = 2 * halfSideAngle
        var sector = theta.truncatingRemainder(dividingBy: period)
        if sector < 0 { sector += period }
        let alpha = sector - halfSideAngle
        return cos(halfSideAngle) / cos(alpha)
    }
}

import SwiftUI

/// Single entry point for rendering a meditation visual: picks the shape,
/// supplies the animation + palette. Everything orthogonal.
struct MeditationCanvas: View {
    let shape: ShapeKind
    let animation: AnimationKind
    let palette: Palette

    var body: some View {
        switch shape {
        case .flower:
            FlowerShape(animation: animation, palette: palette)
        // case .rose:            RoseShape(animation: animation, palette: palette)
        // case .whirlwind:       WhirlwindShape(animation: animation, palette: palette)
        // case .morphingPolygon: MorphingPolygonShape(animation: animation, palette: palette)
        // case .flowerOfLife:    FlowerOfLifeShape(animation: animation, palette: palette)
        // case .phyllotaxis:     PhyllotaxisShape(animation: animation, palette: palette)
        // case .leafCircle:      LeafCircleShape(animation: animation, palette: palette)
        // case .leafS:           LeafSShape(animation: animation, palette: palette)
        }
    }
}

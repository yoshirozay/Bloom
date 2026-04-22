import Foundation

/// A breathing rhythm. Each kind returns a 0→1 phase value representing
/// the inhale/exhale cycle. 0 = fully exhaled, 1 = fully inhaled.
/// All five are evidence-based breathing practices.
/// A breathing rhythm suitable for continuous ambient use (all day).
/// Every rhythm is a smooth sine or gentle asymmetric curve — no holds,
/// no intense protocols. User picks the pace that fits their headspace.
enum AnimationKind: String, CaseIterable, Codable {
    case natural, soft, coherent, resonant, gentle

    /// The rhythm written in human terms.
    var displayName: String {
        switch self {
        case .natural:  return "3s in · 3s out"
        case .soft:     return "4s in · 4s out"
        case .coherent: return "5s in · 5s out"
        case .resonant: return "6s in · 6s out"
        case .gentle:   return "4s in · 6s out"
        }
    }

    /// Total cycle duration (seconds).
    var cycleDuration: Double {
        switch self {
        case .natural:  return 6.0    // 10 bpm — barely slower than normal resting breath
        case .soft:     return 8.0    // ~7.5 bpm — comfortable slowdown
        case .coherent: return 10.0   // 6 bpm — standard coherent breathing
        case .resonant: return 12.0   // 5 bpm — HRV-optimal
        case .gentle:   return 10.0   // 4s in + 6s out — parasympathetic bias
        }
    }

    /// Returns 0..1 phase for the given time + optional per-element offset.
    /// 0 = fully exhaled, 1 = fully inhaled. Smooth cosine easing everywhere.
    func phase(at time: Double, offset: Double = 0) -> Double {
        let cycle = cycleDuration
        var t = (time + offset).truncatingRemainder(dividingBy: cycle)
        if t < 0 { t += cycle }

        switch self {
        case .natural, .soft, .coherent, .resonant:
            // Symmetric sine: inhale and exhale take equal time.
            return (sin(t * 2 * .pi / cycle - .pi / 2) + 1) / 2

        case .gentle:
            // 4s inhale, 6s exhale, cosine-eased.
            let inhale = 4.0
            let exhale = 6.0
            if t < inhale {
                let p = t / inhale
                return (1 - cos(p * .pi)) / 2     // 0 → 1
            } else {
                let p = (t - inhale) / exhale
                return (1 + cos(p * .pi)) / 2     // 1 → 0
            }
        }
    }
}

/// Which shape to render. Shapes read `AnimationKind.phase(at:offset:)`
/// and `Palette` to produce their own visual character.
enum ShapeKind: String, CaseIterable, Codable {
    case flower
    // Other shapes kept as files but not exposed — re-enable by adding cases here
    // and in MeditationCanvas.
    // case rose, whirlwind, morphingPolygon, flowerOfLife, phyllotaxis, leafCircle, leafS

    var displayName: String {
        switch self {
        case .flower: return "Flower"
        }
    }
}

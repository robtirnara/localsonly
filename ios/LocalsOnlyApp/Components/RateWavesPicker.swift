import SwiftUI

/// Wave score control: drag anywhere across the row for 1.0–10.0 (0.1 steps); waves fill progressively.
struct RateWavesPicker: View {
    @Binding var score: Double

    private let waveCount = 5
    private let wavePointSize: CGFloat = 44
    private let minScore = 1.0
    private let maxScore = 10.0

    @State private var lastHapticTick: Int = -1

    var body: some View {
        VStack(spacing: 0) {
            Text("How was it? 🌊")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.feedCanvasInk)
                .padding(.bottom, 16)

            GeometryReader { geo in
                HStack(spacing: 8) {
                    ForEach(0..<waveCount, id: \.self) { index in
                        Image(systemName: "water.waves")
                            .font(.system(size: wavePointSize, weight: waveFillAmount(for: index) > 0.5 ? .bold : .regular))
                            .foregroundStyle(waveColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateScore(fromX: value.location.x, width: geo.size.width)
                        }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Rating score")
                .accessibilityValue(String(format: "%.1f out of 10", score))
                .accessibilityAdjustableAction { direction in
                    let step = 0.1
                    switch direction {
                    case .increment:
                        score = min(maxScore, (score + step * 10).rounded() / 10)
                    case .decrement:
                        score = max(minScore, (score - step * 10).rounded() / 10)
                    @unknown default:
                        break
                    }
                }
            }
            .frame(height: wavePointSize + 4)

            Text(String(format: "%.1f / 10", score))
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.feedCanvasOcean)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func waveFillAmount(for index: Int) -> Double {
        let span = maxScore / Double(waveCount)
        let start = Double(index) * span
        return min(1, max(0, (score - start) / span))
    }

    private func waveColor(for index: Int) -> Color {
        let fill = waveFillAmount(for: index)
        if fill >= 0.92 { return Color.feedCanvasOcean }
        if fill >= 0.08 { return Color.feedCanvasOcean.opacity(0.55) }
        return Color.gray.opacity(0.35)
    }

    private func updateScore(fromX x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let fraction = min(1, max(0, x / width))
        let raw = minScore + Double(fraction) * (maxScore - minScore)
        let stepped = (raw * 10).rounded() / 10
        let clamped = min(maxScore, max(minScore, stepped))
        if abs(clamped - score) > 0.001 {
            score = clamped
            let tick = Int(clamped * 10)
            if tick != lastHapticTick {
                lastHapticTick = tick
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

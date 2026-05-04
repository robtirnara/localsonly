import SwiftUI

struct ScoreSlider: View {
    @Binding var value: Double
    @State private var lastTick: Int = 80

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Your Score")
                    .font(.bodyCopy)
                    .foregroundStyle(Color.coastalTextSecondary)
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(.sectionTitle)
                    .foregroundStyle(Color.coastalAqua)
            }
            Slider(value: $value, in: 1...10, step: 0.1)
                .tint(.coastalAqua)
                .accessibilityLabel("Score")
                .accessibilityValue(String(format: "%.1f out of 10", value))
                .onChange(of: value) { _, newValue in
                    let tick = Int(newValue * 10)
                    if abs(tick - lastTick) >= 5 {
                        lastTick = tick
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
        }
    }
}

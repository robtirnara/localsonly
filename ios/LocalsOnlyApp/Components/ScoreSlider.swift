import SwiftUI

struct ScoreSlider: View {
    @Binding var value: Double
    @State private var lastTick: Int = 85

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Rating")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.coastalTextSecondary)
                        .tracking(1.2)
                    Text("Be honest. Was it a perfect 10?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.coastalTextSecondary.opacity(0.75))
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.coastalCoral)
                    Text("/10")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.gray.opacity(0.35))
                        .padding(.top, 4)
                }
            }

            Slider(value: $value, in: 1...10, step: 0.1)
                .tint(.coastalCoral)
                .accessibilityLabel("Score")
                .accessibilityValue(String(format: "%.1f out of 10", value))
                .onChange(of: value) { _, newValue in
                    let tick = Int(newValue * 10)
                    if abs(tick - lastTick) >= 5 {
                        lastTick = tick
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

            HStack {
                Label("Nah", systemImage: "hand.thumbsdown.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.coastalTextSecondary)
                Spacer()
                Label("Epic", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.coastalTextSecondary)
            }
        }
    }
}

import SwiftUI

struct WavesLoadingView: View {
    @State private var animating = false
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: "water.waves")
            .font(.system(size: size))
            .foregroundStyle(Color.coastalSand)
            .scaleEffect(animating ? 1.08 : 0.92)
            .opacity(animating ? 1 : 0.5)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: animating
            )
            .onAppear { animating = true }
    }
}

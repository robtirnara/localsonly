import SwiftUI

struct EligibilityBanner: View {
    let state: String

    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Local Access")
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalTextSecondary)
                    Text("Your interaction status")
                        .font(.bodyCopy)
                        .foregroundStyle(Color.coastalTextPrimary)
                }
                Spacer()
                StatePill(text: state)
            }
        }
    }
}

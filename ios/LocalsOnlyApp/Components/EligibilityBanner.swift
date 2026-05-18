import SwiftUI

/// Contributor eligibility strip — uses the same `feedCanvas*` tokens and rounded type as Feed / Explore / Rate / Profile.
struct EligibilityBanner: View {
    let state: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Local access")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasConcrete)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(statusSubtitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.feedCanvasInk)
            }

            Spacer(minLength: 8)

            StatePill(text: state)
        }
        .padding(16)
        .background(Color.feedCanvasCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }

    private var statusSubtitle: String {
        switch state {
        case "verified_local":
            return "You're verified to post and rate."
        case "provisional_local":
            return "You can contribute while we finish review."
        case "restricted":
            return "Posting is limited on your account."
        case "under_review":
            return "Your account is under review."
        case "browse_only":
            return "Browse only — complete verification to post."
        default:
            return "Your interaction status"
        }
    }
}

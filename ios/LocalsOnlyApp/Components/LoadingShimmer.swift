import SwiftUI

struct LoadingShimmer: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.coastalTextSecondary.opacity(0.10))
            .overlay(alignment: .leading) {
                shimmerGradient
            }
            .frame(height: 80)
            .redacted(reason: .placeholder)
    }
}

struct ImageTileShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.coastalTextSecondary.opacity(0.10))
                .aspectRatio(3.0 / 2.0, contentMode: .fill)
                .overlay(alignment: .leading) {
                    shimmerGradient
                }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.coastalTextSecondary.opacity(0.10))
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 40)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.coastalTextSecondary.opacity(0.08))
                .frame(height: 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 80)
        }
        .redacted(reason: .placeholder)
    }
}

private var shimmerGradient: some View {
    Rectangle()
        .fill(
            LinearGradient(
                colors: [Color.clear, Color.coastalTextSecondary.opacity(0.14), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(width: 120)
        .offset(x: -70)
}

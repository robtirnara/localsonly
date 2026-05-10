import SwiftUI

struct BrandLockupView: View {
    var compact = false

    var body: some View {
        if compact { compactLayout } else { fullLayout }
    }

    private var compactLayout: some View {
        HStack(spacing: 10) {
            PalmTreeShape()
                .fill(Color.coastalAqua)
                .frame(width: 32, height: 40)

            Text("localsonly")
                .font(.system(size: 20, weight: .heavy, design: .default))
                .foregroundStyle(Color.coastalInk)

            SeagullShape()
                .stroke(Color.coastalAqua,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 20, height: 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coastalAqua.opacity(0.35), lineWidth: 1.3)
        )
    }

    private var fullLayout: some View {
        VStack(spacing: Spacing.xs) {
            PalmTreeShape()
                .fill(Color.coastalAqua)
                .frame(width: 48, height: 56)

            HStack(alignment: .top, spacing: 4) {
                Text("localsonly")
                    .font(.heroTitle)
                    .foregroundStyle(Color.coastalInk)

                SeagullShape()
                    .stroke(Color.coastalAqua,
                            style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .frame(width: 20, height: 12)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.coastalAqua.opacity(0.35), lineWidth: 1.5)
        )
    }
}

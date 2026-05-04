import SwiftUI

struct RatingCard: View {
    let title: String
    let subtitle: String
    let scoreText: String
    let privacy: String
    var photoURL: String? = nil
    var score: Double? = nil
    var timestamp: Date? = nil
    var itemCategory: String? = nil

    private var scoreColor: Color {
        if let score { return .scoreColor(for: score) }
        if let val = Double(scoreText) { return .scoreColor(for: val) }
        return .coastalAqua
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        default:
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.coastalTextSecondary.opacity(0.08))
                                .frame(maxWidth: .infinity, maxHeight: 120)
                                .overlay { WavesLoadingView(size: 20) }
                        }
                    }
                } else if let itemCategory {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.coastalSand.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay {
                            CategoryIconView(category: itemCategory, size: 24)
                                .foregroundStyle(Color.coastalSand.opacity(0.4))
                        }
                }

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(title)
                            .font(.cardTitle)
                            .foregroundStyle(Color.coastalTextPrimary)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.captionCopy)
                                .foregroundStyle(Color.coastalTextSecondary)
                        }
                    }
                    Spacer()
                    Text(scoreText)
                        .font(.sectionTitle)
                        .foregroundStyle(scoreColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(scoreColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack {
                    Text(privacy.uppercased())
                        .font(.microLabel)
                        .foregroundStyle(Color.coastalSand)
                    if let timestamp {
                        Spacer()
                        Text(timestamp.relativeString)
                            .font(.microLabel)
                            .foregroundStyle(Color.coastalTextSecondary)
                    }
                }
            }
        }
    }
}

extension Date {
    var relativeString: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = interval < 31536000 ? "MMM d" : "MMM d, yyyy"
        return formatter.string(from: self)
    }
}

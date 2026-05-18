import Foundation
import Vapor

protocol AppModule {
    var name: String { get }
    func register(routes: RoutesBuilder, app: Application)
}

enum EligibilityState: String, CaseIterable, Codable {
    case browseOnly = "browse_only"
    case provisionalLocal = "provisional_local"
    case verifiedLocal = "verified_local"
    case restricted = "restricted"
    case underReview = "under_review"
}

struct AppModules {
    static let all: [AppModule] = [
        AuthModule(),
        UsersModule(),
        PlacesModule(),
        RatingsModule(),
        FriendshipsModule(),
        FeedModule(),
        EligibilityModule(),
        ModerationModule(),
        UploadsModule(),
        TagsModule(),
        ItemCategoriesModule(),
        BookmarksModule(),
        ListsModule(),
        CosignsModule(),
        NotificationsModule(),
        InvitesModule()
    ]
}

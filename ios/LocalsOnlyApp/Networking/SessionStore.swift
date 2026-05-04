import Foundation

final class SessionStore {
    private enum Keys {
        static let token = "localsonly.session.token"
    }

    var token: String? {
        get { UserDefaults.standard.string(forKey: Keys.token) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.token) }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: Keys.token)
    }
}

import Foundation

extension String {
    /// Look up a localized string by key.
    /// Usage: `"onboarding.welcome.headline".localized`
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Look up a localized string with format arguments.
    /// Usage: `"reminders.perDay".localized(with: 3)`
    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

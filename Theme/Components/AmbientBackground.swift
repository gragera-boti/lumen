import SwiftUI

/// Ambient dark gradient background used as the app's universal background.
struct AmbientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [LumenTheme.Colors.ambientDark, LumenTheme.Colors.ambientMid],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// View modifier that applies the ambient dark background to any screen.
/// For List-based screens, also hides the default scroll content background.
struct AmbientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(AmbientBackground())
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    /// Apply the app's ambient dark background.
    func ambientBackground() -> some View {
        modifier(AmbientBackgroundModifier())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            Text("Sample row")
            Text("Another row")
        }
        .ambientBackground()
        .navigationTitle("Settings")
    }
}

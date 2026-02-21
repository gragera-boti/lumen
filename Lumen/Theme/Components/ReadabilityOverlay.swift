import SwiftUI

struct ReadabilityOverlay: View {
    var opacity: Double = 0.35

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0), location: 0),
                .init(color: .black.opacity(opacity * 0.5), location: 0.3),
                .init(color: .black.opacity(opacity), location: 0.6),
                .init(color: .black.opacity(opacity * 0.8), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        ReadabilityOverlay()
        Text("Readable text")
            .font(.title)
            .foregroundStyle(.white)
    }
    .ignoresSafeArea()
}

import SwiftUI

struct GradientBackground: View {
    let colors: [Color]
    var startPoint: UnitPoint = .topLeading
    var endPoint: UnitPoint = .bottomTrailing

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .ignoresSafeArea()
    }
}

struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

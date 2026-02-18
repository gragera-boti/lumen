import SwiftUI

struct WatchContentView: View {
    @State private var currentAffirmation: WatchAffirmation?
    @State private var isFavorited = false
    @State private var gradientColors: [Color] = [Color(hex: "#7FBBCA"), Color(hex: "#A688B5")]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let affirmation = currentAffirmation {
                VStack(spacing: 8) {
                    Spacer()

                    Text(affirmation.text)
                        .font(.system(.body, design: .serif, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .minimumScaleFactor(0.6)

                    Spacer()

                    HStack(spacing: 16) {
                        Button {
                            isFavorited.toggle()
                        } label: {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorited ? .red : .white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            loadNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 4)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.title2)
                        .foregroundStyle(.white)

                    Text("Lumen")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Open the iPhone app to get started.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            loadFromSharedStorage()
        }
    }

    // MARK: - Data

    private func loadFromSharedStorage() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.lumen.app"
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("watch_affirmations.json")
        guard let data = try? Data(contentsOf: fileURL),
              let affirmations = try? JSONDecoder().decode([WatchAffirmation].self, from: data),
              !affirmations.isEmpty else {
            // Fallback
            currentAffirmation = WatchAffirmation(
                id: "fallback",
                text: "I can take one small step today.",
                gradientColors: ["#7FBBCA", "#A688B5"]
            )
            return
        }

        currentAffirmation = affirmations.first
        if let colors = currentAffirmation?.gradientColors {
            gradientColors = colors.map { Color(hex: $0) }
        }
    }

    private func loadNext() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.lumen.app"
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("watch_affirmations.json")
        guard let data = try? Data(contentsOf: fileURL),
              let affirmations = try? JSONDecoder().decode([WatchAffirmation].self, from: data),
              affirmations.count > 1 else { return }

        let currentId = currentAffirmation?.id ?? ""
        let currentIndex = affirmations.firstIndex { $0.id == currentId } ?? 0
        let nextIndex = (currentIndex + 1) % affirmations.count
        currentAffirmation = affirmations[nextIndex]

        if let colors = currentAffirmation?.gradientColors {
            gradientColors = colors.map { Color(hex: $0) }
        }

        isFavorited = false
    }
}

// MARK: - Watch data model

struct WatchAffirmation: Codable, Identifiable {
    let id: String
    let text: String
    let gradientColors: [String]
}

// MARK: - Color hex (Watch self-contained)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

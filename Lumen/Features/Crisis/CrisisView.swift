import SwiftUI

struct CrisisView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LumenTheme.Spacing.lg) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                        .padding(.top, LumenTheme.Spacing.xl)

                    Text("You're not alone")
                        .font(LumenTheme.Typography.headlineFont)

                    Text("If you or someone you know is in crisis or feeling unsafe, please reach out for help.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LumenTheme.Spacing.lg)

                    VStack(spacing: LumenTheme.Spacing.md) {
                        crisisLink(
                            title: "Emergency Services",
                            subtitle: "Call your local emergency number (112, 911, 999)",
                            icon: "phone.fill",
                            color: .red
                        )

                        crisisLink(
                            title: "Crisis Text Line",
                            subtitle: "Text HOME to 741741 (US)",
                            icon: "message.fill",
                            color: .blue
                        )

                        crisisLink(
                            title: "International Association for Suicide Prevention",
                            subtitle: "Find a crisis centre near you",
                            icon: "globe",
                            color: .purple,
                            url: URL(string: "https://www.iasp.info/resources/Crisis_Centres/")
                        )

                        crisisLink(
                            title: "Befrienders Worldwide",
                            subtitle: "Emotional support worldwide",
                            icon: "person.2.fill",
                            color: .green,
                            url: URL(string: "https://www.befrienders.org")
                        )
                    }
                    .padding(.horizontal, LumenTheme.Spacing.lg)

                    Spacer(minLength: LumenTheme.Spacing.xl)

                    Button("I'm not in crisis") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, LumenTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Get Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func crisisLink(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        url: URL? = nil
    ) -> some View {
        Group {
            if let url {
                Link(destination: url) {
                    crisisCard(title: title, subtitle: subtitle, icon: icon, color: color)
                }
            } else {
                crisisCard(title: title, subtitle: subtitle, icon: icon, color: color)
            }
        }
    }

    private func crisisCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: LumenTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                .fill(.ultraThinMaterial)
        )
    }
}

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

                    Text("crisis.headline".localized)
                        .font(LumenTheme.Typography.headlineFont)

                    Text("crisis.body".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LumenTheme.Spacing.lg)

                    VStack(spacing: LumenTheme.Spacing.md) {
                        crisisLink(
                            title: "crisis.emergency".localized,
                            subtitle: "crisis.emergencySubtitle".localized,
                            icon: "phone.fill",
                            color: .red
                        )

                        crisisLink(
                            title: "crisis.textLine".localized,
                            subtitle: "crisis.textLineSubtitle".localized,
                            icon: "message.fill",
                            color: .blue
                        )

                        crisisLink(
                            title: "crisis.iasp".localized,
                            subtitle: "crisis.iaspSubtitle".localized,
                            icon: "globe",
                            color: .purple,
                            url: URL(string: "https://www.iasp.info/resources/Crisis_Centres/")
                        )

                        crisisLink(
                            title: "crisis.befrienders".localized,
                            subtitle: "crisis.befriendersSubtitle".localized,
                            icon: "person.2.fill",
                            color: .green,
                            url: URL(string: "https://www.befrienders.org")
                        )
                    }
                    .padding(.horizontal, LumenTheme.Spacing.lg)

                    Spacer(minLength: LumenTheme.Spacing.xl)

                    Button("crisis.dismiss".localized) {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, LumenTheme.Spacing.xxl)
                }
            }
            .navigationTitle("crisis.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.close".localized) { dismiss() }
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

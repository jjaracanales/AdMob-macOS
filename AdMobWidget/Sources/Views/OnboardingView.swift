import SwiftUI

/// Step-by-step onboarding tutorial shown on first launch
struct OnboardingView: View {
    @ObservedObject var localization: LocalizationService
    @Binding var onboardingCompleted: Bool
    @State private var currentStep = 0

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            stepContent
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button(L10n.onboardingBack) {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.borderless)
                }

                Spacer()

                // Step dots
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button(L10n.onboardingSkip) {
                        onboardingCompleted = true
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                    .font(.caption)

                    Button(L10n.onboardingNext) {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Button(L10n.onboardingGetStarted) {
                        onboardingCompleted = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(width: 420)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            stepView(
                icon: "star.circle.fill",
                iconColor: .yellow,
                title: L10n.onboardingWelcomeTitle,
                description: L10n.onboardingWelcomeDesc
            )
        case 1:
            stepView(
                icon: "cloud.fill",
                iconColor: .blue,
                title: L10n.onboardingStep1Title,
                description: L10n.onboardingStep1Desc
            )
        case 2:
            stepView(
                icon: "magnifyingglass.circle.fill",
                iconColor: .green,
                title: L10n.onboardingStep2Title,
                description: L10n.onboardingStep2Desc
            )
        case 3:
            stepView(
                icon: "lock.shield.fill",
                iconColor: .orange,
                title: L10n.onboardingStep3Title,
                description: L10n.onboardingStep3Desc
            )
        case 4:
            stepView(
                icon: "key.fill",
                iconColor: .purple,
                title: L10n.onboardingStep4Title,
                description: L10n.onboardingStep4Desc
            )
        case 5:
            stepView(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: L10n.onboardingStep5Title,
                description: L10n.onboardingStep5Desc
            )
        default:
            EmptyView()
        }
    }

    private func stepView(icon: String, iconColor: Color, title: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(iconColor)
                .padding(.bottom, 4)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

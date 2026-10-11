import SwiftUI

struct OpeningScreenView: View {
    @Environment(\.scenePhase) private var scenePhase
    let onFinished: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                Image("OpeningMap")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Bearings")
                    .font(.largeTitle.weight(.medium))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("opening.title")
                Text("Find what’s been lost inside.")
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("opening.slogan")
            }
            .foregroundStyle(BearingsTheme.line)
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .background(BearingsTheme.paper)
        .accessibilityIdentifier("opening.screen")
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            // Restart after interruptions so background time cannot shorten the opening.
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}

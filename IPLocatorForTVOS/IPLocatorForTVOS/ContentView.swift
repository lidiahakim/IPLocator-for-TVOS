import SwiftUI

@MainActor
final class IPLocatorViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded(IPLocationInfo)
        case failed(String)
    }

    @Published private(set) var state: State = .loading

    private let service: IPLocationFetching

    init(service: IPLocationFetching = IPLocationService()) {
        self.service = service
    }

    func refresh() async {
        state = .loading
        do {
            let info = try await service.fetchCurrentLocation()
            state = .loaded(info)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = IPLocatorViewModel()

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 40) {
                header

                Group {
                    switch viewModel.state {
                    case .loading:
                        loadingView
                    case .loaded(let info):
                        LocationCardView(info: info)
                    case .failed(let message):
                        errorView(message)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.state)

                refreshButton
            }
            .padding(.vertical, 60)
        }
        .task {
            await viewModel.refresh()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("IPLocator")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.white)
            Text("FOR TVOS")
                .font(.system(size: 16, weight: .bold))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.6)
                .tint(.white)
            Text("Locating you…")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(height: 420)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("Couldn't Find Your Location")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 640)
        }
        .padding(50)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
                .font(.system(size: 22, weight: .semibold))
                .padding(.horizontal, 12)
        }
        .buttonStyle(.card)
    }
}

#Preview {
    ContentView()
}

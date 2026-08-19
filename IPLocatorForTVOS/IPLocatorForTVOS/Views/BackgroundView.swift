import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.14),
                    Color(red: 0.09, green: 0.12, blue: 0.26),
                    Color(red: 0.03, green: 0.04, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.28), Color.clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 900
            )

            RadialGradient(
                colors: [Color.purple.opacity(0.18), Color.clear],
                center: .bottomLeading,
                startRadius: 60,
                endRadius: 800
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView()
}

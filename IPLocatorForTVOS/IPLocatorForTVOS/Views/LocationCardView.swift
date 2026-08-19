import SwiftUI

struct LocationCardView: View {
    let info: IPLocationInfo

    var body: some View {
        VStack(spacing: 28) {
            Text(CountryFlag.emoji(for: info.countryCode))
                .font(.system(size: 140))
                .shadow(color: .black.opacity(0.35), radius: 20, y: 10)

            VStack(spacing: 10) {
                Text(info.locationName.isEmpty ? "Unknown Location" : info.locationName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if let timezone = info.timezone, !timezone.isEmpty {
                    Text(timezone)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .frame(maxWidth: 420)

            VStack(spacing: 6) {
                Text("YOUR IP ADDRESS")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))

                Text(info.ip)
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            if let org = info.org, !org.isEmpty {
                Text(org)
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(60)
        .frame(maxWidth: 760)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 30, y: 20)
    }
}

#Preview {
    ZStack {
        BackgroundView()
        LocationCardView(
            info: IPLocationInfo(
                ip: "203.0.113.42",
                city: "Bucharest",
                region: "Bucharest",
                countryName: "Romania",
                countryCode: "RO",
                org: "Example ISP",
                timezone: "Europe/Bucharest"
            )
        )
    }
}

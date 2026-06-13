import SwiftUI
import DesignSystem

// MARK: - Card Surface Modifiers

extension View {
    func ncCard() -> some View {
        self
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: NCRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NCRadius.card, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 1)
            )
    }

    func ncCardGold() -> some View {
        self
            .background(Color.goldSoft)
            .clipShape(RoundedRectangle(cornerRadius: NCRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NCRadius.card, style: .continuous)
                    .strokeBorder(Color.goldEdge, lineWidth: 1)
            )
    }
}

// MARK: - Section Eyebrow

struct NCEyebrow: View {
    @Environment(\.ncFonts) private var fonts
    let title: String
    var right: String? = nil

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .font(fonts.monoEyebrow)
                .foregroundStyle(Color.ink3)
                .tracking(1.4)
                .textCase(.uppercase)
            Spacer()
            if let right {
                Text(right)
                    .font(fonts.monoBody)
                    .foregroundStyle(Color.goldDeep)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, NCSpacing.base)
    }
}

// MARK: - Dashed Divider

struct DashedDivider: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(Color.hairline, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .frame(height: 1)
    }
}

// MARK: - Agreement Bar

struct AgreementBar: View {
    let value: Double   // 0.0 – 1.0
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.hairline)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Air Quality Dial

struct AirDial: View {
    @Environment(\.ncFonts) private var fonts
    let grade: Int   // 0=좋음 1=보통 2=나쁨 3=매우나쁨 4=위험
    let size: CGFloat

    private var dialColor: Color {
        switch grade {
        case 0:  return .airGood
        case 1:  return Color(hex: 0xC9A52E)
        case 2:  return Color(hex: 0xCF6F2A)
        case 3:  return Color(hex: 0xA93A26)
        default: return Color(hex: 0x742323)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        stops: [
                            .init(color: dialColor,      location: 0),
                            .init(color: dialColor,      location: Double(grade + 1) / 5.0),
                            .init(color: Color.hairline, location: Double(grade + 1) / 5.0),
                            .init(color: Color.hairline, location: 1),
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    )
                )
            Circle()
                .fill(Color.paper)
                .padding(4)
            Text("\(grade + 1)")
                .font(fonts.monoTiny)
                .foregroundStyle(dialColor)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Outfit Chip

struct NCChip: View {
    @Environment(\.ncFonts) private var fonts
    let label: String
    let highlight: Bool

    var body: some View {
        Text(label)
            .font(fonts.chip)
            .foregroundStyle(highlight ? Color.goldDeep : Color.ink2)
            .padding(.horizontal, NCSpacing.small)
            .padding(.vertical, 5)
            .background(highlight ? Color.goldSoft : Color.paperGrain)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(highlight ? Color.goldEdge : Color.hairline, lineWidth: 1)
            )
    }
}

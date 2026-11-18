import SwiftUI

// MARK: - Brand palette

enum AppColor {
    static let brand = Color(red: 1.00, green: 0.30, blue: 0.38)
    static let brandDeep = Color(red: 0.85, green: 0.10, blue: 0.24)
    static let brandSoft = Color(light: UIColor(red: 1.00, green: 0.92, blue: 0.93, alpha: 1),
                                 dark: UIColor(red: 0.23, green: 0.09, blue: 0.13, alpha: 1))
    static let background = Color(light: UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1),
                                  dark: UIColor(red: 0.043, green: 0.047, blue: 0.063, alpha: 1))
    static let surface = Color(light: .white,
                               dark: UIColor(red: 0.082, green: 0.086, blue: 0.11, alpha: 1))
    static let surfaceAlt = Color(light: UIColor(red: 0.93, green: 0.94, blue: 0.97, alpha: 1),
                                  dark: UIColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1))
    static let textPrimary = Color(light: UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1),
                                   dark: UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1))
    static let textSecondary = Color(light: UIColor(red: 0.43, green: 0.45, blue: 0.52, alpha: 1),
                                     dark: UIColor(red: 0.61, green: 0.63, blue: 0.69, alpha: 1))
    static let separator = Color(light: UIColor(red: 0.90, green: 0.91, blue: 0.94, alpha: 1),
                                 dark: UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1))
    static let success = Color(red: 0.20, green: 0.78, blue: 0.42)
    static let warning = Color(red: 1.00, green: 0.62, blue: 0.04)
    static let danger = Color(red: 1.00, green: 0.27, blue: 0.27)
    static let teal = Color(red: 0.18, green: 0.78, blue: 0.72)
    static let purple = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let blue = Color(red: 0.24, green: 0.52, blue: 1.00)
    static let orange = Color(red: 1.00, green: 0.48, blue: 0.22)

    static let brandGradient = LinearGradient(colors: [brand, brandDeep],
                                              startPoint: .topLeading, endPoint: .bottomTrailing)
    static let measureGradient = LinearGradient(colors: [Color(red: 1.0, green: 0.35, blue: 0.36),
                                                         Color(red: 0.92, green: 0.13, blue: 0.33)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing)
    static let csiGradient = LinearGradient(colors: [Color(red: 0.35, green: 0.29, blue: 0.86),
                                                     Color(red: 0.15, green: 0.16, blue: 0.48)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing)
    static let heartAgeGradient = LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.30),
                                                          Color(red: 0.82, green: 0.15, blue: 0.30)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// MARK: - Reusable surfaces & controls

struct CardBackground: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = 22
    var fill: Color = AppColor.surface

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 5)
            )
    }
}

extension View {
    func card(padding: CGFloat = 18, radius: CGFloat = 22, fill: Color = AppColor.surface) -> some View {
        modifier(CardBackground(padding: padding, radius: radius, fill: fill))
    }

    func screenBackground() -> some View {
        background(AppColor.background.ignoresSafeArea())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppColor.brand
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.82 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(AppColor.surfaceAlt)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SectionTitle: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(L(title))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColor.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(L(actionTitle), action: action)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.brand)
            }
        }
    }
}

struct Chip: View {
    let text: String
    var selected: Bool = false
    var color: Color = AppColor.brand

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(selected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? color : color.opacity(0.12))
            )
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(AppColor.textSecondary)
            Text(L(title))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
            Text(L(message))
                .font(.system(size: 14))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
    }
}

struct HeartPulseView: View {
    @State private var beat = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 30))
            .foregroundColor(AppColor.brand)
            .scaleEffect(beat ? 1.12 : 0.94)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: beat)
            .onAppear { beat = true }
    }
}

// MARK: - Formatting

enum Fmt {
    static func number(_ value: Double, digits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(digits)f", value)
    }

    static var isChinese: Bool { LanguageStore.shared.effective == .chinese }

    static func date(_ date: Date, format: String = "MMM d, yyyy") -> String {
        let f = DateFormatter()
        f.locale = LanguageStore.shared.effectiveLocale
        f.dateFormat = isChinese ? chineseFormat(for: format) : format
        return f.string(from: date)
    }

    private static func chineseFormat(for format: String) -> String {
        switch format {
        case "MMM d, yyyy", "MMMM d, yyyy": return "yyyy年M月d日"
        case "MMM d": return "M月d日"
        case "MMMM yyyy": return "yyyy年M月"
        case "MMM yyyy": return "yyyy年M月"
        case "h:mm a": return "HH:mm"
        case "MMM d, h:mm a": return "M月d日 HH:mm"
        case "MMM d, yyyy · h:mm a", "MMMM d, yyyy · h:mm a": return "yyyy年M月d日 HH:mm"
        case "EEEE, MMM d": return "M月d日 EEEE"
        case "EEEE": return "EEEE"
        default: return format
        }
    }

    static func time(_ date: Date) -> String {
        Fmt.date(date, format: "h:mm a")
    }
}

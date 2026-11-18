import SwiftUI
import WebKit

@MainActor
final class ProfileEditorModel: ObservableObject {
    @Published var age: String
    @Published var gender: Gender
    @Published var weight: String
    @Published var heightCm: String
    @Published var feet: String
    @Published var inches: String

    var usesImperial: Bool { Profile.heightUnit == .imperial }

    init(profile: Profile) {
        let imperial = Profile.heightUnit == .imperial
        age = profile.age.map(String.init) ?? ""
        gender = profile.gender
        if let weightKg = profile.weightKg {
            weight = imperial
                ? String(format: "%.1f", weightKg * 2.2046226218)
                : String(format: "%.1f", weightKg)
        } else {
            weight = ""
        }
        if let heightCmValue = profile.heightCm {
            heightCm = String(format: "%.0f", heightCmValue)
            let totalInches = heightCmValue / 2.54
            feet = String(Int(totalInches / 12))
            inches = String(format: "%.0f", (totalInches - floor(totalInches / 12) * 12).rounded())
        } else {
            heightCm = ""
            feet = ""
            inches = ""
        }
    }

    var canContinue: Bool { true }

    func buildProfile(base: Profile) -> Profile {
        var profile = base
        let ageValue = Int(age.trimmingCharacters(in: .whitespaces)) ?? 0
        profile.age = (1...120).contains(ageValue) ? ageValue : nil
        profile.gender = gender

        let weightValue = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0
        let weightKg = usesImperial ? weightValue / 2.2046226218 : weightValue
        profile.weightKg = (1...500).contains(weightKg) ? (weightKg * 10).rounded() / 10 : nil

        if usesImperial {
            let ft = Double(feet) ?? 0
            let inch = Double(inches) ?? 0
            let cm = (ft * 12 + inch) * 2.54
            profile.heightCm = (50...300).contains(cm) ? cm.rounded() : nil
        } else {
            let cm = Double(heightCm.replacingOccurrences(of: ",", with: ".")) ?? 0
            profile.heightCm = (50...300).contains(cm) ? cm.rounded() : nil
        }
        return profile
    }
}

struct ProfileMetricsForm: View {
    @ObservedObject var model: ProfileEditorModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            fieldRow(label: "Age") {
                TextField("Not Set", text: $model.age)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
            }
            fieldRow(label: "Gender") {
                Menu {
                    ForEach(Gender.allCases) { gender in
                        Button(gender.title) { model.gender = gender }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(model.gender.title)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
                }
            }
            fieldRow(label: "Weight") {
                HStack(spacing: 6) {
                    TextField("Not Set", text: $model.weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                    Text(model.usesImperial ? "lb" : "kg")
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            if model.usesImperial {
                fieldRow(label: "Height") {
                    HStack(spacing: 6) {
                        TextField("0", text: $model.feet)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 34)
                        Text("ft")
                            .foregroundColor(AppColor.textSecondary)
                        TextField("0", text: $model.inches)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 34)
                        Text("in")
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
            } else {
                fieldRow(label: "Height") {
                    HStack(spacing: 6) {
                        TextField("Not Set", text: $model.heightCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                        Text("cm")
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColor.surface)
        )
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            content()
        }
        .frame(minHeight: 44)
    }
}

struct LegalWebView: View {
    enum Document: String, Identifiable {
        case privacy = "https://heartica.pro/pp"
        case terms = "https://heartica.pro/tou"
        var id: String { rawValue }
        var title: String {
            switch self {
            case .privacy: return "Privacy Policy"
            case .terms: return "Terms of Use"
            }
        }
        var url: URL { URL(string: rawValue)! }
    }

    let document: Document
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            WebView(url: document.url)
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

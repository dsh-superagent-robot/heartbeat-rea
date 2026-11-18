import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false
    @State private var started = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.07, green: 0.04, blue: 0.09),
                                    Color(red: 0.20, green: 0.03, blue: 0.10),
                                    Color(red: 0.05, green: 0.02, blue: 0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Circle()
                .fill(AppColor.brand.opacity(0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .scaleEffect(appeared ? 1.15 : 0.8)

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(AppColor.brand.opacity(0.18), lineWidth: 1)
                        .frame(width: 168, height: 168)
                        .scaleEffect(appeared ? 1.25 : 0.9)
                        .opacity(appeared ? 0 : 1)
                    Circle()
                        .stroke(AppColor.brand.opacity(0.12), lineWidth: 1)
                        .frame(width: 128, height: 128)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 62, weight: .medium))
                        .foregroundStyle(AppColor.brandGradient)
                        .scaleEffect(appeared ? 1.0 : 0.7)
                    WaveformMark()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 72, height: 24)
                        .offset(y: 1)
                        .opacity(appeared ? 1 : 0)
                }
                VStack(spacing: 6) {
                    Text("Heartica")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Your health, in your hands")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            guard !started else { return }
            started = true
            Task { await appState.bootstrap() }
        }
    }
}

struct WaveformMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.26, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.width * 0.52, y: rect.height * 0.82))
        path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

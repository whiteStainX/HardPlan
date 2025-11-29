import Combine
import SwiftUI

struct SplashScreenView: View {
    @State private var asciiArt: String?
    @State private var glitchOffsetA: CGSize = .zero
    @State private var glitchOffsetB: CGSize = .zero
    @State private var isGlitching = false

    private let glitchTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome, Comrade.")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.green)
                if let art = asciiArt {
                    ZStack {
                        Text(art)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.orange)

                        Text(art)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.cyan)
                            .blendMode(.screen)
                            .offset(glitchOffsetA)
                            .opacity(isGlitching ? 0.6 : 0)

                        Text(art)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.purple)
                            .blendMode(.screen)
                            .offset(glitchOffsetB)
                            .opacity(isGlitching ? 0.5 : 0)
                    }
                }
            }
        }
        .onAppear(perform: loadAsciiArt)
        .onReceive(glitchTimer) { _ in
            withAnimation(.easeOut(duration: 0.18)) {
                glitchOffsetA = CGSize(width: Double.random(in: -1.5...1.5),
                                       height: Double.random(in: -0.5...0.5))
                glitchOffsetB = CGSize(width: Double.random(in: -1.5...1.5),
                                       height: Double.random(in: -0.5...0.5))
                isGlitching.toggle()
            }
        }
    }

    private func loadAsciiArt() {
        if let url = Bundle.main.url(forResource: "logo", withExtension: "txt"),
           let art = try? String(contentsOf: url) {
            self.asciiArt = art
        } else {
            // Fallback in case the file is missing
            self.asciiArt = "H P"
        }
    }
}

#Preview {
    SplashScreenView()
}

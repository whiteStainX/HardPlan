import SwiftUI

struct SplashScreenView: View {
    @State private var asciiArt: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome, Comrade.")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.green)
                if let art = asciiArt {
                    Text(art)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.orange)
                }
            }
        }
        .onAppear(perform: loadAsciiArt)
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

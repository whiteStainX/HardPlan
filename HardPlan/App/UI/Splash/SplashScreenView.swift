import SwiftUI
import Combine

struct SplashScreenView: View {
    // A long block of "nonsense" text to display
    private let fullLogText = """
    Booting HardPlan v1.0...
    [MEM] 256/256 memory blocks checked.
    [CPU] Calibrating core frequencies... Done.
    [NET] Initializing network services... OK.
    [DATA] Mounting user partition...
    [HPLAN] Loading Strength Protocols...
    [HPLAN] Parsing Exercise Database...
    [HPLAN] Calibrating Volume Equator...
    [HPLAN] Assembling Mesocycle...
    
    Welcome, Comrade.
    """
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var asciiArt: String?
    @State private var showAsciiArt = false
    
    // A single, fast timer to create the typewriter effect
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Text(displayedText + (showAsciiArt ? "" : "█")) // Show cursor only during typing
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.green)
                    .lineLimit(nil)

                if showAsciiArt {
                    if let art = asciiArt {
                        HStack {
                            Spacer()
                            Text(art)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.orange)
                                .transition(.opacity.animation(.easeInOut(duration: 1.0)))
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .onAppear(perform: loadAsciiArt)
        .onReceive(timer) { _ in
            guard currentIndex < fullLogText.count else {
                // Typing is finished
                timer.upstream.connect().cancel()
                // Trigger the ASCII art to fade in
                withAnimation {
                    showAsciiArt = true
                }
                return
            }
            
            let index = fullLogText.index(fullLogText.startIndex, offsetBy: currentIndex)
            displayedText.append(fullLogText[index])
            currentIndex += 1
        }
    }

    private func loadAsciiArt() {
        if let url = Bundle.main.url(forResource: "logo", withExtension: "txt"),
           let art = try? String(contentsOf: url) {
            self.asciiArt = art
        }
    }
}

#Preview {
    SplashScreenView()
}

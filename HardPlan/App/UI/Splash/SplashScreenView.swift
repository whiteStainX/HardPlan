import SwiftUI
import Combine

struct SplashScreenView: View {
    // A long block of "nonsense" text to display
    private let fullLogText = """
    Booting HardPlan v1.0...
    [MEM] 256/256 memory blocks checked.
    [CPU] Calibrating core frequencies... Done.
    [CPU0] 3.2 GHz, [CPU1] 3.2 GHz, [CPU2] 2.8 GHz
    [NET] Starting network services... DHCP OK
    [DATA] Mounting user partition...
    [DATA] Verifying data integrity...
    [AUTH] Verifying user credentials...
    [HPLAN] Loading HardPlan v1.0 Kernel...
    [HPLAN] Initializing strength protocols...
    [HPLAN] Parsing exercise database...
    [HPLAN] Calibrating volume equator...
    [HPLAN] Assembling Mesocycle...
    [HPLAN] Finalizing Program...
    
    Welcome, Athlete.
    """
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    // A single, fast timer to create the typewriter effect
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Text(displayedText + "█") // Append a cursor character
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .lineLimit(nil) // Ensure text wraps
        }
        .onReceive(timer) { _ in
            guard currentIndex < fullLogText.count else {
                timer.upstream.connect().cancel() // Stop the timer when done
                return
            }
            
            let index = fullLogText.index(fullLogText.startIndex, offsetBy: currentIndex)
            displayedText.append(fullLogText[index])
            currentIndex += 1
        }
    }
}

#Preview {
    SplashScreenView()
}

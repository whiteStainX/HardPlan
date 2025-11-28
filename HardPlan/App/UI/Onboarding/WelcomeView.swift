import SwiftUI
import Combine

struct WelcomeView: View {
    let onContinue: () -> Void

    // 1. Define the sequence of symbols
    private let mathSymbols = ["microbe.circle.fill", "timer.circle.fill", "figure.strengthtraining.traditional.circle.fill", "arrow.up.right.circle.fill"]
    
    // 2. Add state to track the current symbol
    @State private var currentSymbolIndex = 0

    // 3. Create a timer that fires every 2 seconds
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                // 4. Display the image based on the current state
                Image(systemName: mathSymbols[currentSymbolIndex])
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                    // 5. This is the magic modifier for the animation!
                    .contentTransition(.symbolEffect(.replace))
                
                Text("Welcome to HardPlan")
                    .font(.largeTitle)
                    .bold()
                VStack(spacing: 4) {
                    Text("You need to do something")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Text("Before we can do anything")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onContinue) {
                Text("Start Onboarding")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        // 6. Listen for the timer and update the state
        .onReceive(timer) { _ in
            withAnimation(.snappy) {
                currentSymbolIndex = (currentSymbolIndex + 1) % mathSymbols.count
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
        .padding()
}

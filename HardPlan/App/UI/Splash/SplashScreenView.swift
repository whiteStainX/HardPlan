import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                Text("HardPlan")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

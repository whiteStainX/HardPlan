import SwiftUI

struct GeneratingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.accentColor)
                .scaleEffect(1.4)

            VStack(spacing: 6) {
                Text("Building your program")
                    .font(.title3)
                    .bold()
                Text("We’re picking exercises, setting volumes, and scheduling your week…")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    GeneratingView()
        .padding()
}

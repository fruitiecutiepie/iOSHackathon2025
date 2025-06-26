import SwiftUI

struct SplashScreenView: View {
  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()
      VStack(spacing: 20) {
        
        Image("MyLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 120, height: 120)
          .cornerRadius(24)
        Text("Spin2Eat")
          .font(.largeTitle).bold()
          .foregroundColor(.primary)
      }
    }
  }
}

#Preview {
  SplashScreenView()
} 

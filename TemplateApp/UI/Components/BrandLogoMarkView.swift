import SwiftUI

struct BrandLogoMarkView: View {
    var body: some View {
        Image("BrandLogo")
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFit()
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    BrandLogoMarkView()
        .frame(width: 120, height: 120)
        .padding()
        .background(Color.black)
}

import SwiftUI

struct VerifierSuccessView: View {
    @Binding var path: NavigationPath

    var success: Bool
    var description: String

    var body: some View {
        VStack(alignment: .leading) {
            if success {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color("GreenValid"))
                        .frame(height: 250)
                    VStack {
                        Spacer()
                        HStack {
                            Image("ValidCheck")
                            Text("True")
                                .font(.customFont(font: .inter, style: .semiBold, size: .h0))
                                .foregroundStyle(Color.white)
                        }

                    }
                    .padding(.all, 20)
                }
                .frame(height: 250)
            } else {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color("RedInvalid"))
                        .frame(width: .infinity, height: 250)
                    VStack {
                        Spacer()
                        HStack {
                            Image("InvalidCheck")
                            Text("False")
                                .font(.customFont(font: .inter, style: .semiBold, size: .h0))
                                .foregroundStyle(Color.white)
                        }

                    }
                    .padding(.all, 20)
                }
                .frame(height: 250)
            }

            Text(description)
                .font(.customFont(font: .inter, style: .semiBold, size: .h1))
                .foregroundStyle(Color("TextHeader"))
                .padding(.top, 20)

            Spacer()

            Button {
                while !path.isEmpty {
                    path.removeLast()
                }
            }  label: {
                Text("Close")
                    .frame(width: UIScreen.screenWidth)
                    .padding(.horizontal, -20)
                    .font(.customFont(font: .inter, style: .medium, size: .h4))
            }
            .foregroundColor(.white)
            .padding(.vertical, 13)
            .background(Color("GrayButton"))
            .cornerRadius(8)
        }
        .padding(.all, 30)
        .navigationBarBackButtonHidden(true)
    }
}

struct VerifierSuccessViewPreview: PreviewProvider {
    @State static var path: NavigationPath = .init()

    static var previews: some View {
        VerifierSuccessView(
            path: $path,
            success: true,
            description: "Valid Verifiable Credential"
        )
    }
}

import SwiftUI
import SpruceIDMobileSdk

struct AddToWallet: Hashable {
    var rawCredential: String
}

struct AddToWalletView: View {
    @Binding var path: NavigationPath
    var rawCredential: String
    var credential: GenericJSON?

    
    init(path: Binding<NavigationPath>, rawCredential: String) {
        self._path = path
        self.rawCredential = rawCredential
        // decode sd-jwt and update next line
        self.credential = getGenericJSON(jsonString: mockAchievementCredential)
    }
    
    func back() {
        while !path.isEmpty {
            path.removeLast()
        }
    }
    
    func addToWallet() {
        _ = CredentialDataStore.shared.insert(
            rawCredential: rawCredential
        )
        back()
    }
    
    var body: some View {
        ZStack {
            VStack{
                Text("Review Info")
                    .font(.customFont(font: .inter, style: .bold, size: .h0))
                    .padding(.horizontal, 20)
                    .foregroundStyle(Color("TextHeader"))
                AchievementCredentialItem(credential: credential).listComponent
                ScrollView(.vertical, showsIndicators: false) {
                    AchievementCredentialItem(credential: credential).detailsComponent
                }
            }
            VStack {
                Spacer()
                Button {
                    addToWallet()
                }  label: {
                    Text("Add to Wallet")
                        .frame(width: UIScreen.screenWidth)
                        .padding(.horizontal, -20)
                        .font(.customFont(font: .inter, style: .medium, size: .h4))
                }
                .foregroundColor(.white)
                .padding(.vertical, 13)
                .background(Color("CTAButtonGreen"))
                .cornerRadius(8)
                Button {
                    back()
                }  label: {
                    Text("Decline")
                        .frame(width: UIScreen.screenWidth)
                        .padding(.horizontal, -20)
                        .font(.customFont(font: .inter, style: .medium, size: .h4))
                }
                .foregroundColor(Color("SecondaryButtonRed"))
                .padding(.vertical, 13)
                .cornerRadius(8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct AddToWalletPreview: PreviewProvider {
    @State static var path: NavigationPath = .init()

    static var previews: some View {
        AddToWalletView(path: $path, rawCredential: "")
    }
}

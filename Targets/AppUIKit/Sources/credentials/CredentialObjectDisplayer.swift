import SwiftUI
import SpruceIDMobileSdk

struct CredentialObjectDisplayer: View {
    let display: [AnyView]
    
    init(dict: [String : GenericJSON]) {
        self.display = genericObjectDisplayer(
            object: dict,
            filter: ["id", "identifier", "type", "proof", "renderMethod", "@context"]
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<display.count, id: \.self) { index in
                display[index]
            }
            
        }
    }
}

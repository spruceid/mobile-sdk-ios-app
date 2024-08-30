import SwiftUI
import AppUIKit

@main
struct AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // @TODO: integrate with the OID4VP flow
                }
        }
    }
}

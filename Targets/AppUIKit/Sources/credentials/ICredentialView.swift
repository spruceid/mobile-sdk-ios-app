import SwiftUI

enum CredentialError: Error {
    case parsingError(String)
}

protocol ICredentialView {
    // component used to display the credential in a list with multiple components
    func credentialListItem(withOptions: Bool) -> any View
    // component used to display only details of the credential
    func credentialDetails() -> any View
    // component used to display the preview and details of the credential
    func credentialPreviewAndDetails() -> any View
}

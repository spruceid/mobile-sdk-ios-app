import SwiftUI
import UniformTypeIdentifiers
import SpruceIDMobileSdk

public struct SelectiveDisclosureView: View {
    @State private var showingSDSheet = true
    @State private var itemsSelected: [String: [String: [String: Bool]]]
    @State private var itemsRequests: [ItemsRequest]
    @Binding var proceed: Bool
    @StateObject var delegate: ShareViewDelegate
    
    init(itemsRequests: [ItemsRequest], delegate: ShareViewDelegate, proceed: Binding<Bool>) {
        self.itemsRequests = itemsRequests
        self._delegate = StateObject(wrappedValue: delegate)
        var defaultSelected: [String: [String: [String: Bool]]] = [:]
        for itemRequest in itemsRequests {
            var defaultSelectedNamespaces: [String: [String: Bool]] = [:]
            for (namespace, namespaceItems) in itemRequest.namespaces {
                var defaultSelectedItems: [String: Bool] = [:]
                for (item, _) in namespaceItems {
                    defaultSelectedItems[item] = true
                }
                defaultSelectedNamespaces[namespace] = defaultSelectedItems
            }
            defaultSelected[itemRequest.docType] = defaultSelectedNamespaces
        }
        self.itemsSelected = defaultSelected
        self._proceed = proceed
    }
    
    public var body: some View {
        Button("Select items") {
            showingSDSheet.toggle()
        }
        .padding(10)
        .buttonStyle(.borderedProminent)
        .sheet(
            isPresented: $showingSDSheet,
            onDismiss: {
                switch delegate.state {
                case .canceled:
                    return
                default:
                    delegate.submitItems(items: itemsSelected)
                }
            }
        ) {
            SDSheetView(itemsSelected: $itemsSelected, itemsRequests: $itemsRequests, proceed: $proceed)
        }
    }
}


//struct SelectiveDisclosureView_Previews: PreviewProvider {
//    static var previews: some View {
//        let itemsRequest = ItemsRequest(docType: "mdl", namespaces: ["aamva": ["age": true, "location": false]])
//        SelectiveDisclosureView(itemsRequests: [itemsRequest])
//    }
//}

struct SDSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var itemsSelected: [String: [String: [String: Bool]]]
    @Binding var itemsRequests: [ItemsRequest]
    @Binding var proceed: Bool
    
    public var body: some View {
        NavigationStack {
            Form {
                ForEach(itemsRequests, id: \.self) { request in
                    let namespaces: [String: [String: Bool]] = request.namespaces
                    Section(header: Text(request.docType)) {
                        ForEach(Array(namespaces.keys), id: \.self) { namespace in
                            let namespaceItems: [String: Bool] = namespaces[namespace]!
                            ForEach(Array(namespaceItems.keys), id: \.self) { item in
                                let retain: Bool = namespaceItems[item]!
                                VStack {
                                    ItemToggle(selected: self.binding(docType: request.docType, namespace: namespace, item: item) , name: item)
                                    if retain {
                                        Text("This piece of information will be retained by the reader.").font(.system(size: 10))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select items")
            .toolbar(content: {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Cancel", role: .cancel) {
                        proceed = false
                        dismiss()
                    }.tint(.red)
                    Button("Share") {
                        dismiss()
                    }
                }
            })
        }
    }
    
    private func binding(docType: String, namespace: String, item: String) -> Binding<Bool> {
            return .init(
                get: { self.itemsSelected[docType]![namespace]![item]! },
                set: { self.itemsSelected[docType]![namespace]![item] = $0 })
        }

}

struct ItemToggle: View {
    @Binding var selected: Bool
    let name: String
    
    public var body: some View {
        Toggle(name, isOn: $selected)
    }
}

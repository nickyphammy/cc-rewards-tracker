import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Best Card", systemImage: "creditcard.and.123") {
                NavigationStack {
                    Text("Best Card")
                        .navigationTitle("Best Card")
                }
            }
            Tab("Wallet", systemImage: "wallet.bifold") {
                NavigationStack {
                    Text("Wallet")
                        .navigationTitle("Wallet")
                }
            }
        }
    }
}

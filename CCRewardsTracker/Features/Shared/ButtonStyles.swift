import SwiftUI

extension View {
    /// The one prominent button per screen: glass prominent, large, with a label color that keeps
    /// contrast on the accent fill in both light and dark mode.
    func primaryActionStyle() -> some View {
        buttonStyle(.glassProminent)
            .controlSize(.large)
            .foregroundStyle(Color("OnAccent"))
    }
}

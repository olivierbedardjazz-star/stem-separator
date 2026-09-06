import SwiftUI

struct ExitPresenceContainer<Item: Equatable, Overlay: View>: View {
    let item: Item?
    let exitDuration: Double
    @ViewBuilder let overlay: (_ item: Item, _ isExiting: Bool) -> Overlay

    @State private var renderedItem: Item?
    @State private var isExiting = false
    @State private var dismissalWorkItem: DispatchWorkItem?

    var body: some View {
        Group {
            if let renderedItem {
                overlay(renderedItem, isExiting)
            }
        }
        .onAppear {
            updatePresentation(for: item)
        }
        .onChange(of: item) { _, newValue in
            updatePresentation(for: newValue)
        }
    }

    private func updatePresentation(for newItem: Item?) {
        dismissalWorkItem?.cancel()
        dismissalWorkItem = nil

        guard let newItem else {
            guard renderedItem != nil else {
                isExiting = false
                return
            }

            withAnimation(AppMotion.exit) {
                isExiting = true
            }

            let workItem = DispatchWorkItem {
                renderedItem = nil
                isExiting = false
                dismissalWorkItem = nil
            }

            dismissalWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration, execute: workItem)
            return
        }

        renderedItem = newItem
        withAnimation(AppMotion.exit) {
            isExiting = false
        }
    }
}

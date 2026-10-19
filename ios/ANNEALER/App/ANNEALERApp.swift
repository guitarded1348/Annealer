import SwiftUI

@main
struct ANNEALERApp: App {
    @StateObject private var store = ContentStore.shared
    @StateObject private var player = AudioPlayer.shared
    @StateObject private var intake = IntakeStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(player)
                .environmentObject(intake)
                .preferredColorScheme(.dark)
                .tint(Palette.straw)
                .task { await store.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await ContentStore.shared.refresh() }
            }
        }
    }
}

/// The first launch is an unboxing; every launch after that opens straight onto the workshop floor.
struct RootView: View {
    @AppStorage("annealer.unboxed") var unboxed = false

    var body: some View {
        ZStack {
            if unboxed {
                FloorView()
                    .transition(.opacity)
            } else {
                UnboxingView {
                    withAnimation(.easeInOut(duration: 0.8)) { unboxed = true }
                }
                .transition(.opacity)
            }
        }
    }
}

import SwiftUI

@main
struct ARKitOcclusionApp: App {
    var body: some Scene {
        WindowGroup {
            let controller = ARController()
            ARViewContainer(controller: controller).edgesIgnoringSafeArea(.all)
        }
    }
}

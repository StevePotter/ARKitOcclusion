import SwiftUI

struct ContentView: View {
    var body: some View {
        let controller = ARController()
        ARViewContainer(controller: controller).edgesIgnoringSafeArea(.all)
    }
}

import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    var controller: ARController
    
    func makeUIView(context: Context) -> ARSCNView {
        return controller.createARView()
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
}

import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    var controller: ARController
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.automaticallyUpdatesLighting = true
        controller.sceneView = arView
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics.insert(.sceneDepth)
        configuration.frameSemantics.insert(.smoothedSceneDepth)

        arView.session.delegate = controller
        arView.session.run(configuration)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
}

import Foundation
import ARKit
import SceneKit

/// This class manages everything related to ARKit and SceneKit
class ARController: NSObject  {
    var sceneView: ARSCNView? = nil
    private let cylinderLength: Float = 1.0
    private var cylinderMaterial: SCNMaterial? = nil

    func createARView() -> ARSCNView {
        let arView = ARSCNView()
        arView.automaticallyUpdatesLighting = true
        self.sceneView = arView
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics.insert(.sceneDepth)
        configuration.frameSemantics.insert(.smoothedSceneDepth)

        arView.session.delegate = self
        arView.session.run(configuration)
        return arView
    }

    func createCylinder(sceneView: ARSCNView) -> SCNNode {
        // Create a long thin cylinder
        let cylinder = SCNCylinder(radius: 0.04, height: CGFloat(cylinderLength))

        // Create a material and assign a color
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.shaderModifiers = [
            .fragment: fragmentShader
        ]
        cylinder.materials = [material]

        return SCNNode(geometry: cylinder)
    }
    
    /// Positions the cylinder slightly in front of the camera as if it were laying down facing away
    func positionCylinder(cylinderNode: SCNNode, sceneView: ARSCNView) {
        let distanceInFrontOfCamera: Float = 0.01  // 10 cm in front of the camera
        cylinderNode.position = SCNVector3(0, 0, -(cylinderLength + distanceInFrontOfCamera))

        // Rotate the cylinder to lay along the camera's z-axis
        cylinderNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
    }

    func setCylinderMaterialProperties(depthMap: CVPixelBuffer, cameraSize: CGSize, axisMaterial: SCNMaterial) {
        guard let depthMap = pixelBufferToImage(depthMap, targetSize: cameraSize) else {
            print("Error: could not convert depth map to image")
            return
        }
        axisMaterial.setValue(SCNMaterialProperty(contents: depthMap), forKey: "depthMap") // todo: is there a more optimal way to do this, like using MTLTexture?
        axisMaterial.setValue(CGFloat(cameraSize.width), forKey: "screenWidth")
        axisMaterial.setValue(CGFloat(cameraSize.height), forKey: "screenHeight")
    }
}

extension ARController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // note: you can also try frame.smoothedSceneDepth?.depthMap
        guard let sceneView = self.sceneView, let depthData = frame.sceneDepth?.depthMap else {
            return
        }
        if let cylinderMaterial = self.cylinderMaterial {
            setCylinderMaterialProperties(depthMap: depthData, cameraSize: frame.camera.imageResolution, axisMaterial: cylinderMaterial)
        } else {
            let cylinderNode = createCylinder(sceneView: sceneView)
            let cylinderMaterial = cylinderNode.geometry!.firstMaterial!
            self.cylinderMaterial = cylinderMaterial
            setCylinderMaterialProperties(depthMap: depthData, cameraSize: frame.camera.imageResolution, axisMaterial: cylinderMaterial)
            positionCylinder(cylinderNode: cylinderNode, sceneView: sceneView)
            sceneView.scene.rootNode.addChildNode(cylinderNode)
        }
    }
}


let fragmentShader = """
#pragma arguments
texture2d<float, access::sample> depthMap;
float screenWidth;
float screenHeight;

#pragma body
constexpr sampler depthSampler(coord::pixel);

float4 modelSpacePosition = scn_node.modelViewTransform * float4(_surface.position, 1);
// the depth, in meters, of the fragment from the camera
float modelDepth = -modelSpacePosition.z;

float2 screenPosition = _surface.diffuseTexcoord * float2(screenWidth, screenHeight);
float physicalDepth = depthMap.sample(depthSampler, screenPosition).r;

// if the depth map detects something before this fragment, don't paint
if (physicalDepth <= modelDepth) {
   discard_fragment();
}
"""

/// Converts a pixel buffer into a CGImage and resizes it appropriately
func pixelBufferToImage(_ buffer: CVPixelBuffer, targetSize: CGSize) -> CGImage? {
    let ciContext = CIContext()
    let ciImage = CIImage(cvPixelBuffer: buffer)

    // Create a CGAffineTransform to resize the image
    let scaleX = targetSize.width / ciImage.extent.width
    let scaleY = targetSize.height / ciImage.extent.height
    let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)

    // Apply the transform
    let scaledImage = ciImage.transformed(by: scaleTransform)

    // Create a CGImage from the scaled CIImage
    return ciContext.createCGImage(scaledImage, from: scaledImage.extent)
}


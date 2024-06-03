import Foundation
import ARKit
import SceneKit

/// This class manages everything related to ARKit and SceneKit
class ARController: NSObject  {
    var sceneView: ARSCNView? = nil
    private let boxLength: Float = 1.0
    private var boxMaterial: SCNMaterial? = nil

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

    func createBox(sceneView: ARSCNView) -> SCNNode {
        let box = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0)

        // Create a material and assign a color
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.shaderModifiers = [
            .fragment: fragmentShader
        ]
        box.materials = [material]

        return SCNNode(geometry: box)
    }
    
    /// Positions the box slightly in front of the camera as if it were laying down facing away
    func positionBox(boxNode: SCNNode, sceneView: ARSCNView) {
        let distanceInFrontOfCamera: Float = 0.01  // 10 cm in front of the camera
        boxNode.position = SCNVector3(0, 0, -(boxLength + distanceInFrontOfCamera))
    }

    func setBoxMaterialProperties(depthMap: CVPixelBuffer, cameraSize: CGSize, material: SCNMaterial) {
        guard let depthMap = pixelBufferToImage(depthMap, targetSize: cameraSize) else {
            print("Error: could not convert depth map to image")
            return
        }
        material.setValue(SCNMaterialProperty(contents: depthMap), forKey: "depthMap") // todo: is there a more optimal way to do this, like using MTLTexture?
        material.setValue(CGFloat(cameraSize.width), forKey: "screenWidth")
        material.setValue(CGFloat(cameraSize.height), forKey: "screenHeight")
    }
}

extension ARController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // note: you can also try frame.smoothedSceneDepth?.depthMap
        guard let sceneView = self.sceneView, let depthData = frame.sceneDepth?.depthMap else {
            return
        }
        if let boxMaterial = self.boxMaterial {
            setBoxMaterialProperties(depthMap: depthData, cameraSize: frame.camera.imageResolution, material: boxMaterial)
        } else {
            let boxNode = createBox(sceneView: sceneView)
            let boxMaterial = boxNode.geometry!.firstMaterial!
            self.boxMaterial = boxMaterial
            setBoxMaterialProperties(depthMap: depthData, cameraSize: frame.camera.imageResolution, material: boxMaterial)
            positionBox(boxNode: boxNode, sceneView: sceneView)
            sceneView.scene.rootNode.addChildNode(boxNode)
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

// screenPosition IS DEFINITELY WRONG.  I think it will require some math with scn_node.inverseModelViewTransform or scn_node.modelViewProjectionTransform
float2 screenPosition = _surface.diffuseTexcoord * float2(screenWidth, screenHeight); // x and y pixel coordinates of this fragment on the screen
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


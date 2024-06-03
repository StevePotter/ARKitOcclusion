import Foundation
import ARKit
import SceneKit

/// This class manages everything related to ARKit and SceneKit
class ARController: NSObject  {
    var sceneView: ARSCNView? = nil
    
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

    func createCylinder() -> SCNNode {
        // Create a cylinder that is thin and long
        let cylinder = SCNCylinder(radius: 0.008, height: 1.0)

        // Create a material and assign a color
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.shaderModifiers = [
            .fragment: fragmentShader
        ]
        cylinder.materials = [material]

        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position = SCNVector3(x: 0, y: 0, z: -0.1)  // Position the cylinder starting at the camera

        // align along the z-axis
        cylinderNode.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: 0)
        
        return cylinderNode
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
            let cylinderNode = createCylinder()
            let cylinderMaterial = cylinderNode.geometry!.firstMaterial!
            self.cylinderMaterial = cylinderMaterial
            setCylinderMaterialProperties(depthMap: depthData, cameraSize: frame.camera.imageResolution, axisMaterial: cylinderMaterial)
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

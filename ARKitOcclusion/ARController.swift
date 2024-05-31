//
//  ARController.swift
//  ARKitOcclusion
//
//  Created by Stephen Potter on 5/31/24.
//

import Foundation
import ARKit
import SceneKit

class ARController: NSObject  {
    var sceneView: ARSCNView? = nil
    
    private var cylinderMaterial: SCNMaterial? = nil

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
        axisMaterial.setValue(SCNMaterialProperty(contents: depthMap), forKey: "depthMap")
        axisMaterial.setValue(CGFloat(cameraSize.width), forKey: "screenWidth")
        axisMaterial.setValue(CGFloat(cameraSize.height), forKey: "screenHeight")
    }
}

extension ARController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let sceneView = self.sceneView, let depthData = frame.smoothedSceneDepth?.depthMap else {
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

float4 model_space_position = scn_node.modelViewTransform * float4(_surface.position, 1);
float modelDepth = -model_space_position.z;

float2 screenPosition = _surface.diffuseTexcoord * float2(screenWidth, screenHeight);
float depthValue = depthMap.sample(depthSampler, screenPosition).r;

if (depthValue <= modelDepth) {
   discard_fragment();
} else {
   _output.color.a = 1.0;
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

# Occlusion of Virtual Objects in ARKit and SceneKit

I'm tackling an exciting challenge using iOS ARKit/SceneKit: occluding virtual objects (like a drawn axis) with physical objects (like a drill) in an AR environment. This issue arises when trying to align a drill with a virtual axis in my app, which assists users in drilling holes accurately.

## Problem Statement
In my AR iPhone app, virtual content (axis drawn as `SCNCylinder`) should not be visible when physical objects are in front of it. However, currently, the axis is drawn over the drill irrespective of their relative positions. Although RealityKit offers [some occlusion capabilities](https://developer.apple.com/documentation/realitykit/arview/environment-swift.struct/sceneunderstanding-swift.struct/options-swift.struct/occlusion), it doesn't suit my specific needs as it doesn't recognize the drill as an occluder.

## Approach
Here’s how I’m approaching the solution:
- **Scene Setup**: When the app loads, it creates a `SCNBox` and adds it to the scene.
- **Shader Implementation**: I apply a material with a `.fragment` `shaderModifier` to the box. This shader uses the lidar depth map to decide whether to render each pixel.
- **Depth Comparison**:
  1. Obtain screen coordinates of the fragment.
  2. Fetch the physical depth from the depth map.
  3. Compare it with the virtual depth.
  4. Render the pixel only if the virtual object is closer than the physical object.

The shader likely contains the root of the issues, although I suspect there's room for optimization and accuracy improvements.

## Get Involved
I’d love your input or help on this project! Check out [ARController.swift](https://github.com/StevePotter/ARKitOcclusion/blob/main/ARKitOcclusion/ARController.swift) to see the core logic. Whether you’re experienced in AR development or just starting, your contributions are welcome. Also, I'm offering a special gift for anyone who can solve this!

### Discuss and Collaborate
Have ideas or need clarification? Start a discussion in the Issues section or contact me directly at [email]. Let’s make AR development better together!

## Thank You!
Thanks for checking out my project. I look forward to your insights and contributions. Happy coding!

# Best Camera Positions

## Phase 1: Scene & Asset Setup

- [x] Import Field Model: Bring in your 3D field/game arena as a static body with collision.
- [x] Create Tag Template:
  - [x] Create a Node3D with a simple Quad mesh.
  - [x] Add four Marker3D nodes at the exact corners of the quad.
  - [x] Add the Tag to a specific Physics Layer (e.g., Layer 2) to keep raycasts clean.
- [x] Place Tags: Instance the tags throughout the field at their real-world XYZ positions and rotations.
  - [x] Import from existing file?
- [x] Robot Proxy: Create a Node3D to represent the robot (the "origin" for your tests).

## Phase 2: Logic & Math (The "Visibility Script")

- [x] Field of View (FOV) Filter: Implement a Dot Product check to ensure tags are within the camera’s horizontal and vertical cone.
- [x] Distance Filter: Define a MAX_DISTANCE constant (e.g., 5 meters) to simulate camera resolution limits.
- [x] Tag Skew filter: define a max skew, and filter by that
- [x] Multi-Point Raycasting: 
  - [x] Access PhysicsDirectSpaceState3D.
  - [x] Loop through the 4 Marker3D nodes on a tag.
  - [x] Verify that all four rays return no obstructions (or hit the tag itself)-

## Phase 3: The Data Runner (Grid Search)

- [x] Define Grid Parameters: Set your X and Y bounds and the step size (e.g., every 0.5 meters).
- [x] Define Rotation Steps: Set your angular increment (e.g., 45∘).
- [x] The Nested Loop:
  - [x] Loop through X positions.
  - [x] Loop through Y positions.
  - [x] Loop through Rotations.
- [x] Data Capture:
  - [x] Move the Robot Proxy to the current XYZ.
  - [x] Run the visibility check.
  - [x] Store the results in a Dictionary or Array

## Phase 4: Output & Export

- [ ] Console Logger: Print a live status (e.g., "Testing position (12, 4)...").
- [x] File Export: Write the final data to a .csv or .json file for analysis.
  - Fields to include: x_pos, y_pos, rotation, tags_visible_count.
- [ ] Visual Debugger: Create a script that draws a green/red dot at each grid point in the Godot Editor to visualize the "dead zones" immediately

## Phase 5: Moving the camera

- [ ] Create restrictions for camera poses that can be modeled as boxes
  - [ ] Store a 'drivetrain width' and 'drivetrain length' variable 
  - [ ] Add a node for boxes for avaliable space
  - [ ] variables for max and min pitch
- [ ] Nested Loop For Camera Poses:
  - [ ] Check that the new camera pose is within the drivetrain limits
  - [ ] Check that the new camera rotation is within limits
  - [ ] X
  - [ ] Y
  - [ ] Yaw 
  - [ ] Pitch
  
## Bonus: Robotics Specifics

- [ ] Dual Cameras: If your robot has two cameras, run the check twice per position (once for each camera offset) and combine the unique tags seen.
  - [ ] Run with 2025 camera configs
 
## Other Wants:
- [ ] Make it so the JSON is a dropdown for the april tags, so it reads from the internet
- [ ] Make the collisions automatic for the raycasts, so a model doesn't need to be made
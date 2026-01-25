# Best Camera Positions

## Phase 1: Scene & Asset Setup

- [x] Import Field Model: Bring in your 3D field/game arena as a static body with collision.
- [] Create Tag Template:
  - [x] Create a Node3D with a simple Quad mesh.
  - [x] Add four Marker3D nodes at the exact corners of the quad.
  - [x] Add the Tag to a specific Physics Layer (e.g., Layer 2) to keep raycasts clean.
- [x] Place Tags: Instance the tags throughout the field at their real-world XYZ positions and rotations.
  - [x] Import from existing file?
- [ ] Robot Proxy: Create a Node3D to represent the robot (the "origin" for your tests).

## Phase 2: Logic & Math (The "Visibility Script")

- [ ] Field of View (FOV) Filter: Implement a Dot Product check to ensure tags are within the camera’s horizontal and vertical cone.
- [ ] Distance Filter: Define a MAX_DISTANCE constant (e.g., 5 meters) to simulate camera resolution limits.
- [ ] Angle of Incidence Filter: Ensure the robot isn't looking at the back of a tag or at a graze angle (>70°).
- [ ] Multi-Point Raycasting: 
  - [ ] Access PhysicsDirectSpaceState3D.
  - [ ] Loop through the 4 Marker3D nodes on a tag.
  - [ ] Verify that all four rays return no obstructions (or hit the tag itself)-

## Phase 3: The Data Runner (Grid Search)

- [ ] Define Grid Parameters: Set your X and Y bounds and the step size (e.g., every 0.5 meters).
- [ ] Define Rotation Steps: Set your angular increment (e.g., 45∘).
- [ ] The Nested Loop:
  - [ ] Loop through X positions.
  - [ ] Loop through Y positions.
  - [ ] Loop through Rotations.
- [ ] Data Capture:
  - [ ] Move the Robot Proxy to the current XYZ.
  - [ ] Run the visibility check.
  - [ ] Store the results in a Dictionary or Array

## Phase 4: Output & Export

- [ ] Console Logger: Print a live status (e.g., "Testing position (12, 4)...").
- [ ] File Export: Write the final data to a .csv or .json file for analysis.
  - Fields to include: x_pos, y_pos, rotation, tags_visible_count.
- [ ] Visual Debugger: Create a script that draws a green/red dot at each grid point in the Godot Editor to visualize the "dead zones" immediately

## Bonus: Robotics Specifics

- [ ] Dual Cameras: If your robot has two cameras, run the check twice per position (once for each camera offset) and combine the unique tags seen.
  - [ ] Run with 2025 camera configs
 
## Other Wants:
- [ ] Make it so the JSON is a dropdown for the april tags, so it reads from the internet
- [ ] Make the collisions automatic for the raycasts, so a model doesn't need to be made
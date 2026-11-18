#!/usr/bin/env bash
# One-click start for the rover simulation.
# Opens two terminal windows:
#   1. Simulation   - Gazebo + RViz (ros2 launch rover_description sim.launch.py)
#   2. WASD Teleop  - the driving window, started once Gazebo has had time to load
#
# Keep this file in your ros2_ws folder. It finds the workspace from its own
# location, so the space in "Robot Development" is not a problem.
#
# Usage:  ./start_rover_sim.sh           start everything
#         ./start_rover_sim.sh --build   rebuild the workspace first

WS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEOP_DELAY=8   # seconds to wait for Gazebo before opening the teleop window

if [ ! -f "$WS/src/rover_description/package.xml" ]; then
  zenity --error --text="start_rover_sim.sh must be in your ros2_ws folder.\nIt is currently in:\n$WS" 2>/dev/null \
    || echo "start_rover_sim.sh must be in your ros2_ws folder (currently in $WS)"
  exit 1
fi

# Close any Gazebo or ROS nodes left over from an earlier run. Two Gazebo
# servers running at once both drive a rover, and the GUI and RViz flicker
# between the two robots' positions.
pkill -f "gz sim" 2>/dev/null
pkill -f "ros_gz_bridge" 2>/dev/null
pkill -f "robot_state_publisher" 2>/dev/null
pkill -f "tfluna_scan_to_range" 2>/dev/null
pkill -f "wasd_teleop" 2>/dev/null
sleep 1

# Downloads and git checkouts can drop the "executable" flag on the Python
# scripts, and ros2 then reports "No executable found". Restore it every time.
chmod +x "$WS"/src/rover_description/scripts/*.py 2>/dev/null

# Build if asked, or if the workspace has never been built
BUILD_STEP=""
if [ "$1" = "--build" ] || [ ! -f "$WS/install/setup.bash" ]; then
  BUILD_STEP="echo 'Building workspace...' && colcon build --symlink-install && "
  TELEOP_DELAY=60   # give the build time to finish too
fi

QWS=$(printf '%q' "$WS")
SETUP="cd $QWS && source /opt/ros/jazzy/setup.bash"

# Window 1: simulation (Gazebo + RViz)
gnome-terminal --title="Rover Simulation" -- bash -c \
  "$SETUP && ${BUILD_STEP}source install/setup.bash && ros2 launch rover_description sim.launch.py; echo; echo 'Simulation stopped. Press Enter to close.'; read"

# Window 2: WASD teleop, started after Gazebo has had time to load
gnome-terminal --title="Rover Teleop" -- bash -c \
  "$SETUP && echo 'Waiting $TELEOP_DELAY s for Gazebo to load...' && sleep $TELEOP_DELAY && source install/setup.bash && ros2 run rover_description wasd_teleop.py; echo; echo 'Teleop closed. Press Enter to close.'; read"

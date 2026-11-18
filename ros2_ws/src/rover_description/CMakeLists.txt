cmake_minimum_required(VERSION 3.8)
project(rover_description)

find_package(ament_cmake REQUIRED)

install(DIRECTORY urdf launch worlds rviz
  DESTINATION share/${PROJECT_NAME})

# WASD teleop node: run with  ros2 run rover_description wasd_teleop.py
install(PROGRAMS scripts/wasd_teleop.py scripts/tfluna_scan_to_range.py
  DESTINATION lib/${PROJECT_NAME})

ament_package()

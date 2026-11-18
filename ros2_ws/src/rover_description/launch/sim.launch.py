import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
import xacro


def generate_launch_description():
    pkg = get_package_share_directory('rover_description')
    xacro_file = os.path.join(pkg, 'urdf', 'rover.urdf.xacro')
    world_file = os.path.join(pkg, 'worlds', 'rover_world.sdf')
    rviz_file = os.path.join(pkg, 'rviz', 'rover.rviz')

    # ros2 launch rover_description sim.launch.py rviz:=false  to skip RViz
    rviz_arg = DeclareLaunchArgument('rviz', default_value='true',
                                     description='Open RViz with the rover layout')

    # Process xacro in Python (not through a shell) so paths with spaces work
    robot_description = xacro.process_file(xacro_file).toxml()

    # Publishes the robot's TF tree from the URDF + /joint_states
    robot_state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        parameters=[{'robot_description': robot_description, 'use_sim_time': True}],
        output='screen',
    )

    # Starts Gazebo Harmonic with our world (-r = start running immediately)
    gazebo = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(get_package_share_directory('ros_gz_sim'), 'launch', 'gz_sim.launch.py')
        ),
        launch_arguments={'gz_args': f'-r -v 3 "{world_file}"'}.items(),
    )

    # Spawns the robot from the /robot_description topic
    spawn = Node(
        package='ros_gz_sim',
        executable='create',
        arguments=['-topic', 'robot_description', '-name', 'rover', '-z', '0.02'],
        output='screen',
    )

    # ]  = ROS -> Gazebo,   [  = Gazebo -> ROS
    bridge = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        arguments=[
            '/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock',
            '/cmd_vel@geometry_msgs/msg/Twist]gz.msgs.Twist',
            '/odom@nav_msgs/msg/Odometry[gz.msgs.Odometry',
            '/tf@tf2_msgs/msg/TFMessage[gz.msgs.Pose_V',
            '/joint_states@sensor_msgs/msg/JointState[gz.msgs.Model',
            '/tfluna_front/scan@sensor_msgs/msg/LaserScan[gz.msgs.LaserScan',
            '/tfluna_rear/scan@sensor_msgs/msg/LaserScan[gz.msgs.LaserScan',
        ],
        parameters=[{'use_sim_time': True}],
        output='screen',
    )

    # Turns each TF-Luna's 5-ray scan into one Range reading, like the real sensor
    tfluna_range = Node(
        package='rover_description',
        executable='tfluna_scan_to_range.py',
        parameters=[{'use_sim_time': True}],
        output='screen',
    )

    # RViz with the saved layout: robot model, frames, front TF-Luna (orange), rear TF-Luna (blue)
    rviz = Node(
        package='rviz2',
        executable='rviz2',
        arguments=['-d', rviz_file],
        parameters=[{'use_sim_time': True}],
        condition=IfCondition(LaunchConfiguration('rviz')),
        output='screen',
    )

    return LaunchDescription([rviz_arg, robot_state_publisher, gazebo, spawn, bridge, tfluna_range, rviz])

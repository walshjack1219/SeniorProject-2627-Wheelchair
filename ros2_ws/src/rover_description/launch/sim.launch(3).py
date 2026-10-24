import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import Node
import xacro


def generate_launch_description():
    pkg = get_package_share_directory('rover_description')
    xacro_file = os.path.join(pkg, 'urdf', 'rover.urdf.xacro')
    world_file = os.path.join(pkg, 'worlds', 'rover_world.sdf')

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
        arguments=['-topic', 'robot_description', '-name', 'rover', '-z', '0.05'],
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
            '/scan_front@sensor_msgs/msg/LaserScan[gz.msgs.LaserScan',
            '/scan_rear@sensor_msgs/msg/LaserScan[gz.msgs.LaserScan',
        ],
        parameters=[{'use_sim_time': True}],
        output='screen',
    )

    return LaunchDescription([robot_state_publisher, gazebo, spawn, bridge])

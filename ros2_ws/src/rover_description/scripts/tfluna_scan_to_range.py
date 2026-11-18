#!/usr/bin/env python3
"""
Converts each simulated TF-Luna's 5-ray LaserScan into one sensor_msgs/Range,
the same message type a real TF-Luna ROS driver publishes.

  /tfluna_front/scan -> /tfluna_front/range
  /tfluna_rear/scan  -> /tfluna_rear/range

Like the real sensor, the reading is the closest thing inside the 2 degree cone.
Nothing in range reports +inf (ROS convention for "no target").
"""
import math

import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data
from sensor_msgs.msg import LaserScan, Range

FOV = math.radians(2.0)   # datasheet: 2 degrees
MIN_RANGE = 0.2           # datasheet: 0.2 m
MAX_RANGE = 8.0           # datasheet: 8 m (bright targets)


class TfLunaScanToRange(Node):
    def __init__(self):
        super().__init__('tfluna_scan_to_range')
        self.sensor_pubs = {}
        for name in ('tfluna_front', 'tfluna_rear'):
            pub = self.create_publisher(Range, f'/{name}/range', 10)
            self.sensor_pubs[name] = pub
            self.create_subscription(
                LaserScan, f'/{name}/scan',
                lambda msg, p=pub: self.convert(msg, p),
                qos_profile_sensor_data)

    def convert(self, scan, pub):
        valid = [r for r in scan.ranges if math.isfinite(r) and MIN_RANGE <= r <= MAX_RANGE]
        out = Range()
        out.header = scan.header
        out.radiation_type = Range.INFRARED
        out.field_of_view = FOV
        out.min_range = MIN_RANGE
        out.max_range = MAX_RANGE
        out.range = min(valid) if valid else math.inf
        pub.publish(out)


def main():
    rclpy.init()
    node = TfLunaScanToRange()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
WASD teleop for the rover.

Opens a small window. Click it to give it focus, then:
  W / S    drive forward / backward
  A / D    turn left / right (hold with W or S to arc)
  Shift    hold to boost
  Space    brake (overrides all other keys)
  Q / E    lower / raise top speed
  Esc      quit (the robot stops)

The robot only moves while keys are held, and it stops when the window
loses focus, so clicking away is always a safe stop.
"""
import pygame
import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node

# Window colors
BG = (24, 24, 28)
TEXT = (220, 220, 220)
DIM = (130, 130, 140)
KEY_OFF = (55, 55, 62)
KEY_ON = (240, 130, 30)
WARN = (230, 90, 80)


class WasdTeleop(Node):
    def __init__(self):
        super().__init__('wasd_teleop')
        # Defaults match the prototype: 160 rpm motors on 0.033 m wheels = ~0.55 m/s,
        # and the joystick's 78% steering cap on a 0.184 m track = ~4.7 rad/s.
        self.declare_parameter('linear_speed', 0.55)  # m/s at 1.0x
        self.declare_parameter('angular_speed', 4.7)  # rad/s at 1.0x
        self.declare_parameter('boost', 1.0)          # multiplier while Shift is held (1.0 = off, since 1.0x is already full motor speed)
        self.declare_parameter('rate', 20.0)          # Hz
        self.linear = self.get_parameter('linear_speed').value
        self.angular = self.get_parameter('angular_speed').value
        self.boost = self.get_parameter('boost').value
        self.rate = self.get_parameter('rate').value
        self.pub = self.create_publisher(Twist, 'cmd_vel', 10)


def draw_key(screen, font, label, x, y, pressed, w=48, h=48):
    pygame.draw.rect(screen, KEY_ON if pressed else KEY_OFF, (x, y, w, h), border_radius=8)
    text = font.render(label, True, BG if pressed else TEXT)
    screen.blit(text, text.get_rect(center=(x + w // 2, y + h // 2)))


def main():
    rclpy.init()
    node = WasdTeleop()

    pygame.init()
    screen = pygame.display.set_mode((480, 260))
    pygame.display.set_caption('Rover WASD Teleop')
    key_font = pygame.font.SysFont('monospace', 22, bold=True)
    font = pygame.font.SysFont('monospace', 15)
    clock = pygame.time.Clock()

    scale = 1.0
    running = True
    try:
        while running and rclpy.ok():
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    elif event.key == pygame.K_e:
                        scale = min(round(scale + 0.1, 1), 1.0)  # 1.0x = real motors' top speed
                    elif event.key == pygame.K_q:
                        scale = max(round(scale - 0.1, 1), 0.1)

            keys = pygame.key.get_pressed()
            focused = pygame.key.get_focused()
            braking = keys[pygame.K_SPACE]
            boosting = keys[pygame.K_LSHIFT] or keys[pygame.K_RSHIFT]

            fwd = int(keys[pygame.K_w]) - int(keys[pygame.K_s])
            turn = int(keys[pygame.K_a]) - int(keys[pygame.K_d])
            if braking or not focused:
                fwd = turn = 0
            mult = scale * (node.boost if boosting else 1.0)

            msg = Twist()
            msg.linear.x = fwd * node.linear * mult
            msg.angular.z = turn * node.angular * mult
            node.pub.publish(msg)

            # ---- draw ----
            screen.fill(BG)
            draw_key(screen, key_font, 'W', 84, 24, keys[pygame.K_w])
            draw_key(screen, key_font, 'A', 28, 80, keys[pygame.K_a])
            draw_key(screen, key_font, 'S', 84, 80, keys[pygame.K_s])
            draw_key(screen, key_font, 'D', 140, 80, keys[pygame.K_d])
            draw_key(screen, font, 'SHIFT', 28, 140, boosting, w=104, h=36)
            draw_key(screen, font, 'SPACE', 140, 140, braking, w=104, h=36)

            lines = [
                (f'speed scale  {scale:.1f}x   (Q / E)', TEXT),
                (f'linear   {msg.linear.x:+.2f} m/s', TEXT),
                (f'angular  {msg.angular.z:+.2f} rad/s', TEXT),
                ('Shift boost   Space brake', DIM),
                ('Esc quit', DIM),
            ]
            for i, (line, color) in enumerate(lines):
                screen.blit(font.render(line, True, color), (220, 34 + i * 26))

            if not focused:
                warn = font.render('Click this window to drive', True, WARN)
                screen.blit(warn, (28, 216))

            pygame.display.flip()
            rclpy.spin_once(node, timeout_sec=0)
            clock.tick(node.rate)
    finally:
        node.pub.publish(Twist())  # always leave the robot stopped
        pygame.quit()
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == '__main__':
    main()

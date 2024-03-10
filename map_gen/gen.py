import math
import random
import matplotlib
from matplotlib import pyplot as plt, patches

class Point:
    def __init__(self, x : float, y : float):
        self.x = x
        self.y = y

class Circle:
    def __init__(self, point : Point, radius : float):
        self.point = point
        self.radius = radius

def overlap(c1 : Circle, c2 : Circle):
    d = math.sqrt((c1.point.x - c2.point.x) * (c1.point.x - c2.point.x) + (c1.point.y - c2.point.y) * (c1.point.y - c2.point.y))

    is_overlap = True

    if d <= c1.radius - c2.radius:
        print("Circle B is inside A")
    elif d <= c2.radius - c1.radius:
        print("Circle A is inside B")
    elif d < c1.radius + c2.radius:
        print("Circle intersect to each other")
    elif d == c1.radius + c2.radius:
        print("Circle touch to each other")
    else:
        print("Circle not touch to each other")
        is_overlap = False


    return is_overlap


# define a rectangle
width = 18
height = 22


n_circles = 3

circles = [Circle(Point(0.0, 0.0), 5), Circle(Point(0.0, 0.0), 5)]

#random.seed(50)

for i in range(len(circles)):
    c = circles[i]
    overlapping = True

    while overlapping:
        x_pos = random.randint(0, width-(c.radius*2))+c.radius
        y_pos = random.randint(0, height-(c.radius*2))+c.radius
        print(f"x={x_pos}, y={y_pos}")
        c.point.x = x_pos
        c.point.y = y_pos

        overlapping = False
        for j in range(i):
            print(f"comparing to {j}")
            if overlap(c, circles[j]):
                overlapping = True
                break

    print(f"{c.point.x}, {c.point.y}, {c.radius}")

plt.rcParams["figure.figsize"] = [7, 4]
plt.rcParams["figure.autolayout"] = True
fig = plt.figure()
ax = fig.add_subplot(111)
rect = patches.Rectangle((0, 0), width, height, color='yellow')
ax.add_patch(rect)

for i in range(len(circles)):
    c = circles[i]
    circle = patches.Circle((c.point.x, c.point.y), radius=c.radius, color='red')
    ax.add_patch(circle)

    rad = c.radius
    side_len = math.sqrt(2) * rad
    square = patches.Rectangle((c.point.x-side_len/2, c.point.y-side_len/2), side_len, side_len, color='blue')
    ax.add_patch(square)


# plt.xlim([-10, 10])
# plt.ylim([-10, 10])
plt.axis('equal')
plt.show()


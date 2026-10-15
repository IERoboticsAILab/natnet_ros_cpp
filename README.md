# NatNet ROS 2 driver

Streams rigid bodies from OptiTrack Motive into ROS 2, using the NatNet protocol.

This is the [IE Robotics & AI Lab](https://github.com/IERoboticsAILab) fork of [L2S-lab/natnet_ros2](https://github.com/L2S-lab/natnet_ros2), with fixes for Motive 3.x:

- [FORK_CHANGELOG.md](FORK_CHANGELOG.md): every change and the issue it fixes
- [BEHAVIOUR_CHANGES.md](BEHAVIOUR_CHANGES.md): what works differently from upstream

| Branch | For |
|---|---|
| `ros1` | ROS 1 Noetic |
| `ros2` (this one) | ROS 2 (tested on Galactic) |
| `main` | unchanged upstream (ROS 1) |

Tested with Motive 3.5, NatNet SDK 4.4, ROS 2 Galactic and Ubuntu 20.04: 120 Hz per body at about 3-4% of one CPU core. Upstream also builds on Humble and Jazzy.

## Install

```
sudo apt install -y ros-$ROS_DISTRO-tf2* wget
cd ~/ros2_ws/src
git clone -b ros2 https://github.com/IERoboticsAILab/natnet_ros_cpp natnet_ros2
cd ..
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release
source install/setup.bash
```

The first build downloads the NatNet SDK into `deps/NatNetSDK`, so it needs internet.

## Motive settings

In Motive, open the **Streaming** panel:

- **NatNet**: Enable on
- **Local Interface**: the Motive PC's IP on the network the robots use
- **Transmission Type**: Unicast or Multicast (must match `serverType` below)
- **Rigid Bodies**: on
- **Up Axis**: Z

Allow NatNet through the Motive PC's firewall (UDP ports 1510 and 1511).

## Run

```
ros2 launch natnet_ros2 natnet_ros2.launch.py serverIP:=<motive-ip> clientIP:=<this-pc-ip> serverType:=unicast
```

Each rigid body is published as `geometry_msgs/PoseStamped` on `/<body-name>/pose`, and as a TF frame `<body-name>` under `world`. A body Motive is not tracking is not published.

There is also a GUI: `ros2 launch natnet_ros2 gui_natnet_ros2.launch.py`

## Options

Pass these as `name:=value` to `ros2 launch`.

| Option | Default | What it does |
|---|---|---|
| `serverIP` | | IP of the Motive PC |
| `clientIP` | | IP of the PC running this driver |
| `serverType` | `multicast` | `unicast` or `multicast`, same as in Motive |
| `global_frame` | `world` | Frame the poses are in |
| `activate` | `true` | Start publishing right away (the node is a lifecycle node) |
| `pub_rigid_body` | `true` | Publish rigid body poses and TF |
| `pub_untracked_rigid_body` | `false` | Keep publishing a body's last pose while Motive is not tracking it |
| `pub_rigid_body_marker` | `false` | Publish each body's markers on `/<body-name>/marker#/pose` |
| `pub_individual_marker` | `false` | Track single markers (see below) |
| `immt` | `PoseStamped` | Message type for single markers: `PoseStamped` or `PointStamped` |
| `pub_pointcloud` | `false` | Publish all markers as one `sensor_msgs/PointCloud` |
| `remove_latency` | `false` | Stamp messages with the camera exposure time instead of the arrival time |
| `log_frames`, `log_latencies`, `log_internals` | `false` | Print debug information |

## Tracking a single marker

A single marker can be published as a pose with fixed orientation:

1. Copy `config/initiate.yaml`, then add the marker's name and starting position (the file explains each field). `log_frames:=true` prints marker positions if you need to find it.
2. Launch with `pub_individual_marker:=true conf_file:=<your-file>.yaml`.

## Credits

Original driver by [L2S-lab](https://github.com/L2S-lab). If you use it in a publication, please cite [hal-04150950](https://hal.science/hal-04150950).

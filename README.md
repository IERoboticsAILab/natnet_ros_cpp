# NatNet ROS driver

Streams rigid bodies from OptiTrack Motive into ROS, using the NatNet protocol.

This is the [IE Robotics & AI Lab](https://github.com/IERoboticsAILab) fork of [L2S-lab/natnet_ros_cpp](https://github.com/L2S-lab/natnet_ros_cpp), with fixes for Motive 3.x:

- [FORK_CHANGELOG.md](FORK_CHANGELOG.md): every change and the issue it fixes
- [BEHAVIOUR_CHANGES.md](BEHAVIOUR_CHANGES.md): what works differently from upstream

| Branch | For |
|---|---|
| `ros1` (this one) | ROS 1 Noetic |
| `ros2` | ROS 2 (tested on Galactic) |
| `main` | unchanged upstream |

Tested with Motive 3.5, NatNet SDK 4.4, ROS Noetic and Ubuntu 20.04: 120 Hz per body at about 4% of one CPU core.

## Install

```
sudo apt install -y ros-noetic-tf2* wget
cd ~/catkin_ws/src
git clone -b ros1 https://github.com/IERoboticsAILab/natnet_ros_cpp
cd ..
catkin_make -DCMAKE_BUILD_TYPE=Release
source devel/setup.bash
```

The first build downloads the NatNet SDK into `deps/NatNetSDK`, so it needs internet.

**Already have the original repo?** Delete its old SDK, then rebuild as above:

```
rm -rf ~/catkin_ws/src/natnet_ros_cpp/deps/NatNetSDK/lib ~/catkin_ws/src/natnet_ros_cpp/deps/NatNetSDK/include
```

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
roslaunch natnet_ros_cpp natnet_ros.launch serverIP:=<motive-ip> clientIP:=<this-pc-ip> serverType:=unicast
```

Each rigid body is published as `geometry_msgs/PoseStamped` on `/natnet_ros/<body-name>/pose`, and as a TF frame `<body-name>` under `world`. A body Motive is not tracking is not published.

There is also a GUI: `roslaunch natnet_ros_cpp gui_natnet_ros.launch`

## Options

Pass these as `name:=value` to `roslaunch`.

| Option | Default | What it does |
|---|---|---|
| `serverIP` | | IP of the Motive PC |
| `clientIP` | | IP of the PC running this driver |
| `serverType` | `multicast` | `unicast` or `multicast`, same as in Motive |
| `globalFrame` | `world` | Frame the poses are in |
| `pub_rigid_body` | `true` | Publish rigid body poses and TF |
| `pub_untracked_rigid_body` | `false` | Keep publishing a body's last pose while Motive is not tracking it |
| `pub_rigid_body_marker` | `false` | Publish each body's markers on `/natnet_ros/<body-name>/marker#/pose` |
| `pub_individual_marker` | `false` | Track single markers (see below) |
| `pub_pointcloud` | `false` | Publish all markers as one `sensor_msgs/PointCloud` |
| `remove_latency` | `false` | Stamp messages with the camera exposure time instead of the arrival time |
| `log_frames`, `log_latencies`, `log_internals` | `false` | Print debug information |

## Tracking a single marker

A single marker can be published as a pose with fixed orientation:

1. Copy `config/initiate.yaml`, then add the marker's name and starting position (the file explains each field). `log_frames:=true` prints marker positions if you need to find it.
2. Launch with `pub_individual_marker:=true conf_file:=<your-file>.yaml`.

## Credits

Original driver by [L2S-lab](https://github.com/L2S-lab). If you use it in a publication, please cite [hal-04150950](https://hal.science/hal-04150950).

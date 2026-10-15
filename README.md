# NatNet 4 ROS 2 driver (WIP)

[![GitHub Action Status](https://github.com/L2S-lab/natnet_ros2/actions/workflows/AMD64-humble.yaml/badge.svg?event=push)](https://github.com/L2S-lab/natnet_ros2) 
[![GitHub Action Status](https://github.com/L2S-lab/natnet_ros2/actions/workflows/AMD64-jazzy.yaml/badge.svg?event=push)](https://github.com/L2S-lab/natnet_ros2) 
[![GitHub Action Status](https://github.com/L2S-lab/natnet_ros2/actions/workflows/ARM64-humble.yaml/badge.svg?event=push)](https://github.com/L2S-lab/natnet_ros2) 
[![GitHub Action Status](https://github.com/L2S-lab/natnet_ros2/actions/workflows/ARM64-jazzy.yaml/badge.svg?event=push)](https://github.com/L2S-lab/natnet_ros2) 


[![Static Badge](https://img.shields.io/badge/hal.science/hal-04150950v2?logo=hal&logoColor=red&label=hal&labelColor=blue&color=red)](https://hal.science/hal-04150950)

It is a continuation of the ROS 1 driver. Which can be found [here](https://github.com/L2S-lab/natnet_ros_cpp).

## About this fork

This is the [IE Robotics & AI Lab](https://github.com/IERoboticsAILab) fork, kept as the `ros2` branch of [IERoboticsAILab/natnet_ros_cpp](https://github.com/IERoboticsAILab/natnet_ros_cpp) and tested with Motive 3.5.

| Branch | ROS | Based on |
|---|---|---|
| `ros1` | ROS 1 Noetic | [L2S-lab/natnet_ros_cpp](https://github.com/L2S-lab/natnet_ros_cpp) `main` |
| `ros2` (this one) | ROS 2 (Galactic, Humble, Jazzy) | [L2S-lab/natnet_ros2](https://github.com/L2S-lab/natnet_ros2) `main` |
| `main` | | unchanged copy of upstream ROS 1 `main` |

Changes on this branch (one commit each):

- **Untracked rigid bodies are not published.** Motive keeps sending the last known pose of a lost body; the driver used to publish it as if it were live. Set `pub_untracked_rigid_body:=true` for the old behaviour.
- **One timestamp per frame** for all poses, markers and TF of that frame (`remove_latency` still applies).
- **Marker topics fixed**: publisher keys no longer collide (body 1 marker 12 vs body 11 marker 2) and `frame_id` is the global frame.
- **`natnet_ros2.launch.py` publishes by default**: `pub_rigid_body` and `activate` now default to `true`, so a plain launch streams rigid bodies.
- **Works on Galactic**: the launch file no longer imports `SetParametersFromFile` (Humble and newer only).
- **`libNatNet.so` is installed** with the package, so the node starts without setting `LD_LIBRARY_PATH` by hand.

The NatNet SDK stays at 4.4. SDK 4.5, which matches Motive 3.5, lost about half the frames in unicast when tested with the ROS 1 driver, so it is not used.

Measured with the lab's Motive 3.5 (120 Hz, unicast, 6 rigid bodies) on Ubuntu 20.04 with Galactic, 2026-10-15: 120 Hz on every body, about 3-4% of a CPU core, largest gap ~19 ms.

**Typical launch** (unicast; `clientIP` must be the IP of the machine running the node). Rigid bodies are published on `/<body-name>/pose`:

```
ros2 launch natnet_ros2 natnet_ros2.launch.py serverIP:=<motive-ip> clientIP:=<this-machine-ip> serverType:=unicast
```

If you are using software for any publication or article, we would be delighted if you could cite it [from here](https://hal.science/hal-04150950). 

## Introduction
This package contains a ROS 2 driver for the NatNet protocol used by the OptiTrack motion capture system. It uses NatNet SDK 4.4 (works with Motive 3.x). The NatNet SDK provided by the optitrack can be found [here](https://optitrack.com/support/downloads/developer-tools.html#natnet-sdk). It will be downloaded under `deps/NatNetSDK` while building it for the first time. NatNet protocol is used for streaming live motion capture data (rigid bodies, skeletons etc) across the shared network. 

This fork is tested with NatNet SDK 4.4, Motive 3.5 and ROS 2 Galactic on Ubuntu 20.04. (Upstream was tested with NatNet 4.0 on Foxy and Humble, and its CI builds Humble and Jazzy.) 

### Current Features:
  
 - Easy gui interface to control the node.
 - Rigid bodies are published as `geometry_msgs/PoseStamped` under name given in the Motive, i.e `/<body-name>/pose`. Plus those are also broadcasting as `tf` frame for rviz
 - Markers of the rigid bodies are published ad `geometry_msgs/PointStamped` unuder the name `/<body-name>/marker#/pose`
 - Unlabeled markers with the initial position and the name mentione in the `/config/initiate.yaml`are published as `geometry_msgs/PoseStamped` or `geometry_msgs/PointStamped` unuder the name `/<name-in-config-file>/pose`. Plus those are also broadcasting as `tf` frame for rviz. The marker position is updated based on Iterative closest point (nearest neighbour)
 - Unlabled markers can be also published as `sensor_msgs/PointCloud`
 - Different options for publishing and logging the data

### Work under progress: 

 - Include Skeleton and other devices in the system to make it package as whole.
 - Considering position and orientation for similar marker configurations (at least 3 markers)
 - Adding an option for the axis orientation (Z UP or Y UP)

## How to use it

#### Building the package
**requirements**
```
sudo apt install -y ros-$ROS_DISTRO-tf2* wget
```
Keep your system connected to the internet while building the package for the first time.
```
cd ~/ros2_ws/src
git clone -b ros2 https://github.com/IERoboticsAILab/natnet_ros_cpp natnet_ros2
cd ..
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
. install/setup.bash
```

#### Setup the Motive for this package
- Disable the firewall for the network on which the data is being published.
- Open the Motive app. 
- In the motive app, open the streaming panel.
- Disable the other streaming Engines like VRPN, Trackd etc.
- Under the OptiTrack Streaming Engine, turn on the Broadcast Frame.
- Select the correct IP address in the Local Interface.
- Select the Up Axis as Z.

Here is an example of how your streaming settings should look.

![alt text](https://github.com/L2S-lab/natnet_ros2/blob/main/img/streaming.png)


#### Easy way

Using GUI tool
Here, you can use simple tool and follow the instruction from the output area on the right bottom corner.
```
ros2 launch natnet_ros2 gui_natnet_ros2.launch.py
```
![alt text](https://github.com/L2S-lab/natnet_ros2/blob/main/img/ui-1.png)


#### Difficult way

Using Non gui approach
`ros2 launch natnet_ros2 natnet_ros2.launch.py`

##### Understanding the launch file
Launch file `natnet_ros2.launch.py` contains the several configurable arguments. The details are mentioned in the launch file. Following are several important argument for the connection and the data transfer. Other connection arguments are for the advanced option.

- `serverIP` : The IP address of the host PC. (The one selected in the Local Interface in Motive app)
- `clientIP` : The IP address of the PC on which the file will be launched
- `serverType` : Two possible options, `multicast` and `unicast`

##### Publishing the single marker 
It is possible to track the single marker as a rigid body with constant orientation. Go to the `config/initiate.yaml` It is suggested to make a copy of the file and rename the new file.
The file contains the details on what to modify. 

The question might arise on how to check the position of the single marker. For that, you can log the frames of the incoming data in the terminal. To do so, enable the `log_frames` in the launch file.

After configuring the `initiate.yaml`, in the launch file, enable the `pub_individual_marker`. Change the name of the config file in the argument `conf_file` if needed and launch the file.

<!-- ## Citation
If you use this software, please consider citing it [from here](https://hal.science/hal-04150950) -->

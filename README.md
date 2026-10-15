# NatNet 4 ROS driver

<!-- [![GitHub Action Status](https://github.com/L2S-lab/natnet_ros_cpp/actions/workflows/main.yaml/badge.svg?event=push)](https://github.com/L2S-lab/natnet_ros_cpp) -->
[![Static Badge](https://img.shields.io/badge/hal.science/hal-04150950v2?logo=hal&logoColor=red&label=hal&labelColor=blue&color=red)](https://hal.science/hal-04150950)

if you are using software for any publication or article, we would be delighted if you could cite it [from here](https://hal.science/hal-04150950).

**NOTE**: This is not maintained a lot. For ROS 2 version [visit here](https://github.com/L2S-lab/natnet_ros2). Which is continuation of this work.

## About this fork

This is the [IE Robotics & AI Lab](https://github.com/IERoboticsAILab) fork of [L2S-lab/natnet_ros_cpp](https://github.com/L2S-lab/natnet_ros_cpp), tested with Motive 3.5 on Ubuntu 20.04.

| Branch | ROS | Based on |
|---|---|---|
| `ros1` (this one) | ROS 1 Noetic | [L2S-lab/natnet_ros_cpp](https://github.com/L2S-lab/natnet_ros_cpp) `main` |
| `ros2` | ROS 2 (Galactic, Humble, Jazzy) | [L2S-lab/natnet_ros2](https://github.com/L2S-lab/natnet_ros2) `main` |
| `main` | | unchanged copy of upstream `main` |

Changes on this branch (one commit each):

- **NatNet SDK 4.4 instead of 4.0.** SDK 4.0 segfaults inside `libNatNet.so` on frames from Motive 3.x, usually within seconds of connecting. ARM is supported too. (SDK 4.5, which matches Motive 3.5, was tested too: in unicast it lost about half the frames in blocks of 10-14 frames, so it is not used.)
- **No more busy loop.** The node re-registered the frame callback in a loop with no sleep and used a full CPU core. It now registers once and spins (about 4-8% of a core with 6 bodies at 120 Hz).
- **Untracked rigid bodies are not published.** Motive keeps sending the last known pose of a lost body; the driver used to publish it as if it were live. Set `pub_untracked_rigid_body:=true` for the old behaviour.
- **One timestamp per frame**, and a new `remove_latency:=true` option that stamps messages with the camera exposure time (as in the ROS 2 driver).
- **Bodies added in Motive after start-up** no longer cause an invalid publisher; they are skipped with a warning until the node restarts.
- **Marker topics fixed**: publisher keys no longer collide (body 1 marker 12 vs body 11 marker 2) and `frame_id` is the global frame.
- **`pub_rigid_body_marker` now defaults to `false`** in `natnet_ros.launch`.
- No `[ERROR]` about the analog frame rate at start-up when Motive has no analog devices.
- `FrameCallback` no longer casts the `NatNetClient*` to `Internal*`.

Measured with the lab's Motive 3.5 (120 Hz, unicast, 6 rigid bodies) on Ubuntu 20.04, 2026-10-15:

| Build | Result |
|---|---|
| upstream `main` (SDK 4.0) | segfault within ~8 s |
| upstream + SDK 4.4 | 120 Hz, but 100% of a CPU core |
| this branch (SDK 4.4) | 120 Hz on every body, ~4% of a core, largest gap ~14 ms |
| this branch with SDK 4.5 | ~67 Hz: about half the frames lost, gaps up to ~127 ms |

**Upgrading an existing workspace:** the SDK download is skipped when `deps/NatNetSDK/lib` exists, so delete the old SDK first:

```
cd <your_ws>/src/natnet_ros_cpp && rm -rf deps/NatNetSDK/lib deps/NatNetSDK/include && cd ../.. && catkin_make -DCMAKE_BUILD_TYPE=Release
```

**Typical launch** (unicast; `clientIP` must be the IP of the machine running the node):

```
roslaunch natnet_ros_cpp natnet_ros.launch serverIP:=<motive-ip> clientIP:=<this-machine-ip> serverType:=unicast
```

## Introduction
This package contains a ROS driver for the NatNet protocol used by the OptiTrack motion capture system. It uses NatNet SDK 4.4 (works with Motive 3.x). The NatNet SDK provided by the optitrack can be found [here](https://optitrack.com/support/downloads/developer-tools.html#natnet-sdk). It will be downloaded under `deps/NatNetSDK` while building it for the first time. NatNet protocol is used for streaming live motion capture data (rigid bodies, skeletons etc) across the shared network. 

This fork is tested with NatNet SDK 4.4, Motive 3.5 and ROS Noetic on Ubuntu 20.04. (Upstream was tested with NatNet 4.0.) 

### Current Features:
  
 - Stable and with more functionality than [mocap_optitrack](https://github.com/ros-drivers/mocap_optitrack)
 - Rigid bodies are published as `geometry_msgs/PoseStamped` under name given in the Motive, i.e `/natnet_ros/<body-name>/pose`. Plus those are also broadcasting as `tf` frame for rviz
 - Markers of the rigid bodies are published ad `geometry_msgs/PointStamped` unuder the name `/natnet_ros/<body-name>/marker#/pose`
 - Unlabeled markers with the initial position and the name mentione in the `/config/initiate.yaml`are published as `geometry_msgs/PoseStamped` unuder the name `/natnet_ros/<name-in-config-file>/pose`. Plus those are also broadcasting as `tf` frame for rviz. The marker position is updated based on Iterative closest point (nearest neighbour)
 - Unlabled markers can be also published as `sensor_msgs/PointCloud`
 - Different options for publishing and logging the data


### Work under progress: 

 - Include Skeleton and other devices in the system to make it package as whole.
 - Considering position and orientation for similar marker configurations (at least 3 markers)
 - Adding an option for the axis orientation (Z UP or Y UP)
 - (ROS 2: see the `ros2` branch of this fork.)

## How to use it

#### Building the package
**requirements**
```
sudo apt install -y ros-$ROS_DISTRO-tf2* wget
```
Keep your system connected to the internet while building the package for the first time.
```
cd ~/catkin_ws/src
git clone -b ros1 https://github.com/IERoboticsAILab/natnet_ros_cpp
cd ..
catkin build -DCMAKE_BUILD_TYPE=Release  #OR catkin_make -DCMAKE_BUILD_TYPE=Release
. devel/setup.bash
```

#### Setup the Motive for this package
- Disable the firewall for the network on which the data is being published.
- Open the Motive app. 
- In the motive app, open the streaming panel.
- Disable the other streaming Engines like VRPN, Trackd etc.
- Under the OptiTrack Streaming Engine, turn on the Broadcast Frame (in Motive 3: under NatNet, turn on Enable).
- Turn on Rigid Bodies. Labeled, unlabeled and asset markers are only needed for the marker options below.
- Select the correct IP address in the Local Interface.
- Select the Up Axis as Z.

Here is an example of how your streaming settings should look.

![alt text](https://github.com/L2S-lab/natnet_ros_cpp/blob/noeitc/img/streaming.png)


#### Easy way

Using GUI tool
Here, you can use simple tool and follow the instruction from the output area on the right bottom corner.
```
roslaunch natnet_ros_cpp gui_natnet_ros.launch
```
![alt text](https://github.com/L2S-lab/natnet_ros_cpp/blob/main/img/ui-1.png)


#### Difficult way

Using Non gui approach
`roslaunch natnet_ros_cpp natnet_ros.launch`

##### Understanding the launch file
Launch file `natnet_ros.launch` contains the several configurable arguments. The details are mentioned in the launch file. Following are several important argument for the connection and the data transfer. Other connection arguments are for the advanced option.

- `serverIP` : The IP address of the host PC. (The one selected in the Local Interface in Motive app)
- `clientIP` : The IP address of the PC on which the file will be launched
- `serverType` : Two possible options, `multicast` and `unicast`

Publishing options (all `false` by default except `pub_rigid_body`):

- `pub_rigid_body` : publish `/natnet_ros/<body-name>/pose` and TF for each rigid body (default `true`)
- `pub_untracked_rigid_body` : keep publishing a rigid body with its last known pose while Motive is not tracking it
- `pub_rigid_body_marker` : publish the markers of each rigid body on `/natnet_ros/<body-name>/marker#/pose`
- `pub_individual_marker`, `pub_pointcloud` : see below
- `remove_latency` : stamp messages with the camera mid-exposure time instead of the time the frame was received

##### Publishing the single marker 
It is possible to track the single marker as a rigid body with constant orientation. Go to the `config/initiate.yaml` It is suggested to make a copy of the file and rename the new file.
The file contains the details on what to modify. 

The question might arise on how to check the position of the single marker. For that, you can log the frames of the incoming data in the terminal. To do so, enable the `log_frames` in the launch file.

After configuring the `initiate.yaml`, in the launch file, enable the `pub_individual_marker`. Change the name of the config file in the argument `conf_file` if needed and launch the file.

##### Replacing existing package
You can easily replace the current package with this package. In the `natnet_ros.launch` change the name of node to the node you currently using. For an example, 
If you are using the `vrpn_client_node`
changes are following

```
<node pkg="natnet_ros_cpp" type="natnet_ros_cpp" name="vrpn_client_node" output="screen" >   
```

## Citation
If you use this software, please consider citing it [from here](https://hal.science/hal-04150950)


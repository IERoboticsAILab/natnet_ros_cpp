# Behaviour changes

What works differently from upstream, and how to get the old behaviour back if you need it. The full list of changes is in [FORK_CHANGELOG.md](FORK_CHANGELOG.md).

## Both drivers (ROS 1 and ROS 2)

### Lost bodies stop publishing

**Before:** when Motive lost a rigid body (hidden, out of the volume, markers covered), the driver kept publishing its last known pose at the full frame rate, as if it were live and not moving.

**Now:** the body's pose topic and TF frame go quiet until Motive tracks it again, then resume right away.

**What to check in your code:** if you wait for "a new message" or use a timeout on the pose topic, a lost body now triggers that timeout instead of silently feeding a frozen pose. That is usually what you want for a robot, but check that your code handles it.

**Old behaviour:** `pub_untracked_rigid_body:=true`

### Marker messages use the global frame

**Before:** marker messages (`<body>/marker#/pose`) had a `frame_id` like `"112"`, and two markers could share one topic.

**Now:** `frame_id` is the global frame (`world` by default) and every marker has its own topic.

### Timestamps are the same for the whole frame

All poses, markers and TF from one camera frame now carry the same timestamp. Nothing to change in your code.

## ROS 1 only

### Marker topics are off by default

**Before:** `natnet_ros.launch` published every marker of every rigid body (`/natnet_ros/<body>/marker#/pose`).

**Now:** only rigid body poses and TF are published.

**Old behaviour:** `pub_rigid_body_marker:=true`

### New option: `remove_latency`

`remove_latency:=true` stamps messages with the time the cameras took the picture, instead of the time the frame reached the PC. Off by default, so nothing changes unless you turn it on.

### Upgrading an existing workspace

The SDK download is skipped when an SDK is already there, so an old workspace keeps SDK 4.0 (which crashes). Delete it and rebuild:

```
cd <your_ws>/src/natnet_ros_cpp && rm -rf deps/NatNetSDK/lib deps/NatNetSDK/include && cd ../.. && catkin_make -DCMAKE_BUILD_TYPE=Release
```

## ROS 2 only

### A plain launch now publishes

**Before:** `natnet_ros2.launch.py` defaulted to `pub_rigid_body:=false` and `activate:=false`, so the node connected but published nothing.

**Now:** both default to `true`.

**Old behaviour:** `pub_rigid_body:=false activate:=false`

### Topic names (unchanged, but different from ROS 1)

ROS 2 topics are `/<body-name>/pose`. ROS 1 topics are `/natnet_ros/<body-name>/pose`.

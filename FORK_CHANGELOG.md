# Fork changelog

Changes made in the [IERoboticsAILab](https://github.com/IERoboticsAILab) fork, on top of upstream:

- `ros1` branch: [L2S-lab/natnet_ros_cpp](https://github.com/L2S-lab/natnet_ros_cpp) `main` (ROS 1 Noetic)
- `ros2` branch: [L2S-lab/natnet_ros2](https://github.com/L2S-lab/natnet_ros2) `main` (ROS 2)

Upstream's own history is in [CHANGELOG.md](CHANGELOG.md). Changes that affect how you use the driver are listed in [BEHAVIOUR_CHANGES.md](BEHAVIOUR_CHANGES.md).

## 2026-10-15

Each change is a separate commit. ✓ = changed on that branch.

| # | Issue | What was changed | ROS1 | ROS2 |
|---|---|---|:-:|:-:|
| 1 | The driver crashed after a few seconds because the old OptiTrack library (SDK 4.0) couldn't read data from Motive 3.x | Switched to the newer library (SDK 4.4), with ARM support | ✓ | (already 4.4) |
| 2 | The driver kept one CPU core 100% busy by repeating a setup step non-stop | It does the setup once, then waits for data (about 4% CPU) | ✓ | (already OK) |
| 3 | Data was passed around labelled as the wrong type; it worked only by luck | The correct type is used | ✓ | (already OK) |
| 4 | A body added in Motive while the driver ran filled the log with errors every frame | It's skipped with a short warning every 5 s until the driver restarts | ✓ | (already OK) |
| 5 | Two markers could end up on the same topic (body 1 marker 12 and body 11 marker 2 both became "112"), and their `frame_id` was a meaningless number | Marker names have a separator; `frame_id` is the global frame (`world`) | ✓ | ✓ |
| 6 | A body Motive couldn't see kept publishing its last position 120 times a second, so it looked live and still | Lost bodies stop publishing until they're seen again (`pub_untracked_rigid_body:=true` restores the old behaviour) | ✓ | ✓ |
| 7 | Messages from the same camera frame had slightly different timestamps | One timestamp per frame | ✓ | ✓ |
| 8 | The time a message was stamped was when the data arrived, not when the cameras saw it | New option `remove_latency:=true` stamps the time the cameras took the picture | ✓ | (already had it) |
| 9 | Every marker of every body was published by default, adding lots of unused topics | Marker topics are off by default (`pub_rigid_body_marker:=true` turns them on) | ✓ | (already off) |
| 10 | A false `[ERROR]` about analog devices at startup looked like a connection problem | It's no longer shown as an error | ✓ | |
| 11 | A plain launch connected but published nothing | Publishing and activation are on by default | | ✓ |
| 12 | The launch file wouldn't start on ROS 2 Galactic (it imported a feature only newer versions have) | Removed that unused import | | ✓ |
| 13 | The driver couldn't find the OptiTrack library at startup unless a path was set by hand | The library is installed with the driver | | ✓ |
| 15 | If the driver died, roslaunch kept running, so a service looked healthy while no data came out | New launch option `respawn:=true` restarts the driver after 5 s | ✓ | |
| 14 | The instructions didn't match the fork | README updated: fork info, SDK choice, new options, test results | ✓ | ✓ |

The two strictly necessary changes are #1 (crash) and #2 (CPU). #6 is strongly recommended for robot safety. The others are smaller fixes and cleanup.

### Why SDK 4.4 and not 4.5

SDK 4.5 matches Motive 3.5, but in unicast it lost about half the frames (in blocks of 10-14 frames, ~67 Hz instead of 120 Hz). SDK 4.4 delivers every frame, so the fork uses 4.4.

### Test results

Lab Motive 3.5, 120 Hz, unicast, 6 rigid bodies, Ubuntu 20.04:

| Setup | Result |
|---|---|
| Upstream ROS 1 (SDK 4.0) | Crashes within ~8 s |
| Upstream ROS 1 + SDK 4.4 | 120 Hz, but 100% of a CPU core |
| Fork `ros1` | 120 Hz on every body, ~4% CPU |
| Fork `ros2` (Galactic) | 120 Hz on every body, ~3-4% CPU |
| Fork with SDK 4.5 | ~67 Hz, about half the frames lost |

Pose check: the fork's ROS 1 output for a tracked body was identical (0.000 mm position difference over 1,756 frames) to OptiTrack's own Python NatNet client from the SDK.

Not tested yet: long runs (30+ min) with marker streaming on, multicast, ROS 2 Humble/Jazzy, `remove_latency` on ROS 1, adding a body while the driver runs.

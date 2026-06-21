KvatiTown FORCE-MOVE lead truck fix

Use this if the leader truck is visible but does not move after the previous speed/path patch.

What it changes:
- Replaces LeadTruckDriver.gd with a simple no-wait movement loop.
- It does NOT wait for CameraStreamer or dashboard Start.
- It moves in _process(), not _physics_process(), so it is harder to freeze.
- It prints [LeadTruckDriver FORCE] ready/moving logs every second.
- Reset sends the leader back to the first path point.
- Dashboard Lead truck speed still works.
- Default lead truck speed is 0.140, close to the old visibly-moving speed.

Apply from KvatiTown root:
  .\kvati_leader_force_move_fix\apply_kvati_leader_force_move_fix.bat

Then run:
  python launch.py --sim --task convoying

If it still does not move, check terminal for:
  [LeadTruckDriver FORCE] ready
  [LeadTruckDriver FORCE] moving

If those logs do not appear, Godot is not loading LeadTruckDriver.gd or convoying.tscn is not the active scene.

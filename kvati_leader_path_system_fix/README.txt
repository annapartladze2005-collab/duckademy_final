KvatiTown path-system leader truck fix

This replaces the fragile imported-model-root movement with a Path3D + PathFollow3D leader, based on the working duckietown-convoy NPC idea.

Changes:
- Adds GodotSimulation/ducky-bot/scripts/KvatiLeaderPathFollow.gd
- Rewrites convoying.tscn so LeadTruck is a PathFollow3D with LeaderVehicle as its child
- WheelCommandServer reset now also calls npc_leader.reset_leader()
- WheelCommandServer set_leader_speed now calls npc_leader.set_speed(speed)

Apply from KvatiTown root:
  .\kvati_leader_path_system_fix\apply_kvati_leader_path_system_fix.bat

Run:
  python launch.py --sim --task convoying

Expected logs:
  [KvatiLeaderPath] ready
  [KvatiLeaderPath] moving
  [WheelServer] Leader speed command: ...

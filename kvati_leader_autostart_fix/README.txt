KvatiTown leader autostart hotfix

Use this after kvati_leader_speed_patch if the lead truck does not move.

What it changes:
- disables CameraStreamer wait gate in LeadTruckDriver.gd
- lowers start grace from 1.0s to 0.2s
- raises default leader speed from 0.055 to 0.080
- keeps dashboard leader-speed slider working

Apply from KvatiTown root:
  .\kvati_leader_autostart_fix\apply_kvati_leader_autostart_fix.bat

Then run:
  python launch.py --sim --task convoying

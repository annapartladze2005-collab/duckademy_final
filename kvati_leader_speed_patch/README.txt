KvatiTown leader truck motion + dashboard speed patch

What this changes:
- Replaces GodotSimulation/ducky-bot/scripts/LeadTruckDriver.gd with a longer, smoother lane path.
- Adds reset_leader() so the lead truck returns to its first path point when the simulation dashboard Reset button is clicked.
- Adds set_leader_speed() on the Godot leader and a set_leader_speed TCP message from Python to Godot.
- Adds a fourth dashboard slider: Lead truck speed.
- Keeps the existing close/good/far multipliers unchanged.

Recommended install on Windows:
1. Extract this folder into your KvatiTown project root:
   C:\Users\sergi\PycharmProjects\KvatiTown
2. From PowerShell in the project root run:
   .\apply_kvati_leader_speed_patch.bat
3. Start convoying:
   python launch.py --sim --task convoying

Alternative git install:
   git apply --ignore-whitespace --whitespace=nowarn .\kvati_leader_speed.patch

If something breaks, copy files back from the backup folder printed by the script.

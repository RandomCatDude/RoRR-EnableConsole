Toggle via `Shift`+`~`.

Comes with reimplementations of many commands that are in the game's source code, but aren't compiled into the public build of the game. Special Thanks to Dee for providing the code and assisting with innumerable things.

Note:
- () Circle brackets denote required arguments. [] square brackets denote optional arguments.

- Certain commands take in "namespace-identifier pairs" for classes like items, objects, and monster spawn cards. For vanilla classes, the namespace can be omitted (e.g. `ror-soldiersSyringe` can be written as `soldiersSyringe` and still work). For modded content, you will usually have to provide the full namespace-identifier pair.
  - See the `find` command at the very bottom for finding namespace-identifier pairs

- Untested in multiplayer. Be careful! And don't ruin others' online experience!

Command list:
| Signature | Description |
| --- | --- |
| `build_id` | Prints the game's build id, branch, and version number.|
| `toggle_hud` | Toggles HUD visibility when used in-game |
| `iphost (port)` | Start a non-steam coop game on the given port number. `port` should be within the 1024-65535 range. |
| `ipconnect (ip) (port)` | Connect to a coop game started with `iphost` on the matching `(port)` number. `(ip)` can also be a hostname instead, use `localhost` or `127.0.0.1` to connect to a game running on the same computer. |
| `game_speed [fps]` | Sets the game speed, or resets it to 60fps if no value is given. |
| `summon (card) [count] [elite]` | Spawns an enemy from a monster card. `(card)` and `[elite]` are namespace-identifier pairs. |
| `locate (object) [index]` | Teleports the player to the specified object, disambiguated by `[index]`. Note that you must not include the `o` prefix when typing the object's name (i.e. `locate oTeleporter` doesn't work, but `locate Teleporter` does). `(object)` is a namespace-identifier pair. |
| `camera_lock` | The in-game camera stops tracking and remains stuck. |
| `camera_track (object) [index]` | Set the camera to track the specified object. See `locate` for details on `(object)` and `[index]`. |
| `camera_reset` | Reset the camera to its default state, usually tracking the local player. |
| `zoom` | Gives you 60 Paul's Goat Hoofs and 60 Hopoo Feathers |
| `unzoom` | Removes the same items given by `zoom`. |
| `firepower` | Gives you 20 Lens Maker's Glasses, 20 Soldier's Syringes, and 100 Brilliant Behemoths. |
| `unfirepower` | Removes the same items given by `firepower` |
| `peace` | Disables the director from spawning enemies. |
| `unpeace` | Enables the director to spawn enemies again |
| `god` | Gives you permanent invincibility |
| `ungod` | Removes your invincibility |
| `skip_tp` | Sets the Teleporter to finish charging instantly. Affects all Teleporters if there are multiple |
| `kill_all` | Kills every actor that isn't on the player team. |
| `give_item (item) [count] [temporary]` | Gives you the specified quantity of an item, and if it's temporary or not. 0: normal, 1: blue temporary, 2: red temporary (from CHEF's COOK.) `(item)` is a namespace-identifier pair. |
| `remove_item (item) [count]` | Removes the given amount of the given item from you. Cannot remove temporary items..|
| `gimme (object) [count]` | Spawns the specified object at your mouse location. Note that some objects, mainly pickups and interactables, may appear at the nearest valid ground instead of your exact mouse location. `(object)` is a namespace-identifier pair |
| `spawn_boss [kind] [mountain]` | Simulates spawning the Teleporter boss for the current stage. A `[kind]` of `horde` or `blight` specifies a Horde of Many and Phantasm event respectively, other values do nothing. `[mountain]` specifies mountain shrine count. |
| `test_lategame [minutes] [items] [levels]` | Simulates a lategame run by advancing time and giving you items and leveling you up. Defaults to 60 minutes, 90 items, and 12 levels. |
| `unlockall` | Unlocks all achievements. Requires confirmation by specifying a `confirm` argument. |
| `lockall` | Locks all achievements. Ditto. |
| `unlock (achievement)` | Unlocks a specific achievement, does not require confirmation. `(achievement)` is a namespace-identifier pair. |
| `lock (achievement)` | Locks a specific achievement. Ditto. |
| `logs` | Gives you all item, monster, survivor, and environment logs. |
| `test_eclipse` | Enters the select menu in an unfinished "Eclipse" game mode. |
| `log_environment_cam_get` | Use while having an environment log open, to copy the camera's location to your clipboard. Useful for setting the starting camera position in stages' environment logs. |
| `set_gold (amount)` | Set your gold to the specified amount. |

## `find (class) (pattern)`
Search through the specified class type for matches in both namespace and identifier, against the specified pattern. Prints a list of every namespace-identifier pair found. No further info is provided beyond their raw ID.

A `(class)` of `*` will search through every class. A `(pattern)` of `*` will disable pattern-matching.

`(class)` may be one of the following:
- `achievement`
- `actor_skin`
- `actor_state`
- `artifact`
- `difficulty`
- `elite`
- `ending`
- `environment_log`
- `equipment`
- `gamemode`
- `interactable_card`
- `item`
- `item_log`
- `monster_card`
- `monster_log`
- `skill`
- `stage`
- `survivor`
- `survivor_log`

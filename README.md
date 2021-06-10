### install

switch to your awesome config folder, typically at:

```
cd ~/.config/awesome
```

clone this repository:

```
https://github.com/basaran/awesomewm-machina
```

and call it from your `rc.lua`

```lua
local machina = require('awesomewm-machina')
```

append to your keybindings, typically in your `rc.lua`

```lua
root.keys(gears.table.join(config.globalkeys, machina.keys))
```

default shortcuts are:

```lua
modkey + p : next in region
modkey + o : prev in region
modkey + insert : move top left
modkey + delete : move bottom right
modkey + home : center as float
modkey + pageup : move top right
modkey + pagedown : move bottom right
```
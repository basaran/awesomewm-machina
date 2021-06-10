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
local machina = require('awesomewm-backham')
```

append to your keybindings, typically in your `rc.lua`

```lua
root.keys(gears.table.join(config.globalkeys, machina.keys))
```
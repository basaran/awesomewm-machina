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
modkey + delete : move bottom left
modkey + home : center as float
modkey + pageup : move top right
modkey + pagedown : move bottom right

modkey + j : stack friendly left
modkey + k : stack friendly down
modkey + l : stack friendly right
modkey + i : stack friendly up
```

### Preview
https://user-images.githubusercontent.com/30809170/121564284-48bf6d80-c9e9-11eb-982c-6abfbf1fddf1.mp4




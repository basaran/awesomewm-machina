### Why?
Layout-machi is great, however it requires you to use its built-in switcher to manage your open windows. If you are shuffling, swapping, and moving things around often, this could become counter productive.

`Machina` is built on top of layout-machi, and allows you to bind frequently used actions to your keys and gives you additional user friendly features.

A combination of `layout-machi` and `awesomewm-machina` will give you a similar experience to fancy zones on windows.


### What?
These are the features I added:

- Quick Expand:
Expand focused window to left, right, or vertically. This will make the window snap to the next available region.

- Directional Swapping:
Swap windows between regions.

- Directional Shifting:
Relocate windows like Elv13's collision module.

- Rotational Shifting:
Relocate windows clockwise or counter clockwise. This uses a different algorithm compared to directional shifting and should be more accurate in merging your floating clients to the tiling layout.

- Shuffling:
Go backward or forward in a region, and it will cycle the clients inside that area.

- Auto-Hide Floating Windows:
Often times, the floating windows pollutes your background if you are using `useless-gaps`. Machina will hide those for you, but they can still be accessed through your window-switcher such as Rofi.

- Floating and Tiled:
All keybindings, including swapping work seamlessy on both the tiled and the floating windows. So, if you need to push that terminal to a corner, you can easily do so without changing it to tiling mode.

- Experimental Tabs:
We now have tabs for tiled clients :)

### Next?

New layout-machi has some logic to auto expand your windows onto multiple regions. I need to change region expansion to work nicely with it.

### Layout-Machi compatibility

Machina should work just fine with both versions of layout-machi. 

### Problems?

If you have any issues or recommendations, please feel free to open a request. PRs are most welcome.


### Install
switch to your awesome config folder, typically at:

```
cd ~/.config/awesome
```

clone this repository:

```
git clone https://github.com/basaran/awesomewm-machina machina
```

and call it from your `rc.lua`

```lua
local machina = require('machina')()
```

### Keybindings

This module directly injects into rc.lua and ideally, all keybindings should work unless you override them in your rc.lua.

If you have any issues, you can change in your `rc.lua`:

```lua
root.keys(globalkeys)
```

to:

```lua
root.keys(gears.table.join(root.keys(),globalkeys))
```
or, you can just copy / paste what you like from `init.lua` onto your rc.lua globalkeys table.

Some of the default shortcuts are:

```lua

-- Please see init.lua for keybindings and their descriptions.

```


### Preview
https://user-images.githubusercontent.com/30809170/123538385-ab5f7b80-d702-11eb-9a14-e8b9045d9d27.mp4





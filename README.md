### why?
Layout-machi is great, however it requires you to use its built-in switcher to manage your open windows. If you are shuffling, swapping, and moving things around often, this could become counter productive.

`Machina` is built on top of layout-machi, and allows you to bind frequently used actions to your keys and gives you additional user friendly features.

A combination of `layout-machi` and `awesomewm-machina` will give you a similar experience to fancy zones on windows.


### what?
These are the features I added:

- Quick Expand
Added feature, expands the focused client to left, right, or vertically.

- Directional Swapping
Added feature, swaps clients between regions.

- Directional Shifting
Relocate clients like Elv13's collision module

- Rotational Shifting
Relocate clients clock wise or counter clock wise.

- Shuffling
Go backward or forward in a region, and it will cycle the clients inside that area.

- Auto-Hide Floating Windows 
Often times, the floating windows pollutes your background if you are using `useless-gaps`. Machina will hide those for you, but they can still be accessed through your window-switcher such as Rofi.

- Floating and Tiled

All keybindings, including swapping work seamlessy on both the tiled and the floating windows. So, if you need to push that terminal to a corner, you can easily do so without changing it to tiling mode.

### next?

The region shuffling works like tabs, but it would be nice to have a visual queue like tabs. That will be in the next version.


### problems?

If you have any issues, please feel free to open a request. PRs are most welcome.


### install
switch to your awesome config folder, typically at:

```
cd ~/.config/awesome
```

clone this repository:

```
git clone https://github.com/basaran/awesomewm-machina
```

and call it from your `rc.lua`

```lua
local machina = require('awesomewm-machina')()
```

some of the default shortcuts are:

```lua
modkey + [ : prev within region
modkey + ] : next within region

modkey + shift + [ : move to region (counter clock wise, infinite)
modkey + shift + ] : move to region (clock wise, infinite)

modkey + ; : swap with client on left (if any)
modkey + ' : swap with client on right (if any)

modkey + insert : quick expand to left side (toggle)
modkey + pageup : quick expand to right side (toggle)

modkey + home : center (float or tiled)
modkey + end : toggle float

modkey + delete : expand client vertically

modkey + j : focus left
modkey + k : focus down
modkey + l : focus right
modkey + i : focus up

modkey + shift + j : move to left region
modkey + shift + k : move to down region
modkey + shift + l : move to right region
modkey + shift + i : move to up region
```

### Preview
https://user-images.githubusercontent.com/30809170/121564284-48bf6d80-c9e9-11eb-982c-6abfbf1fddf1.mp4




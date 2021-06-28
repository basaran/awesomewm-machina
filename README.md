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
Go backward or forward in a region, and it will cycle the clients inside that area. Kind of like fake tabs.

- Auto-Hide Floating Windows:
Often times, the floating windows pollutes your background if you are using `useless-gaps`. Machina will hide those for you, but they can still be accessed through your window-switcher such as Rofi.

- Floating and Tiled:
All keybindings, including swapping work seamlessy on both the tiled and the floating windows. So, if you need to push that terminal to a corner, you can easily do so without changing it to tiling mode.

### Next?

The region shuffling works like tabs, but it would be nice to have a visual queue like tabs. That will be in the next version. I'm also planning to add chained keybindings kind of like in emacs and vi that displays a modal help window.

New layout-machi has some logic to auto expand your windows onto multiple regions. For some work flows this might be desired, but I might look into a way to disable that as I find it to get in the way when changing windows from float to tile. This is especially annoying when you have a centered float.

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
git clone https://github.com/basaran/awesomewm-machina
```

and call it from your `rc.lua`

```lua
local machina = require('awesomewm-machina')()
```

### Keybindings

some of the default shortcuts are:

```lua
modkey + [ : shift to region (counter clock wise, infinite)
modkey + ] : shift to region (clock wise, infinite)

modkey + shift + [ : swap with client on left (if any)
modkey + shift + ] : swap with client on right (if any)
--|will keep the focus on the region you execute

modkey + shift + ' : prev within region
modkey + shift + ; : next within region

modkey + insert : quick expand to left side (toggle)
modkey + pageup : quick expand to right side (toggle)
modkey + delete : expand client vertically

modkey + home : center (float or tiled)
--|you can use this one like zooming, when executed on tiled
--|clients, it will toggle back to original region.

modkey + end : toggle float status

modkey + j : focus left
modkey + k : focus down
modkey + l : focus right
modkey + i : focus up

modkey + shift + j : shift to left region
modkey + shift + k : shift to down region
modkey + shift + l : shift to right region
modkey + shift + i : shift to up region

modkey + shift + insert : move to top-left
modkey + shift + page_up :  move to top-right
modkey + shift + home :  move to center
modkey + shift + end :  move to center
modkey + shift + delete :  move to bottom-left
modkey + shift + page_down :  move to bottom-right
--|these will also work with tiled clients
```


### Preview
https://user-images.githubusercontent.com/30809170/123538385-ab5f7b80-d702-11eb-9a14-e8b9045d9d27.mp4





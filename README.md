### why?

Layout-machi is great, however it requires you to use its built-in switcher to manage your open windows. If you are shuffling, swapping, and move things around a lot, this could become counter productive.

`Machina` is built on top of layout-machi, and allows you to bind frequently used actions to your keys and gives you additional user friendly features.

In other words, combination of `layout-machi` and `awesomewm-machina` will give you a similar (if not better) experience than the fancyzones on windows.

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

- Auto-Hide Floating Windows 
Often times, the floating windows pollutes your background if you are using `useless-gaps`. Machina will hide those for you, but they can still be accessed through your window-switcher such as Rofi.

- Floating and Tiled

All keybindings work seamlessy on both tiled and floating clients. So, if you need to push that terminal to a corner, you can easily do so without changing it to tiling mode.

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
modkey + [ : prev client within region
modkey + ] : next client within region

modkey + shift + [ : move client to region (counter clock wise)
modkey + shift + ] : move client to region (clock wise)

modkey + ; : move client to region on left (with bump)
modkey + ' : move client to region on right (with bump)

modkey + shift + ; : swap with client on left if any
modkey + shift + ' : swap with client on right if any

modkey + insert : quick expand to left side (toggle)
modkey + pageup : quick expand to right side (toggle)

modkey + home : center (float or tiled)
modkey + end : toggle float

modkey + delete : expand client vertically

modkey + j : stack friendly left
modkey + k : stack friendly down
modkey + l : stack friendly right
modkey + i : stack friendly up
```

### Preview
https://user-images.githubusercontent.com/30809170/121564284-48bf6d80-c9e9-11eb-982c-6abfbf1fddf1.mp4




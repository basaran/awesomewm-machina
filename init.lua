
---------------------------------------------------------- dependencies -- ;

local capi = {root=root}
local gears = require("gears")
local naughty = require("naughty")
local inspect = require('inspect')
local awful = require("awful")
local modkey = "Mod4"

local machina = require('awesomewm-machina.methods')
local compare = machina.compare
local region_tablist = machina.region_tablist
local focus_by_direction = machina.focus_by_direction
local get_active_regions = machina.get_active_regions
local shift_by_direction = machina.shift_by_direction
local expand_horizontal = machina.expand_horizontal
local geoms = machina.geoms
local shuffle = machina.shuffle
local my_shifter = machina.my_shifter
local expand_vertical = machina.expand_vertical
local move_to = machina.move_to

---------------------------------------------------------- key bindings -- ;

local bindings = {
   awful.key({modkey}, ";", shuffle("backward")),
   awful.key({modkey}, "'", shuffle("forward")),
   --▨ shuffle decks

   awful.key({modkey, "Shift"}, "j", shift_by_direction("left")),
   awful.key({modkey, "Shift"}, "l", shift_by_direction("right")),
   awful.key({modkey, "Shift"}, "k", shift_by_direction("down")),
   awful.key({modkey, "Shift"}, "i", shift_by_direction("up")),
   --▨ move (directional)

   awful.key({modkey}, "[", my_shifter("backward")),
   awful.key({modkey}, "]", my_shifter("forward")),
   --▨ move (clockwise)

   awful.key({modkey, "Shift"}, "Insert", move_to("top-left")),
   awful.key({modkey, "Shift"}, "Page_Up", move_to("top-right")),
   awful.key({modkey, "Shift"}, "Home", move_to("center")),
   awful.key({modkey, "Shift"}, "End", move_to("center")),
   awful.key({modkey, "Shift"}, "Delete", move_to("bottom-left")),
   awful.key({modkey, "Shift"}, "Page_Down", move_to("bottom-right")),
   --▨ move (positional)

   awful.key({modkey, "Shift"  }, "[", shift_by_direction("left", true)),
   awful.key({modkey, "Shift"  }, "]", shift_by_direction("right", true)),
   awful.key({modkey, "Control"}, "[", shift_by_direction("down", true)),
   awful.key({modkey, "Control"}, "]", shift_by_direction("up", true)),
   --▨ swap (directional)

   awful.key({modkey}, "Insert", expand_horizontal("left")),
   awful.key({modkey}, "Page_Up", expand_horizontal("right")),
   awful.key({modkey}, "Home", expand_horizontal("center")),
   awful.key({modkey}, "Page_Down", expand_vertical),
   --▨ expand (neighbor)

   awful.key({modkey}, "End", function() 
      client.focus.maximized_vertical = false
      client.focus.maximized_horizontal = false
      awful.client.floating.toggle()
   end), --|toggle floating status

   awful.key({modkey}, "Left", focus_by_direction("left")),
   awful.key({modkey}, "j", focus_by_direction("left")),

   awful.key({modkey}, "Down", focus_by_direction("down")),
   awful.key({modkey}, "k", focus_by_direction("down")),

   awful.key({modkey}, "Right", focus_by_direction("right")),
   awful.key({modkey}, "l", focus_by_direction("right")),

   awful.key({modkey}, "Up", focus_by_direction("up")),
   awful.key({modkey}, "i", focus_by_direction("up"))
   --▨ focus
}

--------------------------------------------------------------- signals -- ;

client.connect_signal("request::activate", function(c) 
   c.hidden = false
   c:raise()
   client.focus = c
end) --|this is needed to ensure floating stuff becomes
     --|visible when invoked through run_or_raise

client.connect_signal("focus", function(c) 
   if not c.floating then
      for _, tc in ipairs(screen[awful.screen.focused()].all_clients) do
         if tc.floating then
            tc.hidden = true
         end
      end
      return
   end

   if c.floating then
      for _, tc in ipairs(screen[awful.screen.focused()].all_clients) do
         if tc.floating and not tc.role then
            tc.hidden = false
         end
      end
      return
   end
end) --|hide all floating windows when the user switches to a
     --|tiled client. this is handy when you have a floating
     --|browser open.

--------------------------------------------------------------- exports -- ;

module = {
   bindings = bindings
}

local function new(arg)
   capi.root.keys(awful.util.table.join(capi.root.keys(), table.unpack(bindings)))
   return module
end

return setmetatable(module, { __call = function(_,...) return new({...}) end })


-- return module
----------------╮
--▨ FOCUS      ▨
----------------╯
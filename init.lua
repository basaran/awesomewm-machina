---------------------------------------------------------> dependencies -- ;

local gears = require("gears")
local awful = require("awful")
local modkey = "Mod4"

local function tablelength(T)
   local count = 0
   for _ in pairs(T) do count = count + 1 end
   return count
end

--------------------------------------------------------------> methods -- ;

local function region_tablist()
   local focused_screen = awful.screen.focused()
   local workarea = awful.screen.focused().workarea
   local selected_tag = awful.screen.focused().selected_tag
   local tablist = {}
   local active_region = nil

   local regions = awful.layout.get(focused_screen).machi_get_regions(workarea, selected_tag)
   --+ table of regions on the selected screen and tag

   if not client.focus then return false end
   --+ flow control

   for i, a in ipairs(regions) do
      if a.x <= client.focus.x and client.focus.x < a.x + a.width and
         a.y <= client.focus.y and client.focus.y < a.y + a.height
      then
         active_region = i
      end
   end
   --+ focused client's region

   for _, tc in ipairs(screen[focused_screen].tiled_clients) do
      if not (tc.floating or tc.immobilized) then
         if regions[active_region].x <= tc.x + tc.width + tc.border_width * 2 and
            tc.x <= regions[active_region].x + regions[active_region].width  and
            regions[active_region].y <= tc.y + tc.height + tc.border_width * 2  and
            tc.y <= regions[active_region].y + regions[active_region].height 
         then
            tablist[#tablist + 1] = tc
         end
      end
   end
   --+ tablist inside the active region

   if not tablelength(tablist) == 1 then return false end
   --+ flow control

    return tablist
end
--+ tablist order is adjusted by awesomewm and it will
--> always have the focused client as the first item.

---------------------------------------------------------> key bindings -- ;

local keys = gears.table.join(
   awful.key({modkey}, "p", function ()
      local tablist = region_tablist()
      local next_client = nil

      if not tablist then return false end
      --+ flow control

      for _, cc in ipairs(tablist) do
         if (cc.window == client.focus.window) then
            if tablist[_+1] then
               client.focus:lower()
               next_client = tablist[_+1]
               next_client:emit_signal("request::activate", "mouse_enter",{raise = true})
               break
               --+ activate next client
             end
         end
      end
    end),
    --+ shortcut: shuffle down

   awful.key({modkey}, "o", function () 
      local tablist = region_tablist()
      local prev_client = nil

      if not tablist then return false end
      --+ flow control

      for i = #tablist, 1, -1 do
         prev_client = tablist[i]
         prev_client:emit_signal("request::activate", "mouse_enter",{raise = true})
         break
         --+ activate previous client
      end
   end),
   --+ shortcut: shuffle up

   awful.key({ modkey,   }, "Page_Up", function () 
      client.focus:geometry({width=800,height=800}) awful.placement.top_right(client.focus) 
   end),
    --+ shortcut: align top-right

   awful.key({ modkey,    }, "Page_Down", function () 
      client.focus:geometry({width=800,height=800}) awful.placement.bottom_right(client.focus)
   end),
   --+ shortcut: align bottom-right

   awful.key({ modkey,    }, "Home", function () 
      if not client.focus.floating then client.focus.floating = true end
      awful.placement.centered(client.focus) 
   end),
   --+ shortcut: align center as float

   awful.key({ modkey,    }, "Insert", function () 
      awful.placement.top_left(client.focus) 
   end),
   --+ shortcut: align top-left

   awful.key({ modkey,    }, "Delete", function () 
      awful.placement.bottom_left(client.focus) 
   end)
   --+ shortcut: align bottom-left

)

--------------------------------------------------------------> exports -- ;

local module = {
   keys = keys,
   tablist = tablist
}

return module
---------------------------------------------------------> dependencies -- ;

local gears = require("gears")
local awful = require("awful")
local modkey = "Mod4"
local show_desktop = true

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

   if not client.focus then return {} end
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
   
   if tablelength(tablist) == 1 then 
      return {}
   end
   --+ flow control: if there is only one client in the
   --> region, there is nothing to shuffle. having this here
   --> makes it easier to avoid if nesting later.

    return tablist
end
--+ tablist order is adjusted by awesomewm and it will
--> always have the focused client as the first item.

---------------------------------------------------------> key bindings -- ;

local keys = gears.table.join(
   
   ----------------------> SHUFFLE <----------------------

   awful.key({modkey}, "[", function () 
      local tablist = region_tablist()
      local prev_client = nil

      for i = #tablist, 1, -1 do
         prev_client = tablist[i]
         prev_client:emit_signal("request::activate", "mouse_enter",{raise = true})
         break
         --+ activate previous client
      end
   end),
   ----+ shortcut: shuffle back

   awful.key({modkey}, "]", function ()
      local tablist = region_tablist()
      local next_client = nil

      for _, cc in ipairs(tablist) do
         client.focus:lower()
         next_client = tablist[_+1]
         next_client:emit_signal("request::activate", "mouse_enter",{raise = true})
         break
         --+ activate next client
      end
    end),
    ----+ shortcut: shuffle forward


   ----------------------> PLACEMENT <----------------------

   awful.key({modkey}, "Page_Up", function () 
      if not client.focus then return false end

      client.focus:geometry({width=800,height=800})
      awful.placement.top_right(client.focus)
      client.focus:raise() 
   end),
   ----+ shortcut: align top-right

   awful.key({modkey}, "Page_Down", function () 
      if not client.focus then return false end

      client.focus:geometry({width=800,height=800})
      awful.placement.bottom_right(client.focus)
      client.focus:raise() 
   end),
   ----+ shortcut: align bottom-right

   awful.key({modkey}, "Home", function () 
      if not client.focus.floating then client.focus.floating = true end
      awful.placement.centered(client.focus) 
      client.focus:raise() 
   end),
   ----+ shortcut: align center as float

   awful.key({modkey}, "Insert", function ()
      if not client.focus then return false end

      awful.placement.top_left(client.focus) 
      client.focus:raise() 
   end),
   ----+ shortcut: align top-left

   awful.key({modkey}, "Delete", function () 
      if not client.focus then return false end

      awful.placement.bottom_left(client.focus) 
      client.focus:raise() 
   end),
   ----+ shortcut: align bottom-left

   ----------------------> NAVIGATION <----------------------

   awful.key({modkey}, "j", function () 
      if not client.focus then return false end

      awful.client.focus.bydirection("left", nil,true)
      client.focus:raise()
   end),
   ----+ shortcut: stack friendly left

   awful.key({modkey, "Shift"}, "j", function () 
      if not client.focus then return false end

      c = client.focus
      c.machi.region = 1
      naughty.notify({text=inspect(c.machi)})
   end),
   ----+ shortcut:

   awful.key({modkey}, "k", function ()
      if not client.focus then return false end

      awful.client.focus.bydirection("down", nil,true)
      client.focus:raise()
   end),
   ----+ shortcut: stack friendly down
   
   awful.key({modkey}, "l", function ()
      if not client.focus then return false end

      awful.client.focus.bydirection("right", nil,true)
      client.focus:raise()
   end),
   ----+ shortcut: stack friendly right

   awful.key({modkey}, "i", function ()
      if not client.focus then return false end

      awful.client.focus.bydirection("up", nil,true)
      client.focus:raise()
   end)
   ----+ shortcut: stack friendly up

   ----------------------> MISC <----------------------

   -- awful.key({modkey}, "F9", function ()
   --    if show_desktop then 
   --       awful.tag.viewnone()
   --       show_desktop = false
   --       return false
   --    end

   --    if not show_desktop then
   --       awful.tag.viewtoggle()
   --       return false
   --    end
   -- end)
   ----+ shortcut: stack friendly up


)

--------------------------------------------------------------> exports -- ;

local module = {
   keys = keys,
   tablist = tablist
}

return module



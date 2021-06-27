---------------------------------------------------------------- locals -- ;

local grect = require("gears.geometry").rectangle
local geoms = {}

geoms.crt43 = function ()
   return {
      x = awful.screen.focused().workarea.width - client.focus:geometry().width,
      y = awful.screen.focused().workarea.height - client.focus:geometry().height,
      width = 1280,
      height = 1024
   }
end

geoms.p1080 = function ()
   return {
      x = awful.screen.focused().workarea.width - client.focus:geometry().width,
      y = awful.screen.focused().workarea.height - client.focus:geometry().height,
      width = awful.screen.focused().workarea.width * 0.70,
      height = awful.screen.focused().workarea.height * 0.90
   }
end

local function compare(a,b)
   return a.v < b.v
end

local function tablelength(T)
   local count = 0
   for _ in pairs(T) do count = count + 1 end
   return count
end

local function focus_by_direction(direction)
   return function()
      if not client.focus then return false end
      awful.client.focus.bydirection(direction, nil,true)
      client.focus:raise()
   end
end

local function screen_info()
   local focused_screen = awful.screen.focused() or nil
   local workarea = focused_screen.workarea or nil
   local selected_tag = focused_screen.selected_tag or nil
   local layout = awful.layout.get(focused_screen) or nil
   local focused_client = client.focus or nil

   return focused_screen, workarea, selectedtag, layout, focused_client
end

--------------------------------------------------------- get_regions() -- ;

local function get_regions()
   local focused_screen,
         workarea,
         selected_tag,
         layout,
         focused_client = screen_info()

   local machi_fn = nil
   local machi_data = nil
   local machi_regions = nil

   if layout.machi_get_regions then
      machi_fn = layout.machi_get_regions
      machi_data = machi_fn(workarea, selected_tag)
      machi_regions = machi_data
   end --| version 1

   if layout.machi_get_instance_data then
      machi_fn = layout.machi_get_instance_data
      machi_data = {machi_fn(focused_screen, selected_tag)}
      machi_regions = machi_data[3]
   
      for i=#machi_regions,1,-1 do
          if machi_regions[i].habitable == false  then
              table.remove(machi_regions, i)
          end
      end --| remove unhabitable regions

      table.sort(
         machi_regions,
         function (a1, a2)
            local s1 = a1.width * a1.height
            local s2 = a2.width * a2.height
            if math.abs(s1 - s2) < 0.01 then
               return (a1.x + a1.y) < (a2.x + a2.y)
            else
               return s1 > s2
            end
         end
      ) --| unlike v1, v2 returns unordered region list and
        --| needs sorting
   end --| version 2/NG

   return machi_regions, machi_fn
end

-------------------------------------------------- get_active_regions() -- ;

local function get_active_regions()
   local active_region = nil
   local outofboundary = nil
   local proximity = {}
   local regions = get_regions()
   
   if (not regions) then return {} end
   -- flow control

   if not client.focus then return {} end
   -- flow control

   if client.focus.x < 0 or client.focus.y < 0 
      then outofboundary = true 
   end --| negative coordinates always mean out of boundary

   for i, a in ipairs(regions) do
      local px = a.x - client.focus.x
      local py = a.y - client.focus.y

      if px == 0 then px = 1 end
      if py == 0 then py = 1 end

      proximity[i] = {
         index = i,
         v = math.abs(px * py)
      } --│ keep track of proximity in case nothing matches in
        --│ this block.

   end --│ figures out focused client's region under normal
       --│ circumstances.

   if not active_region then
      table.sort(proximity, compare)       --| sort to get the smallest area
      active_region = proximity[1].index   --| first item should be the right choice
      ----┐
          -- naughty.notify({preset = naughty.config.presets.critical, text=inspect(regions[active_region])})
          -- naughty.notify({preset = naughty.config.presets.critical, text=tostring(client.focus.width .. " " .. client.focus.height)})

      if client.focus.floating then
         if regions[active_region].width - client.focus.width ~= 2
            or regions[active_region].height - client.focus.height ~= 2
         then
            outofboundary = true
         end
      end --| when client is not the same size as the located
          --| region, we should still consider this as out of
          --| boundary
   end --| user is probably executing get_active_regions on a
       --| floating window.

   if not active_region then
      active_region = 1
   end --| at this point, we are out of options, set the index
       --| to one and hope for the best.

   return {
      active_region = active_region,
      regions = regions,
      outofboundary = outofboundary
   }
end
-- tablist order is adjusted by awesomewm and it will
-- always have the focused client as the first item.

------------------------------------------------------ region_tablist() -- ;

local function region_tablist()
   local focused_screen = awful.screen.focused()
   local workarea = awful.screen.focused().workarea
   local selected_tag = awful.screen.focused().selected_tag
   local tablist = {}
   local active_region = nil

   local regions = get_regions()
   
   if (not regions) then return {} end
   -- flow control

   if not client.focus then return {} end
   -- flow control

   if client.floating then return {} end

   for i, a in ipairs(regions) do
      if a.x <= client.focus.x and client.focus.x < a.x + a.width and
         a.y <= client.focus.y and client.focus.y < a.y + a.height
      then
         active_region = i
      end
   end --| focused client's region

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
   end --| tablist inside the active region
   
   if tablelength(tablist) == 1 then 
      return {}
   end --| flow control: if there is only one client in the
       --| region, there is nothing to shuffle. having this here
       --| makes it easier to avoid if nesting later.

    return tablist
end
-- tablist order is adjusted by awesomewm and it will
-- always have the focused client as the first item.
-- list of all the clients within a region.

----------------------------------------------------- expand_horizontal -- ;

local function expand_horizontal(direction)
   return function ()
      local c = client.focus
      local geom = nil

      if c.maximized_horizontal then 
         c.maximized_horizontal = false
      end --| reset toggle maximized state

      if c.direction == direction then
         c.direction = nil
         return
      end --| reset toggle when sending same shortcut
          --| consequitively

      local stuff = get_active_regions()
      local target = grect.get_in_direction(direction, stuff.regions, client.focus:geometry())
      
      if not target and direction ~= "center" then return end -- flow control

      if direction == "right" then
         tobe = {
            x=c.x,
            width=stuff.regions[target].x + stuff.regions[target].width - c.x
         }
         c.direction = direction
         c.maximized_horizontal = true
         c.maximixed_vertical = false
         c.width = tobe.width
         c.x = tobe.x
         c:raise()
         return
      end

      if direction == "left" then
         tobe = {
            x=stuff.regions[target].x,
            width=c.x + c.width - stuff.regions[target].x
         }
         c.direction = direction
         c.maximized_horizontal = true
         c.maximixed_vertical = false
         c.width = tobe.width
         c.x = tobe.x
         c:raise()
         return
      end
     
      if direction == "center" then
         
         c.maximized = false
         c.maximixed_vertical = false

         if c.floating then
            geom = geoms.crt43()
         end

         if not c.floating then
            c.direction = "center"
            c.maximized_horizontal = true
            geom = geoms.p1080()
         end
         
         gears.timer.delayed_call(function () 
            client.focus:geometry(geom)
            awful.placement.centered(client.focus)
         end) --| give it time in case maximize_horizontal is
              --| adjusted before centering
         
         return
      end
   end
end
-- c.direction is used to create a fake toggling effect.
-- tiled clients require an internal maximized property to
-- be set, otherwise they won't budge.

----------------------------------------------------- expand_vertical() -- ;

local function expand_vertical()
   local c = client.focus
   local going = "down"

   if c.maximized_vertical then 
      c.maximized_vertical = false
      return
   end --| reset toggle maximized state

   local stuff = get_active_regions()
   local target = grect.get_in_direction("down", stuff.regions, client.focus:geometry())
   
   if target and stuff.regions[target].x ~= c.x then
      return
   end --| flow control
       --| ensure we are operating in the same X axis,
       --| vertical directions jump around

   if not target then
      going = "up"
      target = grect.get_in_direction("up", stuff.regions, client.focus:geometry())
   end --| flow control
       --| try reverse direction

   if not target then return end
   -- flow control
   
   if going == "down" then
      tobe = {
         y=c.y,
         height=stuff.regions[target].y + stuff.regions[target].height - c.y
      }
   end

   if going == "up" then
      tobe = {
         y=stuff.regions[target].y,
         height= c.height + c.y - stuff.regions[target].y
      }
   end

   c.maximized_vertical = true
   c.height = tobe.height
   c.y = tobe.y
   c:raise()

   return
end

---------------------------------------------------- shift_by_direction -- ;

local function shift_by_direction(direction, swap)
   return function ()
      local stuff = get_active_regions()
      local cltbl = awful.client.visible(client.focus.screen, true)

      local map = {}
      for a,region in ipairs(stuff.regions) do
         for i,c in ipairs(cltbl) do
            if c.x == region.x and c.y == region.y then
               map[a] = i
               break --| avoid stacked regions
            end
         end
      end --◸
          --| client list order we obtain via cltbl changes in
          --| each invokation, therfore we need to map the
          --| client table onto the region_list from machi.
          --| this will give us the region numbers of clients. 
          --| naughty.notify({text=inspect(map)})
          --◺

      local target = grect.get_in_direction(direction, stuff.regions, client.focus:geometry())
      --| awesomewm magic function to find out what lies
      --| ahead and beyond based on the direction

      if not target then
         target = stuff.active_region + 1 
         
         if target > #stuff.regions then
            target = stuff.active_region - 1
         end
      end --◸
          --| we bumped into an edge, try to locate region via
          --| region_index and if that also fails, set back the
          --| previous region as target clock wise.
          --| naughty.notify({text=inspect(target)})
          --| naughty.notify({text=inspect(map[target])})
          --| naughty.notify({text=inspect(cltbl[map[target]])})
          --◺

      tobe = stuff.regions[target]
      is = client.focus:geometry()

      client.focus:geometry(tobe)
      -- relocate

      swapee = cltbl[map[target]]
      -- try to get client at target region

      if swap and swapee then
         swapee:geometry(is)
         swapee:raise()
      end

      -- naughty.notify({text=inspect(cltbl[2]:geometry())})
      -- --◹◿ naughty.notify({text=inspect(cltbl[2]:geometry())})
   end
end

------------------------------------------------------------- shuffle() -- ;

local function shuffle(direction)
   return function()
      if direction == "backward" then
         local tablist = region_tablist()
         local prev_client = nil

         for i = #tablist, 1, -1 do
            prev_client = tablist[i]
            prev_client:emit_signal("request::activate", "mouse_enter",{raise = true})
            break --| activate previous client
         end
         return
      end

      if direction == "forward" then
         local tablist = region_tablist()
         local next_client = nil

         for _, cc in ipairs(tablist) do
            client.focus:lower()
            next_client = tablist[_+1]
            next_client:emit_signal("request::activate", "mouse_enter",{raise = true})
            break --| activate next client
         end
         return
      end
   end
end

local function my_shifter(direction)
   return function()

      if direction == "backward" then
         local next_client = nil
         local stuff = get_active_regions()
         local client_region = stuff.active_region
         local next_region

         if (client_region + 1 > #stuff.regions) then 
            next_region=stuff.regions[1]
         else
            next_region=stuff.regions[client_region+1]
         end --| figure out the action

         if stuff.outofboundary then
            next_region=stuff.regions[client_region]
         end --| ignore action, and push inside the boundary instead

         client.focus:geometry({
            x=next_region.x,
            y=next_region.y,
            width=next_region.width-2,
            height=next_region.height-2
         })
         return
      end

      if direction == "forward" then
      
         local next_client = nil
         local stuff = get_active_regions()
         local client_region = stuff.active_region
         local previous_region

         if (client_region - 1 < 1) then 
            previous_region = stuff.regions[#stuff.regions]
         else
            previous_region = stuff.regions[client_region-1]
         end --| figure out the action

         if stuff.outofboundary then
            previous_region = stuff.regions[client_region]
         end --| ignore action, and push inside the boundary instead

         client.focus:geometry({
            x=previous_region.x,
            y=previous_region.y,
            width=previous_region.width-2,
            height=previous_region.height-2
         })
      
      end


   end   
end
--------------------------------------------------------------- exports -- ;

module = {
   region_tablist = region_tablist,
   focus_by_direction = focus_by_direction,
   compare = compare,
   get_active_regions = get_active_regions,
   shift_by_direction = shift_by_direction,
   expand_horizontal = expand_horizontal,
   geoms = geoms,
   shuffle = shuffle,
   my_shifter = my_shifter,
   expand_vertical = expand_vertical
}

return module




-- naughty.notify({preset = naughty.config.presets.critical,text=inspect(client.focus:geometry())})
-- naughty.notify({preset = naughty.config.presets.critical,text=inspect(regions)})
-- naughty.notify({preset = naughty.config.presets.critical,text=inspect(proximity)})

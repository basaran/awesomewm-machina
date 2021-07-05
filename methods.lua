
--------------------------------------------------------- dependencies  -- ;

local grect = require("gears.geometry").rectangle
local tabs = require("machina.tabs")
local geoms = require("machina.geoms")
local helpers = require("machina.helpers")

local get_client_ix = helpers.get_client_ix
local getlowest = helpers.getlowest
local compare = helpers.compare
local tablelength = helpers.tablelength
local set_contains = helpers.set_contains
local clear_tabbar = helpers.clear_tabbar

---------------------------------------------------------------- locals -- ;

local global_client_table = {}
local global_tab_table = {}

function get_global_clients()
   return global_client_table
end

function update_global_clients(c)
   global_client_table[c.window] = c
end

function log(m,context)
   context = context or ""
   naughty.notify({text=inspect(m) .. " :" .. context })
end

local function clear_tabbar(c, position)
   -- log(position, " clear_tab_bar_invoked ")

   if not c then return end
   
   position = position or "bottom"
   local titlebar = awful.titlebar(c, {size=3, position=position})
   awful.titlebar(c, {size=0, position="left"})
   awful.titlebar(c, {size=0, position="right"})
   titlebar:setup{
      layout=wibox.layout.flex.horizontal, nil
   }
end --|clears bottom tabbar


------------------------------------------------------------- go_edge() -- ;

local function go_edge(direction, regions, current_box)
   test_box = true
   edge_pos = nil

   while test_box do
      test_box = grect.get_in_direction(direction, regions, current_box)

      if test_box then
         current_box = regions[test_box]
         edge_pos = test_box
      end
   end

   return edge_pos
end --|
    --|figures out the beginning of each row on the layout.

----------------------------------------------------------- always_on() -- ;

local function toggle_always_on()
   always_on = nil or client.focus.always_on
   client.focus.always_on = not always_on
end

--------------------------------------------------------- screen_info() -- ;

local function screen_info()
   local focused_screen = awful.screen.focused() or nil
   local workarea = focused_screen.workarea or nil
   local selected_tag = focused_screen.selected_tag or nil
   local layout = awful.layout.get(focused_screen) or nil
   local focused_client = client.focus or nil

   return focused_screen,
      workarea,
      selected_tag,
      layout,
      focused_client
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
   end --|version 1

   if layout.machi_get_instance_data then
      machi_fn = layout.machi_get_instance_data
      machi_geom = layout.machi_set_geometry
      machi_data = {machi_fn(screen[focused_screen], selected_tag)}
      machi_regions = machi_data[3]
   
      for i=#machi_regions,1,-1 do
         if machi_regions[i].habitable == false  then
            table.remove(machi_regions, i)
         end
      end --|remove unhabitable regions

      table.sort(
         machi_regions,
         function (a1, a2)
            return a1.id > a2.id
         end
      ) --|v2 returns unordered region list and needs sorting.
   end --|version 2/NG

   return machi_regions, machi_fn
end

----------------------------------------------------------- get_edges() -- ;

local function move_to(location)
   return function()
      local useless_gap = nil
      local regions = get_regions()
      local edges = {x={},y={}}

      for i,region in ipairs(regions) do
         edges.x[region.x] = region.x + region.width
         edges.y[region.y] = region.y + region.height
      end
      
      useless_gap = getlowest(edges.x)
      client.focus:geometry(geoms[location](useless_gap))
      return
   end
end

------------------------------------------------------- get_client_info -- ;

local function get_client_info(c)
   local active_region = nil
   local outofboundary = nil
   local proximity = {}
   local regions = get_regions()
   local source_client = c or client.focus or nil
   

   if not regions then return {} end
   --|flow control

   if not source_client then return {} end
   --|flow control

   if source_client.x < 0 or source_client.y < 0 
      then outofboundary = true 
   end --| negative coordinates always mean out of boundary


   for i, a in ipairs(regions) do
      local px = a.x - source_client.x
      local py = a.y - source_client.y

      if px == 0 then px = 1 end
      if py == 0 then py = 1 end

      proximity[i] = {
         index = i,
         v = math.abs(px * py)
      } --│keep track of proximity in case nothing matches in
        --│this block.

   end --│figures out focused client's region under normal
       --│circumstances.

   if not active_region then
      table.sort(proximity, compare)       --| sort to get the smallest area
      active_region = proximity[1].index   --| first item should be the right choice

      if source_client.floating then
         if regions[active_region].width - source_client.width ~= 0
            or regions[active_region].height - source_client.height ~= 0
         then
            outofboundary = true
         end
      end --|when client is not the same size as the located
          --|region, we should still consider this as out of
          --|boundary
   end --|user is probably executing get_active_regions on a
       --|floating window.

   if not active_region then
      active_region = 1
   end --|at this point, we are out of options, set the index
       --|to one and hope for the best.


   -- refactor
   if active_region and source_client.width > regions[active_region].width then
      outofboundary = true
   end --|machi sometimes could auto expand the client, consider
       --|that as out of boundary.

   if active_region and source_client.height > regions[active_region].height then
      outofboundary = true
   end --|machi sometimes could auto expand the client, consider
       --|that as out of boundary.
   -- refactor


   return {
      active_region = active_region,
      regions = regions,
      outofboundary = outofboundary
   }
end

----------------------------------------- focus_by_direction(direction) -- ;

local function focus_by_direction(direction)
   return function()
      if not client.focus then return false end
      awful.client.focus.global_bydirection(direction, nil,true)
      client.focus:raise()
   end
end

------------------------------------------------------ region_tablist() -- ;

local function test_tablist(region_ix, c)
   local focused_screen = awful.screen.focused()
   local workarea = awful.screen.focused().workarea
   local selected_tag = awful.screen.focused().selected_tag
   local tablist = {}
   local active_region = region_ix or nil
   local source_client = c or client.focus or nil
   local regions = get_regions()
   
   all_client = get_global_clients()

   if not active_region then
      for i, a in ipairs(regions) do
         if a.x <= source_client.x and source_client.x < a.x + a.width and
            a.y <= source_client.y and source_client.y < a.y + a.height
         then
            active_region = i
         end
      end
   end --|if no region index provided, find the region of the
       --|focused_client.


   region_clients = {}
   for i, cc in pairs(all_client) do
      if cc.region == active_region and regions[active_region].x == cc.x 
         and regions[active_region].y == cc.y
         then
         region_clients[#region_clients + 1] = cc
      end
   end

    return region_clients

end


local function region_tablist(region_ix, c)
   local focused_screen = awful.screen.focused()
   local workarea = awful.screen.focused().workarea
   local selected_tag = awful.screen.focused().selected_tag
   local tablist = {}
   local active_region = region_ix or nil
   local source_client = c or client.focus or nil

   local regions = get_regions()
   
   if not regions then return {} end
   --|flow control


   ------------------ CHECK FOR SIDE EFFECTS
   -- if not source_client or source_client.floating then return {} end
   --|flow control

   if not active_region then
      for i, a in ipairs(regions) do
         if a.x <= source_client.x and source_client.x < a.x + a.width and
            a.y <= source_client.y and source_client.y < a.y + a.height
         then
            active_region = i
         end
      end
   end --|if no region index provided, find the region of the
       --|focused_client.

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
   end --|tablist inside the active region

    return tablist
end
--|tablist order is adjusted by awesomewm and it will
--|always have the focused client as the first item.
--|list of all the clients within a region.

----------------------------------------------------- expand_horizontal -- ;

local function expand_horizontal(direction)
   return function ()
      local c = client.focus
      local geom = nil

      if c.maximized_horizontal then 
         c.maximized_horizontal = false
      end --|reset toggle maximized state

      if c.direction == direction then
         c.direction = nil
         c.maximized_horizontal = false
         c.maximized_vertical = false
         draw_tabbar(c.region)
         resize_region(c.region, c:geometry(), true)
         return
      end --|reset toggle when sending same shortcut
          --|consequitively

      local stuff = get_client_info()
      local target = grect.get_in_direction(direction, stuff.regions, client.focus:geometry())
      
      if not target and direction ~= "center" then return end -- flow control

      --▨▨▨
      if direction == "right" then
         tobe = {
            x=c.x,
            width=math.abs(stuff.regions[target].x + stuff.regions[target].width - c.x - 4),
            height=c.height,
            y=c.y
         }

         c.direction = direction
         c.maximized_horizontal = true
         c.maximixed_vertical = false

         -- if not c.floating then
         --    awful.layout.get(focused_screen).machi_zort(c, tobe)
         --    instance_data = awful.layout.get(
         --       awful.screen.focused())
         --       .machi_get_instance_data(awful.screen.focused(), awful.screen.selected_tag)
         --       naughty.notify({text=inspect(instance_data)})

         --    instance_data[c] = {
         --       lu=0, rd=0
         --    }
         -- end
   
         gears.timer.delayed_call(function (c) 
            c:geometry(tobe)
            draw_tabbar(c.region)
            resize_region(c.region, tobe, {horizontal=true,vertical=false,direction=direction})
            -- clear_tabbar(c)
         end,c)
         return
      end

      --▨▨▨
      if direction == "left" then
         tobe = {
            x=stuff.regions[target].x,
            width=c.x + c.width - stuff.regions[target].x,
            height=c.height,
            y=c.y
         }
         c.direction = direction
         c.maximized_horizontal = true
         c.maximixed_vertical = false

         gears.timer.delayed_call(function (c) 
            client.focus:geometry(tobe)
            draw_tabbar(c.region)
            clear_tabbar(c)
         end,c)
         return
      end
     
      --▨▨▨
      if direction == "center" then
         c.maximized = false
         c.maximixed_vertical = false
         fixedchoice = geoms.clients[c.class] or nil

         if c.floating then
            c.maximized_horizontal = false
            geom = geoms.crt43()
         end

         if not c.floating then
            c.direction = "center"
            c.maximized_horizontal = true
            geom = geoms.p1080()
         end

         if fixedchoice then
            c.direction = "center"
            c.maximized_horizontal = true
            geom = fixedchoice()
         end

         c:geometry(geom)
         awful.placement.centered(c)

         gears.timer.delayed_call(function (c)
            c:raise()
            client.emit_signal("tabbar_draw", c.region)
            clear_tabbar(c)
         end,c) --|give it time in case maximize_horizontal is
              --|adjusted before centering
         return
      end
   end
end
--|c.direction is used to create a fake toggling effect.
--|tiled clients require an internal maximized property to
--|be set, otherwise they won't budge.

--|change the logic handling for the center layout to use
--|fixedchoices

----------------------------------------------------- expand_vertical() -- ;

local function expand_vertical()
   local c = client.focus
   local going = "down"

   if c.maximized_vertical then 
      c.maximized_vertical = false
      return
   end --|reset toggle maximized state

   local stuff = get_client_info()
   local target = grect.get_in_direction("down", stuff.regions, client.focus:geometry())
   
   if target and stuff.regions[target].x ~= c.x then
      return
   end --|flow control
       --|ensure we are operating in the same X axis,
       --|vertical directions jump around

   if not target then
      going = "up"
      target = grect.get_in_direction("up", stuff.regions, client.focus:geometry())
   end --|flow control
       --|try reverse direction

   if not target then return end
   --|flow control
   
   if going == "down" then
      tobe = {
         y=c.y,
         x=c.x,
         width=c.width,
         height=stuff.regions[target].y + stuff.regions[target].height - c.y
      }
   end

   if going == "up" then
      tobe = {
         x=c.x,
         width=c.width,
         y=stuff.regions[target].y,
         height= c.height + c.y - stuff.regions[target].y
      }
   end

   c.maximized_vertical = true

   gears.timer.delayed_call(function () 
      client.focus:geometry(tobe)   
      client.focus:raise()
   end)

   return
end

------------------------------------------------------------- shuffle() -- ;

local function shuffle(direction)
   return function()
      local tablist = get_tiled_clients()
      --|this is the ordered list
      

      if not #tablist then return end
      --▨ flow control

      if not client.focus then return end
      --▨ flow control

      focused_client_ix = get_client_ix(client.focus.window, tablist)
      --|find the index position of the focused client

      if not focused_client_ix then return end
      --▨ flow control

      prev_ix = focused_client_ix - 1
      next_ix = focused_client_ix + 1
      --|calculate target indexes

      if next_ix > #tablist then next_ix = 1 end
      if prev_ix < 1 then prev_ix = #tablist end
      --|check for validity of the index

      if direction == "backward" then
         tablist[prev_ix]:emit_signal("request::activate", "mouse_enter",{raise = true})
         return
      end

      if direction == "forward" then
         tablist[next_ix]:emit_signal("request::activate", "mouse_enter",{raise = true})
         return
      end
   end
end

---------------------------------------------------------- get_swapee() -- ;

local function get_swapee(target_region_ix)
   local regions = get_regions()
   --| all regions

   local cltbl = awful.client.visible(client.focus.screen, true)
   --| all visible clients on all regions
   --| but we don't know which regions they are at
   
   local swap_map = {}

   for a,region in ipairs(regions) do
      for i,c in ipairs(cltbl) do
         if c.x == region.x and c.y == region.y then
            swap_map[a] = i
            break --|avoid stacked regions
         end
      end
   end --|iterate over regions, and match the client objects in
       --|each region.

   local swapee = cltbl[swap_map[target_region_ix]]
   return swapee
end
--[[
   returns the client object at a specific region. we can
   also use signals to keep track of this but we are trying
   to avoid exessive use of signals.
--]]

---------------------------------------------------------- my_shifter() -- ;

local function reset_client_meta(c)
   c.maximized = false
   c.maximized_horizontal = false
   c.maximized_vertical = false
   c.direction = nil
   return c
end

local function my_shifter(direction, swap)
   return function()

      if direction == "left" then direction = "backward" end
      if direction == "right" then direction = "forward" end

      local c = client.focus
      local stuff = get_client_info()
      local client_region_ix = stuff.active_region
      local source_region
      local target_region_ix
      local target_region

      c = reset_client_meta(c)
      --|clean artifacts in case client was expanded.
   
      if direction == "backward" then
         if (client_region_ix + 1) > #stuff.regions then 
            target_region_ix = 1
         else
            target_region_ix = client_region_ix+1
         end
      end --|go next region by index, 
          --|if not reset to first

      if direction == "forward" then
         if (client_region_ix - 1) < 1 then 
            target_region_ix = #stuff.regions
         else
            target_region_ix = client_region_ix - 1
         end
      end --|go previous region by index,
          --|if not reset to last

      if stuff.outofboundary then
         target_region_ix = client_region_ix
      end --|ignore previous when out of boundary
          --|probably floating or expanded client
          --|push inside the boundary instead

      source_region = stuff.regions[client_region_ix]
      target_region = stuff.regions[target_region_ix]
      --|target regions geometry

      local swapee = get_swapee(target_region_ix)
      --|visible client at the target region

      c:geometry(target_region)
      --|relocate client

      c.region = target_region_ix
      --|update client property

      if not swap then c:raise() end
      --|raise

      if swap and swapee then
         swapee:geometry(source_region)
         swapee:emit_signal("request::activate", "mouse_enter",{raise = true})
      end --|perform swap

      draw_tabbar(target_region_ix)
      resize_region(target_region_ix, target_region, true)
      --|update tabs in target region
      
      draw_tabbar(client_region_ix)
      resize_region(client_region_ix, source_region, true)
      --|update tabs in source region
   end   
end

---------------------------------------------------- shift_by_direction -- ;

local function shift_by_direction(direction, swap)
   return function ()

      local c = client.focus
      local stuff = get_client_info()
      local target_region_ix = nil
      local client_region_ix = stuff.active_region

      if stuff.outofboundary == true then
         return my_shifter(direction)()
      end --|my_shifter handles this situation better.

      local candidate = {
         up = grect.get_in_direction("up", stuff.regions, client.focus:geometry()),
         down = grect.get_in_direction("down", stuff.regions, client.focus:geometry()),
         left = grect.get_in_direction("left", stuff.regions, client.focus:geometry()),
         right = grect.get_in_direction("right", stuff.regions, client.focus:geometry())
      } --|awesomewm magic function to find out what lies
        --|ahead and beyond based on the direction

      target_region_ix = candidate[direction]
      --|try to get a candidate region if possible

      if not target_region_ix then
         if direction == "right" then try = "left" end
         if direction == "left" then try = "right" end
         if direction == "down" then try = "up" end
         if direction == "up" then try = "down" end

         target_region_ix = go_edge(try, stuff.regions, client.focus:geometry())
      end --|go the beginning or the end if there is no
          --|candidate
      
      source_region = stuff.regions[client_region_ix]
      target_region = stuff.regions[target_region_ix]

      local swapee = get_swapee(target_region_ix)
      --|visible client at the target region

      c:geometry(target_region)
      --|relocate client

      c.region = target_region_ix
      --|update client property

      if not swap then c:raise() end
      --|raise

      if swap and swapee then
         swapee:geometry(source_region)
         swapee:emit_signal("request::activate", "mouse_enter",{raise = true})
      end --|perform swap

      draw_tabbar(target_region_ix)
      resize_region(target_region_ix, target_region, true)
      --|update tabs in target region
      
      draw_tabbar(client_region_ix)
      resize_region(client_region_ix, source_region, true)
      --|update tabs in source region
   end
end

----------------------------------------------------- get_tiled_clients -- ;

function get_tiled_clients(region_ix)
   local tablist = test_tablist(region_ix)
   local all_clients = get_global_clients()
   local tiled_clients = {}
   local myorder = {}
   local window_ix = {}

   for i,t in ipairs(tablist) do
      window_ix[t.window] = true
   end

   local po = 1
   for i,c in pairs(all_clients) do
      if not c.floating and window_ix[c.window] then
            tiled_clients[po] = c
         po = po + 1
      end
   end

   return tiled_clients
end
--[[+]
   global_client_index stores the ordered list of all clients
   available and it is used as a blueprint to keep the order
   of our tablist intact, without this, tabbars would go out
   of order when user focuses via shortcuts (run_or_raise). ]]

-------------------------------------------------------- draw_tabbar() -- ;



-- client.connect_signal("property::name", function (c)
--    -- todo: need to update the other clients in the region here as well
      -- this may not even be worth it as the client names kind of pollute the
      -- tabs a lot making it harder to distinguish what is what.

--    if widget_ix[c.window] then
--       for i, p in pairs(widget_ix[c.window]) do
--          if p.focused then
--             widget = widget_ix[c.window][i]:get_children_by_id(c.window)[1]
--             -- naughty.notify({preset = naughty.config.presets.critical, text=inspect(widget)})
--             widget.widget.markup = c.name
--          end
--       end
--    end
-- end)


client.connect_signal("focus", function (c)
   if global_tab_table[c.window] then
      for i, p in pairs(global_tab_table[c.window]) do
         if p.focused then
            local widget = global_tab_table[c.window][i]:get_children_by_id(c.window)[1]
            widget.bg = "#43417a"
         end
      end
   end
end)

client.connect_signal("unfocus", function (c)
   if global_tab_table[c.window] then
      for i, p in pairs(global_tab_table[c.window]) do
         if p.focused then
            p.bg = "#292929"
            break
         end
      end
   end
end)

function draw_tabbar(region_ix)
   local flexlist = tabs.layout()
   local tablist = get_tiled_clients(region_ix)

   if tablelength(tablist) == 0 then
      return
   end --|this should only fire on an empty region

   if tablelength(tablist) == 1 then
      clear_tabbar(tablist[1])
      return
   end --|reset tabbar titlebar when only
       --|one client is in the region.

   for c_ix, c in ipairs(tablist) do
      local flexlist = tabs.layout()
      global_tab_table[c.window] = {}

      for cc_ix, cc in ipairs(tablist) do
         local buttons = gears.table.join(awful.button({}, 1, function() end))
         -- wid_temp
         global_tab_table[c.window][cc_ix] = tabs.create(cc, (cc == c), buttons, c_ix)

         flexlist:add(global_tab_table[c.window][cc_ix])
         flexlist.max_widget_size = 120
      end

      local titlebar = awful.titlebar(c, {
         bg = tabs.bg_normal,
         size = tabs.size,
         position = tabs.position,
      })

      titlebar:setup{layout = wibox.layout.flex.horizontal, flexlist}
      awful.titlebar(c, {size=8, position = "top"})
      awful.titlebar(c, {size=0, position = "left"})
      awful.titlebar(c, {size=0, position = "right"})
   end
end

function resize_region(region_ix, geom, reset)
   local tablist = get_tiled_clients(region_ix)
   for c_ix, c in ipairs(tablist) do
      if reset == true then 
         reset_client_meta(c) 
      else
         c.maximized_horizontal = reset.horizontal
         c.maximized_vertical = reset.vertical
         c.direction = reset.direction
      end
      c:geometry(geom)
   end
end

local function teleport_client(c)
   -- todo: need to recalculate tabs and also update c.region
   local cl = c or client.focus
   if not cl then return true end


   local is = {
      region=cl.region or get_client_info(c).active_region,
      geom=cl:geometry(),
      screen=cl.screen.index
   }

   if not cl.floating then
      cl:geometry({width=300, height=300})
   end --|to avoid machi's auto expansion


   cl:move_to_screen()
   local new_region = get_client_info(c).active_region

   if not new_region then
      c.region = nil
   end

   gears.timer.delayed_call(function (cl) 
      
      -- clear_tabbar(cl)
      cl:emit_signal("request::activate", "mouse_enter",{raise = true})
      cl:emit_signal("draw_tabbar", new_region)
   end,cl)
end

------------------------------------------------------ signal helpers -- ;

local function manage_signal(c)
   if c then
      global_client_table[c.window] = c
      --|add window.id to global index

      local active_region = get_client_info(c).active_region
      if active_region then
         c.region = active_region
         draw_tabbar(active_region)
      end --|in case new client appears tiled
          --|we must update the regions tabbars.
   end
end

local function unmanage_signal(c)
   if c then
      global_client_table[c.window] = nil
      --|remove window.id to global index

      if not c.floating then
         local active_region = get_client_info(c).active_region
         if active_region then 
            draw_tabbar(active_region) end
      end
   end
end

local function selected_tag_signal(t)
   gears.timer.delayed_call(function() 
      local regions = get_regions()
         if regions and #regions then
            for i, region in ipairs(regions) do
               draw_tabbar(i)
            end
         end
   end)
end

local function floating_signal(c)
   if c.floating then
      if c.region then
         gears.timer.delayed_call(function(active_region)
            clear_tabbar(c)
            draw_tabbar(c.region)
         end, active_region)
      end
   end --|window became floating

   if not c.floating then
      local active_region = get_client_info(c).active_region
      if active_region then
         c.region = active_region
         gears.timer.delayed_call(function(active_region)
            draw_tabbar(active_region)   
         end, active_region)
      end
   end --|window became tiled
end


--------------------------------------------------------------- signals -- ;

client.connect_signal("property::minimized", function(c)
   if c.minimized then unmanage_signal(c) end
   if not c.minimized then manage_signal(c) end 
end)
--[[+] manage minimized and not minimized ]]

client.connect_signal("property::floating", floating_signal)
--[[+]
   when windows switch between float and tiled we must
   perform necessary maintenance on the destination and
   source regions. a delayed call was necessary when
   clients become tiled to give awm enough time to draw the
   widgets properly.]]

client.connect_signal("tabbar_draw", draw_tabbar)
--[[+] experimental signalling ]]

-- client:connect_signal("property::name", function(c)
--    if widget_ix[c.window] then
--       local widget = widget_ix[c.window]:get_children_by_id(c.window)

--       text_temp.markup = "<span foreground='" .. fg_temp .. "'>" .. title_temp.. "</span>"
--    end
-- end)


client.connect_signal("unmanage", unmanage_signal) 
--[[+]
   when removing a tiled client we must update the tabbars
   of others. floating clients do not require any cleanup. ]]

client.connect_signal("manage", manage_signal)
--[[+]
   global_client_table is the milestone the tabbars rely on.
   whenever a new client appears we must add to it, and
   when a client is killed we must make sure it is removed. ]]

tag.connect_signal("property::selected", selected_tag_signal)
--[[+]
   property::selected gets called the last, by the time we
   are here, we already have the global_client_list to draw
   tabbars. This may appear redundant here, but it's good
   to have this fire up in case the user switches tags. ]]

--------------------------------------------------------------- exports -- ;

module = {
   focus_by_direction = focus_by_direction,
   get_active_regions = get_client_info,
   shift_by_direction = shift_by_direction,
   expand_horizontal = expand_horizontal,
   shuffle = shuffle,
   old_shuffle = old_shuffle,
   my_shifter = my_shifter,
   expand_vertical = expand_vertical,
   move_to = move_to,
   get_regions = get_regions,
   toggle_always_on = toggle_always_on,
   draw_tabbar = draw_tabbar,
   get_global_clients = get_global_clients,
   update_global_clients = update_global_clients,
   get_client_info = get_client_info,
   teleport_client = teleport_client,
}

return module



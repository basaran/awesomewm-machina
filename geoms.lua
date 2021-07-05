local geoms = {}

geoms.crt43 = function ()
   return {
      x=awful.screen.focused().workarea.width - client.focus:geometry().width,
      y=awful.screen.focused().workarea.height - client.focus:geometry().height + awful.screen.focused().workarea.y,
      width=1280,
      height=1024
   }
end --|awful.screen.focused().workarea.y is required for
    --|multiple monitors to relocate properly.

geoms.p1080 = function ()
   return {
      x=awful.screen.focused().workarea.width - client.focus:geometry().width,
      y=awful.screen.focused().workarea.height - client.focus:geometry().height  + awful.screen.focused().workarea.y,
      width=awful.screen.focused().workarea.width * 0.65,
      height=awful.screen.focused().workarea.height * 0.90
   }
end

geoms.p720 = function ()
   return {
      x=awful.screen.focused().workarea.width - client.focus:geometry().width,
      y=awful.screen.focused().workarea.height - client.focus:geometry().height  + awful.screen.focused().workarea.y,
      width=awful.screen.focused().workarea.width * 0.40,
      height=awful.screen.focused().workarea.height * 0.45
   }
end

geoms["center"] = function(useless_gap)
   return {
      x=awful.screen.focused().workarea.width/2 - client.focus.width/2,
      y=awful.screen.focused().workarea.height/2 - client.focus.height/2  + awful.screen.focused().workarea.y
   }
end

geoms["top-left"] = function(useless_gap)
   return {
      x=useless_gap,
      y=useless_gap + awful.screen.focused().workarea.y
   }
end

geoms["bottom-left"] = function(useless_gap)
   return {
      x=useless_gap,
      y=awful.screen.focused().workarea.height - useless_gap - client.focus.height  + awful.screen.focused().workarea.y
   }
end

geoms["top-right"] = function(useless_gap)
   return {
      x=awful.screen.focused().workarea.width - useless_gap - client.focus.width,
      y=useless_gap + awful.screen.focused().workarea.y
   }
end

geoms["bottom-right"] = function(useless_gap)
   return {
      x=awful.screen.focused().workarea.width - useless_gap - client.focus.width,
      y=awful.screen.focused().workarea.height - useless_gap - client.focus.height + awful.screen.focused().workarea.y
   }
end

geoms.clients = {
   Subl=geoms.p1080,
   Byobu=geoms.p720,
   Krom=geoms.crt43,
}

return geoms
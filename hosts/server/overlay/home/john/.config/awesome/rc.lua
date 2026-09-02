-- Custom awesome config, ported from the operator's Hyprland config
-- (previously ~/.config/hypr/hyprland.lua, see git history) after
-- abandoning Hyprland/Wayland for the NVIDIA 470.xx proprietary
-- driver's VDPAU decode (EGLStreams-only, incompatible with
-- Hyprland/aquamarine). See AWESOME-X11-PLAN.md for the full story.
--
-- This is a port of the *spirit* of the old bindings, not a line-by-
-- line translation -- awesome's model (tags, index/direction-based
-- tiling, master-width-factor resize) differs structurally from
-- Hyprland's (workspaces, dwindle binary-tree tiling, free-form pixel
-- resize even while tiled). Noted inline wherever the mapping isn't a
-- direct equivalent.

pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")

-- Real bug found and fixed (2026-08-26): naughty's own dbus submodule
-- (naughty/dbus.lua) claims org.freedesktop.Notifications synchronously
-- as a side effect of the require above (a bare `dbus.request_name`
-- call baked into that module's top level) -- effectively instant, so
-- it always wins the race against dunst (spawned in the Autostart
-- block below), no matter how early dunst is launched: dunst is slower
-- to initialize (fork, GTK/glib, X connection, config parse) than
-- naughty is to claim the name during its own require. First attempt
-- at fixing this started dunst before awesome, from .xinitrc -- did
-- not work, confirmed live via dbus-send GetConnectionUnixProcessID
-- (still owned by awesome's PID). Also confirmed dunst does NOT queue
-- for the name if its initial request loses -- it just gives up, so
-- releasing the name later/asynchronously doesn't help either.
-- Releasing it here, deterministically before dunst is spawned later
-- in this same file, is the only ordering that actually works.
dbus.release_name("session", "org.freedesktop.Notifications")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Theme
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- Closest native equivalent to Hyprland's gaps_in/gaps_out -- awesome's
-- own gap support, not a hack. useless_gap applies uniformly to both
-- inter-client gaps and the outer screen-edge margin (no separate
-- awful.screen.padding is set here), matching Hyprland's gaps_in and
-- gaps_out both scaling together. Bumped 5 -> 8 (~50% more) to match
-- the gap size on the operator's other Hyprland machines.
beautiful.useless_gap = 8
beautiful.border_width = 3
beautiful.border_normal = "#595959aa"
beautiful.border_focus = "#33ccffee"

-- }}}

-- {{{ Variable definitions
terminal = "alacritty"
browser = "firefox"
launcher = "rofi -show drun"
modkey = "Mod4"

-- dwindle (binary space partitioning) is the closest built-in layout
-- to Hyprland's own dwindle layout -- kept first/default to match.
awful.layout.layouts = {
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}
-- }}}

-- {{{ Screens / tags
-- No wibar/taglist/tasklist/systray widgets -- deliberately not built,
-- matching the operator's explicit "no waybar" instruction from the
-- Hyprland setup. Tag *creation* is NOT optional, though -- it's what
-- actually assigns new clients to a viewable workspace at all. Real
-- bug found and fixed here (2026-08-26): the stock awesome rc.lua
-- bundles tag creation inside the same connect_for_each_screen
-- function as the wibar setup; stripping that whole block for "no
-- wibar" silently took the tag creation with it. Without any tags
-- existing, every new client had an empty tag list (confirmed live
-- via awesome-client: `c:tags()` returned nothing for three spawned
-- alacritty windows) -- they were real, managed, running clients that
-- were simply never assigned anywhere visible. Also silently broke
-- the SUPER+1-9 tag-switching keybindings the same way (screen.tags[i]
-- was always nil).
awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Directional focus/swap helpers
-- awesome 4.3 has awful.client.focus.bydirection built in (matches
-- Hyprland's arrow-key focus semantics directly). There's no built-in
-- directional *swap* -- implemented here by finding the client in that
-- direction the same way focus does, then swapping with it.
local function focused_or_nil()
    return client.focus
end

local function swap_bydirection(dir)
    local c = focused_or_nil()
    if not c then return end
    awful.client.focus.bydirection(dir, c)
    if client.focus and client.focus ~= c then
        c:swap(client.focus)
        client.focus = c
    end
end
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey }, "q", function () if client.focus then client.focus:kill() end end,
              {description = "close focused window", group = "client"}),
    awful.key({ modkey }, "m", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey }, "v", function ()
        if client.focus then
            client.focus.floating = not client.focus.floating
        end
    end, {description = "toggle floating", group = "client"}),
    awful.key({ modkey }, "d", function () awful.spawn(launcher) end,
              {description = "app launcher", group = "launcher"}),
    awful.key({ modkey }, "space", function () awful.layout.inc(1) end,
              {description = "cycle layout (closest equivalent to Hyprland's togglesplit)", group = "layout"}),
    awful.key({ modkey }, "f", function ()
        if client.focus then
            client.focus.fullscreen = not client.focus.fullscreen
            client.focus:raise()
        end
    end, {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift" }, "b", function () awful.spawn(browser) end,
              {description = "launch firefox", group = "launcher"}),

    -- Focus (directional, matches Hyprland's arrow-key bindings)
    awful.key({ modkey }, "Left",  function () awful.client.focus.bydirection("left")  end,
              {description = "focus left", group = "client"}),
    awful.key({ modkey }, "Right", function () awful.client.focus.bydirection("right") end,
              {description = "focus right", group = "client"}),
    awful.key({ modkey }, "Up",    function () awful.client.focus.bydirection("up")    end,
              {description = "focus up", group = "client"}),
    awful.key({ modkey }, "Down",  function () awful.client.focus.bydirection("down")  end,
              {description = "focus down", group = "client"}),

    -- Swap windows (directional)
    awful.key({ modkey, "Shift" }, "Left",  function () swap_bydirection("left")  end,
              {description = "swap with window to the left", group = "client"}),
    awful.key({ modkey, "Shift" }, "Right", function () swap_bydirection("right") end,
              {description = "swap with window to the right", group = "client"}),
    awful.key({ modkey, "Shift" }, "Up",    function () swap_bydirection("up")    end,
              {description = "swap with window above", group = "client"}),
    awful.key({ modkey, "Shift" }, "Down",  function () swap_bydirection("down")  end,
              {description = "swap with window below", group = "client"}),

    -- Resize -- awesome's tiling model resizes via the layout's master-
    -- width-factor, not per-window pixel drag like Hyprland's; this is
    -- the closest native equivalent, applied in all four directions.
    awful.key({ modkey, "Control" }, "Left",  function () awful.tag.incmwfact(-0.05) end,
              {description = "shrink master width", group = "layout"}),
    awful.key({ modkey, "Control" }, "Right", function () awful.tag.incmwfact( 0.05) end,
              {description = "grow master width", group = "layout"}),
    awful.key({ modkey, "Control" }, "Up",    function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase master count", group = "layout"}),
    awful.key({ modkey, "Control" }, "Down",  function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease master count", group = "layout"}),

    -- Volume (wpctl -- wireplumber's own CLI, already installed and
    -- working with this system's pipewire stack; pamixer, what the
    -- old Hyprland config pointed at, was never actually installed)
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") end,
              {description = "volume up", group = "media"}),
    awful.key({ }, "XF86AudioLowerVolume", function () awful.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") end,
              {description = "volume down", group = "media"}),
    awful.key({ }, "XF86AudioMute", function () awful.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") end,
              {description = "mute toggle", group = "media"}),
    awful.key({ }, "XF86AudioMicMute", function () awful.spawn("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") end,
              {description = "mic mute toggle", group = "media"}),

    -- Screenshots -- ImageMagick's `import`, not maim+slop (see
    -- BUILD-REPORT.md: maim/slop's dependency chain needed glew/glm,
    -- neither built; import covers the same three cases natively).
    awful.key({ modkey }, "Print", function () awful.spawn.with_shell("import -window \"$(xdotool getactivewindow)\" ~/screens/window-$(date +%Y%m%d-%H%M%S).png") end,
              {description = "screenshot focused window", group = "screenshot"}),
    awful.key({ }, "Print", function () awful.spawn.with_shell("import -window root ~/screens/output-$(date +%Y%m%d-%H%M%S).png") end,
              {description = "screenshot full output", group = "screenshot"}),
    awful.key({ modkey, "Shift" }, "Print", function () awful.spawn.with_shell("import ~/screens/region-$(date +%Y%m%d-%H%M%S).png") end,
              {description = "screenshot region (interactive drag)", group = "screenshot"}),

    -- Clipboard history (clipmenu, rofi-driven -- CM_LAUNCHER=rofi set
    -- in the autostart environment below)
    awful.key({ modkey }, "c", function () awful.spawn("clipmenu") end,
              {description = "clipboard history", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey, "Shift" }, "space", awful.client.floating.toggle,
              {description = "toggle floating", group = "client"})
)

-- Workspaces (tags 1-9, matching Hyprland's 1-9 + 0->10 scheme as
-- closely as awesome's 9-tag-by-default convention allows)
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then tag:view_only() end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then client.focus:move_to_tag(tag) end
                      end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    -- SUPER+left-drag / SUPER+right-drag -- matches Hyprland's
    -- mouse:272 (drag) / mouse:273 (resize) bindings.
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },
    -- emacs opacity -- ported directly from the Hyprland window_rule.
    { rule = { class = "Emacs" },
      properties = { opacity = 0.90 } },
}
-- }}}

-- {{{ Signals
client.connect_signal("manage", function (c)
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- }}}

-- {{{ Autostart
-- Matches the Hyprland config's autostart block: redshift (wlsunset's
-- replacement, same fixed lat/long), clipmenud (cliphist's
-- replacement), dunst (mako's replacement). dunst is spawned here,
-- after the dbus.release_name() call near the top of this file, so it
-- always finds the notification name free -- see that comment for why
-- ordering (not just "start dunst first") is what actually matters.
--
-- picom (added 2026-08-27) does rounded corners + shadows + fade now,
-- replacing the client.shape-based rounding this file used to do by
-- hand (removed from the Signals section above) -- that was a hard
-- X11 Shape-extension cutout, no anti-aliasing; picom composites
-- properly. Running both would double-clip against an already
-- nonrectangular window shape, so it's exclusively picom's job now.
awful.spawn.with_shell("redshift -l 35.46:-97.32")
awful.spawn.with_shell("CM_LAUNCHER=rofi clipmenud")
awful.spawn.with_shell("dunst")
awful.spawn.with_shell("picom")
-- }}}

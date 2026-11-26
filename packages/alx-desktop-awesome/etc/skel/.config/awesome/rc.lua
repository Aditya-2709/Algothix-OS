-- Algothix OS (ALX) Lite — Awesome WM Configuration (CHANGE-001)
-- Plain Lua using Awesome 4.3 built-ins only (no extra libraries).
-- Compositor is OFF by default for 2-4 GB RAM / Intel GMA performance.

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")

-- Error handling
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "ALX Awesome startup error",
        text = awesome.startup_errors,
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "ALX Awesome runtime error",
            text = tostring(err),
        })
        in_error = false
    end)
end

-- ALX Palette Tokens (CHANGE-001 / DESIGN.md)
local theme = {
    bg_normal     = "#0B0D10",
    bg_focus      = "#13171D",
    bg_urgent     = "#F85149",
    bg_minimize   = "#0B0D10",
    bg_systray    = "#0B0D10",

    fg_normal     = "#8B949E",
    fg_focus      = "#E6EDF3",
    fg_urgent     = "#0B0D10",
    fg_minimize   = "#484F58",

    useless_gap   = 4,
    border_width  = 2,
    border_normal = "#1F2630",
    border_focus  = "#3DDC97",
    border_marked = "#F85149",

    font          = "JetBrains Mono 9",
    taglist_fg_focus    = "#0B0D10",
    taglist_bg_focus    = "#3DDC97",
    taglist_fg_occupied = "#E6EDF3",
    taglist_bg_occupied = "#13171D",
    taglist_fg_empty    = "#8B949E",
    taglist_bg_empty    = "#0B0D10",
    taglist_fg_urgent   = "#0B0D10",
    taglist_bg_urgent   = "#F85149",

    tasklist_bg_focus   = "#0B0D10",
    tasklist_fg_focus   = "#E6EDF3",
    tasklist_bg_normal  = "#0B0D10",
    tasklist_fg_normal  = "#8B949E",
}
beautiful.init(theme)

local terminal = "urxvt"
local modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.max,
    awful.layout.suit.floating,
}

-- Select best-matching PNG ASCII "ALX" wallpaper for current screen geometry
local function pick_wallpaper(s)
    local g = s.geometry
    local exact = string.format("/usr/share/alx/wallpapers/alx-%dx%d.png", g.width, g.height)
    if gears.filesystem.file_readable(exact) then
        return exact
    end
    local candidates = {
        "/usr/share/alx/wallpapers/alx-1366x768.png",
        "/usr/share/alx/wallpapers/alx-1920x1080.png",
        "/usr/share/alx/wallpapers/alx-1280x720.png",
        "/usr/share/alx/wallpapers/alx-1024x768.png",
    }
    for _, path in ipairs(candidates) do
        if gears.filesystem.file_readable(path) then
            return path
        end
    end
    return nil
end

local function set_wallpaper(s)
    local wp = pick_wallpaper(s)
    if wp then
        gears.wallpaper.maximized(wp, s, false)
    else
        gears.wallpaper.set("#0B0D10")
    end
end

screen.connect_signal("property::geometry", set_wallpaper)

-- Lightweight /proc and /sys wibar widgets (all polling >= 2 seconds)
local sep = wibox.widget.textbox("  |  ")

-- CPU usage from /proc/stat (3s)
local cpu_widget = awful.widget.watch(
    { "sh", "-c", "awk '/^cpu / {u=$2+$4; t=$2+$4+$5; if (t>0) printf \"CPU %d%%\", (u*100)/t}' /proc/stat" },
    3,
    function(widget, stdout)
        widget:set_markup("<span foreground='#8B949E'>" .. gears.string.xml_escape(stdout:gsub("\n", "")) .. "</span>")
    end
)

-- RAM usage from /proc/meminfo (3s)
local ram_widget = awful.widget.watch(
    { "sh", "-c", "awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {if (t>0) printf \"RAM %d/%dM\", (t-a)/1024, t/1024}' /proc/meminfo" },
    3,
    function(widget, stdout)
        widget:set_markup("<span foreground='#E6EDF3'>" .. gears.string.xml_escape(stdout:gsub("\n", "")) .. "</span>")
    end
)

-- Network status from /sys/class/net (5s)
local net_widget = awful.widget.watch(
    { "sh", "-c", "for d in /sys/class/net/*; do i=$(basename \"$d\"); [ \"$i\" = lo ] && continue; [ \"$(cat \"$d/operstate\" 2>/dev/null)\" = up ] && { printf 'NET %s' \"$i\"; exit 0; }; done; printf 'NET down'" },
    5,
    function(widget, stdout)
        local txt = stdout:gsub("\n", "")
        local col = txt:match("down") and "#F85149" or "#3DDC97"
        widget:set_markup("<span foreground='" .. col .. "'>" .. gears.string.xml_escape(txt) .. "</span>")
    end
)

-- Battery status from /sys/class/power_supply (15s)
local bat_widget = awful.widget.watch(
    { "sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && { printf 'BAT %s%%' \"$(cat \"$b/capacity\")\"; exit 0; }; done; printf 'AC'" },
    15,
    function(widget, stdout)
        widget:set_markup("<span foreground='#8B949E'>" .. gears.string.xml_escape(stdout:gsub("\n", "")) .. "</span>")
    end
)

-- ALX Link peer count & mesh state (15s)
local link_widget = awful.widget.watch(
    { "sh", "-c", "p=$(find \"$HOME/.config/alx-link/peers\" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' '); if [ \"$p\" -gt 0 ]; then printf 'LINK %s' \"$p\"; else printf 'LINK 0'; fi" },
    15,
    function(widget, stdout)
        local txt = stdout:gsub("\n", "")
        local col = txt == "LINK 0" and "#8B949E" or "#3DDC97"
        widget:set_markup("<span foreground='" .. col .. "'>" .. gears.string.xml_escape(txt) .. "</span>")
    end
)

local clock_widget = wibox.widget.textclock("<span foreground='#E6EDF3'>%Y-%m-%d %H:%M</span>", 15)

-- Taglist buttons
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end)
)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    -- 5 ALX tags
    awful.tag({ "1:term", "2:code", "3:web", "4:ops", "5:misc" }, s, awful.layout.layouts[1])

    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    })

    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.focused,
    })

    -- 28px top wibar
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = 28,
        bg = "#0B0D10",
        fg = "#E6EDF3",
    })

    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            wibox.widget.textbox("  "),
        },
        s.mytasklist,
        {
            layout = wibox.layout.fixed.horizontal,
            link_widget,
            sep,
            net_widget,
            sep,
            ram_widget,
            sep,
            cpu_widget,
            sep,
            bat_widget,
            sep,
            clock_widget,
            wibox.widget.textbox(" "),
            wibox.widget.systray(),
        },
    })
end)

-- Global keybindings (ported from ALX-i3)
local globalkeys = gears.table.join(
    awful.key({ modkey }, "Return", function() awful.spawn(terminal) end, { description = "open terminal", group = "launcher" }),
    awful.key({ modkey }, "d", function() awful.spawn("rofi -show drun") end, { description = "app launcher (rofi)", group = "launcher" }),
    awful.key({ modkey }, "e", function() awful.spawn("pcmanfm") end, { description = "file manager", group = "launcher" }),
    awful.key({ modkey, "Shift" }, "slash", function() awful.spawn("alx-cheatsheet") end, { description = "keybinding cheat-sheet", group = "launcher" }),

    -- Focus navigation (Vim keys + arrows)
    awful.key({ modkey }, "h", function() awful.client.focus.bydirection("left") end, { description = "focus left", group = "client" }),
    awful.key({ modkey }, "j", function() awful.client.focus.bydirection("down") end, { description = "focus down", group = "client" }),
    awful.key({ modkey }, "k", function() awful.client.focus.bydirection("up") end, { description = "focus up", group = "client" }),
    awful.key({ modkey }, "l", function() awful.client.focus.bydirection("right") end, { description = "focus right", group = "client" }),
    awful.key({ modkey }, "Left", function() awful.client.focus.bydirection("left") end, { description = "focus left", group = "client" }),
    awful.key({ modkey }, "Down", function() awful.client.focus.bydirection("down") end, { description = "focus down", group = "client" }),
    awful.key({ modkey }, "Up", function() awful.client.focus.bydirection("up") end, { description = "focus up", group = "client" }),
    awful.key({ modkey }, "Right", function() awful.client.focus.bydirection("right") end, { description = "focus right", group = "client" }),

    -- Swap windows
    awful.key({ modkey, "Shift" }, "h", function() awful.client.swap.bydirection("left") end, { description = "swap left", group = "client" }),
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.bydirection("down") end, { description = "swap down", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.bydirection("up") end, { description = "swap up", group = "client" }),
    awful.key({ modkey, "Shift" }, "l", function() awful.client.swap.bydirection("right") end, { description = "swap right", group = "client" }),

    -- Layout & master width
    awful.key({ modkey }, "space", function() awful.layout.inc(1) end, { description = "next layout", group = "layout" }),
    awful.key({ modkey }, "t", function() awful.layout.inc(1) end, { description = "toggle layout", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incmwfact(0.05) end, { description = "increase master width", group = "layout" }),
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incmwfact(-0.05) end, { description = "decrease master width", group = "layout" }),

    -- Session control
    awful.key({ modkey, "Shift" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "e", awesome.quit, { description = "quit awesome", group = "awesome" })
)

local clientkeys = gears.table.join(
    awful.key({ modkey, "Shift" }, "q", function(c) c:kill() end, { description = "close window", group = "client" }),
    awful.key({ modkey }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "space", awful.client.floating.toggle, { description = "toggle floating", group = "client" })
)

-- Bind tags 1..5
for i = 1, 5 do
    globalkeys = gears.table.join(
        globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then tag:view_only() end
        end, { description = "view tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end, { description = "move focused window to tag #" .. i, group = "tag" })
    )
end

local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate", "mouse_click", { raise = true }) end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

root.keys(globalkeys)

-- Window rules
awful.rules.rules = {
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
    },
    {
        rule = { name = "ALX Keybindings" },
        properties = {
            floating = true,
            width = 760,
            height = 520,
            placement = awful.placement.centered,
        },
    },
}

client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Autostart (no compositor by default)
awful.spawn.with_shell("xrdb -merge ~/.Xresources")
awful.spawn.once("dunst")
awful.spawn.once("nm-applet")

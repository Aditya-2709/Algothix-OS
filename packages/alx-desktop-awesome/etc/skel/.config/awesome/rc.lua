-- Algothix OS (ALX) Lite — Awesome WM Configuration (v1.2)
-- Pure Lua using Awesome 4.3 built-ins only (no extra libraries).
-- Features: 28px top bar, 42px bottom dock, window titlebars (min/max/close),
-- desktop icons via pcmanfm --desktop, and Black Hole default wallpaper.

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")

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

-- Exact DESIGN.md Section 4.1 & Section 6 tokens
local theme = {
    bg_normal     = "#12161B",
    bg_focus      = "#1A1F26",
    bg_urgent     = "#F26B6B",
    bg_minimize   = "#0B0D10",
    bg_systray    = "#12161B",

    fg_normal     = "#8A94A3",
    fg_focus      = "#E6EAF0",
    fg_urgent     = "#06130D",
    fg_minimize   = "#566070",

    useless_gap   = 8,
    border_width  = 2,
    border_normal = "#374150",
    border_focus  = "#3DDC97",
    border_marked = "#F26B6B",

    font          = "JetBrains Mono 9",
    taglist_fg_focus    = "#06130D",
    taglist_bg_focus    = "#3DDC97",
    taglist_fg_occupied = "#E6EAF0",
    taglist_bg_occupied = "#12161B",
    taglist_fg_empty    = "#566070",
    taglist_bg_empty    = "#12161B",
    taglist_fg_urgent   = "#06130D",
    taglist_bg_urgent   = "#F26B6B",

    tasklist_bg_focus   = "#1A1F26",
    tasklist_fg_focus   = "#E6EAF0",
    tasklist_bg_normal  = "#12161B",
    tasklist_fg_normal  = "#8A94A3",
    tasklist_bg_minimize = "#0B0D10",
    tasklist_fg_minimize = "#566070",

    titlebar_bg_focus   = "#12161B",
    titlebar_fg_focus   = "#E6EAF0",
    titlebar_bg_normal  = "#0B0D10",
    titlebar_fg_normal  = "#8A94A3",
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

-- Select best-matching Black Hole PNG wallpaper
local function pick_wallpaper(s)
    local g = s.geometry
    local exact = string.format("/usr/share/backgrounds/alx/alx-%dx%d.png", g.width, g.height)
    if gears.filesystem.file_readable(exact) then
        return exact
    end
    local candidates = {
        "/usr/share/backgrounds/alx/alx-1366x768.png",
        "/usr/share/backgrounds/alx/alx-1920x1080.png",
        "/usr/share/backgrounds/alx/alx-1280x720.png",
        "/usr/share/backgrounds/alx/alx-1024x768.png",
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
        gears.wallpaper.set("#000000")
    end
end

screen.connect_signal("property::geometry", set_wallpaper)

-- Helper: clickable pill button for the bottom dock
local function dock_button(label, cmd, accent)
    local fg_default = accent and "#06130D" or "#E6EAF0"
    local bg_default = accent and "#3DDC97" or "#1A1F26"
    local bg_hover   = accent and "#5BE8AB" or "#222831"
    local bd_default = accent and "#3DDC97" or "#262C35"

    local btn = wibox.widget({
        {
            {
                text = label,
                font = "JetBrains Mono Bold 9",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            left = 12,
            right = 12,
            top = 5,
            bottom = 5,
            widget = wibox.container.margin,
        },
        bg = bg_default,
        fg = fg_default,
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 6) end,
        shape_border_width = 1,
        shape_border_color = bd_default,
        widget = wibox.container.background,
    })

    btn:connect_signal("mouse::enter", function()
        btn.bg = bg_hover
        if not accent then btn.shape_border_color = "#3DDC97" end
    end)
    btn:connect_signal("mouse::leave", function()
        btn.bg = bg_default
        btn.shape_border_color = bd_default
    end)
    btn:buttons(gears.table.join(
        awful.button({}, 1, function() awful.spawn(cmd) end)
    ))
    return btn
end

-- Helper: crisp text titlebar button (Minimize / Maximize / Close)
local function titlebar_btn(symbol, fg_col, hover_bg, action)
    local b = wibox.widget({
        {
            {
                text = symbol,
                font = "JetBrains Mono Bold 10",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            left = 8,
            right = 8,
            widget = wibox.container.margin,
        },
        bg = "#12161B",
        fg = fg_col,
        widget = wibox.container.background,
    })
    b:connect_signal("mouse::enter", function() b.bg = hover_bg end)
    b:connect_signal("mouse::leave", function() b.bg = "#12161B" end)
    b:buttons(gears.table.join(awful.button({}, 1, action)))
    return b
end

-- Lightweight /proc and /sys top-bar widgets (polling >= 2s)
local sep = wibox.widget.textbox("  ·  ")

local ram_widget = awful.widget.watch(
    { "sh", "-c", "awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {if (t>0) printf \"RAM %dM\", (t-a)/1024}' /proc/meminfo" },
    3,
    function(widget, stdout)
        widget:set_markup("<span foreground='#E6EAF0'>" .. gears.string.xml_escape(stdout:gsub("\n", "")) .. "</span>")
    end
)

local cpu_widget = awful.widget.watch(
    { "sh", "-c", "awk '/^cpu / {u=$2+$4; t=$2+$4+$5; if (t>0) printf \"CPU %d%%\", (u*100)/t}' /proc/stat" },
    3,
    function(widget, stdout)
        widget:set_markup("<span foreground='#8A94A3'>" .. gears.string.xml_escape(stdout:gsub("\n", "")) .. "</span>")
    end
)

local net_widget = awful.widget.watch(
    { "sh", "-c", "for d in /sys/class/net/*; do i=$(basename \"$d\"); [ \"$i\" = lo ] && continue; [ \"$(cat \"$d/operstate\" 2>/dev/null)\" = up ] && { printf 'NET %s' \"$i\"; exit 0; }; done; printf 'NET down'" },
    5,
    function(widget, stdout)
        local txt = stdout:gsub("\n", "")
        local col = txt:match("down") and "#F26B6B" or "#3DDC97"
        widget:set_markup("<span foreground='" .. col .. "'>" .. gears.string.xml_escape(txt) .. "</span>")
    end
)

local bat_widget = awful.widget.watch(
    { "sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && { printf 'BAT %s%%' \"$(cat \"$b/capacity\")\"; exit 0; }; done; printf 'AC'" },
    15,
    function(widget, stdout)
        widget:set_markup("<span foreground='#8A94A3'>" .. gears.string.xml_escape(stdout:gsub("\n", "")) .. "</span>")
    end
)

local link_widget = awful.widget.watch(
    { "sh", "-c", "p=$(find \"$HOME/.config/alx-link/peers\" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' '); if [ \"$p\" -gt 0 ]; then printf 'ALX Link %s' \"$p\"; else printf 'ALX Link 0'; fi" },
    15,
    function(widget, stdout)
        local txt = stdout:gsub("\n", "")
        local col = txt == "ALX Link 0" and "#566070" or "#3DDC97"
        widget:set_markup("<span foreground='" .. col .. "'>" .. gears.string.xml_escape(txt) .. "</span>")
    end
)

local clock_widget = wibox.widget.textclock("<span foreground='#E6EAF0'>%a %d %b %H:%M</span>", 15)

local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end)
)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag({ "1:term", "2:code", "3:web", "4:ops", "5:misc" }, s, awful.layout.layouts[1])

    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    })

    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
    })

    -- 28px top bar
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = 28,
        bg = "#12161B",
        fg = "#E6EAF0",
        border_width = 1,
        border_color = "#262C35",
    })

    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.textbox(" [ALX] "),
            s.mytaglist,
            wibox.widget.textbox("  "),
        },
        s.mytasklist,
        {
            layout = wibox.layout.fixed.horizontal,
            ram_widget,
            sep,
            cpu_widget,
            sep,
            net_widget,
            sep,
            bat_widget,
            sep,
            link_widget,
            sep,
            clock_widget,
            wibox.widget.textbox(" "),
            wibox.widget.systray(),
        },
    })

    -- 42px bottom navigation dock
    s.mydock = awful.wibar({
        position = "bottom",
        screen = s,
        height = 42,
        bg = "#12161B",
        fg = "#E6EAF0",
        border_width = 1,
        border_color = "#262C35",
    })

    s.mydock:setup({
        layout = wibox.layout.align.horizontal,
        expand = "none",
        nil,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = 10,
            dock_button("Apps", "rofi -show drun", true),
            dock_button("Terminal", terminal, false),
            dock_button("Brave", "brave-browser", false),
            dock_button("VS Code", "code", false),
            dock_button("Files", "pcmanfm", false),
            dock_button("Install ALX", "/usr/sbin/alx-calamares-launch", false),
            dock_button("Help", "alx-cheatsheet", false),
        },
        nil,
    })
end)

local globalkeys = gears.table.join(
    awful.key({ modkey }, "Return", function() awful.spawn(terminal) end, { description = "open terminal", group = "launcher" }),
    awful.key({ modkey }, "d", function() awful.spawn("rofi -show drun") end, { description = "app launcher (rofi)", group = "launcher" }),
    awful.key({ modkey }, "e", function() awful.spawn("pcmanfm") end, { description = "file manager", group = "launcher" }),
    awful.key({ modkey, "Shift" }, "slash", function() awful.spawn("alx-cheatsheet") end, { description = "keybinding cheat-sheet", group = "launcher" }),

    awful.key({ modkey }, "h", function() awful.client.focus.bydirection("left") end, { description = "focus left", group = "client" }),
    awful.key({ modkey }, "j", function() awful.client.focus.bydirection("down") end, { description = "focus down", group = "client" }),
    awful.key({ modkey }, "k", function() awful.client.focus.bydirection("up") end, { description = "focus up", group = "client" }),
    awful.key({ modkey }, "l", function() awful.client.focus.bydirection("right") end, { description = "focus right", group = "client" }),
    awful.key({ modkey }, "Left", function() awful.client.focus.bydirection("left") end, { description = "focus left", group = "client" }),
    awful.key({ modkey }, "Down", function() awful.client.focus.bydirection("down") end, { description = "focus down", group = "client" }),
    awful.key({ modkey }, "Up", function() awful.client.focus.bydirection("up") end, { description = "focus up", group = "client" }),
    awful.key({ modkey }, "Right", function() awful.client.focus.bydirection("right") end, { description = "focus right", group = "client" }),

    awful.key({ modkey, "Shift" }, "h", function() awful.client.swap.bydirection("left") end, { description = "swap left", group = "client" }),
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.bydirection("down") end, { description = "swap down", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.bydirection("up") end, { description = "swap up", group = "client" }),
    awful.key({ modkey, "Shift" }, "l", function() awful.client.swap.bydirection("right") end, { description = "swap right", group = "client" }),

    awful.key({ modkey }, "space", function() awful.layout.inc(1) end, { description = "next layout", group = "layout" }),
    awful.key({ modkey }, "t", function() awful.layout.inc(1) end, { description = "toggle layout", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incmwfact(0.05) end, { description = "increase master width", group = "layout" }),
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incmwfact(-0.05) end, { description = "decrease master width", group = "layout" }),

    awful.key({ modkey, "Shift" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "e", awesome.quit, { description = "quit awesome", group = "awesome" })
)

local clientkeys = gears.table.join(
    awful.key({ modkey, "Shift" }, "q", function(c) c:kill() end, { description = "close window", group = "client" }),
    awful.key({ modkey }, "n", function(c) c.minimized = true end, { description = "minimize window", group = "client" }),
    awful.key({ modkey }, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, { description = "maximize window", group = "client" }),
    awful.key({ modkey }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "space", awful.client.floating.toggle, { description = "toggle floating", group = "client" })
)

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
            titlebars_enabled = true,
        },
    },
    {
        -- Keep pcmanfm --desktop borderless, titlebar-free, and below all windows
        rule_any = { type = { "desktop" } },
        properties = {
            titlebars_enabled = false,
            border_width = 0,
            sticky = true,
            below = true,
            focusable = false,
            skip_taskbar = true,
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

-- Window titlebar with clickable Minimize (_), Maximize ([]), and Close (x)
client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, { size = 26, bg_normal = "#0B0D10", bg_focus = "#12161B" }):setup({
        {
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal,
        },
        {
            {
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c),
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal,
        },
        {
            titlebar_btn("_", "#8A94A3", "#222831", function() c.minimized = true end),
            titlebar_btn("[]", "#3DDC97", "#222831", function()
                c.maximized = not c.maximized
                c:raise()
            end),
            titlebar_btn("x", "#F26B6B", "#3A1B1E", function() c:kill() end),
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    })
end)

client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

awful.spawn.with_shell("xrdb -merge ~/.Xresources")
awful.spawn.once("dunst")
awful.spawn.once("nm-applet")
awful.spawn.once("pcmanfm --desktop")

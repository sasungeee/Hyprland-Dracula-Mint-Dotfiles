
-- Monitors -----------------

hl.monitor({
    output   = "DP-1",
    mode     = "1920x1080@143.98",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "DVI-D-1",
    mode     = "1280x1024@76.00",
    position = "1920x0",
    scale    = "1",
})


-- Workspaces -----------------

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "DP-1" })
hl.workspace_rule({ workspace = "7", monitor = "DP-1" })

hl.workspace_rule({ workspace = "8", monitor = "DVI-D-1" })
hl.workspace_rule({ workspace = "9", monitor = "DVI-D-1" })
hl.workspace_rule({ workspace = "10", monitor = "DVI-D-1" })


-- Programs -----------------

local terminal    = "foot"
local fileManager = "nemo"
local menu        = "rofi -show drun -theme ~/.config/rofi/launchers/type-7/style-2.rasi"


-- Autostart -----------------

hl.on("hyprland.start", function () 

  hl.exec_cmd("wlsunset -t 3500 -T 3501")
  hl.exec_cmd("mako")
  hl.exec_cmd("swayosd-server")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")

  hl.exec_cmd("swaybg -i ~/.config/bgimages/BG.jpg")

  hl.exec_cmd("Telegram")
  hl.exec_cmd("discord")
  hl.exec_cmd("firefox")

  hl.exec_cmd("waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css")
  hl.exec_cmd("waybar --config ~/.config/waybar/config-second.jsonc --style ~/.config/waybar/style.css")

  hl.exec_cmd("feishin")

end)


-- Environment Variables -----------------

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "21")
hl.env("HYPRCURSOR_SIZE", "21")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")


-- General Options -----------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border   = "rgba(25a487ff)",
            inactive_border = "rgba(1e1f29ff)",
        },

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {

        rounding       = 5,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {

            enabled      = false,

        },

        blur = {

            enabled = true,
            size = 3,
            passes = 1,

            vibrancy = 0.1696,

        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        force_split = 2,
        smart_split = false,
    },

    misc = {

        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        middle_click_paste = false,
        
    },

    input = {
        kb_layout  = "us,ru,ua",
        -- kb_variant = "",
        -- kb_model   = "",
        kb_options = "grp:win_space_toggle",
        -- kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },

    cursor = {
        no_warps = true,
        no_hardware_cursors = 1,
    }
})

-- Animations -----------------

hl.curve("myBezier",   { type = "bezier", points = {{0.33, 0}, {0.25, 1}}})

hl.animation({ leaf = "global",        enabled = true,  speed = 1, bezier = "myBezier" })
hl.animation({ leaf = "border",        enabled = true,  speed = 1, bezier = "myBezier" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 1, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 1, bezier = "myBezier" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1, bezier = "myBezier" })


-- Keybindings -----------------

local mainMod = "SUPER"

-- exec programs
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu))

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("~/.config/hypr/show_layout_popup.sh"))

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -n"))

hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd('rofi -modi emoji -show emoji -kb-secondary-copy "" -kb-custom-1 Ctrl+c -theme ~/.config/rofi/launchers/type-7/style-2.rasi'))
hl.bind("ALT + F4", hl.dsp.exec_cmd("~/.config/rofi/rofi-power-menu-alt-f4.sh"))
hl.bind("ALT + 4", hl.dsp.exec_cmd("~/.config/rofi/rofi-power-menu-alt-f4.sh"))

hl.bind("Caps_Lock", hl.dsp.exec_cmd("swayosd-client --caps-lock"), { release = true, ignore_mods = true })

hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd('hyprctl clients | grep "title:" > /home/user/a.txt'))

-- screenshots
hl.bind("Print", hl.dsp.exec_cmd("flameshot gui"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

-- hyprland

hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("playerctl --all-players pause & pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

local function reloadWaybar()
    hl.dispatch(hl.dsp.exec_cmd("pkill waybar"))
    hl.dispatch(hl.dsp.exec_cmd("waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css &"))
    hl.dispatch(hl.dsp.exec_cmd("waybar --config ~/.config/waybar/config-second.jsonc --style ~/.config/waybar/style.css &"))
end

hl.bind(mainMod .. " + SHIFT + Y", reloadWaybar)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch & Move window to workspace
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Move/resize windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise --max-volume 100"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower --max-volume 100"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("playerctl --all-players pause"), { locked = true, repeating = true })


-- Windowrules -----------------

-- Gamescope
hl.window_rule({
    name = "windowrule-1",
    match = { class = "gamescope" },
    fullscreen = true
})

-- GSimpleCal
hl.window_rule({
    name = "windowrule-2",
    match = { class = "gsimplecal" },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    size = "350 240",
    move = "((monitor_w*1)-410) 42"
})

-- yad (layout osd)
hl.window_rule({
    name = "windowrule-3",
    match = { class = "yad" },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    no_follow_mouse = true,
    border_color = "rgb(25a487) rgb(25a487)",
    border_size = 1
})

-- Hyprland Share Picker
hl.window_rule({
    name = "windowrule-4",
    match = { class = "hyprland-share-picker" },
    center = true,
    float = true
})

-- Viber Messages
hl.window_rule({
    name = "windowrule-5",
    match = { title = "ViberPC" },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    size = "300 100",
    move = "((monitor_w*1)-310) ((monitor_h*1)-110)"
})

-- Flameshot
hl.window_rule({
    name = "windowrule-6",
    match = { 
        class = "flameshot",
        title = "flameshot"
    },
    move = "0 0",
    pin = true,
    fullscreen = true,
    float = true,
    no_anim = true
})

-- Pavucontrol
hl.window_rule({
    name = "windowrule-7",
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    size = "625 450",
    move = "((monitor_w*1)-645) 42"
})

-- Pwvucontrol
hl.window_rule({
    name = "windowrule-8",
    match = { class = "com.saivert.pwvucontrol" },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    size = "700 450",
    move = "((monitor_w*1)-750) 42"
})

-- Standart Hyprland Windowrules
hl.window_rule({
    name = "windowrule-9",
    match = { class = ".*" },
    suppress_event = "maximize"
})

hl.window_rule({
    name = "windowrule-10",
    match = { 
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false
    },
    no_focus = true
})

-- Program On Special Workspace
hl.window_rule({
    name = "windowrule-11",
    match = { class = "librewolf" },
    workspace = 8
})

hl.window_rule({
    name = "windowrule-12",
    match = { class = "firefox" },
    workspace = 8
})

hl.window_rule({
    name = "windowrule-13",
    match = { class = "vivaldi-stable" },
    workspace = 8
})

hl.window_rule({
    name = "windowrule-14",
    match = { class = "org.telegram.desktop" },
    workspace = 9
})

hl.window_rule({
    name = "windowrule-15",
    match = { class = "discord" },
    workspace = 9
})

hl.window_rule({
    name = "windowrule-16",
    match = { class = "feishin" },
    workspace = 10
})

-- ZOOM annotate
hl.window_rule({
    name = "windowrule-17",
    match = { title = "annotate_toolbar" },
    float = true,
    no_anim = true,
    no_initial_focus = true,
    size = "50 50",
    move = "35 ((monitor_h * 1) - 145)"
})



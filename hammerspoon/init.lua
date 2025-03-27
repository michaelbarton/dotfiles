-- Hammerspoon configuration

local MONITORS = {
    MAIN = "DELL U3421WE",
    SECONDARY = "27GL850"
}

local LAYOUT_POSITIONS = {
    LEFT_THIRD = {x = 0, y = 0, w = 0.33, h = 1},
    RIGHT_TWO_THIRDS = {x = 0.33, y = 0, w = 0.67, h = 1},
    TOP_THIRD = {x = 0, y = 0, w = 1, h = 0.33},
    MIDDLE_THIRD = {x = 0, y = 0.33, w = 1, h = 0.33},
    BOTTOM_THIRD = {x = 0, y = 0.67, w = 1, h = 0.33}
}

local APPS = {
    CURSOR = "Cursor",
    TERMINAL = "Ghostty",
    SLACK = "Slack",
    CHROME = "Google Chrome",
    SPOTIFY = "Spotify"
}

local WINDOW_LAYOUT = {
    {APPS.CURSOR, nil, MONITORS.MAIN, LAYOUT_POSITIONS.LEFT_THIRD, nil, nil},
    {APPS.TERMINAL, nil, MONITORS.MAIN, LAYOUT_POSITIONS.RIGHT_TWO_THIRDS, nil, nil},
    {APPS.SLACK, nil, MONITORS.SECONDARY, LAYOUT_POSITIONS.TOP_THIRD, nil, nil},
    {APPS.CHROME, nil, MONITORS.SECONDARY, LAYOUT_POSITIONS.MIDDLE_THIRD, nil, nil},
    {APPS.SPOTIFY, nil, MONITORS.SECONDARY, LAYOUT_POSITIONS.BOTTOM_THIRD, nil, nil}
}

local menubar = hs.menubar.new()

local function setupMenubar()
    menubar:setTitle("🖥")
    menubar:setTooltip("Window Layout Manager")
    menubar:setMenu({
        {
            title = "Launch & Arrange Apps",
            fn = function()
                for _, appName in pairs(APPS) do
                    hs.application.launchOrFocus(appName)
                end
                hs.layout.apply(WINDOW_LAYOUT)
            end
        }
    })
end

setupMenubar()


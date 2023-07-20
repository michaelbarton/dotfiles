local mainMonitor = "DELL U3421WE"  -- replace with the name of your main monitor
local secondMonitor = "27GL850"  -- replace with the name of your second monitor

-- Define custom position values in hs.layout.*
local positions = {
  leftThirdMain = {x=0, y=0, w=0.33, h=1},
  rightTwoThirdsMain = {x=0.33, y=0, w=0.67, h=1},
  topThirdSecond = {x=0, y=0, w=1, h=0.33},
  middleThirdSecond = {x=0, y=0.33, w=1, h=0.33},
  bottomThirdSecond = {x=0, y=0.67, w=1, h=0.33},
}

local layout = {
  {"iTerm", nil, mainMonitor, positions.leftThirdMain, nil, nil},
  {"PyCharm", nil, mainMonitor, positions.rightTwoThirdsMain, nil, nil},
  {"Slack", nil, secondMonitor, positions.topThirdSecond, nil, nil},
  {"Google Chrome", nil, secondMonitor, positions.middleThirdSecond, nil, nil},
  {"Spotify", nil, secondMonitor, positions.bottomThirdSecond, nil, nil},
}

local appNames = {
  "iTerm",
  "PyCharm",
  "Slack",
  "Google Chrome",
  "Spotify"
}

local function launchApps()
  for i, appName in ipairs(appNames) do
    hs.application.launchOrFocus(appName)
  end
end

local menu = hs.menubar.new()
local function setLayout()
  menu:setTitle("🖥")
  menu:setTooltip("Set Layout")
  hs.layout.apply(layout)
end

local function enableMenu()
  menu:setTitle("🖥")
  menu:setTooltip("No Layout")
  menu:setMenu({
      { title = "Launch & Arrange Apps", fn = function() launchApps(); setLayout() end },
  })
end

enableMenu()


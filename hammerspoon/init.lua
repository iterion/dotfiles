-- Hammerspoon config: http://www.hammerspoon.org/go/
local application = require "hs.application"
local hotkey = require "hs.hotkey"
local log = hs.logger.new('iterion','debug')

local mashApps = {
  'cmd',
  'option'
}

local mashGeneral = {
  'cmd',
  'shift'
}

-- Disable window animations (janky for iTerm)
hs.window.animationDuration = 0

function showSlack()
  local appName = 'Slack'
  local app = application.find(appName)
  application.launchOrFocus(appName)

  if (app and application.isRunning(app)) then
    Grid.topleft()
  end
end

function lgMonitor()
  return hs.screen.find('LG UltraFine')
end

function builtInDisplay()
  return hs.screen.find('Color LCD')
end

-- Get the window for an actual zoom call, i.e. not the main window
function zoomCallWindow(app)
  local main = app:getWindow('Zoom')
  -- hs.fnutils.each(app:allWindows(), function(w) log.i(w:title()) end)
  return hs.fnutils.find(app:allWindows(), function(w)
    return w:title() ~= "" and w:id() ~= main:id()
  end)
end

function showZoom()
  local appName = 'zoom.us'
  local app = application.find(appName)
  application.launchOrFocus(appName)

  if (app and app:isRunning()) then
    local lgScreen = lgMonitor()
    local builtInScreen = builtInDisplay()
    local win = app:getWindow('Zoom')
    if win then
      win:moveToScreen(builtInScreen)
      win:focus()
      Grid.topleft()
    end
    local win = zoomCallWindow(app)
    if win then
      win:moveToScreen(lgScreen)
      win:focus()
      Grid.fullscreen()
    end
  end
end

function identifyFrontmost()
  local app = application.frontmostApplication()
  local appElement = hs.axuielement.applicationElement(app)
  log.i(app:name())
  -- hs.alert(appElement:attributeNames())
  -- for i,line in ipairs(appElement:attributeNames()) do
  --   hs.alert(line)
  -- end
end

-- App Shortcuts
hotkey.bind(mashApps, 'S', showSlack)
hotkey.bind(mashApps, 'Z', showZoom)
hotkey.bind(mashApps, '9', identifyFrontmost)


-- Reload automatically on config changes
hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', hs.reload):start()
hs.alert('Hammerspoon is locked and loaded', 1)

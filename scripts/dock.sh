#1/bin/bash

# Remove Dock items
echo -b 'Setting defaults for Dock...'

main() {
  if type dockutil &>/dev/null; then

      dockutil --no-restart \
          --remove 'Maps' \
          --remove 'Notes' \
          --remove 'Photos' \
          --remove 'Contacts' \
          --remove 'FaceTime' \
          --remove 'Feedback Assistant' \
          --remove 'Siri' \
          --remove 'Launchpad' \
          --remove 'Numbers' \
          --remove 'Pages' \
          --remove 'Keynote' \
          --remove 'iBooks' \
          --remove 'Mail' \
          --remove 'Podcasts' \
          --remove 'TV' \
          --remove 'News' \
          --add /Applications/kitty.app \
          -- add /Applications/Visual Studio Code.app \
          --add /Applications/Notion.app \
          --add /Applications/Slack.app \
          &>/dev/null

      killall cprefsd &>/dev/null
      killall -HUP Dock &>/dev/null

  else
    echo 'ERROR: dockutil not found'
  fi
}

main
#!/bin/bash
echo "compiling applescripts for Warp Stable..."
osacompile -o ~/Workspaces/shuttle/apple-scpt/Warp-stable-new-window.scpt -x ~/Workspaces/shuttle/apple-scripts/Warp/Warp-stable-new-window.applescript
osacompile -o ~/Workspaces/shuttle/apple-scpt/Warp-stable-current-window.scpt -x ~/Workspaces/shuttle/apple-scripts/Warp/Warp-stable-current-window.applescript
osacompile -o ~/Workspaces/shuttle/apple-scpt/Warp-stable-new-tab-default.scpt -x ~/Workspaces/shuttle/apple-scripts/Warp/Warp-stable-new-tab-default.applescript
#!/bin/bash
# Double-click this to run the Tiles typesetter with LIVE svg editing.
# It serves this LETTERS folder locally and opens the typesetter in your browser.
# Edit any file in SVG/ then refresh the browser (Cmd-R) to see the change.
# Leave this Terminal window open while you work; close it to stop the server.

cd "$(dirname "$0")" || exit 1

PORT=8777
# find a free port if 8777 is taken
while lsof -i :"$PORT" >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

URL="http://localhost:$PORT/"
echo "──────────────────────────────────────────────"
echo " Tiles Typesetter"
echo " Serving: $(pwd)"
echo " Open:    $URL"
echo " (leave this window open; close it to stop)"
echo "──────────────────────────────────────────────"

# open the browser a moment after the server starts
( sleep 1; open "$URL" ) &

# start the static server (foreground; Ctrl-C or closing the window stops it)
python3 -m http.server "$PORT"

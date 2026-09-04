# Social preview

`social-preview.png` is the image GitHub shows when a link to this repository is shared.
It is uploaded by hand at Settings, Social preview. It is not served from this directory,
so changing the file here does not change what GitHub shows until it is uploaded again.

`social-preview.html` is the source. To regenerate after an edit:

    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
      --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
      --screenshot=.github/social-preview.png --window-size=1280,640 \
      "file://$PWD/.github/social-preview.html"

GitHub asks for at least 640x320 and recommends 1280x640, under 1 MB.

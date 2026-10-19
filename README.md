# NovaVideo

Reference-video player that follows the **NovaAnimator** timeline in Roblox Studio.
Play a video from your PC next to Studio, locked to play / pause / scrubbing / speed. Your video never leaves your computer.

Reproductor de video de referencia que sigue la linea de tiempo de **NovaAnimator** en Roblox Studio.
Reproduce un video de tu PC junto a Studio, pegado a play / pausa / arrastrar / velocidad. Tu video no sale de tu computadora.

## Use / Uso

Pick ONE of the two versions (same page, same features):

| Version | Needs | Start |
|---|---|---|
| PowerShell | Windows (nothing to install) | double-click `Start_NovaVideo_PowerShell.bat` |
| Python | Python 3 | double-click `Start_NovaVideo.bat` or run `python NovaVideo.py` |

1. Start NovaVideo. A page opens in your browser.
2. Pick or drag your video into the page.
3. In Studio: **SupremeAnimator > Reference video (synced) > Sync with NovaVideo**. Allow `127.0.0.1` if Studio asks.
4. Keep the black window open while you animate.

Default port is 8765. To change it, use the same port in the Studio menu (`Port`) and start with `python NovaVideo.py 9000` or `-Port 9000`.

## Page controls

Delay (ms), speed multiplier, +-1 frame (arrow keys), zoom with the mouse wheel, drag to move, double-click to reset, Pin (floating window, Chrome/Edge), mute.
Dragging the video bar while synced lines the video up with the current Studio frame.

## Notes

- Listens only on `127.0.0.1` (your own PC).
- Made for NovaAnimator. It is not related to Eclipse Animator or Eclipse Video.

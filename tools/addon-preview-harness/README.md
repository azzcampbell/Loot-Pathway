# Addon Preview Harness

A lightweight, reusable browser harness for reviewing addon interfaces without launching the game.

## Open it

Double-click `index.html`. It opens with the Loot Pathway example loaded.

## Use it with another addon

1. Create a self-contained HTML mock for the addon UI.
2. Open the harness.
3. Select **Load preview** and choose the HTML file.
4. Use the zoom and backdrop controls to inspect alignment, clipping and readability.

The harness does not depend on Loot Pathway. Its bundled screen is only an example and can be replaced by any local HTML preview.

## Accuracy boundary

HTML can reproduce addon frames, textures, typography, spacing and interaction states. Game-rendered elements such as live 3D character models, spell effects and protected API behaviour must still be verified inside World of Warcraft.

# BLUSpellTracker

**Author:** Faceless  
**Version:** 8.675309

## Description

BLUSpellTracker is a Lua addon for Final Fantasy XI that helps Blue Mages track learnable Blue Magic spells available in the current zone. The addon displays the spells that can be learned, including details about the required mobs and their locations.

## Commands

- **`/bs`**: Displays the current learnable Blue Magic spells in the zone.
- **`/bs scale <factor>`**: Sets the scale of the UI (e.g., `/bs scale 1.5`).
- **`/bs scale r`**: Resets the scale of the UI to the default size (1.0).
- **`/bs help`**: Displays a list of available commands and their descriptions.

## Features

- Automatically updates the list of learnable spells based on the player's current zone.
- Displays the name, level, and mob details for each learnable spell.
- Hides the UI when there are no spells to show.
- Includes commands for UI scaling and help information.

## Installation

1. Download the BLUSpellTracker files.
2. Place the addon folder in your `addons` directory of the Windower installation.
3. Start Windower and run the command `/lua load BLUSpellTracker`.

## Usage

Once loaded, the addon will automatically display a window with the learnable Blue Magic spells for your current zone whenever you change zones. Use the command `/bs` to refresh the UI or to adjust the scaling and access help information.

## Notes

- Ensure you have the resources library and spells data available for the addon to function correctly.
- If the UI does not display as expected, please check for errors in the Windower console.

## Troubleshooting

- If you encounter issues with the addon, ensure that:
  - You have the latest version of Windower and the required libraries.
  - There are no conflicting addons that may affect the UI display.

## Feedback

Feel free to provide feedback or report issues. Contributions and suggestions are welcome!

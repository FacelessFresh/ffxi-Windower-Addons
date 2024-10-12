AssaultHelper
Author: Faceless
Version: 867530.1

Overview
AssaultHelper is a Lua addon for Final Fantasy XI that assists players with information about Assault missions. It provides a user interface (UI) that displays details about current missions, including guides and relevant status effects.

Features
Displays current assault mission details in a customizable UI.
Supports dynamic font, size, and background opacity adjustments.
Allows dragging and repositioning of the UI.
Logs packet data for troubleshooting and analysis.
Supports setup mode for UI adjustments.
Provides help commands for easy access to functionality.
Installation
Download the addon: Clone or download the AssaultHelper files into your Windower addons directory.
Load the addon: Use the command //assault or //ah in-game to activate the UI.
Commands
-Addon Commands that operate this addon are 'assaulthelper', 'assault', 'ah', and 'ass'-
//assault help: Displays help information for the addon.
//assault wrap <number>: Sets the word wrap limit.
//assault setfont <font_name>: Sets the font for the UI.
//assault setfontsize <size>: Sets the font size for the UI.
//assault setopacity <value>: Sets the background opacity (0-255).
//assault setup: Toggles setup mode for adjusting UI settings.
Configuration
The addon saves its settings in AssaultHelper.json. You can adjust the following settings:

Font: The font used in the UI (default: Arial).
Font Size: The size of the font (default: 12).
Position: The position of the UI on the screen.
Background Color: The background color and opacity settings.
UI Functionality
Mission Information: Displays the name and guide for the current assault mission.
Text Formatting: Supports word wrapping and text justification for better readability.
Logging
The addon logs packet data to parse_log.txt for troubleshooting purposes. You can find this file in the addon directory.

Usage
To display the assault mission guide, the addon listens for specific incoming packets related to assault missions. When a mission is accepted or canceled, it retrieves the mission details and displays them in the UI.

Acknowledgments
This addon utilizes the following libraries:

resources: For accessing game data.
packets: For handling network packets.
texts: For UI display.
tables: For managing data structures.
Troubleshooting
If you encounter issues with the addon:

Ensure it is installed in the correct directory.
Check the log file for any error messages.
Adjust your settings in the AssaultHelper.json file.

Enemy Bar Addon
Description

The Enemy Bar addon provides a visual display of target information for your main target, sub-target, focus target, and any mobs currently showing aggression toward you or your party. Each bar shows the mob's HP, distance, enmity, and other relevant information.
Installation

    Download the addon and place it into your Windower addons folder.
    Add the following line to your Windower's init.txt file (located in the Windower root directory):

    lua

    lua load enemybar

Usage

To use the Enemy Bar addon, the following commands are available via the in-game Windower console.
Commands

    /enemybar or /eb
        Opens the list of possible commands for the addon.

Command List

    /eb help
    Displays a list of available commands and their descriptions.

    /eb toggle
    Toggles the entire UI on or off. If hidden, no bars will be displayed.

    /eb target
    Toggles the main target's bar on or off.

    /eb subtarget
    Toggles the sub-target's bar on or off.

    /eb focus
    Toggles the focus target's bar on or off.

    /eb aggro
    Toggles the aggro bars for mobs that have shown aggression toward you or your party.

    /eb reset
    Resets all bars to their default positions as configured in the settings file.

    /eb setup
    Puts the addon into "setup mode," which forces all bars to appear for easy configuration and testing.

    /eb cs
    Toggles the display on or off during cutscenes (CS).

Example Usage

    Enable all bars:
    /eb toggle

    Only show target bar:
    /eb target

    Setup and test bars:
    /eb setup

    Reset bars to default positions:
    /eb reset

Configuration

The addon uses a configuration file to control the appearance and behavior of the bars. You can edit the settings file located in:

bash

Windower4/addons/enemybar/data/settings.xml

Settings Available

    Customize bar positions, colors, size, and more by editing the settings.xml file directly or using the configuration UI mode (/eb setup).

Acknowledgments

The Enemy Bar addon was originally developed by Mike McKee (mmckee) and maintained by akaden.

All rights to this addon and its distribution are governed by the included license.
License

This addon is provided under the terms of the BSD-3-Clause License. For more details, please refer to the LICENSE.txt file included with the addon.
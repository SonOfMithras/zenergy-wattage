# Zenergy Wattage Widget

A KDE Plasma 6 widget that displays the real-time CPU Package Power wattage. It uses the `zenergy` kernel module to read energy data and visualizes it with a customizable graph and text. It was developed for personal use with the use of Google's Antigravity.

Tested on Plasma 6.5.3 with KDE Frameworks 6.20.0 on Arch Linux (CachyOS)

## Features
- **Real-time Monitoring**: Updates CPU wattage every second.
- **Historical Graph**: Visualizes power usage over time (configurable duration).
- **Full Customization**:
    - **Fonts**: Choose font family, size, and styles (Bold, Italic, Underline).
    - **Colors**: Customize text and graph line colors, or let them automatically match your System Theme.
    - **Layout**: Position text Overlay, Above, or Below the graph.
- **System Service**: Includes an optional system service to automatically start the monitor in the background.

## Prerequisites
- **Linux OS** with **KDE Plasma 6**.
- **Python 3** installed.
- **Zenergy Kernel Module**: You must have the `zenergy` driver installed and loaded for your AMD CPU.
    - Check if it's loaded: `lsmod | grep zenergy`
    - Check if it's working: `ls /sys/class/hwmon/hwmon*/name` (should see `zenergy` in one of them).

## Installation

### 1. Install the Widget
1.  Open a terminal in this folder.
2.  Run the install script:
    ```bash
    ./install_widget.sh
    ```
3.  **Add to Desktop**: Right-click on your desktop or panel -> "Add Widgets..." -> Search for "Zenergy Wattage" -> Drag it to your screen.

### 2. Install the Background Service (Recommended)
The widget needs a background script (`monitor.py`) to read the sensor data. You can set this up to run automatically at startup.

1.  Run the service install script (requires sudo):
    ```bash
    sudo ./install_service.sh
    ```
2.  That's it! The service is now running and will start automatically on reboot.

*Note: If you choose not to install the service, the widget will try to warn you if the monitor isn't running, but you'll have to start it manually.*

## Configuration
Right-click the widget and select **Configure Zenergy Wattage...**

### General Settings
- **Graph Background**:
    - **Mode**: Choose between "System Theme" (matches your windows), "Transparent", or a "Custom Color".
    - **Opacity**: Adjust transparency for custom backgrounds.
- **Applet Background**:
    - **Default**: Standard Plasma widget frame.
    - **Transparent**: No frame, just the content.
    - **Transparent with Shadow**: Adds a subtle shadow.

### Text Settings
- **Font**: Customize the font family, size, and style.
- **Color Mode**:
    - **System Theme**: Text color automatically matches your desktop theme (e.g., white on dark themes).
    - **Custom Color**: Pick any color you like.
- **Position**: Place the wattage text on top of the graph (Overlay), or above/below it.

### Graph Settings
- **Show Wattage Graph**: Toggle the graph on/off.
- **Duration**: How many minutes of history to show.
- **Line Color Mode**:
    - **System Theme**: Uses your theme's "Highlight" color.
    - **Custom Color**: Pick your own line color.
- **Line Width**: Adjust the thickness of the graph line.

## Uninstallation

### Remove the Service
If you installed the system service, remove it first:
```bash
sudo ./uninstall_service.sh
```

### Remove the Widget
To remove the widget from your system:
```bash
./uninstall_widget.sh
```

## Troubleshooting
- **"Monitor Inactive" Warning**: This means the widget isn't receiving data.
    - **If using the service**:
        - Make sure you installed it: `sudo ./install_service.sh`
        - Check status: `systemctl status zenergy-wattage`
    - **If NOT using the service**:
        - You must run the monitor manually. The widget includes the script at:
          `~/.local/share/plasma/plasmoids/zergy.wattage.monitor/contents/scripts/monitor.py`
        - Run it with: `python3 ~/.local/share/plasma/plasmoids/zergy.wattage.monitor/contents/scripts/monitor.py`
    - Check if the log file exists: `ls -l ~/.local/share/zenergy-wattage/cpu_wattage.log`
- **Graph Line Not Updating**: Try toggling the "Line Color Mode" in settings. (This issue should be resolved in v0.5.0+).

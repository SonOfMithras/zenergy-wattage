#!/bin/bash

WIDGET_DIR="widget"

WIDGET_ID="zergy.wattage.monitor"
TEMP_DIR="build_widget"

if command -v kpackagetool6 &> /dev/null; then
    KTOOL="kpackagetool6"
elif command -v kpackagetool5 &> /dev/null; then
    KTOOL="kpackagetool5"
else
    echo "Error: kpackagetool not found."
    exit 1
fi

echo "Using $KTOOL"

# Standard Log Path
LOG_FILE="$HOME/.local/share/zenergy-wattage/cpu_wattage.log"

# Get absolute path to the current project directory
PROJECT_DIR=$(pwd)

# Check if monitor.py exists here, if so, we assume the user will run it from here
MONITOR_SCRIPT="$PROJECT_DIR/monitor.py"

if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "Warning: monitor.py not found in current directory. Widget might not have data source."
fi

# Ensure log file exists or will be created
touch "$LOG_FILE"

echo "Configuring widget to read from: $LOG_FILE"

# Create a temporary build directory
rm -rf $TEMP_DIR
cp -r $WIDGET_DIR $TEMP_DIR

# Create scripts directory in build folder
mkdir -p "$TEMP_DIR/contents/scripts"
cp "$MONITOR_SCRIPT" "$TEMP_DIR/contents/scripts/"
chmod +x "$TEMP_DIR/contents/scripts/monitor.py"

# Replace placeholders in main.qml
# Note: monitor.py path is now resolved dynamically in QML, so we don't inject it
sed -i "s|PLACEHOLDER_LOG_PATH|$LOG_FILE|g" "$TEMP_DIR/contents/ui/main.qml"

# Remove existing if present
$KTOOL --type Plasma/Applet --remove $WIDGET_ID 2>/dev/null

# Install from build directory
$KTOOL --type Plasma/Applet --install $TEMP_DIR

if [ $? -eq 0 ]; then
    echo "Widget installed successfully!"
    echo "You can now add 'Zenergy Wattage' to your desktop or panel."
else
    echo "Installation failed."
fi

# Cleanup
rm -rf $TEMP_DIR

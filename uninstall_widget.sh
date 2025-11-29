#!/bin/bash

WIDGET_ID="zergy.wattage.monitor"

if command -v kpackagetool6 &> /dev/null; then
    KTOOL="kpackagetool6"
elif command -v kpackagetool5 &> /dev/null; then
    KTOOL="kpackagetool5"
else
    echo "Error: kpackagetool not found."
    exit 1
fi

echo "Using $KTOOL"
echo "Removing widget: $WIDGET_ID"

$KTOOL --type Plasma/Applet --remove $WIDGET_ID

if [ $? -eq 0 ]; then
    echo "Widget uninstalled successfully."
else
    echo "Failed to uninstall widget (it might not be installed)."
fi

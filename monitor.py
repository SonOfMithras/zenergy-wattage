import os
import time
import argparse
import glob
import sys
import logging

def find_zenergy_hwmon():
    """Finds the hwmon path for zenergy."""
    for path in glob.glob("/sys/class/hwmon/hwmon*/name"):
        try:
            with open(path, "r") as f:
                name = f.read().strip()
            if name == "zenergy":
                return os.path.dirname(path)
        except IOError:
            continue
    return None

def find_socket_energy_file(hwmon_path):
    """Finds the energy input file for the socket (Esocket0)."""
    for path in glob.glob(os.path.join(hwmon_path, "energy*_label")):
        try:
            with open(path, "r") as f:
                label = f.read().strip()
            if label == "Esocket0":
                # The input file has the same prefix but ends in _input
                # e.g., energy9_label -> energy9_input
                base = path.rsplit("_", 1)[0]
                return f"{base}_input"
        except IOError:
            continue
    return None

def read_energy_uj(path):
    """Reads energy in microjoules."""
    try:
        with open(path, "r") as f:
            return int(f.read().strip())
    except (IOError, ValueError):
        return None

def main():
    # Default log path: ~/.local/share/zenergy-wattage/cpu_wattage.log
    default_log_dir = os.path.expanduser("~/.local/share/zenergy-wattage")
    default_log_path = os.path.join(default_log_dir, "cpu_wattage.log")

    parser = argparse.ArgumentParser(description="Monitor CPU Wattage via zenergy")
    parser.add_argument("--interval", type=float, default=1.0, help="Refresh interval in seconds")
    parser.add_argument("--log", type=str, default=default_log_path, help="Log file path")
    args = parser.parse_args()

    # Ensure log directory exists
    log_dir = os.path.dirname(args.log)
    if log_dir and not os.path.exists(log_dir):
        try:
            os.makedirs(log_dir)
        except OSError as e:
            print(f"Error creating log directory {log_dir}: {e}")
            sys.exit(1)

    # Setup logging
    logging.basicConfig(
        filename=args.log,
        level=logging.INFO,
        format="%(asctime)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    
    # Add stdout handler to print to console as well
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(message)s')
    console.setFormatter(formatter)
    # We only want the message on console, or maybe the full log? 
    # The user asked for "output the current cpu usage... And I would like a log to be generated"
    # So let's keep the console output simple or consistent.
    # Actually, let's just print the wattage to console and log the full details to file.
    
    print(f"Monitoring zenergy... Interval: {args.interval}s, Log: {args.log}")

    hwmon_path = find_zenergy_hwmon()
    if not hwmon_path:
        print("Error: zenergy hwmon not found. Is the module loaded?")
        sys.exit(1)
    
    energy_file = find_socket_energy_file(hwmon_path)
    if not energy_file:
        print(f"Error: Esocket0 energy file not found in {hwmon_path}")
        sys.exit(1)

    print(f"Found zenergy at {hwmon_path}")
    print(f"Reading from {energy_file}")

    last_energy = read_energy_uj(energy_file)
    last_time = time.time()

    if last_energy is None:
        print("Error: Could not read initial energy value.")
        sys.exit(1)

    try:
        while True:
            time.sleep(args.interval)
            
            current_energy = read_energy_uj(energy_file)
            current_time = time.time()
            
            if current_energy is None:
                print("Error: Could not read energy value.")
                continue

            # Handle potential counter overflow if necessary, though 64-bit uJ is huge.
            # But just in case current < last (reboot or overflow), skip one sample.
            if current_energy < last_energy:
                last_energy = current_energy
                last_time = current_time
                continue

            delta_energy_uj = current_energy - last_energy
            delta_time = current_time - last_time
            
            if delta_time == 0:
                continue

            watts = (delta_energy_uj / 1_000_000.0) / delta_time
            
            output_msg = f"CPU Package Power: {watts:.2f} W"
            print(output_msg)
            logging.info(f"{watts:.2f} W")

            last_energy = current_energy
            last_time = current_time

    except KeyboardInterrupt:
        print("\nStopping monitor.")

if __name__ == "__main__":
    main()

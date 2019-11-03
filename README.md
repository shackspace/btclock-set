# btclock-set
Simple shell script to set the btClock to the current system time.

**Usage**: ```sudo ./BtClock-Set.sh [pin]```

The pin parameter is only needed if the clock is not paired yet.

## Build deprecated rfcomm tool
```git submodule init
git submodule update --recursive
nix-shell -p gnumake bluez
make```

## Dependencies
You need to have following tools installed: *bluez, bt-agent, rfcomm, stty*

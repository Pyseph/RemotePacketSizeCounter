# RemotePacketSizeCounter
Calculates the size of remote packet data in bytes, given the packet data.
Used in https://github.com/PysephWasntAvailable/PacketProfiler.

## Installation
Install using Wally:
https://wally.run/package/pysephwasntavailable/remotepacketsizecounter

## Usage
```lua
local CountPacketSize = require(Packages.RemotePacketSizeCounter)

CountPacketSize(
    true, -- Whether to ignore remote size overhead
    ... -- Remote packet data, can be any number of arguments of (almost) any type
)
```

## Example
```lua
CountPacketSize(true, 1) -- 9
CountPacketSize(true, 912038912098) -- 9

CountPacketSize(true, "Hello") -- 8
CountPacketSize(false, "Hello") -- 17

CountPacketSize(true, CFrame.new()) -- 14
CountPacketSize(true, CFrame.Angles(0, 10, 0)) -- 22
```
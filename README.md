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
    true, -- Take into account for remote size overhead
    ... -- Remote packet data, can be any number of arguments of (almost) any type
)
```
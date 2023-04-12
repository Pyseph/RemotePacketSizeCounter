# RemotePacketSizeCounter
Calculates the size of remote packet data in bytes, given the packet data.
Used in https://github.com/PysephWasntAvailable/PacketProfiler.

## Installation
Install using Wally:
https://wally.run/package/pysephwasntavailable/remotepacketsizecounter

## Usage
```lua
local PacketSizeCounter = require(Packages.RemotePacketSizeCounter)

-- Use the GetDataByteSize function to get the size of a single argument from a remote
PacketSizeCounter.GetDataByteSize(Value)

-- Use the GetPacketSize function to get the size of all arguments from a remote
PacketSizeCounter.GetPacketSize(
	IgnoreRemoteOffset = true, -- Whether to ignore remote size overhead
	PacketData = {...} -- Array of remote packet data, supports most types
)
```

## Example
```lua
PacketSizeCounter.GetPacketSize({
	IgnoreRemoteOffset = true,
	PacketData = {1}
}) -- 9
PacketSizeCounter.GetPacketSize({
	IgnoreRemoteOffset = true,
	PacketData = {912038912098}
}) -- 9

PacketSizeCounter.GetPacketSize({
	IgnoreRemoteOffset = true,
	PacketData = {"Hello"}
}) -- 8
PacketSizeCounter.GetPacketSize({
	IgnoreRemoteOffset = false,
	PacketData = {"Hello"}
}) -- 17

PacketSizeCounter.GetPacketSize({
	IgnoreRemoteOffset = true,
	PacketData = {CFrame.new()}
}) -- 14
PacketSizeCounter.GetPacketSize({
	IgnoreRemoteOffset = true,
	PacketData = {CFrame.Angles(0, 10, 0)}
}) -- 22
```
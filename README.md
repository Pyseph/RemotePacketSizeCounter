# RemotePacketSizeCounter
Calculates the size of remote packet data in bytes, given the packet data.
Used in https://github.com/PysephWasntAvailable/PacketProfiler.

Buffer values at least 100 bytes long are estimated using Roblox's transparent Zstandard network compression. `GetPacketSizeDetails` and `GetDataByteSizeDetails` return both the estimated transmitted size and the uncompressed serialized size:

```luau
local details = PacketSizeCounter.GetPacketSizeDetails({
	RunContext = "Server",
	RemoteType = "RemoteEvent",
	PacketData = { buffer.create(1024) },
})

print(details.Size)
print(details.UncompressedSize)
print(details.CompressionSavings)
print(details.CompressedBufferCount)
```

Compressed sizes are estimates because Roblox does not expose its exact remote serialization or transport framing. The existing `GetPacketSize` and `GetDataByteSize` functions return the estimated compressed size.

## Installation
Install using Wally:
https://wally.run/package/pysephwasntavailable/remotepacketsizecounter

## Contributing
Please see [CONTRIBUTING.md] for more information.

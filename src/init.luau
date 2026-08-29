--!strict

local BufferSize = require(script.BufferSize)

local BASE_REMOTE_OVERHEAD = 9
local REMOTEFUNCTION_OVERHEAD = 2
local CLIENT_TO_SERVER_OVERHEAD = 5

local TYPE_OVERHEAD = 1

-- Byte sizes of different types of values
local Float64 = 8
local Float32 = 4
local Float16 = 2
local Int32 = 4
local Int16 = 2
local Int8 = 1

-- Vector3's are stored as 3 Float32s, which equates to 12 bytes. They have a 1-byte overhead
-- for what's presumably type differentiation, so the informal calculation for datatypes is:
-- num_types*num_bytes_in_type + TYPE_OVERHEAD
-- Example:
-- Vector3: 3 float32s, 1 byte overhead: 3*4 + 1 = 13 bytes
-- The structs of datatypes can be found below:
-- https://dom.rojo.space/binary.html
-- !! It should still be benchmarked to see if the bytes are correctly calculated !!

local COLOR3_BYTES = 3*Float32
local VECTOR3_BYTES = 3*Float32

local TypeByteSizes: {[string]: number} = {
	["nil"] = 0,
	EnumItem = Int32,
	boolean = 1,
	number = Float64,
	UDim = Float32 + Int32,
	UDim2 = 2*(Float32 + Int32),
	Ray = 6*Float32,
	Faces = 6,
	Axes = 6,
	BrickColor = Int32,
	Color3 = COLOR3_BYTES,
	Vector2 = 2*Float32,
	Vector3 = VECTOR3_BYTES,
	-- It's unclear how instances are sent, but in binary-storage format they're stored with
	-- 'Referents', which can be found in the binary-storage documentation above.
	-- Benchmarks also show that they take up 4 bytes, excluding byte overhead.
	Instance = Int32,
	Vector2int16 = 2*Int16,
	Vector3int16 = 3*Int16,
	NumberSequenceKeypoint = 3*Float32,
	ColorSequenceKeypoint = 4*Float32,
	NumberRange = 2*Float32,
	Rect = 2*(2*Float32),
	PhysicalProperties = 5*Float32,
	Color3uint8 = 3*Int8,
}

-- https://dom.rojo.space/binary.html#cframe
local CFrameSpecialCases = {
	[CFrame.Angles(0, 0, 0)] 							= true, 	[CFrame.Angles(0, math.rad(180), math.rad(0))] 				= true,
	[CFrame.Angles(math.rad(90), 0, 0)] 				= true, 	[CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0))] = true,
	[CFrame.Angles(0, math.rad(180), math.rad(180))] 	= true,		[CFrame.Angles(0, math.rad(0), math.rad(180))] 				= true,
	[CFrame.Angles(math.rad(-90), 0, 0)] 				= true,		[CFrame.Angles(math.rad(90), math.rad(180), math.rad(0))] 	= true,
	[CFrame.Angles(0, math.rad(180), math.rad(90))] 	= true,		[CFrame.Angles(0, math.rad(0), math.rad(-90))] 				= true,
	[CFrame.Angles(0, math.rad(90), math.rad(90))] 		= true,		[CFrame.Angles(0, math.rad(-90), math.rad(-90))]			= true,
	[CFrame.Angles(0, 0, math.rad(90))] 				= true,		[CFrame.Angles(0, math.rad(-180), math.rad(-90))] 			= true,
	[CFrame.Angles(0, math.rad(-90), math.rad(90))] 	= true,		[CFrame.Angles(0, math.rad(90), math.rad(-90))] 			= true,
	[CFrame.Angles(math.rad(-90), math.rad(-90), 0)] 	= true,		[CFrame.Angles(math.rad(90), math.rad(90), 0)] 				= true,
	[CFrame.Angles(0, math.rad(-90), 0)] 				= true,		[CFrame.Angles(0, math.rad(90), 0)] 						= true,
	[CFrame.Angles(math.rad(90), math.rad(-90), 0)] 	= true,		[CFrame.Angles(math.rad(-90), math.rad(90), 0)] 			= true,
	[CFrame.Angles(0, math.rad(90), math.rad(180))] 	= true,		[CFrame.Angles(0, math.rad(-90), math.rad(180))] 			= true,
}

-- https://en.wikipedia.org/wiki/Variable-length_quantity
local function GetVLQSize(InitialSize: number, Length: number)
	return math.max(math.ceil(math.log(Length + InitialSize, 128)), InitialSize)
end

local function GetDataByteSizes(Data: any, AlreadyTraversed: {[{[any]: any}]: boolean}): (number, number, number)
	local DataType = typeof(Data)
	if TypeByteSizes[DataType] then
		local Size = TypeByteSizes[DataType]
		return Size, Size, 0
	elseif DataType == "string" then
		-- https://data-oriented-house.github.io/Squash/docs/binary/#strings
		local Size = GetVLQSize(1, #Data) + #Data
		return Size, Size, 0
	elseif DataType == "buffer" then
		local Size, UncompressedSize, IsCompressed = BufferSize.Measure(Data)
		return Size, UncompressedSize, if IsCompressed then 1 else 0
	elseif DataType == "table" then
		if AlreadyTraversed[Data] then
			return 0, 0, 0
		end
		AlreadyTraversed[Data] = true

		local KeyTotal = 0
		local ValueTotal = 0
		local UncompressedKeyTotal = 0
		local UncompressedValueTotal = 0
		local CompressedBufferCount = 0

		local NumKeys = 1
		local IsArray = Data[1] ~= nil
 		for Key, Value in next, Data do
			NumKeys += 1

			if not IsArray then
				local KeySize, UncompressedKeySize, KeyCompressedBufferCount = GetDataByteSizes(Key, AlreadyTraversed)
				KeyTotal += KeySize + TYPE_OVERHEAD
				UncompressedKeyTotal += UncompressedKeySize + TYPE_OVERHEAD
				CompressedBufferCount += KeyCompressedBufferCount
			end
			local ValueSize, UncompressedValueSize, ValueCompressedBufferCount = GetDataByteSizes(Value, AlreadyTraversed)
			ValueTotal += ValueSize + TYPE_OVERHEAD
			UncompressedValueTotal += UncompressedValueSize + TYPE_OVERHEAD
			CompressedBufferCount += ValueCompressedBufferCount
		end

		local LengthSize = GetVLQSize(1, NumKeys)

		if IsArray then
			return LengthSize + ValueTotal, LengthSize + UncompressedValueTotal, CompressedBufferCount
		else
			return
				LengthSize + KeyTotal + ValueTotal,
				LengthSize + UncompressedKeyTotal + UncompressedValueTotal,
				CompressedBufferCount
		end
	elseif DataType == "CFrame" then
		local IsSpecialCase = false
		for SpecialCase in next, CFrameSpecialCases do
			if SpecialCase == Data.Rotation then
				IsSpecialCase = true
				break
			end
		end

		if IsSpecialCase then
			-- Axis-aligned CFrames skip sending rotation and are encoded as only 13 bytes
			local Size = 1 + VECTOR3_BYTES
			return Size, Size, 0
		else
			-- 1 byte for the ID, 12 bytes for the position vector, and 6 bytes for the quaternion representation
			--                         I'm assuming they send x,y,z quaternions and reconstruct w from `x*x + y*y + z*z + w*w = 1`.
			local Size = 1 + VECTOR3_BYTES + 3*Float16
			return Size, Size, 0
		end
	elseif DataType == "NumberSequence" or DataType == "ColorSequence" then
		local Total = 4
		local UncompressedTotal = 4
		local CompressedBufferCount = 0
		for _, Keypoint in next, Data.Keypoints do
			local Size, UncompressedSize, KeypointCompressedBufferCount = GetDataByteSizes(Keypoint, AlreadyTraversed)
			Total += Size
			UncompressedTotal += UncompressedSize
			CompressedBufferCount += KeypointCompressedBufferCount
		end

		return Total, UncompressedTotal, CompressedBufferCount
	else
		warn("[PacketSizeCounter]: Unsupported data type: " .. DataType)
		return 0, 0, 0
	end
end

export type SizeDetails = {
	Size: number,
	UncompressedSize: number,
	CompressionSavings: number,
	CompressedBufferCount: number,
}

--- @class PacketSizeCounter
--- The main class for calculating the size of packets.
local PacketSizeCounter = {}

--- @prop BaseRemoteOverhead number
--- @within PacketSizeCounter
--- @readonly
--- The byte overhead of a remote event, in bytes.
PacketSizeCounter.BaseRemoteOverhead = BASE_REMOTE_OVERHEAD


--- @prop RemoteFunctionOverhead number
--- @within PacketSizeCounter
--- @readonly
--- The additional byte overhead of a remote function, in bytes.
PacketSizeCounter.RemoteFunctionOverhead = REMOTEFUNCTION_OVERHEAD


--- @prop ClientToServerOverhead number
--- @within PacketSizeCounter
--- @readonly
--- The additional byte overhead of a client-to-server remote, in bytes.
PacketSizeCounter.ClientToServerOverhead = CLIENT_TO_SERVER_OVERHEAD


--- @prop TypeOverhead number
--- @within PacketSizeCounter
--- @readonly
--- The byte overhead of a type, in bytes.
PacketSizeCounter.TypeOverhead = TYPE_OVERHEAD

--- @prop BufferCompressionThreshold number
--- @within PacketSizeCounter
--- @readonly
--- The minimum buffer length at which Roblox applies transparent network compression.
PacketSizeCounter.BufferCompressionThreshold = BufferSize.CompressionThreshold

--- @prop BufferCompressionLevel number
--- @within PacketSizeCounter
--- @readonly
--- The Zstandard compression level used to estimate compressed buffer sizes.
PacketSizeCounter.BufferCompressionLevel = BufferSize.CompressionLevel

local function GetBasePacketSize(CounterData: {
	RunContext: "Server" | "Client",
	RemoteType: "RemoteEvent" | "RemoteFunction",
	PacketData: {any}
}): number
	local Total = BASE_REMOTE_OVERHEAD
	if CounterData.RemoteType == "RemoteFunction" then
		Total += REMOTEFUNCTION_OVERHEAD
	end
	if CounterData.RunContext == "Client" then
		Total += CLIENT_TO_SERVER_OVERHEAD
	end
	return Total
end

--- Returns estimated compressed and uncompressed byte sizes for a packet.
function PacketSizeCounter.GetPacketSizeDetails(CounterData: {
	RunContext: "Server" | "Client",
	RemoteType: "RemoteEvent" | "RemoteFunction",
	PacketData: {any}
}): SizeDetails
	local Total = GetBasePacketSize(CounterData)
	local UncompressedTotal = Total
	local CompressedBufferCount = 0
	local AlreadyTraversed = {}

	for _, Data in ipairs(CounterData.PacketData) do
		local Size, UncompressedSize, DataCompressedBufferCount = GetDataByteSizes(Data, AlreadyTraversed)
		Total += Size + TYPE_OVERHEAD
		UncompressedTotal += UncompressedSize + TYPE_OVERHEAD
		CompressedBufferCount += DataCompressedBufferCount
	end

	return {
		Size = Total,
		UncompressedSize = UncompressedTotal,
		CompressionSavings = UncompressedTotal - Total,
		CompressedBufferCount = CompressedBufferCount,
	}
end

--- Returns the byte size of a packet from the given data. Remote overhead is automatically added, and is different based on the remote type and run context.
function PacketSizeCounter.GetPacketSize(CounterData: {
	RunContext: "Server" | "Client",
	RemoteType: "RemoteEvent" | "RemoteFunction",
	PacketData: {any}
}): number
	return PacketSizeCounter.GetPacketSizeDetails(CounterData).Size
end
--- Returns the byte size of a single data object type. Supports most types.
function PacketSizeCounter.GetDataByteSize(Data: any): number
	local Size = GetDataByteSizes(Data, {})
	return Size + TYPE_OVERHEAD
end

--- Returns estimated compressed and uncompressed byte sizes for a single data object.
function PacketSizeCounter.GetDataByteSizeDetails(Data: any): SizeDetails
	local Size, UncompressedSize, CompressedBufferCount = GetDataByteSizes(Data, {})
	Size += TYPE_OVERHEAD
	UncompressedSize += TYPE_OVERHEAD
	return {
		Size = Size,
		UncompressedSize = UncompressedSize,
		CompressionSavings = UncompressedSize - Size,
		CompressedBufferCount = CompressedBufferCount,
	}
end

table.freeze(PacketSizeCounter)
return PacketSizeCounter

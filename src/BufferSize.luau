--!strict

local EncodingService = game:GetService("EncodingService")

local COMPRESSION_THRESHOLD = 100
local COMPRESSION_LEVEL = 0

local function getVLQSize(initialSize: number, length: number): number
	return math.max(math.ceil(math.log(length + initialSize, 128)), initialSize)
end

local function getSerializedSize(length: number): number
	return getVLQSize(1, length) + length
end

local function measure(value: buffer): (number, number, boolean)
	local uncompressedSize = getSerializedSize(buffer.len(value))
	if buffer.len(value) < COMPRESSION_THRESHOLD then
		return uncompressedSize, uncompressedSize, false
	end

	local success, compressed = pcall(
		EncodingService.CompressBuffer,
		EncodingService,
		value,
		Enum.CompressionAlgorithm.Zstd,
		COMPRESSION_LEVEL
	)
	if not success then
		return uncompressedSize, uncompressedSize, false
	end

	return getSerializedSize(buffer.len(compressed)), uncompressedSize, true
end

return table.freeze({
	CompressionLevel = COMPRESSION_LEVEL,
	CompressionThreshold = COMPRESSION_THRESHOLD,
	Measure = measure,
})

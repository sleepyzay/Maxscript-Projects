from inc_noesis import *
import noesis
import rapi

texList = []

class _textureData():
	def __init__(self, bs):
		self.texturePathOffset = bs.readInt()
		self.textureOffset = bs.readInt()
		self.textureUncompressedLength = bs.readInt()
		self.textureCompressedLength = bs.readInt()
		self.paletteOffset = bs.readInt()
		self.paletteLength = bs.readInt()
		self.textureWidth = bs.readUShort()
		self.textureHeight = bs.readUShort()
		self.null = bs.readInt()
		self.null2 = bs.readInt()
		self.unk = bs.readByte()
		self.unk2 = bs.readByte()
		self.unk3 = bs.readUShort()				# 0x0501
		self.textureNameOffset = bs.readInt()	# textureName is substring of texturePath
		self.unk4 = bs.readInt()				# offset? / length?

def registerNoesisTypes():
	handle = noesis.register("goober", ".dse")
	noesis.setHandlerTypeCheck(handle, noepyCheckType)
	noesis.setHandlerLoadRGBA(handle, noepyLoadRGBA)
	#noesis.logPopup()
	return 1

def noepyCheckType(data):
	return 1

def noepyLoadRGBA(data, texList):
	bs = NoeBitStream(data)

	bs.seek(0x1e, NOESEEK_ABS)
	unk = bs.readUShort()
	unk2 = bs.readUShort()
	boneCount = bs.readUShort()
	meshCount = bs.readUShort()
	meshCount2 = bs.readUShort()			# same as meshCount
	materialCount = bs.readUShort()
	textureCount = bs.readUShort()

	boneDataOffset = bs.readInt()
	boneDataOffset2 = bs.readInt()
	meshDataOffset = bs.readInt()
	meshDataOffset2 = bs.readInt()
	materialDataOffset = bs.readInt()
	textureDataOffset = bs.readInt()    # length?
	stringBufferOffset = bs.readInt()

	unkOffset = bs.readInt()			# another baseOffset? / null
	stringBufferOffset2 = bs.readInt()	# another baseOffset? / usually the same as stringBufferOffset
	stringBufferLength = bs.readInt()
	fileNameOffset = bs.readInt()		# relative to stringBufferOffset
	unkDataOffset = bs.readInt()
	textureBufferOffset = bs.readInt()
	fileSize = bs.readInt()

	baseOffset = bs.tell()
	print("boneCount: {0} meshCount: {1} materialCount: {2} textureCount: {3}".format(boneCount, meshCount, materialCount, textureCount))

	bs.seek(textureDataOffset + baseOffset, NOESEEK_ABS)
	textureDataList = [_textureData(bs) for x in range(textureCount)]
	for x, textureData in enumerate(textureDataList):
		if x == 1:
			bs.seek(textureData.textureNameOffset + stringBufferOffset2 + baseOffset, NOESEEK_ABS)
			textureName = bs.readString()[:-4]

			bs.seek(textureData.paletteOffset + textureBufferOffset, NOESEEK_ABS)
			palData = bs.readBytes(textureData.paletteLength)

			imgWidth = textureData.textureWidth
			imgHeight = textureData.textureHeight

			bpp = None
			if textureData.unk == 3: bpp = 4
			if textureData.unk == 4: bpp = 8

			# print("{0:x} {1:x} {2:x} {3:x}".format())

			bs.seek(textureData.textureOffset + textureBufferOffset, NOESEEK_ABS)
			if textureData.textureCompressedLength == textureData.textureUncompressedLength:
				print("uncompressed")
				# print("{0:x}".format(bs.tell()))
				# texData = bs.readBytes(textureData.textureUncompressedLength)
				# texData2 = rapi.imageDecodeRawPal(texData, palData, imgHeight, imgHeight, 8, "r5g5b5p1")
				# texList.append(NoeTexture(rapi.getInputName(), imgWidth, imgHeight, texData2, noesis.NOESISTEX_RGBA32))
			else:
				print("compressed")
				print(hex(bs.tell()))
				uncompressedTexDataLength = bs.readInt()
				compressedTexData = bs.readBytes(textureData.textureCompressedLength - 0x04)
				
				# compressedTexData = bs.readBytes(textureData.textureCompressedLength)
				
				decompressedTexData = rapi.decompLZS01(compressedTexData,textureData.textureUncompressedLength)

				texData2 = rapi.imageDecodeRawPal(decompressedTexData, palData, imgHeight, imgHeight, bpp, "r5g5b5p1")
				# texData2 = rapi.imageDecodeRawPal(compressedTexData, palData, imgHeight, imgHeight, bpp, "r5g5b5p1")

				# Iterate through each pixel in the texture
				for i in range(0, len(texData2), 4):  # Iterate over pixels (4 bytes per pixel: RGBA)
					if texData2[i] == 0 and texData2[i + 1] == 255 and texData2[i + 2] == 0:  # Check for 00FF00
						texData2[i + 3] = 0  # Set alpha to fully transparent

				texList.append(NoeTexture(str(x), imgWidth, imgHeight, texData2, noesis.NOESISTEX_RGBA32))
	return 1
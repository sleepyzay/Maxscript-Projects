from inc_noesis import *
import noesis
import rapi

texList = []

def registerNoesisTypes():
	handle = noesis.register("Dead Space Mobile", ".m3g")
	noesis.setHandlerTypeCheck(handle, noepyCheckType)
	noesis.setHandlerLoadRGBA(handle, noepyLoadRGBA)
	#noesis.logPopup()
	return 1

def noepyCheckType(data):
	return 1

def noepyLoadRGBA(data, texList):
	bs = NoeBitStream(data)

	
	bs.seek(0x60, NOESEEK_ABS)	#always the same
	ukw = bs.readUInt()
	imgWidth = bs.readUInt()
	imgHeight = bs.readUInt()
	null = bs.readUInt()
	dataLength = bs.readUInt()
	dataOffset = bs.tell()
	

	bs.seek(dataOffset, NOESEEK_ABS)
	texData = bs.readBytes(dataLength)
	#texData = rapi.swapEndianArray(texData, 2)

	#texData = rapi.imageDecodeRaw(texData, imgWidth, imgHeight, "b8g8r8a8")
	#rapi.imageDecodeDXT(texData, imgWidth, imgHeight, noesis.NOESISTEX_DXT1)
	#texData = rapi.imageDecodeRaw(texData, imgWidth, imgHeight, "r5 g6 b5 a1")
	texData = rapi.imageDecodeETC(texData, imgWidth, imgHeight, "RGB")
	texData = rapi.imageFlipRGBA32(texData, imgWidth, imgHeight, 0, 1)
	texList.append(NoeTexture(rapi.getInputName(), imgWidth, imgHeight, texData, noesis.NOESISTEX_RGBA32))

	return 1
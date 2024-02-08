--sleepyzay--

fn paddstring len instring = (
	instring=instring as string
	local str=""
	if instring.count <=len then (
		for i = 1 to (len-instring.count) do(
			str+="0"
		)
		str = (str+instring)
	)
	else (
		for i = 1 to len do(
			str+="0";str[i]=instring[i]
		)
	)
	str
)
fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)
fn ReadFixedString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str0 = ReadByte bstream #unsigned
      If str0!=0xFD AND str0!=0xFC do str+= bit.intAsChar str0
   )
   str
)
fn ReadFixedByteString bstream fixedLen var var2 = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   if var == 1 do fseek bstream -fixedLen #seek_cur
   if var2 == 1 do print str
)
fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHexArr inArr var = (
	if var == 0 do (
		for o in inArr do printHex o
	)
	if var == 1 do (
		nomapArr = #()
		for o in inArr do append nomapArr (bit.intashex(o as integer))
		print nomapArr #nomap
	)
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex((ftell bstream) as integer))as string))
)

fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn findValLoc val bstream = (
	--0x1000 search limit / maxscript is slow and large numbers will freeze max
	--need to add option for endianes
	searchVal = val
	-- searchVal = readlong bstream #unsigned
	--fseek bstream -4 #seek_cur
	-- 	printHex searchVal
	-- 	printHere f

	-- bitMask = 0xff
	bitMask = 0xff000000

	j=0
	while true do (
		j+=1
		valFound = false
		
		k = 0
		for y=1 to 4 do (	--loop through all the bytes in long
			testByte = readbyte bstream #unsigned
			testCompare = (bit.shift (bit.and searchVal (bit.shift bitMask -k)) -(8*(4-y)))
	-- 		testCompare = (bit.shift (bit.and searchVal (bit.shift bitMask k)) -(8*(y-1)))
			k+=8
			
-- 			format "testByte:%	testCompare:%\n" (bit.intashex((testByte) as integer)) (bit.intashex((testCompare) as integer))
			
			if testByte == testCompare then (
				if y==4 do (
					valFound = true
				)
				continue
			)
			else (	--if fail go back to the beginning
				fseek bstream -y #seek_cur
				exit
			)
		)
		
		if valFound == true then (
-- 			format "val found at %\n" (bit.intashex(((ftell bstream) - 4) as integer))
			return ((ftell bstream) - 4)
			exit
		)
		else (fseek bstream 1 #seek_cur)
		
-- 		if j >= 0x1000 do exit
	)
)

-- fname = GetOpenFileName caption:"" types:" (*.)|*.tpl" historyCategory:""
fname=@"D:\models\ripped\h2a\elite__h_edit.tpl"
-- fname = @"D:\models\ripped\h2a\masterchief__h_edit.tpl"

-- fname=@"C:\Users\Owner\Desktop\h2a\cortana__h_edit.tpl"
-- fname=@"D:\models\ripped\h2a\marine_armory__h_edit.tpl"
-- fname=@"C:\Users\Owner\Desktop\h2a\masterchief__h_edit.tpl"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileSize = getFileSize fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct bufferInfo (
	faceBufferOffset,
	ukwBufferOffset,
	staticVertBufferOffset,
	skinnedVertBufferOffset,
	normalTextureVertBufferOffset,
	ukwFaceOffset02,
	ukwVertexOffset30,	
	ukwVertexOffset70
)
struct bufferType (
	ukw = (readshort f #unsigned),
	ukw2 = (readbyte f #unsigned),
	bufferType = (readbyte f #unsigned),
	ukw4 = (readbyte f #unsigned),
	ukw5 = (readbyte f #unsigned),
	ukw6 = (readlong f #unsigned)
)
struct meshData (
	bufferID = (readlong f #unsigned + 1),
	subBufferOffset = (readlong f #unsigned)	
)
struct ukwMeshTable (
	ukw = (readshort f #unsigned),
	ukw2 = (readbyte f #unsigned),
	ukw3 = (readbyte f #unsigned),
	ukw4 = (readbyte f #unsigned),
	ukw5 = (readbyte f #unsigned),
	ukw6 = (readlong f #unsigned)
)
struct subMeshData (
	vertOffset = (readshort f #unsigned),			--how often this is zero is meshCount
	vertCount = (readshort f #unsigned),
	faceOffset = (readshort f #unsigned),			--how often this is zero is meshCount
	faceCount = (readshort f #unsigned),
	nodeID = (readshort f #unsigned),
	skinCompoundID = (readshort f #unsigned)
)
struct ukwNodeTable (
	ukw = readshort f,		--0x28
	ukw2 = readshort f,	--0x00 / 0x04 / isMesh?
	ukw3 = readshort f,	--0x00 / 0x800 / isBone?
	ukw4 = readbyte f		--0x00 / 0x01 / isHighestLod?
)
struct subMeshUVScaleData (
	ukw = readbyte f,
	ukw2 = readbyte f,
	ukw3 = readbyte f,
	ukw4 = readbyte f
)
struct subMeshScaleData (
	pos = [readshort f,readshort f,readshort f],
	scale = [readshort f,readshort f,readshort f]
)

struct boundBox (
	ukw = (readlong f),				--0x03
	ukw2 = (readbyte f),				--0x07
	subMeshIndex = (readlong f #unsigned+1),
	subMeshRange = (readlong f),
	bbMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale),
	bbMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
)

struct mat (version,shadingMtl_Tex,shadingMtl_Mtl,lm,layer0,layer1,layer2,extraParams)
	struct lm (source,texName,uvSetIdx,tangent)
		struct tangent (uvSetIdx)
	struct layer0 (texName,mtlName,tint,vcSet,tilingU,tilingV,blending,uvSetIdx)
	struct layer1 (texName,mtlName,tint,vcSet,tilingU,tilingV,blending,uvSetIdx)
	struct layer2 (texName,mtlName,tint,vcSet,tilingU,tilingV,blending,uvSetIdx)
		struct blending (method,useLayerAlpha,useHeightmap,weightMultiplier,heightmapSoftness,texChannelBlendMask,weights,heightmap_,heightmapOverride,upVector,heightmapUVOverride)
			struct weights (colorSetIdx)
			struct heightmap_ (colorSetIdx,invert_)
			struct upVector (angle_,enabled,falloff_)
			struct heightmapUVOverride (enabled,tilingU,tilingV,uvSetIdx)
	struct extraParams (reliefNormalmaps,auxiliaryTextures,transparency,extraVertexColorData)
		struct reliefNormalmaps (macro,micro1,micro2)
			struct macro (end,falloff_,isVisible,scale_,start,textureName,tilingU,tilingV,uvSetIdx)
			struct micro1 (end,falloff_,isVisible,scale_,start,textureName,tilingU,tilingV,uvSetIdx)
			struct micro2 (end,falloff_,isVisible,scale_,start,textureName,tilingU,tilingV,uvSetIdx)
		struct auxiliaryTextures (mask_)
			struct mask_ (textureName,tilingU,tilingV,uvSetIdx)
		struct transparency (colorSetIdx,enabled,multiplier,sources)
		struct extraVertexColorData (colorA,colorB,colorG,colorR)
			struct colorA (colorSetIdx)
			struct colorB (colorSetIdx)
			struct colorG (colorSetIdx)
			struct colorR (colorSetIdx)

struct dataType6 (
	ukw = (readlong f),
	ukw2 = (readfloat f)
)

fn getData dataType = (
	case dataType of (
		1:(
			return (readlong f)
		)
		2:(
			return (readfloat f)
		)
		3:(
			return (readbyte f)
		)
		4:(
			return (ReadFixedString f (readlong f))
		)
		6:(
			return (for x=1 to (readlong f) collect (data = dataType6()))
		)
		7:(	--subChunkCount
			return (readlong f)
		)
		default:(
			format "unknown dataType: %\n" (bit.intashex(dataType as integer))
		)
	)
)
fn readMat mat parent = (
	chunkType = ReadFixedString f (readlong f)
	dataType = readlong f		--1 = int, 2 = float, 3 = bool, 4 = fixedStringCount, 5 = ? / havent encountered yet, 6 = unk 0x08 size struct count, 7 = subChunkCount
	data = getData dataType
	
	case chunkType of (
		"angle":(
			parent.angle_ = data
		)
		"auxiliaryTextures":(
			parent.auxiliaryTextures = auxiliaryTextures()
			for y=1 to data do (
				readMat mat parent.auxiliaryTextures
			)
		)
		"blending":(
			parent.blending = blending()
			for y=1 to data do (
				readMat mat parent.blending
			)
		)
		"colorA":(
			parent.colorA = colorA()
			for y=1 to data do (
				readMat mat parent.colorA
			)
		)
		"colorB":(
			parent.colorB = colorB()
			for y=1 to data do (
				readMat mat parent.colorB
			)
		)
		"colorG":(
			parent.colorG = colorG()
			for y=1 to data do (
				readMat mat parent.colorG
			)
		)
		"colorR":(
			parent.colorR = colorR()
			for y=1 to data do (
				readMat mat parent.colorR
			)
		)
		"colorSetIdx":(
			parent.colorSetIdx = data
		)
		"enabled":(
			parent.enabled = data
		)
		"end":(
			parent.end = data
		)
		"extraParams":(
			parent.extraParams = extraParams()
			for y=1 to data do (
				readMat mat parent.extraParams
			)
		)
		"extraVertexColorData":(
			parent.extraVertexColorData = extraVertexColorData()
			for y=1 to data do (
				readMat mat parent.extraVertexColorData
			)
		)
		"falloff":(
			parent.falloff_ = data
		)
		"heightmap":(
			parent.heightmap_ = heightmap_()
			for y=1 to data do (
				readMat mat parent.heightmap_
			)
		)
		"heightmapOverride":(
			parent.heightmapOverride = data
		)
		"heightmapSoftness":(
			parent.heightmapSoftness = data
		)
		"heightmapUVOverride":(
			parent.heightmapUVOverride = heightmapUVOverride()
			for y=1 to data do (
				readMat mat parent.heightmapUVOverride
			)
		)
		"invert":(
			parent.invert_ = data
		)
		"isVisible":(
			parent.isVisible = data
		)
		"layer0":(
			parent.layer0 = layer0()
			for y=1 to data do (
				readMat mat parent.layer0
			)
		)
		"layer1":(
			parent.layer1 = layer1()
			for y=1 to data do (
				readMat mat parent.layer1
			)
		)
		"layer2":(
			parent.layer2 = layer2()
			for y=1 to data do (
				readMat mat parent.layer2
			)
		)
		"lm":(
			parent.lm = lm()
			for y=1 to data do (
				readMat mat parent.lm
			)
		)
		"mask":(
			parent.mask_ = mask_()
			for y=1 to data do (
				readMat mat parent.mask_
			)
		)
		"macro":(
			parent.macro = macro()
			for y=1 to data do (
				readMat mat parent.macro
			)
		)
		"micro1":(
			parent.micro1 = micro1()
			for y=1 to data do (
				readMat mat parent.micro1
			)
		)
		"micro2":(
			parent.micro2 = micro2()
			for y=1 to data do (
				readMat mat parent.micro2
			)
		)
		"method":(
			parent.method = data
		)
		"multiplier":(
			parent.multiplier = data
		)
		"mtlName":(
			parent.mtlName = data
		)
		"reliefNormalmaps":(
			parent.reliefNormalmaps = reliefNormalmaps()
			for y=1 to data do (
				readMat mat parent.reliefNormalmaps
			)
		)
		"shadingMtl_Mtl":(
			parent.shadingMtl_Mtl = data
		)
		"shadingMtl_Tex":(
			parent.shadingMtl_Tex = data
		)
		"source":(
			parent.source = data
		)
		"sources":(
			parent.sources = data
		)
		"scale":(
			parent.scale_ = data
		)
		"start":(
			parent.start = data
		)
		"tangent":(
			parent.tangent = tangent()
			for y=1 to data do (
				readMat mat parent.tangent
			)
		)
		"texChannelBlendMask":(
			parent.texChannelBlendMask = data
		)
		"texName":(
			parent.texName = data
		)
		"textureName":(
			parent.textureName = data
		)
		"tilingU":(
			parent.tilingU = data
		)
		"tilingV":(
			parent.tilingV = data
		)
		"tint":(
			parent.tint = data
		)
		"transparency":(
			parent.transparency = transparency()
			for y=1 to data do (
				readMat mat parent.transparency
			)
		)
		"useHeightmap":(
			parent.useHeightmap = data
		)
		"useLayerAlpha":(
			parent.useLayerAlpha = data
		)
		"uvSetIdx":(
			parent.uvSetIdx = data
		)
		"upVector":(
			parent.upVector = upVector()
			for y=1 to data do (
				readMat mat parent.upVector
			)
		)
		"vcSet":(
			parent.vcSet = data
		)
		"version":(
			parent.version = data
		)
		"weightMultiplier":(
			parent.weightMultiplier = data
		)
		"weights":(
			parent.weights = weights()
			for y=1 to data do (
				readMat mat parent.weights
			)
		)
		default:(
			format "undefined chunkType:% from parent:%	at %\n" chunkType parent (bit.intashex(ftell f as integer))
			exit
		)
	)
)

fn reverseString s =
(
    local reversed = ""
    for i in s.count to 1 by -1 do reversed += s[i]
    reversed
)
fn printBinary val size = (
	str = ""
	for i=1 to size do (
		if (bit.get val i)  then str += "1"
		else str += "0"
		
		if ((mod i 8) == 0) and (i < size) do str+=" "
	)
	
	str = reverseString str
	print str
)

_1SERtpl = ReadFixedString f 8
ukw = readlonglong f		--flag? / count?
ukwflag = readlonglong f	--flag? / count?
ukw3 = readlonglong f
null = readlong f			--ff's
fseek f 0x10 #seek_cur	--floats / bb info?
fseek f 0x20 #seek_cur	--non important data?
texNameLength = readlong f
texName = ReadFixedString f texNameLength

TPL1 = ReadFixedString f 4
ukw4 = readlong f			--0xc
ukw5 = readshort f
modelNameLength = readlong f
modelName = ReadFixedString f modelNameLength
ukw6 = readshort f		--0x1e
ukw7 = readlong f			--0x40
exportStringLength = readlong f
exportString = ReadFixedString f exportStringLength
typeStringLength = readlong f
typeString = ReadFixedString f typeStringLength

matrixCount = readlong f
ukw8 = readshort f		--0x03
ukw9 = readbyte f			--flag?

--skipping above, not always consistant
fseek f (findValLoc 0x4F474D31 f) #seek_set	--OGM1

OGM1 = ReadFixedString f 4
fseek f 0x07 #seek_cur	--01 00 02 00 03 00 01
nodeCount = readlong f
sectionCount = readlong f

format "nodeCount: %	sectionCount: %\n" (bit.intashex(nodeCount)) (bit.intashex(sectionCount))

BNArr=#()
nodeIDArr=#()
parentIDArr=#()
siblingIDArr=#()
siblingID2Arr=#()
childIDArr=#()
boneIDArr=#()
nodeNameArr=#()
exportNameArr=#()
ukwNodeTableArr=#()
globalMatrixArr=#()
localMatrixArr=#()
nodeBoundPresentArray=#()
nodeBoundArray=#()

for x=1 to sectionCount do (
	isDataPresent = readbyte f
	if isDataPresent != 0 then (
-- 		format "data present for %\n" x
		case x of (
			1:(		-- node ids
				for y=1 to nodeCount do append nodeIDArr (readshort f)
			)
			2:(		-- node names
				for y=1 to nodeCount do append nodeNameArr (ReadFixedString f (readlong f))
			)
			3:(		-- ukw table
				for y=1 to nodeCount do append ukwNodeTableArr (
					--ReadFixedByteString f 0x07 1 1
					table = ukwNodeTable()
				)
			)
			4:(		-- parent ids
				for y=1 to nodeCount do append parentIDArr (readshort f)
			)
			5:(		-- sibling ids
				for y=1 to nodeCount do append siblingIDArr (readshort f)
			)
			6:(		-- second sibling ids
				for y=1 to nodeCount do append siblingID2Arr (readshort f)
			)
			7:(		-- child ids
				for y=1 to nodeCount do append childIDArr (readshort f)
			)
			8:(		-- bone ids
				for y=1 to nodeCount do append boneIDArr (readshort f)
			)
			9:(		-- export info
				for y=1 to nodeCount do append exportNameArr (ReadFixedString f (readlong f))
			)
			10:(		-- global matrices
				for y=1 to nodeCount do (
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					
					tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] ([m41,m42,m43] * fscale)
					append globalMatrixArr tfm
				)
			)
			11:(		-- local matrices
				for y=1 to nodeCount do (
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					
					tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] ([m41,m42,m43] * fscale)
					append localMatrixArr tfm
				)
			)
			12:(		-- bound box
				for y=1 to (ceil (nodeCount / 8.0)) do (
					byte = readbyte f
					for z=1 to 8 where nodeBoundPresentArray.count < nodeCount do (
						b = bit.get byte z
						append nodeBoundPresentArray (if b then 1 else 0)
					)
				)
				for y=1 to nodeCount where nodeBoundPresentArray[y] == 1 do (
					ReadFixedByteString f 0x25 1 0
					nodeBoundArray[y] = (_boundBox = boundBox())
				)
			)
			13:(		-- node hierarchy
				for y=1 to nodeCount do (nodeHierarchy = ReadFixedString f (readlong f))
			)
			14:(		-- null table
				for y=1 to nodeCount do (ReadFixedByteString f 0x3c 0 0)
			)
			15:(		-- node names
				for y=1 to nodeCount do append nodeNameArr (nodeName = ReadFixedString f (readshort f))
			)
			16:(		-- export info
				for y=1 to nodeCount do append exportNameArr (exportInfo = ReadFixedString f (readshort f))
			)
			default:(
				format "% @ %\n" x (bit.intashex((ftell f)as integer))
				exit
			)
		)
	)
	else (
		format "empty % @ %\n" x (bit.intashex(((ftell f)-1)as integer))
		continue
	)
)

for x=1 to nodeCount do (
	tfm = globalMatrixArr[x]
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = tfm
	newBone.name = nodeNameArr[x]
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	append BNArr newBone
)
for x=1 to nodeCount do (
	if parentIDArr[x] != -1 do (
		BNArr[x].parent = BNArr[parentIDArr[x] + 1]
		--BNArr[x].transform *= BNArr[x].parent.transform
	)
)

for b in BNArr where b.parent==undefined do b.transform = (matrix3 [0,-1,0] [0,0,1] [-1,0,0] [0,0,0])
for x=1 to nodeCount do (
	format "% % % % % % % %\n" nodeBoundPresentArray[x] (paddstring 4 (bit.intashex(nodeIDArr[x] as integer))) (paddstring 4 (bit.intashex(boneIDArr[x] as integer))) (paddstring 4 (bit.intashex(parentIDArr[x] as integer))) (paddstring 4 (bit.intashex(ukwNodeTableArr[x].ukw2 as integer))) (paddstring 4 (bit.intashex(ukwNodeTableArr[x].ukw3 as integer))) (paddstring 4 (bit.intashex(ukwNodeTableArr[x].ukw4 as integer))) BNArr[x].name
)
printhere f
chunkTag = readshort f						--0x00 / modelInfo
chunkEnd = readlong f						--points to bufferContainer

rootNodeIndex = readshort f				--h
nodeCount2 = readlong f					--same as nodeCount / usedNodes?
bufferCount = readlong f
meshCount = readlong f
subMeshCount = readlong f
fseek f 0x08 #seek_cur						--null

format "\nrootNodeIndex: %	nodeCount: %	bufferCount: %	meshCount: %	subMeshCount: %\n" (bit.intashex(rootNodeIndex as integer)) (bit.intashex(nodeCount2 as integer)) (bit.intashex(bufferCount as integer)) (bit.intashex(meshCount as integer)) (bit.intashex(subMeshCount as integer))
	
chunkTag = readshort f						--0x02 / bufferContainer
chunkEnd = readlong f						--points to meshContainer

chunkTag = readshort f						--0x00 / bufferType
chunkEnd = readlong f						--points to bufferElmSize
bufferTypeArray = for x=1 to bufferCount collect (
	ReadFixedByteString f 0x0a 1 0
	type = bufferType()
)
--print bufferTypeArray

chunkTag = readshort f						--0x01 / bufferElmSize
chunkEnd = readlong f						--points to bufferLength
bufferElmSizeArray = for x=1 to bufferCount collect (readshort f #unsigned)

chunkTag = readshort f						--0x02 / bufferLength
chunkEnd = readlong f						--points to bufferData
bufferLengthArray = for x=1 to bufferCount collect (readlong f #unsigned)

chunkTag = readshort f						--0x03 / bufferData
chunkEnd = readlong f						--points to meshContainer
buffer = bufferInfo()
for x=1 to bufferCount do (
	case bufferTypeArray[x].bufferType of (
		0x00:(
			buffer.faceBufferOffset = ftell f
		)
		0x02:(
			buffer.ukwFaceOffset02 = ftell f
		)
		0x0c:(
			buffer.staticVertBufferOffset = ftell f
		)
		0x0f:(
			buffer.skinnedVertBufferOffset = ftell f
		)
		0x10:(
			buffer.normalTextureVertBufferOffset = ftell f
		)
		0x30:(
			buffer.ukwVertexOffset30 = ftell f
		)
		0x70:(
			buffer.ukwVertexOffset70 = ftell f
		)
		default:(
			format "unparsed subBufferID: % @ %\n" (bit.intashex((bufferTypeArray[x].bufferType)as integer)) (bit.intashex((ftell f) as integer))
		)
	)
	fseek f bufferLengthArray[x] #seek_cur
)

chunkTag = readshort f						--0x03 / meshContainer
chunkEnd = readlong f						--points to subMeshContainer

chunkTag = readshort f						--0x02 / meshData
chunkEnd = readlong f						--points to ukwTable
meshDataArray=#()
for x=1 to meshCount do (				--describes which buffers the mesh reads from and the base offsets whithin each buffer to be read from
	meshDataArray[x] = for y=1 to (readbyte f) collect (data = meshData())
)
-- print meshDataArray

chunkTag = readshort f						--0x00 / ukwMeshDataTable / same stucture as bufferType
chunkEnd = readlong f						--points to subMeshContainer
meshFlagArray = #()
for x=1 to meshCount collect (
	flagString = ""
	flagArr = #()
	
	ReadFixedByteString f 0x0a 1 0;
	flagCount = readshort f
-- 	print flagCount
	for y=1 to (ceil (flagCount / 8.0)) do (
		byte = readbyte f
		for z=1 to 8 do (
			b = bit.get byte z
			if b == true and flagArr.count < flagCount then (
				append flagArr 1
				flagString += "1"
			)
			else if flagArr.count < flagCount do (
				append flagArr 0
				flagString += "0"
			)
		)
	)
-- 	print flagString
	append meshFlagArray flagArr
)

chunkTag = readshort f						--0x04 / subMeshContainer
chunkEnd = readlong f						--points to delimiter at end of file

chunkTag = readshort f						--0x00 / subMeshData
chunkEnd = readlong f						--points to subMeshID
subMeshDataArray=#()
for x=1 to subMeshCount do (
	ReadFixedByteString f 0x10 1 0
	append subMeshDataArray (data = subMeshData())
	ukwFlags = readlong f
	ukwFloats = for y=1 to 8 where (bit.get ukwFlags y == true) collect (	--never seen it higher than 3, doing 8 just in case
		floats = [readfloat f, readfloat f]
	)
)
-- print subMeshDataArray

chunkTag = readshort f						--0x01 / meshID
chunkEnd = readlong f						--points to  subMeshMaterialData
meshIDArray = for x=1 to subMeshCount collect (readlong f #unsigned + 1)
-- print meshIDArray

chunkTag = readshort f						--0x08 / subMeshMaterialData
chunkEnd = readlong f						--points to subMeshBoneMap
subMeshNodeIdArr=#()
for x=1 to subMeshCount do (
	_mat = mat()
	subMeshNodeIdArr[x] = readshort f #unsigned + 1	--will change in the future to encompas rest of data / matNameID
	for y=1 to (readlong f) do (readMat _mat _mat)	--no parent
)
-- print subMeshNodeIdArr

chunkTag = readshort f						--0x03 / subMeshBoneMap
chunkEnd = readlong f						--points to subMeshUVScaleData
j = 0
boneMapArray = #()
while ((ftell f) < chunkEnd) do (		--count is number of skinned meshes
	j+=1
	boneMapCount = readbyte f
	boneMapArray[j] = for y=1 to boneMapCount collect (readshort f)
)
format "boneMapArrayCount: %\n\n" (bit.intashex(j as integer))

chunkTag = readshort f						--0x04 / subMeshUVScaleData / uvScale?
chunkEnd = readlong f						--points to subMeshScale
subMeshUVScaleArray = for x=1 to subMeshCount collect (
	ReadFixedByteString f 4 1 0
	table = subMeshUVScaleData()
)
-- print subMeshUVScaleArray

--print "subMeshScale"
chunkTag = readshort f						--0x05 / subMeshScale
chunkEnd = readlong f						--points to delimiter
subMeshScaleArray = for x=1 to subMeshCount collect (
	ReadFixedByteString f 0x0c 1 1
	subMeshScale = subMeshScaleData()
)
--print subMeshScaleArray

chunkTag = readshort f						--delimiter
chunkEnd = readlong f						--points to end of file
if ((ftell f) == FileSize) do format "Reached end of file.\n\n"
format "\n"

for x=1 to subMeshCount do ( --subMeshCount
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	Bone_Array=#()
	
	meshID = meshIDArray[x]
	--print BNArr[subMeshNodeIdArr[x]].name
	for y=1 to meshDataArray[meshID].count do (
		bufferType = bufferTypeArray[meshDataArray[meshID][y].bufferID].bufferType
		bufferElmSize = bufferElmSizeArray[meshDataArray[meshID][y].bufferID]
		--format "% %\n" (bit.intashex(bufferType)) (bit.intashex(bufferElmSize))
		
		case bufferType of (
			0x00:(
				fseek f ((subMeshDataArray[x].faceOffset * bufferElmSize) + buffer.faceBufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].faceCount do (
					fa = readshort f #unsigned + 1 - subMeshDataArray[x].vertOffset
					fb = readshort f #unsigned + 1 - subMeshDataArray[x].vertOffset 
					fc = readshort f #unsigned + 1 - subMeshDataArray[x].vertOffset 
					
					append Face_array[fa,fb,fc]
				)
			)
			0x02:(
				fseek f ((subMeshDataArray[x].faceOffset * bufferElmSize) + buffer.ukwFaceOffset02 + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].faceCount do (
					ukwFaceID = readlong f #unsigned + 1	--matID?
				)
			)
			0x0c:(
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + buffer.staticVertBufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].vertCount do (
					vx = readshort f / 32767.0 * subMeshScaleArray[x].scale[1] + subMeshScaleArray[x].pos[1]
					vy = readshort f / 32767.0 * subMeshScaleArray[x].scale[2] + subMeshScaleArray[x].pos[2]
					vz = readshort f / 32767.0 * subMeshScaleArray[x].scale[3] + subMeshScaleArray[x].pos[3]
					vw = readshort f / 32767.0
					
					append Vert_Array([vx,vy,vz]*fscale)
				)
			)
			0x0f:(
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + buffer.skinnedVertBufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].vertCount do (
					vx = readshort f / 32767.0 * subMeshScaleArray[x].scale[1] + subMeshScaleArray[x].pos[1]
					vy = readshort f / 32767.0 * subMeshScaleArray[x].scale[2] + subMeshScaleArray[x].pos[2]
					vz = readshort f / 32767.0 * subMeshScaleArray[x].scale[3] + subMeshScaleArray[x].pos[3]
					vw = readshort f / 32767.0
					weight1 = readbyte f
					weight2 = readbyte f
					weight3 = readbyte f
					weight4 = readbyte f
					bone1 = readbyte f
					bone2 = readbyte f
					bone3 = readbyte f
					bone4 = readbyte f
					
					append Vert_Array([vx,vy,vz]*fscale)
					append Weight_Array[weight1,weight2,weight3,weight4]
					append Bone_Array[bone1,bone2,bone3,bone4]
				)
			)
			0x10:(
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + buffer.normalTextureVertBufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].vertCount do (
					normals = readlong f
					tu = readshort f / 32767.0 * subMeshUVScaleArray[x].ukw3
					tv = readshort f / 32767.0 * subMeshUVScaleArray[x].ukw3
					-- * subMeshUVScaleArray[x].ukw + subMeshUVScaleArray[x].ukw3
					
					append UV_array[tu,1-tv,0]
				)
			)
			0x30:(
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + buffer.ukwVertexOffset30 + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].vertCount do (
					normals = readlong f
					binormals = readlong f
					tu = readshort f #unsigned / 32767.0
					tv = readshort f #unsigned / 32767.0
					tu2 = readshort f #unsigned / 32767.0
					tv2 = readshort f #unsigned / 32767.0
					
					append UV_array[tu,1-tv,0]
				)
			)
			0x70:(
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + buffer.ukwVertexOffset70 + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].vertCount do (
					normals = readlong f
					binormals = readlong f 
					tangents = readlong f
					tu = readshort f #unsigned / 32767.0
					tv = readshort f #unsigned / 32767.0
					tu2 = readshort f #unsigned / 32767.0
					tv2 = readshort f #unsigned / 32767.0
					tu3 = readshort f #unsigned / 32767.0
					tv3 = readshort f #unsigned / 32767.0
					
					append UV_array[tu,1-tv,0]
				)
			)
			default:(
				format "unknown bufferType: %	bufferElmSize: %\n" (bit.intashex(bufferType as integer)) (bit.intashex(bufferElmSize as integer))
			)
		)
	)
	--format "\n"
	
	msh = mesh vertices:Vert_array faces:Face_Array
	msh.numTVerts = UV_array.count
	msh.wirecolor = random black white
  	msh.name = BNArr[subMeshNodeIdArr[x]].name
-- 	msh.name = (subMeshUVScaleArray[x].ukw as string + " " + subMeshUVScaleArray[x].ukw2 as string + " " + subMeshUVScaleArray[x].ukw3 as string + " " + subMeshUVScaleArray[x].ukw4 as string)
-- 	msh.name = (bit.intashex(ukwMeshTableArray[meshID].ukw3 as integer)) as string
-- 	msh.name = (bit.intashex(subMeshDataArray[x].skinCompoundID as integer))
-- 	msh.name = subMeshDataArray[x].nodeID as string
-- 	msh.name = (meshID as string) 
	
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	--for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	
	printhex subMeshDataArray[x].skinCompoundID
	
	if subMeshDataArray[x].nodeID != -1 do (
 		--msh.transform = BNArr[subMeshDataArray[x].nodeID + 1].transform
		--print BNArr[subMeshDataArray[x].nodeID + 1].name
	)
	if subMeshDataArray[x].skinCompoundID != 65535 do (	
		--BNArr[subMeshDataArray[x].skinCompoundID + 1].pos
		--msh.transform = BNArr[subMeshDataArray[x].skinCompoundID + 1].transform
	)
	
--  	msh.pos += subMeshScaleArray[x].pos
--  	msh.scale = subMeshScaleArray[x].scale
	
	msh.parent = BNArr[subMeshNodeIdArr[x]].parent
	msh.transform = BNArr[subMeshNodeIdArr[x]].transform
	--msh.transform *= (getnodebyname BNArr[subMeshNodeIdArr[x]].name).parent.transform
	--print msh.transform
)


Print ("Last Read @ "+((bit.intAsHex((ftell f) as integer))as string))
)
gc()
fclose f
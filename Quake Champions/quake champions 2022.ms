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
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
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

fname = GetOpenFileName caption:"" types:" (*.)|*.tpl" historyCategory:""
-- fname=@"E:\models\ripped\quake champions\mm_doom_marine.tpl"
-- fname=@"E:\models\ripped\quake champions\mm_bj_blazkovicz.tpl"
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
	ukw6 = (readbyte f #unsigned),
	ukw7 = (readshort f #unsigned),
	ukw8 = (readbyte f #unsigned),
	ukw9 = (readbyte f #unsigned)
)
struct meshData (
	bufferID = (readlong f #unsigned + 1),
	subBufferOffset = (readlong f #unsigned)	
)
struct ukwMeshTable (
	ukw = (readshort f #unsigned),		--0x45
	ukw2 = (readbyte f #unsigned),		--0x8b / 0x0b
	ukw3 = (readbyte f #unsigned),		--0x1f / 0x1c
	ukw4 = (readbyte f #unsigned),		--0x02
	ukw5 = (readshort f #unsigned),	--0x42
	ukw6 = (readshort f #unsigned),	--0x20
	ukw7 = (readbyte f #unsigned),		--0x00
	ukw8 = (readbyte f #unsigned)		--0x00 / 0x08 / 0x10
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
	ukw4 = readshort f		--0x00 / 0x01 / isHighestLod?
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
	ukw = (readlong f),				--0x04
	ukw2 = (readbyte f),				--0x0f
	subMeshIndex = (readlong f #unsigned+1),
	subMeshRangeCount = (readlong f),
	bbMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale),
	bbMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale),
	todo = (ReadFixedByteString f 0x3c 0 0)
)
struct mat (version,shadingMtl_Tex,shadingMtl_Mtl,mayaMtl,lm,layer0,layer1,layer2,extraParams,bs)
	struct mayaMtl (undefined)
	struct lm (source,texName,uvSetIdx,tangent)
		struct tangent (uvSetIdx)
	struct layer0 (texName,mtlName,tint,vcSet,tilingU,tilingV,blending,uvSetIdx)
	struct layer1 (texName,mtlName,tint,vcSet,tilingU,tilingV,blending,uvSetIdx)
	struct layer2 (texName,mtlName,tint,vcSet,tilingU,tilingV,blending,uvSetIdx)
		struct blending (method_from_parent,method,useLayerAlpha,useHeightmap,weightMultiplier,heightmapSoftness,texChannelBlendMask,weights,heightmap_,heightmapOverride,upVector,heightmapUVOverride,blendNormalAdd)
			struct weights (colorSetIdx)
			struct heightmap_ (colorSetIdx,invert_)
			struct upVector (angle_,enabled,falloff_)
			struct heightmapUVOverride (enabled,tilingU,tilingV,uvSetIdx)
	struct extraParams (reliefNormalmaps,auxiliaryTextures,transparency,extraVertexColorData,parallax,extraUVData)
		struct reliefNormalmaps (macro,micro1,micro2)
			struct macro (end,falloff_,isVisible,scale_,start,textureName,tilingU,tilingV,uvSetIdx)
			struct micro1 (end,falloff_,isVisible,scale_,start,textureName,tilingU,tilingV,uvSetIdx)
			struct micro2 (end,falloff_,isVisible,scale_,start,textureName,tilingU,tilingV,uvSetIdx)
		struct auxiliaryTextures (mask_)
			struct mask_ (textureName,tilingU,tilingV,uvSetIdx)
		struct transparency (colorSetIdx,dirtModifyAlpha,enabled,multiplier,sources,useBlendMaskAlpha)
		struct extraVertexColorData (colorA,colorB,colorG,colorR)
			struct colorA (colorSetIdx)
			struct colorB (colorSetIdx)
			struct colorG (colorSetIdx)
			struct colorR (colorSetIdx)
		struct parallax (baseLayerParallax,parallaxSettings,secondLayerParallax)
			struct baseLayerParallax (colorSetIdx,textureName,tilingU,tilingV,uvSetIdx)
			struct secondLayerParallax (colorSetIdx,textureName,tilingU,tilingV,uvSetIdx)
			struct parallaxSettings (enableSecondParallaxLayer,flatten,overrideSecondParallaxTexture)
				struct flatten (colorSetIdx)
		struct extraUVData (uvSetIdx)
	struct bs(dataTexName,idTexName,uvSetIdx)


struct dataType6 (
	ukw = (readlong f),
	ukw2 = (readfloat f)
)
struct _bone(
	tfm,
	pos
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
		"baseLayerParallax":(
			parent.baseLayerParallax = baseLayerParallax()
			for y=1 to data do (
				readMat mat parent.baseLayerParallax
			)
		)
		"blendNormalAdd":(
			parent.blendNormalAdd = data
		)
		"blending":(
			parent.blending = blending()
			for y=1 to data do (
				readMat mat parent.blending
			)
		)
		"bs":(
			parent.bs = bs()
			for y=1 to data do (
				readMat mat parent.bs
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
		"dataTexName":(
			parent.dataTexName = data
		)
		"dirtModifyAlpha":(
			parent.dirtModifyAlpha = data
		)
		"enabled":(
			parent.enabled = data
		)
		"enableSecondParallaxLayer":(
			parent.enableSecondParallaxLayer = data
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
		"extraUVData":(
			parent.extraUVData = extraUVData()
			for y=1 to data do (
				readMat mat parent.extraUVData
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
		"flatten":(
			parent.flatten = flatten()
			for y=1 to data do (
				readMat mat parent.flatten
			)
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
		"idTexName":(
			parent.idTexName = data
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
		"macro":(
			parent.macro = macro()
			for y=1 to data do (
				readMat mat parent.macro
			)
		)
		"mask":(
			parent.mask_ = mask_()
			for y=1 to data do (
				readMat mat parent.mask_
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
		"mayaMtl":(
			parent.mayaMtl = data
		)
		"method":(
			parent.method = data
		)
		"method from parent":(
			parent.method_from_parent = data
		)
		"mtlName":(
			parent.mtlName = data
		)
		"multiplier":(
			parent.multiplier = data
		)
		"overrideSecondParallaxTexture":(
			parent.overrideSecondParallaxTexture = data
		)
		"parallax":(
			parent.parallax = parallax()
			for y=1 to data do (
				readMat mat parent.parallax
			)
		)
		"parallaxSettings":(
			parent.parallaxSettings = parallaxSettings()
			for y=1 to data do (
				readMat mat parent.parallaxSettings
			)
		)
		"reliefNormalmaps":(
			parent.reliefNormalmaps = reliefNormalmaps()
			for y=1 to data do (
				readMat mat parent.reliefNormalmaps
			)
		)
		"secondLayerParallax":(
			parent.secondLayerParallax = secondLayerParallax()
			for y=1 to data do (
				readMat mat parent.secondLayerParallax
			)
		)
		"scale":(
			parent.scale_ = data
		)
		"sources":(
			parent.sources = data
		)
		"start":(
			parent.start = data
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
		"upVector":(
			parent.upVector = upVector()
			for y=1 to data do (
				readMat mat parent.upVector
			)
		)
		"useHeightmap":(
			parent.useHeightmap = data
		)
		"useBlendMaskAlpha":(
			parent.useBlendMaskAlpha = data
		)
		"useLayerAlpha":(
			parent.useLayerAlpha = data
		)
		"uvSetIdx":(
			parent.uvSetIdx = data
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

fn parentBones BNarr parentIDArr = (
	for x=1 to BNArr.count do (
		if parentIDArr[x] != -1 do (
 			BNArr[x].parent = BNArr[parentIDArr[x] + 1]
	-- 		BNArr[x].transform *= BNArr[x].parent.transform
		)
	)
-- 	for b in BNArr where b.parent==undefined do b.transform = (matrix3 [0,-1,0] [0,0,1] [-1,0,0] [0,0,0])
-- 	for b in BNArr do b.setskinpose()
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

_1SERtpl = ReadFixedString f 0x08
fseek f 0x34 #seek_cur
fseek f (readlong f) #seek_cur

TPL1 = ReadFixedString f 4
ukw = readlong f	--0x0c
ukw2 = readshort f
modelNameLength = readlong f
modelName = ReadFixedString f modelNameLength
ukw3 = readshort f		--0x1e
ukw4 = readlong f			--0x40
materialStringLength = readlong f
fseek f materialStringLength #seek_cur

matrixCount = readlong f
ukw5 = readlong f			--0x03
ukw6 = readlong f			--flags?

--skipping above, not always consistant
fseek f (findValLoc 0x4F474D31 f) #seek_set	--OGM1

OGM1 = ReadFixedString f 4
ukwFlags = readshort f	--flags?
ukw2 = readshort f		--0x02
ukw3 = readshort f		--0x03
ukw4 = readbyte f

nodeCount = readlong f
sectionCount = readlong f

printHex ukwFlags

BNArr=#()
boneNameArray=#()
nodeIDArr=#()
parentIDArr=#()
siblingIDArr=#()
siblingID2Arr=#()
childIDArr=#()
boneIDArr=#()
nodeNameArr=#()
exportNameArr=#()
ukwNodeTableArray=#()
boneInfoArray=#()
bitArr=#()
boundBoxArray=#()
bufferOffsetArray=#()

for x=1 to sectionCount do (
	isDataPresent = readbyte f
	if isDataPresent != 0 then (
		case x of (
			1:(		-- nodeIDArr
				for y=1 to nodeCount do append nodeIDArr (readshort f)
			)
			3:(		-- ukwNodeTableArray
				for y=1 to nodeCount do append ukwNodeTableArray (
					--ReadFixedByteString f 0x08 1 1
					table = ukwNodeTable()
				)
			)
			4:(		-- parentIDArr
				for y=1 to nodeCount do append parentIDArr (readshort f)
			)
			5:(		-- siblingIDArr
				for y=1 to nodeCount do append siblingIDArr (readshort f)
			)
			6:(		-- siblingID2Arr
				for y=1 to nodeCount do append siblingID2Arr (readshort f)
			)
			7:(		-- childIDArr
				for y=1 to nodeCount do append childIDArr (readshort f)
			)
			8:(		-- boneIDArr
				for y=1 to nodeCount do append boneIDArr (readshort f)
			)
			10:(		-- global matrices
				for y=1 to nodeCount do (
					b = _bone()
					
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
					
					b.tfm = tfm
					b.pos = ([m14,m24,m34] * tfm * fscale)
					append boneInfoArray b
				)
			)
			11:(		-- inverse matrices
				fseek f (nodeCount * 0x40) #seek_cur
			)
			12:(		-- boundBoxArray
				boundBoxCount = 0
				for y=1 to (ceil (nodeCount / 8.0)) do (	--wow im retarded, it was this simple
					byte = readbyte f
					for z=1 to 8 do (
						b = bit.get byte z
						if b == true and bitArr.count < nodeCount then (
							boundBoxCount += 1
							append bitArr 1
						)
						else if bitArr.count < nodeCount do (
							append bitArr 0
						)
					)
				)
				for y=1 to boundBoxCount do (					--should prob store in array to act as dictionary to nodes
-- 					ReadFixedByteString f 0x25 1 0
-- 					append boundBoxArray (_boundBox = boundBox())
					skipVer = readlong f
					if skipVer == 3 do (fseek f 0x21 #seek_cur)
					if skipVer == 4 do (fseek f 0x5d #seek_cur)
				)
			)
			13:(		-- boneNameHierarchy
				for y=1 to nodeCount do (boneNameHierarchy = ReadFixedString f (readlong f))
			)
			17:(		-- nodeNameArr
				for y=1 to nodeCount do append nodeNameArr (ReadFixedString f (readlong f))
			)
			18:(		-- exportNameArr
				for y=1 to nodeCount do append exportNameArr (ReadFixedString f (readlong f))
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
format "nodeCount: %	sectionCount: %	boundBoxCount: %\n" (bit.intashex(nodeCount)) (bit.intashex(sectionCount)) (bit.intashex(boundBoxArray.count))

if (bit.get ukwFlags 2) == true do (
	ukwCount = readlong f
	ukw7 = readbyte f
	for x=1 to ukwCount do (
		tableIndex = readlong f
		ukw = readlong f			--0x01
		ukw2 = readbyte f			--0x01
		ukw3 = readbyte f			--0x00
		ukw4 = readbyte f			--0x01
		ukw5 = readbyte f			--0x01
		ukw6 = readlong f
		
		if ukw6 == 1 do (
			ukw = readbyte f
			ukwCount = readlong f
			ukw2 = readbyte f
			
			for y=1 to ukwCount do (
				ukwString  = ReadFixedString f (readlong f)
			)
		)
	)
)
if (bit.get ukwFlags 1) == true do (
	ukw8 = readlong f				--0x01
	ukw9 = readbyte f				--0x01
	ukw10 = readlong f			--0x4c
	ukwStringLength = readlong f
	fseek f ukwStringLength #seek_cur
)
if (bit.get ukwFlags 3) == true do (
	boneNameCount = readlong f
	ukw12 = readbyte f
	for x=1 to boneNameCount do (
		append nodeNameArr (ReadFixedString f (readlong f))
	)
)
for x=1 to nodeCount do (
	b = boneInfoArray[x]
	
	newBone = bonesys.createbone	\
	b.tfm.row4	\
	(b.tfm.row4 + 0.01 * (normalize b.tfm.row1)) \
	(normalize b.tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = b.tfm
	newBone.pos = b.pos
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if nodeNameArr[x] != undefined do newBone.name = nodeNameArr[x]
	
	append BNArr newBone
)
parentBones BNArr parentIDArr
for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
-- for x=1 to nodeCount do (format "% % % % % % % %\n" bitArr[x] (paddstring 4 (bit.intashex(nodeIDArr[x] as integer))) (paddstring 4 (bit.intashex(boneIDArr[x] as integer))) (paddstring 4 (bit.intashex(parentIDArr[x] as integer))) (paddstring 4 (bit.intashex(ukwNodeTableArray[x].ukw2 as integer))) (paddstring 4 (bit.intashex(ukwNodeTableArray[x].ukw3 as integer))) (paddstring 2 (bit.intashex(ukwNodeTableArray[x].ukw4 as integer))) nodeNameArr[x])

chunkTag = readshort f						--0x00 / modelInfo
chunkEnd = readlong f						--points to 0x02 / bufferContainer

rootNodeIndex = readshort f				--h
nodeCount2 = readlong f					--same as nodeCount / usedNodes?
bufferCount = readlong f
meshCount = readlong f
subMeshCount = readlong f
ukw11 = readlong f							--0x01
null = readlong f

format "\nrootNodeIndex: %	nodeCount: %	bufferCount: %	meshCount: %	subMeshCount: %\n" (bit.intashex(rootNodeIndex as integer)) (bit.intashex(nodeCount2 as integer)) (bit.intashex(bufferCount as integer)) (bit.intashex(meshCount as integer)) (bit.intashex(subMeshCount as integer))

chunkTag = readshort f						--0x02 / bufferContainer
chunkEnd = readlong f						--points to 0x03 / meshContainer

chunkTag = readshort f						--0x00 / bufferType
chunkEnd = readlong f						--points to 0x01 / bufferElmSize

bufferTypeArray = for x=1 to bufferCount collect (ReadFixedByteString f 0x0a 1 0; type = bufferType())

chunkTag = readshort f						--0x04
chunkEnd = readlong f						--points to 0x01 / bufferElmSize
for x=1 to bufferCount do (ReadFixedByteString f 0x03 0 0)

chunkTag = readshort f						--0x01 / bufferElmSize
chunkEnd = readlong f						--points to 0x02 / bufferLength
bufferElmSizeArray = for x=1 to bufferCount collect (readshort f #unsigned)

chunkTag = readshort f						--0x02 / bufferLength
chunkEnd = readlong f						--points to 0x03 / bufferData
bufferLengthArray = for x=1 to bufferCount collect (readlong f #unsigned)

chunkTag = readshort f						--0x03 / bufferData
chunkEnd = readlong f						--points to 0x03 / meshContainer
for x=1 to bufferCount do (bufferOffsetArray[x] = ftell f; fseek f bufferLengthArray[x] #seek_cur)

chunkTag = readshort f						--0x03 / meshContainer
chunkEnd = readlong f						--points to 0x04 / subMeshContainer

chunkTag = readshort f						--0x02 / meshData
chunkEnd = readlong f						--points to 0x00 / meshFlagData
meshDataArray = for x=1 to meshCount collect ((for y=1 to (readbyte f) collect (data = meshData())))

chunkTag = readshort f						--0x00 / meshFlagData / same stucture as bufferType
chunkEnd = readlong f						--points to 0x04 / subMeshContainer
meshFlagArray=#()
--0x02	-	everything but crown on unholy paladin
--0x08	-	is skinned?, 0x08, 0x09, 0x0a always the same
--0x09	-	is skinned?
--0x0a	-	is skinned?
--0x17	-	head related
--0x1b	-	head hair?, 	0x20 is the same
--0x20	-	head hair?
--0x2e	-	everything but crown on unholy paladin
--0x44	-	armor related
--0x45 	-	head related

for x=1 to meshCount collect (
	flagString = ""
	flagArr = #()
	
	ReadFixedByteString f 0x0b 1 0;
	flagCount = readshort f
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
-- for x=1 to 1 do (
-- 	for y=1 to meshFlagArray[x].count do (
-- 		format "%	%\n" (bit.intashex(y)) (bit.intashex(meshFlagArray[x][y]))
-- 	)
-- )

chunkTag = readshort f						--0x04 / subMeshContainer
chunkEnd = readlong f						--points to file delimiter
	
chunkTag = readshort f						--0x00 / subMeshData
chunkEnd = readlong f						--points to 0x01 / meshID
subMeshDataArray=#()
for x=1 to subMeshCount do (
	ReadFixedByteString f 0x10 1 0
	append subMeshDataArray (data = subMeshData())
	ukwFlags = readlong f
	ukwFloats = for y=1 to 8 where (bit.get ukwFlags y == true) collect (	--never seen it higher than 3, doing 8 ust in case
		floats = [readfloat f, readfloat f]
	)
)
	
chunkTag = readshort f						--0x01 / meshID
chunkEnd = readlong f						--points to  0x08 / subMeshMaterialData
meshIDArray = for x=1 to subMeshCount collect (readlong f #unsigned + 1)--links subMesh to mesh

chunkTag = readshort f						--0x08 / subMeshMaterialData
chunkEnd = readlong f						--points to 0x03 / subMeshBoneMap
subMeshMatArray=#()
for x=1 to subMeshCount do (
	_mat = mat()
	subMeshMatArray[x] = readshort f	#unsigned + 1	--will change in the future to encompas rest of data / matNameID
	for y=1 to (readlong f) do (readMat _mat _mat)	--no parent
)


-- for x=1 to bufferCount do (
-- 	format "% %\n" (bit.intashex(bufferTypeArray[x].bufferType)) (bit.intashex(bufferElmSizeArray[x]))
-- )

chunkTag = readshort f						--0x03 / subMeshBoneMap
chunkEnd = readlong f						--points to 0x04 / subMeshUVScale
subMeshBoneMap = #()
for x=1 to subMeshCount do (
	if meshFlagArray[meshIDArray[x]][9] == 1 then (
		subMeshBoneMap[x] = (boneMap = for y=1 to (readbyte f) collect (readshort f))
	)
	else continue
)

chunkTag = readshort f						--0x04 / subMeshUVScale
chunkEnd = readlong f						--points to 0x05 / subMeshScale
-- printHex ((chunkEnd - (ftell f)) /  0x04)
-- subMeshUVScaleArray = for x=1 to subMeshCount collect (ReadFixedByteString f 4 1 0; subMeshUVScale = subMeshUVScaleData())
fseek f chunkEnd #seek_set				--inconsistant count?

chunkTag = readshort f						--0x05 / subMeshScale, sometimes one short and overflows past end of file
chunkEnd = readlong f						--points to delimiter
subMeshScaleArray=#()
for x=1 to subMeshCount do (
	if meshFlagArray[meshIDArray[x]][4] == 1 then (
		subMeshScaleArray[x] = (subMeshScale = subMeshScaleData())
	)
	else continue
)
fseek f chunkEnd #seek_set

chunkTag = readshort f						--delimiter
chunkEnd = readlong f						--points to end of file
if ((ftell f) == FileSize) do format "Reached end of file.\n\n"
format "\n"

for x=1 to subMeshCount do (
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	
	meshID = meshIDArray[x]
	for y=1 to meshDataArray[meshID].count do (
-- 		print meshDataArray[meshID][y]
		bufferType = bufferTypeArray[meshDataArray[meshID][y].bufferID].bufferType
		bufferElmSize = bufferElmSizeArray[meshDataArray[meshID][y].bufferID]
		bufferOffset = bufferOffsetArray[meshDataArray[meshID][y].bufferID]
		
-- 		if bufferType != 0x00 do for o in bufferFlags do format "%" o
-- 		if bufferType == 0x07 and bufferElmSize == 0x24 do for o in bufferFlags do format "%" o
-- 		format "\n"
		
		case bufferType of (
			0x00:(	--faces
				fseek f ((subMeshDataArray[x].faceOffset * bufferElmSize) + bufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].faceCount do (
					fa = readshort f #unsigned + 1 - subMeshDataArray[x].vertOffset
					fb = readshort f #unsigned + 1 - subMeshDataArray[x].vertOffset 
					fc = readshort f #unsigned + 1 - subMeshDataArray[x].vertOffset 
					
					append Face_array[fa,fb,fc]
				)
			)
			0x07:(	--pos skn nrm
-- 				format " % %\n" (bit.intashex(bufferType)) (bit.intashex(bufferElmSize))
-- 				format "\n"
				
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + bufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				if bufferElmSize == 0x1c do (
					for z=1 to subMeshDataArray[x].vertCount do (
						vx = readshort f / 32767.0
						vy = readshort f / 32767.0
						vz = readshort f / 32767.0
						vw = readshort f / 32767.0
						weight1 = readbyte f
						weight2 = readbyte f
						weight3 = readbyte f
						weight4 = readbyte f
						bone1 = readbyte f
						bone2 = readbyte f
						bone3 = readbyte f
						bone4 = readbyte f
						nx = readfloat f
						ny = readfloat f
						nz = readfloat f
						
						append Vert_Array([vx,vy,vz]*fscale)
					)
				)
				if bufferElmSize == 0x20 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						weight1 = readbyte f
						weight2 = readbyte f
						weight3 = readbyte f
						weight4 = readbyte f
						bone1 = readbyte f
						bone2 = readbyte f
						bone3 = readbyte f
						bone4 = readbyte f
						nx = readfloat f
						ny = readfloat f
						nz = readfloat f
						
						append Vert_Array([vx,vy,vz]*fscale)
					)
				)
				if bufferElmSize == 0x24 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						weight1 = readbyte f
						weight2 = readbyte f
						weight3 = readbyte f
						weight4 = readbyte f
						bone1 = readbyte f
						bone2 = readbyte f
						bone3 = readbyte f
						bone4 = readbyte f
						ukw = readlong f	--prob for dq skinning
						nx = readfloat f
						ny = readfloat f
						nz = readfloat f
						
						append Vert_Array([vx,vy,vz]*fscale)
					)
				)
			)
			0x0c:(	--pos
-- 				format " % %\n" (bit.intashex(bufferType)) (bit.intashex(bufferElmSize))
-- 				format "\n"
				
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + bufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				for z=1 to subMeshDataArray[x].vertCount do (
					vx = readshort f / 32767.0
					vy = readshort f / 32767.0
					vz = readshort f / 32767.0
					vw = readshort f / 32767.0
					
					append Vert_Array([vx,vy,vz]*fscale)
				)
			)
			0x0f:(	--pos skn
-- 				format " % %\n" (bit.intashex(bufferType)) (bit.intashex(bufferElmSize))
-- 				format "\n"
				
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + bufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				if bufferElmSize == 0x10 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						vx = readshort f / 32767.0
						vy = readshort f / 32767.0
						vz = readshort f / 32767.0
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
					)
				)
				if bufferElmSize == 0x14 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						vx = readshort f / 32767.0
						vy = readshort f / 32767.0
						vz = readshort f / 32767.0
						vw = readshort f / 32767.0
						weight1 = readbyte f
						weight2 = readbyte f
						weight3 = readbyte f
						weight4 = readbyte f
						bone1 = readbyte f
						bone2 = readbyte f
						bone3 = readbyte f
						bone4 = readbyte f
						ukw = readlong f	--dq skinning? idfk
						
						append Vert_Array([vx,vy,vz]*fscale)
					)
				)
				if bufferElmSize == 0x18 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						vw = readfloat f
						weight1 = readbyte f
						weight2 = readbyte f
						weight3 = readbyte f
						weight4 = readbyte f
						bone1 = readbyte f
						bone2 = readbyte f
						bone3 = readbyte f
						bone4 = readbyte f
						
						append Vert_Array([vx,vy,vz]*fscale)
					)
				)
			)
			0x10:(	--nrm uvs
-- 				format " % %\n" (bit.intashex(bufferType)) (bit.intashex(bufferElmSize))
-- 				format "\n"
				
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + bufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				if bufferElmSize == 0x08 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						normals = readlong f
						tu = readshort f / 32767.0
						tv = readshort f / 32767.0
						
						append UV_array[tu,1-tv,0]
					)
				)
				if bufferElmSize == 0x0c do (
					for z=1 to subMeshDataArray[x].vertCount do (
						normals = readlong f
						ukw = readlong f				--may me 4 elements?
						tu = readshort f / 32767.0
						tv = readshort f / 32767.0
						
						append UV_array[tu,1-tv,0]
					)
				)
				if bufferElmSize == 0x10 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						normals = readlong f
						ukw = readlong f				--may me 4 elements?
						ukw2 = readlong f
						tu = readshort f / 32767.0
						tv = readshort f / 32767.0
						
						append UV_array[tu,1-tv,0]
					)
				)
				if bufferElmSize == 0x18 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						fseek f 0x14 #seek_cur
						tu = readshort f / 32767.0	--prob half float
						tv = readshort f / 32767.0
						
						append UV_array[tu,1-tv,0]
					)
				)
				if bufferElmSize == 0x1c do (
					for z=1 to subMeshDataArray[x].vertCount do (
						fseek f 0x18 #seek_cur
						tu = readshort f / 32767.0	--prob half float
						tv = readshort f / 32767.0
						
						append UV_array[tu,1-tv,0]
					)
				)
				
			)
			0x30:(	--nrm nrm2 uvs uvs2
-- 				format " % %\n" (bit.intashex(bufferType)) (bit.intashex(bufferElmSize))
-- 				format "\n"
				
				fseek f ((subMeshDataArray[x].vertOffset * bufferElmSize) + bufferOffset + meshDataArray[meshID][y].subBufferOffset) #seek_set
				if bufferElmSize == 0x10 do (
					for z=1 to subMeshDataArray[x].vertCount do (
						normals = readlong f
						normals2 = readlong f
						tu = readshort f #unsigned / 32767.0
						tv = readshort f #unsigned / 32767.0
						tu2 = readshort f #unsigned / 32767.0
						tv2 = readshort f #unsigned / 32767.0
						
						append UV_array[tu,1-tv,0]
					)
				)
			)
			default:(
-- 				format "unknown bufferType: %	bufferElmSize: %\n" (bit.intashex(bufferType as integer)) (bit.intashex(bufferElmSize as integer))
			)
		)
	)
-- 	format "\n"
	
	msh = mesh vertices:Vert_array faces:Face_Array
	msh.numTVerts = UV_array.count
	msh.wirecolor = random black white
	msh.name = nodeNameArr[subMeshMatArray[x]]
-- 	msh.name = meshFlagArray[meshID][23] as string
-- 	msh.name = bufferFlags[1] as string
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	--for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	
	if subMeshScaleArray[x] != undefined do (
		msh.pos += subMeshScaleArray[x].pos * fscale
		msh.scale = subMeshScaleArray[x].scale
	)
	
-- 	delete BNArr[subMeshMatArray[x]]
-- 	BNArr[subMeshMatArray[x]] = msh
	msh.transform *= BNArr[subMeshMatArray[x]].transform
	msh.parent = BNArr[subMeshMatArray[x]].parent
)


Print ("Last Read @ "+((bit.intAsHex((ftell f) as integer))as string))
)
gc()
fclose f
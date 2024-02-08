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
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
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

fname = GetOpenFileName caption:"" types:" (*.bod)|*.bod" historyCategory:""
-- fname=@"C:\Users\Owner\Desktop\tlg\chara\skin\condora\condora_model.bod"
-- fname=@"C:\Users\Owner\Desktop\tlg\chara\skin\condora\condorl_skeleton.bod"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

ukw = readlong f	--1
ukw2 = readlong f	--0x15
dataOffset = readlong f
stringBufferOffset = readlong f
ukwOffset = readlong f
ukwOffset2 = readlong f	--same as before
dataCount = readlong f
dataCount2 = readlong f	--one less than before
ukw3 = readlong f	--count/length?

fseek f stringBufferOffset #seek_set
stringCount = readlong f
dataString = for x=1 to stringCount collect (ReadFixedString f (readlong f))
	
for x=1 to dataString.count do (
	format "% %\n" (bit.intashex(x-1)) dataString[x]
)
	
bPos=#()
bRot=#()

fseek f dataOffset #seek_set
for x=1 to dataCount do (--)
	dataType = dataString[readlong f + 1]
	dataName = dataString[readlong f + 1]
	ukw2 = readlong f	--2/delimiter?
	
	print (dataType + "	" + dataName)	--because i like it blue
-- 	printHere f
-- 	format "\n"
	while true do (--)
		dataTypeIndex = readlong f
		if dataTypeIndex == -1 do exit
		
		subDataType = dataString[dataTypeIndex + 1]
		subDataLength = readlong f
		subDataEnd = ((ftell f) + subDataLength)
		case subDataType of (--)	--langth of certain dataTypes vary / should check for but too lazy		
			"flags":(
				flags = dataString[readlong f + 1]
				format "%:	%\n" subDataType flags
			)
			"animDataBinds":(
				animDataBindsCount = readlong f
				format "%:	%\n" subDataType animDataBindsCount
				
				for y=1 to animDataBindsCount do (
					animDataBinds = dataString[readlong f + 1]
					animDataBinds2 = dataString[readlong f + 1]
					
 					format "%:	%	%\n" subDataType animDataBinds	animDataBinds2
				)
			)
			"animName":(
				animName = dataString[readlong f + 1]
				format "%:	%\n" subDataType animName
			)
			"assetName":(
				assetName = dataString[readlong f + 1]
				format "%:	%\n" subDataType assetName
			)
			"attributes":(
				attributesCount = readlong f
				
				_attributes=#()
				for y=1 to attributesCount do (
					null = readlong f
					_attributes[y] = dataString[readlong f + 1]
				)
				format "%:	%\n" subDataType _attributes
			)
			"auxBuf":(
				auxBuf = dataString[readlong f + 1]
				auxBuf2 = dataString[readlong f + 1]
				format "%:	%	%\n" subDataType auxBuf auxBuf2
			)
			"baseElemIndex":(
				baseElemIndex = readlong f
				format "%:	%\n" subDataType (bit.intashex(baseElemIndex))
			)
			"baseName":(
				baseName = dataString[readlong f + 1]
				format "%:	%\n" subDataType baseName
			)
			"baseRenderable":(
				baseRenderable = dataString[readlong f + 1]
				baseRenderable2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType baseRenderable baseRenderable2
			)
			"baseVertexIndex":(
				baseVertexIndex = readlong f
				format "%:	%\n" subDataType (bit.intashex(baseVertexIndex))
			)
			"batches":(
				batchesCount = readlong f
				format "%:	%\n" subDataType batchesCount
				
				for y=1 to batchesCount do (	--RenderBatch
					batches = dataString[readlong f + 1]
					batches2 = dataString[readlong f + 1]
					
 					format "%:	%	%\n" subDataType batches	batches2
				)
			)
			"bones":(
				bonesCount = readlong f
				
				_bones=#()
				for y=1 to bonesCount do (
					null = readlong f
					_bones[y] = dataString[readlong f + 1]
				)
				format "%:	%\n" subDataType _bones
			)
			"boneNames":(
				boneNamesCount = readlong f
				boneNames = for y=1 to boneNamesCount collect (dataString[readlong f + 1])
				format "%:	%\n" subDataType boneNames
			)
			"bindPoseMatrices":(
				bindPoseMatricesCount = readlong f
				for y=1 to bindPoseMatricesCount do (	--being lazy
					fseek f 0x40 #seek_cur
				)
				format "%:	%\n" subDataType bindPoseMatricesCount
			)
			"charaScale":(
				charaScale = readfloat f
				format "%:	%\n" subDataType charaScale
			)
			"children":(
				childrenCount = readlong f
				format "%:	%\n" subDataType childrenCount
				
				for y=1 to childrenCount do (
					children = dataString[readlong f + 1]
					children2 = dataString[readlong f + 1]
					
					format "%:	%	%\n" subDataType children children2
				)
			)
			"childSelection":(
				childSelection = readlong f
				format "%:	%\n" subDataType childSelection
			)
			"createCascadeBatchFlags":(
				createCascadeBatchFlags = dataString[readlong f + 1]
				format "%:	%\n" subDataType createCascadeBatchFlags
			)
			"data":(
				format "%:	\n" subDataType
			)
			"data_flag":(
				data_flag = dataString[readlong f + 1]
				format "%:	%\n" subDataType data_flag
			)
			"dataFormat":(
				dataFormat = dataString[readlong f + 1]
				format "%:	%\n" subDataType dataFormat
			)
			"elems":(
				elems = dataString[readlong f + 1]
				elems2 = dataString[readlong f + 1]
				format "%:	%	%\n" subDataType elems elems2
			)
			"endFrame":(
				endFrame = readlong f
				format "%:	%\n" subDataType endFrame
			)
			"entityFlags":(
				entityFlags = dataString[readlong f + 1]
				format "%:	%\n" subDataType entityFlags
			)
			"eventArg":(
				eventArg = readlong f
				format "%:	%\n" subDataType eventArg
			)
			"extBufs":(
				extBufsCount = readlong f
				for y=1 to extBufsCount do (
					extBufs = dataString[readlong f + 1]
					extBufs2 = dataString[readlong f + 1]
					
-- 					format "%:	%	%\n" subDataType extBufs	extBufs2
				)
				format "%:	%\n" subDataType extBufsCount
			)
			"extensions":(
				extensionsCount = readlong f
				format "%:	%\n" subDataType extensionsCount
				
				for y=1 to extensionsCount do (
					extensions = dataString[readlong f + 1]
					extensions2 = dataString[readlong f + 1]
					
					format "%:	%	%\n" subDataType extensions extensions2
				)
			)
			"format":(
				_format = dataString[readlong f + 1]
				format "%:	%\n" subDataType _format
			)
			"geometryBuf":(
				geometryBuf = dataString[readlong f + 1]
				geometryBuf2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType geometryBuf geometryBuf2
			)
			"geometryBuffer":(
				geometryBuffer = dataString[readlong f + 1]
				geometryBuffer2 = dataString[readlong f + 1]
				format "%:	%	%\n" subDataType geometryBuffer geometryBuffer2
			)
			"indirectBuf":(
				indirectBuf = dataString[readlong f + 1]
				indirectBuf2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType indirectBuf indirectBuf2
			)
			"instanceBuf2":(
				instanceBuf2 = dataString[readlong f + 1]
				instanceBuf2_2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType instanceBuf2 instanceBuf2_2
			)
			"instanceCtx":(
				instanceCtx = readlong f
				format "%:	%\n" subDataType instanceCtx
			)
			"isClosed":(
				_isClosed = readlong f
				format "%:	%\n" subDataType _isClosed
			)
			"objects":(
				objectsCount = readlong f
				for y=1 to objectsCount do (
					_objects = dataString[readlong f + 1]
					_objects2 = dataString[readlong f + 1]
					
					format "%:	%	%\n" subDataType _objects _objects2
				)
-- 				format "%:	%\n" subDataType extBufsCount
			)
			"parent":(
				parent = dataString[readlong f + 1]
				parent2 = dataString[readlong f + 1]
				format "%:	%	%\n" subDataType parent parent2
			)
			"num":(
				num = readlong f
				format "%:	%\n" subDataType (bit.intashex(num))
			)
			"numTris":(
				numTris = readlong f
				format "%:	%\n" subDataType (bit.intashex(numTris))
			)
			"marker":(
				marker = dataString[readlong f + 1]
				format "%:	%\n" subDataType marker
			)
			"modifierTarget":(
				modifierTarget = dataString[readlong f + 1]
				modifierTarget2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType modifierTarget modifierTarget2
			)
			"numVerts":(
				numVerts = readlong f
				format "%:	%\n" subDataType (bit.intashex(numVerts))
			)
			"numElems":(
				numElems = readlong f
				format "%:	%\n" subDataType (bit.intashex(numElems))
			)
			"numWeights":(
				numWeights = readlong f	--count
				format "%:	%\n" subDataType (bit.intashex(numWeights))
			)
			"parentEntity":(
				parentEntity = dataString[readlong f + 1]
				parentEntity2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType parentEntity parentEntity2
			)
			"position":(
				px = readfloat f
				py = readfloat f
				pz = readfloat f
				pw = readfloat f
				
				position = [px, py, pz]
				
				format "%:	%\n" subDataType position
			)
			"primType":(
				primType = readlong f
				format "%:	%\n" subDataType primType
			)
			"remoteAttach":(
				remoteAttach = dataString[readlong f + 1]
				format "%:	%\n" subDataType remoteAttach
			)
			"rotation":(
				rx = readfloat f
				ry = readfloat f
				rz = readfloat f
				rw = readfloat f
				
				_rotation = (quat rx ry rz rw)
				
				format "%:	%\n" subDataType _rotation
			)
			"scale":(
				sx = readfloat f
				sy = readfloat f
				sz = readfloat f
				sw = readfloat f
				
				_scale = [sx, sy, sz]
				
				format "%:		%\n" subDataType _scale
			)
			"skinCluster":(
				skinCluster = dataString[readlong f + 1]
				skinCluster2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType skinCluster skinCluster2
			)
			"shadingGroups":(
				shadingGroupsCount = readlong f
				for y=1 to shadingGroupsCount do (
					shadingGroups = dataString[readlong f + 1]
					shadingGroups2 = dataString[readlong f + 1]
					
-- 					format "%:	%	%\n" subDataType shadingGroups shadingGroups2
				)
				format "%:	%\n" subDataType shadingGroupsCount
			)
			"shadowGBuf":(
				shadowGBuf = dataString[readlong f + 1]
				shadowGBuf2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType shadowGBuf shadowGBuf2
			)
			"shapes":(
				shapesCount = readlong f
				for y=1 to shapesCount do (
					_shapes = dataString[readlong f + 1]
					_shapes2 = dataString[readlong f + 1]
					
-- 					format "%:	%	%\n" subDataType _shapes _shapes2
				)
				format "%:	%\n" subDataType shapesCount
			)
			"shapeIndex":(
				shapeIndex = readlong f
				format "%:	%\n" subDataType shapeIndex
			)
			"sklData":(
				sklData = dataString[readlong f + 1]
				sklData2 = dataString[readlong f + 1]
				
				format "%:	%	%\n" subDataType sklData sklData2
			)
			"start":(
				start = readlong f
				format "%:	%\n" subDataType (bit.intashex(start))
			)
			"startFrame":(
				startFrame = readlong f
				format "%:	%\n" subDataType startFrame
			)
			"stride":(
				stride = readlong f
				format "%:	%\n" subDataType (bit.intashex(stride))
			)
			"time":(
				time = readfloat f
				format "%:	%\n" subDataType time
			)
			"type":(
				type = dataString[readlong f + 1]
				format "%:	%\n" subDataType type
			)
			"verts":(
				verts = dataString[readlong f + 1]
				verts2 = dataString[readlong f + 1]
				format "%:	%	%\n" subDataType verts verts2
			)
			default:(
				format "%	%	%\n" (bit.intashex(ftell f as integer)) (bit.intashex(subDataLength)) subDataType
				fseek f subDataLength #seek_cur
			)
		)		
	)
	format "\n"
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
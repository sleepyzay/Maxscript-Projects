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
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
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
struct weight_data (
	boneids,weights
)

-- fname = GetOpenFileName caption:"" types:" (*.)|*.m3g" historyCategory:""
fname = @"D:\models\ripped\dead space mobile\models\isaac.m3g"
-- fname =@"C:\Users\Owner\Downloads\com.ea.deadspace-1.1.40-free-www.apkshub.com\assets\data\published\models\isaac.m3g"

If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileSize = getFileSize fname
clearlistener()
Global fscale=50
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _HeaderObject (undefined)
struct _AnimationController (undefined)
struct _AnimationTrack (undefined)
struct _Appearance (
	null = readlong f,	--prob count
	ukwObjectIndexArray = for x=1 to (readlong f) collect (readlong f),
	ukw = readlong f, 	--2
	null2 = readlong f,
	textureName = ReadFixedString f (readlong f),	--materialName?
	ukw2 = readlong f,	--0x259
	ukw3 = readlong f,		--0x10
	ukw4 = [(readfloat f),(readfloat f),(readfloat f),(readfloat f)],
	ukw5 = readlong f,
	null3 = readlong f,
	ukw6 = readlong f,
	null4 = readlong f,
	ukw7 = readbyte f,
	texture2DObjectIndexArray = for x=1 to (readlong f) collect (readlong f)
)
struct _GroupTransform (
	position	=	[readfloat f,readfloat f,readfloat f],
	scale		=	[readfloat f,readfloat f,readfloat f],
	rotation	=	(angleaxis (readfloat f) [(readfloat f),(readfloat f),(readfloat f)])
)
struct _Group (
	null = readlong f,
	ukwObjectIndexArray = for x=1 to (readlong f) collect (readlong f),
	groupName = (if (readlong f) == 1 do (null = readlong f; groupName = ReadFixedString f (readlong f))),
	groupTransform = (if (readbyte f) == 1 do (ReadFixedByteString f 0x28 1 0; groupTransform = _GroupTransform())),
	ukwArray = for x=1 to 9 collect (readbyte f),
	childrenObjectIndexArray = for x=1 to (readlong f) collect (readlong f)
)
struct _Image2D (
	ukw = readlong f,		--0x02
	ukw2 = readlong f,	--0x384
	texturePath = ReadFixedString f (readlong f),
	null = readlong f,
	fileString = ReadFixedString f (readlong f),
	ukw3 = readshort f,	--0x63
	ukw4 = readlong f,	--0x01
	ukw5 = readlong f,	--0x01
	null2 = readlong f,
	null3 = readlong f,
	ukw6 = readbyte f,
	ukw7 = readbyte f,
	ukw8 = readbyte f
)
struct _Texture2D (
	image2DObjectIndex = readlong f,
	blendColor = color (readbyte f) (readbyte f) (readbyte f) 255,
	blending = readbyte f,
	wrappingS = readbyte f,
	wrappingT = readbyte f,
	levelFilter = readbyte f,
	imageFilter = readbyte f
)
struct _TriangleStripArray (
	encoding = readbyte f #unsigned,
	indicesCount = readlong f,
	indicesOffset = ftell f		--more after indexBuffer but I don't need it to build the model
)
struct _IndexBuffer (
	isSubMesh = readlong f,		--maybe subMeshCount
	null = (if isSubMesh == 1 do null = readlong f),
	subMeshName = (if isSubMesh == 1 do subMeshName = ReadFixedString f (readlong f)),
	triangleStripArrayObjectIndex = readlong f,
	appearanceObjectIndex = readlong f
)
struct _Mesh (
	vertexBufferObjectIndex = readlong f,
	indexBufferObjectIndexArray = for x=1 to (readlong f) collect (readlong f)
)
struct _SkinnedMeshKeyframeSequenceGroup (
	keyframeSequenceObjectIndex = readlong f,
	groupObjectIndex = readlong f
)
struct _SkinnedMeshAnimation (
	animNameLength = readshort f,
	animName = readstring f,
	ukw = readfloat f,
	keyframeSequenceObjectIndexCount = readshort f,
	keyframeSequenceObjectIndexArray = for y=1 to keyframeSequenceObjectIndexCount collect (readlong f)
)
struct _SkinnedMesh (
	ukw = readlonglong f,				--1
	meshName = (ReadFixedString f (readlong f)),
	ukw2 = readbyte f,
	ukw3 = for x=1 to 9 collect (readbyte f),
	keyframeSequenceGroupArray = for x=1 to (readshort f) collect (goup = _SkinnedMeshKeyframeSequenceGroup()),
	skinnedMeshAnimationArray = for x=1 to (readshort f) collect (anim = _SkinnedMeshAnimation()),
	vertexBufferObjectIndex = readlong f,
	indexBufferObjectIndexArray = for x=1 to (readlong f) collect (readlong f),
	transformObjectIndex = readlong f,
	blendIndicesObjectIndex = readlong f,
	blendWeightsObjectIndex = readlong f,
	groupObjectIndexArray = for x=1 to (readlong f) collect (readlong f)	--usedBones?
)
struct _KeyframeSequence (
	interpolation = readbyte f #unsigned,
	repeatMode = readbyte f #unsigned,
	encoding = readbyte f #unsigned,
	duration = readlong f #unsigned,
	validRangeFirst = readlong f #unsigned,
	validRangeLast = readlong f #unsigned,
	componentCount = readlong f #unsigned,
	keyframeCount = readlong f #unsigned,
	keyframeOffset = ftell f
)
struct _VertexArray (
	componentSize = readbyte f,
	componentCount = readbyte f,
	encoding = readbyte f,
	vertexCount = readshort f,
	vertexOffset = ftell f
)
struct _texcoord (
	texcoordObjectIndex = readlong f #unsigned,
	texcoordBias = [readfloat f,readfloat f,readfloat f],
	texcoordScale = readfloat f
)
struct _VertexBuffer (
	defaultColor = (color (readbyte f) (readbyte f) (readbyte f) (readbyte f)),
	positionsObjectIndex = readlong f,
	positionBias = [readfloat f,readfloat f,readfloat f],
	positionScale = readfloat f,
	normalsObjectIndex = readlong f,
	colorsObjectIndex = readlong f,
	texcoordArray = for x=1 to (readlong f) collect (texcoord = _texcoord())
)

magic = readstring f
fileSize = readlong f
fileSize2 = readlong f

objArray=#()

objIndex = 0
while (ftell f) < FileSize do (
	ReadFixedByteString f 0x10 1 0
	objIndex += 1
	
	chunkOffset = ftell f
	chunkType = readbyte f
	chunkLength = readlong f
	chunkEnd = chunkOffset + chunkLength + 5
	
	case chunkType of (
		0x00:(		--header
			fseek f chunkEnd #seek_set
		)
		0x01:(		--animationController
			fseek f chunkEnd #seek_set
		)
		0x02:(		--animationTrack
			fseek f chunkEnd #seek_set
		)
		0x03:(		--appearance
			objArray[objIndex] = _Appearance()
			fseek f chunkEnd #seek_set
		)
		0x06:(		--compositingMode
			fseek f chunkEnd #seek_set
		)
		0x08:(		--polygonMode
			fseek f chunkEnd #seek_set
		)
		0x09:(		--group
			objArray[objIndex] = _Group()
			fseek f chunkEnd #seek_set
		)
		0x0a:(		--image2D
			fseek f 0x08 #seek_cur	--null
			objArray[objIndex] = _Image2D()
			
-- 			ReadFixedByteString f (chunkEnd - (ftell f)) 1 1
			fseek f chunkEnd #seek_set
		)
		0x0b:(		--triangleStripArray
			fseek f 0x0c #seek_cur	--null
			objArray[objIndex] = _TriangleStripArray()
			fseek f chunkEnd #seek_set
		)
		0x0e:(		--mesh
			fseek f 0x16 #seek_cur
			objArray[objIndex] = _Mesh()			
			fseek f chunkEnd #seek_set
		)
		0x10:(		--skinnedMesh
			fseek f 0x08 #seek_cur	--null
-- 			ReadFixedByteString f (chunkEnd - (ftell f)) 1 1
			objArray[objIndex] = _SkinnedMesh()
			fseek f chunkEnd #seek_set
		)
		0x11:(		--texture2D
			fseek f 0x0e #seek_cur
			objArray[objIndex] = _Texture2D()
			fseek f chunkEnd #seek_set
		)
		0x13:(		--keyframeSequence
			fseek f 0x0c #seek_cur	--null
			objArray[objIndex] = _KeyframeSequence()
			fseek f chunkEnd #seek_set
		)
		0x14:(		--vertexArray
			fseek f 0x0c #seek_cur	--null
			objArray[objIndex] = _VertexArray()
			fseek f chunkEnd #seek_set
		)
		0x15:(		--vertexBuffer
			fseek f 0x0c #seek_cur	--null
			objArray[objIndex] = _VertexBuffer()
			fseek f chunkEnd #seek_set
		)
		0x64:(		--indexBuffer
			fseek f 0x08 #seek_cur	--null
			objArray[objIndex] = _IndexBuffer()
			fseek f chunkEnd #seek_set
		)
		default:(
			format "unknown chunkType: % @ %\n" (bit.intashex(chunkType as integer)) (bit.intashex(chunkOffset as integer))
			fseek f chunkEnd #seek_set
		)
	)
	
  	--format "%	% %\n" (bit.intashex(objIndex as integer)) (bit.intashex(chunkType as integer)) (bit.intashex(chunkOffset as integer))
)

sliderTime = 0
for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
deleteKeys objects #allKeys
stopanimation()
numframes = 0
framerate = 30

for o in objArray where classof o == _SkinnedMesh do (	--sometimes there is more than 1 skinnedMesh
	skinnedMesh = o
	
	Vert_Array=#()
	UV_Array=#()
	Normal_Array=#()
	BlendIndices_Array=#()
	BlendWeight_Array=#()
	Weight_Array=#()
	
	print o
	
	for x=1 to o.skinnedMeshAnimationArray.count do (
		format "%	%\n" x o.skinnedMeshAnimationArray[x].animName
	)
	
	animSelect = 28
	for x=animSelect to animSelect do (	--o.skinnedMeshAnimationArray.count
		print o.skinnedMeshAnimationArray[x]
		for y=1 to o.skinnedMeshAnimationArray[x].keyframeSequenceObjectIndexCount do ( --boneCount
			boneName = objArray[o.keyframeSequenceGroupArray[y].groupObjectIndex].groupName			
			keyframeSequenceObject = objArray[o.skinnedMeshAnimationArray[x].keyframeSequenceObjectIndexArray[y]]
			
-- 			print boneName
			print keyframeSequenceObject
			
			if numframes < keyframeSequenceObject.duration do numframes = keyframeSequenceObject.duration
			
			fseek f keyframeSequenceObject.keyframeOffset #seek_set
			
			posArr=#()
			posTime=#()
			if keyframeSequenceObject.componentCount == 3 do (	--translation
				posBias = [readfloat f,readfloat f,readfloat f]
				posScale = [readfloat f,readfloat f,readfloat f]
				for z=1 to keyframeSequenceObject.keyframeCount do (
					posT = readlong f / framerate
					posX = readshort f #unsigned / 65535.0 * posScale.x + posBias.x
					posY = readshort f #unsigned / 65535.0 * posScale.y + posBias.y
					posZ = readshort f #unsigned / 65535.0 * posScale.z + posBias.z
					
					append posTime posT
					append posArr (point3 posX posY posZ)
				)
			)
			
			rotArr=#()
			rotTime=#()
			if keyframeSequenceObject.componentCount == 4 do (	--rotation
				rotBias = [readfloat f,readfloat f,readfloat f,readfloat f]
				rotScale = [readfloat f,readfloat f,readfloat f,readfloat f]
				
-- 				print rotBias
-- 				print rotScale
				
				for z=1 to keyframeSequenceObject.keyframeCount do (
					rotT = readlong f / framerate
					rotW = readshort f #unsigned / 65535.0 * rotScale.w + rotBias.w
					rotZ = readshort f #unsigned / 65535.0 * rotScale.z + rotBias.z
					rotY = readshort f #unsigned / 65535.0 * rotScale.y + rotBias.y
					rotX = readshort f #unsigned / 65535.0 * rotScale.x + rotBias.x
					
					rot = quat rotX rotY rotZ rotW
					
-- 					format "% % % %\n" rotx roty rotz rotw
--  					(print rotX * rotX + roty * roty + rotz * rotz + rotw * rotw)
					
					append rotTime rotT
					append rotArr rot
				)
				format "\n"
			)
			
			with animate on(
				for a=1 to rotArr.count do (
					b = getnodebyname boneName
					t = rotTime[a]
					q = rotArr[a]
					
					if (b!=undefined) then (
						at time t
							b.Controller.Rotation = inverse q
					)
				)
				for a=1 to posArr.count do (
					b = getnodebyname boneName
					t = posTime[a]
					p = posArr[a]
					
					if (b!=undefined) then (
						at time t
							b.Controller.Position = p * fscale
					)
				)
			)
			
-- 			format "\n"
		)
		format "\n"
	)
	animationRange = interval 0 (numFrames / framerate)

	
	/*
	usedBones = for p in skinnedMesh.groupObjectIndexArray collect (objArray[p].groupName)
	
	vertexBuffer = objArray[skinnedMesh.vertexBufferObjectIndex]

	positionsArray = objArray[vertexBuffer.positionsObjectIndex]
	fseek f positionsArray.vertexOffset #seek_set
	for x=1 to positionsArray.vertexCount do (
		vx = readshort f
		vy = readshort f
		vz = readshort f
		
		append Vert_Array([vx,vy,vz] * vertexBuffer.positionScale * fscale + vertexBuffer.positionBias * fscale)
	)
	
	texcoordArray = objArray[vertexBuffer.texcoordArray[1].texcoordObjectIndex]
	fseek f texcoordArray.vertexOffset #seek_set
	for x=1 to texcoordArray.vertexCount do (
		tu = readshort f
		tv = readshort f
		
		append UV_Array([tu,tv,0] * vertexBuffer.texcoordArray[1].texcoordScale + vertexBuffer.texcoordArray[1].texcoordBias)
	)
	
	if vertexBuffer.normalsObjectIndex != 0 do (
		normalsArray = objArray[vertexBuffer.normalsObjectIndex]
		fseek f normalsArray.vertexOffset #seek_set
		for x=1 to normalsArray.vertexCount do (
			nx = readbyte f
			ny = readbyte f
			nz = readbyte f
			
			append Normal_Array[nx,ny,nz]
		)
	)
	
	if vertexBuffer.colorsObjectIndex != 0 do (
		colorsArray = objArray[vertexBuffer.colorsObjectIndex]
		fseek f colorsArray.vertexOffset #seek_set
	)
	
	blendIndicesArray = objArray[skinnedMesh.blendIndicesObjectIndex]
	blendWeightArray = objArray[skinnedMesh.blendWeightsObjectIndex]
	for x=1 to positionsArray.vertexCount do (
		w = (weight_data boneids:#() weights:#())
		
		fseek f (blendIndicesArray.vertexOffset + (0x04 * (x - 1))) #seek_set
		bone1 = readbyte f #unsigned + 1
		bone2 = readbyte f #unsigned + 1
		bone3 = readbyte f #unsigned + 1
		bone4 = readbyte f #unsigned + 1
		
		fseek f (blendWeightArray.vertexOffset + (0x10 * (x - 1))) #seek_set
		weight1 = readfloat f
		weight2 = readfloat f
		weight3 = readfloat f
		weight4 = readfloat f
		
		maxweight = 0
		if(weight1 != 0) then
			maxweight = maxweight + weight1
		if(weight2 != 0) then
			maxweight = maxweight + weight2
		if(weight3 != 0) then
			maxweight = maxweight + weight3
		if(weight4 != 0) then
			maxweight = maxweight + weight4
		
		if(maxweight != 0) then (
			mxw = 255.0
			if(weight1 != 0) then (
				w1 = weight1 as float
				append w.boneids (bone1)
				append w.weights (w1 / mxw)
			)
			if(weight2 != 0) then (
				w2 = weight2 as float
				append w.boneids (bone2)
				append w.weights (w2 / mxw)
			)
			if(weight3 != 0) then (
				w3 = weight3 as float
				append w.boneids (bone3)
				append w.weights (w3 / mxw)
			)
			if(weight4 != 0) then (
				w4 = weight4 as float
				append w.boneids (bone4)
				append w.weights (w4 / mxw)
			)		
		)
		
		append Weight_Array w
	)
	
	for p in o.indexBufferObjectIndexArray do (
		Face_Array=#()
		indexBuffer = objArray[p]
		
		triangleStripArray = objArray[indexBuffer.triangleStripArrayObjectIndex]
		fseek f triangleStripArray.indicesOffset #seek_set
		if triangleStripArray.encoding == 0x81 do (
			for x=1 to triangleStripArray.indicesCount / 3 do (
				fa = readbyte f #unsigned + 1
				fb = readbyte f #unsigned + 1
				fc = readbyte f #unsigned + 1
				
				append Face_Array[fa,fb,fc]
			)
		)
		if triangleStripArray.encoding == 0x82 do (
			for x=1 to triangleStripArray.indicesCount / 3 do (
				fa = readshort f #unsigned + 1
				fb = readshort f #unsigned  + 1
				fc = readshort f #unsigned  + 1
				
				append Face_Array[fa,fb,fc]
			)
		)
		stripLengths = for x=1 to (readlong f) collect (readlong f)	--not needed to build model
		
		msh = mesh vertices:Vert_Array faces:Face_Array
		msh.numTVerts =UV_Array.count
		msh.wirecolor = random black white
		msh.name = indexBuffer.subMeshName
		buildTVFaces msh
		defaultVCFaces msh
		for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
		for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
		for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
		
		msh.transform = (getnodebyname objArray[o.transformObjectIndex].groupName).transform
		
		max modify mode
		select msh
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to usedBones.count do (
			maxbone = getnodebyname usedBones[i]
			if i != usedBones.count then
				skinOps.addBone skinMod maxbone 0
			else
				skinOps.addBone skinMod maxbone 1
		)
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_array.count do (skinOps.ReplaceVertexWeights skinMod i Weight_array[i].boneids Weight_array[i].weights)
		
		meshop.deleteisoverts msh		--lazy but effective
	)*/
)


Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
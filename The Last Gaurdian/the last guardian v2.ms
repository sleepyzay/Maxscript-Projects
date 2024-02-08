(--)
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

struct dataStringRef (
	type,
	name
)

struct _AnimationMarker (
	type,
	name,
	flags,
	time,
	startFrame,
	endFrame,
	marker,
	eventArg
)
struct _AttributeExt (
	type,
	name,
	parentEntity,
	AttributeBuf
)
struct _Bone (
	type,
	name,
	assetName,
	remoteAttach,
	entityFlags,
	parent,
	children,
	extensions,
	position,
	scale,
	rotation,
	rootRotation,
	rootPosition,
	rootScale
)
struct _Entity (
	type,
	name,
	assetName,
	remoteAttach,
	entityFlags,
	parent,
	children,
	extensions,
	position,
	scale,
	rotation
)
struct _FurEffectBuffer (
	type,
	name,
	parentEntity,
	buffers,
	hashIDs
)
struct _GeometryBuffer (
	type,
	name,
	format,
	verts,
	elems,
	auxBuf,
	extBufs,
	shapes
)
struct _MaterialDefinition (
	type,
	name,
	albedo,
	normal,
	specular,
	roughness,
	emissive,
	backlight,
	detailNormal,
	detailMask,
	bloomMask,
	color,
	texTilePan,
	uvSelect,
	specularIntensity,
	roughnessScale,
	bumpScale,
	emissiveIntensity,
	alphaThreshold,
	refractionAmount,
	refractionScale,
	incidenceAngleRampIntensity,
	incidenceAngleMaxIntensity,
	incidenceAngleRampRange,
	incidenceAngleYupCutoff,
	bloomIntensityOffset,
	detailTilePan,
	detailBumpScale,
	detailUvSelect,
	uvScrollSpeed,
	uvScrollSnap,
	blendType,
	renderPass,
	renderPriority,
	materialFlags,
	parallax,
	twoSidedFlip,
	extStreamFlags,
	layer,
	shader,
	customParamArray,
	customTextureArray,
	customTextureUsage,
	color2,
	wetSpecularIntensity,
	wetRoughnessScalema,
	wetBumpScale,
	color3,
	customDefinition,
	extraData
)
struct _Mesh (
	type,
	name,
	assetName,
	remoteAttach,
	entityFlags,
	parent,
	children,
	extensions,
	position,
	scale,
	rotation,
	isClosed
)
struct _PhysicsMeshBuffer (
	type,
	name,
	data
)
struct _PhysicsShapeRawMesh (
	type,
	name,
	translation,
	rotation,
	scale,
	inertiaFactor,
	centerOfMassOffset,
	attribValue,
	pbuf,
	meshIndex,
	physicsShapeIndex
)
struct _RawAnimationDataBind (
	type,
	name,
	animName,
	_attributes,
	data
)
struct _RenderBatch (
	type,
	name,
	material,
	materialDefinition,
	materialLocalDef,
	primType,
	start,
	numTris
)
struct _RenderExt (
	type,
	name,
	parentEntity,
	shapeIndex,
	geometryBuf,
	shadowGBuf,
	modifierTarget,
	instanceBuf2,
	indirectBuf,
	batches,
	baseVertexIndex,
	numVerts,
	baseElemIndex,
	numElems,
	layer,
	renderableFlags,
	decalId,
	category,
	cascadeFlagSunIndexMask,
	cascadeBatches,
	bboxMin,
	bboxMax
)
struct _RenderShape (
	type,
	name,
	baseVertexIndex,
	baseElemIndex,
	numVerts,
	numElems,
	shadingGroups
)
struct _RigidBodyExt (
	type,
	name,
	parentEntity,
	phase,
	active,
	selfFilter,
	targetFilter,
	nonContactGroup,
	shape,
	volumeFlags,
	impulseFlags,
	userFlags,
	motionType,
	useBodyQuality,
	mass,
	gravityFactor,
	linearDamping,
	angularDamping,
	maxLinearVelocity,
	maxAngularVelocity,
	inverseInertia,
	inverseInertiaRatio,
	restitution,
	friction,
	dynfric_coeff
)
struct _SceneRoot (
	type,
	name,
	assetName,	
	remoteAttach,	
	entityFlags,	
	parent,
	children,
	extensions,
	position,
	scale,
	rotation,
	childSelection,
	animDataBinds,
	geometryBuffer,
	baseName,
	instanceCtx,
	createCascadeBatchFlags
)
struct _ShadingGroup (
	type,
	name,
	start,
	numPrims,
	primType,
	material,
	materialDefinition
)
struct _Skeleton (
	type,
	name,
	assetName,
	remoteAttach,	
	entityFlags,
	parent,
	children,
	extensions,
	position,
	scale,
	rotation,
	bones,
	sklData,
	charaScale
)
struct _SkinCluster (
	type,
	name,
	boneNames,
	bindPoseMatrices,
	numWeights,
	weights,
	flags
)
struct _SkinMesh (
	type,
	name,
	parentEntity,
	shapeIndex,
	geometryBuf,
	shadowGBuf,
	modifierTarget,
	instanceBuf2,	
	indirectBuf,	
	batches,
	baseVertexIndex,
	numVerts,
	baseElemIndex,
	numElems,
	layer,
	renderableFlags,
	decalId,
	category,
	cascadeFlagSunIndexMask,
	cascadeBatches,
	bboxMin,
	bboxMax,
	skinCluster,
	baseRenderable,
	skinFlags,
	windEnabled,
	windAnimationEnabled,
	viewDistanceScaleRefMax,
	windRecvBoneName,
	windParams,
	morphRate
)
struct _StreamBuffer (
	type,
	name
)
struct _Texture (
	type,
	name
)
struct _VertexClusterParam (
	type,
	name,
	windInterp,
	windIntensity,
	windAnimMin,
	windAnimMax,
	windAnimIntensity,
	texSpeed,
	texScale,
	texAmount,
	texWindShift,
	texNoise,
	branchOffset,
	normalDecay,
	forceInterp,
	forceRadius,
	forceAmount,
	forceScale,
	forceNormalDecay
)
struct _WetModifier (
	type,
	name,
	parentEntity,
	flags,
	fadeLength,
	fadeLerp,
	fadeOffset,
	drySpeed,
	watchMotion,
	paintColor
)
struct _WindRecvExt	(
	type,
	name,
	parentEntity,
	Flags,
	Pos,
	Radius,
	IgnoreList,
	MaxStrength,
	SelfWind,
	ForceInterp,
	ForceScale,
	ForceMax
)

fn getObjStruct objType = (
	case objType of (
		"AnimationMarker":(return _AnimationMarker())
		"AttributeExt":(return _AttributeExt())
		"Bone":(return _Bone())
		"Entity":(return _Entity())
		"FurEffectBuffer":(return _FurEffectBuffer())
 		"GeometryBuffer":(return _GeometryBuffer())
		"MaterialDefinition":(return _MaterialDefinition())
		"Mesh":(return _Mesh())
		"PhysicsMeshBuffer":(return _PhysicsMeshBuffer())
		"PhysicsShapeRawMesh":(return _PhysicsShapeRawMesh())
		"RawAnimationDataBind":(return _RawAnimationDataBind())
		"RenderBatch":(return _RenderBatch())
 		"RenderExt":(return _RenderExt())
 		"RenderShape":(return _RenderShape())
		"RigidBodyExt":(return _RigidBodyExt())
		"SceneRoot":(return _SceneRoot())
 		"ShadingGroup":(return _ShadingGroup())
		"Skeleton":(return _Skeleton())
 		"SkinCluster":(return _SkinCluster())
		"SkinMesh":(return _SkinMesh())
 		"StreamBuffer":(return _StreamBuffer())
		"Texture":(return _Texture())
		"VertexClusterParam":(return _VertexClusterParam())
		"WetModifier":(return _WetModifier())
		"WindRecvExt":(return _WindRecvExt())
		default:(
			format "unknown obj type: %\n" objType
		)
	)
)
fn getObj objArr objName = (
	for o in objArr where o.name == objName do return o
-- 	for o in objArr where o.type == obj.type and o.name == obj.name do return o
)
fn getGeometryBuffer buffer = (
	bufferBaseName=""
	nameFilter = (filterstring buffer.name "/")
	if nameFilter.count > 0 do bufferBaseName = nameFilter[nameFilter.count]
	
	bufferPath = 	((getFileNamePath fname) + bufferBaseName + ".data")
	print bufferPath
	
	g = fopen bufferPath "rb"
	if (bufferPath!=undefined) and ((DoesFileExist bufferPath)==true) then (
		CDAT = ReadFixedString g 4
		ukw = readshort g
		ukw2 = readshort g
		bufferStride = readlong g
		bufferLength = readlong g
		
		case bufferStride of (
			0x20:(	--verts
				struct _VertBuffer (
					Vert_Array=#(),
					UV_Array=#(),
					Normal_Array=#()
				)
				
				vertBuffer = _VertBuffer()
				for x=1 to bufferLength / bufferStride do (
					vx = readfloat g
					vy = readfloat g
					vz = readfloat g
					nx = (readbyte g #unsigned / 255.0) * 2 - 1
					ny = (readbyte g #unsigned / 255.0) * 2 - 1
					nz = (readbyte g #unsigned / 255.0) * 2 - 1
					nw = readbyte g
					ukw = readlong g
					ukw2 = readlong g
					tu = readfloat g
					tv = readfloat g
					
					append vertBuffer.Vert_Array [vx,vy,vz]
					append vertBuffer.UV_Array [tu,1-tv,0]
					append vertBuffer.Normal_Array [nx,ny,nz]
				)
				
				return vertBuffer
			)
			0x08:(	--uv
				for x=1 to bufferLength / bufferStride do ()
			)
			0x02:(	--elems
				struct _faceBuffer (
					Face_Array=#()
				)
				
				faceBuffer = _faceBuffer()
				for x=1 to bufferLength / bufferStride / 3 do (
					fa = readshort g +1
					fb = readshort g +1
					fc = readshort g +1
					
					append faceBuffer.Face_array[fa,fc,fb]
				)
				
				return faceBuffer
			)
		)
		
		
	)
	else (
		format "unknown bufferPath: %\n" bufferPath
	)
	Print ("Last Read @ 0x"+((bit.intAsHex(ftell g))as string))
	fclose g
)

fname = GetOpenFileName caption:"" types:" (*.bod)|*.bod" historyCategory:""
-- fname=@"C:\Users\Owner\Desktop\tlg\chara\skin\boya\boya_model.bod"
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

objArr=#()
fseek f dataOffset #seek_set
for x=1 to dataCount do (
	objType = dataString[readlong f + 1]
	objName = dataString[readlong f + 1]
	ukw2 = readlong f	--2/delimiter?
	
	obj = getObjStruct objType
	obj.type = objType
	obj.name = objName
	
-- 	print objType
	while true do (
		dataStringIndex = readlong f
		if dataStringIndex == -1 do exit
		
		subObjType = dataString[dataStringIndex + 1]
		subObjLength = readlong f
		subObjEnd = ((ftell f) + subObjLength)
		
-- 		print subObjType
		case subObjType of (
			"animName":(
				obj.animName = dataString[readlong f + 1]
			)
			"assetName":(
				obj.assetName = dataString[readlong f + 1]
			)
			"attributes":(
				obj._attributes = #()
				
				attributesCount = readlong f
				for y=1 to attributesCount do (
					null = readlong f
					obj._attributes[y] = dataString[readlong f + 1]
				)
			)
			"animDataBinds":(
				obj.animDataBinds = #()
				
				animDataBindsCount = readlong f
				
				for y=1 to animDataBindsCount do (
					animDataBinds = dataStringRef()
					
					animDataBinds.type = dataString[readlong f + 1]
					animDataBinds.name = dataString[readlong f + 1]
					
 					append obj.animDataBinds animDataBinds
				)
			)
			"auxBuf":(
				obj.auxBuf = dataStringRef()
				
				obj.auxBuf.type = dataString[readlong f + 1]
				obj.auxBuf.name = dataString[readlong f + 1]
			)
			"baseName":(
				obj.baseName = dataString[readlong f + 1]
			)
			"baseElemIndex":(
				obj.baseElemIndex = readlong f
			)
			"baseVertexIndex":(
				obj.baseVertexIndex = readlong f
			)
			"bones":(
				bonesCount = readlong f
				
				obj.bones=#()
				for y=1 to bonesCount do (
					null = readlong f
					obj.bones[y] = dataString[readlong f + 1]
				)
			)
			"children":(
				obj.children = #()
				
				childrenCount = readlong f				
				for y=1 to childrenCount do (
					children = dataStringRef()
					
					children.type = dataString[readlong f + 1]
					children.name = dataString[readlong f + 1]
					
					append obj.children children
				)
			)
			"childSelection":(
				obj.childSelection = readlong f
			)
			"createCascadeBatchFlags":(
				obj.createCascadeBatchFlags = dataString[readlong f + 1]
			)
			"data":(
			)
			"elems":(
				obj.elems = dataStringRef()
				
				obj.elems.type = dataString[readlong f + 1]
				obj.elems.name = dataString[readlong f + 1]
			)
			"endFrame":(
				obj.endFrame = readlong f
			)
			"entityFlags":(
				obj.entityFlags = dataString[readlong f + 1]
			)
			"eventArg":(
				obj.eventArg = readlong f
			)
			"extBufs":(
				obj.extBufs = #()
				
				extBufsCount = readlong f
				for y=1 to extBufsCount do (
					extBufs = dataStringRef()
					
					extBufs.type = dataString[readlong f + 1]
					extBufs.name = dataString[readlong f + 1]
					
					append obj.extBufs extBufs
				)
			)
			"extensions":(
				obj.extensions = #()
				
				extensionsCount = readlong f				
				for y=1 to extensionsCount do (
					extensions = dataStringRef()
					
					extensions.type = dataString[readlong f + 1]
					extensions.name = dataString[readlong f + 1]
					
					append obj.extensions extensions
				)
			)
			"flags":(
				obj.flags = dataString[readlong f + 1]
			)
			"geometryBuffer":(
				obj.geometryBuffer = dataStringRef()
				
				obj.geometryBuffer.type = dataString[readlong f + 1]
				obj.geometryBuffer.name = dataString[readlong f + 1]
			)
			"marker":(
				obj.marker = dataString[readlong f + 1]
			)
			"numVerts":(
				obj.numVerts = readlong f
			)
			"numElems":(
				obj.numElems = readlong f
			)
			"parent":(
				obj.parent = dataStringRef()
				
				obj.parent.type = dataString[readlong f + 1]
				obj.parent.name = dataString[readlong f + 1]
			)
			"position":(
				px = readfloat f
				py = readfloat f
				pz = readfloat f
				pw = readfloat f
				
				obj.position = [px, py, pz]
			)
			"instanceCtx":(
				obj.instanceCtx = readlong f	--pretty sure is a count to something, probably a dataStringRef
			)
			"remoteAttach":(
				obj.remoteAttach = dataString[readlong f + 1]
			)
			"rootPosition":(
				px = readfloat f
				py = readfloat f
				pz = readfloat f
				pw = readfloat f
				
				obj.rootPosition = [px, py, pz]
			)
			"rootRotation":(
				rx = readfloat f
				ry = readfloat f
				rz = readfloat f
				rw = readfloat f
				
				obj.rootRotation = (quat rx ry rz rw)
			)
			"rootScale":(
				sx = readfloat f
				sy = readfloat f
				sz = readfloat f
				sw = readfloat f
				
				obj.rootScale = [sx, sy, sz]
			)
			"rotation":(
				rx = readfloat f
				ry = readfloat f
				rz = readfloat f
				rw = readfloat f
				
				obj.rotation = (quat rx ry rz rw)
			)
			"scale":(
				sx = readfloat f
				sy = readfloat f
				sz = readfloat f
				sw = readfloat f
				
				obj.scale = [sx, sy, sz]
			)
			"start":(
				obj.start = readlong f
			)
			"startFrame":(
				obj.startFrame = readlong f
			)
			"time":(
				obj.time = readfloat f
			)
			"verts":(
				obj.verts = dataStringRef()
				
				obj.verts.type = dataString[readlong f + 1]
				obj.verts.name = dataString[readlong f + 1]
			)
			default:(
-- 				format "%	%	%\n" (bit.intashex(ftell f as integer)) (bit.intashex(subObjLength)) subObjType
				fseek f subObjEnd #seek_set
			)
		)
	)
-- 	format "\n"
	append objArr obj
)

SceneRoot = (for o in objArr where classof o == _SceneRoot collect o)[1]
GeometryBuffer = getObj objArr SceneRoot.geometryBuffer.name
-- print GeometryBuffer.verts.name
-- print GeometryBuffer.elems.name
-- print GeometryBuffer.auxBuf.name



-- print (getObj objArr SceneRoot.animDataBinds[1].name)._attributes

vertBuffer = undefined
elemsBuffer = undefined
for o in SceneRoot.children do (
	case o.type of (
		"Mesh":(
			if vertBuffer == undefined do vertBuffer = getGeometryBuffer GeometryBuffer.verts
			if elemsBuffer == undefined do elemsBuffer = getGeometryBuffer GeometryBuffer.elems
			
			cMesh = (getObj objArr o.name)
			RenderExt = (getObj objArr cMesh.extensions[1].name)
			
			subVert_array = 		for y = (RenderExt.baseVertexIndex + 1) to (RenderExt.baseVertexIndex + RenderExt.numVerts) collect vertBuffer.Vert_Array[y] * fscale
			subNormal_array =	for y = (RenderExt.baseVertexIndex + 1) to (RenderExt.baseVertexIndex + RenderExt.numVerts) collect vertBuffer.Normal_Array[y]
			subUV_array = 			for y = (RenderExt.baseVertexIndex + 1) to (RenderExt.baseVertexIndex + RenderExt.numVerts) collect vertBuffer.UV_Array[y]
			subFace_array =		for y = ((RenderExt.baseElemIndex / 3) + 1) to ((RenderExt.baseElemIndex / 3) + (RenderExt.numElems / 3)) collect elemsBuffer.Face_Array[y]
			
			msh = mesh vertices:subVert_array faces:subFace_array
			msh.numTVerts = subUV_array.count
			msh.wirecolor = random black white
			msh.name = RenderExt.name
			buildTVFaces msh
			for j = 1 to subUV_array.count do setTVert msh j subUV_array[j]
			for j = 1 to subFace_array.count do setTVFace msh j subFace_array[j]
-- 			for j = 1 to subNormal_array.count do setNormal msh j subNormal_array[j]
		)
		"Skeleton":(
			cSkeleton = (getObj objArr o.name)
			
			BNArr=#()
			for b in cSkeleton.bones do (
				cBone = (getObj objArr b)
				
				tfm = inverse cBone.rootRotation as matrix3
				tfm.row4 = (cBone.rootPosition * fscale)
				
				newBone = bonesys.createbone	\
				tfm.row4	\
				(tfm.row4 + 0.01 * (normalize tfm.row1)) \
				(normalize tfm.row3)
				newBone.width  = 0.01
				newBone.height = 0.01
				newBone.transform = tfm
				newBone.setBoneEnable false 0
				newBone.wirecolor = yellow
				newbone.showlinks = true
				newBone.pos.controller      = TCB_position ()
				newBone.rotation.controller = TCB_rotation ()
				newBone.name = cBone.assetName
				newBone.parent = getNodeByName (getObj objArr cBone.parent.name).assetName
			)
		)
		default:(
			format "unparsed type: %\n" o.type
		)
	)
	
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
)
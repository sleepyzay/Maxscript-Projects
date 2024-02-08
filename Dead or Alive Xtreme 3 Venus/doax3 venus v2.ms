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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)  
fn ReadHalfFloat fstream = (
    hf=readshort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
return bit.intasfloat outputasfloat*2
)

fname = GetOpenFileName caption:"" types:" (*.)|*.tmc" historyCategory:""
gname = GetOpenFileName caption:"" types:" (*.)|*.tmcm" historyCategory:""

If (fname!=undefined) and ((DoesFileExist fname)==true) and (gname!=undefined) and ((DoesFileExist gname)==true) then (
f = fopen fname "rb"   --open file in read only format
g = fopen gname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct weight_data (
	boneids,weights
)

struct vertElment (
	stream,
	offset,
	type,
	usage,
	usageIndex
)

struct header (
	offset = ftell f,
	name = ReadFixedString f 0x08,
	flags = readlong f,
	headerLength = readlong f,
	length = readlong f,
	dataCount = readlong f, 
	dataCount2 = readlong f,
	dataCount3 = readlong f,
	dataOffset = readlong f + offset,
	dataOffset2 = readlong f + offset,
    dataOffset3 = readlong f + offset,
	null = readlong f
)
--define entire structure hierarchy
struct TMC (header, MdlGeo, TTNM, VtxLay, IdxLay, MtrCol, MdlInfo, HieLay, LHeader, NodeLay, GlblMtx, BnOfsMtx)
	struct MdlGeo (header, ObjGeo)
			struct ObjGeo (header, name, GeoDecl)
				struct GeoDecl (header, faceBufferCount, vertBufferCount, vertStride, vertElm, meshID)
	struct TTNM (header, TTNH,TTNL)
		struct TTNH (header)
		struct TTNL (header)
	struct VtxLay (header, vertBufferOffset, vertBufferLength)
	struct IdxLay (header, faceBufferOffset, faceBufferLength)
	struct MtrCol (header)
	struct MdlInfo (header)
	struct HieLay (header, matrix, parentID, pos)
	struct LHeader (header)
	struct NodeLay (header, NodeObj)
		struct NodeObj (header, boneName, boneID, boneMap, meshID)
	struct GlblMtx (header, matrix)
	struct BnOfsMtx (header, matrix)

--instance one layer at a time
TMC = TMC \
	header:		undefined \
	MdlGeo: 	(MdlGeo	header:undefined ObjGeo:#()) \
	TTNM: 		(TTNM 		header:undefined TTNH:undefined TTNL:undefined) \
	VtxLay:		(VtxLay		header:undefined vertBufferOffset:#() vertBufferLength:#()) \
	IdxLay: 	(IdxLay 	header:undefined faceBufferOffset:#() faceBufferLength:#()) \
	MtrCol: 		(MtrCol 	header:undefined) \
	MdlInfo: 	(MdlInfo 	header:undefined) \
	HieLay: 	(HieLay 	header:undefined matrix:#() parentID:#() pos:#()) \
	LHeader: 	(LHeader	header:undefined) \
	NodeLay:	(NodeLay	header:undefined NodeObj:#()) \
	GlblMtx: 	(GlblMtx	header:undefined matrix:#()) \
	BnOfsMtx: (BnOfsMtx	header:undefined matrix:#())

ukw6 = readlong g	--0x03/count?
resourceFileSize = readlong g
fseek g 0x08 #seek_cur	--null

vertDataOffset = ftell g
totalVertBufferCount = readlong g
totalVertBufferLength = readlong g
fseek g 0x08 #seek_cur
fseek g (vertDataOffset + totalVertBufferLength) #seek_set

faceDataOffset = ftell g
totalFaceBufferCount = readlong g
totalFaceBufferLength = readlong g
fseek g 0x08 #seek_cur
fseek g (faceDataOffset + totalFaceBufferLength) #seek_set

TMC.header = header()
fseek f 0x20 #seek_cur	--not important
mdlName = ReadFixedString f 0x10

fseek f TMC.header.dataOffset #seek_set
subChunkOffset = for x=1 to TMC.header.dataCount collect (readlong f #unsigned + TMC.header.offset)
for x=1 to TMC.header.dataCount do (
	fseek f subChunkOffset[x] #seek_set
	if subChunkOffset[x] > 0 do (
		chunk = header()
		
		case chunk.name of (
			"MdlGeo":(
				TMC.MdlGeo.header = chunk
				
				fseek f TMC.MdlGeo.header.dataOffset #seek_set
				objGeoOffset = for y=1 to TMC.MdlGeo.header.dataCount collect (readlong f #unsigned + TMC.MdlGeo.header.offset)
				for y=1 to TMC.MdlGeo.header.dataCount do (
					fseek f objGeoOffset[y] #seek_set
					TMC.MdlGeo.ObjGeo[y] = (ObjGeo header:undefined name:undefined GeoDecl:undefined)	--I think there's only one GeoDecl per MdlGeo
					TMC.MdlGeo.ObjGeo[y].header = header()
					
					fseek f 0x20 #seek_cur	--hopefully not important
					TMC.MdlGeo.ObjGeo[y].name = readstring f
					
					--subMesh/polyElm data?
					fseek f TMC.MdlGeo.ObjGeo[y].header.dataOffset #seek_set
					subMeshOffset = for z=1 to TMC.MdlGeo.ObjGeo[y].header.dataCount collect (readlong f #unsigned + TMC.MdlGeo.ObjGeo[y].header.offset)
					for z=1 to TMC.MdlGeo.ObjGeo[y].header.dataCount do (
						fseek f subMeshOffset[z] #seek_set
						ReadFixedByteString f 0xd0 1 0
						
						subMeshID = readlong f
						matID = readlong f
						null = readlong f
						ukwCount = readlong f	--subMatCount?/texCount?
						ukwOffset = readlong f + subMeshOffset[z]
						ukw = readlong f
						fseek f 0x48 #seek_cur	--null
						ukw2 = readlong f	--1
						ukw3 = readlong f	--5
						ukw4 = readlong f	--1
						ukw5 = readlong f	--0/1
						
						faceOffset = readlong f
						faceCount = readlong f
						vertOffset = readlong f
						vertCount = readlong f
						--more data but don't think i need it
						
						fseek f ukwOffset #seek_set
						for a=1 to ukwCount do (
							ReadFixedByteString f 0x70 0 0
						)
-- 						format "\n"
					)
					
					fseek f TMC.MdlGeo.ObjGeo[y].header.dataOffset3 #seek_set
					TMC.MdlGeo.ObjGeo[y].GeoDecl = GeoDecl header:undefined faceBufferCount:#() vertBufferCount:#() vertStride:#() vertElm:#() meshID:#()
					TMC.MdlGeo.ObjGeo[y].GeoDecl.header = header()
					
					fseek f TMC.MdlGeo.ObjGeo[y].GeoDecl.header.dataOffset #seek_set
					bufferOffset = for z=1 to TMC.MdlGeo.ObjGeo[y].GeoDecl.header.dataCount collect (readlong f #unsigned + TMC.MdlGeo.ObjGeo[y].GeoDecl.header.offset)
					for z=1 to TMC.MdlGeo.ObjGeo[y].GeoDecl.header.dataCount do (
						fseek f bufferOffset[z] #seek_set
						ReadFixedByteString f 0x70 1 0
						
						null = readlong f
						ukw = readlong f	--vertDataOffset?/0x30
						ukw2 = readlong f	--count?/0x01
						meshID = readlong f	+ 1 --meshID?/matID?
						faceBufferCount = readlong f
						vertBufferCount = readlong f
						ukwID2 = readlong f	+ 1 --matID?
						fseek f 0x14 #seek_cur	
						ukwID3 = readlong f	+ 1 --meshID?/matID?
						vertStride = readlong f
						vertElmCount = readlong f
						null = readlong f
						
						vertElm=#()
						for a=1 to vertElmCount do (
							ReadFixedByteString f 0x08 1 0
							append vertElm (
								vertexElment = (vertElment	\ 
									stream:			(readshort f) \
									offset: 			(readshort f) \
									type:			(readshort f) \
									usage: 			(readbyte f) \
									usageIndex: 	(readbyte f) \
								)
							)
						)
-- 						format "\n"
						
-- 						print vertElm
						
						TMC.MdlGeo.ObjGeo[y].GeoDecl.faceBufferCount[z] = faceBufferCount
						TMC.MdlGeo.ObjGeo[y].GeoDecl.vertBufferCount[z] = vertBufferCount
						TMC.MdlGeo.ObjGeo[y].GeoDecl.vertStride[z] = vertStride
						TMC.MdlGeo.ObjGeo[y].GeoDecl.vertElm[z] = vertElm
						TMC.MdlGeo.ObjGeo[y].GeoDecl.meshID[z] = meshID
					)
				)
			)
			"TTNM":(
				TMC.TTNM.header = chunk
				
				fseek f (TMC.TTNM.header.headerLength + TMC.TTNM.header.offset) #seek_set	--TTNH
				TMC.TTNM.TTNH = TTNH header:undefined
				TMC.TTNM.TTNH.header = header()
				
				fseek f TMC.TTNM.TTNH.header.dataOffset #seek_set
				gxtHeaderOffset = for y=1 to TMC.TTNM.TTNH.header.dataCount collect (readlong f #unsigned + TMC.TTNM.TTNH.header.offset)
				for y=1 to TMC.TTNM.TTNH.header.dataCount do (
					fseek f gxtHeaderOffset[y] #seek_set
					ReadFixedByteString f 0x50 1 0
					
					ukw = readlong f	--1
					gxtID = readlong f	--mipMapID?/textureID?
					fseek f 0x08 #seek_cur	--null
					
					fseek f 0x40 #seek_cur	--GXT header
				)
				
				fseek f TMC.TTNM.header.dataOffset3 #seek_set	--TTNL
			)
			"VtxLay":(
				TMC.VtxLay.header = chunk
				fseek f 0x10 #seek_cur	--null
				
				vertBufferCount = readlong f	--may be wrong
				vertBufferLength = readlong f
				
				fseek f TMC.VtxLay.header.dataOffset #seek_set
				TMC.VtxLay.vertBufferOffset = for y=1 to TMC.VtxLay.header.dataCount collect (readlong f #unsigned)
				
				fseek f TMC.VtxLay.header.dataOffset2 #seek_set
				TMC.VtxLay.vertBufferLength = for y=1 to TMC.VtxLay.header.dataCount2 collect (readlong f #unsigned)
			)
			"IdxLay":(
				TMC.IdxLay.header = chunk
				fseek f 0x10 #seek_cur	--null
				
				faceBufferCount = readlong f	--may be wrong
				faceBufferLength = readlong f
				
				fseek f TMC.IdxLay.header.dataOffset #seek_set
				TMC.IdxLay.faceBufferOffset = for y=1 to TMC.IdxLay.header.dataCount collect (readlong f #unsigned)
				
				fseek f TMC.IdxLay.header.dataOffset2 #seek_set
				TMC.IdxLay.faceBufferLength = for y=1 to TMC.IdxLay.header.dataCount2 collect (readlong f #unsigned)
			)
			"HieLay":(
				TMC.HieLay.header = chunk
				
				fseek f TMC.HieLay.header.dataOffset #seek_set
				matrixOffset = for y=1 to TMC.HieLay.header.dataCount collect (readlong f #unsigned + TMC.HieLay.header.offset)
				for y=1 to TMC.HieLay.header.dataCount do (
					fseek f matrixOffset[y] #seek_set
					ReadFixedByteString f 0x40 1 0
					
					m11 = Readfloat f; m12 = Readfloat f; m13 = Readfloat f; m14 = Readfloat f
					m21 = Readfloat f; m22 = Readfloat f; m23 = Readfloat f; m24 = Readfloat f
					m31 = Readfloat f; m32 = Readfloat f; m33 = Readfloat f; m34 = Readfloat f
					m41 = Readfloat f; m42 = Readfloat f; m43 = Readfloat f; m44 = Readfloat f
					TMC.HieLay.matrix[y] = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
					TMC.HieLay.parentID[y] = readlong f + 1
					TMC.HieLay.pos[y] = [m41,m42,m43]
					childIDCount = readlong f
					ukwID = readlong f + 1	--siblingID?
					null = readlong f
					childID = for z=1 to childIDCount collect (readlong f + 1)
				)
				
				fseek f TMC.HieLay.header.dataOffset3 #seek_set
			)
			"NodeLay":(
				TMC.NodeLay.header = chunk
				fseek f TMC.NodeLay.header.dataOffset #seek_set
				NodeObjOffset = for y=1 to TMC.NodeLay.header.dataCount collect (readlong f #unsigned + TMC.NodeLay.header.offset) 
				for y=1 to TMC.NodeLay.header.dataCount do (
					fseek f NodeObjOffset[y] #seek_set
					TMC.NodeLay.NodeObj[y] = (NodeObj header:undefined boneName:undefined boneID:undefined boneMap:undefined meshID:undefined)
					TMC.NodeLay.NodeObj[y].header = header()
					
					null = readlong f
					ukw = readlong f	--ff's
					TMC.NodeLay.NodeObj[y].boneID = readlong f #unsigned + 1
					null = readlong f
					TMC.NodeLay.NodeObj[y].boneName = readstring f
					
					fseek f TMC.NodeLay.NodeObj[y].header.dataOffset #seek_set
					if TMC.NodeLay.NodeObj[y].header.dataOffset > TMC.NodeLay.NodeObj[y].header.offset do (	--bone names match meshes'
						
						ukwDataOffset = for z=1 to TMC.NodeLay.NodeObj[y].header.dataCount collect (readlong f #unsigned + TMC.NodeLay.NodeObj[y].header.offset)
						for z=1 to TMC.NodeLay.NodeObj[y].header.dataCount do (
							fseek f ukwDataOffset[z] #seek_set
							ReadFixedByteString f 0x10 1 0
							
							TMC.NodeLay.NodeObj[y].meshID = readlong f #unsigned + 1
							boneMapCount = readlong f
							ukwIDCount2 = readlong f	--always 1 more than last
							null = readlong f
							
							fseek f 0x40 #seek_cur	--matrix
							
							TMC.NodeLay.NodeObj[y].boneMap = for a=1 to boneMapCount collect (readlong f #unsigned + 1)	--why is this here of all places?
						)
					)
				)
				
			)
			"GlblMtx":(
				TMC.GlblMtx.header = chunk
				
				fseek f TMC.GlblMtx.header.dataOffset #seek_set
				matrixOffset = for y=1 to TMC.GlblMtx.header.dataCount collect (readlong f #unsigned + TMC.GlblMtx.header.offset)
				for y=1 to TMC.GlblMtx.header.dataCount do (
					m11 = Readfloat f; m12 = Readfloat f; m13 = Readfloat f; m14 = Readfloat f
					m21 = Readfloat f; m22 = Readfloat f; m23 = Readfloat f; m24 = Readfloat f
					m31 = Readfloat f; m32 = Readfloat f; m33 = Readfloat f; m34 = Readfloat f
					m41 = Readfloat f; m42 = Readfloat f; m43 = Readfloat f; m44 = Readfloat f
					TMC.GlblMtx.matrix[y] = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
				)
			)
			default:(
-- 				format "%	0x%\n" chunk.name (bit.intashex(subChunkOffset[x] as integer))
			)
		)
	)
)

BNArr=#()
for x=1 to TMC.HieLay.header.dataCount do (
	pos = TMC.HieLay.pos[x]
	tfm = TMC.HieLay.matrix[x]
	boneName = TMC.NodeLay.NodeObj[x].boneName
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newBone.showlinks = false
	newBone.transform = tfm
	newBone.name = boneName
	
	newBone.pos = (pos*fscale)
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	append BNArr newBone
)
for x=1 to TMC.HieLay.header.dataCount do (
	parentID = TMC.HieLay.parentID[x]

	if parentID != 0 do (
		BNArr[x].parent = BNArr[parentID]
		BNArr[x].transform *= BNArr[parentID].transform
	)
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
delete rootRT

for y=1 to TMC.MdlGeo.ObjGeo.count do (	--modelCount
	for z=1 to TMC.MdlGeo.ObjGeo[y].GeoDecl.header.dataCount do (	--meshCount
		
		Vert_Array=#()
		UV_Array=#()
		UV_Array2=#()
		Face_Array=#()
		Normal_array=#()
		Weight_Array=#()
		blendIndicesArray=#()
		blendWeightArray=#()
		
		fseek g (TMC.VtxLay.vertBufferOffset[TMC.MdlGeo.ObjGeo[y].GeoDecl.meshID[z]] + vertDataOffset) #seek_set
		for a=1 to TMC.MdlGeo.ObjGeo[y].GeoDecl.vertBufferCount[z] do (			--verts
			vertRef = ftell g
			vertElm = TMC.MdlGeo.ObjGeo[y].GeoDecl.vertElm[z]
			for b=1 to vertElm.count do (
				fseek g (vertElm[b].offset + vertRef) #seek_set
				
				case vertElm[b].usage of (
					0x00:(	--position
						vx = readfloat g
						vy = readfloat g
						vz = readfloat g
						
						append Vert_Array([vx,vy,vz]*fscale)
					)
					0x01:(	--blendweight
						if vertElm[b].type == 03 do (	--float4?
							weight1 = readfloat g
							weight2 = readfloat g
							weight3 = readfloat g
							weight4 = readfloat g
							
							append blendWeightArray [weight1,weight2,weight3,weight4]
						)
						if vertElm[b].type == 13 do (	--ubyte4n?
							weight1 = readbyte g #unsigned
							weight2 = readbyte g #unsigned
							weight3 = readbyte g #unsigned
							weight4 = readbyte g #unsigned
							
							append blendWeightArray [weight1,weight2,weight3,weight4]
						)
					)
					0x02:(	--blendindices
						bone1 = readbyte g #unsigned + 1
						bone2 = readbyte g #unsigned + 1
						bone3 = readbyte g #unsigned + 1
						bone4 = readbyte g #unsigned + 1
						
						append blendIndicesArray [bone1,bone2,bone3,bone4]
					)
					0x03:(	--normal
						if vertElm[b].type == 0x03 do (	--float4
							nx = readfloat g
							ny = readfloat g
							nz = readfloat g
							nw = readfloat g
							
							append Normal_Array[nx,ny,nz]
						)
						if vertElm[b].type == 0x13 do (	--ubyte4n
							
							nx = readbyte g
							ny = readbyte g
							nz = readbyte g
							nw = readbyte g
							
							append Normal_Array[nx,ny,nz]
						)
					)
					0x05:(	--texcoord
						if vertElm[b].usageIndex == 0 do (
							tu = ReadHalfFloat g
							tv = ReadHalfFloat g
							
							append UV_Array[tu,1-tv,0]
						)
						if vertElm[b].usageIndex == 1 do (
							tu = ReadHalfFloat g
							tv = ReadHalfFloat g
							
							append UV_Array2[tu,1-tv,0]
						)
					)
					default:(
					)
				)
-- 				format "\n"
			)
			fseek g (vertRef + TMC.MdlGeo.ObjGeo[y].GeoDecl.vertStride[z]) #seek_set	--this might fuck me up
		)
		
		for a=1 to TMC.MdlGeo.ObjGeo[y].GeoDecl.vertBufferCount[z] do (			--blend weight/indices
-- 			format "%\n%\n\n" blendIndicesArray[a] blendWeightArray[a]
			w = (weight_data boneids:#() weights:#())
			
			bone1 = blendIndicesArray[a][1]
			bone2 = blendIndicesArray[a][2]
			bone3 = blendIndicesArray[a][3]
			bone4 = blendIndicesArray[a][4]
			
			weight1 = blendWeightArray[a][1]
			weight2 = blendWeightArray[a][2]
			weight3 = blendWeightArray[a][3]
			weight4 = blendWeightArray[a][4]
			
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
		
		fseek g (TMC.IdxLay.faceBufferOffset[TMC.MdlGeo.ObjGeo[y].GeoDecl.meshID[z]] + faceDataOffset) #seek_set
		for a=1 to TMC.MdlGeo.ObjGeo[y].GeoDecl.faceBufferCount[z] / 3 do (	--faces
			fa = readshort g #unsigned + 1
			fb = readshort g #unsigned + 1
			fc = readshort g #unsigned + 1
			
			append Face_Array[fa,fc,fb]
		)
		
		msh = mesh vertices:Vert_Array faces:Face_Array
		msh.numTVerts = UV_Array.count
		msh.wirecolor = random black white
		msh.name = TMC.MdlGeo.ObjGeo[y].name
		buildTVFaces msh
		for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
		for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
		msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		for o in TMC.NodeLay.NodeObj where o.meshID == TMC.MdlGeo.ObjGeo[y].GeoDecl.meshID[z] do (msh.transform = BNArr[o.boneID].transform)
		
		boneMap = (for o in TMC.NodeLay.NodeObj where o.meshID == y collect (o.boneMap))[1]	--y was TMC.MdlGeo.ObjGeo[y].GeoDecl.meshID[z]/HTM_OWN_SK_10_A_TMC broke it >:(
		
		-- Applying Skinning --
		count = msh.numverts
		max modify mode
		select msh
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to boneMap.count do (
		   maxbone = getnodebyname BNArr[boneMap[i]].name
		   skinOps.addBone skinMod maxbone 1
		)
		-- Applying Weights --
		select msh
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_Array.count do (
			w = Weight_Array[i]
			bi = #() --bone index array
			wv = #() --weight value array
			
			for j = 1 to w.boneids.count do
			(
				boneid = w.boneids[j]
				weight = w.weights[j]
				append bi boneid
				append wv weight
			)	
			
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)
		deselect msh
	)
-- 	format "\n"
)
Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
Print ("Last Read g @ 0x"+((bit.intAsHex(ftell g))as string))
)
gc()
fclose f
fclose g
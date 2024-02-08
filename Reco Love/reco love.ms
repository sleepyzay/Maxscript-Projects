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
fn reverseString s = (
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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)  
fname = GetOpenFileName caption:"" types:" (*.)|*.fed" historyCategory:""
-- fname=@"C:\Users\Owner\Desktop\models\reco love\models\data\00_chara\01_sagara\02_b_model\000_0_S_default\mdb_01sag_000_0_S_def_00.fed"
-- fname=@"D:\stuff\models\ripped\reco love\gold\8"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=10
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _FPACNTOD (
	dataOffset=#(),
	dataLength=#(),
	dataTableCount,
	dataStringCount,
	dataID=#(),
	dataID2=#(),
	dataName=#(),
	dataHash=#(),
	subData=#(),
	subDataBaseOffset
)
struct _subDataStruct (
	subDataCount,
	subDataOffset
)


FPAC = ReadFixedString f 8
tableCount = readshort f
ukw = readshort f	--fileVer?
null = readlong f

dataOffset=#()
dataLength=#()
for x=1 to tableCount do (
	dataOffset[x] = readlong f
	dataLength[x] = readlong f
-- 	format "offset: 0x%	length: 0x%\n" (bit.intashex(dataOffset[x])) (bit.intashex(dataLength[x]))
)

FPACNTOD = _FPACNTOD()

for x=1 to tableCount do (
	fseek f dataOffset[x] #seek_set
	dataType = ReadFixedString f 8
	dataCount = readshort f
	ukw = readshort f
	ukw2 = readlong f	--long/short flag?
	
	format "dataType: %	dataOffset: 0x% dataLength: 0x%	dataCount: 0x%\n" (dataType) (bit.intashex(dataOffset[x])) (bit.intashex(dataLength[x])) (bit.intashex(dataCount))

	case dataType of (
		"FPACTRAN":(	--multiple skeletons?
			
			nodeOffset=#()
			for y=1 to dataCount do (
				nodeOffset[y] = readshort f #unsigned + dataOffset[x]
				ukw = readshort f	--related to boneCount?
			)
			
			skelDelimiter=false
			BNArr=#()
			for y=1 to dataCount do (
				fseek f nodeOffset[y] #seek_set
				
				null = readshort f
				parentID = readshort f  + 1
				
-- 				if parentID == 0 and y > 1 do skelDelimiter = true
-- 				if skelDelimiter == true do exit
				
-- 				ReadFixedByteString f 0x0c 0 1
-- 				ReadFixedByteString f 0x0c 0 1
-- 				ReadFixedByteString f 0x0c 0 1
-- 				ReadFixedByteString f 0x0c 0 1
-- 				
-- 				format "\n"
-- 				fseek f -0x30 #seek_cur
				
				posX = readfloat f;		posY = readfloat f;		posZ = readfloat f
				ukwX = readfloat f;	ukwY = readfloat f;	ukwZ = readfloat f
				sclX = readfloat f;		sclY = readfloat f;		sclZ = readfloat f
				rotX = readfloat f;		rotY = readfloat f;		rotZ = readfloat f
				fseek f 0xc #seek_cur	--null
				
				print [ukwX, ukwY, ukwZ]
				
-- 				tfm = (quat 0 0 0 1) as matrix3
				tfm = ((eulerAngles (RadToDeg (rotX)) (RadToDeg (rotY)) (RadToDeg (rotZ))) as matrix3)
				
				newBone = bonesys.createbone	\
				tfm.row4	\
				(tfm.row4 + 0.01 * (normalize tfm.row1)) \
				(normalize tfm.row3)
				newBone.width  = 0.01
				newBone.height = 0.01
				newBone.transform = tfm
				newBone.setBoneEnable false 0
				newBone.wirecolor = white
				newbone.showlinks = true
				newBone.pos.controller      = TCB_position ()
				newBone.rotation.controller = TCB_rotation ()
				
				newBone.pos = ([posx, posy,posz]*fscale)
				
				if (parentID != 0) then(
					newBone.transform *= BNArr[parentID].objecttransform	
					newBone.parent = BNArr[parentID]
				)
				append BNArr newBone
			)
			rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
			for b in BNArr where b.parent==undefined do b.parent = rootRT
			rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		)
		
		"FPACGEOM":(
			struct _FPACGEOM (
				meshOffset=#(),
				meshLength=#(),
				FPACMESH=#()
			)
			
			FPACGEOM = _FPACGEOM()
			
			for y=1 to dataCount do (
				FPACGEOM.meshOffset[y] = readlong f #unsigned + dataOffset[x]
				FPACGEOM.meshLength[y] = readlong f #unsigned
				
-- 				format "meshOffset: %	meshLength: %\n" (bit.intashex(FPACGEOM.meshOffset[y])) (bit.intashex(FPACGEOM.meshLength[y]))
			)
			
			for y=1 to dataCount do (	--meshCount
				fseek f FPACGEOM.meshOffset[y] #seek_set
-- 				format "meshOffset: %	meshLength: %\n" (bit.intashex(FPACGEOM.meshOffset[y])) (bit.intashex(FPACGEOM.meshLength[y]))

				
				struct _FPACMESH(
					name,
					meshDataCount,
					ukw,
					meshDataOffset=#(),
					meshDataLength=#(),
					subMeshCount,
					ukw2
				)
				
				FPACMESH = _FPACMESH()
				
				Face_array=#()
				Vert_array=#()
				UV_Array=#()
				Normal_array=#()
				Weight_array=#()	
				blendIndicesArray=#()
				blendWeightArray=#()
				
				FPACMESH.name = ReadFixedString f 8
				FPACMESH.meshDataCount = readshort f
				FPACMESH.ukw = readshort f	--2
				null = readlong f
				
				for z=1 to FPACMESH.meshDataCount do (
					ReadFixedByteString f 0x08 1 0
					
					FPACMESH.meshDataOffset[z] = readlong f #unsigned
					FPACMESH.meshDataLength[z] = readlong f #unsigned
					
-- 					format "%	offset: 0x%	length: 0x%\n" z (bit.intashex(FPACMESH.meshDataOffset[z] + FPACGEOM.meshOffset[y])) (bit.intashex(FPACMESH.meshDataLength[z]))
				)
-- 				format "\n"
				
				for z=1 to FPACMESH.meshDataCount do (	--meshDataCount
					fseek f (FPACMESH.meshDataOffset[z] + FPACGEOM.meshOffset[y]) #seek_set
					
					case z of (
						0x01:(		--subMeshData?
							ReadFixedByteString f 0x1c 1 0
							
							fseek f 0x18 #seek_cur				--bound box data
							FPACMESH.subMeshCount = readshort f #unsigned	--data if zero with no available pointers / gotta figure out why
							FPACMESH.ukw2 = readshort f	--0x0004 or 0x0104
						)
						0x02:(		--subMeshes
							for b=1 to FPACMESH.subMeshCount do (	--baseMesh?
								ReadFixedByteString f 0x20 1 0
-- 								format "\n"
								Vert_Array=#()
								UV_Array=#()
								Normal_Array=#()
								Face_Array=#()
								
								faceCount = readshort f
								ukw = readshort f			--matID?
								vertStride = readlong f
								fseek f 0x08 #seek_cur	--null
								vertCount = readlong f
								fseek f 0x0c #seek_cur	--null
								
								/*
								0x1c	11100	vp vn vb vt
								0x18	11000	vp    vb vt
								0x08	01000	vp    vb

								04 03 02 01
								vt vb vn
								*/
								
								format "vertCount: 0x%	faceCount: 0x%\n" (bit.intashex(vertCount)) (bit.intashex(faceCount))
								printHere f
								for a=1 to vertCount do (						--vertices
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									
									append Vert_array([vx,vy,vz]*fscale)
								)
								AlignOffset  f (ftell f) 16
								
								if ((bit.get vertStride 3) == true) do (	--normals
									for a=1 to vertCount do (
										nx = readfloat f
										ny = readfloat f
										nz = readfloat f
										
										append Normal_array[nx,ny,nz]
									)
									AlignOffset  f (ftell f) 16
								)
								if ((bit.get vertStride 4) == true) do (	--binds
									for a=1 to vertCount do (	--not sure how this works
										bone1 = readbyte f #unsigned
										bone2 = readbyte f #unsigned
										bone3 = readbyte f #unsigned
										bone4 = readbyte f #unsigned
									)
									AlignOffset  f (ftell f) 16
								)
								if ((bit.get vertStride 5) == true) do (	--uv's
									for a=1 to vertCount do (
										tu = readfloat f
										tv = readfloat f
										
										append UV_Array[tu,-tv,0]
									)
									AlignOffset  f (ftell f) 16
								)
								
								for a=1 to (faceCount / 3) do (	--indices
									fa = readshort f #unsigned + 1
									fb = readshort f #unsigned + 1
									fc = readshort f #unsigned + 1
									
									append Face_Array[fa,fc,fb]
								)
								AlignOffset  f (ftell f) 16
								
								if UV_Array.count == 0 do (for x=1 to vertCount do append UV_Array [0,0,0])
								
								msh = mesh vertices:Vert_array faces:Face_Array
								msh.numTVerts = UV_Array.count
								msh.wirecolor = random black white
								msh.name = y as string
								buildTVFaces msh
								for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
								for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
				 				for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
								msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
							)
						)
						0x03:(		--verts
						)
						0x04:(		--normals
						)
						0x05:(		--colors?
						)
						0x06:(		--uv's
						)
						0x07:(		--bind id/weight info?
						)
						0x08:(		--faces
						)
						0x09:(
						)
					)
				)
				
			)
			
		)
		/*
		"FPACDRMS":(
			ukwOffset=#()
			for y=1 to dataCount do (
				ukwOffset[y] = readshort f + dataOffset[x]
				ukw = readshort f	
			)
			for y=1 to dataCount do (	--meshTransform?/parent info?
				fseek f ukwOffset[y] #seek_set
				
				meshID = readshort f
				boneID = readshort f
				fseek f 0x0c #seek_cur	--null
			)
		)
		*/
		/*
		"FPACMOR":(	--morphData?
			ukwOffset=#()
			ukwLength=#()
			for y=1 to dataCount do (
				ukwOffset[y] = readlong f + dataOffset[x]
				ukwLength[y] = readlong f
			)
			
			for y=1 to dataCount do (
				fseek f ukwOffset[y] #seek_set
				
				ukwID = readshort f
				ukwCount = readshort f
				ukwArr = for z=1 to ukwCount collect (readlong f)
			)
		)
		*/
		"FPACNTOD":(
			for y=1 to dataCount do (
				FPACNTOD.dataOffset[y] = readshort f + dataOffset[x]
				FPACNTOD.dataLength[y] = readshort f
			)
			
			for y=1 to dataCount do (
				fseek f FPACNTOD.dataOffset[y] #seek_set
				
				if y==1 do (
					FPACNTOD.dataTableCount = readshort f
					FPACNTOD.dataStringCount = readshort f	--same as before
					
					format "tableCount: %\n" (bit.intashex(FPACNTOD.dataTableCount))
					for z=1 to FPACNTOD.dataTableCount do (
						ReadFixedByteString f 0x0c 1 0
						
						FPACNTOD.dataID[z] = readshort f	#unsigned 	--0-bones/1-textures/2-materials?/3-meshes?/5-morphs?
						FPACNTOD.dataID2[z] = readshort f #unsigned	--local to dataID
						FPACNTOD.dataName[z] = getName f ((readlong f #unsigned) + FPACNTOD.dataOffset[y])
						FPACNTOD.dataHash[z] = readlong f #unsigned
						
						format "%	%	%	%	%\n" (z-1) FPACNTOD.dataID[z] FPACNTOD.dataID2[z] (bit.intashex(FPACNTOD.dataHash[z])) FPACNTOD.dataName[z]
					)
				)
				if y==2 do (
					ukw = readlong f	--short/long flag?
					printHere f
					subDataCountSum = 0
					for z=1 to 0x100 do (	--always the same?
						subDataStruct = _subDataStruct()
						
						subDataStruct.subDataCount = readshort f	--sum  equal to FPACNTOD.dataTableCount
						subDataStruct.subDataOffset = readshort f
						
-- 						append FPACNTOD.subData subDataStruct	--might boil this down to if count/offset isnt 0
						if subDataStruct.subDataCount != 0 do append FPACNTOD.subData subDataStruct
					)
					FPACNTOD.subDataBaseOffset = ftell f
				)
			)
			
			for y=1 to FPACNTOD.subData.count do (
				subData = FPACNTOD.subData[y]
				
				if subData.subDataCount != 0 do (	--redundant line, keeping it in anyways just incase
					fseek f (subData.subDataOffset + FPACNTOD.subDataBaseOffset) #seek_set
-- 					format "subDataOffset: %	subDataCount:	%\n" (bit.intashex(subData.subDataOffset + FPACNTOD.subDataBaseOffset as integer)) (bit.intashex(subData.subDataCount))
					
					dataHashRefArr = for z=1 to subData.subDataCount collect (readlong f #unsigned)
					dataIDRefArr = for z=1 to subData.subDataCount collect (readshort f #unsigned)
					
-- 					for o in dataHashRefArr do printHex o
-- 					print dataIDRefArr #nomap
-- 					format "\n"
				)
			)
		)
		default:(
-- 			print dataType
		)
	)
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
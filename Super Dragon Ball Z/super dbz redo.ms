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

fname = GetOpenFileName caption:"Super Dragon Ball Z" types:"Model (*.mdl)|*.mdl" historyCategory:"Super Dragon Ball Z"
-- fname =@"C:\Users\Owner\Desktop\New folder\ply\p01\p01a.mdl"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=1
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _header (
	offset = (ftell f),
	type = (ReadFixedString f 4),
	length = (readlong f),
	count = (readlong f)
)
struct _mat (
	float1 = (readfloat f),
	float2 = (readfloat f),
	float3 = (readfloat f),
	float4 = (readfloat f),
	float5 = (readfloat f),
	float6 = (readfloat f),
	float7 = (readfloat f),
	float8 = (readfloat f),
	texID = (readlong f),
	null =	(readlong f),
	null2 = (readlong f),
	null3 = (readlong f)
)
struct _FMDL (header,DMOD,XMTX,DMAT,XTEX,DHIE,XNON,XMON,XCUD)
	struct _DMOD (header,XMOD)
		struct _XMOD (header,Vert_Array=#(),Vert_Array2=#(),UV_Array=#(),Face_Array=#(),Normal_Array=#(),Normal_Array2=#(),Weight_array=#(),MatID_Array=#())
	struct _XMTX (header,boneMap)
	struct _DMAT (header,XMAT,XMAL)
		struct _XMAT (header,matData)
		struct _XMAL (header,matIDArray)
	struct _XTEX (header, texIDArray)
	struct _DHIE (header,XHIE,XTRE)
		struct _XHIE (header,boneOffset)
		struct _XTRE (header,ukwData)
	struct _XNON (header,stringArray)
	struct _XMON (header,stringArray)
	struct _XCUD (header)

fn readModel parent = (
	header = _header()
	case header.type of (
		"FMDL":(
			FMDL = _FMDL()
			FMDL.header = header
			ukw =	readlong f	--0x100
			
			fseek f 0x10 #seek_cur
			dataOffset = for x=1 to FMDL.header.count collect (readlong f + FMDL.header.offset)
			for o in dataOffset do (
				fseek f o #seek_set
				readModel FMDL
			)
			return FMDL
		)
		"DMOD":(
			parent.DMOD = _DMOD()
			parent.DMOD.header = header
			ukw =	readlong f
			ukw2 =	readlong f
			ukw3 =	readlong f
			ukw4 =	readlong f
			ukw5 =	readlong f
			dataOffset = for x=1 to parent.DMOD.header.count collect (readlong f + parent.DMOD.header.offset)
			for o in dataOffset do (
				fseek f o #seek_set
				readModel parent.DMOD
			)
		)
		"XMOD":(
			XMOD = _XMOD()
			XMOD.header = header
			
			ReadFixedByteString f 0x34 1 0
			vertType = readlong f		--vertType
			xmodIndex = readlong f
			ukw2 = readlong f			--2
			null = readlong f
			null2 = readlong f
			vertType2 = readlong f	--same as vertType
			ukw4 = readlong f			--2
			vertexDataLength = readlong f
			ukw5 = readlong f			--1
			vertTotal = readlong f
			faceTotal = readlong f
			subMeshCount = readlong f
			ukw9 = readlong f			--two shorts?
			
			fseek f (XMOD.header.offset + 0x40) #seek_set
			matIDArray = for z=1 to subMeshCount collect (readlong f #unsigned + 1)											--space for 32, unused spaces are 0x00's
			
			fseek f (XMOD.header.offset + 0xc0) #seek_set
			meshOffset = for z=1 to subMeshCount collect (readlong f #unsigned + XMOD.header.offset + 0x1a0)	--space for 32, unused spaces are 0xff's
			
			vertIndex = 0
			for z=1 to subMeshCount do (	--meshCount
				fseek f meshOffset[z] #seek_set
				
				ReadFixedByteString f 0x10 1 0
				vertBufferLength = readshort f #unsigned * 0x10
				ukw11 = readshort f	--0x60
				null4 = readlong f
				null5 = readlong f
				null6 = readlong f
				
				vertOffset = ftell f
				vertArrayCount = 0
				while (ftell f) < (vertOffset + vertBufferLength) do (
					ReadFixedByteString f 0x30 1 0
					
					fseek f 0x10 #seek_cur
					faceCount = readbyte f
					fseek f 0x0f #seek_cur
					vertCount = readbyte f
					fseek f 0x0f #seek_cur
-- 					printHere f
-- 					printHex vertType
-- 					format "\n"
					for x=1 to vertCount do (
						case vertType of (
							0x00:(	--no weights
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								vw = readlong f
								nx = readfloat f
								ny = readfloat f
								nz = readfloat f
								nw = readfloat f
								tu = readfloat f
								tv = readfloat f
								tw = readfloat f
								null = readlong f
								
								append XMOD.Vert_Array([vx,vy,vz,vw]*fscale)
								append XMOD.Normal_Array([nx,ny,nz])
								append XMOD.UV_Array[tu,1-tv,0]
							)
							0x01:(	--no weights
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								vw = readlong f
								nx = readfloat f
								ny = readfloat f
								nz = readfloat f
								nw = readfloat f
								tu = readfloat f
								tv = readfloat f
								tw = readfloat f
								null = readlong f
								
								append XMOD.Vert_Array([vx,vy,vz,vw]*fscale)
								append XMOD.Normal_Array([nx,ny,nz])
								append XMOD.UV_Array[tu,1-tv,0]
							)
							0x03:(	--has weights
								w = (weight_data boneids:#() weights:#())
								
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								vw = readlong f
								nx = readfloat f
								ny = readfloat f
								nz = readfloat f
								nw = readfloat f
								tu = readfloat f
								tv = readfloat f
								tw = readfloat f
								null = readlong f
								bone1 = (readlong f #unsigned / 4 ) + 1
								bone2 = (readlong f #unsigned / 4 ) + 1
								bone3 = (readlong f #unsigned / 4 ) + 1
								bone4 = (readlong f #unsigned / 4 ) + 1
								weight1 = readfloat f
								weight2 = readfloat f
								weight3 = readfloat f
								weight4 = readfloat f
								
								maxweight = 0
								if(bone1 != 0) then
									maxweight += weight1
								if(bone2 != 0) then
									maxweight += weight2
								if(bone3 != 0) then
									maxweight += weight3
								if(bone4 != 0) then
									maxweight += weight4
									
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
								
								append XMOD.Vert_Array([vx,vy,vz,vw]*fscale)
								append XMOD.Normal_Array([nx,ny,nz])
								append XMOD.UV_Array[tu,1-tv,0]
								append XMOD.Weight_array w
							)
							0x04:(	--incomplete
								w = (weight_data boneids:#() weights:#())
								
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								vw = readlong f
								fseek f 0x30 #seek_cur
								
								append XMOD.Vert_Array([vx,vy,vz,vw]*fscale)
								append XMOD.UV_Array[0,0,0]
							)
							0x0b:(	--no weights / has morphs
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								vw = readlong f
								nx = readfloat f
								ny = readfloat f
								nz = readfloat f
								nw = readfloat f
								tu = readfloat f
								tv = readfloat f
								tw = readfloat f
								null = readlong f
								vx2 = readfloat f	--morphs
								vy2 = readfloat f
								vz2 = readfloat f
								vw2 = readfloat f
								nx2 = readfloat f
								ny2 = readfloat f
								nz2 = readfloat f
								nw2 = readfloat f
								
								append XMOD.Vert_Array([vx,vy,vz,vw]*fscale)
								append XMOD.Vert_Array2([vx2,vy2,vz2,vw2]*fscale)
								append XMOD.Normal_Array([nx,ny,nz])
								append XMOD.Normal_Array2([nx2,ny2,nz2])
								append XMOD.UV_Array[tu,1-tv,0]
							)
							default:(
								format "uknown vertType:%\n" vertType
								exit
							)
						)
					)
					
					ukw12 = readlong f	--0x17
					null7 = readlong f
					null8 = readlong f
					null9 = readlong f
					
					vertArrayCount += vertCount
				)
				
				FaceDirection = 1
				newTri = false
				newTriVertCount = 0
				for x=1 to vertArrayCount do (
					vertFlag = XMOD.Vert_Array[x + vertIndex][4] as integer
					
					f1 = x - 2
					f2 = x - 1
					f3 = x
					
					if vertFlag == 0x8000 do newTri = true
					if newTri == true then (
						newTriVertCount += 1
						if newTriVertCount == 3 do (
							newTri = false
							FaceDirection = 1
							newTriVertCount = 0
							
							append XMOD.Face_Array ([f1,f2,f3] + vertIndex)
							append XMOD.MatID_Array matIDArray[z]
						)
					)
					else (			
						FaceDirection *= -1
						if FaceDirection > 0 then (
							append XMOD.Face_array ([f1,f2,f3] + vertIndex)
							append XMOD.MatID_Array matIDArray[z]
						)
						else (
							append XMOD.Face_array ([f1,f3,f2] + vertIndex)
							append XMOD.MatID_Array matIDArray[z]
						)
					)
				)
				vertIndex += XMOD.Vert_Array.count
			)
			
-- 			msh = mesh vertices:XMOD.Vert_array faces:XMOD.Face_array materialIDs:XMOD.MatID_Array
-- 			msh.numTVerts = XMOD.UV_array.count
-- 			msh.wirecolor = random black white
-- 			buildTVFaces msh
-- 			defaultVCFaces msh
-- 			for j = 1 to XMOD.UV_array.count do setTVert msh j XMOD.UV_array[j]
-- 			for j = 1 to XMOD.Face_array.count do setTVFace msh j XMOD.Face_array[j]
			
			if parent.XMOD == undefined do parent.XMOD = #()
			append parent.XMOD XMOD
		)
		"XMTX":(
			parent.XMTX = _XMTX()
			parent.XMTX.header = header
			
			fseek f 0x14 #seek_cur	--null
			parent.XMTX.boneMap=#()
			for y=1 to parent.XMTX.header.count do (				
				parent.XMTX.boneMap[y] = #()
				for z=1 to 32 do (
					boneMapID = readlong f #unsigned + 1
					if boneMapID != 0 do append parent.XMTX.boneMap[y] boneMapID
				)
			)
		)
		"DMAT":(
			parent.DMAT = _DMAT()
			parent.DMAT.header = header
			
			fseek f 0x14 #seek_cur	--null
			dataOffset = for x=1 to parent.DMAT.header.count collect (readlong f + parent.DMAT.header.offset)
			for o in dataOffset do (
				fseek f o #seek_set
				readModel parent.DMAT
			)
		)
		"XMAT":(
			parent.XMAT = _XMAT()
			parent.XMAT.header = header
			
			fseek f 0x14 #seek_cur
			parent.XMAT.matData = for x=1 to parent.XMAT.header.count collect (mat = _mat())
			print parent.XMAT.matData
		)
		"XMAL":(
			parent.XMAL = _XMAL()
			parent.XMAL.header = header
			
			fseek f 0x14 #seek_cur
			parent.XMAL.matIDArray=#()
			for y=1 to parent.XMAL.header.count do (				
				parent.XMAL.matIDArray[y] = #()
				for z=1 to 32 do (
					matID = readlong f #unsigned + 1
					if matID != 0 do append parent.XMAL.matIDArray[y] matID
				)
			)
		)
		"XTEX":(
			parent.XTEX = _XTEX()
			parent.XTEX.header = header
			
			fseek f 0x14 #seek_cur	--null
			parent.XTEX.texIDArray = for x=1 to parent.XTEX.header.count collect (readlong f #unsigned + 1)
			print parent.XTEX.texIDArray #nomap
		)
		"DHIE":(
			parent.DHIE = _DHIE()
			parent.DHIE.header = header
			
			fseek f 0x14 #seek_cur	--null
			dataOffset = for x=1 to parent.DHIE.header.count collect (readlong f + parent.DHIE.header.offset)
			for o in dataOffset do (
				fseek f o #seek_set
				readModel parent.DHIE
			)
		)
		"XHIE":(
			parent.XHIE = _XHIE()
			parent.XHIE.header = header
			
			fseek f 0x14 #seek_cur	
			parent.XHIE.boneOffset = ftell f
		)
		"XTRE":(
			parent.XTRE = _XTRE()
			parent.XTRE.header = header
			
			fseek f 0x14 #seek_cur	--null
			parent.XTRE.ukwData = for x=1 to parent.XTRE.header.count collect (readlong f)	--offset?
		)
		"XNON":(
			parent.XNON = _XNON()
			parent.XNON.header = header
			
			fseek f 0x14 #seek_cur	--null
			parent.XNON.stringArray = for x=1 to parent.XNON.header.count collect (readstring f)
		)
		"XMON":(
			parent.XMON = _XMON()
			parent.XMON.header = header
			
			fseek f 0x14 #seek_cur	--null
			parent.XMON.stringArray = for x=1 to parent.XMON.header.count collect (readstring f)
		)
		"XCUD":(
			parent.XCUD = _XCUD()	--collision?
			parent.XCUD.header = header
			
			fseek f 0x14 #seek_cur	--null
			for x=1 to parent.XCUD.header.count do (	--maps directly to meshCount
				ukw = readlong f	--1
				ukwFloat1 = readfloat f
				ukwFloat2 = readfloat f
				ukwFloat3 = readfloat f
				ukwFloat4 = readfloat f
				null = readlong f
				null2 = readlong f
				
-- 				format "% % % %\n" ukwFloat1 ukwFloat2 ukwFloat3 ukwFloat4
			)
		)
		default:(
			format "unparsed dataType: %\n" (header.type)
		)
	)
)

FMDL = readModel null

BNArr=#()
fseek f FMDL.DHIE.XHIE.boneOffset #seek_set
for x=1 to FMDL.DHIE.XHIE.header.count do (
	boneID = readlong f
	parentID = readlong f
	ukwID = readlong f	--siblingID?
	ukwID2 = readlong f	--siblingID?
		
	sx = readfloat f;	sy = readfloat f;	sz = readfloat f;	sw = readfloat f
	rx = readfloat f;	ry = readfloat f;	rz = readfloat f;	rw = readfloat f
	tx = readfloat f;	ty = readfloat f;	tz = readfloat f;	tw = readfloat f
	tfm = (eulerangles rx ry rz) as matrix3	
	tfm.row4 = ([tx,ty,tz]*fscale)
	
	if (parentID != -1) do (
		tfm *= BNArr[parentID + 1].objecttransform
	)
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width  = 0.01
	newBone.height = 0.01
	newBone.transform = tfm
	newBone.name = FMDL.XNON.stringArray[x]
	newBone.setBoneEnable false 0
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.pos.controller      = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if (parentID != -1) then(
		newBone.parent = BNArr[parentID + 1]
		--newBone.transform *= newBone.parent.transform
	)
	append BNArr newBone
)
for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
for b in BNArr do b.setskinpose()

multiMat = MultiMaterial numsubs:FMDL.DMAT.XMAT.header.count showInViewport:true
meditMaterials[1] = multiMat
for x=1 to multiMat.count do (
	XMAT = FMDL.DMAT.XMAT.matData[x]
	
	--multiMat[x].Diffuse = color (XMAT.float1 * 255.0) (XMAT.float2 * 255.0) (XMAT.float3 * 255.0) (XMAT.float4 * 255.0)
	multiMat[x].Diffuse = random black white
	multiMat[x].name = FMDL.DMAT.XMAT.matData[x].texID as string
)

for x=1 to FMDL.DMOD.XMOD.count do (
	
	XMOD = FMDL.DMOD.XMOD[x]
	
	--remapping  XMOD.MatID_Array
	MatID_Array = for o in XMOD.MatID_Array collect FMDL.DMAT.XMAL.matIDArray[x][o]
	
	msh = mesh vertices:XMOD.Vert_array faces:XMOD.Face_array materialIDs:MatID_Array
	msh.numTVerts = XMOD.UV_array.count
	msh.mat = multiMat
	msh.name = FMDL.XMON.stringArray[x]
	buildTVFaces msh
	defaultVCFaces msh
	for j = 1 to XMOD.UV_array.count do setTVert msh j XMOD.UV_array[j]
	for j = 1 to XMOD.Face_array.count do setTVFace msh j XMOD.Face_array[j]
	for j = 1 to XMOD.Normal_array.count do setNormal msh j XMOD.Normal_array[j]
	msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
	if XMOD.Weight_array.count == 0 do (for b in geometry where classof b == bonegeometry and b.name == msh.name do msh.transform = b.transform)
	for b in geometry where classof b == bonegeometry and b.name == msh.name do (
		msh.parent = b.parent
		for o in b.children do o.parent = msh
		delete b
	)
	
	if XMOD.Vert_Array2.count > 0 do (
		msh2 = mesh vertices:XMOD.Vert_array2 faces:XMOD.Face_array
		msh2.numTVerts = XMOD.UV_array.count
		buildTVFaces msh2
		defaultVCFaces msh2
		for j = 1 to XMOD.UV_array.count do setTVert msh2 j XMOD.UV_array[j]
		for j = 1 to XMOD.Face_array.count do setTVFace msh2 j XMOD.Face_array[j]
	 	for j = 1 to XMOD.Normal_array2.count do setNormal msh2 j XMOD.Normal_array[j]
		
		for b in geometry where classof b == bonegeometry and b.name == msh.children[1].name do (
			msh2.name = b.name
			msh2.transform = b.transform
			msh2.parent = b.parent
			delete b
		)
		
		MorphMod = morpher ()
		addModifier msh MorphMod
		msh.morpher.Autoload_of_targets = 1
		WM3_MC_BuildFromNode msh.morpher 1 msh2
		hide msh2
	)
	
	if XMOD.Weight_array.count > 0 do (
		max modify mode
		select msh
		skinMod = skin ()
		
		addModifier msh skinMod
		for i = 1 to FMDL.XMTX.boneMap[x].count do (
			maxbone = getnodebyname BNArr[FMDL.XMTX.boneMap[x][i]].name
			
			if i != FMDL.XMTX.boneMap[x].count then
				skinOps.addBone skinMod maxbone 0
			else
				skinOps.addBone skinMod maxbone 1
		)
		
 		-- Applying Weights --
		modPanel.setCurrentObject skinMod
		for i = 1 to XMOD.Weight_array.count do (
			w = XMOD.Weight_array[i]
   			skinOps.ReplaceVertexWeights skinMod i w.boneids w.weights
		)
	)
)
deselect $*


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
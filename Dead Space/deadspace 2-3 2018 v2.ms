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
fn ReadFixedByteString bstream fixedLen ret p = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   if ret == 1 do fseek bstream -fixedLen #seek_cur
   if p == 1 do print str
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
fn SplitLayout Split =(
	str=""
	j=0
	for i in Split do (
		j+=1
		if j >1 do (
			str += i
			if j != Split.count do str += "_" 
		)
	)
	str
)
fn skelPresent = (
	allBones = for o in geometry where classOf o == boneGeometry collect o
	if allBones.count > 0 then (
		return true
	)
	else (
		return false
	)
)

struct weight_data (
	boneids,weights
)

struct _polyInfo (
	vertCount,
	vertOffset,
	vertType,
	uvSize,
	faceCount,
	faceOffset,
	primType,
	matID,
	polyID,
	polyName
)

fname = GetOpenFileName caption:"Dead Space 2-3 Geometry" types:" (*.geo)|*.geo" historyCategory:"meshes"
-- fname=@"C:\Users\Xavier\Documents\stuff\projects\models\ripped\dead space 3\global_assets\global_assets\ds_assets\char_str\plyr\plyr_unfm\unievacontact_unpacked\Mesh\0154_generic_a1.geo"
-- fname=@"C:\Users\Xavier\Documents\stuff\projects\models\ripped\dead space 3\global_assets\global_assets\ds_assets\char_str\plyr\plyr_unfm\unievacontact_unpacked\Mesh\0160_mesh_body_bot_dism.geo"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FilePath = GetFilenamePath fname
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileSize = getFileSize fname
Leaf = pathConfig.removePathLeaf fname
ParentFolder = pathConfig.removePathLeaf Leaf

UVFolder = ParentFolder + "\MeshVolatile\\"
Split = filterString FileName "_"
UVID= ((Split[1] as number)+1)
Rest = SplitLayout (Split)
gname = (UVFolder + (paddstring 4 (UVID as string)) + "_" + Rest + ".geo")

clearlistener()
Global fscale=100
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)
	
if (skelPresent() == false) do (
	global BNArr=#()
	
	hname = GetOpenFileName caption:"Dead Space 2-3 Skeleton" types:" (*.rcb)|*.rcb.win" historyCategory:"skeleton"
	if (hname!=undefined) and ((DoesFileExist hname)==true) then (
		h = fopen hname "rb"   --open file in read only format
		
		boneNameOffset=#()
		boneNameLength=#()
		boneName=#()
		parentIDArr=#()
		boneNameOffsetArr=#()
		boneName=#()
		boneCount=#()
		boneIDTable=#()
		boneStart=#()
		
		fileLength = readlong h
		ukw =readlong h	--always 0x1a
		ukw2 = readlong h
		fseek h 0xc #seek_cur
		
		skelCount = readlong h	-- always 1, prob count
		dataOffset = readlong h
		ukw4 = readlong h	-- same as ukw 3
		dataOffset2 = readlong h
		fseek h 0x10 #seek_cur
		ukw5 = readlong h
		ukw6 = readlong h	-- same as ukw 4 and 3
		dataOffset3 = readlong h
		
		fseek h dataOffset #seek_set
		for x=1 to skelCount do (
			ukw7 = readlong h
			boneNameOffsetArr[x] = readlong h
			BoneCount[x] = readlong h
			BoneIDTable[x] = readlong h
			BoneStart[x] = readlong h
			ukwtableoffset = readlong h
			
			Print ("BoneStart @ 0x"+((bit.intAsHex(BoneStart[x]))as string))
			Print ("BoneCount @ 0x"+((bit.intAsHex(BoneCount[x]))as string))
		)
		
		for x=1 to skelCount do (
			boneName[x] = GetName h boneNameOffsetArr[x]
			print boneName[x]
		)
		
		for x=1 to skelCount do (
			boneParentID=#()
			
			fseek h boneIDTable[x] #seek_set
			for y=1 to boneCount[x] do (
				boneParentID[y] = readlong h + 1
				fseek h 0xc #seek_cur
			)
			parentIDArr[x] = boneParentID
		)
		
		for x=1 to 1 do (	--skelCount
			fseek h bonestart[x] #seek_set
			
			for y=1 to boneCount[x] do (
				
				m11 = readfloat h; m12 = readfloat h; m13 = readfloat h; m14 = readfloat h
				m21 = readfloat h; m22 = readfloat h; m23 = readfloat h; m24 = readfloat h
				m31 = readfloat h; m32 = readfloat h; m33 = readfloat h; m34 = readfloat h
				m41 = readfloat h; m42 = readfloat h; m43 = readfloat h; m44 = readfloat h
				tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
				
				newBone = bonesys.createbone	\
				tfm.row4	\
				(tfm.row4 + 0.01 * (normalize tfm.row1)) \
				(normalize tfm.row3)
				newBone.width = 0.1
				newBone.height = 0.1
				newBone.wirecolor = orange
				newbone.showlinks = true
				newBone.transform = inverse tfm
				
				pos = [m41,m42,m43]
				pos = pos * tfm
				
				newBone.pos.x += ((fscale)*pos.x)
				newBone.pos.y += ((fscale)*pos.y)
				newBone.pos.z += ((fscale)*pos.z)	
				
				newBone.setBoneEnable false 0
				newBone.pos.controller = TCB_position ()
				newBone.rotation.controller = TCB_rotation ()
				
				if (parentIDArr[x][y] != 0) then (
					newBone.parent = BNArr[parentIDArr[x][y]]
				)
				else (
					newbone.name = boneName[x]
				)
				append BNArr newBone
			)
			for b in BNArr where b.parent==undefined do b.transform = (matrix3 [-1,0,0] [0,0,-1] [0,1,0] [0,0,0])
			for b in BNArr where b.children.count == 0 do b.wirecolor = green
		)
		
		Print ("Last Read @ 0x"+((bit.intAsHex(ftell h))as string))
	)
)

magic = readfixedstring f 4
ukw = readlong f	-- always 0x32
ukw2 = readlong f	-- always 0x3
fileSizeZ = readlong f	--if fileSize included size of uv file
fseek f 0x10 #seek_cur	-- bunch of shit

modelNameOffset = readlong f #unsigned
ukw3 = readlong f
fseek f 0xc #seek_cur	--null

tableCount = readlong f
boneCount = readlong f
fseek f 0xc #seek_cur	-- look at later, may be important

refTableCount=readlong f	--don't know what its's actually called. It's a list of all of the offsets in which you'll reference in the future and the offsets that point to them.
refTableOffset=readlong f

dataTable=readlong f
boundBoxTable=readlong f
fseek f 0x08 #seek_cur	--null

boneMapOffset=readlong f	-- looks like uv's
null = readlong f
vertBufferData=readlong f
faceBufferData=readlong f

fseek f 0x9c #seek_set
localUVOffset = readlong f

extUV = false
if localUVOffset == FileSize then (
	extUV = true
	g = fopen gname "rb"
)
else (
	print "Local Texture Coordinates"
)

-- boneMap=#()
-- fseek f boneMapOffset #seek_set
-- for x=1 to boneCount do (
-- 	hash = readlong f
-- 	boneMap[x] = readlong f #unsigned 
-- )
-- print boneMap

meshName=#()
vertOffset=#()
vertOffsetRef=#()
vertCount=#()
vertType=#()
faceOffset=#()
faceOffsetRef=#()
faceCount=#()
primType=#()
uvSize=#()
boneMapCount=#()
boneMapOffset=#()
fseek f dataTable #seek_set
printHere f
for x=1 to tableCount do (
	meshName[x] = getName f (readlong f)
	ukw = readbyte f
	ukw2 = readbyte f
	ukw3 = readbyte f
	ukw4 = readbyte f		--something to do with uv's
	ukw5 = readlong f
	ukwArr = for y=1 to 5 collect (readfloat f)
	bbOffset = readlong f
	ukw6 = readbyte f		--always 0xff, offset 0x24 of table
	boneMapCount[x] = readbyte f
	ukw7 = readbyte f		--vert stride?
	uvSize[x] = readbyte f
	ukw8 = readshort f
	ukw9 = readshort f	--always 0xfeff
	null = readlong f	
	faceCount[x] = readlong f 
	faceOffsetRef[x]=readlong f
	vertCount[x] = readshort f --	offset 0x38 of table
	vertOffsetRef[x] = readshort f
	primType[x] = readshort f
	ukw8 = readshort f				-- looks like an offset
	preVertTotal = readshort f		-- if first of index then 0
	vertTotal = readshort f + 1			-- updated per index
	boneMapOffset[x] =readlong f
	fseek f 0x1c #seek_cur		-- null
	ReadFixedByteString f 0xc 1 1
	vertType[x] = readlong f + 2
	ukw10 = readlong f
	polyID = readlong f + 1
	ukw11 = readlong f
	fseek f 0x10 #seek_cur		--null
	vertOffset[x] = readlong f 
	faceOffset[x] = readlong f 
	fseek f 0x20 #seek_cur		--null
	ukwArr3 = for y=1 to 5 collect readfloat f --mat info?
		
-- 	print polyID
-- 	printHex preVertTotal
-- 	printHex VertTotal
-- 	printHex ukw8
-- 	printHex vertCount[x]
	printHex uvSize[x]
	format "\n"
)

uvOffset = 0
for x=1 to tableCount do (
	Vert_Array=#()
	Face_Array=#()
	UV_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	Mat_Array=#()
	boneMap=#()
	
	fseek f boneMapOffset[x] #seek_set
	for y=1 to boneMapCount[x] do (
		boneMap[y] = readbyte f #unsigned + 1
		ukw = readbyte f #unsigned + 1
	)
-- 	format "\n"
-- 	
-- 	print boneMap #nomap
	
	fseek f vertOffset[x] #seek_set
	if vertType[x] == 1 do (
		for y = 1 to vertCount[x] do (
			w = (weight_data boneids:#() weights:#())
			
			vx=readfloat f
			vy=readfloat f
			vz=readfloat f
			nx=readbyte f #unsigned 
			ny=readbyte f #unsigned
			nz=readbyte f #unsigned
			nw=readbyte f #unsigned
			tx=readbyte f #unsigned
			ty=readbyte f #unsigned
			tz=readbyte f #unsigned
			tw=readbyte f #unsigned
			bone1 = readbyte f #unsigned + 1
			bone2 = readbyte f #unsigned + 1
			bone3 = readbyte f #unsigned + 1
			bone4 = readbyte f #unsigned + 1
			weight1 = readshort f #unsigned / 65535.0
			weight2 = readshort f #unsigned / 65535.0
			weight3 = readshort f #unsigned / 65535.0
			weight4 = readshort f #unsigned / 65535.0
			
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
					append w.weights (w1)
				)
				if(weight2 != 0) then (
					w2 = weight2 as float
					append w.boneids (bone2)
					append w.weights (w2)
				)
				if(weight3 != 0) then (
					w3 = weight3 as float
					append w.boneids (bone3)
					append w.weights (w3)
				)
				if(weight4 != 0) then (
					w4 = weight4 as float
					append w.boneids (bone4)
					append w.weights (w4)
				)		
			)
			
-- 			format "% % % %\n" bone1 bone2 bone3 bone4
-- 			format "% % % %\n\n" weight1 weight2 weight3 weight4
			
			append Vert_array([vx,vy,vz]*fscale)
			append Normal_array(([nx,ny,nz] /255.0) * 2 - 1)
			append Weight_array w
		)
	)
	if vertType[x] >= 2 do (
		if primType[x] == 4 do (
			for y = 1 to vertCount[x] do(
				vx=readfloat f
				vy=readfloat f
				vz=readfloat f
				nx=readbyte f #unsigned 
				ny=readbyte f #unsigned
				nz=readbyte f #unsigned
				nw=readbyte f #unsigned
				tx=readbyte f #unsigned
				ty=readbyte f #unsigned
				tz=readbyte f #unsigned
				tw=readbyte f #unsigned
				
				append Vert_array([vx,vy,vz]*fscale)
				append Normal_array(([nx,ny,nz] /255.0) * 2 - 1)
			)
		)
		if primType[x] == 5 do (
			for y = 1 to vertCount[x] do(
				vx=readfloat f
				vy=readfloat f
				vz=readfloat f
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([0,0,0])
			)
		)
	)

	fseek f faceOffset[x] #seek_set
	if primType[x] == 4 do (
		for y = 1 to faceCount[x]/3 do (
			fa = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
			fb = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
			fc = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
			
			append Face_Array[fa,fb,fc]
			append Mat_Array matID
		)
	)
	if primType[x] == 5 do (
		facecount = (faceCount[x])
		facestart = (ftell f)
		StartDirection = 1	--was -1
		f1 = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
		f2 = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
		FaceDirection = StartDirection
		Do (
		f3 = (Readshort f)
		if (f3==0xFFFF) then (
		f1 = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
		f2 = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
		FaceDirection = StartDirection   
		) else (
		f3 += 1
		FaceDirection *= -1
		if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
		if FaceDirection > 0 then append Face_array[f1,f3,f2]
		else append Face_array [f1,f2,f3]
		)
		f1 = f2
		f2 = f3
		)  
		)
		while (ftell f) < (facestart + (facecount * 2))
	)
	
	if extUV == true then (
		fseek g uvOffset #seek_set
		printHere g
		for y=1 to vertCount[x] do (
			tu = readfloat g
			tv = readfloat g
			
			fseek g (uvSize[x] - 8) #seek_cur
			
			append UV_array([tu,1-tv,0])
		)
		
		uvOffset = ftell g
	)
	else (
		fseek f localUVOffset #seek_set
		for y=1 to vertCount[x] do (
			tu = readfloat f
			tv = readfloat f
			
			fseek f (uvSize[x] - 8) #seek_cur
			
			append UV_array([tu,1-tv,0])
		)
		
		print UV_Array
	)
	
	msh = mesh vertices:Vert_array faces:Face_Array
	msh.numTVerts = UV_array.count
	msh.material = mat
-- 	msh.name = meshName[x]
	buildTVFaces msh
	for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])

	if (skelPresent()) do (
		max modify mode
		select msh
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to boneMapCount[x] do (
			maxbone = getnodebyname BNArr[boneMap[i]].name
			if i != BNArr.count then
				skinOps.addBone skinMod maxbone 0
			else
				skinOps.addBone skinMod maxbone 1
		)
		
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_array.count do (
			w = Weight_array[i]
			bi = #() --bone index array
			wv = #() --weight value array
			
			for j = 1 to w.boneids.count do (
				boneid = w.boneids[j]
				weight = w.weights[j]
				append bi boneid
				append wv weight
			)	
			
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)
	)
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
fclose h
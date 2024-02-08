-- SleepyZay --

Global fscale=50
Global IDArray=#()
Global LoadSkel = true

struct weight_data (
	boneids,weights
)

fn convertTo32 input16 = (
      inputAsInt = input16
      sign = bit.get inputAsInt 16
      exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
      fraction = bit.and inputAsInt (bit.hexasint "03FF")
      if sign==true then sign = 1 else sign = 0
      exponentF = exponent + 127
      --Ouput 32 bit integer representing a 32 bit float
      outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
      --Output Check   
      return bit.intasfloat outputasfloat
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)  
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
)
fn ReadFixedString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)
fn ReadFixedHexString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += bit.intAsHex (ReadByte bstream #unsigned)
   )
   str
)
fn NameSplitter FileName = (
	global Split =  filterstring FileName "_"
	Char = Split[1]
	ItemNumber = Split[2]
	If Split.Count > 2 do (
		Item = Split[3]
		format Char
		format "_"
		format ItemNumber
		format "_"
		format Item
		
		
		SubTest=#()
		SubItem=#()
		
		If Split.count == 3 do format "\n"
		If Split.count >= 4 do (
			For x=4 to Split.Count do (
				SubTest[x] = substring Split[x] 1 3
				If Split.Count == x do (
					If SubTest[x] == "LOD" do (
						LodType = Split[x]
						format "_"
						format LodType
						format "\n"
					)
					If SubTest[x] != "LOD" do (
						SubItem[x] = Split[x]
						format "_"
						format SubItem[x] 
						format "\n"
					)
				)
				If Split.Count != x do (
					If SubTest[x] != "LOD" do (
						SubItem[x] = Split[x]
						format "_"
						format SubItem[x] 
						If x == (Split.Count + 1) do format "_"
					)
				)
			)
		)
	)
	
	Append IDArray (ItemNumber)
	
	-- print Split.count	
)
fn DupeFinder uniques = (
	for i in uniques.count to 1 by -1 do
	(
		id = findItem uniques uniques[i]
		if (id != i) do deleteItem uniques i
	)
	return uniques
-- 	print uniques
)
fn LoadSkeleton Filename FileFolder = (
	global Split =  filterstring FileName "_"
	Skel = Split[1]
	SkelNumber = Split[2]
	if Split.count > 2 do (
		SkelLodType = Split[3]
	)
	SkelPath = (FileFolder + Skel + "_" + SkelNumber + ".esk")
	SkelPath_Default = (FileFolder + Skel + "_" + "000" + ".esk")
	If (SkelPath!=undefined) and ((DoesFileExist SkelPath)==true) then (
		SkelName = SkelPath
	)
	Else (
		SkelName = SkelPath_Default
	)
	
-- 	Print SkelName
	
	fname = SkelName
	s = fopen fname "rb"   --open file in read only format
	g = s
	If (fname!=undefined) and ((DoesFileExist fname)==true) and (LoadSkel == true)then (
		
-- 		Print "Skeleton Loaded"
		boneMapTable=#()
		BoneName=#()
		BoneParentID=#()
		
		FileType = ReadFixedString g 4
		fseek g 0x20 #seek_set
		boneCount = ReadBEShort g
-- 		print boneCount
		fseek g 0x6 #seek_cur -- looks the ame for all file but only checked 3
		NameOffsetTable = ReadBElong g + 0x20
		ukwOffset = ReadBElong g + 0x20
		BoneStart = ReadBElong g + 0x20
		ukwOffset2 = ReadBElong g + 0x20
		ukwOffset3 = ReadBElong g + 0x20
		fseek g 0x8 #seek_cur
		For x=1 to boneCount do (
			BoneParentID[x] = ReadBEShort g + 1
			fseek g 0x6 #seek_cur -- Stuff probs important but too lazy
		)
		
		fseek g NameOffsetTable #seek_set
		For x=1 to boneCount do (
			boneMapTable[x] = ReadBElong g + 0x20
		)
		
		For x=1 to boneCount do (
			fseek g boneMapTable[x] #seek_set
			BoneName[x] = readstring g
		-- 	Print BoneName[x] as string
		)
			
		fseek g bonestart #seek_set
			
		global BNArr = #()
		for x=1 to boneCount do (
			
			m11 = ReadBEfloat g; m12 = ReadBEfloat g; m13 = ReadBEfloat g; m14 = ReadBEfloat g
			m21 = ReadBEfloat g; m22 = ReadBEfloat g; m23 = ReadBEfloat g; m24 = ReadBEfloat g
			m31 = ReadBEfloat g; m32 = ReadBEfloat g; m33 = ReadBEfloat g; m34 = ReadBEfloat g
			m41 = ReadBEfloat g; m42 = ReadBEfloat g; m43 = ReadBEfloat g; m44 = ReadBEfloat g
			tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
			
			newBone = bonesys.createbone	\
			tfm.row4	\
			(tfm.row4 + 0.01 * (normalize tfm.row1)) \
			(normalize tfm.row3)
			newBone.width = 0.1
			newBone.height = 0.1
-- 			newBone.wirecolor = yellow
			newbone.showlinks = false
			newBone.transform = tfm
			newBone.name = boneName[x]
			
			pos = [m41,m42,m43]
			pos *= tfm
			newBone.pos += ((fscale)*-pos)
			
			newBone.setBoneEnable false 0
			newBone.pos.controller = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
			
			if (BoneParentID[x] != 0) then (
			newBone.parent = BNArr[BoneParentID[x]]
		   )
			
			append BNArr newBone
		)
-- 		rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
-- 		for b in BNArr where b.parent==undefined do b.parent = rootRT
-- 		rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
		for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
		for b in BNArr do b.setskinpose()
	)
	gc()
	fclose g
)
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	name = readstring bstream
	fseek bstream backJump #seek_set
	
	return name
)

fname = GetOpenFileName caption:"Dragon Ball Xenoverse EMD" types:"(*.emd)|*.emd"
-- fname = @"C:\Users\Xavier\Documents\projects\models\xenoverse\TRX\TRX_003_Boots.emd"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
f = fopen fname "rb"   --open file in read only format
clearlistener()

delete $*

FileName = getFileNameFile fname
FileExtension = getFileNameType  fname
FileFolder = getFileNamePath fname
File = (FileName + FileExtension)

NameSplitter FileName 
Print "===================================="

-- LoadSkel = true
LoadSkeleton Filename FileFolder

CharID = substring File 1 3
MainID =  substring File 5 3
Print ("Focus ID is "+(MainID as string))

emdFiles = getFiles (FileFolder + "\\*.emd")
for a=1 to emdFiles.count do (
	gname = emdFiles[a]
	g = fopen gname "rb"
	f = g
	FileName2 = getFileNameFile gname
	FileExtension2 = getFileNameType  gname
	File2 = (FileName + FileExtension)
	NameSplitter FileName2 
	TestID = substring File2 5 3
-- 	TestLodType = substring Split[Split.count] 1 5	-- for loading lod models
	TestLodType = substring Split[Split.count] 1 3
-- 	If Split[2] == MainID and TestLodType == "LOD03" do (		-- for loading lod models
	If Split[1] == CharID and Split[2] == MainID and TestLodType != "LOD" and TestLodType != "scd" and TestLodType != "SCD" do (
	
	modelOffset=#()
	meshCount=#()
	modelName=#()
	subMeshCount=#()
	
	EMD = ReadFixedString f 0x04
	fseek f 0x0c #seek_cur
	
	modelCount = ReadBElong f
	modelTable = ReadBElong f
	NameTableOffset = ReadBElong f
	
	modelOffset = for x=1 to modelCount collect (ReadBElong f)
	
	Print ("Model Count is "+(modelCount as string))
	Print "==============================="
	
	For x=1 to modelCount do (
		meshOffset=#()
		
		fseek f modelOffset[x] #seek_set
		fseek f 0x10 #seek_cur	-- Looks the same throughout the files 
		fseek f 0x30 #seek_cur	--Block of shit
		modelNameOffset = ReadBElong f + modelOffset[x] + 0x10
		meshCount = ReadBElong f
		meshTableOffset = ReadBElong f + modelOffset[x] + 0x10
		
		fseek f modelNameOffset #seek_set
		modelName = readstring f
		
		fseek f meshTableOffset #seek_set
		meshOffset = for mc=1 to meshCount collect (ReadBElong f + modelOffset[x] + 0x10)
		
		For m=1 to meshCount do (
			Vert_Array=#()
			UV_Array=#()
			Normal_Array=#()
			Weight_array =#()
			
			vertCount=#()
			vertOffset=#()
			faceOffset=#()
			polyOffsetTable=#()
			meshNameLength=#()
			meshName=#()
			boneMap=#()
			
			fseek f meshOffset[m] #seek_set
			fseek f 0x30 #seek_cur
			ukw = readbelong f -- always 0x8207
			vertStride = readbelong f
			vertCount = readbelong f
			vertOffset = readbelong f + meshOffset[m]
			ukw2 = readbelong f
			ukw3 = readbeshort f -- always 0x2
			subMeshCount = readbeshort f
			meshNameEnd = ReadBElong f
			subMeshOffsetTable = readbelong f + meshOffset[m]
			meshName = readstring f
			
			fseek f vertOffset #seek_set
			Print ("vertOffset @ 0x"+((bit.intAsHex(vertOffset))as string))
			
			If vertStride == 0x30 do (
				for x = 1 to vertCount do(
				w = (weight_data boneids:#() weights:#())
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				nx = ReadBEfloat f
				ny = ReadBEfloat f
				nz = ReadBEfloat f
				tu=ReadBEfloat f
				tv=ReadBEfloat f
				bone4 = readbyte f #unsigned
				bone3 = readbyte f #unsigned
				bone2 = readbyte f #unsigned
				bone1 = readbyte f #unsigned
				weight1 = ReadBEfloat f
				weight2 = ReadBEfloat f
				weight3 = ReadBEfloat f
				weight4 = 0
				weight4 = 1 - (weight1+weight2+weight3)
				maxweight = 0
				if(bone1 != 0xFF) then
					maxweight = maxweight + weight1
				if(bone2 != 0xFF) then
					maxweight = maxweight + weight2
				if(bone3 != 0xFF) then
					maxweight = maxweight + weight3
				if(bone4 != 0xFF) then
					maxweight = maxweight + weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(bone1 != 0xFF) then (
						w1 = weight1 as float
						append w.boneids (bone1+1)
						append w.weights (w1 / mxw)
					)
					if(bone2 != 0xFF) then (
						w2 = weight2 as float
						append w.boneids (bone2+1)
						append w.weights (w2 / mxw)
					)
					if(bone3 != 0xFF) then (
						w3 = weight3 as float
						append w.boneids (bone3+1)
						append w.weights (w3 / mxw)
					)
					if(bone4 != 0xFF) then (
						w4 = weight4 as float
						append w.boneids (bone4+1)
						append w.weights (w4 / mxw)
					)
				)
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				append Normal_Array ([nx,ny,nz])
				append Weight_array w
				)
			)
			If vertStride == 0x28 do (
				for x = 1 to vertCount do(
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				nx = ReadBEHalfFloat f	-- Probably weights not normals
				ny = ReadBEHalfFloat f
				nz = ReadBEHalfFloat f
				null = ReadBEHalfFloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f
				fseek f 0x10 #seek_cur
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				append Normal_Array ([nx,ny,nz])
				)
			)
			If vertStride == 0x24 do (
				for x = 1 to vertCount do(
				w = (weight_data boneids:#() weights:#())
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				nx = ReadBEHalfFloat f
				ny = ReadBEHalfFloat f
				nz = ReadBEHalfFloat f
				null = ReadBEHalfFloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f
				
				bone4 = readbyte f #unsigned
				bone3 = readbyte f #unsigned
				bone2 = readbyte f #unsigned
				bone1 = readbyte f #unsigned
				weight1 = ReadBEHalfFloat f
				weight2 = ReadBEHalfFloat f
				weight3 = ReadBEHalfFloat f
				weight4 = ReadBEHalfFloat f
				weight4 = 1 - (weight1+weight2+weight3)
				
				maxweight = 0
				if(bone1 != 0xFF) then
					maxweight = maxweight + weight1
				if(bone2 != 0xFF) then
					maxweight = maxweight + weight2
				if(bone3 != 0xFF) then
					maxweight = maxweight + weight3
				if(bone4 != 0xFF) then
					maxweight = maxweight + weight4
				
				if(maxweight != 0) then (
					mxw = 255.0
					if(bone1 != 0xFF) then (
						w1 = weight1 as float
						append w.boneids (bone1+1)
						append w.weights (w1 / mxw)
					)
					if(bone2 != 0xFF) then (
						w2 = weight2 as float
						append w.boneids (bone2+1)
						append w.weights (w2 / mxw)
					)
					if(bone3 != 0xFF) then (
						w3 = weight3 as float
						append w.boneids (bone3+1)
						append w.weights (w3 / mxw)
					)
					if(bone4 != 0xFF) then (
						w4 = weight4 as float
						append w.boneids (bone4+1)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				append Normal_Array ([nx,ny,nz])
				append Weight_array w
				)
			)
			If vertStride == 0x20 do (
				for x = 1 to vertCount do(
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				nx = ReadBEHalfFloat f	-- Probably weights not normals
				ny = ReadBEHalfFloat f
				nz = ReadBEHalfFloat f
				null = ReadBEHalfFloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f
				fseek f 0x8 #seek_cur
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				append Normal_Array ([nx,ny,nz])
				)
			)
			If vertStride == 0x1c do (
				for x = 1 to vertCount do(
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				nx = ReadBEHalfFloat f	-- Probably weights not normals
				ny = ReadBEHalfFloat f
				nz = ReadBEHalfFloat f
				null = ReadBEHalfFloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f
				fseek f 0x4 #seek_cur
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				append Normal_Array ([nx,ny,nz])
				)
			)
			If vertStride == 0x18 do (
				for x = 1 to vertCount do(
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				nx = ReadBEHalfFloat f	-- Probably weights not normals
				ny = ReadBEHalfFloat f
				nz = ReadBEHalfFloat f
				null = ReadBEHalfFloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				append Normal_Array ([nx,ny,nz])
				)
			)
			If vertStride == 0x14 do (
				for x = 1 to vertCount do(
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f
				bonesnstuff = ReadBEfloat f -- Double back to this
				
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				)
			)
			If vertStride == 0x10 do (
				for x = 1 to vertCount do(
				vx = ReadBEfloat f
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				tu=ReadBEHalfFloat f
				tv=ReadBEHalfFloat f			
				append Vert_Array(([vx,vy,vz])*fscale)
				append UV_Array([tu,-tv,0]*2)
				)
			)
			
			fseek f subMeshOffsetTable #seek_set
			subMeshOffset = for p=1 to subMeshCount collect (readbelong f + meshOffset[m])
			
			for p=1 to subMeshCount do (
				Face_Array=#()
				
				fseek f subMeshOffset[p] #seek_set
				faceCount = readbelong f
				boneMapCount = readbelong f
				faceOffset = readbelong f + subMeshOffset[p]
				boneMapOffset = readbelong f + subMeshOffset[p]
				
				fseek f faceOffset #seek_set
				for x=1 to faceCount/3 do(
					fa=ReadBEShort f +1
					fb=ReadBEShort f +1
					fc=ReadBEShort f +1
					append Face_Array[fa,fb,fc]
				)
				
				fseek f boneMapOffset #seek_set
				for x=1 to boneMapCount do boneMap[x] = (getName f (ReadBElong f + subMeshOffset[p]))
				
				msh = mesh vertices:Vert_Array faces:Face_Array name:meshName
				msh.numTVerts = UV_Array.count
				buildTVFaces msh
				for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
				for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
				for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
				msh.transform=(matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
				
				If LoadSkel == true do (
					-- Applying Skinning --
					count = msh.numverts
					max modify mode
					select msh
					skinMod = skin ()
					addModifier msh skinMod
					for i = 1 to boneMap.count do (
					   maxbone = getnodebyname boneMap[i]
					   skinOps.addBone skinMod maxbone 1
					)
					-- Applying Weights --
					select msh
					modPanel.setCurrentObject skinMod
					for i = 1 to weight_array.count do (
						w = Weight_array[i]
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
				)
				
				format "\n"
			)
		)
		
		Print "==============================="
	)

	Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
	
	)
)

DupeFinder IDArray
print IDArray
Print ("Total costume count is "+(IDArray.count as string))

)
gc()
fclose f
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
fn Readword fstream = (
return readshort fstream #unsigned
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
   if var == 1 do fseek f -fixedLen #seek_cur
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
fn skelPresent = (
	allBones = for o in geometry where classOf o == boneGeometry collect o
	if allBones.count > 0 then (
		return true
	)
	else (
		return false
	)
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
fn dupeFinder uniques = (
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
	
	Print SkelName
	
	fname = SkelName
	s = fopen fname "rb"   --open file in read only format
	g = s
	If (fname!=undefined) and ((DoesFileExist fname)==true) and (LoadSkel == true)then (
		
		Print "Skeleton Loaded"
		BoneNameOffset=#()
		BoneNameLength=#()
		boneName=#()
		BoneParentID=#()
		
		FileType = ReadFixedString g 4
		fseek g 0x20 #seek_set
		BoneCount = ReadShort g
		print BoneCount
		fseek g 0x6 #seek_cur -- looks the ame for all file but only checked 3
		NameOffsetTable = Readlong g + 0x20
		ukwOffset = Readlong g + 0x20
		BoneStart = Readlong g + 0x20
		ukwOffset2 = Readlong g + 0x20
		ukwOffset3 = Readlong g + 0x20
		fseek g 0x8 #seek_cur
		for x=1 to BoneCount do (
			BoneParentID[x] = ReadShort g + 1
			fseek g 0x6 #seek_cur -- Stuff probs important but too lazy
		)
		
		fseek g NameOffsetTable #seek_set
		for x=1 to BoneCount do (BoneNameOffset[x] = Readlong g + 0x20)
		
		for x=1 to BoneCount do (
			fseek g BoneNameOffset[x] #seek_set
			boneName[x] = readstring g
		-- 	Print boneName[x] as string
		)
			
		fseek g bonestart #seek_set
		BNArr = #()
		for x=1 to BoneCount do (
			
			m11 = Readfloat g; m12 = Readfloat g; m13 = Readfloat g; m14 = Readfloat g
			m21 = Readfloat g; m22 = Readfloat g; m23 = Readfloat g; m24 = Readfloat g
			m31 = Readfloat g; m32 = Readfloat g; m33 = Readfloat g; m34 = Readfloat g
			m41 = Readfloat g; m42 = Readfloat g; m43 = Readfloat g; m44 = Readfloat g
			tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
			
			newBone = bonesys.createbone	\
			tfm.row4	\
			(tfm.row4 + 0.01 * (normalize tfm.row1)) \
			(normalize tfm.row3)
			newBone.width = 0.1
			newBone.height = 0.1
-- 			newBone.wirecolor = yellow
			newbone.showlinks = true
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
		
		rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
		for b in BNArr where b.parent==undefined do b.parent = rootRT
		rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
		for b in BNArr do b.setskinpose()
		
	)
	gc()
	fclose g
)

fname = GetOpenFileName caption:"Dragon Ball Xenoverse EMD" types:"All Formats|*.nmd;*.emd|(*.emd)|*.emd|(*.nmd)|*.nmd"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
f = fopen fname "rb"   --open file in read only format
clearlistener()

FileName = getFileNameFile fname
FileExtension = getFileNameType  fname
FileFolder = getFileNamePath fname
File = (FileName + FileExtension)

NameSplitter FileName 
Print "===================================="

-- if (skelPresent() == false) then (
-- 	-- LoadSkel = true
-- 	LoadSkeleton Filename FileFolder
-- )


EMD = ReadFixedString f 0x04
ukw = readshort f
ukw2 = readshort f
ukw3 = readshort f
ukw4 = readshort f
null = readlong f
null = readshort f
modelCount = readshort f
modelTableOffset = readlong f
nameTableOffset = readlong f

fseek f modelTableOffset #seek_set
modelOffset = for x=1 to modelCount collect (readlong f #unsigned)

fseek f nameTableOffset #seek_set
modelName = for x=1 to modelCount collect (readlong f #unsigned)

for x=1 to modelCount do (
	fseek f modelOffset[x] #seek_set
	
	null = readshort f
	meshCount = readshort f
	meshTableOffset = readlong f + modelOffset[x]
	
	fseek f meshTableOffset #seek_set
	meshOffset = for y=1 to meshCount collect (readlong f #unsigned + modelOffset[x])
	
	for y=1 to meshCount do (
		fseek f meshOffset[y] #seek_set
		
		fseek f 0x30 #seek_cur	--matrix info
		meshNameOffset = readlong f + meshOffset[y]
		null = readshort f
		polyElmCount = readshort f
		polyElmTableOffset = readlong f + meshOffset[y]
		
		fseek f meshNameOffset #seek_set
		meshName = readstring f
		
		fseek f polyElmTableOffset #seek_set
		polyElmOffset = for z=1 to polyElmCount collect (readlong f #unsigned + meshOffset[y])
		
		for z=1 to polyElmCount do (
			Vert_Array=#()
			UV_Array=#()
			Normal_array=#()
			Weight_array=#()
			boneMap=#()
			
			fseek f polyElmOffset[z] #seek_set
			
			fseek f 0x30 #seek_cur	--matrix info
			ukw = readlong f	--always 0x8207, prob flags
			vertStride = readlong f
			vertCount = readlong f
			vertOffset = readlong f + polyElmOffset[z]
			polyElmNameOffset = readlong f + polyElmOffset[z]
			ukw = readshort f
			subPolyElmCount = readshort f
			ukwOffset = readlong f + polyElmOffset[z]	--mat info?
			subPolyDataOffset = readlong f + polyElmOffset[z]
			
			printHex vertStride
			
			fseek f vertOffset #seek_set
			if vertStride == 0x18 do (
				for a=1 to vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					bone1 = readbyte f #unsigned
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					weight3 = ReadHalfFloat f
					weight4 = ReadHalfFloat f
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
					
					append Vert_Array([vx,vy,vz]*fscale)
					append UV_Array[0,0,0]
					append Weight_array w
				)
			)
			if vertStride == 0x24 do (
				for a=1 to vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					nx = ReadHalfFloat f
					ny = ReadHalfFloat f
					nz = ReadHalfFloat f
					nw = ReadHalfFloat f
					tu = ReadHalfFloat f * 2
					tv = ReadHalfFloat f
					bone1 = readbyte f #unsigned
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					weight3 = ReadHalfFloat f
					weight4 = ReadHalfFloat f
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
					
					append Vert_Array([vx,vy,vz]*fscale)
					append Normal_array[nx,ny,nz]
					append UV_Array[tu,-tv,0]
					append Weight_array w
				)
			)
			if vertStride == 0x28 do (
				for a=1 to vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					nx = ReadHalfFloat f
					ny = ReadHalfFloat f
					nz = ReadHalfFloat f
					nw = ReadHalfFloat f
					tu = ReadHalfFloat f * 2
					tv = ReadHalfFloat f
					cr = readbyte f
					cb = readbyte f
					cg = readbyte f
					ca = readbyte f
					bone1 = readbyte f #unsigned
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					weight3 = ReadHalfFloat f
					weight4 = ReadHalfFloat f
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
					
					append Vert_Array([vx,vy,vz]*fscale)
					append Normal_array[nx,ny,nz]
					append UV_Array[tu,-tv,0]
					append Weight_array w
				)
			)
			If vertStride == 0x30 do (
				for x = 1 to vertCount do(
				w = (weight_data boneids:#() weights:#())
				
				vx = readfloat f
				vy = readfloat f
				vz = readfloat f
				nx = readfloat f
				ny = readfloat f
				nz = readfloat f
				tu=readfloat f
				tv=readfloat f
				bone4 = readbyte f #unsigned
				bone3 = readbyte f #unsigned
				bone2 = readbyte f #unsigned
				bone1 = readbyte f #unsigned
				weight1 = readfloat f
				weight2 = readfloat f
				weight3 = readfloat f
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
			
			fseek f polyElmNameOffset #seek_set
			polyElmName = readstring f	--or matName
			
			fseek f subPolyDataOffset #seek_set
			subPolyElmOffset = for a=1 to subPolyElmCount collect (readlong f #unsigned + polyElmOffset[z])
			
			for a=1 to subPolyElmCount do (
				Face_Array=#()
				
				fseek f subPolyElmOffset[a] #seek_set
				
				faceCount = readlong f #unsigned
				boneMapCount = readlong f #unsigned
				faceOffset = readlong f #unsigned + subPolyElmOffset[a]
				boneMapOffset = readlong f #unsigned + subPolyElmOffset[a]
				
				fseek f faceOffset #seek_set
				for b=1 to (faceCount/3) do (
					fa = readshort f #unsigned + 1
					fb = readshort f #unsigned + 1
					fc = readshort f #unsigned + 1
					
					append Face_Array[fa,fb,fc]
				)
				
				fseek f boneMapOffset #seek_set
				for b=1 to boneMapCount do boneMap[b] = (getName f (readlong f #unsigned + subPolyElmOffset[a]))
					
				msh = mesh vertices:Vert_Array faces:Face_Array name:polyElmName
				msh.numTVerts = UV_Array.count
				buildTVFaces msh
				for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
				for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
				for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
				msh.transform=(matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
				
				if (skelPresent()) do (
					-- Applying Skinning --
					count = msh.numverts
					max modify mode
					select msh
					skinMod = skin ()
					addModifier msh skinMod
					for i = 1 to boneMap.Count do (
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
			)
		)
	)
)

DupeFinder IDArray
print IDArray
Print ("Total costume count is "+(IDArray.count as string))

)
gc()
fclose f
-- SleepyZay --

fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
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


fn ReadFaces VertCount FaceType = (
	Global Face_array=#()
	
	if FaceType == 1 do (
		StartDirection = -1
		x=0
		a=0
		b=1
		
		f1 = a + 1
		f2 = b + 1  
		FaceDirection = StartDirection
		do (
			x+=1
			
			f3 = x
			FaceDirection *= -1
			if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
				if FaceDirection > 0 then append Face_array [f1,f2,f3]
				else append Face_array [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
		)
		while (x < (vertcount))
-- 		print Face_array #nomap
	)
	
	if FaceType == 0 do (
		
		a=0
		b=0
		c=0
		
		For x=1 to vertcount by 3 do (
			a=x
			b=x+1
			c=x+2
			append face_array [a,b,c]
		)
-- 		print face_array #nomap
	)
)
fn ApplyNormals msh Normal_array= (
	max modify mode
	select msh
		
	--set smoothing group of all faces to 1 to get one normal per vertex
	for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
		--set normals via edit normals modifier
		select msh
		addmodifier msh (Edit_Normals ()) ui:off
		msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		EN_setNormal = msh.Edit_Normals.SetNormal
		normID = #{}
	
		--apply normals
		for v = 1 to Normal_array.count do
		(
			free normID
			EN_convertVS #{v} &normID
			for id in normID do EN_setNormal id Normal_array[v]
		)
		collapseStack msh
)
fn getId bstream offset = (
	id = 0
	if offset != 0 do (
		backjump = ftell bstream
		fseek bstream offset #seek_set
		id = (readlong bstream) + 1
		fseek bstream backjump #seek_set
	)
	return id
)
fn getOffset bstream ref offset = (
	backjump = ftell bstream
	fseek bstream offset #seek_set
	fseek bstream 0x8 #seek_cur
	theOffset = readlong bstream + ref
	null = readlong bstream
	fseek bstream backjump #seek_set
	return theOffset
)
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)
fn BuildFaces VertCount FaceType &Face_Array= (
	Global Face_array=#()
	
	if FaceType == 1 do (
		StartDirection = -1
		x=0
		a=0
		b=1
		
		f1 = a + 1
		f2 = b + 1  
		FaceDirection = StartDirection
		do (
			x+=1
			
			f3 = x
			FaceDirection *= -1
			if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
				if FaceDirection > 0 then append Face_array [f1,f2,f3]
				else append Face_array [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
		)
		while (x < (vertcount))
-- 		print Face_array #nomap
	)
	
	if FaceType == 0 do (
		
		a=0
		b=0
		c=0
		
		For x=1 to vertcount by 3 do (
			a=x
			b=x+1
			c=x+2
			append face_array [a,b,c]
		)
-- 		print face_array #nomap
	)
)

fname = GetOpenFileName caption:"Budokai PS2" types:"All Known Formats|*.amo;*.bin|Model (*.amo)|*.amo"
-- fname = @"C:\Users\Xavier\Desktop\New folder (4)\New folder\unnamed_488_010.amo"
-- fname = @"D:\models\ripped\dbz budokai 3\unnamed_88.bin"
-- fname = @"D:\models\ripped\dbz budokai 3\unnamed_277.bin"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileExtension = toLower FileExtension
FileName = getFileNameFile fname
delete $*
clearlistener()
Global fscale=5
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _boneDataTable (
	boneID = readlong f,
	boneDataOffset = readlong f,
	childTableOffset = readlong f,
	siblingTableOffset = readlong f,
	parentTableOffset = readlong f,
	null = (fseek f 0x0c #seek_cur)
)

struct _boneData (	--0x13 of these per bone
	amgID = readlong f + 1,
	boneID = readlong f + 1,
	matrixOffset = readlong f,
	null = readlong f
)

struct _amgDataTable (
    tfm,
	ukw,
	ukw2,
	dataOffset,
	childOffset,
	siblingOffset,
	parentOffset,

    -- Constructor
    fn init f amgOffset = (
		c11 = readfloat f; c12 = readfloat f; c13 = readfloat f; c14 = readfloat f
		c21 = readfloat f; c22 = readfloat f; c23 = readfloat f; c24 = readfloat f 
		c31 = readfloat f; c32 = readfloat f; c33 = readfloat f; c34 = readfloat f
		tfm = inverse (quat c11 c12 c13 c14) as matrix3
		tfm.row4 = ([c21,c22,c23]*fscale)
		ukw = readshort f
		ukw2 = readshort f
		dataOffset = readlong f + amgOffset
		childOffset = readlong f + amgOffset
		siblingOffset = readlong f + amgOffset
		parentOffset = readlong f + amgOffset
		null = readlong f
		null2 = readlong f
		null3 = readlong f
    )
)

fn buildSkeleton boneDataList boneDataOffset amoOffset boneNameList &BNArr= (
	x = 0
	for boneData in boneDataList do (
		x += 1
		boneId = boneData.boneId + 1
		childId = (if boneData.childTableOffset > 0 then ((boneData.childTableOffset + amoOffset) -  boneDataOffset) as integer / 0x20 + 1 else 0)
		siblingId = (if boneData.siblingTableOffset > 0 then ((boneData.siblingTableOffset + amoOffset) -  boneDataOffset) as integer / 0x20 + 1 else 0)
		parentId = (if boneData.parentTableOffset > 0 then ((boneData.parentTableOffset + amoOffset) -  boneDataOffset) as integer / 0x20 + 1 else 0)
-- 		format "% % % %\n" boneId childId siblingId parentId

		fseek f (fseek f (boneData.boneDataOffset + 8) #seek_set; readlong f) #seek_set
		c11 = readfloat f; c12 = readfloat f; c13 = readfloat f; c14 = readfloat f
		c21 = readfloat f; c22 = readfloat f; c23 = readfloat f; c24 = readfloat f 
		c31 = readfloat f; c32 = readfloat f; c33 = readfloat f; c34 = readfloat f
		tfm = inverse (quat c11 c12 c13 c14) as matrix3
		tfm.row4 = ([c21,c22,c23]*fscale)
		
		if (parentID != 0) do (
			tfm *= BNArr[parentID].objecttransform	
		)
		
		newBone = bonesys.createbone	\
		tfm.row4	\
		(tfm.row4 + 0.01 * (normalize tfm.row1)) \
		(normalize tfm.row3)
		newBone.width  = 0.01
		newBone.height = 0.01
		newBone.transform = tfm
		newBone.setBoneEnable false 0
		newBone.wirecolor = white
	 	newbone.name = boneNameList[x]
		newbone.showlinks = false
		newBone.pos.controller      = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()

		if (parentID != 0) then(
			newBone.parent = BNArr[parentID]
		)
		append BNArr newBone
	)
	rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
	for b in BNArr where b.parent==undefined do b.parent = rootRT
	rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	for b in BNArr do b.setskinpose()
)
fn testForQuat f = (
	rx = readfloat f
	ry = readfloat f
	rz = readfloat f
	rw = readfloat f
	fseek f -0x10 #seek_cur
	test = rx * rx + ry * ry + rz * rz + rw * rw
	if test == 1.0 then (
		return true
	)
	else (
		return false
	)
)

amoOffset = ftell f
amo = ReadFixedString f 4
headerLength = readlong f
null = readlonglong f
boneCount = readlong f
boneDataOffset = readlong f
amgCount = readlong f
amgOffsetTable = readlong f 
ukwCount = readlong f	--amount of meshes that have blened weights
boneNameOffset = readlong f

fseek f boneDataOffset #seek_set
boneDataList = for x=1 to boneCount collect (table = _boneDataTable())
printhex boneDataOffset
	
fseek f amgOffsetTable #seek_set
amgOffsetArray = for x=1 to amgCount collect (readlong f)
	
fseek f boneNameOffset #seek_set
boneNameList = for x=1 to boneCount collect (ReadFixedString f 0x20)

BNArr = #()
buildSkeleton boneDataList boneDataOffset amoOffset boneNameList BNArr

for x=1 to BNArr.count do format "% %\n" x BNArr[x].name

Mesh_Array = #()
vertOffsetToIndexArray=#()
Weight_Array=#()
TexId_Array=#()
TexId_Array2=#()

multiMat = MultiMaterial numsubs:0 showInViewport:true
meditMaterials[1] = multiMat

for x=1 to 1 do (	--amgCount
	fseek f amgOffsetArray[x] #seek_set
-- 	ReadFixedByteString f 0x20 1 0
	amg = ReadFixedString f 4
	headerLength = readlong f
	null = readlong f
	unk = readlong f	--4, count?
	
	amgBoneCount = readlong f
	amgBoneOffset = readlong f + amgOffsetArray[x]
	amgMaterialCount= readlong f
	amgBoneNameOffset = readlong f + amgOffsetArray[x]
	
	-- doing it this way is simpler but will have a bunch of empty slots where the ramp textures normally go
-- 	if multiMat.count < amgMaterialCount do (
-- 		multiMat.numsubs = amgMaterialCount
-- 		for m in Multimat do m.diffuse = random black white
-- 	)
	
	fseek f amgBoneNameOffset #seek_set
	amgBoneNameList = for x=1 to amgBoneCount collect (ReadFixedString f 0x20)
	
	fseek f amgBoneOffset #seek_set
	amgDataTableList = for y=1 to amgBoneCount collect ((amgTable = _amgDataTable()).init f amgOffsetArray[x]; amgTable)
	
	for y=1 to amgBoneCount do (	--amgBoneCount
		fseek f amgDataTableList[y].dataOffset #seek_set
		
-- 		print BNArr[y].name
		
		ReadFixedByteString f 0x10 1 0
		boneId = readlong f + 1
		modelDataOffset = readlong f + amgOffsetArray[x]
		weightDataOffset = readlong f + amgOffsetArray[x]
		matrixDataOffset = readlong f + amgOffsetArray[x]
		
		fseek f modelDataOffset #seek_set
		if modelDataOffset > amgOffsetArray[x] do (
			Vert_Array=#()
			UV_Array=#()
			Face_Array=#()
			Normal_Array=#()
			Color_Array=#()
			MatId_Array=#()
			MatId_Array2=#()
			vertAdd = 0
			
			meshCount = readlong f
			meshOffsetTable = readlong f + modelDataOffset
			
			fseek f meshOffsetTable #seek_set
			meshOffsetList = for z=1 to meshCount collect (readlong f + modelDataOffset)
			for z=1 to meshCount do (	--meshCount
				fseek f meshOffsetList[z] #seek_set
				ReadFixedByteString f 0x10 1 0
				
				vertexFlags = for a=1 to 8 collect (readbyte f #unsigned)
				texId = readlong f	 + 1		--diffuse texture
				texId2 = readlong f + 1		--color ramp texture
				fseek f 0x30 #seek_cur		--matrix
				
				
				-- this way the multiMat will only be composed of diffuse textures
				appendifunique TexId_Array texId
				appendifunique TexId_Array2 texId2
				matId = finditem TexId_Array texId
				matId2 = finditem TexId_Array2 texId2
				
				if multiMat.count < TexId_Array.count do (
					multiMat.numsubs = TexId_Array.count 
					multiMat[matId].diffuse = random black white
				)
				multiMat[matId].name = texId2 as string
				
				format "% %\n" texId texId2
				
-- 				if vertexFlags[1] != 0xb4 and vertexFlags[1] != 0xb5 do (
-- 					print "pie"
-- 					printhex vertexFlags[1]
-- 				)
				
				baseOffset = ftell f
				
				fseek f 0x50 #seek_cur	--unkData / always the same
				
				vertexDataLength = readshort f * 0x10
				null = readbyte f
				vertexDataOffset = readbyte f + baseOffset
				meshEndOffset = vertexDataOffset + vertexDataLength
				
				fseek f vertexDataOffset #seek_set
				
				j = 0
-- 				for a = 1 to 1 do (
				while (ftell f < meshEndOffset - 0x10) do (
					j += 1
					if j >= 100 do exit
					ReadFixedByteString f 0x20 1 0

					unk = readlong f	--flags?
					null = readlong f
					null = readlong f
					unk2 = readlong f	--flags?
					faceType = readlong f
					vertexCount = readlong f
					null = readlong f
					null = readlong f
-- 					printhere f
-- 					printhex unk2
					for b=1 to vertexCount do (
						if y == 1 do append vertOffsetToIndexArray (ftell f)	--if main model
						
						if vertexFlags[1] == 0x10 do (
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([0,0,0])
							append Normal_array[0,0,0]
						)
						if vertexFlags[1] == 0x12 do (
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							cr = readfloat f
							cg = readfloat f
							cb = readfloat f
							ca = readfloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([0,0,0])
							append Normal_array[0,0,0]
						)
						if vertexFlags[1] == 0x36 do (							
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							cr = readfloat f
							cg = readfloat f
							cb = readfloat f
							ca = readfloat f
							tu = readfloat f
							tv = readfloat f
							f2 = readfloat f
							null = readfloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([tu,-tv,0])
							append Normal_array[0,0,0]
						)
						if vertexFlags[1] == 0x34 or vertexFlags[1] == 0xb4 do (
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							tu = readfloat f
							tv = readfloat f
							f2 = readfloat f
							null = readfloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([tu,-tv,0])
							append Normal_array[0,0,0]
						)
						if vertexFlags[1] == 0xb5 do (							
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							nx = readfloat f
							ny = readfloat f
							nz = readfloat f
							f2 = readfloat f
							tu = readfloat f
							tv = readfloat f
							f3 = readfloat f
							null = readfloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([tu,-tv,0])
							append Normal_Array([nx,ny,nz])
						)
					)
					if faceType == 0 do (
						j=0
						k=0
						l=0
						
						For b=1 to vertexcount by 3 do (
							j=b
							k=b+1
							l=b+2
							append face_array ([j,k,l] + vertAdd)
							append MatId_Array matId
							append MatId_Array2 matId2
						)
					)
					if faceType == 1 do (
						StartDirection = -1
						j=0
						k=0
						l=1
						
						f1 = k + 1
						f2 = l + 1  
						FaceDirection = StartDirection
						do (
							j+=1
							
							f3 = j
							FaceDirection *= -1
							if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
								if FaceDirection > 0 then (
									append Face_array ([f1,f2,f3] + vertAdd)
								)
								else (
									append Face_array ([f1,f3,f2] + vertAdd)
								)
								append MatId_Array matId
								append MatId_Array2 matId2
							)
							f1 = f2
							f2 = f3
						)
						while (j < (vertexcount))
					)
					vertAdd += vertexCount
				)
				
			)
			msh = mesh vertices:Vert_array faces:Face_array materialIds:MatId_Array
			msh.numTVerts = UV_array.count
			msh.wirecolor = random black white
			msh.backfacecull = off
			msh.mat = multimat
			msh.name = BNArr[y].name
			buildTVFaces msh    
			for j = 1 to UV_array.count do setTVert msh j UV_array[j]
			for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
-- 			for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
			
			msh.parent = BNArr[y]
			msh.transform = BNArr[y].transform
			
			append Mesh_Array msh
		)
		
		
		fseek f weightDataOffset #seek_set
		if weightDataOffset > amgOffsetArray[x] do (
			fseek f 0x0c #seek_cur
			weightTableCount = readlong f
			for z=1 to weightTableCount do (
				ReadFixedByteString f 0x20 1 0
				
				weight = readfloat f
				weightVertCount = readlong f
				weightVertOffset = readlong f + amgOffsetArray[x]
				weightVertCount2 = readlong f
				weightVertOffset2 = readlong f + amgOffsetArray[x]
				fseek f 0x0c #seek_cur	--null
				
				boneId2 = (finditem BNArr BNArr[boneID].parent)
				weight2 = 1.0 - weight
				
				backJump = ftell f
				
				fseek f weightVertOffset #seek_set
				if weightVertOffset > amgOffsetArray[x] do (
					for i=1 to weightVertCount do (
						--ReadFixedByteString f 0x20 1 1
						fseek f 0x0c #seek_cur	--floats
						vertOffset = readlong f
						fseek f 0x0c #seek_cur	--floats
						null = readlong f
						
						for j = 1 to vertOffsetToIndexArray.count do (
							if vertOffsetToIndexArray[j] == vertOffset+amgOffsetArray[x] do (
								Weight_Array[j] = #(#(boneId, boneId2), #(weight, weight2))
							)
						)
					)
				)
				
				fseek f weightVertOffset2 #seek_set
				if weightVertOffset2 > amgOffsetArray[x] do (
					for i=1 to weightVertCount2 do (
						--ReadFixedByteString f 0x10 1 1
						fseek f 0x0c #seek_cur	--null
						vertOffset = readlong f
						
						for j = 1 to vertOffsetToIndexArray.count do (
							if vertOffsetToIndexArray[j] == vertOffset+amgOffsetArray[x] do (
								Weight_Array[j] = #(#(boneId, boneId2), #(weight, weight2))
							)
						)
					)
				)
				
				fseek f backJump #seek_set
			)
-- 			format "\n"
		)
	)
	
	/*
	if Weight_Array.count != 0 do (
		-- Applying Skinning --
		max modify mode
		select Mesh_Array[1]
		skinMod = skin ()
		addModifier Mesh_Array[1] skinMod
		for i = 1 to BNArr.count do (
			maxbone = getnodebyname boneNameList[i]
			if i != BNArr.count then
				skinOps.addBone skinMod maxbone 0
			else
				skinOps.addBone skinMod maxbone -1
		)
		-- Applying Weights --
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_Array.count do (
			w = Weight_Array[i]
			
			--format "% % %\n" (i-1) w[1] w[2] 
			
		-- 	skinOps.ReplaceVertexWeights skinMod i w[1] w[2]
			skinOps.SetVertexWeights skinMod i w[1] w[2]
		-- 	print (skinOps.GetVertexWeight skinMod i 1)
		)
	)
	*/
)
format "\n"


Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f

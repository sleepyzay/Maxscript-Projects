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
	Global Face_Array=#()
	
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
				if FaceDirection > 0 then append Face_Array [f1,f2,f3]
				else append Face_Array [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
		)
		while (x < (vertcount))
-- 		print Face_Array #nomap
	)
	
	if FaceType == 0 do (
		
		a=0
		b=0
		c=0
		
		For x=1 to vertcount by 3 do (
			a=x
			b=x+1
			c=x+2
			append Face_Array [a,b,c]
		)
-- 		print Face_Array #nomap
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
fn createCapsuleFromPoints startPoint endPoint radius =
(
    -- Calculate the direction vector and length between the points
    local direction = normalize (endPoint - startPoint)
    local length = distance startPoint endPoint
    
    -- Create the capsule
    local cap = capsule radius:radius height:(length - 2 * radius)
    
    -- Position the capsule at the midpoint between startPoint and endPoint
    local midpoint = (startPoint + endPoint) / 2.0
    cap.pos = midpoint
    
    -- Create a matrix that aligns the Z-axis with the direction vector
    local zAxis = [0, 0, 1] -- default Z axis
    local rotationMatrix = matrixFromNormal direction
    
    -- Set the capsule's transformation matrix
    cap.transform = rotationMatrix
    
    -- Return the capsule object
    cap
)


fname = GetOpenFileName caption:"Shin Budokai" types:"All Known Formats|*.amo;*.bin|Model (*.amo)|*.amo"
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

amoOffset = ftell f
amo = ReadFixedString f 4
headerLength = readlong f
null = readlonglong f
boneCount = readlong f
boneDataTableOffset = readlong f
amgCount = readlong f
amgOffsetTable = readlong f 
boneDataCount = readlong f			-- how many possible amg data tables to associate with a bone
boneNameOffset = readlong f
print boneDataCount
struct _boneDataTable (
	boneID = readlong f,
	boneDataOffset = readlong f,
	childTableOffset = readlong f,		--pointer to another element of _boneDataTable relative to amo
	siblingTableOffset = readlong f,	--same as above
	parentTableOffset = readlong f,	--same as above
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

fn buildSkeleton boneDataTableArray boneDataTableOffset amoOffset boneNameList &BNArr= (
	x = 0
	for boneData in boneDataTableArray do (
		x += 1
		boneId = boneData.boneId + 1
		childId = (if boneData.childTableOffset > 0 then ((boneData.childTableOffset + amoOffset) -  boneDataTableOffset) as integer / 0x20 + 1 else 0)
		siblingId = (if boneData.siblingTableOffset > 0 then ((boneData.siblingTableOffset + amoOffset) -  boneDataTableOffset) as integer / 0x20 + 1 else 0)
		parentId = (if boneData.parentTableOffset > 0 then ((boneData.parentTableOffset + amoOffset) -  boneDataTableOffset) as integer / 0x20 + 1 else 0)
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
		newBone.wirecolor = orange
	 	newbone.name = boneNameList[x]
		newbone.showlinks = true
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
	for b in BNArr where b.children.count == 0 do b.wirecolor = green
	for b in BNArr do b.setskinpose()
)

fn getTransformBoneId boneDataArray boneId = (
	for i=1 to boneDataArray.count do (
		for j=1 to boneDataArray[i].count do (
			if boneDataArray[i][j].boneID == boneID do return i
		)
	)
)

fseek f boneDataTableOffset #seek_set
boneDataTableArray = for x=1 to boneCount collect (ReadFixedByteString f 0x20 1 0; table = _boneDataTable())

boneDataArray = #()
for boneDataTable in boneDataTableArray do (
	fseek f boneDataTable.boneDataOffset #seek_set
	append boneDataArray (for x=1 to boneDataCount collect (ReadFixedByteString f 0x10 1 0 ; boneData = _boneData()))
-- 	format "\n"
)

fseek f amgOffsetTable #seek_set
amgOffset = for x=1 to amgCount collect (readlong f)
	
fseek f boneNameOffset #seek_set
boneNameList = for x=1 to boneCount collect (ReadFixedString f 0x20)

BNArr = #()
buildSkeleton boneDataTableArray boneDataTableOffset amoOffset boneNameList BNArr
for x=1 to BNArr.count do format "% %\n" (x-1) BNArr[x].name

Mesh_Array = #()
vertPosOffsetReferenceArray=#()
vertNrmOffsetReferenceArray=#()

Weight_Array=#()

multiMat = MultiMaterial numsubs:0 showInViewport:true
meditMaterials[1] = multiMat

p = 0
for x=1 to amgCount do (	--amgCount
	fseek f amgOffset[x] #seek_set
	ReadFixedByteString f 0x20 1 0
	
	amg = ReadFixedString f 4
	headerLength = readlong f
	ukw = readlong f	--1, count?
	null = readlong f
	
	amgBoneCount = readlong f
	amgBoneOffset = readlong f + amgOffset[x]
	amgMatCount = readlong f
	amgBoneNameOffset = readlong f + amgOffset[x]
	
	fseek f amgBoneNameOffset #seek_set
	amgBoneNameList = for x=1 to amgBoneCount collect (ReadFixedString f 0x20)
	
	fseek f amgBoneOffset #seek_set
	amgDataTableList = for y=1 to amgBoneCount collect ((amgDataTable = _amgDataTable()).init f amgOffset[x]; amgDataTable)

	if multiMat.count == 1 do (
		multiMat.numSubs = amgMatCount
		for y=1 to multiMat.numSubs do (
			multiMat[y].diffuse = random black white
			multiMat[y].name = y as string
		)
	)
	
	q = 0
	pp = 0
	
	for y=1 to amgBoneCount do (	--amgBoneCount
		fseek f amgDataTableList[y].dataOffset #seek_set
-- 		print y
		--the first amgData is the main model, it has no rigid or blend weight data, it will be supplied weight data later
		--later amgData's if contain model data will have only rigid weight data
		--if amgData's have blend weight data there is no other data, its purpose is to supply weight data to main model
		
		ReadFixedByteString f 0x20 1 0
		boneId = readlong f + 1
		modelDataOffset = readlong f + amgOffset[x]					--main model
		modelDataOffset2 = readlong f + amgOffset[x]				--cel shade model
		blendWeightDataOffset = readlong f + amgOffset[x]
		rigidWeightDataOffset = readlong f + amgOffset[x]			--not used?
		matrixDataOffset = readlong f + amgOffset[x]					--matrix, transform/material?
		null = readlong f
		null2 = readlong f
		
		fseek f modelDataOffset #seek_set
		if modelDataOffset > amgOffset[x] do (
			Vert_Array=#()
			UV_Array=#()
			Face_Array=#()
			Normal_Array=#()
			Color_Array=#()
			matId_Array=#()
			
			skinDictionary = #()
			vertAdd = 0
			
			q += 1
			ReadFixedByteString f 0x20 1 0
			meshCount = readlong f
			meshOffsetTable = readlong f + modelDataOffset
			
			fseek f meshOffsetTable #seek_set
			meshOffsetList = for z=1 to meshCount collect (readlong f + modelDataOffset)
			for z=1 to meshCount do (
				p+=1
				fseek f meshOffsetList[z] #seek_set
				ReadFixedByteString f 0x40 1 0
				
				fseek f 0x18 #seek_cur
				ukwOffset3 = readlong f					--this is populated for non models, ff's otherwise
				ukwOffset4 = readlong f
				null = readlong f
				null2 = readlong f
				
				ukw0 = readshort f
				ukw1 = readshort f						--if has physics
-- 				printhex ukw
				matId = readlong f + 1
				ukw2 = readlong f
				ukw3 = readlong f
				null3 = readshort f
				subMeshCount = readshort f
				null4 = readlong f
				
-- 				print matID
				
				for a=1 to subMeshCount do (				
					ReadFixedByteString f 0x10 1 0
					nextSubMeshOffset = readlong f + modelDataOffset
					subMeshOffset = readlong f + modelDataOffset
					vertFlags = readshort f
					ukw = readshort f
					vertCount = readshort f
					faceType = readbyte f
					ukw = readbyte f
-- 					printhere f
-- 					printhex vertFlags
-- 					print"\n"
					for b=1 to vertCount do (
						if bit.get vertFlags 2 == true do (		--texVerts
							if bit.get vertFlags 1 == false do (	--shorts
								tu=readshort f / 32767.0
								tv=readshort f / 32767.0
								
								append UV_array([tu,1-tv,0])
							)
							if bit.get vertFlags 1 == true do (	--floats
								tu=readfloat f 
								tv=readfloat f
								
								append UV_array([tu,1-tv,0])
							)
						)
						if bit.get vertFlags 2 == false do (
							append UV_array([0,0,0])
						)
						if bit.get vertFlags 3 == true do (		--colors
							cr = readbyte f / 255.0
							cg = readbyte f / 255.0
							cb = readbyte f / 255.0
							ca = readbyte f / 255.0
							
							append Color_Array(color cr cg cb ca)
						)
						if bit.get vertFlags 7 == true do (		--normals
							if y == 1 do append vertNrmOffsetReferenceArray (ftell f)
							
							nx = readfloat f
							ny = readfloat f
							nz = readfloat f
							
							append Normal_Array([nx,ny,nz])
						)
						if bit.get vertFlags 9 == true do (		--positions
							if y == 1 do append vertPosOffsetReferenceArray (ftell f)
							
							vx=readfloat f 
							vy=readfloat f
							vz=readfloat f
							append Vert_Array([vx,vy,vz]*fscale)
						)
					)
					if faceType == 3 do (
						j=0
						k=0
						l=0
						
						For b=1 to vertcount by 3 do (
							j=b
							k=b+1
							l=b+2
							append Face_Array ([j,k,l] + vertAdd)
							append matId_Array matID
						)
					)
					if faceType == 4 do (
						
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
									append Face_Array ([f1,f2,f3] + vertAdd)
									append matId_Array matID
								)
								else (
									append Face_Array ([f1,f3,f2] + vertAdd)
									append matId_Array matID
								)
							)
							f1 = f2
							f2 = f3
						)
						while (j < (vertcount))
					)
					vertAdd += vertCount
				)
			)
			
			msh = mesh vertices:Vert_Array faces:Face_Array materialIDs:matId_Array
			msh.numTVerts = UV_array.count
			msh.wirecolor = random black white
			msh.backfacecull = off
-- 			msh.name = q as string + "_" + amgBoneNameList[boneId]
			msh.name = amgBoneNameList[y]
			msh.mat = multimat
			buildTVFaces msh    
			for j = 1 to UV_array.count do setTVert msh j UV_array[j]
			for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
			for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
			--format "\n"
			
			transformBoneId = getTransformBoneId boneDataArray boneId
			msh.parent = BNArr[transformBoneId]
			msh.transform = msh.parent.transform
			
			append Mesh_Array msh
			
		)
		fseek f blendWeightDataOffset #seek_set
		if blendWeightDataOffset > amgOffset[x] do (
			-- Budokai series does weighting backwards. Instead of having a list of refrences to bones and their weights per vertex, they have a list of weigths and vertices per bone
			-- each vertex has one bone influence
			-- per bone is a list of weights and per weight is a list of vertices that has that weight as an influence
			-- if the weight value is not 1.0 a second weight is generated at runtime?
			-- the second influence is the bone's parent?
			-- the second weight is generated only if the first one is under a certain value?
			gameSelection = 2
			if gameSelection == 1 do (
				-- for shin budokai 1 --
				
				fseek f 0x0c #seek_cur
				weightTableCount = readlong f
				for z=1 to weightTableCount do (
					--ReadFixedByteString f 0x10 1 0
					
					weight = readfloat f
					weightVertCount = readlong f
					weightVertOffset = readlong f + amgOffset[x]
					null = readlong f
				
					boneId2 = (finditem BNArr BNArr[boneID].parent)
					weight2 = 1.0 - weight
					
					if weight2 < 0.5 do weight2 = 0
					
					format "%	%	%\n" weight weight2 amgBoneNameList[y]
					backJump = ftell f
					
					fseek f weightVertOffset #seek_set
					for i=1 to weightVertCount do (
						--ReadFixedByteString f 0x30 1 0
						unkFloat = readfloat f
						unkFloat2 = readfloat f
						unkFloat3 = readfloat f
						unkFloat4 = readfloat f
						unkFloat5 = readfloat f
						unkFloat6 = readfloat f
						unkFloat7 = readfloat f
						
	-- 					currBBMax = [unkFloat,unkFloat2,unkFloat3]*fscale
	-- 					currBBMin = [unkFloat5,unkFloat6,unkFloat7]*fscale
	-- 					currA = currBBMax - currBBMin
	-- 					
	-- 					bb = box()
	-- 					bb.width = abs(currA[1])
	-- 					bb.length = abs(currA[2])
	-- 					bb.height = abs(currA[3])
	-- 					bb.transform *= BNArr[getTransformBoneId boneDataArray boneId].transform
	-- 					
	-- 					format "% % % % % % %\n" unkFloat unkFloat2 unkFloat3 unkFloat4 unkFloat5 unkFloat6 unkFloat7
						
	-- 					b = sphere()
	-- 					b.pos = ([unkFloat,unkFloat2,unkFloat3]*fscale) * BNArr[getTransformBoneId boneDataArray boneId].transform
	-- 					b.wirecolor = red
	-- 					
	-- 					b2 = sphere()
	-- 					b2.pos = (([unkFloat5,unkFloat6,unkFloat7]+[unkFLoat,unkFloat2,unkFloat3])*fscale) * BNArr[getTransformBoneId boneDataArray boneId].transform
	-- 					b2.wirecolor = green
	-- 					
	-- 					b.radius = 1
	-- 					b2.radius = 1
	-- 					b.transform *= BNArr[getTransformBoneId boneDataArray boneId].transform
	-- 					b2.transform *= BNArr[getTransformBoneId boneDataArray boneId].transform
	-- 					
	-- 					b2.parent = b
	-- 					b2.showlinks = true
	-- 					b.showlinks = true
	-- 					
	-- 					startPoint = b.pos
	-- 					endPoint = b2.pos
	-- 					radius = 1.0

	-- 					createCapsuleFromPoints startPoint endPoint radius

						vertOffset = readlong f 		--for main model
						vertOffset2 = readlong f		--for cel model
						null = readlong f
						null2 = readlong f
						null3 = readlong f
						
						for j = 1 to vertPosOffsetReferenceArray.count where vertPosOffsetReferenceArray[j] == vertOffset+amgOffset[x] do (
							Weight_Array[j] = #(#(boneId, boneId2), #(weight, weight2))
						)
					)
					fseek f backJump #seek_set
				)
			)
			if gameSelection == 2 do (
				-- for shin budokai 2 / evolution--
				
				ReadFixedByteString f 0x10 1 0
				weightTableCount = readlong f
				weightTableArray = for z=1 to weightTableCount collect (readlong f + amgOffset[x])
				
				for z=1 to weightTableCount do (
					fseek f weightTableArray[z] #seek_set
					ReadFixedByteString f 0x10 1 0
					
					weight = readfloat f
					vertOffsetTableCount = readlong f
					unk = readlong f	--pointer?
					vertOffsetTable = for a=1 to vertOffsetTableCount collect (readlong f + amgOffset[x])
					for a=1 to vertOffsetTableCount do (
						fseek f vertOffsetTable[a] #seek_set
						ReadFixedByteString f 0x30 1 0
						
						fseek f 0x1c #seek_cur
						vertOffsetCount = readlong f
						vertOffsetArray = for b=1 to vertOffsetCount collect (readlong f)
						
						for vertOffset in vertOffsetArray do (
							boneId2 = (finditem BNArr BNArr[boneID].parent)
							weight2 = 1.0 - weight
							
							nrmOffsetIndex = finditem vertPosOffsetReferenceArray (vertOffset+amgOffset[x])
							posOffsetIndex = finditem vertNrmOffsetReferenceArray (vertOffset+amgOffset[x])
							vertexIndex = if nrmOffsetIndex != 0 then nrmOffsetIndex else posOffsetIndex
							
							Weight_Array[vertexIndex] = #(#(boneId, boneId2), #(weight, weight2))
						)
						
						pp += vertOffsetCount
						
						--no alignment if last element
						-- it imediatley continues into next vertOffsetTable
						AlignOffset f (ftell f) 0x10
					)
-- 					format "\n"
				)
-- 				format "\n"
			)
		)
		/*
		fseek f rigidWeightDataOffset #seek_set
		if rigidWeightDataOffset > amgOffset[x] do (
			ReadFixedByteString f 0x10 1 0
			weightVertCount = readlong f
			weightVertOffset = readlong f + amgOffset[x]
			null = readlong f
			null2 = readlong f
			
			fseek f weightVertOffset #seek_set
			for a = 1 to weightVertCount do (
				ReadFixedByteString f 0x20 1 0
				
				fseek f 0x1c #seek_cur
				vertOffset = readlong f
			)
		)
		fseek f matrixDataOffset #seek_set
		if matrixDataOffset > amgOffset[x] do (
			m11 = readfloat f ; m12 = readfloat f ; m13 = readfloat f
			m21 = readfloat f ; m22 = readfloat f ; m23 = readfloat f
			m31 = readfloat f ; m32 = readfloat f ; m33 = readfloat f
			m41 = readfloat f ; m42 = readfloat f ; m43 = readfloat f
			m51 = readfloat f ; m52 = readfloat f ; m53 = readfloat f
		)*/
	)
	--printhex p
	--print pp
)

-- print vertOffsetReferenceArray.count

printhex Weight_Array.count
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


Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f

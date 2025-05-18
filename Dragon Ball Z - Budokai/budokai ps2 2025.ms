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
-- fname = @"C:\Users\Xaxa\Downloads\Budokai Models\B3GHC Exclusive Models\160a. Cell Jr. (Default).amo"
-- fname = @"C:\Users\Xavier\Downloads\Budokai Models\Budokai Models\B3GHC Exclusive Models\160a. Cell Jr. (Default).amo"
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

format "boneCount: %\n" boneCount
struct _boneDataTable (
	boneID = readlong f,
	boneDataOffset = readlong f,
	childTableOffset = readlong f,	--pointer to another element of _boneDataTable relative to amo
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
-- 		ReadFixedByteString f 0x50 1 1
		
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
-- print boneNameList

BNArr = #()
buildSkeleton boneDataTableArray boneDataTableOffset amoOffset boneNameList BNArr
for x=1 to BNArr.count do format "% %\n" (x-1) BNArr[x].name

Mesh_Array = #()
vertOffsetReferenceArray=#()
Weight_Array=#()

multiMat = MultiMaterial numsubs:0 showInViewport:true
meditMaterials[1] = multiMat

vertType1 = #()
vertType2 = #()

format "amg count: %\n" (bit.intashex(amgCount))
k = 7
for x=1 to amgCount do (	--amgCount
	fseek f amgOffset[x] #seek_set
	ReadFixedByteString f 0x20 1 0
	
	amg = ReadFixedString f 4
	headerLength = readlong f
	null = readlong f
	unk = readlong f	--4, count?
	
	amgBoneCount = readlong f
	amgBoneOffset = readlong f + amgOffset[x]
	amgMatCount = readlong f
	amgBoneNameOffset = readlong f + amgOffset[x]
	
	fseek f amgBoneNameOffset #seek_set
	amgBoneNameList = for x=1 to amgBoneCount collect (ReadFixedString f 0x20)
	
	fseek f amgBoneOffset #seek_set
	amgDataTableList = for y=1 to amgBoneCount collect ((amgDataTable = _amgDataTable()).init f amgOffset[x]; amgDataTable)
	
	if multiMat.numSubs < amgMatCount do multiMat.numSubs = amgMatCount
	
-- 	-- may cause problems later?
-- 	if multiMat.count == 1 do (
-- 		multiMat.numSubs = amgMatCount
-- 		for y=1 to multiMat.numSubs do (
-- 			multiMat[y].diffuse = random black white
-- 			multiMat[y].name = y as string
-- 		)
-- 	)
	
	for y=1 to amgBoneCount do (	--amgBoneCount
		fseek f amgDataTableList[y].dataOffset #seek_set
		-- amgDataTables either have modelData + matrixData or weightData
		
		ReadFixedByteString f 0x10 1 0
		boneId = readlong f + 1
		modelDataOffset = readlong f + amgOffset[x]
		weightDataOffset = readlong f + amgOffset[x]
		matrixDataOffset = readlong f + amgOffset[x]					--matrix, transform/material?
		
		fseek f modelDataOffset #seek_set
		if modelDataOffset > amgOffset[x] do (
			Vert_Array=#()
			UV_Array=#()
			Face_Array=#()
			Normal_Array=#()
			Color_Array=#()
			matId_Array=#()
			MatId_Array=#()
			MatId_Array2=#()
			
			skinDictionary = #()
			vertAdd = 0
			
			meshCount = readlong f
			meshOffsetTable = readlong f + modelDataOffset
			
			fseek f meshOffsetTable #seek_set
			meshOffsetList = for z=1 to meshCount collect (readlong f + modelDataOffset)
			for z=1 to meshCount do (	--meshCount
				fseek f meshOffsetList[z] #seek_set
				
-- 				format "% %\n" (bit.intashex(readlong f)) (bit.intashex(readlong f))
-- 				fseek f -0x08 #seek_cur
				
				vertexFlags = for a =1 to 8 collect (readbyte f #unsigned)
				texId = readlong f	 + 1		--diffuse texture
				texId2 = readlong f + 1		--color ramp texture
				fseek f 0x30 #seek_cur		--material info?
				
				baseOffset = ftell f
				fseek f 0x50 #seek_cur		--unknownData / always the same
				
				meshDataLength = readshort f * 0x10
				null = readbyte f
				meshDataOffset = readbyte f + baseOffset
				meshEndOffset = meshDataOffset + meshDataLength
				
				fseek f meshDataOffset #seek_set
				
				j = 0
				while (ftell f < meshEndOffset ) do (
					if (j += 1) >= 100 do exit
					
					unk = readlong f	--flags?
					null = readlong f
					null = readlong f
					vifCode = readlong f
					
					if vifCode != 0 do (
						faceType = readlong f
						vertexCount = readlong f
						fseek f 0x08 #seek_cur	-- null
						
						for b=1 to vertexCount do (
							if y == 1 do append vertOffsetReferenceArray (ftell f)	--if main model
							if vertexFlags[5] == 0xb4 or vertexFlags[5] == 0xbc then (
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
								append Color_Array( white)
							)
							else if vertexFlags[5] == 0xbd then (		
-- 								if vertexFlags[5] == 0xb6 do ReadFixedByteString f 0x30 1 1
								
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
								append Color_Array( white)
							)
							else if vertexFlags[5] == 0xb6 then (		
-- 								if vertexFlags[5] == 0xb6 do ReadFixedByteString f 0x30 1 1
								
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								f1 = readfloat f
								cr = readfloat f * 255.0
								cg = readfloat f * 255.0
								cb = readfloat f * 255.0
								ca = readfloat f * 255.0
								tu = readfloat f
								tv = readfloat f
								f3 = readfloat f
								null = readfloat f								
								
								append Vert_Array([vx,vy,vz]*fscale)
								append UV_Array([tu,-tv,0])
-- 								append Normal_Array([0,0,0])
								append Color_Array(color cr cg cb ca)
							)
							else if vertexFlags[5] == 0x90 then (
								vx = readfloat f
								vy = readfloat f
								vz = readfloat f
								f1 = readfloat f
								
								append Vert_Array([vx,vy,vz]*fscale)
								append UV_Array([0,0,0])
								append Normal_array[0,0,0]
								append Color_Array ( white)
							)
							else (
								format "unknown vertex format: % @ %\n" (bit.intashex(vertexFlags[5])) (bit.intashex(ftell f as integer))
								exit
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
			)
			
			msh = mesh vertices:Vert_array faces:Face_array
			msh.numTVerts = UV_array.count
			msh.wirecolor = random black white
			msh.backfacecull = off
			msh.name = amgBoneNameList[y]
			buildTVFaces msh    
			defaultVCFaces msh
-- 			setShadeCVerts msh true
-- 			setCVertMode msh true
			for j = 1 to UV_array.count do setTVert msh j UV_array[j]
			for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
			for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
			for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
			
			transformBoneId = getTransformBoneId boneDataArray boneId
			msh.parent = BNArr[transformBoneId]
			msh.transform = msh.parent.transform
		)
	)
)
print k
Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f

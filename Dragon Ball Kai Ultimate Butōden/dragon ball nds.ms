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
fn getString bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn buildFaces vertexCount vertexSum sectionType matID &Face_Array &MatId_Array= (
	if sectionType == 4 do (	--quads?
		a = 0
		b = 0
		c = 0
		d = 0
		
		for x=1 to vertexCount by 4 do (
			a = x
			b = x + 1
			c = x + 2
			d = x + 3
			
			append Face_array ([a,b,c] + vertexSum)
			append Face_array ([a,c,d]  + vertexSum)
			append MatId_Array (matID + 1)
			append MatId_Array (matID + 1)
		)
	)
	if sectionType == 3 do (
		
		a=0
		b=0
		c=0
		
		for x=1 to vertexCount by 3 do (
			a = x
			b = x + 1
			c = x + 2
			append Face_Array ([a,b,c] + vertexSum)
			append MatId_Array (matID + 1)
		)
	)
	return Face_Array
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

fname = GetOpenFileName caption:"" types:" (*.dse)|*.dse" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileFolder = getFileNamePath fname
clearlistener()
Global fscale=15
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _boneData (
	m11 = readlong f / 4096.0, m12 = readlong f / 4096.0, m13 = readlong f / 4096.0,
	m21 = readlong f / 4096.0, m22 = readlong f / 4096.0, m23 = readlong f / 4096.0,
	m31 = readlong f / 4096.0, m32 = readlong f / 4096.0, m33 = readlong f / 4096.0,
	m41 = readlong f / 4096.0, m42 = readlong f / 4096.0, m43 = readlong f / 4096.0,
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
)
struct _boneData2 (
	ukw = readshort f,							--0201
	ukw2 = readlong f,						--offset?
	ukw3 = readshort f,						--0001
	boneNameOffset = readlong f,		--geoshape/geol
	boneParentID = readshort f,
	boneSiblingID = readshort f,
	boneOffset = readlong f					--offset to element within _boneData
)
struct _meshData (
	meshNameOffset = readlong f,
	meshOffset = readlong f,
	ukw = readshort f,							--0x60/0x61
	ukw2 = readbyte f,						--null
	ukw3 = readbyte f,						--visableId?
	ukw4 = readshort f,
	meshScale = (2 ^ (readshort f))
)
struct _meshData2 (
	meshNameOffset = readlong f,
	meshBoneId = readlong f,
	meshId = readlong f,
	null = readlong f
)
struct _materialData (
	modelNameOffset = readlong f,
	ukw = readbyte f,					-- 0x0f
	ukw2 = readbyte f,				-- 0x01 / 0x02 / 0x03
	ukw3 = readbyte f,				-- 0x1f
	ukwId = readbyte f,				--visibleId?
	ukw4 = readshort f,				--0x6739
	null = readlong f,
	ukw5 = readshort f,				--0x1ce7
	textureId = readbyte f,
	skip = fseek f 0x13 #seek_cur
)
struct _textureData (
	texturePathOffset = readlong f,
	pixelOffset = readlong f,
	pixelUncompressedLength = readlong f,
	pixelCompressedLength = readlong f,
	paletteOffset = readlong f,
	paletteLength = readlong f,
	textureWidth = readshort f,
	textureHeight = readshort f,
	null = readlong f,
	null2 = readlong f,
	bitsPerPixel = readbyte f,
	ukw2 = readbyte f,
	ukw3 = readbyte f,
	paletteCount = readbyte f,
	textureNameOffset = readlong f,	-- points to substring of texturePath
	ukw4 = readbyte f,
	compressionType = readbyte f,
	ukw5 = readshort f					-- 0x7c4a
)
struct data8 (
	ukw = readlong f,	--longs?
	ukw2 = readlong f,
	ukw3 = readlong f
)
struct _sectionHeader (
	sectionOffset = ftell f,
	sectionType = readbyte f,
	ukw = readbyte f,
	materialId = readbyte f,			-- if sectionType is 2 then is materialId, else null
	boneIdCount = readbyte f,	-- if sectionType is 2 then 0x7c, for 3 or 4 is weight influence count
	sectionLength = readlong f,
	sectionEnd = sectionOffset + sectionLength
)

magic = ReadFixedString f 0x04
fseek f 0x1a #seek_cur

ukw = readshort f
ukw2 = readshort f
boneCount = readshort f
meshCount = readshort f
meshCount2 = readshort f
materialCount = readshort f
textureCount = readshort f

boneDataOffset = readlong f
boneDataOffset2 = readlong f
meshDataOffset = readlong f
meshDataOffset2 = readlong f
modelDataOffset = readlong f
texDataOffset = readlong f
stringBufferOffset = readlong f

ukwOffset8 = readlong f				--another baseOffset? / null
stringBufferOffset2 = readlong f	--another baseOffset? / same as stringBufferOffset
stringBufferLength = readlong f
fileNameOffset = readlong f		--rel to stringBufferOffset
dataOffset8 = readlong f
dataOffset9 = readlong f			--texture?
fileEndOffset = readlong f

baseOffset = ftell f
printhex baseOffset

format "boneCount: %	meshCount: %	materialCount: %	textureCount: %\n" (bit.intashex(boneCount)) (bit.intashex(meshCount)) (bit.intashex(materialCount)) (bit.intashex(textureCount))   

fseek f (boneDataOffset + baseOffset) #seek_set
boneDataArray = for x=1 to boneCount collect (ReadFixedByteString f 0x30 1 0 ; data = _boneData())

fseek f (boneDataOffset2 + baseOffset) #seek_set
boneDataArray2 = for x=1 to boneCount collect (ReadFixedByteString f 0x14 1 0 ; data = _boneData2())
	
fseek f (meshDataOffset + baseOffset) #seek_set
meshDataArray = for x=1 to meshCount collect (ReadFixedByteString f 0x10 1 0 ; data = _meshData())
	
fseek f (meshDataOffset2 + baseOffset) #seek_set
meshData2Array = for x=1 to meshCount2 collect (ReadFixedByteString f 0x10 1 0 ; data = _meshData2())
	
fseek f (modelDataOffset + baseOffset) #seek_set
materialDataArray = for x=1 to materialCount collect (ReadFixedByteString f 0x20 1 1 ; data = _materialData())
	
fseek f (texDataOffset + baseOffset) #seek_set
texDataArray = for x=1 to textureCount collect (ReadFixedByteString f 0x30 1 0 ; data = _textureData())
	
fseek f (dataOffset8) #seek_set
ukwData8 = for x=1 to boneCount collect (ReadFixedByteString f 0x0c 1 0 ; data = data8())

textureNameArray = #()
for textureData in texDataArray do (
	fseek f (textureData.textureNameOffset + stringBufferOffset2 + baseOffset) #seek_set
	textureName = readstring f
	append textureNameArray (substring textureName 1 (textureName.count - 4))
)	

multiMat = multimaterial()
multiMat.numSubs = textureCount
meditMaterials[1] = multiMat
for x=1 to textureCount do (
	multiMat[x].Diffuse = random black white
	
-- 	texturePath = FileFolder + ((x-1) as string) + ".png"
	texturePath = FileFolder + textureNameArray[x] + ".png"
	if (DoesFileExist texturePath) do (
		multiMat[x].selfIllumAmount = 100
		multiMat[x].diffuseMap = Bitmaptexture fileName:texturePath
		multiMat[x].diffuseMap.coords.u_mirror = true
		multiMat[x].diffuseMap.coords.v_mirror = true
	)
	multiMat[x].name = (x-1) as string
)

for x=1 to boneCount do (format "% %\n" (x-1) (getString f (boneDataArray2[x].boneNameOffset + baseOffset + stringBufferOffset)))

BNArr=#()
for x=1 to boneCount do (
	boneData = boneDataArray[x]
	boneData2 = boneDataArray2[x]
	
	parentID = boneData2.boneParentID + 1
	tfm = boneData.tfm
	tfm.pos *= fscale
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = inverse tfm
	newBone.name = (getString f (boneData2.boneNameOffset + baseOffset + stringBufferOffset))
 	
	--newBone.position = -tfm.row4
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if parentID != 0 do newBone.parent = BNArr[parentID]
	
	append BNArr newBone	
)
for b in BNArr where b.parent==undefined do 
	b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])

for x=1 to meshCount do (	--meshCount
	meshData = meshDataArray[x]
	meshData2 = meshData2Array[x]
	fseek f (meshData.meshOffset + baseOffset) #seek_set
-- 	print x
-- 	print meshData
-- 	
-- 	printhere f
-- 	format "%\n%\n\n" (getString f (meshData.meshNameOffset + baseOffset + stringBufferOffset)) (getString f (meshData2.meshNameOffset + baseOffset + stringBufferOffset))
-- 	format("%\n") (getString f (meshData.meshNameOffset + baseOffset + stringBufferOffset))
-- 	format "started at %\n" (bit.intashex(ftell f as integer))
-- 	print meshData
-- 	print meshData2
	
	vertexSum = 0
	materialId = undefined
	
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	MatId_Array=#()
	Color_Array=#()
	Weight_Array=#(#(),#())
	j = 0
-- 	print x
-- 	for x=1 to 1 do (
	while true do (	--per sectionType
		sectionHeader = _sectionHeader()
-- 		print sectionHeader
-- 		j = 0
		if sectionHeader.sectionType == 2 do (
			materialId = sectionHeader.materialId + 1
		)
		if sectionHeader.sectionType == 3 or sectionHeader.sectionType == 4 do (
			ReadFixedByteString f 0x18 1 0
			
			vertexCount = readshort f
			vertexStride = readbyte f
			vertexFlags = readbyte f
			
			--		87654321
			-- 19	00011001					tuv_h							vxyz_h	w1-n_h
			-- 1d	00011101					tuv_h	unk1_h				vxyz_h	w1-n_h
			-- 21	00100001	unk1234_b									vxyz_h	null_h
			-- 25	00100101	unk1234_b			unk1_h	unk2h		vxyz_h	null_h
			-- 29	00101001	unk1234_b	tuv_h							vxyz_h	null_h
			-- 2d	00101101	unk1234_b	tuv_h	unk1_h	unk2h 	vxyz_h	null_h
			--		87654321
			-- unk1234: colors? / one vertex has this but no uv's
			-- unk1:    looks like unk4 in meshData
			-- unk2:    null / latter half of int?
			-- unk3:    null / is the same as w1-n?
			-- unk?:	 is unk1?# 
			-- 0: positions
			-- 1: 0
			-- 2: unk1
			-- 3: uv's
			-- 4: weights
			-- 5: unk1234_b
			-- 6: 0
			-- 7: 0
			
-- 			format "% %\n" (bit.intashex(vertexStride)) (bit.intashex(vertexFlags))
-- 			ReadFixedByteString f 0x14 1 1
			
-- 			print materialDataArray[materialId].ukw2 as string
			
			ukw = readlong f	-- 0x0c / flags? / only non null if boneIdCount is non null
			boneIdArray = for y=1 to sectionHeader.boneIdCount collect readshort f + 1
			fseek f (0x10 - (2 * boneIdArray.count)) #seek_cur	--null
			if boneIdArray.count != 0 do print boneIdArray #nomap
			
-- 			for z=1 to 16 do format "% %\n" z (bit.get vertexFlags z)
-- 			print boneIdArray.count
			for z=1 to vertexCount do (
				vertexBaseOffset = ftell f
-- 				if z < 50 do ReadFixedByteString f vertexStride 1 1
				
				if (bit.get vertexFlags 6) == true do (	-- colors
					cr = readbyte f #unsigned
					cg = readbyte f #unsigned
					cb = readbyte f #unsigned
					ca = readbyte f #unsigned
				)
				if (bit.get vertexFlags 4) == true do (	-- uv's
					tu = readshort f / 4096.0
					tv = readshort f / 4096.0
					
					append UV_Array([tu,1-tv,0])
				)
				if (bit.get vertexFlags 4) == false do (	-- uv's
					append UV_Array([0,0,0])
				)
				if (bit.get vertexFlags 3) == true do (	-- unk
					unk = readshort f / 4096.0
					
					if boneIdArray.count == 0 do (
						null = readshort f
					)
				)
				if (bit.get vertexFlags 1) == true do (	-- positions
					vx = readshort f / 4096.0
					vy = readshort f / 4096.0
					vz = readshort f / 4096.0
					
					if boneIdArray.count == 0 do (
						null = readshort f
						
						if null != 0 do print "pie"
					)
					
					append Vert_Array([vx,vy,vz] * meshData.meshScale * fscale)
				)
				if (bit.get vertexFlags 5) == true do (	-- weights
					append Weight_Array[1] (for y=1 to boneIdArray.count collect (readshort f / 4096.0))
					append Weight_Array[2] boneIdArray
				)
				
				fseek f (vertexBaseOffset + vertexStride) #seek_set	-- just in case
			)
			AlignOffset f (ftell f) 4
-- 			format "\n"
			
			textureId = materialDataArray[materialId].textureId
			buildFaces vertexCount vertexSum sectionHeader.sectionType textureId Face_Array MatId_Array
			vertexSum += vertexCount
		)
		if sectionHeader.sectionType == 1 do (
			exit
		)
	)
-- 	format "\n"
	
-- 	print Weight_Array[1] #nomap
-- 	print Weight_Array[2] #nomap
-- 	print Vert_Array.count
-- 	format "\n"
	
	--if Weight_Array[1].count != 0 do (
		materialData = materialDataArray[materialId]
		materialName = (getString f (materialData.modelNameOffset + baseOffset + stringBufferOffset))
		
		msh = mesh vertices:Vert_Array faces:Face_Array materialids:MatId_Array
		msh.numTVerts = UV_Array.count
		msh.mat = multiMat
-- 		msh.name = (x as string)
		msh.name = materialName
-- 		msh.name = BNArr[meshData2.meshBoneId + 1].name
	-- 	msh.name = (materialId as string)
	-- 	msh.name = materialData.ukwId as string
	-- 	msh.name = materialData.ukw2 as string
	-- 	msh.wirecolor = random black white
		msh.wirecolor = white
-- 		msh.name = meshData.ukw3 as string
	-- 	msh.name = (bit.intashex(j)) as string
		buildTVFaces msh
	-- 	defaultVCFaces msh
	-- 	setShadeCVerts msh true
	-- 	setCVertMode msh true
		for j = 1 to UV_Array.count Do setTVert msh j UV_Array[j]
		for j = 1 to Face_Array.count Do setTVFace msh j Face_Array[j]
	-- 	for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
		msh.transform = BNArr[meshData2.meshBoneId + 1].transform
		msh.parent = BNArr[meshData2.meshBoneId + 1]
		
		
		if Weight_Array[1].count != 0 do (
		-- Applying Skinning --
		max modify mode
		select msh
		
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to BNArr.count do (
			maxbone = getnodebyname BNArr[i].name
			if i != BNArr.count then
				skinOps.addBone skinMod maxbone 0
			else
				skinOps.addBone skinMod maxbone -1
		)
		-- Applying Weights --
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_Array[1].count do (
			w = Weight_Array[1][i]
			b = Weight_Array[2][i]
			
-- 			print w #nomap
-- 			print b #nomap
-- 			format "\n"
			
			--format "% % %\n" (i-1) w[1] w[2] 
			
		-- 	skinOps.ReplaceVertexWeights skinMod i w[1] w[2]
			skinOps.SetVertexWeights skinMod i b w
		-- 	print (skinOps.GetVertexWeight skinMod i 1)
		)
		deselect msh
	)
	--)
)

actionMan.executeAction 0 "63545"
Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
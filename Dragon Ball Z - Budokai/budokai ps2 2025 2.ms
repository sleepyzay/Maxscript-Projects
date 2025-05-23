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
			str+=" "
		)
		str = (str+instring)
	)
	else (
		for i = 1 to len do(
			str+=" ";str[i]=instring[i]
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

-- fname = GetOpenFileName caption:"Budokai PS2" types:"All Known Formats|*.amo;*.bin|Model (*.amo)|*.amo"
-- fname = @"C:\Users\Xavier\Downloads\Budokai Models\Budokai Models\074. Android 16 (Default).amo"
fname = @"C:\Users\Xavier\Downloads\Budokai Models\Budokai Models\277. Gogeta (Default) - SSJ.amo"
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

struct _boneData (
	boneID = readlong f,
	groupDataOffset = readlong f,
	childTableOffset = readlong f,		--pointer to another element of _boneData relative to amo
	siblingTableOffset = readlong f,	--same as above
	parentTableOffset = readlong f,	--same as above
	null = (fseek f 0x0c #seek_cur)
)
struct _groupData (				-- L_XX / up to 0x13 of these per bone
	amgId = readlong f + 1,
	boneId = readlong f + 1,	-- can exceed amo's defined boneCount
	amgDataTableOffset = readlong f,	-- pointer to a specific matrix inside of amg number amgId
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
    fn init f = (
		c11 = readfloat f; c12 = readfloat f; c13 = readfloat f; c14 = readfloat f
		c21 = readfloat f; c22 = readfloat f; c23 = readfloat f; c24 = readfloat f 
		c31 = readfloat f; c32 = readfloat f; c33 = readfloat f; c34 = readfloat f
		tfm = inverse (quat c11 c12 c13 c14) as matrix3
		tfm.row4 = ([c21,c22,c23]*fscale)
		
		ukw = readshort f
		ukw2 = readshort f
		dataOffset = readlong f
		childOffset = readlong f
		siblingOffset = readlong f
		parentOffset = readlong f
		null = readlong f
		null2 = readlong f
		null3 = readlong f
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
groupCount = readlong f			-- how many possible amg data tables to associate with a bone
boneNameOffset = readlong f

fseek f boneDataOffset #seek_set
boneDataArray = for x=1 to boneCount collect (ReadFixedByteString f 0x20 1 0; table = _boneData())

fseek f amgOffsetTable #seek_set
amgOffsetArray = for x=1 to amgCount collect (readlong f)	
	
fseek f boneNameOffset #seek_set
boneNameArray = for x=1 to boneCount collect (ReadFixedString f 0x20)
	
Weight_Array=#()
vertOffsetReferenceArray=#()

BNArr = #()
for x = 1 to boneCount do (
	boneData = boneDataArray[x]
	
	boneId = boneData.boneId + 1
	childId = (if boneData.childTableOffset > 0 then (boneData.childTableOffset -  boneDataOffset) as integer / 0x20 + 1 else 0)
	siblingId = (if boneData.siblingTableOffset > 0 then (boneData.siblingTableOffset -  boneDataOffset) as integer / 0x20 + 1 else 0)
	parentId = (if boneData.parentTableOffset > 0 then (boneData.parentTableOffset -  boneDataOffset) as integer / 0x20 + 1 else 0)
-- 	format "%	%	%	%	%	%\n" boneId childId siblingId parentId BNArr.count boneNameArray[x]
	
	fseek f boneData.groupDataOffset #seek_set
	groupDataArray = for y=1 to groupCount collect (groupData = _groupData())
	
	groupData = groupDataArray[1]
	fseek f groupData.amgDataTableOffset #seek_set											-- For now I only wan't the first one
	amgDataTable = ((amgDataTable = _amgDataTable()).init f ; amgDataTable)	-- Why can't maxscript have classes?
	
	amgOffset = amgOffsetArray[groupData.amgId]
	fseek f (amgDataTable.dataOffset + amgOffset) #seek_set
-- 	ReadFixedByteString f 0x10 1 1
	
	boneId = readlong f + 1									-- same as boneId?, for skinning referencing?
	modelDataOffset = readlong f + amgOffset
	weightDataOffset = readlong f + amgOffset
	matrixDataOffset = readlong f + amgOffset		-- matrix, transform/material?
	
	format "%	%	%	%	%\n" (bit.intashex(boneId)) (paddstring 8 (bit.intashex(modelDataOffset))) (paddstring 8 (bit.intashex(weightDataOffset))) (paddstring 8 (bit.intashex(matrixDataOffset))) boneNameArray[x]
	
	fseek f modelDataOffset #seek_set
	if modelDataOffset > amgOffset then (
		Vert_Array=#()
		UV_Array=#()
		Face_Array=#()
		Normal_Array=#()
		Color_Array=#()
		MatId_Array=#()
		MatId_Array2=#()
		
		skinDictionary = #()
		vertAdd = 0
		
		meshCount = readlong f
		meshOffsetTable = readlong f + modelDataOffset
		
		fseek f meshOffsetTable #seek_set
		meshOffsetArray = for z=1 to meshCount collect (readlong f + modelDataOffset)
		
		for z=1 to meshCount do (	--meshCount
			fseek f meshOffsetArray[z] #seek_set
			
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
			
			while (ftell f < meshEndOffset ) do (
				unk = readlong f	--flags?
				null = readlong f
				null = readlong f
				vifCode = readlong f
				
				if vifCode != 0 do (
					faceType = readlong f
					vertexCount = readlong f
					fseek f 0x08 #seek_cur	-- null
					for b=1 to vertexCount do (
						if boneID == 1 do append vertOffsetReferenceArray (ftell f)	--if main model
						
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
						else if vertexFlags[5] == 0x36 or vertexFlags[5] == 0xb6 then (		
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
							append Color_Array(color cr cg cb ca)
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
							append Color_Array(white)
						)
						else if vertexFlags[5] == 0x12 then (
-- 								ReadFixedByteString f 0x20 1 1
							
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							cr = readfloat f * 255.0
							cg = readfloat f * 255.0
							cb = readfloat f * 255.0
							ca = readfloat f * 255.0
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([0,0,0])
							append Color_Array(color cr cg cb ca)
						)
						else if vertexFlags[5] == 0x99 then (
-- 								ReadFixedByteString f 0x20 1 1
							
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							nx = readfloat f 
							ny = readfloat f 
							nz = readfloat f 
							f2 = readfloat f 
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([0,0,0])
							append Normal_Array([nx,ny,nz])
							append Color_Array(white)
						)
						else if vertexFlags[5] == 0x90 then (
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							f1 = readfloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
							append UV_Array([0,0,0])
							append Normal_array[0,0,0]
							append Color_Array (white)
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
		msh.name = boneNameArray[x]
		buildTVFaces msh    
		for j = 1 to UV_array.count do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
		
		if parentId != 0 do (
			msh.transform *= BNArr[parentId].objecttransform
			msh.parent = BNArr[parentId]
		)
		append BNArr msh
	)
	else (
		newBone = bonesys.createbone	\
		amgDataTable.tfm.row4	\
		(amgDataTable.tfm.row4 + 0.01 * (normalize amgDataTable.tfm.row1)) \
		(normalize amgDataTable.tfm.row3)
		newBone.width  = 0.01
		newBone.height = 0.01
		newBone.transform = amgDataTable.tfm
		newBone.setBoneEnable false 0
		newBone.wirecolor = orange
		newbone.name = boneNameArray[x]
		newbone.showlinks = true
		newBone.pos.controller      = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()
		
		if parentId != 0 do (
			newBone.transform *= BNArr[parentId].objecttransform
			newBone.parent = BNArr[parentId]
		)
		append BNArr newBone
	)
	
	fseek f weightDataOffset #seek_set
	if weightDataOffset > amgOffset do (
		fseek f 0x0c #seek_cur
		weightTableCount = readlong f
		for z=1 to weightTableCount do (			
			weight = readfloat f
			weightVertCount = readlong f
			weightVertOffset = readlong f + amgOffset
			weightVertCount2 = readlong f
			weightVertOffset2 = readlong f + amgOffset
			fseek f 0x0c #seek_cur	--null
			
			boneId2 = (finditem BNArr BNArr[boneID].parent)
			weight2 = 1.0 - weight
			
			backJump = ftell f
			
			fseek f weightVertOffset #seek_set
			if weightVertOffset > amgOffset do (
				for i=1 to weightVertCount do (					
					ux = readfloat f				-- for collision?
					uy = readfloat f
					uz = readfloat f
					vertOffset = readlong f
					ux2 = readfloat f
					uy2 = readfloat f
					uz2 = readfloat f
					null = readlong f
					
					Weight_Array[finditem vertOffsetReferenceArray (vertOffset + amgOffset)] = #(#(boneId, boneId2), #(weight, weight2))
				)
			)
			
			fseek f weightVertOffset2 #seek_set
			if weightVertOffset2 > amgOffset do (	-- only for mouth and hair?
				for i=1 to weightVertCount2 do (
-- 						ReadFixedByteString f 0x10 0 1
					
					ux = readfloat f				-- for collision?
					uy = readfloat f
					uz = readfloat f
					vertOffset = readlong f
					
					Weight_Array[finditem vertOffsetReferenceArray (vertOffset + amgOffset)] = #(#(boneId, boneId2), #(weight, weight2))
				)
			)
			fseek f backJump #seek_set
		)
	)
)
-- rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
-- for b in BNArr where b.parent==undefined do b.parent = rootRT
-- rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
-- for b in BNArr where b.children.count == 0 do b.wirecolor = green
-- for b in BNArr do b.setskinpose()

-- with new way of building model the meshes are considred the same as bones so the main model can't add the body bone to the
-- skin modifier twowing it off and breaking the skinning
if Weight_Array.count != 0 do (
	-- Applying Skinning --
	max modify mode
	select BNArr[1]
	skinMod = skin ()
	addModifier BNArr[1] skinMod
	
	for i = 1 to BNArr.count do (
		maxbone = getnodebyname boneNameArray[i]
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

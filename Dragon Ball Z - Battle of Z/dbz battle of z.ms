--sleepyzay--

fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn AddHexaDecimalPadding nr = (
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
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
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
fn ReadBEshort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn readbelong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
fn readbefloat fstream = (
return floatSwap2(readfloat fstream)
)
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)  
fn ApplyNormals msh Normal_array = (
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
	max create mode

)

struct vertElement (
	usage,
	usageIndex,
	type,
	null,
	offset
)
struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"Battle of Z" types:"(*.mdl)|*.mdl"
-- fname=@"D:\stuff\models\ripped\dbz battle of z\ch_colmt.mdl"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

ENDIBIGE = ReadFixedString f 8
null = readlonglong f

MDL_HEAD = ReadFixedString f 8
headLength = readbelong f
null = readbelong f
fseek f headLength #seek_cur

MDL_HDE2 = ReadFixedString f 8
hde2Length = readbelong f
null = readbelong f
fseek f hde2Length #seek_cur

MDL_HDET = ReadFixedString f 8
hdetLength = readbelong f
null = readbelong f

texCount=readbelong f
mtlbCount=readbelong f	--blocks 0x1a0 long
ukwCount=readbelong f
boneCount=readbelong f	--blocks 0x50 long
ukwCount2=readbelong f
fseek f 0x0c #seek_cur		--null
ukwHash = readbelong f
ukwHash2 = readbelong f
fseek f 0x08 #seek_cur		--null
fseek f 0x10 #seek_cur

MDL_STHB = ReadFixedString f 8
sthbLength=readbelong f
null=readbelong f
stringCount=readbelong f
tableLength=readbelong f
stringBufferLength=readbelong f
null=readbelong f

stringHash=#()
stringOffset=#()
for x=1 to stringCount do (
	stringHash[x] = readbelong f
	stringOffset[x] = readbelong f
)
AlignOffset f (ftell f) 16

stringArr=#()
stringBufferOffset = ftell f
for x=1 to stringCount do (
	fseek f (stringOffset[x] + stringBufferOffset) #seek_set
	dataString = readstring f
	
	append stringArr dataString
	
	format "%	%\n" (bit.intashex(stringHash[x])) dataString
)
AlignOffset f (ftell f) 16
printHere f

-- fseek f (tableLength + stringLength) #seek_cur

MDL_MTDT = ReadFixedString f 8
mtdtLength=readbelong f
null = readbelong f
fseek f mtdtLength #seek_cur

MDL_IMGB = ReadFixedString f 8 
imgbLength = readbelong f
null = readbelong f
fseek f IMGBLength #seek_cur

MDL_MTLB = ReadFixedString f 8 
mtlbLength=readbelong f
null = readbelong f
fseek f mtlbLength #seek_cur

MDL_NDEB = ReadFixedString f 8 
ndebLength=readbelong f
null = readbelong f

BNArr = #()
for x=1 to boneCount do (
	boneName = stringArr [(findItem stringHash (readbelong f))]
	parentID = readbelong f + 1
	ukw2 = readbelong f	--non body bones
	ukw3 = readbelong f	--always 1

	m11 = readbefloat f; m12 = readbefloat f; m13 = readbefloat f; m14 = readbefloat f
	m21 = readbefloat f; m22 = readbefloat f; m23 = readbefloat f; m24 = readbefloat f
	m31 = readbefloat f; m32 = readbefloat f; m33 = readbefloat f; m34 = readbefloat f
	m41 = readbefloat f; m42 = readbefloat f; m43 = readbefloat f; m44 = readbefloat f
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = false
	newBone.transform =  tfm
	newBone.name = boneName
	
	pos = [m41,m42,m43]
	pos = pos * tfm
	
	newbone.pos += pos
	newbone.pos *= fscale
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()

	append BNArr newBone
	if (parentID != 0) then (
	newBone.parent = BNArr[parentID]
	newBone.transform = newBone.transform * (newBone.parent.transform)
   )
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
delete rootRT

MDL_TMP = ReadFixedString f 8
fseek f -8 #seek_cur

if MDL_TMP == "MDL INVB" do (
	MDL_INVB = ReadFixedString f 8 
	invbLength=readbelong f
	null=readbelong f
	
	headerLength = readbelong f
	nodeCount = readbelong f
	nodeTable = readbelong f
	nodeTableLength = readbelong f
	nodeOffset = readbelong f
	nodeLength=readbelong f
	fseek f 0x08 #seek_cur	--null
	
	boneMap = for x=1 to nodeCount collect (readbelong f + 1)
	format "boneMapCount = %\n" boneMap.count
	AlignOffset f (ftell f) 16
	for x=1 to nodeCount do (
		m11 = readbefloat f; m12 = readbefloat f; m13 = readbefloat f; m14 = readbefloat f
		m21 = readbefloat f; m22 = readbefloat f; m23 = readbefloat f; m24 = readbefloat f
		m31 = readbefloat f; m32 = readbefloat f; m33 = readbefloat f; m34 = readbefloat f
		m41 = readbefloat f; m42 = readbefloat f; m43 = readbefloat f; m44 = readbefloat f
		tfm = inverse (matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44])
	)
)

MDL_GEOB = ReadFixedString f 8 
geobLength=readbelong f
geobHeaderLength=readbelong f
meshOffet=readbelong f	
meshCount=readbelong f
fseek f 0x08 #seek_cur	--null

format "meshCount = %\n\n" meshCount

mshArr=#()
for x=1 to meshCount do (	--meshCount	
	MDL_GEO = ReadFixedString f 8 
	geoLength = readbelong f
	geoHeaderLength=readbelong f
	meshName = stringArr [(findItem stringHash (readbelong f))]
	polyElmCount=readbelong f
	fseek f 0x08 #seek_cur	--null
	
	for y=1 to polyElmCount do (	--polyElmCount
		Face_array=#()
		Vert_array=#()
		UV_array=#()
		Normal_array=#()
		Weight_array=#()
		blendIndicesArray=#()
		blendWeightArray=#()
		
		MDL_SGEO = ReadFixedString f 8 
		sgeoLength = readbelong f
		sgeoBlockLength = readbelong f
		ukw13=readbelong f		--always 1
		ukw14=ReadBEshort f	--always 8
		ukwID=ReadBEshort f	-- ukw id?
-- 		printHex ukwID
		
		fseek f 0x08 #seek_cur	--null
		fseek f 0x20 #seek_cur	-- bounding box info
		vertElmCount=readbelong f
		vertDecTableOffset=readbelong f
		vertDecTableLength=readbelong f
		vertStride=readbelong f
		
		decTable =#()
		for y=1 to vertElmCount collect (
			vertElm = vertElement()
			
			vertElm.usage = readbelong f 
			vertElm.usageIndex = readbelong f 
			vertElm.type = readbelong f 
			vertElm.null = readbelong f 
			vertElm.offset =	readbelong f 
			fseek f 0x0c #seek_cur	--null
			
			append decTable vertElm
		)
		print decTable
		format "\n"
		
		MDL_GEOP = ReadFixedString f 8 
		geopLength = readbelong f
		null = readbelong f
		ukw13=readbelong f			--always 3
		fseek f 0x0c #seek_cur		--null
		vertCount=readbelong f
		vertOffset=readbelong f	--relative to the offset of MDLGEOP + 0x10
		vertLength=readbelong f
		null=readbelong f
		faceCount=readbelong f
		faceOffset = readbelong f	-- same so here
		faceLength=readbelong f
		null=readbelong f
		
		for y=1 to vertCount do (
			vertRef = ftell f
			for z=1 to vertElmCount do (
				vertElm = decTable[z]
				fseek f (vertElm.offset + vertRef) #seek_set
				case vertElm.usage of (
					0x00:(	--position
						vx = readbefloat f
						vy = readbefloat f
						vz = readbefloat f
						
						append Vert_array([vx,vy,vz]*fscale)
					)
					0x01:(	--blendweight
						weight1 = readbyte f #unsigned / 255.0
						weight2 = readbyte f #unsigned / 255.0
						weight3 = readbyte f #unsigned / 255.0
						weight4 = readbyte f #unsigned / 255.0
						
						append blendWeightArray [weight1,weight2,weight3,weight4]
						
						--if vertStride == 0x24 do print (weight1+weight2+weight3+weight4)
					)
					0x02:(	--blendindices
						bone1 = readbyte f #unsigned + 1
						bone2 = readbyte f #unsigned + 1
						bone3 = readbyte f #unsigned + 1
						bone4 = readbyte f #unsigned + 1
						
						append blendIndicesArray [bone1,bone2,bone3,bone4]
						
						--if vertStride == 0x24 do format "% % % % \n" bone1 bone2 bone3 bone4
					)
					0x03:(	--normal
						nx = readbefloat f
						ny = readbefloat f
						nz = readbefloat f
						
						append Normal_array [nx,ny,nz]
					)
					0x05:(	--texcoord
						tu = ReadBEHalfFloat f
						tv = ReadBEHalfFloat f
						
						if UV_array[vertElm.usageIndex + 1] == undefined do UV_array[vertElm.usageIndex + 1] = #()
						append UV_array[vertElm.usageIndex + 1]([tu,1 + -tv,0] * 2)
					)
					0x06:(	--tangent
						tx = readbefloat f
						ty = readbefloat f
						tz = readbefloat f
					)
					0x07:(	--binormal
						bnx = readbefloat f
						bny = readbefloat f
						bnz = readbefloat f
					)
				)
			)
			fseek f (vertRef + vertStride) #seek_set
		)
		
		for y=1 to blendWeightArray.count do (			--blend weight/indices
			--format "%\n%\n\n" blendIndicesArray[y] blendWeightArray[y]
			w = (weight_data boneids:#() weights:#())
			
			bone1 = blendIndicesArray[y][1]
			bone2 = blendIndicesArray[y][2]
			bone3 = blendIndicesArray[y][3]
			bone4 = blendIndicesArray[y][4]
			
			weight1 = blendWeightArray[y][1]
			weight2 = blendWeightArray[y][2]
			weight3 = blendWeightArray[y][3]
			weight4 = blendWeightArray[y][4]
			
			maxweight = 0
			if(weight1 != 0) then
				maxweight = maxweight + weight1
			if(weight2 != 0) then
				maxweight = maxweight + weight2
			if(weight3 != 0) then
				maxweight = maxweight + weight3
			if(weight4 != 0) then
				maxweight = maxweight + weight4
			
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
			
			append Weight_Array w
		)
		
		AlignOffset f (ftell f) 16
		
		for y=1 to faceCount/3 do(
			fa=ReadBEShort f +1
			fb=ReadBEShort f +1
			fc=ReadBEShort f +1
			append Face_array[fa,fb,fc]
		)
		AlignOffset f (ftell f) 16
		
 		if UV_array.count == 0 do UV_array[1] = Vert_array
		
		msh = mesh vertices:Vert_array faces:Face_array 
		msh.numTVerts = UV_array[1].count
		buildTVFaces msh
		msh.name = meshName
		for j = 1 to UV_array[1].count do setTVert msh j UV_array[1][j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
		msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		UV_Array2=#()
		numUVChannels = 0
		for o in UV_Array where o != undefined do (
			numUVChannels += 1
			append UV_Array2 o
		)
		print numUVChannels
		if numUVChannels > 1 do (
 			meshop.setNumMaps msh (2 + (numUVChannels - 1)) keep:true
			j = 2
			for y=2 to numUVChannels do (	--first array used for uv channel 0, so skip
				for i = 1 to UV_Array2[y].count do meshop.setMapVert msh j i UV_Array2[y][i]
				j+=1
			)
		)
		
		
		if Weight_Array.count > 0 do (
			-- Applying Skinning --
			count = msh.numverts
			max modify mode
			select msh
			skinMod = skin ()
			addModifier msh skinMod
			for i = 1 to boneMap.count do (
			   maxbone = getnodebyname BNArr[boneMap[i]].name
			   skinOps.addBone skinMod maxbone 1
			)
			-- Applying Weights --
			select msh
			modPanel.setCurrentObject skinMod
			for i = 1 to Weight_Array.count do (
				w = Weight_Array[i]
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
			deselect msh
		)
		
-- 		if mshArr[x] == undefined do mshArr[x] = #()
-- 		append mshArr[x] msh
	)
)

-- MDL_IGOB = ReadFixedString f 0x08
-- igobLength = readbelong f
-- null = readbelong f
-- for x=1 to meshCount do (
-- 	
-- 	boneID = readbelong f + 1
-- 	meshID = readbelong f + 1
-- 	meshType = readbelong f	--1 = hands, 2 = body
-- 	fseek f 0x08 #seek_cur	--null
-- 	
-- 	for a in mshArr[x] do a.transform = BNArr[boneID].transform
-- )




Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
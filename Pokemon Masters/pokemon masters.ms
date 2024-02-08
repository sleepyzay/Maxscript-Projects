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
fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream as integer))as string))
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
	strLength = readlong bstream
	str = ReadFixedString bstream strLength
	fseek bstream backJump #seek_set
	return str
)
fn getMatIdByName multiMat matName = (
	matID = undefined
	for x=1 to multiMat.count do (
		matID = x
		if multiMat[x].name == matName do return x
	)
)
fn getVal bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newVal = readbelong f
	fseek bstream backJump #seek_set
	return newVal
)
fn signVal x size= (
	if (bit.get x size) do (
		bitMask = 0
		for i=1 to size do bitMask = bit.set bitMask i true
		
		x = bit.xor x bitMask
		x += 1	--because of 2's complement
		x *= -1
	)
	return x
)
fn readbits pos range num = (
	local i = 0, result = 0, c = 1
	local val = num
	for i = pos to ((pos - 1) + range) do (
		result = bit.set result c (bit.get val i);c+=1
		)
	result
)
fn unpackNormal format divisor val = (
	result = [0,0,0]
	pos = 1
	for x=1 to 3 do (
		result[x] = signVal (readBits pos format[x] val) format[x]
		pos+=format[x]
	)
	result/=divisor
)

struct vertElement (
	usage,
	count,
	offset,
	type
)
struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"" types:" (*.)|*.lmd" historyCategory:""
-- fname=@"C:\Users\Owner\Desktop\New folder (2)\ch0000_00_red.lmd"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

fseek f 0x18 #seek_set
dataTableOffset = readlong f + (ftell f - 4)
fseek f dataTableOffset #seek_set
fseek f 0x0c #seek_cur	--can read data but don't need to
dataCount = readlong f
dataType = for x=1 to dataCount collect (getString f (readlong f + (ftell f - 4)))

boneDataOffset=0
matDataOffset=0
meshDataOffset=0	

fseek f 0x34 #seek_set
for x=1 to dataCount do (
	case dataType[x] of (
		"bone":(
			boneDataOffset = readlong f + (ftell f - 4)
		)
		"material":(
			matDataOffset = readlong f + (ftell f - 4)
		)
		"mesh":(
			meshDataOffset = readlong f + (ftell f - 4)
		)
		default:(
			print dataType[x]
		)
	)
)

/*
--dosent always work
fseek f matDataOffset #seek_set
tags = readlong f
matDataLength = readlong f
matTableOffset = (readlong f + (ftell f - 4))

fseek f matTableOffset #seek_set
matCount = readlong f
matOffset = for x=1 to matCount collect (readlong f + (ftell f - 4))
	
multiMat = multimaterial()
multiMat.numSubs = matCount
meditMaterials[1] = multiMat
for x=1 to matCount do (
	fseek f matOffset[x] #seek_set
	
	tags = readlong f
	matName = getString f (readlong f + (ftell f - 4))
	texName = getString f (readlong f + (ftell f - 4))
	
	multiMat[x].name = matName
	multiMat[x].selfIllumAmount = 100

-- 	print matName
-- 	print texName
-- 	format "\n"
)
*/

fseek f boneDataOffset #seek_set
tags = readlong f
ukw2 = readlong f
boneCount = readlong f
boneOffset = for x=1 to boneCount collect (readlong f + (ftell f - 4))

BNArr=#()
boneName=#()
parentName=#()
for x=1 to boneCount do (
	fseek f boneOffset[x] #seek_set
	
	tags = readlong f
	boneName[x] = (getString f (readlong f + (ftell f - 4)))
	
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	
	parentName[x] = (getString f (readlong f + (ftell f - 4)))
	childTableOffset = readlong f + (ftell f - 4)
	ukw5 = readlong f	--ID?
	
	
-- 	fseek f childTableOffset #seek_set
-- 	childCount = readlong f
-- 	childNames = for y=1 to childCount collect (getString f (readlong f + (ftell f - 4)))
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = false
-- 	newBone.transform = tfm	--breaks some models for some reason
	newBone.name = boneName[x]
 	
	pos = [m14,m24,m34]
	pos *= tfm
	newBone.pos = (pos*fscale)
 	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	
	append BNArr newBone	
)

for x=1 to boneCount do (
	parentID = (finditem boneName parentName[x])
 	if parentID != 0 do (
		BNArr[x].parent = BNArr[parentID]
		BNArr[x].transform *= BNArr[x].parent.transform
	)
)
for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
for b in BNArr do b.setskinpose()

fseek f meshDataOffset #seek_set
tags = readlong f
meshTableOffset = readlong f + (ftell f - 4)
meshCount = readlong f
meshOffset = for x=1 to meshCount collect (readlong f + (ftell f - 4))
	
for x=1 to meshCount do (
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	Color_Array=#()
	blendIndicesArray=#()
	blendWeightArray=#()
	
	fseek f meshOffset[x] #seek_set	
	ReadFixedByteString f 0x06 1 0
	
	tags = readlong f
	null = readshort f
	faceStride = readbyte f
	vertStride = readbyte f
	meshName = (getString f (readlong f + (ftell f - 4)))
	matName = (getString f (readlong f + (ftell f - 4)))
	ukwOffset = readlong f + (ftell f - 4)
	matNameOffset2 = readlong f + (ftell f - 4)
	fseek f 0x40 #seek_cur	--mesh transform
	boneNameOffset = readlong f + (ftell f - 4)	--using as boneMap
	boneDataOffset = readlong f + (ftell f - 4)
	fseek f 0x18 #seek_cur	--bound box
	faceCount = readlong f
	faceOffset = readlong f + (ftell f - 4)
	vertElmTableOffset = readlong f + (ftell f - 4)
	vertCount = readlong f
	vertOffset = readlong f + (ftell f - 4)
	
	fseek f boneNameOffset #seek_set
	boneMapCount = readlong f
	boneMap = for y=1 to boneMapCount collect (getString f (readlong f + (ftell f - 4)))
	
	fseek f vertElmTableOffset #seek_set
	vertElmTableCount = readlong f
	decTable = for z=1 to vertElmTableCount collect (
		vertInfo = (vertElement	\ 
			usage:	(readlong f)	\
			count:	(readlong f)	\
			offset:	(readlong f)	\
			type:	(readlong f)
		)
	)
	
	print decTable
	format "\n"
	
	fseek f vertOffset #seek_set
	vertDataLenth = readlong f --this included
	if vertDataLenth <= 0xff do vertBufferLength = readbyte f
	if vertDataLenth > 0xff and vertDataLenth <= 0xffff do vertBufferLength = readshort f
	if vertDataLenth > 0xffff do vertBufferLength = readlong f
	
	for y=1 to vertCount do (		
		vertRef = ftell f
		for z=1 to vertElmTableCount do (
			vertInfo = decTable[z]
			fseek f (vertInfo.offset + vertRef) #seek_set
			case vertInfo.usage of (
				0x00:(	--position
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					
					append Vert_array([vx,vy,vz]*fscale)
				)
				0x01:(	--normals
					normals = (unpackNormal [10,10,10] 511 (readlong f))
					
					append Normal_array normals
				)
				0x02:(	--blend indices
					cr = readbyte f / 255.0
					cg = readbyte f / 255.0
					cb = readbyte f / 255.0
					ca = readbyte f / 255.0
					
					append Color_Array (color cr cg cb ca)
				)
				0x03:(	--tex coords
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					
					append UV_array[tu,1-tv,0]
				)
				0x0f:(	--blend indices
					bone1 = readbyte f #unsigned + 1
					bone2 = readbyte f #unsigned + 1
					bone3 = readbyte f #unsigned + 1
					bone4 = readbyte f #unsigned + 1
					
					append blendIndicesArray [bone1,bone2,bone3,bone4]
				)
				0x10:(	--blend weights
					if vertInfo.type == 0x0b do (
						weight1b = readbyte f #unsigned
						weight1 = readbyte f #unsigned
						weight2b = readbyte f #unsigned
						weight2 = readbyte f #unsigned
						weight3b = readbyte f #unsigned
						weight3 = readbyte f #unsigned
						weight4b = readbyte f #unsigned
						weight4 = readbyte f #unsigned
						
						append blendWeightArray [weight1,weight2,weight3,weight4]
					)
					if vertInfo.type == 0x00 do (
						weight1 = readfloat f
						weight2 = readfloat f
						weight3 = readfloat f
						weight4 = readfloat f
						
						append blendWeightArray [weight1,weight2,weight3,weight4]
					)
				)
			)
		)
		fseek f (vertRef + vertStride) #seek_set
	)
	
	for y=1 to vertCount do (			--blend weight/indices
	-- 			format "%\n%\n\n" blendIndicesArray[y] blendWeightArray[y]
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
	
	
	fseek f faceOffset #seek_set
	faceDataLenth = readlong f
	if faceDataLenth <= 0x100 do faceBufferLength = readbyte f
	if faceDataLenth > 0x100 and faceDataLenth <= 0x10000 do faceBufferLength = readshort f
	if faceDataLenth > 0x10000 do faceBufferLength = readlong f
	
	if faceStride == 1 do (
		for y=1 to (faceCount/3) do (
			fa = readbyte f #unsigned + 1
			fb = readbyte f #unsigned + 1
			fc = readbyte f #unsigned + 1
			
			append Face_Array[fa,fb,fc]
		)
	)
	if faceStride == 2 do (
		for y=1 to (faceCount/3) do (
			fa = readshort f #unsigned + 1
			fb = readshort f #unsigned + 1
			fc = readshort f #unsigned + 1
			
			append Face_Array[fa,fb,fc]
		)
	)
	
	msh = mesh vertices:Vert_array faces:Face_Array
	msh.numTVerts = UV_array.count
	msh.name = meshName
	msh.wirecolor = random black white
	buildTVFaces msh
-- 	defaultVCFaces msh
-- 	setShadeCVerts msh true
-- 	setCVertMode msh true
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
  	for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
--  	for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
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


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
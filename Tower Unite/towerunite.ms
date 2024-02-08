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

struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"" types:" (*.plymodel)|*.plymodel" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=0.5
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

MODL = ReadFixedString f 4
ukw = readlong f	--count?
print ukw

if ukw == 1 do fseek f 0x0a #seek_cur
if ukw == 2 do fseek f 0x0d #seek_cur

polyElmTableOffset = readlong f
polyElmTableLength = readlong f
matTableOffset = readlong f
matTableLength = readlong f
boneOffset = readlong f
boneLength = readlong f
ukwOffset4 = readlong f
ukwLength4 = readlong f
faceBufferOffset = readlong f
faceBufferLength = readlong f
vertBufferOffset = readlong f
vertBufferLength = readlong f
texBufferOffset = readlong f
texBufferLength = readlong f

struct polyElment (
	faceOffset,
	faceCount,
	matID,
	polyElmID
)

fseek f polyElmTableOffset #seek_set
polyElmCount = readbyte f
polyArr = for x=1 to polyElmCount collect (
	polyElm = (polyElment	\ 
		faceOffset: (readlong f) \
		faceCount: (readlong f) \
		matID: (readlong f + 1) \
		polyElmID: (readlong f)
	)
)

fseek f matTableOffset #seek_set
matCount = readbyte f
for x=1 to matCount do (
	ReadFixedByteString f 6 1 1
	
	ukw = readshort f			--1
	matID = readbyte f			--id?
	fseek f 0x03 #seek_cur	--ff's
)

parentID=#()
BNArr=#()
fseek f boneOffset #seek_set
boneCount = readbyte f
for x=1 to boneCount do (
	ukw = readbyte f	--1
	boneName = ReadFixedString f (readbyte f)
	
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] ([m14,m24,m34] * fscale)

	n11 = readfloat f; n12 = readfloat f; n13 = readfloat f; n14 = readfloat f
	n21 = readfloat f; n22 = readfloat f; n23 = readfloat f; n24 = readfloat f
	n31 = readfloat f; n32 = readfloat f; n33 = readfloat f; n34 = readfloat f
	tfm2 = matrix3 [n11,n21,n31] [n12,n22,n32] [n13,n23,n33] ([n14,n24,n34] * fscale)

	parentID[x] = readlong f #unsigned + 1
	boneID = readlong f #unsigned + 1
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	
	newBone.transform = inverse tfm
-- 	newBone.transform = tfm2
	
	newBone.name = boneName
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	append BNArr newBone
)
for x=1 to BoneCount do (
-- 	if (parentID[x] != 0) do (
-- 		BNArr[x].transform *= BNArr[parentID[x]].objecttransform	
-- 	)	
	if parentID[x] != 0 do (
		
		BNArr[x].parent = BNArr[parentID[x]]
	)	
)
-- for b in BNArr where b.parent == undefined do b.transform = (matrix3 [0,1,0] [1,0,0] [0,0,1] [0,0,0])

fseek f ukwOffset4 #seek_set
ukwCount4 = readbyte f

format "ukwCount4: %\n" (bit.intashex(ukwCount4))

fseek f faceBufferOffset #seek_set
fseek f 0x03 #seek_cur
ukw = readbyte f
faceBufferStart = ftell f
if ukw == 0 do faceBufferStart -=1 --hack job
fseek f faceBufferLength #seek_cur

fseek f vertBufferOffset #seek_set
ukw = readbyte f
ukw2 = readbyte f
vertStride = readlong f
ukw3 = readbyte f
ukw4 = readshort f

Vert_Array=#()
UV_Array=#()
Face_Array=#()
Normal_array=#()
MatID_Array=#()
Weight_array=#()

format "vertStride: %\n" (bit.intashex(vertStride))
for x=1 to ((vertBufferLength - 0x08) / vertStride) do (	--hopefully theyre all 0x2c
	w = (weight_data boneids:#() weights:#())
	
	vx = readfloat f
	vy = readfloat f
	vz = readfloat f
	tangent = readlong f
	nx = (readbyte f #unsigned / 255.0) * 2 - 1
	ny = (readbyte f #unsigned / 255.0) * 2 - 1
	nz = (readbyte f #unsigned / 255.0) * 2 - 1
	nw = readbyte f
	tu = readfloat f
	tv = readfloat f
	--ReadFixedByteString f 16 1 1
	bone1 = readbyte f #unsigned + 1
	bone2 = readbyte f #unsigned + 1
	bone3 = readbyte f #unsigned + 1
	bone4 = readbyte f #unsigned + 1
	bone5 = readbyte f #unsigned + 1
	bone6 = readbyte f #unsigned + 1
	bone7 = readbyte f #unsigned + 1
	bone8 = readbyte f #unsigned + 1
	weight1 = readbyte f #unsigned
	weight2 = readbyte f #unsigned
	weight3 = readbyte f #unsigned
	weight4 = readbyte f #unsigned
	weight5 = readbyte f #unsigned
	weight6 = readbyte f #unsigned
	weight7 = readbyte f #unsigned
	weight8 = readbyte f #unsigned
	
	maxweight = 0
	if(bone1 != 0) then
		maxweight += weight1
	if(bone2 != 0) then
		maxweight += weight2
	if(bone3 != 0) then
		maxweight += weight3
	if(bone4 != 0) then
		maxweight += weight4
	if(bone5 != 0) then
		maxweight += weight5
	if(bone6 != 0) then
		maxweight += weight6
	if(bone7 != 0) then
		maxweight += weight7
	if(bone8 != 0) then
		maxweight += weight8
		
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
		if(weight5 != 0) then (
			w5 = weight5 as float
			append w.boneids (bone5)
			append w.weights (w5 / mxw)
		)
		if(weight6 != 0) then (
			w6 = weight6 as float
			append w.boneids (bone6)
			append w.weights (w6 / mxw)
		)
		if(weight7 != 0) then (
			w7 = weight7 as float
			append w.boneids (bone7)
			append w.weights (w7 / mxw)
		)
		if(weight8 != 0) then (
			w8 = weight8 as float
			append w.boneids (bone8)
			append w.weights (w8 / mxw)
		)	
	)
	
	append Vert_Array([vx,vy,vz]*fscale)
	append Normal_array [nx,ny,nz]
	append UV_Array[tu,-tv,0]
	append Weight_array w
)

print polyArr

multiMat = multimaterial()
multiMat.numSubs = matCount
meditMaterials[1] = multiMat
for o in multiMat do o.diffuse = random black white

for x=1 to polyElmCount do (
	fseek f (faceBufferStart + (polyArr[x].faceOffset * 4) ) #seek_set
	for y = 1 to ((polyArr[x].faceCount) / 3) do (
		fa = readlong f #unsigned + 1
		fb = readlong f #unsigned + 1
		fc = readlong f #unsigned + 1
		
		append Face_Array [fa,fc,fb]
		append MatID_Array polyArr[x].matID 
	)
)

msh = mesh vertices:Vert_array faces:Face_Array materialIDs:MatID_Array
msh.numTVerts = UV_array.count
msh.wirecolor = random black white
msh.material = multiMat
buildTVFaces msh
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
-- msh.transform=(matrix3 [1,0,0] [0,-1,0] [0,0,1] [0,0,0])
-- msh.transform=(matrix3 [0,1,0] [1,0,0] [0,0,1] [0,0,0])

max modify mode
select msh
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BNArr.count do (
	
	maxbone = getnodebyname BNArr[i].name
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

-- for b in BNArr where b.parent == undefined do b.transform = (matrix3 [0,1,0] [1,0,0] [0,0,1] [0,0,0])
-- $root.rotation = eulerAngles 0 0 90

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
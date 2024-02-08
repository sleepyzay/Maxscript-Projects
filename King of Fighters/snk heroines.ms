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

fname = GetOpenFileName caption:"" types:" (*.obacx)|*.obacx" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=10
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

Vert_Array=#()
Normal_Array=#()
UV_Array=#()
Face_Array=#()
Weight_Array=#()

magic = ReadFixedString f 4
modelType = readshort f

format "modelType: %\n" modelType

if magic == "SFÃ" do (
	ukw = readlong f
	
	print ukw
	format "Accessory / Item \n"
)

vertCount = readlong f #unsigned
for x=1 to vertCount do (
	vx = ReadHalfFloat f
	vy = ReadHalfFloat f
	vz = ReadHalfFloat f
	
	append Vert_Array([vx,vy,vz]*fscale)
)

normalCount = readlong f #unsigned
for x=1 to normalCount do (
	nx = ReadHalfFloat f
	ny = ReadHalfFloat f
	nz = ReadHalfFloat f
	
	append Normal_Array([nx,ny,nz]*fscale)
)

print ukwFlag
if magic == "SFÃ" then (
	ukwCount = readlong f
	for x=1 to ukwCount do (fseek f 0x06 #seek_cur)	--not even gonna bother reading it
	null = readlong f
)
else(
	ukwCount = readlong f #unsigned
	for x=1 to ukwCount do (
		s_ukwCount = readlong f
		for y=1 to s_ukwCount do (
			x = ReadHalfFloat f
			y = ReadHalfFloat f
			z = ReadHalfFloat f
		)
	)
)

uvChannelCount = readlong f #unsigned
for x=1 to uvChannelCount do (
	append UV_Array #()
	
	uvCount = readlong f
	for y=1 to uvCount do (
		tu = ReadHalfFloat f
		tv = ReadHalfFloat f
		
		append UV_Array[x][tu,-tv,0]
	)
)

if magic == "SFÃ" do null = readlong f


BNArr = #()
parentID=#()
boneCount = readlong f #unsigned
for x=1 to boneCount do (
	if ukwFlag != 1 do fseek f 0x0c #seek_cur
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
	parentID[x] = readlong f #unsigned + 1
	if magic == "SFÃ" do null = readlong f
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = orange
	newbone.showlinks = false
	newBone.transform = tfm	
	
	pos = [m41,m42,m43]
	pos *= tfm
	
	newBone.pos = (-fscale*pos)
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	
	append BNArr newBone
)
for x=1 to boneCount do (
	if parentID[x] != 0 do (
		BNArr[x].parent = BNArr[parentID[x]]
	)	
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
for b in BNArr do b.setskinpose()
for b in BNArr where b.children.count == 0 do b.wirecolor = green

if magic == "SFÃ" then (
	stringBlockLength = readlong f
	boneNameOffset = for b=1 to boneCount collect (readlong f #unsigned)
	for b=1 to boneCount do (BNArr[b].name = readstring f)
	
	for b=1 to boneCount do (fseek f 0x6c #seek_cur)	--not looking here either
	null = readlong f
)
else(
	for b=1 to boneCount do (BNArr[b].name = ReadFixedString f (readlong f))
)

matID=#()
FaceID_Array=#()
matCount = readlong f
for x=1 to matCount do (
	matID[x] = readlong f #unsigned + 1
	ukw = readlong f
	
	if ukw == 0x7ff do (
		if magic == "SFÃ" then (
			fseek f 0xa4 #seek_cur
		)
		else (
			fseek f 0x60 #seek_cur
		)
	)
	if ukw == 0xffff do fseek f 0x84 #seek_cur
	
	matIDCount = readlong f #unsigned	--faces the mat id will be applied to
	for y=1 to (matIDCount/3) do (
		append FaceID_Array matID[x]
	)
)

matName=#()
if magic == "SFÃ" then (
	stringBlockLength = readlong f
	matNameOffset = for b=1 to matCount collect (readlong f #unsigned)
	for m=1 to matCount do (matName[m] = readstring f)
)
else (
	matName = for x=1 to matCount collect (ReadFixedString f (readlong f))
)
	

if modelType == 6 do (
	ukwArr = for x=1 to matCount do (
		ukw = readshort f
		ukw2 = readshort f	-- always 0x8000
	)
	
	faceCount = readlong f
	print magic
	if magic == "SFÂ" or magic == "SFÃ" do (
		for x=1 to faceCount/3 do(
			fa = readshort f #unsigned +1
			fb = readshort f #unsigned +1
			fc = readshort f #unsigned +1
			
			append face_array[fa,fc,fb]
		)
	)
	if magic == "SFB" do (
		for x=1 to faceCount/3 do(
			fa = readlong f #unsigned +1
			fb = readlong f #unsigned +1
			fc = readlong f #unsigned +1
			
			append face_array[fa,fc,fb]
		)
	)
	for x=1 to faceCount/3 do(	--2nd index buffer breaks model
		fa = readshort f #unsigned +1
		fb = readshort f #unsigned +1
		fc = readshort f #unsigned +1
		
	-- 	append face_array[fa,fc,fb]
	)
)
if modelType == 7 do (
	faceEnd=#()
	
	polyElmCount = readlong f	--same as matCount
	null = readlong f
	for x=1 to polyElmCount do (
		ukw = readshort f #unsigned
		ukw2 = readshort f #unsigned	--always 0x8000
		faceEnd[x] = readlong f	#unsigned --length?	don't add up though
	)

	faceStart = ftell f
	if magic == "SFÂ" do (
		for x=1 to polyElmCount do (
			while ((ftell f) < (faceStart + (faceEnd[x] * 2))) do (
				fa = readshort f #unsigned + 1
				fb = readshort f #unsigned + 1
				fc = readshort f #unsigned + 1
				
				append face_array[fa,fc,fb]
			)
		)
	)
	if magic == "SFB" do (
		for x=1 to polyElmCount do (
			while ((ftell f) < (faceStart + (faceEnd[x] * 4))) do (
				fa = readlong f #unsigned + 1
				fb = readlong f #unsigned + 1
				fc = readlong f #unsigned + 1
				
				append face_array[fa,fc,fb]
			)
		)
	)
	faceStart2 = ftell f
	for x=1 to polyElmCount do (
		while ((ftell f) < (faceStart2 + (faceEnd[x] * 2))) do (	--2nd index buffer breaks model
			fa = readshort f #unsigned + 1
			fb = readshort f #unsigned + 1
			fc = readshort f #unsigned + 1
			
-- 			append face_array[fa,fc,fb]
		)
	)
)

for x=1 to vertCount do (		--weights
	w = (weight_data boneids:#() weights:#())
	
	boneID=#(0,0,0,0,0,0,0,0)
	weight=#(0,0,0,0,0,0,0,0)
	
	ukw = readlong f #unsigned	--bone parent id?
	bindCount = readbyte f #unsigned
	for y=1 to bindCount do (
		weight[y] = readfloat f
		boneID[y] = readshort f #unsigned + 1
	)
	
	maxweight = 0
	for y=1 to bindCount do if boneID[y] != 0 do maxweight += weight[y]
	if maxweight != 0 do (
		for y=1 to bindCount do (
			if weight[y] != 0 do (
				append w.boneids (boneID[y])
				append w.weights ((weight[y] as float) / 255.0)
			)
		)
	)
	
	append Weight_Array w
)

if magic != "SFÃ" do (	
	binormalCount = readlong f	--not sure tho
	for x=1 to vertCount do (
		b1 = ReadHalfFloat f
		b2 = ReadHalfFloat f
		b3 = ReadHalfFloat f	
		
	-- 	append Normal_Array[b1,b2,b3]
	)
)

format "uvChannelCount : %\n" uvChannelCount
format "vertCount : %\n" vertCount
format "ukwCount  : %\n" ukwCount
format "boneCount : %\n" boneCount
format "matCount  : %\n" matCount

mat = MultiMaterial numsubs:matCount materialIDList:matID showInViewport:true
for x=1 to mat.count do (
	mat.materialList[x].Diffuse = random black white
	mat[x].name = matName[x]
)
meditMaterials[1] = mat

msh = mesh vertices:Vert_Array faces:Face_Array materialIDs:FaceID_Array
msh.numTVerts = UV_Array[1].count
msh.material = mat
msh.name = FileName
buildTVFaces msh
for j = 1 to UV_array[1].count Do setTVert msh j UV_array[1][j]
for j = 1 to Face_Array.count Do setTVFace msh j Face_Array[j]
-- for j = 1 to Normal_Array.count Do setNormal msh j Normal_Array[j]
msh.transform=(matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])

if UV_Array.count > 1 do(
	meshop.setNumMaps msh 3 keep:true
	for i = 1 to UV_Array[2].count do meshop.setMapVert msh 2 i UV_Array[2][i]
)

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


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
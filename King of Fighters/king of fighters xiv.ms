--sleepyzay--

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
fn getArrSum arr = (
	sum = 0
	for i in arr do sum += i
	
	return sum
)
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)

struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"King of Fighters XIV" types:" (*.obac)|*.obac" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
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

magic = ReadFixedString f 3
fseek f 0x03 #seek_cur
if magic == "SFC" do (
	ukwCount = readlong f
)

vertCount = readlong f
for x=1 to vertCount do (
	vx = readfloat f
	vy = readfloat f
	vz = readfloat f
	
	append Vert_Array([vx,vy,vz]*fscale)
)

normalCount = readlong f
for x=1 to normalCount do (	--something aint right
	nx = readfloat f
	ny = readfloat f
	nz = readfloat f
	
	append Normal_Array[nx,ny,nz]
)

if magic == "SFC" do (
	for x=1 to ukwCount do (
		s_ukwCount = readlong f
		for x=1 to s_ukwCount do (
			x = readfloat f
			y = readfloat f
			z = readfloat f
		)
	)
)

ukwCount2 = readlong f
ukwArr = for x=1 to ukwCount2 collect (readlong f) 

uvChannelCount = readlong f
for x=1 to uvChannelCount do (
	append UV_Array #()
	
	uvCount = readlong f
	for y=1 to uvCount do (
		tu = readfloat f
		tv = readfloat f
		
		append UV_Array[x][tu,-tv,0]
	)
)

BNArr = #()
parentID=#()
if magic == "SFC" do boneLength = readlong f
boneCount = readlong f
for x=1 to BoneCount do (
	if magic == "SFB" do fseek f 0x0c #seek_cur
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
	parentID[x] = readlong f #unsigned + 1
	if magic == "SFC" do fseek f 0x04 #seek_cur
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
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
for x=1 to BoneCount do (
	if parentID[x] != 0 do (
		BNArr[x].parent = BNArr[parentID[x]]
	)	
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
for b in BNArr do b.setskinpose()

nameOffset=#()
if magic == "SFC" do boneNameLength = readlong f
for x=1 to boneCount do (
	if magic == "SFC" do nameOffset[x] = readlong f
	if magic == "SFB" do (
		nameLength = readlong f
		boneName = ReadFixedString f nameLength
		BNArr[x].name = boneName
	)
)

if magic == "SFC" do (
	addTo = ftell f
	for x=1 to boneCount do (
		fseek f (nameOffset[x] + addTo) #seek_set
		BNArr[x].name = readstring f
	)
)

if magic == "SFC" do (		--second skeleton?
	for x=1 to boneCount do (
		fseek f 0x6c #seek_cur
	)
	matDataLength = readlong f
)

matID=#()
FaceID_Array=#()
matCount = readlong f
for x=1 to matCount do (
	matID[x] = readlong f #unsigned + 1
	ukw = readlong f
	
	if ukw == 0x7ff do fseek f 0x60 #seek_cur
	if ukw == 0xffff do fseek f 0x84 #seek_cur
	
	if magic == "SFC" do fseek f 0x44 #seek_cur
	
	matIDCount = readlong f #unsigned	--faces the mat id will be applied to
	
	for y=1 to (matIDCount/3) do (
		append FaceID_Array matID[x]
	)
)

nameOffset=#()
matName=#()
if magic == "SFC" do( 
	matNamesLength = readlong f
	for x=1 to matCount do (
		nameOffset[x] = readlong f
	)
	
	addTo = ftell f
	for x=1 to matCount do (
		fseek f (nameOffset[x] + addTo) #seek_set
		matName[x] = readstring f
-- 		print matName[x]
	)
	
)

if magic == "SFB" do( 
	for x=1 to matCount do (
		nameLength = readlong f
		matName[x] = ReadFixedString f nameLength	
	-- 	print matName[x]
	)
)

test = readlong f
if test == matCount then (	--mats get fucked up, fix CNG, MTK, SLV, KDS XND?
	ukwArr = for x=1 to matCount collect (readlong f)
)
else (
	fseek f -4 #seek_cur
)

faceCount = readlong f
for x=1 to faceCount/3 do(
	fa=readlong f +1
	fb=readlong f +1
	fc=readlong f +1
	
	append face_array[fa,fc,fb]
)

for x=1 to vertCount do (		--weights
	w = (weight_data boneids:#() weights:#())
	
	boneID=#(0,0,0,0,0,0,0,0)
	weight=#(0,0,0,0,0,0,0,0)
	
	ukw = readlong f	--bone parent id?
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

binormalCount = readlong f	--not sure tho
for x=1 to vertCount do (
	b1 = readfloat f
	b2 = readfloat f
	b3 = readfloat f
)

format "uvChannelCount : %\n" uvChannelCount
format "vertCount : %\n" vertCount
format "faceCount : %\n" (faceCount/3)
format "boneCount : %\n" boneCount
format "matCount  : %\n" matCount
format "ukw2Count  : %\n" ukwCount2

mat = MultiMaterial numsubs:matCount materialIDList:matID showInViewport:true
for x=1 to mat.count do (
	mat.materialList[x].Diffuse = random black white
	mat[x].name = matName[x]
)
meditMaterials[1] = mat

uvSet = 1	--don't know how to properly implemnt all channels
msh = mesh vertices:Vert_Array faces:Face_Array materialIDs:FaceID_Array
msh.numTVerts = UV_Array[uvSet].count
msh.backfacecull = on
msh.material = mat
msh.name = FileName 
buildTVFaces msh
for j = 1 to UV_array[uvSet].count Do setTVert msh j UV_array[uvSet][j]
for j = 1 to Face_Array.count Do setTVFace msh j Face_Array[j]
-- for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
-- ApplyNormals msh Normal_array
msh.transform=(matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])

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
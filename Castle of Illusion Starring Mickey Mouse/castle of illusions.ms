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

struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"" types:" (*.)|*.dat" historyCategory:""
-- fname=@"C:\Users\Xavier\Documents\stuff\projects\models\ripped\castle of illusions\303467b2dd604ef4dbb7ac95563023f4-mm"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

ukw = readshort f	--0x04
tableCount = readshort f
ukw2 = readshort f
ukw3 = readshort f
ukw4 = readlong f
tableOffset = readlong f
ukw5 = readlong f

vertStart = 0
vertStride = 0
faceStart = 0
boneStart = 0
boneCount = 0
boneOffset=0
parentIDOffset=0
vertCount=#()
faceCount=#()
vertOffset=#()
faceOffset=#()
meshDataArr=#()

struct meshData (
	faceOffset,
	faceCount,
	vertCount,
	vertOffset,
	boneMapCount,
	boneMapOffset
)

fseek f tableOffset #seek_set
for x=1 to tableCount do (
	ukw = readlong f
	dataType = readshort f
	dataSize = readshort f
	dataCount = readlong f
	dataOffset = readlong f
	
	nextTable = ftell f
	fseek f dataOffset #seek_set
	
	if dataType == 0x0a do (	--indices
		faceStart = ftell f
		faceBuferCount = dataCount
		faceSize = dataSize
	)
	if dataType == 0x0b do (	--bones matrices
		boneOffset = (ftell f)
		boneCount = dataCount
	)
	if dataType == 0x0c do (	--parent id's
		parentIDOffset = (ftell f)
	)
	if dataType == 0x17 do (	--model info
		lodCount=#()
		for y=1 to dataCount do (
			tableIndex = readlong f
			totallodCount = readlong f
			lodCount[y] = readlong f
		)
		for z = 1 to lodCount[1] do (		--highest lod
			m = meshData()
			
			m.faceOffset = readlong f
			m.faceCount = readshort f
			m.vertCount = readshort f
			m.vertOffset = readlong f
			m.boneMapCount = readshort f + 1
			polyID = readshort f + 1
			m.boneMapOffset = readlong f
			
			if meshDataArr[polyID] == undefined do meshDataArr[polyID] = #()
			append meshDataArr[polyID] m
		)
	)
	if dataType == 0x18 do (	--verts
		vertStart = ftell f
		vertStride = dataSize
		vertBufferCount = dataCount
	)
	
	fseek f nextTable #seek_set
)

fseek f parentIDOffset #seek_set
parentID = for x=1 to boneCount collect (readlong f #unsigned + 1)

BNArr=#()
fseek f boneOffset #seek_set
for x=1 to boneCount do (
	m11 = Readfloat f; m12 = Readfloat f; m13 = Readfloat f; m14 = Readfloat f
	m21 = Readfloat f; m22 = Readfloat f; m23 = Readfloat f; m24 = Readfloat f
	m31 = Readfloat f; m32 = Readfloat f; m33 = Readfloat f; m34 = Readfloat f
	m41 = Readfloat f; m42 = Readfloat f; m43 = Readfloat f; m44 = Readfloat f
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = white
	newbone.showlinks = false
	newBone.transform = tfm
	
	pos = [m41,m42,m43]
	pos *= tfm
	newBone.pos += (fscale*pos)
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if (parentID[x] != 0) then (
	newBone.parent = BNArr[parentID[x]]
   )
	
	append BNArr newBone
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0])
for b in BNArr do b.setskinpose()

for x=1 to meshDataArr.count do (	--
	Vert_array=#()
	UV_array=#()
	Normal_array=#()
	Face_array=#()
	Weight_array=#()
	
	vertSum = 0
	m = meshDataArr[x]
	for y=1 to m.count do (
		fseek f m[y].boneMapOffset #seek_set
		boneMap = for z=1 to m[y].boneMapCount collect (readbyte f #unsigned + 1)
		print boneMap #nomap
		
		fseek f (vertStart + (m[y].vertOffset * vertStride)) #seek_set
		if vertStride == 0x30 do (
			for z=1 to m[y].vertCount do (
				vx = readfloat f
				vy = readfloat f
				vz = readfloat f
				nx = readfloat f
				ny = readfloat f
				nz = readfloat f
				tx = readfloat f
				ty = readfloat f
				tz = readfloat f
				p1 = readfloat f
				tu = readfloat f
				tv = readfloat f
				
				append Vert_array([vx,vy,vz]*fscale)
				append Normal_array[nx,ny,nz]
				append UV_array[tu,1-tv,0]
			)
		)
		if vertStride == 0x44 do (
			for z=1 to m[y].vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = readfloat f
				vy = readfloat f
				vz = readfloat f
				weight1 = readfloat f
				weight2 = readfloat f
				weight3 = readfloat f
				weight4 = readfloat f
				bone1 = readbyte f #unsigned + 1
				bone2 = readbyte f #unsigned + 1
				bone3 = readbyte f #unsigned + 1
				bone4 = readbyte f #unsigned + 1
				nx = readfloat f
				ny = readfloat f
				nz = readfloat f
				tx = readfloat f
				ty = readfloat f
				tz = readfloat f
				p1 = readfloat f
				tu = readfloat f
				tv = readfloat f
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 1.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (boneMap[bone1])
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (boneMap[bone2])
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (boneMap[bone3])
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (boneMap[bone4])
						append w.weights (w4 / mxw)
					)		
				)
-- 				
-- 				format "% % % %\n" weight1 weight2 weight3 weight4
-- 				format "% % % %\n\n" bone1 bone2 bone3 bone4
				
				append Vert_array([vx,vy,vz]*fscale)
				append Normal_array[nx,ny,nz]
				append UV_array[tu,1-tv,0]
				append Weight_array w
			)
		)
		
		fseek f (faceStart + (m[y].faceOffset * 2)) #seek_set
		for y=1 to m[y].faceCount do (
			fa = (ReadShort f #unsigned + 1 + vertSum) 
			fb = (ReadShort f #unsigned + 1 + vertSum)
			fc = (ReadShort f #unsigned + 1 + vertSum)
			
			append Face_Array[fa,fc,fb]
		)
		vertSum += m[y].vertCount
	)
	
	msh = mesh vertices:Vert_array faces:Face_Array
	msh.numTVerts = UV_array.count
	msh.material = mat
	buildTVFaces msh
	for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
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
			skinOps.addBone skinMod maxbone 1
	)
	
	-- Applying Weights --
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
	
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
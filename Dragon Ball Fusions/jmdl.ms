-- SleepyZay --

fn ReadFixedString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)
fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)	
fn ReadFixedByteString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  if mod i 1 == 0 do str += " "
   )
   str
   print str
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
fn AlignOffset fstream relativeoffset alignment = (
   align = (alignment - (mod relativeoffset alignment as integer))
   align = fseek fstream align #seek_cur
   return align
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
fn Readword fstream = (
return readshort fstream #unsigned
)

fname = GetOpenFileName caption:"Dragon Ball Fusions" types:"(.jmdl)|*.jmdl"
-- fname = @"C:\Users\Xavier\Desktop\chara\body_70_g0_m_b_0\body_70_g0_m_b_0.jmdl"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 4
jIMG_Offset = readlong f
ukw = readlong f
boneOffset = readlong f
polyDataOffset = readlong f
ukwOffset3 = readlong f
null = readlong f
meshDataOffset = readlong f
/*
-- Bone Data --
fseek f boneOffset #seek_set
boneCount = readshort f #unsigned
BNArr=#()
for x=1 to boneCount do (
	ukw = readshort f
	ukw2 = readlong f
	null = readlong f
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; 
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; 
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; 
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [0,1,0]
	parentID = readshort f #unsigned
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newbone.showlinks = true
	newBone.transform = tfm
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	append BNArr newBone
)
*/




-- Poly Data --
fseek f polyDataOffset #seek_set
addto = ftell f
polyCount = readlong f
polyOffset = for x=1 to polyCount collect (readlong f)+addto

PolyElmLengthArr=#()
PolyElmOffsetArr=#()
PolyElmIDArr=#()
subPolyCount=#()

for x=1 to polyCount do (
	polyElmLength=#()
	polyElmOffset=#()
	polyElmID=#()
	fseek f polyOffset[x] #seek_set
-- 	Print ("polyOffset @ 0x"+((bit.intAsHex(ftell f))as string))
	
	null = readshort f
	ukw = readshort f
	null = readlonglong f
	currBBMax = [(readfloat f),(readfloat f),(readfloat f)]*fscale
	currBBMin = [(readfloat f),(readfloat f),(readfloat f)]*fscale
	currA = currBBMax - currBBMin

	currWidth = abs(currA[1])
	currHeight = abs(currA[2])
	currLength = abs(currA[3])

	bb = box()
	bb.width = currWidth
	bb.height = currHeight
	bb.length = currLength

	subPolyCount[x] = readlong f
	
	for y=1 to subPolyCount[x] do (
		polyElmOffset[y] = (readlong f*2)
		polyElmLength[y] = readlong f
		polyElmID[y] = (readshort f+1)
		matID = readshort f
		fseek f 0x38 #seek_cur
	)
	
	PolyElmOffsetArr[x] = polyElmOffset
	PolyElmLengthArr[x] = polyElmLength
	PolyElmIDArr[x] = polyElmID
)

-- print PolyElmIDArr

-- Mesh Data --
fseek f meshDataOffset #seek_set
addto = (ftell f)
meshCount = readlong f
ukw3 = readlong f	-- prob tableOffset
ukw4 = readlong f	-- always 1
faceOffset = (readlong f)+addto

Print ("meshcount is 0x"+((bit.intAsHex(meshcount))as string))
format "\n"
	
vertOffset=#()
vertLength=#()
vertSize=#()

for x=1 to meshCount do (
	vertOffset[x] = (readlong f)+addto
	vertLength[x] = readlong f
	tableCount = readlong f
	tableOffset = (readlong f)+addto
	null = readlong f
	ukw5 = readlong f
	
	backJump = ftell f
	fseek f tableOffset #seek_set
	for y=1 to tableCount do (
		ukw = readlong f
		fseek f 3 #seek_cur
		vertSize[x] = readbyte f
	)
	fseek f backJump #seek_set
)

-- Building Meshes --
for x=1 to meshCount do (
	Vert_array=#()
	UV_array=#()
	
	fseek f vertOffset[x] #seek_set
	
	vertCount = vertLength[x]/vertSize[x]
	Print ("vertCount is 0x"+((bit.intAsHex(vertCount))as string))
	Print ("vertOffset is 0x"+((bit.intAsHex(vertOffset[x]))as string))
	Print ("vertSize is 0x"+((bit.intAsHex(vertSize[x]))as string))
	format "\n"
	
	if vertSize[x] == 0xa do (
		for x=1 to vertCount do (
			vx = Readshort f
			vy = Readshort f
			vz = Readshort f
			tu = Readword f
			tv = Readword f
			
			append Vert_array([vx,-vz,vy]*fscale)
			append UV_array[tu,(tv*-1),0]
		)
	)
	if vertSize[x] == 0x12 do (
		for x=1 to vertCount do (
			vx = Readshort f
			vy = Readshort f
			vz = Readshort f
			tu = Readword f
			tv = Readword f
			fseek f 0x8 #seek_cur
			append Vert_array([vx,-vz,vy]*fscale)
			append UV_array[tu,(tv*-1),0]
		)
	)
	if vertSize[x] == 0x14 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			fseek f 0x4 #seek_cur
			tu = Readword f
			tv = Readword f
			
			append Vert_array([vx,-vz,vy]*fscale)
			append UV_array[tu,(tv*-1),0]
		)
	)
	if vertSize[x] == 0x18 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			fseek f 0x8 #seek_cur
			tu = Readword f
			tv = Readword f
			
			append Vert_array([vx,-vz,vy]*fscale)
			append UV_array[tu,(tv*-1),0]
		)
	)
	if vertSize[x] == 0x1c do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			fseek f 0x4 #seek_cur
			tu = Readword f
			tv = Readword f
			w1 = readbyte f
			w2 = readbyte f
			w3 = readbyte f
			w4 = readbyte f
			b1 = readbyte f
			b2 = readbyte f
			b3 = readbyte f
			b4 = readbyte f
			
			append Vert_array([vx,-vz,vy]*fscale)
			append UV_array[tu,(tv*-1),0]
		)
	)
	if vertSize[x] == 0x20 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			fseek f 0x8 #seek_cur
			tu = readshort f
			tv = readshort f
			w1 = readbyte f
			w2 = readbyte f
			w3 = readbyte f
			w4 = readbyte f
			b1 = readbyte f
			b2 = readbyte f
			b3 = readbyte f
			b4 = readbyte f
			
			append Vert_array([vx,-vz,vy]*fscale)
			append UV_array(([tu,tv,0]/32767.0)*8)
		)
	)
	
	fseek f faceOffset #seek_set
	ukw6 = readlong f	-- always 10
	faceLength = readlong f
	faceCount = readlong f
	ukw8 = readlong f
	addto = (ftell f)
	
	for y=1 to polyCount do (
--  		print subPolyCount[y]
		
		for z=1 to subPolyCount[y] do (
			Face_array=#()
			
-- 			print (bit.intashex(PolyElmLengthArr[y][z]))
			fseek f (PolyElmOffsetArr[y][z]+addto) #seek_set
			
			boxNum = paddstring 3 (y as string)
			boxName = "Box"+boxNum
			boundBox = getnodebyname boxName
			boundBox.xray = true
			hide boundBox
-- 			
			if (PolyElmIDArr[y][z] == x) do (
-- 				print PolyElmIDArr[y][z]
				
				for a=1 to PolyElmLengthArr[y][z]/3 do(
					fa=ReadShort f #unsigned +1 
					fb=ReadShort f #unsigned +1 
					fc=ReadShort f #unsigned +1 
					append Face_array[fa,fb,fc]
				)
				
				msh = mesh vertices:Vert_array faces:Face_array 
				msh.numTVerts = UV_array.count
				msh.wirecolor = random black white
				msh.name = bit.intAsHex(vertSize[x]) as string
				buildTVFaces msh
				for j = 1 to UV_array.count do setTVert msh j UV_array[j]
				for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
				meshop.deleteIsoVerts msh
				if z== 1 do boundBox.center = msh.center
				
			)
			
		)
	)
	
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

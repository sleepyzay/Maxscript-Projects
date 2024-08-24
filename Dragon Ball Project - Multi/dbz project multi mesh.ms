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
fn printMatrix bstream = (
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	fseek f -0x40 #seek_cur
	format "\n"
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

-- fname = GetOpenFileName caption:"" types:" (*.mesh)|*.mesh" historyCategory:""
fname = @"C:\Users\Xavier\Downloads\JPKGReader-0.1.0\JPKGReader-0.1.0\JPKGReader\bin\Debug\net7.0\output\download\00000170.mesh"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

allBones = for o in geometry where classof o == bonegeometry collect o
if allbones.count == 0 do delete $*

magic = ReadFixedString f 4
fileSize = readlong f
unk = readlong f
unk2 = readlong f	--0x0a

table1Count = readshort f
table2Count = readshort f
table3Count = readshort f				--count?
table4Count = readshort f				--count?

null = readlong f				--may be two shorts

table1Offset = readlong f
table2Offset = readlong f
table3Offset = readlong f
table4Offset = readlong f
unkOffset = readlong f

format "table1Count: %	table1Offset: % \n" (bit.intashex(table1Count)) (bit.intashex(table1Offset))
format "table2Count: %	table2Offset: % \n" (bit.intashex(table2Count)) (bit.intashex(table2Offset))
format "table3Count: %	table3Offset: % \n" (bit.intashex(table3Count)) (bit.intashex(table3Offset))
format "table4Count: %	table4Offset: % \n" (bit.intashex(table4Count)) (bit.intashex(table4Offset))

--next 0x18 is bound box

struct _table1 (
	read = (ReadFixedByteString f 0x188 1 1),
	unk = readlong f,							--hash?
	unk2 = readlong f,							--offset/count?
	unk3 = readlong f,							--float?
	unk4 = readlong f,							--float?
	unk5 = readlong f,							--index?
	unk6 = readlong f,							--index?
	skip1 = (fseek f 0xa0 #seek_cur),	--floats? / null
	unk7 = readlong f,							--0x01010000
	unk8 = readlong f,							--0x01010000
	unk9 = readlong f,							--0x01010000
	skip2 = (fseek f 0xc4 #seek_cur)	--more floats and mostly nulls
)
struct _table2 (
	read = (ReadFixedByteString f 0x28 1 1),
	table1Id = readshort f,
	meshId = readshort f,
	bodyBoneId = readlong f,	--second smaller skeleton who's root is named body
	null = readlong f,
	faceCount = readlong f,
	unkFloat1 = readfloat f,
	unkFloat2= readfloat f,
	unkFloat3 = readfloat f,
	unkFloat4 = readfloat f,
	unkFloat5 = readfloat f,
	unkFloat6 = readfloat f
)
struct _table3 (
	read = (ReadFixedByteString f 0x1c 1 0),
	boneId = readlong f + 1,
	unkFloat1 = readfloat f,	--pos?
	unkFloat2= readfloat f,
	unkFloat3 = readfloat f,
	unkFloat4 = readfloat f,	--rot?
	unkFloat5 = readfloat f,
	unkFloat6 = readfloat f
)
struct _table4 (
	meshOffset = readlong f
)

fseek f table1Offset #seek_set
table1Array = for x=1 to table1Count collect (table = _table1())
format "\n"

fseek f table2Offset #seek_set
table2Array = for x=1 to table2Count collect (table = _table2())
format "\n"

fseek f table3Offset #seek_set
table3Array = for x=1 to table3Count collect (table = _table3())	--skeleton related?
format "\n"

fseek f table4Offset #seek_set
table4Array = for x=1 to table4Count collect (table = _table4())
format "\n"

boneIdArray=#()
for x=1 to table4Count do (	--table4Count
	table4 = table4Array[x]
	table2 = (for table in table2Array where table.meshId == (x-1) collect table)[1]	--should rewrite this to get table4 from table 2
	table1 = table1Array[table2.table1Id + 1]

	fseek f table4.meshOffset #seek_set
-- 	format "% meshOffset: %\n" (bit.intashex(x)) (bit.intashex(table4.meshOffset))
	
-- 	ReadFixedByteString f 0x24 1 1
	sectionLength = readlong f
	vertCount = readlong f
	vertLength = readlong f
	vertOffset = readlong f
	vertFlags = readshort f
	unk3 = readshort f			--primType?
	faceCount = readlong f
	faceLength = readlong f
	faceOffset = readlong f
	null = readlong f
	
	printhex (x-1)
	printhex table2.table1Id
	printhex table1.unk5
	format "vertCount:	% faceCount:	%\n" (bit.intashex(vertCount)) (bit.intashex((table4.meshOffset + vertOffset)))
	format "faceCount:	% faceOffset:	%\n" (bit.intashex(faceCount)) (bit.intashex((table4.meshOffset + faceOffset)))
	
	Vert_Array = #()
	UV_Array = #()
	UV_Array2 = #()
	UV_Array3 = #()
	Face_Array = #()
	Normal_Array = #()
	Weight_Array = #()
	BoneId_Array = #()
	Color_Array=#()
	
	fseek f (table4.meshOffset + vertOffset) #seek_set
	for bitIndex = 16 to 1 by -1 do (
		if (bit.get vertFlags bitIndex) == true do (
			case bitIndex of (
				11: ( -- positions
					for y = 1 to vertCount do (
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						append Vert_Array ([vx, vy, vz] * fscale)
					)
				)
				10: ( -- normals
					for y = 1 to vertCount do (
						nx = readbyte f #unsigned / 255.0 * 2 - 1
						ny = readbyte f #unsigned / 255.0 * 2 - 1
						nz = readbyte f #unsigned / 255.0 * 2 - 1
						nw = readbyte f #unsigned --128 / scalar?
						append Normal_Array [nx, ny, nz]
					)
				)
				06: ( -- colors
					for y = 1 to vertCount do (
-- 						if y < 0x50 do ReadFixedByteString f 0x04 1 1
						ca = readbyte f #unsigned
						cb = readbyte f #unsigned
						cg = readbyte f #unsigned
						cr = readbyte f #unsigned
						
-- 						cr = readbyte f #unsigned	--outlines
-- 						cg = readbyte f #unsigned	--null
-- 						cb = readbyte f #unsigned	--shadows?
-- 						ca = readbyte f #unsigned
						
						c = ca
						append Color_Array (color c c c c)
-- 						append Color_Array (color cr cg cb ca)
					)
				)
				05: ( -- uv's colors
					for y = 1 to vertCount do (
						tu = ReadHalfFloat f
						tv = ReadHalfFloat f
						append UV_Array [tu, 1-tv, 0]
					)
				)
				04: ( -- uv's 1
					for y = 1 to vertCount do (
						tu = ReadHalfFloat f
						tv = ReadHalfFloat f
						append UV_Array2 [tu, 1-tv, 0]
					)
				)
				03: ( -- uv's 2 (sometimes broken)
					for y = 1 to vertCount do (
						tu = ReadHalfFloat f
						tv = ReadHalfFloat f
						append UV_Array3 [tu, 1-tv, 0]
					)
				)
				02: ( -- weights
					for y = 1 to vertCount do (
						weight1 = readfloat f
						weight2 = readfloat f
						weight3 = readfloat f
						weight4 = readfloat f
						append Weight_Array #(weight1, weight2, weight3, weight4)
					)
				)
				01: ( -- bone id's
					for y = 1 to vertCount do (
						bone1 = readbyte f #unsigned + 1
						bone2 = readbyte f #unsigned + 1
						bone3 = readbyte f #unsigned + 1
						bone4 = readbyte f #unsigned + 1
						append BoneId_Array #(bone1, bone2, bone3, bone4)
					)
				)
				default: (
					format "Unknown vertex element found: %\n" bitIndex
				)
			)
		)
	)
	
	fseek f (table4.meshOffset + faceOffset) #seek_set
	for x=1 to (faceCount/3) do (
		fa = readshort f #unsigned + 1
		fb = readshort f #unsigned + 1
		fc = readshort f #unsigned + 1
		
		if fc > vertCount do fc = vertCount	--end of files are sometimes corrupted
		
		append Face_Array[fa,fc,fb]
	)
	
	format "Vert_Array	count: %\nUV_Array	count: %\nUV_Array2	count: %\nUV_Array3	count: %\n"\
	Vert_Array.count	\
	UV_Array.count		\
	UV_Array2.count	\
	UV_Array3.count	\
	
	if UV_Array.count == 0 do UV_Array = for x=1 to Vert_Array.count collect [0,0,0]
	
	msh = mesh vertices:Vert_Array faces:Face_Array
	msh.numTVerts = UV_Array.count
-- 	msh.name = (bit.intashex(x-1)) as string
-- 	msh.name = (bit.intashex(vertFlags as integer)) as string
	msh.name = table1.unk5 as string
	msh.wirecolor = white
	buildTVFaces msh
-- 	defaultVCFaces msh
-- 	setShadeCVerts msh true
-- 	setCVertMode msh true
	for j = 1 to UV_Array.count Do setTVert msh j UV_Array[j]
	for j = 1 to Face_Array.count Do setTVFace msh j Face_Array[j]
	for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
-- 	for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
	if Weight_Array.count != 0 and allbones.count != 0 do (
		--  Applying Skinning --
		count = msh.numverts
		max modify mode
		select msh
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to allbones.count do (
		   maxbone = getnodebyname allbones[i].name
		   skinOps.addBone skinMod maxbone 1
		)
		-- Applying Weights --
		select msh
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_Array.count do (
-- 			boneWeights = #()
-- 			boneIds = #()
-- 			for j = 1 to Weight_Array[i].count do (
-- 				if Weight_Array[i][j] != 0 do (
-- 					append boneWeights Weight_Array[i][j]
-- 					append boneIds BoneId_Array[i][j]
-- 				)
-- 			)
-- 			skinOps.ReplaceVertexWeights skinMod i boneIds boneWeights
			skinOps.ReplaceVertexWeights skinMod i BoneId_Array[i] Weight_Array[i]
		)
		deselect msh
	)
	format "\n"
)


Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
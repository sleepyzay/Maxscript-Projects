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

-- fname=@"D:\g7\master chief\masterchief.model"
-- fname=@"D:\g7\flood juggernaut\flood_juggernaut.model"
-- fname=@"D:\g7\elite ultra\elite_ultra.model"
fname = GetOpenFileName caption:"" types:" (*.)|*.model" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=10
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

modeName = readstring f

fseek f 0x80 #seek_set
stringBufferLength = readlonglong f
stringBufferOffset = (ftell f) + readlonglong f
vertexBufferOffset = (ftell f) + readlonglong f
faceBufferOffset = (ftell f) + readlonglong f

fseek f 0xd4 #seek_set
unk = readlong f	--vertdectable?
vertexStride = readlong f
faceCount = readlong f
faceCount2 = readlong f
vertexCount = readlong f
faceBufferLength = readlong f
vertexBufferLength = readlong f
null = readlong f

struct _vertInfo (
	count = readlong f,
	offset = readlong f
)

vertInfoArray = for x=1 to 0x0e collect (vertInfo = _vertInfo())

Vert_Array=#()
UV_Array=#()
Face_Array=#()
Normal_Array=#()
BoneId_Array=#()
Weight_Array=#()
Color_Array=#()
	
fseek f vertexBufferOffset #seek_set
printhex vertexStride
printHex vertexCount
for x=1 to vertexCount do (
	vertRef = ftell f
	for y=1 to vertInfoArray.count do (
		vertInfo = vertInfoArray[y]
		if vertInfo.count != 0 do (
			fseek f (vertRef + vertInfo.offset) #seek_set
			case y of (
				0x01:(	--position
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					
					append Vert_Array([vx,vy,vz]*fscale)
				)
				0x02:(	--uvs
					tu = readfloat f
					tv = readfloat f
					
					append UV_Array([tu,1-tv,0])
				)
				0x0a:(	--colors
					cr = readfloat f
					cg = readfloat f
					cb = readfloat f
					ca = readfloat f
					
					append Color_Array(color cr cg cb ca)
				)
				0x0b:(	--normals
					nx = readfloat f
					ny = readfloat f
					nz = readfloat f
					
					append Normal_Array([nx,ny,nz])
				)
				0x0c:(	--tangents
					tx = readfloat f
					ty = readfloat f
					tz = readfloat f
					tw = readfloat f	-- 1 or -1
				)
				0x0d:(	--bone ids
					b1 = (readfloat f as integer) + 1
					b2 = (readfloat f as integer) + 1
					b3 = (readfloat f as integer) + 1
					b4 = (readfloat f as integer) + 1
					
					append BoneId_Array #(b1,b2,b3,b4)
				)
				0x0e:(	--bone weights
					w1 = readfloat f
					w2 = readfloat f
					w3 = readfloat f
					w4 = readfloat f
					
					append Weight_Array #(w1,w2,w3,w4)
				)
				default:(
					if x == 1 do format "unknown vertex element: % %\n" (bit.intashex(y)) (bit.intashex(vertInfo.offset))
				)
			)
		)
	)
	fseek f (vertRef + vertexStride) #seek_set	--just in case
)

fseek f faceBufferOffset #seek_set
for x=1 to faceCount do (
	fa = readlong f #unsigned + 1
	fb = readlong f #unsigned + 1
	fc = readlong f #unsigned + 1
	
	append Face_Array [fa,fb,fc]
)

msh = mesh vertices:Vert_Array faces:Face_Array
msh.numTVerts = UV_Array.count
buildTVFaces msh
msh.wirecolor = white
msh.name = modeName
-- defaultVCFaces msh
-- setShadeCVerts msh true
-- setCVertMode msh true
for j = 1 to UV_Array.count Do setTVert msh j UV_Array[j]
for j = 1 to Face_Array.count Do setTVFace msh j Face_Array[j]
for j = 1 to Normal_Array.count Do setNormal msh j Normal_Array[j]
-- for j = 1 to Color_array.count Do setVertColor msh j Color_array[j]
msh.transform *= matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0]

	
allBones = for o in geometry where classof o == bonegeometry collect o
	
if allBones.count > 0 do (
	-- Applying Skinning --
	count = msh.numverts
	max modify mode
	select msh
	skinMod = skin ()
	addModifier msh skinMod
	for i = 1 to allBones.Count do (
	   maxbone = getnodebyname allBones[i].name
	   skinOps.addBone skinMod maxbone 1
	)
	-- Applying Weights --
	select msh
	modPanel.setCurrentObject skinMod
	for i = 1 to Weight_array.count do (
		bi = #()
		wv = #()
		for j=1 to 4 where Weight_array[i][j] != 0 do (	--for some reason if I don't do this some verts are not weighted
			append bi BoneId_Array[i][j]
			append wv Weight_Array[i][j]
		)
		skinOps.ReplaceVertexWeights skinMod i bi wv
	)
)




Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
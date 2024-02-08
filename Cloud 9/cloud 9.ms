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

fname = GetOpenFileName caption:"" types:" (*.)|*.xskin" historyCategory:""
-- fname=@"C:\NetGame\CloudNine\Data\chara\char\macska\cica\basic\pl_cica_arm_00_00.xskin"
-- fname=@"C:\NetGame\CloudNine\Data\chara\char\macska\cica\c_b_07\22_10720_02_1.xskin"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

xbin = ReadFixedString f 4
ukw = readlong f
ukw2 = readshort f
xSkinLength = readshort f
xSkin = readstring f
modelNameLength = readshort f
modelName = readstring f
fseek f 0x21 #seek_cur	--skipping data, may need later
vertCount = readshort f
faceCount = readshort f	--may be wrong / never checked

Vert_array=#()
UV_array=#()
Face_array=#()
Normal_array=#()

for x=1 to vertCount do (
	vx = readfloat f
	vy = readfloat f
	vz = readfloat f
	nx = readfloat f
	ny = readfloat f
	nz = readfloat f
	tu = readfloat f
	tv = readfloat f
	
	append Vert_array([vx,vy,vz]*fscale)
	append UV_array[tu,1-tv,0]
	append Normal_array [nx,ny,nz]
)

for x=1 to (faceCount/3) do (
	fa = readshort f #unsigned + 1
	fb = readshort f #unsigned + 1
	fc = readshort f #unsigned + 1
	
	append Face_Array[fa,fb,fc]
)

matNameLength = readshort f
matName = readstring f

fseek f 0x49 #seek_cur	--matrix / hope this isn't variable

texNameLength = readshort f
texName = readstring f

fseek f 0x0f #seek_cur	--null

alphaBlendLength = readshort f
alphaBlend = readstring f

fseek f 0x14 #seek_cur	--skipping data

ukwCount = readlong f
for x=1 to ukwCount do (
	vx = readfloat f
	vy = readfloat f
	vz = readfloat f
)
for x=1 to ukwCount do (
	ukw = readbyte f	--always 1
	ukw2 = readlong f
)

ukwCount2 = readlong f
for x=1 to  ukwCount2 do (
	ukw = readfloat f
	ukw2 = readlong f
	ukw3 = readlong f
)

ukwCount3 = readlong f	--same as ukwCount 1
for x=1 to ukwCount do (
	nx = readfloat f
	ny = readfloat f
	nz = readfloat f
)

format "% % % % \n" (bit.intashex((vertCount)as integer)) (bit.intashex((ukwCount)as integer)) (bit.intashex((ukwCount2)as integer)) (bit.intashex((ukwCount3)as integer))




msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = UV_array.count
msh.wirecolor = random black white
buildTVFaces msh
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
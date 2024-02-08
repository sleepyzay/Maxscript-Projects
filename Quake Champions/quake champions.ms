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

fname=@"C:\Users\Xavier\Documents\stuff\projects\models\ripped\quake champions\[tpl]\cc_doom_marine.tpl"
-- fname = GetOpenFileName caption:"" types:" (*.)|*." historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=0.002
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 8
fseek f 0x1c #seek_cur	--null
S3DRESOURCE = ReadFixedString f 0x10
null = readlong f
ukw = readlong f	--count?
tplOffset = readlong f + 0x40
fseek f 0x14 #seek_cur	--null
stringLength = readlong f
fileName = ReadFixedString f stringLength

TPL1 = ReadFixedString f 4
ukw2 = readlong f	--offset?
ukw3 = readshort f
stringLength = readlong f
modelName = ReadFixedString f stringLength
ukw4 = readshort f
ukw5 = readlong f

stringLength = readlong f
fseek f stringLength #seek_cur	--tpl file

if stringLength == 0x14 do (
	stringLength = readlong f
	fseek f stringLength #seek_cur	--tpl file
)

ukwCount = readlong f
ukw = readlong f	--always 3
null = readbyte f
ukwDataEnd = readlong f
for x=1 to ukwCount do fseek f 0x40 #seek_cur
	
Vert_Array=#()
UV_Array=#()
Face_Array=#()

fseek f 0x89FB14 #seek_set
for x=1 to 0x90395 do (	--0x90395
	vx = readshort f
	vy = readshort f
	vz = readshort f
	fseek f 0xe #seek_cur
	
	append Vert_Array([vx,vy,vz]*fscale)
	append UV_Array[0,0,0]
)

msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = UV_array.count
msh.wirecolor = random black white
buildTVFaces msh
for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]





Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
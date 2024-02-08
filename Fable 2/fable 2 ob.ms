--sleepyzay--

fn convertTo32 input16 = (
      inputAsInt = input16
      sign = bit.get inputAsInt 16
      exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
      fraction = bit.and inputAsInt (bit.hexasint "03FF")
      if sign==true then sign = 1 else sign = 0
      exponentF = exponent + 127
      --Ouput 32 bit integer representing a 32 bit float
      outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
      --Output Check   
      return bit.intasfloat outputasfloat
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
)
fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
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
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
)
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	bb = box()
	bb.width = abs(currA[1])
	bb.length = abs(currA[2])
	bb.height = abs(currA[3])
-- 	hide bb
	delete bb
)
fn GetName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn triangle_strip count = (
Face_Array=#()
face_flip = true
face_reset=true
x=1;while x < count do (
x+=1
if face_reset == true then (
x+=2
face_reset=false
face_flip = false
fa = (ReadBEword f ) + 1
fb = (ReadBEword f ) + 1
fc = (ReadBEword f ) + 1
if face_flip == true then (
append Face_array [fa,fb,fc]
face_flip=false
)
else(
append Face_array [fa,fc,fb]
face_flip=true
)
)
else(
fa = fb
fb = fc
fc = ReadBEword f 
if fc!=0xFFFF then (
fc += 1
if face_flip == true then (
append Face_array [fa,fb,fc]
face_flip=false
)
else(
append Face_array [fa,fc,fb]
face_flip=true
)
)
else(
face_reset=true
)
)
)
return Face_Array
)
fn skelPresent = (
	allBones = for o in geometry where classOf o == boneGeometry collect o
	if allBones.count > 0 then (
		return true
	)
	else (
		return false
	)
)
fn reverseString s = (
    local reversed = ""
    for i in s.count to 1 by -1 do reversed += s[i]
	reversed
)
fn printBinary val size = (
	str = ""
	for i=1 to size do (
		if (bit.get val i)  then str += "1"
		else str += "0"
		
		if ((mod i 8) == 0) and (i < size) do str+=" "
	)
	
	str = reverseString str
	print str
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
fn get32bitNormal format divisor val = (
	result = [0,0,0]
	pos = 1
	for x=1 to 3 do (
		result[x] = signVal (readBits pos format[x] val) format[x]
		pos+=format[x]
	)
	result/=divisor
)

-- fname = GetOpenFileName caption:"" types:" (*.)|*.mdl" historyCategory:""
-- fname=@"C:\Users\Owner\Downloads\hal_spartan_files_fable2\hal spartan files fable2\CH_HeroFemale_Spartan_Boots\CH_HeroFemale_Spartan_Boots.mdl"
fname=@"C:\Users\Owner\Downloads\hal_spartan_files_fable2\hal spartan files fable2\DLC_SpartanGun\DLC_SpartanGun.mdl"
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

fseek f 0x20 #seek_set
boneCount = ReadBElong f			--no bones in obj
boneCount2 = ReadBElong f

fseek f 0x28 #seek_cur				--floats

ukw = readbelong f
ukw2 = readbelong f
ukw3 = readbelong f

fseek f 0x21 #seek_cur				--always he same
fseek f 0x2d4 #seek_cur			--more floats

ukw4 = readbelong f					--count?
ukw5 = readbelong f					--count?

modelName = readstring f
fseek f 0x2d #seek_cur

ukw6 = readbelong f					--count?

texturePathArray=#()
while true do (
	append texturePathArray (readstring f)
	
	testNext = readbelong f
	fseek f -4 #seek_cur
	if testNext == 0 then exit
)

ReadFixedByteString f 0x0d 0 1

meshName = readstring f





Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
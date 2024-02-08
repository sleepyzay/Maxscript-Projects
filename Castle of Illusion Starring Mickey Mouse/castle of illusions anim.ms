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

fname = GetOpenFileName caption:"" types:" (*.)|*.*" historyCategory:""
-- fname=@"C:\Users\Xavier\Desktop\castle of illusions\idle"
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

ukw = readshort f
boneCount = readlong f
ukw2 = readshort f
ukw3 = readlong f
framesOffset = readlong f
fileSize = readlong f

sliderTime = 0
numFrames = 0
deleteKeys objects #allKeys
allBones = for o in geometry where classof o == bonegeometry collect o
	
print allBones.count
print boneCount
for x=1 to allBones.count do (	--boneCount
 	ReadFixedByteString f 0x10 1 1
	ukw = readlong f
	ukw2 = readshort f	--may also  key type
	keySize = readshort f
	frameCount = readlong f	
	frameOffset = readlong f	
	nextBone = ftell f
	
	posArr=#()
	rotArr=#()
	sclArr=#()
	
	fseek f frameOffset #seek_set
	if keySize == 0x16 do (
		for y=1 to frameCount do (
			rx = readshort f / 32768.0
			ry = readshort f / 32768.0
			rz = readshort f / 32768.0
			rw = readshort f / 32768.0
			p1 = readshort f
			sx = readshort f
			sy = readshort f
			sz = readshort f
			px = readshort f / 16384.0
			py = readshort f / 16384.0
			pz = readshort f / 16384.0
			
			append rotArr (quat rx ry rz rw)
			append posArr (point3 px py pz)
-- 			
-- 			print (rx * rx + ry * ry + rz * rz + rw * rw)
		)
	)
	for y=1 to frameCount do (
		with animate on(
			b = allBones[x]
			if(b != undefined) then (
				at time (y-1)
					b.Controller.Rotation = rotArr[y]
-- 					b.Controller.Position = (posArr[y] * fscale)
-- 					in coordsys parent b.pos = b.skinpos + (posArr[y] * fscale)
			)
		)
	)
	
	
	if numFrames < frameCount do numFrames = frameCount
	fseek f nextBone #seek_set
)
animationRange = interval 0 numFrames


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
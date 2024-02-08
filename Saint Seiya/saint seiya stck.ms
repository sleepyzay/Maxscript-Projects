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

fname = GetOpenFileName caption:"" types:"STCK (*.stck)|*.stck" historyCategory:""
-- fname=@"C:\Users\Xavier\Desktop\saint seiya online\Ikki\Running.stck"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
fscale=50
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

MOXBKCTS = ReadFixedString f 8
ukw = readlong f
boneCount = readlong f

fseek f 0x14 #seek_set
numFrames = readlong f
ukw = readlong f

format "boneCount: %\n" boneCount

if numFrames > 0 do (
	timeMult = 1.0
	
	sliderTime = 0
	animationRange = interval 0 (numFrames*timeMult)
	deleteKeys objects #allKeys
	BNArr = for o in geometry where classOf o == boneGeometry collect o
	for x=1 to boneCount do (
		boneID = readlong f + 1

		posCount = readlong f
		ReadFixedByteString f 0x8 0 0	--always 0x01 and 0x1e
		posArr = for y=1 to posCount collect (point3 (readfloat f) (readfloat f) (readfloat f))
		ReadFixedByteString f 0x8 0 0	--always 0x258 and 0x01
		posTime = for y=1 to posCount collect (readshort f #unsigned)
		
		rotArr=#()
		rotCount = readlong f
		ReadFixedByteString f 0x8 0 0	--always 0x01 and 0x1e
		ukw = readlong f	--keyType?, always 0x01
		for y=1 to rotCount do (
			rx = readfloat f
			ry = readfloat f
			rz = readfloat f
			rw = sqrt(abs(1.0 - (rx*rx + ry*ry + rz*rz)))
			
			rotArr[y] = (quat rx ry rz rw)
		)
		ReadFixedByteString f 0x8 0 0	--always 0x258 and 0x01
		rotTime = for y=1 to rotCount collect (readshort f #unsigned)
		
-- 		format "boneID: % posCount: % rotCount: %\n" boneID posCount rotCount
		
		with animate on(
			b = BNArr[boneID]
			print b.name
			
			for i=1 to rotArr.count do (
				q = rotArr[i]
				
				if(b != undefined) then (
					at time (rotTime[i]*timeMult)
					b.Controller.Rotation = inverse q
				)
			)
			
			for i=1 to posArr.count do (
				p = posArr[i]
				
				if(b != undefined) then (
					at time (posTime[i]*timeMult)
					b.Controller.Position = (p*fscale)
				)
			)
			
		)
		stopanimation()
		
		
		
	)
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
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

fname = GetOpenFileName caption:"" types:"STCK (*.stck)|*.stck" historyCategory:""
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
fileVersion = readlong f
boneCount = readlong f

fseek f 0x14 #seek_set
numFrames = readlong f
ukw = readlong f

format "fileVersion: % \nboneCount: %\nframeCount: %\n" fileVersion boneCount numFrames

if numFrames > 0 do (
	if fileVersion == 1 do numFrames *= 2.0
	
	sliderTime = 0
	animationRange = interval 0 numFrames
	deleteKeys objects #allKeys
	BNArr = for o in geometry where classOf o == boneGeometry collect o
	for x=1 to boneCount do (
		boneID = readlong f + 1
		
		posArr=#()
		posTime=#()
		posCount = readlong f
		ReadFixedByteString f 0x8 0 0
		posArr = for y=1 to posCount collect (point3 (readfloat f) (readfloat f) (readfloat f))
		ReadFixedByteString f 0x8 0 0
		if fileVersion > 1 then (
			posTime = for y=1 to posCount collect (readshort f #unsigned)
		)
		else (
			fseek f 0x08 #seek_cur
		)
		
		rotArr=#()
		rotTime=#()
		rotCount = readlong f
		ReadFixedByteString f 0x8 0 0
		if fileVersion > 1 then (
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
		)
		else(
			rotArr = for y=1 to rotCount collect (quat (readfloat f) (readfloat f) (readfloat f) (readfloat f))
			ReadFixedByteString f 0x10 0 0
		)
		
-- 		format "boneID: % posCount: % rotCount: %\n" boneID posCount rotCount
		
		with animate on(
			b = BNArr[boneID]
			
			for i=1 to rotArr.count do (
				q = rotArr[i]
				t = rotTime[i]
				
				if t == undefined do t = ((i-1)*2)
				
				if(b != undefined) then (
					at time t
					b.Controller.Rotation = inverse q
				)
			)
			
			for i=1 to posArr.count do (
				p = posArr[i]
				t = posTime[i]
				
				if t == undefined do t = ((i-1)*2)
				
				if(b != undefined) then (
					at time t
					b.Controller.Position = (p*fscale)
				)
			)
			
		)
	)
	stopanimation()
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
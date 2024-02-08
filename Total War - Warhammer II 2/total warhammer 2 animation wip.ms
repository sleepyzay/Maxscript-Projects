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

fn assumeskinpose = (
	stopAnimation()
	allBones = for o in geometry where classOf o == boneGeometry collect o
	for a in allBones do (
		a.assumeskinpose()
	)
)

fname = GetOpenFileName caption:"" types:" (*.anim)|*.anim" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=75
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

ukw = readlong f	--always 7
ukw2 = readlong f	--always 1
null = readshort f
ukw3 = ReadHalfFloat f
nameLength = readshort f
skelName = ReadFixedString f nameLength
null = readlong f
ukw4 = readfloat f
boneCount = readlong f

print ukw3
print ukw4

boneName=#()
parentID=#()
for x=1 to boneCount do (
	nameLength = readshort f
	boneName[x] = ReadFixedString f nameLength
	parentID[x] = readlong f + 1
)

sliderTime = 0
BNArr = for x=1 to boneCount collect (getnodebyname boneName[x])
deleteKeys objects #allKeys
assumeskinpose()

--0x00 bone is animated
--0x27 bone is static

posIDArr=#(#(),#())
rotIDArr=#(#(),#())
for x=1 to boneCount do (
	boneID = readbyte f #unsigned + 1
	boneFlag = readbyte f #unsigned
	ukw = readshort f		--0, -1
	
	if boneFlag == 0x00 do append posIDArr[1] x
	if boneFlag == 0x27 do append posIDArr[2] x
)
for x=1 to boneCount do (
	boneID = readbyte f #unsigned + 1
	boneFlag = readbyte f #unsigned
	ukw = readshort f		--0, -1
	
	if boneFlag == 0x00 do append rotIDArr[1] x
	if boneFlag == 0x27 do append rotIDArr[2] x
)

staticPosCount = readlong f
staticRotCount = readlong f
for x=1 to staticPosCount do (
	px = readfloat f
	py = readfloat f
	pz = readfloat f
	
	with animate on (
		b = BNArr[posIDArr[2][x]]
		if(b != undefined) then (
			at time 0
				b.Controller.Position = [px,py,pz]*fscale
		)
	)
)
for x=1 to staticRotCount do (
	rx = readshort f
	ry = readshort f
	rz = readshort f
	rw = readshort f
	
	with animate on (
		b = BNArr[rotIDArr[2][x]]
		if(b != undefined) then (
			at time 0
				b.Controller.Rotation = inverse (quat rx ry rz rw)
		)
	)
)

animPosCount = readlong f
animRotCount = readlong f
frameCount = readlong f

framerate = 30
animationRange = interval 0 frameCount
for x=1 to frameCount do (
	for y=1 to animPosCount do (
		px = readfloat f
		py = readfloat f
		pz = readfloat f
		
		with animate on(
			b = BNArr[posIDArr[1][y]]
			if(b != undefined) then (
				at time (x-1)
					b.Controller.Position = [px,py,pz]*fscale
			)
		)
	)
	for y=1 to animRotCount do (
		rx = readshort f
		ry = readshort f
		rz = readshort f
		rw = readshort f
		
		with animate on(
			b = BNArr[rotIDArr[1][y]]
			if(b != undefined) then (
				at time (x-1)
					b.Controller.Rotation = inverse (quat rx ry rz rw)
			)
		)
	)
)
stopanimation()

format "boneCount: % \n" boneCount
format "frameCount: % \n\n" frameCount

format "animPosCount: % \n" animPosCount
format "staticPosCount: % \n\n" staticPosCount
format "animRotCount: % \n" animRotCount
format "staticRotCount: % \n\n" staticRotCount

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
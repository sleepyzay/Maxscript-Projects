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

fname = GetOpenFileName caption:"King of Fighters XIV Animation" types:" (*.otra)|*.otra" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()z
Global fscale=10
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 3
fseek f 0x03 #seek_cur
animCount = readlong f
boneCount = readlong f

boneName=#()
for x=1 to boneCount do (
	boneNameLength = readlong f
	boneName[x] = ReadFixedString f boneNameLength
)

format "animation count: % \n" animCount
animSelect = 82
for x=1 to animSelect do (	--animCount
	numFrames = readlong f
	boneCount = readlong f
	null = readlong f
	animNameLength = readlong f
	animName = ReadFixedString f animNameLength
	ukw = readlong f	--always 1
	
	format "% % \n" x animName
	
	sliderTime = 0
	animationRange = interval 0 numFrames
	deleteKeys objects #allKeys
	for y=1 to boneCount do (
		boneID = readlong f #unsigned + 1
		
		posTime=#()
		posArr=#()
		posCount = readlong f
		for z=1 to posCount do (
			posTime[z] = readlong f #unsigned
			posArr[z] = (point3 (readfloat f) (readfloat f) (readfloat f))
		)
		
		sclTime=#()
		sclArr=#()
		sclCount = readlong f
		for z=1 to sclCount do (
			sclTime[z] = readlong f #unsigned
			sclArr[z] = (point3 (readfloat f) (readfloat f) (readfloat f))
		)
		
		rotTime=#()
		rotArr=#()
		rotCount = readlong f
		for z=1 to rotCount do (
			rotTime[z] = readlong f #unsigned
			rotArr[z] = (quat (readfloat f) (readfloat f) (readfloat f) (readfloat f))
		)
		ukw = readlong f
		
-- 		print boneName[y]
-- 		print ukw
-- 		format "\n"
-- 		if ukw == 0 do print boneName[y]
		
		if x== animSelect do (
			with animate on(
				b = getnodebyname boneName[boneId]
				
				for i=1 to rotArr.count do (
					q = rotArr[i]
					t = rotTime[i]
					
					if(b != undefined) then (
						at time t
						b.Controller.Rotation = q
					)
				)
				
				for i=1 to posArr.count do (
					p = posArr[i]
					t = posTime[i]
					
					
					if(b != undefined) then (
						at time t
							if ukw != 4 do (
-- 							if ((p.x + p.y + p.z) > 0) do (
								b.Controller.Position = (p*fscale)
							)
					)
				)
				
			)
		)
	)
	stopAnimation()
)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
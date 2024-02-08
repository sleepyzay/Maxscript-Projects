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

gname = GetOpenFileName caption:"skeleton" types:" (*.)|*.pxd" historyCategory:""
fname = GetOpenFileName caption:"animation" types:" (*.)|*.pxd" historyCategory:""
If ((gname!=undefined) and ((DoesFileExist gname)==true)) and ((fname!=undefined) and ((DoesFileExist fname)==true)) then (
g = fopen gname "rb"
f = fopen fname "rb"
clearlistener()
-- delete $*
Global fscale=50
Print "===================================="
print ((getFileNameFile gname) + (getFileNameType  gname)) as string
print ((getFileNameFile fname) + (getFileNameType  fname)) as string
Print "===================================="
--)

fseek g 0x48 #seek_set
parentIDOffset = readlonglong g + 0x40
boneCount = readlonglong g
fseek g 0x10 #seek_cur
boneNameOffset = readlonglong g + 0x40
fseek g 0x20 #seek_cur
boneOffset = readlonglong g

fseek g parentIDOffset #seek_set
parentID = for x=1 to boneCount collect (readshort g)

boneName=#()
fseek g boneNameOffset #seek_set
for x=1 to boneCount do (
	append boneName (getName g (readlonglong g + 0x40))
	null = readlonglong g
)

-- BNArr=#()
-- for x=1 to boneCount do (
-- 	float11 = readfloat g; float12 = readfloat g; float13 = readfloat g; float14 = readfloat g
-- 	float21 = readfloat g; float22 = readfloat g; float23 = readfloat g; float24 = readfloat g 
-- 	float31 = readfloat g; float32 = readfloat g; float33 = readfloat g; float34 = readfloat g
-- 	tfm = inverse (quat float21 float22 float23 float24) as matrix3
-- 	tfm.row4 = ([float11,float12,float13]*fscale)
-- 	if (parentID[x] != -1) do (
-- 	tfm *= BNArr[(parentID[x] + 1)].objecttransform	
-- 	)	
-- 	newBone = bonesys.createbone	\
-- 	tfm.row4	\
-- 	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
-- 	(normalize tfm.row3)
-- 	newBone.width  = 0.01
-- 	newBone.height = 0.01
-- 	newBone.transform = tfm
-- 	newBone.setBoneEnable false 0
-- 	newBone.wirecolor = yellow
-- 	newbone.showlinks = true
-- 	newBone.pos.controller      = TCB_position ()
-- 	newBone.rotation.controller = TCB_rotation ()
-- 	newBone.name = boneName[x]
-- 	if (parentID[x] != -1) then(
-- 		newBone.parent = BNArr[(parentID[x] + 1)]
-- 	)
-- 	
-- 	append BNArr newBone
-- )
-- for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
-- for b in BNArr do b.setskinpose()


fseek f 0x58 #seek_set
ukw = readfloat f	--frameRate?
numFrames = readlong f	--frameCount?
tableCount = readlonglong f	--boneCount?
tableOffset = readlonglong f + 0x40

print ukw

sliderTime = 0
framerate = 60
animationRange = interval 0 numFrames
-- for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
deleteKeys objects #allKeys
stopanimation()

fseek f tableOffset #seek_set
for x=1 to tableCount do (	--boneCount
	posArr=#()
	rotArr=#()
	sclArr=#()
	
	--pos--
	posCount = readlonglong f
	posTimeOffset = readlonglong f #unsigned + 0x40
	posOffset = readlonglong f #unsigned  + 0x40
	
	--rot--
	rotCount = readlonglong f
	rotTimeOffset = readlonglong f #unsigned + 0x40
	rotOffset = readlonglong f #unsigned  + 0x40
	
	--scl--
	sclCount = readlonglong f
	sclTimeOffset = readlonglong f #unsigned + 0x40
	sclOffset = readlonglong f #unsigned  + 0x40
	
	backJump = ftell f
	
	fseek f posTimeOffset #seek_set
	posTime = for y=1 to posCount collect (readshort f #unsigned)
	
	fseek f posOffset #seek_set
	for y=1 to posCount do (
		append posArr (point3 (readFloat f) (readFloat f) (readFloat f))
		null = readlong f
	)
	
	fseek f rotTimeOffset #seek_set
	rotTime = for y=1 to rotCount collect (readshort f #unsigned) 
	
	fseek f rotOffset #seek_set
	for y=1 to rotCount do (append rotArr (quat (readFloat f) (readFloat f) (readFloat f) (readFloat f)))
	
	fseek f sclTimeOffset #seek_set
	sclTime = for y=1 to sclCount collect (readshort f #unsigned)
	
	fseek f sclOffset #seek_set
	for y=1 to sclCount do (
		append sclArr (point3 (readFloat f) (readFloat f) (readFloat f))
		null = readlong f
	)
	
	with animate on(
		if posCount == 1 and posTime[1] == (numFrames - 1) do posTime[1] = 0
		for a=1 to posArr.count do (
			
			b = getnodebyname boneName[x]
			t = posTIme[a]
			p = posArr[a]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Position = p * fscale
			)
			
		)
		
		if sclCount == 1 and sclTime[1] == (numFrames - 1) do sclTime[1] = 0
		for a=1 to sclArr.count do (
			
			b = getnodebyname boneName[x]
			t = sclTIme[a]
			s = sclArr[a]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Scale = s
			)
			
		)
		
		if rotCount == 1 and rotTime[1] == (numFrames - 1) do rotTime[1] = 0
		for a=1 to rotArr.count do (
			
			b = getnodebyname boneName[x]
			t = rotTime[a]
			q = rotArr[a]
			
			
			
			if (b!=undefined) then (
				
				at time t
					b.Controller.Rotation = inverse q
			)
			
		)
	)
	
	fseek f backJump #seek_set
)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
fclose g
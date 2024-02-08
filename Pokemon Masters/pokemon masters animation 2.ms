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
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn getString bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	strLength = readlong bstream
	str = ReadFixedString bstream strLength
	fseek bstream backJump #seek_set
	return str
)
fn getVal bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newVal = readlong f
	fseek bstream backJump #seek_set
	return newVal
)
fname = GetOpenFileName caption:"Pokemon Masters Animation" types:" (*.lmd)|*.lmd" historyCategory:""
-- fname=@"E:\models\ripped\pokemon masters\pokemon\pm0001_00_fushigidane\Motions\pm0001_00_ba01_landA01.lmd"
-- fname=@"E:\models\ripped\pokemon masters\trainers\ch0000_00_red\Motions\ch0000_00_red_110_cutin_trainer.lmd"
-- fname=@"E:\models\ripped\pokemon masters\pokemon\pm0002_00_fushigisou\Motions\pm0002_00_eye01.lmd"
-- fname=@"E:\models\ripped\pokemon masters\pokemon\pm0001_00_fushigidane\Motions\pm0001_00_ba20_buturi01.lmd"
-- fname=@"E:\models\ripped\pokemon masters\trainers\ch0000_00_red\Motions\ch0000_00_red_110_idle_uv.lmd"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

headerLength = readlong f
LMD0 = ReadFixedString f 4
ReadFixedByteString f (headerLength - 4) 0 1

ukwOffset = readlong f
ukwOffset2 = readlong f

ukwLength1 = readlong f ; ReadFixedByteString f ukwLength1 0 1
ukwLength2 = readlong f ; ReadFixedByteString f ukwLength2 0 1
ukwLength3 = readlong f ; ReadFixedByteString f ukwLength3 0 1
ukwLength4 = readlong f ; ReadFixedByteString f ukwLength4 0 1

animLength = readfloat f
if ukwLength4 == 0x04 do ukw = readlong f	--null?
animName = (getString f (readlong f + (ftell f - 4)))
frameRate = readfloat f
animOffset = (readlong f + (ftell f - 4))	--4
	
format "animLength: %\n" animLength

fseek f animOffset #seek_set
boneCount = readlong f	--might have to rename to something other than boneCount
boneOffset = for x=1 to boneCount collect (readlong f + (ftell f - 4))
	
print boneCount

sliderTime = 0
allBones = for o in geometry where classof o == bonegeometry collect o
for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
deleteKeys objects #allKeys
stopanimation()

numFrames = 0
for x=1 to boneCount do (
	fseek f boneOffset[x] #seek_set
	ukw = readlong f	--hash? / e0 4f 55 40
	boneName = (getString f (readlong f + (ftell f - 4)))
	boneAnimLength = readfloat f
	
	posTime=#()
	posArr=#()
	posArr2=#()
	
	rotTime=#()
	rotArr=#()
	rotArr2=#()
	
	sclTime=#()
	sclArr=#()
	sclArr2=#()
	
	--0x01	0001		--0x07	0111
	--0x03	0011		--0x11		1 0001
	--0x04	0100		--0x07	0111
	--0x08	1000
	
-- 	print boneName
-- 	ReadFixedByteString f 0x10 1 1
	
	ukw2 = readlong f	-- 0x01 / 0x03 / 0x04 / 0x08, bitMask?
	
	if ukw2 == 1 do (
		ukw = readlong f
		ukwLength1 = readlong f
		fseek f ukwLength1 #seek_cur
		
		ukwOffset = (readlong f + (ftell f - 4))	--faceAnim? / visAnim?
		sclDataOffset = (readlong f + (ftell f - 4))	--scale?
		rotDataOffset = (readlong f + (ftell f - 4))
		posDataOffset = (readlong f + (ftell f - 4))
		
		--Scale--
		fseek f sclDataOffset #seek_set
		ukw = readlong f
		sclTimeOffset = (readlong f + (ftell f - 4))
		sclOffset = (readlong f + (ftell f - 4))
		
		fseek f sclTimeOffset #seek_set
		sclTimeCount = readlong f
		for y=1 to sclTimeCount do append sclTime (readfloat f * (frameRate * animLength))
		
		fseek f sclOffset #seek_set
		sclCount = readlong f
		for y=1 to (sclCount / 3) do append sclArr (point3 (readfloat f) (readfloat f) (readfloat f))
		
		--Rotations--
		fseek f rotDataOffset #seek_set
		ukw = readlong f
		rotTimeOffset = (readlong f + (ftell f - 4))
		rotOffset = (readlong f + (ftell f - 4))
		
		fseek f rotTimeOffset #seek_set
		rotTimeCount = readlong f
		for y=1 to rotTimeCount do append rotTime (readfloat f * (frameRate * animLength))
		
		fseek f rotOffset #seek_set
		rotCount = readlong f
		for y=1 to (rotCount / 4) do append rotArr (quat (readfloat f) (readfloat f) (readfloat f) (readfloat f))
		
		--Translations --
		fseek f posDataOffset #seek_set
		ukw = readlong f
		posTimeOffset = (readlong f + (ftell f - 4))
		posOffset = (readlong f + (ftell f - 4))
		
		fseek f posTimeOffset #seek_set
		posTimeCount = readlong f
		for y=1 to posTimeCount do append posTime (readfloat f * (frameRate * animLength))
		
		fseek f posOffset #seek_set
		posCount = readlong f
		for y=1 to (posCount / 3) do append posArr ((point3 (readFloat f) (readFloat f) (readFloat f)))
	)
	if ukw2 == 3 do (
		ukw = readlong f
		ukwLength1 = readlong f
		fseek f ukwLength1 #seek_cur
		
		print boneName
-- 		printHere f
		
		ukwOffset = (readlong f + (ftell f - 4))
		sclDataOffset = (readlong f + (ftell f - 4))
		rotDataOffset = (readlong f + (ftell f - 4))
		posDataOffset = (readlong f + (ftell f - 4))
		
-- 		printhex ukwOffset
-- 		printhex sclDataOffset
-- 		printhex rotDataOffset
-- 		printhex posDataOffset
-- 		format "\n"
		
		fseek f rotDataOffset #seek_set
		ukw = readlong f
		rotTimeOffset = (readlong f + (ftell f - 4))
		rotDataOffset = (readlong f + (ftell f - 4))
		
		fseek f rotTimeOffset #seek_set
		for y=1 to (readlong f) do append rotTime (readfloat f * (frameRate * animLength))
 		
		fseek f rotDataOffset #seek_set
		for y=1 to ((readlong f) / 3) do append rotArr ((quat (readFloat f) (readFloat f) (readFloat f) (readFloat f)))
		
		fseek f posDataOffset #seek_set
		ukw = readlong f
		posTimeOffset = (readlong f + (ftell f - 4))
		posOffset = (readlong f + (ftell f - 4))
		
		fseek f posTimeOffset #seek_set
		posTimeCount = readlong f
		for y=1 to posTimeCount do append posTime (readfloat f * (frameRate * animLength))
		
		posArr=#()
		fseek f posOffset #seek_set
		posCount = readlong f
		for y=1 to (posCount / 3) do append posArr ((point3 (readFloat f) (readFloat f) (readFloat f)))
		print posArr
	)
	if ukw2 == 8 do (
		ukwLength1 = readlong f
		fseek f ukwLength1 #seek_cur
		
		ukwOffset1 = (readlong f + (ftell f - 4))
		ukwOffset2 = (readlong f + (ftell f - 4))
		ukwOffset3 = (readlong f + (ftell f - 4))
		ukwOffset4 = (readlong f + (ftell f - 4))
		
		fseek f ukwOffset1 #seek_set
		ukw = readlong f
		ukwTimeOffset1 = (readlong f + (ftell f - 4))
		ukwSubOffset1 = (readlong f + (ftell f - 4))
		
		ukwTime1 = #()
		fseek f ukwTimeOffset1 #seek_set
		for y=1 to (readlong f) do append ukwTime1 (readfloat f * (frameRate * animLength))
		
		ukwSubArr1=#()
		fseek f ukwSubOffset1 #seek_set
		for y=1 to (readlong f) do append ukwSubArr1 (readlong f)

		fseek f ukwOffset2 #seek_set
		ukw = readlong f
		ukwTimeOffset2 = (readlong f + (ftell f - 4))
		ukwSubOffset2 = (readlong f + (ftell f - 4))
		
		ukwTime2 = #()
		fseek f ukwTimeOffset2 #seek_set
		for y=1 to (readlong f) do append ukwTime2 (readfloat f * (frameRate * animLength))
 		
		ukwSubArr2=#()
		fseek f ukwSubOffset2 #seek_set
		for y=1 to ((readlong f) / 3) do append ukwSubArr2 ((point3 (readFloat f) (readFloat f) (readFloat f)))
 		
		fseek f ukwOffset3 #seek_set
		ukw = readlong f
		ukwTimeOffset3 = (readlong f + (ftell f - 4))
		ukwSubOffset3 = (readlong f + (ftell f - 4))
		
		ukwTime3 = #()
		fseek f ukwTimeOffset3 #seek_set
		for y=1 to (readlong f) do append ukwTime3 (readfloat f * (frameRate * animLength))
 		
		ukwSubArr3=#()
		fseek f ukwSubOffset3 #seek_set
		for y=1 to ((readlong f) / 4) do append ukwSubArr3 ((point4 (readFloat f) (readFloat f) (readFloat f) (readFloat f)))
		
		fseek f ukwOffset4 #seek_set
		ukw = readlong f
		ukwTimeOffset4 = (readlong f + (ftell f - 4))
		ukwSubOffset4 = (readlong f + (ftell f - 4))
		
		ukwTime4 = #()
		fseek f ukwTimeOffset4 #seek_set
		for y=1 to (readlong f) do append ukwTime4 (readfloat f * (frameRate * animLength))
		
		ukwSubArr4=#()
		fseek f ukwSubOffset4 #seek_set
		for y=1 to ((readlong f) / 3) do append ukwSubArr4 ((point3 (readFloat f) (readFloat f) (readFloat f)))
	)
	if ukw2 == 4 do (
		ukw = readlong f
		ukwLength1 = readlong f
		fseek f ukwLength1 #seek_cur
		
		ukwOffset = (readlong f + (ftell f - 4))	--faceAnim? / visAnim?
		sclDataOffset = (readlong f + (ftell f - 4))	--scale?
		rotDataOffset = (readlong f + (ftell f - 4))
		posDataOffset = (readlong f + (ftell f - 4))
		
		--Scale--
		fseek f sclDataOffset #seek_set
		ukw = readlong f
		sclTimeOffset = (readlong f + (ftell f - 4))
		sclOffset = (readlong f + (ftell f - 4))
		sclOffset2 = (readlong f + (ftell f - 4))
 		
		fseek f sclTimeOffset #seek_set
		sclTimeCount = readlong f
		for y=1 to sclTimeCount do append sclTime (readfloat f * (frameRate * animLength))
		
		fseek f sclOffset #seek_set
		sclCount = readlong f
		for y=1 to (sclCount / 3) do append sclArr (point3 (readfloat f) (readfloat f) (readfloat f))
		
		fseek f sclOffset2 #seek_set
		sclCount2 = readlong f
		for y=1 to (sclCount2 / 3) do append sclArr2 (point3 (readfloat f) (readfloat f) (readfloat f))
		
		--Rotations--
		fseek f rotDataOffset #seek_set
		ukw = readlong f
		rotTimeOffset = (readlong f + (ftell f - 4))
		rotOffset = (readlong f + (ftell f - 4))
		rotOffset2 = (readlong f + (ftell f - 4))
		
		fseek f rotTimeOffset #seek_set
		rotTimeCount = readlong f
		for y=1 to rotTimeCount do append rotTime (readfloat f * (frameRate * animLength))
		
		fseek f rotOffset #seek_set
		rotCount = readlong f
		for y=1 to (rotCount / 3) do append rotArr (inverse (eulertoquat (eulerangles (radtodeg (readfloat f)) (radtodeg (readfloat f)) (radtodeg (readfloat f)))))
		
		fseek f rotOffset #seek_set
		rotCount2 = readlong f
		for y=1 to (rotCount2 / 3) do append rotArr2 (inverse (eulertoquat (eulerangles (radtodeg (readfloat f)) (radtodeg (readfloat f)) (radtodeg (readfloat f)))))
		
		--Translations --
		fseek f posDataOffset #seek_set
		ukw = readlong f
		posTimeOffset = (readlong f + (ftell f - 4))
		posOffset = (readlong f + (ftell f - 4))
		posOffset2 = (readlong f + (ftell f - 4))
		
		fseek f posTimeOffset #seek_set
		posTimeCount = readlong f
		for y=1 to posTimeCount do append posTime (readfloat f * (frameRate * animLength))
		
		fseek f posOffset #seek_set
		posCount = readlong f
		for y=1 to (posCount / 3) do append posArr ((point3 (readFloat f) (readFloat f) (readFloat f)))
		
		fseek f posOffset2 #seek_set
		posCount2 = readlong f
		for y=1 to (posCount2 / 3) do append posArr2 ((point3 (readFloat f) (readFloat f) (readFloat f)))
	)
	
	if (frameRate * animLength) > numFrames do numFrames = (frameRate * animLength)
	with animate on(
		for y=1 to sclTime.count do (
			b = getnodebyname boneName
			t = sclTime[y]
			s = sclArr[y]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Scale = s
			)
		)
		for y=1 to rotTime.count do (
			b = getnodebyname boneName
			t = rotTime[y]
			q = rotArr[y]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Rotation = inverse q
			)
		)
		for y=1 to posTime.count do (
			b = getnodebyname boneName
			t = posTime[y]
			p = posArr[y]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Position = p * fscale
			)
		)
	)
	
	
	format "\n"
)
animationRange = interval 0 numFrames

-- for b in geometry where classof b == bonegeometry do (
-- 	for j in b.position.controller.keys do (
-- 		j.tension = 50
-- 	)
-- 	for k in b.rotation.controller.keys do (
-- 		k.tension = 50
-- 	)
-- 	for l in b.scale.controller.keys do (
-- 		l.inTangentType = #linear
-- 		l.outTangentType = #linear
-- 	)
-- )


Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
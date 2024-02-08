--sleepyzay--

fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn AddHexaDecimalPadding nr = (
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
fn ReadFixedByteString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += AddHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   print str
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)   
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
fn ReadBEshort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
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
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
)
fn getBone boneArray boneName = (
	--too slow
	boneSuffix = (filterstring boneName "_")[2]
	for a in boneArray do (
		
		if (matchpattern a.name pattern:("*"+boneSuffix+"*")) == true do (
			return a
		)
	)
)

struct translationData ( BoneId, FrameID, Position )
struct rotationData (BoneId, FrameID, Euler  )

fname = GetOpenFileName caption:"DBZ Burst Limit Animation" types:" (*.bin)|*.bin" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=5
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = ReadFixedString f 4
headerLength = readbelong f
null = readbelong f
ukw = readbelong f	--always 2
tableCount = readbelong f
tableOffset = readbelong f
boneCount = readbelong f
nameOffset = readbelong f

boneName=#()
fseek f nameOffset #seek_set
for x=1 to boneCount do (boneName[x] = ReadFixedString f 0x20)
print boneName[1]
BNArr = for o in geometry where classOf o == boneGeometry collect o
-- for a in BNArr do a.assumeskinpose()

animOffset=#()
numFrames=#()
fseek f tableOffset #seek_set
for x=1 to tableCount do (
	frames = readbeshort f
	ukw2 = readbeshort f
	offset = readbelong f
	
	if offset != 0 do append animOffset offset
	if frames != 0 do append numFrames frames
)

format "bone count :% \n\n" boneCount
format "animation count :% \n\n" animOffset.count


anim = 1
for x=anim to anim do (	--tableCount
	fseek f animOffset[x] #seek_set
	
	keyFrameCount=#()
	keyFrameOffset=#()
	for y=1 to boneCount do (
		keyFrameCount[y] = readbelong f
		keyFrameOffset[y] = readbelong f
	)
	
	translations = #()
	rotations = #()
	for y=1 to boneCount do (
		fseek f keyFrameOffset[y] #seek_set
		
		if keyFrameOffset[y] !=0 do (
-- 			format "% \n" boneName[y]
-- 			format "keyframe data at: 0x%\n" (bit.intashex(ftell f))
-- 			format "keyframe count: %\n\n" keyFrameCount[y]
			
			for z=1 to keyFrameCount[y] do (
				tableIndex = readbeshort f
				frameIDSize = readbeshort f
				frameCount = readbeshort f
				ukw = readbeshort f	--always 1
				frameIDOffset = readbelong f
				frameOffset = readbelong f
				nextKeyFrame = ftell f
				
-- 				format "frame count: %\n" (bit.intashex(frameCount))
				
				fseek f frameIDOffset #seek_set
				if frameIDSize == 0 do frameID = for j=1 to frameCount collect readbyte f #unsigned
				if frameIDSize == 1 do frameID = for j=1 to frameCount collect readbeword f 
				
				fseek f frameOffset #seek_set
				if z==1 do (
-- 					format "rotations at: 0x% \n\n" (bit.intashex(ftell f))
					for j=1 to frameCount do (
						rot = rotationData()
						
-- 						rx = ReadBEshort f / (32768.0/pi)
-- 						ry = ReadBEshort f / (32768.0/pi)
-- 						rz = ReadBEshort f / (32768.0/pi)
-- 						
-- 						rx = ReadBEword f / (32768.0/pi)
-- 						ry = ReadBEword f / (32768.0/pi)
-- 						rz = ReadBEword f / (32768.0/pi)
						
-- 						rx = (ReadBEshort f / 32767.0)*pi
-- 						ry = (ReadBEshort f / 32767.0)*pi
-- 						rz = (ReadBEshort f / 32767.0)*pi
						
						rx = (ReadBEshort f / 65535.0)*360.0
						ry = (ReadBEshort f / 65535.0)*360.0
						rz = (ReadBEshort f / 65535.0)*360.0
-- 						
-- 						rx = (ReadBEshort f / 180.0)
-- 						ry = (ReadBEshort f / 180.0)
-- 						rz = (ReadBEshort f / 180.0)
						
						rot.BoneId = y
						rot.FrameID = frameID[j]
						rot.Euler = (eulerAngles rx ry rz)
-- 						rot.Euler = (eulerAngles (RadToDeg (rx)) (RadToDeg (ry)) (RadToDeg (rz)))
						append rotations rot
					)
				)
				if z==2 do (
-- 					format "translations at: 0x% \n\n" (bit.intashex(ftell f))
					for j=1 to frameCount do (
						tran = translationData()
						
						tx = ReadBEfloat f
						ty = ReadBEfloat f
						tz = ReadBEfloat f
						
						tran.BoneId = y
						tran.FrameID = frameID[j]
						tran.Position = [tx,ty,tz]*fscale
						
						append translations tran
					)
				)
				
				fseek f nextKeyFrame #seek_set
			)
		)
	)
	
	
	with animate on(
		sliderTime = 0
		animationRange = interval 1 numFrames[x]
		for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
		deleteKeys objects #allKeys
		
		for i=1 to rotations.count do (
-- 			b = getBone BNArr boneName[rotations[i].boneId]
			b = getnodebyname boneName[rotations[i].boneId]
-- 			b = BNArr[rotations[i].boneId]
			t = rotations[i].FrameID
			q = rotations[i].Euler
			
			if(b != undefined) then (
				at time t
				b.Controller.Rotation = q
			)
		)
		
-- 		bcArr=#()	--cheap fix --referencing from the original position, need to reload the model per animation load
-- 		for i=1 to translations.count do (
-- 			bcArr[i] = copy (getnodebyname boneName[translations[i].boneId])
-- 		)
 		
		for i=1 to translations.count do (
-- 			b = getBone BNArr boneName[translations[i].boneId]
			b = getnodebyname boneName[translations[i].boneId]
-- 			b = BNArr[translations[i].boneId]
			t = translations[i].FrameID
			p = translations[i].Position
			
			if(b != undefined) then (
				at time t
					in coordsys parent b.pos = b.skinpos + p
			)
		)
		
		
		stopAnimation()
	)
	
-- 	bn = $GOK_WAIST
-- 	bn.pos.x = 0
-- 	bn.pos.y = 0
	
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
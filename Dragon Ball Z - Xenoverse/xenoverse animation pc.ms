-- SleepyZay --

fn ReadFixedString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)
fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)	
fn ReadFixedByteString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  if mod i 1 == 0 do str += " "
   )
   str
   print str
)
fn Readword fstream = (
return readshort fstream #unsigned
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
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	name = readstring bstream
	fseek bstream backJump #seek_set
	
	return name
)
fn getOffset bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newOffset = readlong bstream
	fseek bstream backJump #seek_set
	return newOffset
)
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
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

struct posData (boneId, frameID, pos)
struct rotData (boneId, frameID, rot)
-- struct frameData (
-- 	
-- )

fname = GetOpenFileName caption:"" types:"All Formats|*.nan;*.ean|(.ean)|*.ean|(.nan)|*.nan"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 4
ukw = readshort f
headerLength = readshort f
ukw = readfloat f
null = readlong f
ukw = readshort f
animCount = readshort f
skelOffset = readlong f
animOffsetTable = readlong f
animNameOffset = readlong f

fseek f skelOffset #seek_set
boneCount = readshort f
ukw = readshort f	--skelCount?
boneDataOffset = readlong f + skelOffset
nameOffsetTable = readlong f + skelOffset
boneStart = readlong f + skelOffset

parentID=#()
fseek f boneDataOffset #seek_set
for x=1 to boneCount do (
	parentID[x] = readshort f + 1
	childID = readshort f + 1
	siblingID = readshort f + 1
	ukwID = readshort f + 1
)

fseek f nameOffsetTable #seek_ser
boneName = for x=1 to boneCount collect (getName f (readlong f + skelOffset))

if (skelPresent() == false) do (
	BNArr = #()
	fseek f boneStart #seek_set
	for x=1 to boneCount do (
		float11 = readfloat f; float12 = readfloat f; float13 = readfloat f; float14 = readfloat f 
		float21 = readfloat f; float22 = readfloat f; float23 = readfloat f; float24 = readfloat f 
		float31 = readfloat f; float32 = readfloat f; float33 = readfloat f; float34 = readfloat f
		tfm = (quat float21 float22 float23 float24) as matrix3
		tfm.row4 = [float11,float12,float13]*fscale
		if (parentID[x] != 0) do (
			tfm *= BNArr[(parentID[x])].objecttransform	
		)
		newBone = bonesys.createbone	\
		tfm.row4	\
		(tfm.row4 + 0.01 * (normalize tfm.row1)) \
		(normalize tfm.row3)
		newBone.width = 0.1
		newBone.height = 0.1
		newBone.wirecolor = orange
		newbone.showlinks = true
		newBone.transform =  tfm
		newBone.name = boneName[x]
		newBone.setBoneEnable false 0
		newBone.pos.controller = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()

		if (parentID[x] != 0) then (
			newBone.parent = BNArr[parentID[x]]
		)
		
		append BNArr newBone
	)
	rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
	for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
	for b in BNArr where b.children.count == 0 do b.wirecolor = green
	for b in BNArr do b.setskinpose()
)

fseek f animNameOffset #seek_set
aniName = for x=1 to animCount collect (GetName f (readlong f))

fseek f animOffsetTable #seek_set
animOffset = for x=1 to animCount collect (readlong f)
	
for x=1 to animCount do (
	format "% %\n" x aniName[x]
)

animSelect = 1
for x=animSelect to animSelect do (	-- animCount
	fseek f animOffset[x] #seek_set
	format "% \n" aniName[x]

	null = readshort f
	frameIDSize = readbyte f #unsigned
	frameSize = readbyte f #unsigned
	numFrames = readlong f
	boneCount = readlong f
	boneDataOff = readlong f + animOffset[x]
	boneOffset = for y=1 to boneCount collect (readlong f +animOffset[x])
	
	sliderTime = 0
	framerate = 60
	animationRange = interval 0 numFrames
	for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
	deleteKeys objects #allKeys
	stopanimation()
	
	for y=1 to boneCount do (
		
		fseek f boneOffset[y] #seek_set
		boneID = readword f + 1
		controllerCount = readshort f
		controllerOffsetTable = readlong f + boneOffset[y]
		
		fseek f controllerOffsetTable #seek_set
		controllerOffset = for z=1 to controllerCount collect (readlong f + boneOffset[y])
		
		posArr=#()
		posTIme=#()
		rotArr=#()
		rotTime=#()
		sclArr=#()
		sclTime=#()
		for z=1 to controllerCount do (
			fseek f controllerOffset[z] #seek_set
			
			tableIndex = readbyte f #unsigned
			ukw = readbyte f #unsigned	-- usually 7, sometimes 3 for camera
			null = readshort f
			frameCount = readlong f
			frameIDOffset = readlong f + controllerOffset[z]
			frameOffset = readlong f + controllerOffset[z]
			
			if ukw != 7 do (
				print tableIndex
				print ukw
				format "\n"
			)
			
			fseek f frameIDOffset #seek_set
			if frameIDSize == 0 do frameID = for a=1 to frameCount collect (readbyte f #unsigned)
			if frameIDSize == 1 do frameID = for a=1 to frameCount collect (readword f)
			
			fseek f frameOffset #seek_set
			if tableIndex==0 do (	--pos
				for a=1 to frameCount do (
					if frameSize == 1 do (append posArr ((point3 (readHalfFloat f) (readHalfFloat f) (readHalfFloat f)) / (readHalfFloat f)))
					if frameSize == 2 do (append posArr ((point3 (readFloat f) (readFloat f) (readFloat f)) / (readFloat f)))
				)
				posTIme = frameID
			)
			if tableIndex==1 do (	--rot
				for a=1 to frameCount do (
					if frameSize == 1 do (append rotArr (quat (readHalfFloat f) (readHalfFloat f) (readHalfFloat f) (readHalfFloat f)))
					if frameSize == 2 do (append rotArr (quat (readFloat f) (readFloat f) (readFloat f) (readFloat f)))
				)
				rotTime = frameID
			)
			if tableIndex==2 do (	--scale
				for a=1 to frameCount do (
					if frameSize == 1 do (append sclArr (point3 (readHalfFloat f) (readHalfFloat f) (readHalfFloat f)))
					if frameSize == 2 do (append sclArr (point3 (readFloat f) (readFloat f) (readFloat f)))
				)
				sclTime = frameID
			)
		)
		
		with animate on(
			for a=1 to posArr.count do (
				
				b = getnodebyname boneName[boneID]
				t = posTIme[a]
				p = posArr[a]
				
				if (b!=undefined) then (
					at time t
					b.Controller.Position = p * fscale
				)
				
			)
			for a=1 to rotArr.count do (
				
				b = getnodebyname boneName[boneID]
				t = rotTime[a]
				q = rotArr[a]
				
				if (b!=undefined) then (
					at time t
					b.Controller.Rotation = inverse q
				)
				
			)
			for a=1 to sclArr.count do (
				
				b = getnodebyname boneName[boneID]
				t = sclTime[a]
				s = sclArr[a]
				
-- 				if (b!=undefined) then (
-- 					at time t
-- 					b.Controller.Scale = s
-- 				)
-- 				
			)
		)
	)
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

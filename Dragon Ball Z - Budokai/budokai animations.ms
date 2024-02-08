fn ReadFixedString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str0 = ReadByte bstream #unsigned
      If str0!=0xFD AND str0!=0xFC do str+= bit.intAsChar str0
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
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   print str
)
fn GetName bstream Offset = (
	fseek bstream Offset #seek_set
	MeshName = readstring bstream
	return MeshName
)
fn FindNumofOcurrences narray num = (
	j=0
	for i in narray do (
		if i == num do j+=1
	)
	return j
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
fn Readword fstream = (
return readshort fstream #unsigned
)
fn getBone boneArray boneName = (
	compare = filterstring boneName "_"
	for x=1 to boneArray.count do (	--loop through bone names until we reached the desired bone
		suffix = filterstring boneArray[x].name "_"
		if compare[compare.count] == suffix[suffix.count] do (
			return boneArray[x]
		)
-- 		else (
-- 			return undefined
-- 		)
	)
)

struct translationData ( BoneId, FrameID, Position )
struct rotationData (BoneId, FrameID, Euler  )

fname = GetOpenFileName caption:"" types:" (*.amm)|*.amm;*.bin" historyCategory:""
-- fname = @"C:\Users\Xavier\Desktop\FULL_AFS_FILE_DUMP\BC18G_out\BC18G_005.bin"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=5
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = ReadFixedString f 4
headerLength = readlong f
null = readlong f
ukw = readlong f	--always 2
tableCount = readlong f
tableOffset = readlong f
boneCount = readlong f
nameOffset = readlong f

boneName=#()
fseek f nameOffset #seek_set
for x=1 to boneCount do (
	boneName[x] = ReadFixedString f 0x20
)
print boneName[1]
BNArr=#()
for o in geometry where classOf o == boneGeometry do (
	append BNArr o
	o.assumeSkinPose()
)

animOffset=#()
numFrames=#()
fseek f tableOffset #seek_set
for x=1 to tableCount do (
	ukw = readlong f	--always 9
	ukw2 = readlong f
	frames = readlong f
	offset = readlong f
	
	if offset != 0 do append animOffset offset
	if frames != 0 do append numFrames frames
)

format "bone count :% \n\n" boneCount
format "animation count :% \n\n" animOffset.count

anim = 131
print anim
for x=anim to anim do (	--tableCount
	fseek f animOffset[x] #seek_set
	
	translations = #()
	rotations = #()
	for y=1 to boneCount do (
		rotOffset = readlong f
		posOffset = readlong f
		nextBone = ftell f
		
		fseek f rotOffset #seek_set
		if rotOffset != 0 do (
			null = readlong f
			ukw = readlong f
			rotCount = readlong f
			
			for z=1 to rotCount do (
				rot = rotationData()
				
				frameID = readshort f #unsigned + 1
				rx = (readshort f / 65536.0)*360
				ry = (readshort f / 65536.0)*360
				rz = (readshort f / 65536.0)*360
				
				rot.BoneId = y
				rot.FrameID = frameID
				rot.Euler = eulerAngles rx ry rz
				append rotations rot
			)
		)
		
		fseek f posOffset #seek_set
		if posOffset != 0 do (
			null = readlong f
			ukw = readlong f
			posCount = readlong f
			
			for z=1 to posCount do (
				tran = translationData()
				
				frameID = readlong f + 1
				
				tx = readfloat f
				ty = readfloat f
				tz = readfloat f
				
				tran.BoneId = y
				tran.FrameID = frameID
				tran.Position = [tx,ty,tz]*fscale
				
				append translations tran
			)
			
			
			
		)
		fseek f nextBone #seek_set
	)
	
	with animate on(
		sliderTime = 0
		animationRange = interval 1 numFrames[x]
		deleteKeys objects #allKeys
		
		for i=1 to rotations.count do (
-- 			b = getBone BNArr boneName[rotations[i].boneId]
			b = getnodebyname boneName[rotations[i].boneId]
			t = rotations[i].FrameID
			q = rotations[i].Euler
			
			if(b!=undefined) then (	--works for some reason, should be "OK"
				at time t
				b.Controller.Rotation = q
			)
		)
 		
		for i=1 to translations.count do (
-- 			b = getBone BNArr boneName[translations[i].boneId]
			b = getnodebyname boneName[translations[i].boneId]
			t = translations[i].FrameID
			p = translations[i].Position
			
			if(b != undefined) then (
				at time t
					in coordsys parent b.pos = b.skinpos + p
			)
		)
		
		stopAnimation()
	)

)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
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
fn printMatrix bstream = (
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	fseek f -0x40 #seek_cur
	format "\n"
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

-- fname = @"C:\Users\Xavier\Downloads\halo_3.11\pm\g7\halo\data\g7\masterchiefanim.g7"
-- fname = @"C:\Users\Xavier\Downloads\halo_3.11\pm\g7\halo\data\g7\l1anim.g7"
fname = @"C:\Users\Xavier\Downloads\halo_3.11\pm\g7\halo\data\g7\l4anim.g7"
fname = @"C:\Users\Xavier\Downloads\halo_3.11\pm\g7\halo\data\g7\ml_unsc_marineanim.g7"
-- fname = GetOpenFileName caption:"" types:" (*.)|*.anim" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=10
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

--have to read from the archive bc the game for some reason stores animations per bone in a file and the current extractor overrites existing files

struct _file (
	fileName = ReadFixedString f 0x40,
	fileLength = readlonglong f,
	fileOffset = readlonglong f,
	ukw = readlonglong f,		--only see it not null when fileType is 1
	fileType = readlonglong f	--1 = animHeader, 4 = animData
)

struct _frameData (
	ukw = readfloat f,		--80, delemeter?, last frame is 0
	ukw2 = readshort f,	--0xff01
	frameId = readshort f,
	rot = (point3 (readFloat f) (readFloat f) (readFloat f)),
	pos = (point3 (readFloat f) (readFloat f) (readFloat f)),
	scl = (point3 (readFloat f) (readFloat f) (readFloat f))
)

struct _animData (
	boneName,
	
	null = readshort f,
	frameCount = readshort f,
	null2 = readlong f,
	ukw = readfloat f,			--8000, animLength?
	frameDataArray = (for x=1 to frameCount collect (frameData = _frameData()))
)

ukw = readlong f
ukw2 = readlong f
fileCount = readlong f
files = for x=1 to fileCount collect (file = _file())

-- fileCount = 127
animIndex = 0
animArray = #()
animNameArray = #()

for x=1 to fileCount do (
	file = files[x]
	if file.fileType == 1 do (		--if animHeader
		animIndex += 1
		animNameArray[animIndex] = file.fileName
-- 		print file.fileName
	)
	if file.fileType == 4 do (		--if animData
		fseek f file.fileOffset #seek_set
		animData = _animData boneName: file.fileName
		if animArray[animIndex] == undefined do animArray[animIndex] = #()
		append animArray[animIndex] animData
	)
)

allBones = for o in geometry where classof o == bonegeometry collect o

for x=1 to animNameArray.count do (
	format "% %\n" (paddstring 2 (x as string)) animNameArray[x]
)

sliderTime = 0
framerate = 60
animationRange = interval 0 100
for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
deleteKeys objects #allKeys
format "animation count: %\n" animArray.count


tx = [-999,999]
ty = [-999,999]
tz = [-999,999]


animSelect = 1
for x=animSelect to 1 do (
	anim = animArray[x]
	print animNameArray[x]
	for animBone in anim do (
		b = getnodebyname animBone.boneName
		if b != undefined do (
-- 			print b.name
			
			for y=1 to animBone.frameDataArray.count do (
				frameData = animBone.frameDataArray[y]
				
				if y < 10 do print frameData
				
				t = frameData.frameId
				r = frameData.rot
				p = frameData.pos * fscale
				if r.x > tx[1] do tx[1] = r.x
				if r.x < tx[2] do tx[2] = r.x
					
				if r.y > ty[1] do ty[1] = r.y
				if r.y < ty[2] do ty[2] = r.y
					
				if r.z > tz[1] do tz[1] = r.z
				if r.z < tz[2] do tz[2] = r.z
				
				
				/*
				r = r * (pi / 180.0)
				with animate on at time t
-- 					b.Controller.Position = p
-- 					in coordsys parent b.pos = b.skinpos + p
					b.Controller.Rotation = inverse ((eulerAngles r.x r.y r.z) as quat)
				*/
			)
		)
	)
)

print tx
print ty
print tz




Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
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
fn ReadUntilOffset bstream offset = (
	local str = ""
	while ((ftell bstream) < offset) do (
		str += bit.intAsChar (ReadByte bstream #unsigned)
	)
   str
)
fn ReadUntilChar bstream char = (
	str = ""
	testChar = ""
	
	t=0
	
	while(testChar != char) 
	do (
		t+=1
		testChar = ReadFixedString bstream 1
		str += testChar
		
		if t > 50 do exit	--failsafe
	)
	str = trimright str char
	str
-- 	print str
	
)
-- fname = GetOpenFileName caption:"" types:" (*.)|*." historyCategory:""
fname=@"C:\Users\Xavier\Desktop\crash ps4\temporary\mack\data\ps4\output\actors\Playable\Crash.igz"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

ukwOffset=#()
ukwLength=#()

fseek f 0x10 #seek_set
for x=1 to 3 do (
	ukw = readlong f
	ukw2 = readlong f
	ukwOffset[x] = readlong f
	ukwLength[x] = readlong f
)

fseek f ukwOffset[2] #seek_set

fseek f (0x210 + ukwOffset[2]) #seek_set
printHEre f
boneDataOffset = readlonglong f + ukwOffset[2]
meshDataOffset = readlonglong f + ukwOffset[2]
ukwDataOffset = readlonglong f + ukwOffset[2]

/*
fseek f boneDataOffset #seek_set
ukw = readlonglong f	--chunkID?, 4
ukw = readlonglong f	--chunkID/count?, 1
ukw = readlonglong f	--chunkID/offset?, 10

boneTableData = readlonglong f + ukwOffset[2]
boneDataLength = readlong f	--length of bone matrices
ukw = readlong f
boneOffset = readlonglong f + ukwOffset[2]

fseek f boneTableData #seek_set
ukw = readlonglong f	--chunkID?, 5
ukw = readlong f
boneCount = readlong f
tableCount = readlong f
tableLength = readlonglong f
ukw = readlong f
tableOffset = readlonglong f + ukwOffset[2]

fseek f tableOffset #seek_set
boneDataOffset = for x=1 to tableCount collect (readlonglong f #unsigned + ukwOffset[2])
for x=1 to tableCount do (
	fseek f boneDataOffset[x] #seek_set

	ukw = readlonglong f	--always 6
	ukw2 = readlonglong f	--always 1
	ukwID = readlonglong f
	ukwID2 = readlong f
	ukwID3 = readlong f
	qx = readfloat f
	qy = readfloat f
	qz = readfloat f
	qw = readfloat f
)

fseek f boneOffset #seek_set
for x=1 to boneCount do (
	fseek f 0x40 #seek_cur
)
*/
fseek f meshDataOffset #seek_set











Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
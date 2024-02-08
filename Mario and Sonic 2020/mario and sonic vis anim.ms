--sleepyzay--

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
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
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
	
	bb = box()
	bb.width = abs(currA[1])
	bb.length = abs(currA[2])
	bb.height = abs(currA[3])
-- 	hide bb
	delete bb
)
fn GetName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)

fname = GetOpenFileName caption:"" types:" (*.)|*.vis-anim" historyCategory:""
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

fileSize = readbelong f
tableCount = readbelong f
fileSize2 = readbelong f	-- minus header
tableOffset = readbelong f
tableOffset2 = readbelong f

fseek f tableOffset #seek_set
dataOffset = readbelong f + 0x18
dataLength = readbelong f
dataOffset2 = readbelong f + 0x18
dataLength2 = readbelong f
dataOffset3 = readbelong f + 0x18
dataLength3 = readbelong f

fseek f dataOffset #seek_set
null = readbelong f
ukw = readbelong f --offset/length?
tableCount3 = readbelong f
tableOffset3 = for x=1 to tableCount3 collect (readbelong f + 0x18)
for x=1 to tableCount3 do ReadFixedByteString f 0x20 0 1
	
animDataName=#()
animDataCount=#()
animDataOffset=#()
for x=1 to tableCount3 do (
	fseek f tableOffset3[x] #seek_set
	animDataName[x] = GetName f (readbelong f + dataOffset3)
	ukw2 = readbefloat f	--60.0 / framerate?
	null = readbelong f
	ukw3 = readbefloat f	--360.0 / numframes?
	ukw4 = readbelong f	--1
	null = readbelong f
	animDataCount[x] = readbelong f
	animDataOffset[x] = readbelong f
)
	
print animDataName

fseek f dataOffset2 #seek_set
for x=1 to tableCount3 / 8 do (
	fseek f ((animDataOffset[x] * 8) + dataOffset2) #seek_set
	m = getnodebyname (animDataName[x])
	
	with animate on (
		for y=1 to animDataCount[x] do (
			visTime = readbefloat f
			visState = readbefloat f
			
			if (m!=undefined) then (
				at time visTime (
					if visState == 1 do hide m
					if visState == 0 do unhide m
				)
			)
			else (print m)
			
			
-- 			format "%	%\n" visTime visState
		)
	)
	
)

	
fseek f dataOffset3 #seek_set
-- for x=1 to 13 do (
-- 	ukwString = readstring f
-- 	ukwString2 = readstring f
-- 	
-- 	print ukwString
-- 	print ukwString2
-- 	format "\n"
-- )
	



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
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

fname = GetOpenFileName caption:"" types:" (*.)|*.bin" historyCategory:""
-- fname = @"C:\Users\Xavier\Desktop\out\MN_BG_TESTEF_001.bin"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

AmgOffset=#()

AMO = readfixedstring f 4
HeaderLength = readlong f
fseek f 0x8 #seek_cur
AmoData_Count = readlong f	-- dont know that its for but its by an interval of 0x20
AmoData_Start = readlong f
AmgCount = readlong f
AmgOffsetTable = readlong f
Bonecount = readlong f	-- Looks like a count
BoneNameTableOffset = readlong f

Print ("AmgCount is "+((AmgCount)as string))
Print "_________________________________"

fseek f BoneNameTableOffset #seek_set
boneName=#()
for x=1 to AmoData_Count do (
	boneName[x] = ReadFixedString f 0x20
)


fseek f AmgOffsetTable #seek_set
for x=1 to AmgCount do (
	AmgOffset[x] = readlong f
)

for x=1 to amgCount do (	-- amgCount
	
	DataOffset=#()
	Ukw1=#()
	Ukw2=#()

-- 	Print ("AMG"+(x)as string)
-- 	Print "______________________________"
	
	fseek f AmgOffset[x] #seek_set
	addto_amg = ftell f 
	
-- 	Print ("addto_amg is 0x"+((bit.intAsHex(ftell f))as string))
	
	AMG = ReadFixedString f 4
	HeaderLength = readlong f
	unk1 = readlong f
	unkcount = readlong f
	BlockCount = readlong f
	BlockStart = readlong f + addto_amg
	unk2 = readlong f
	NameOffset = readlong f + addto_amg
	vertBufferOffset = readlong f + addto_amg
	vertBufferLength = readlong f
	ukwDataOffset = readlong f + addto_amg
	ukwDataCount = readlong f
	vertInfoOffset = readlong f + addto_amg
	vertInfoCount = readlong f
	
	fseek f vertInfoOffset #seek_set
	vertOffset = readlong f + addto_amg
	vertSize = readlong f
	fseek f 0x10 #seek_cur
	uvOffset = readlong f + addto_amg
	uvSize = readlong f
	bindIDOffset = readlong f + addto_amg
	boneIDSize = readlong f
	
	vertCount = ((bindIDOffset - vertOffset) / vertSize)
	
	
	Vert_array=#()
	UV_array=#()	
	
	fseek f vertOffset #seek_set
	for y=1 to vertCount do (
		vx = readfloat f
		vy = readfloat f
		vz = readfloat f
		
		append Vert_array([vx,vz,vy]*fscale)
	)
	fseek f bindIDOffset #seek_set
	for y=1 to vertCount do (
		bone1 = readbyte f #unsigned
		bone2 = readbyte f #unsigned
		bone3 = readbyte f #unsigned
		bone4 = readbyte f #unsigned
	)
	fseek f uvOffset #seek_set
	printHere f
	for y=1 to vertCount do (
		tu = readfloat f
		tv = readfloat f
		
		append UV_array[tu,tv,0]
	)
	
	fseek f BlockStart #seek_set
	For y=1 to BlockCount do (
		fseek f 0x30 #seek_cur		--bone matrix?
		DataType = readshort f
		DataType2 = readshort f 
		DataOffset[y] = readlong f + addto_amg
		Ukw1[y] = readlong f
		ukw2[y] = readlong f
		fseek f 0x10 #seek_cur
		
-- 		Print ("DataType   "+(paddstring 2 y)+" is 0x"+((bit.intAsHex(DataType))as string))
-- 		Print ("DataOffset "+(paddstring 2 y)+" @ 0x"+((bit.intAsHex(DataOffset[y]))as string))
-- 		format"\n"
	)
	
	For y=1 to blockCount do (	-- blockCount
		fseek f DataOffset[y] #seek_set
-- 		Print ("DataOffset "+(paddstring 2 y)+" @ 0x"+((bit.intAsHex(DataOffset[y]))as string))
-- 		format"\n"
		
		modelNumber = readlong f
		modelOffset = for z=1 to 5 collect (readlong f #unsigned + addto_amg) 
		for z=1 to 5 do (
			if modelOffset[z] > addto_amg do (
				fseek f modelOffset[z] #seek_set	
-- 				Print ("modelOffset "+(paddstring 2 z)+" @ 0x"+((bit.intAsHex(modelOffset[z]))as string))
-- 				format "\n"
				
				if z==1 do (
					Face_array=#()
					faceOffset=#()
					faceCount=#()
					
					fseek f 0x18 #seek_cur	--bb data?
					tableCount = readlong f #unsigned
					for a=1 to tableCount do (
						tableID = readlong f
						faceOffset[a] = readlong f + addto_amg
						faceCount[a] = readlong f
						fseek f 0x10 #seek_cur
					)
					
					for a=1 to tableCount do (
						fseek f faceOffset[a] #seek_set
						printHere f
						For x=1 to faceCount[a]/6 do(
							fa=readshort f +1
							fb=readshort f +1
							fc=readshort f +1
							append Face_array[fc,fb,fa]
						)
						printHere f
					)
					
					msh = mesh vertices:Vert_array faces:Face_array
					msh.numTVerts = UV_array.count
					buildTVFaces msh
					for j = 1 to UV_array.count do setTVert msh j UV_array[j]
					for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
					
				)
				
				
				
			)
		)
	)



)




Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
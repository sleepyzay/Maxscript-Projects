-- SleepyZay --

fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
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


fn ReadFaces VertCount FaceType = (
	Global Face_array=#()
	
	if FaceType == 1 do (
		StartDirection = -1
		x=0
		a=0
		b=1
		
		f1 = a + 1
		f2 = b + 1  
		FaceDirection = StartDirection
		do (
			x+=1
			
			f3 = x
			FaceDirection *= -1
			if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
				if FaceDirection > 0 then append Face_array [f1,f2,f3]
				else append Face_array [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
		)
		while (x < (vertcount))
-- 		print Face_array #nomap
	)
	
	if FaceType == 0 do (
		
		a=0
		b=0
		c=0
		
		For x=1 to vertcount by 3 do (
			a=x
			b=x+1
			c=x+2
			append face_array [a,b,c]
		)
-- 		print face_array #nomap
	)
)
fn ApplyNormals msh Normal_array= (
	max modify mode
	select msh
		
	--set smoothing group of all faces to 1 to get one normal per vertex
	for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
		--set normals via edit normals modifier
		select msh
		addmodifier msh (Edit_Normals ()) ui:off
		msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		EN_setNormal = msh.Edit_Normals.SetNormal
		normID = #{}
	
		--apply normals
		for v = 1 to Normal_array.count do
		(
			free normID
			EN_convertVS #{v} &normID
			for id in normID do EN_setNormal id Normal_array[v]
		)
		collapseStack msh
)
fn getId bstream offset = (
	id = 0
	if offset != 0 do (
		backjump = ftell bstream
		fseek bstream offset #seek_set
		id = (readlong bstream) + 1
		fseek bstream backjump #seek_set
	)
	return id
)
fn getOffset bstream ref offset = (
	backjump = ftell bstream
	fseek bstream offset #seek_set
	fseek bstream 0x8 #seek_cur
	theOffset = readlong bstream + ref
	null = readlong bstream
	fseek bstream backjump #seek_set
	return theOffset
)
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)
fn BuildFaces VertCount FaceType &Face_Array= (
	Global Face_array=#()
	
	if FaceType == 1 do (
		StartDirection = -1
		x=0
		a=0
		b=1
		
		f1 = a + 1
		f2 = b + 1  
		FaceDirection = StartDirection
		do (
			x+=1
			
			f3 = x
			FaceDirection *= -1
			if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
				if FaceDirection > 0 then append Face_array [f1,f2,f3]
				else append Face_array [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
		)
		while (x < (vertcount))
-- 		print Face_array #nomap
	)
	
	if FaceType == 0 do (
		
		a=0
		b=0
		c=0
		
		For x=1 to vertcount by 3 do (
			a=x
			b=x+1
			c=x+2
			append face_array [a,b,c]
		)
-- 		print face_array #nomap
	)
)

-- fname = GetOpenFileName caption:"Budokai PS2" types:"All Known Formats|*.amo;*.bin|Model (*.amo)|*.amo"
fname = @"C:\Users\Xaxa\Downloads\Budokai Models\B3GHC Exclusive Models\160a. Cell Jr. (Default).amo"
-- fname = @"C:\Users\Xavier\Desktop\New folder (4)\New folder\unnamed_488_010.amo"
-- fname = @"D:\models\ripped\dbz budokai 3\unnamed_88.bin"
-- fname = @"D:\models\ripped\dbz budokai 3\unnamed_277.bin"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileExtension = toLower FileExtension
FileName = getFileNameFile fname
delete $*
clearlistener()
Global fscale=5
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

amoOffset = ftell f
amo = ReadFixedString f 4
headerLength = readlong f
null = readlonglong f
boneCount = readlong f
boneDataTableOffset = readlong f
amgCount = readlong f
amgOffsetTable = readlong f 
boneDataCount = readlong f			-- how many possible amg data tables to associate with a bone
boneNameOffset = readlong f

format "boneCount: %\n" boneCount
struct _boneDataTable (
	boneID = readlong f,
	boneDataOffset = readlong f,
	childTableOffset = readlong f,	--pointer to another element of _boneDataTable relative to amo
	siblingTableOffset = readlong f,	--same as above
	parentTableOffset = readlong f,	--same as above
	null = (fseek f 0x0c #seek_cur)
)

struct _boneData (	--0x13 of these per bone
	amgID = readlong f + 1,
	boneID = readlong f + 1,
	matrixOffset = readlong f,
	null = readlong f
)

struct _amgDataTable (
    tfm,
	ukw,
	ukw2,
	dataOffset,
	childOffset,
	siblingOffset,
	parentOffset,

    -- Constructor
    fn init f amgOffset = (
		c11 = readfloat f; c12 = readfloat f; c13 = readfloat f; c14 = readfloat f
		c21 = readfloat f; c22 = readfloat f; c23 = readfloat f; c24 = readfloat f 
		c31 = readfloat f; c32 = readfloat f; c33 = readfloat f; c34 = readfloat f
		tfm = inverse (quat c11 c12 c13 c14) as matrix3
		tfm.row4 = ([c21,c22,c23]*fscale)
		ukw = readshort f
		ukw2 = readshort f
		dataOffset = readlong f + amgOffset
		childOffset = readlong f + amgOffset
		siblingOffset = readlong f + amgOffset
		parentOffset = readlong f + amgOffset
		null = readlong f
		null2 = readlong f
		null3 = readlong f
    )
)

fseek f boneDataTableOffset #seek_set
boneDataTableArray = for x=1 to boneCount collect (ReadFixedByteString f 0x20 1 0; table = _boneDataTable())
	
boneDataArray = #()
for boneDataTable in boneDataTableArray do (
	fseek f boneDataTable.boneDataOffset #seek_set
	append boneDataArray (for x=1 to boneDataCount collect (ReadFixedByteString f 0x10 1 0 ; boneData = _boneData()))
-- 	format "\n"
)

fseek f amgOffsetTable #seek_set
amgOffset = for x=1 to amgCount collect (readlong f)
	
fseek f boneNameOffset #seek_set
boneNameList = for x=1 to boneCount collect (ReadFixedString f 0x20)
print boneNameList



Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f

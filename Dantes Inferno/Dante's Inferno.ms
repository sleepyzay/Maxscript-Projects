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
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
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
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
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

fname = GetOpenFileName caption:"Dantes inferno" types:"Dante's Inferno Geometry(*.geo)|*.geo" historyCategory:"Dante's Inferno"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

Magic = readfixedstring f 4
Ukw = readbelong f	-- always 0x2f
Ukw2 = readbelong f	-- always 0x2
FileSize = readbelong f
fseek f 0x10 #seek_cur	-- bunch of shit

ModelNameOffset = ReadBElong f
Ukw3 = readbelong f
fseek f 0xc #seek_cur

TableCount = readbelong f
Ukw4 = readbelong f
fseek f 0xc #seek_cur	-- look at later, may be important

UkwTableCount=readbelong f
UkwTable=readbelong f

DataTable1=readbelong f
UkwTable2=readbelong f
fseek f 0x08 #seek_cur

UkwBuffer=readbelong f	-- looks like uv's
null = readbelong f
DataTable2=readbelong f
ukw3=readbelong f		--always 40 more than datatable2
fseek f 0x2c #seek_cur

UVStart = readbelong f


print ("Table count is "+((TableCount)as string))	
print ("DataTable 1 offset is 0x"+((bit.intAsHex(DataTable1))as string))
print ("UVStart offset is 0x"+((bit.intAsHex(UVStart))as string))
format "\n"

MeshNameOffset=#()
VertCount=#()
VertSize=#()
VertOffset=#()
VertID=#()
UVSize=#()
FaceOffset=#()
FaceCount=#()
LodType=#()
UVSwitch=#()
	
fseek f DataTable1 #seek_set	
For x=1 to TableCount do (
	Print "===================================="------------------------------
	Print (("Table "+((x)as string))+("					   0x"+(bit.intAsHex(ftell f))))
	Print "===================================="------------------------------
	
	MeshNameOffset[x]=readbelong f 
	fseek f 0x4 #seek_cur	-- data, look into
	UVSwitch[x] = readbelong f
	fseek f 0x14 #seek_cur	-- Bounding box info?
	TableOffset = readbelong f
	ukw2=readbeshort f
	_0x14 = readbyte f	-- always 0x14
	UVSize[x]=readbyte f
	fseek f 0x08 #seek_cur
	
	FaceCount[x]=readbelong f 
	ukwcount = readbelong f -- This plus current facecount = this on the next table of the same id
	VertCount[x]=readbeshort f 
	ukwcount = readbeshort f	-- This plus current vertcount = this on the next table of the same id
	LodType[x]=readbeshort f 	--determines whether or not its a lod model and uses tristrips.  5 If it is, 4 If it isnt
	ukw4 = readbeshort f 	-- looks like an offset
	ukw5 = readbeshort f	-- same as supposed sofar vert total.
	ukw6 = readbeshort f	-- the next supposed sofar vert total of same id - 3. this - last table of the same id's this = current vert count
	ukwOffset=readbelong f 
	fseek f 0x1c #seek_cur	-- blank
	ReadFixedByteString f 0xc
	fseek f (-12) #seek_cur
	VertSize[x]=readbelong f	--	-1 For vertsize of 0x20,  Else For 0x14
	Ukw7 = readbelong f
	VertID[x] = readbelong f
	fseek f 0xc #seek_cur
	null = fseek f 0xc #seek_cur
	VertOffset[x]=readbelong f 
	FaceOffset[x]=readbelong f 
	fseek f 0x20 #seek_cur
	Print ("Vertex count is 0x"+((bit.intAsHex(VertCount[x]))as string))
	Print ("Vertex offset is 0x"+((bit.intAsHex(VertOffset[x]))as string))
	Print ("Vertex size is "+(VertSize[x]as string))
	Print ("Lod type is 0x"+((bit.intAsHex(LodType[x]))as string))
	/*
	
	
	
	Print ("Face count is 0x"+((bit.intAsHex(FaceCount[x]))as string))
	Print ("Face offset is 0x"+((bit.intAsHex(FaceOffset[x]))as string))
	*/
)
format "\n"

UniqueID_array = makeUniqueArray VertID	-- array of all ID's w/o duplications
print ("VertID = "+(VertID)as string)
print ("UniqueID_array = "+(UniqueID_array)as string)

BaseUVArray=#()
UVBufferSize=#()
BaseUVOffsetArray=#()
BaseVertArray=#()
BaseFaceArray=#()
MeshNameArray=#()
BaseVertIDArray=#()

For x=1 to UniqueID_array.count do (
	append UVBufferSize(0)
	append BaseUVArray(#())
	append BaseVertArray(#())
	append BaseFaceArray(#())
	append MeshNameArray(#())
	append BaseVertIDArray(#())
	append BaseUVOffsetArray(0)
)

format "\n"
-- print ("BaseUVArray = "+(BaseUVArray)as string)
print ("BaseVertArray = "+(BaseVertArray)as string)	-- an array of all the verts. where an element would an array of all verts of the same id. each id consisting of an array of each individual vert buffer.
print ("BaseFaceArray = "+(BaseFaceArray)as string)
print ("MeshNameArray = "+(MeshNameArray)as string)
print ("BaseUVOffsetArray = "+(BaseUVOffsetArray)as string)


j=0
For a in BaseFaceArray do (
	j+=1
	For x=1 to (FindNumofOcurrences VertID UniqueID_array[j]) do (
		append a (#())
	)
)

-- Getting UV buffer size associated by vert id
For x=1 to TableCount do (
	GetUniqueIDElement = FindItem UniqueID_array VertID[x]
	
	Case UVSize[x] of (
		
		(0x8):(
			UVBufferSize[GetUniqueIDElement] += (VertCount[x] * 0x8)
		)
		(0xc):(
			UVBufferSize[GetUniqueIDElement] += (VertCount[x] * 0xc)
		)
		(0x10):(
			UVBufferSize[GetUniqueIDElement] += (VertCount[x] * 0x10)
		)
		(0x14):(
			UVBufferSize[GetUniqueIDElement] += (VertCount[x] * 0x14)
		)
		(0x1c):(
			UVBufferSize[GetUniqueIDElement] += (VertCount[x] * 0x1c)
		)
		
	)
	
)

-- Setting the initial offset of the vert id's uv buffer
addto = 0
BaseUVOffsetArray[1] += UVStart
For x=2 to (UniqueID_Array.count) do (
	BaseUVOffsetArray[x] += UVBufferSize[x-1] + addto + UVStart
	addto = BaseUVOffsetArray[x] 
)

format "\n"
print ("BaseUVOffsetArray updated = "+(BaseUVOffsetArray)as string)
print ("UVBufferSize updated = "+(UVBufferSize)as string)
format "\n"

format "\n"
print ("BaseUVArray after = "+(BaseUVArray)as string)
print ("BaseVertArray after = "+(BaseVertArray)as string)
print ("BaseFaceArray after = "+(BaseFaceArray)as string)
-- print ("MeshNameArray after = "+(MeshNameArray)as string)


UV_array=#()
UV_Offset = 0
-- Print ("0x"+bit.intashex(UVStart)as string)
For x=1 to TableCount do ( --should be tablecount
	
	-- getting the index position of the basevertarray based on the current table's id --
	GetUniqueIDElement = FindItem UniqueID_array VertID[x]	
	j=0	-- Getting the index value of the first empty array
	For a in BaseFaceArray[GetUniqueIDElement] do (
		j+=1
		if a.count == 0 then exit
	)
	
-- 	print GetUniqueIDElement	-- this would be 1	
	format "\n"
	print ("j is "+(j)as string)
	
	-- Building Vertices --
	fseek f VertOffset[x] #seek_set	
	Case VertSize[x] of (
		
		(-1): (
			
			print "x20"
			
			For y = 1 to VertCount[x] do(
				vx=readbefloat f
				vy=readbefloat f
				vz=readbefloat f
				fseek f 0x14 #seek_cur
				append BaseVertArray[GetUniqueIDElement]([vx,vy,vz]*fscale)
				append UV_array[0,0,0]
			)
		)
		
		default:(
			Case LodType[x] of (
				(5):(
					print "x14"
					
					for x = 1 to VertCount[x] do(
						vx=readbefloat f
						vy=readbefloat f
						vz=readbefloat f
						fseek f 0x8 #seek_cur
						append BaseVertArray[GetUniqueIDElement]([vx,vy,vz]*fscale)
						append UV_array[0,0,0]
					)
				)
				
				(6):(
					print "x0c"
					
					for x = 1 to VertCount[x] do(
						vx=readbefloat f
						vy=readbefloat f
						vz=readbefloat f
						append BaseVertArray[GetUniqueIDElement]([vx,vy,vz]*fscale)
						append UV_array[0,0,0]
					)
				)
				
				default: Throw "Lod type unrecognized"
			)
		)
	)
	
	-- Building UV's --
-- 	fseek f UVStart #seek_set
	fseek f BaseUVOffsetArray[GetUniqueIDElement] #seek_set
	print (bit.intashex(UVSize[x]) as string)
	Print ("UV start @ 0x"+((bit.intAsHex(ftell f))as string))
	
	Case UVSize[x] of (
		(0x8):(
			For y=1 to VertCount[x] do (
				tu = readbefloat f
				tv = readbefloat f
				append BaseUVArray[GetUniqueIDElement][tu,1-tv,0]		
			)
			Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
		)
		(0xc):(
			For y=1 to VertCount[x] do (
				tu = readbefloat f
				tv = readbefloat f
				tw = readbefloat f
				append BaseUVArray[GetUniqueIDElement][tu,1-tv,0]
			)
			Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
		)
		(0x10):(
			For y=1 to VertCount[x] do (
				tu = readbefloat f
				tv = readbefloat f
				fseek f 0x8 #seek_cur
				append BaseUVArray[GetUniqueIDElement][tu,1-tv,0]
			)
			Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
		)
		(0x14):(
			For y=1 to VertCount[x] do (
				tu = readbefloat f
				tv = readbefloat f
				fseek f 0xc #seek_cur
				append BaseUVArray[GetUniqueIDElement][tu,1-tv,0]		
			)
			Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
		)
		(0x1c):(
			For y=1 to VertCount[x] do (
				tu = readbefloat f
				tv = readbefloat f
				tw = readbefloat f
				fseek f 0x10 #seek_cur
				append BaseUVArray[GetUniqueIDElement][tu,1-tv,0]
			)
			Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
		)
		
	)
	BaseUVOffsetArray[GetUniqueIDElement] = ftell f
	
	-- Building Indices --
	fseek f FaceOffset[x] #seek_set
	if (LodType[x]==0x06) then (
		FaceStart = ftell f
		StartDirection = 1	--was -1
		f1 = (ReadBEword f) + 1
		f2 = (ReadBEword f) + 1  
		FaceDirection = StartDirection
		Do (
		f3 = (ReadBEword f)
		if (f3==0xFFFF) then (
		f1 = (ReadBEword f) + 1
		f2 = (ReadBEword f) + 1
		FaceDirection = StartDirection   
		) else (
		f3 += 1
		FaceDirection *= -1
		if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
		if FaceDirection > 0 then append BaseFaceArray[GetUniqueIDElement][j][f1,f2,f3]
		else append BaseFaceArray[GetUniqueIDElement][j] [f1,f3,f2]
		)
		f1 = f2
		f2 = f3
		)  
		)while (ftell f) < (facestart + (FaceCount[x] * 2))
	)
	Else (
		for y = 1 to FaceCount[x]/3 do (
			fa = (readbeword f) + 1
			fb = (readbeword f) + 1
			fc = (readbeword f) + 1
			append BaseFaceArray[GetUniqueIDElement][j] [fa,fb,fc]
		)
	)
	
	-- Setting up meshname --
	MeshNameArray[GetUniqueIDElement][j] = GetName f MeshNameOffset[x]
	BaseVertIDArray[GetUniqueIDElement][j] = (VertID[x] as string)
	
-- 	print BaseVertArray[2]
-- 	print BaseFaceArray[1]
-- 	print BaseVertIDArray #nomap
	
)
For x=1 to UniqueID_Array.count do (
	
	For y=1 to BaseFaceArray[x].count do (
		msh = mesh vertices:BaseVertArray[x] faces:BaseFaceArray[x][y]
		msh.numTVerts = BaseUVArray[x].count
		msh.wirecolor = random black white
		msh.name = MeshNameArray[x][y]
		msh.backfacecull = off
		buildTVFaces msh
		for j = 1 to BaseUVArray[x].count do setTVert msh j BaseUVArray[x][j]
		for j = 1 to BaseFaceArray[x][y].count do setTVFace msh j BaseFaceArray[x][y][j]
		msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		select msh
		convertTo $ PolyMeshObject
		$.EditablePoly.deleteIsoVerts ()
		convertTo $ TriMeshGeometry
		-- modPanel.addModToSelection (smooth ()) ui:on
		-- $.modifiers[#Smooth].autosmooth = on
		deselect msh
	)
	
)


	
select $*
-- actionMan.executeAction 0 "310"  -- Tools: Zoom Extents Selected
deselect $*

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
-- 4/7/15 11:02 ye. now how about getting a job
gc()
fclose f
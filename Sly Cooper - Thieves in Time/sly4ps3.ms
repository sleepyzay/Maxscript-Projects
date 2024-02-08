-- SleepyZay --

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
fn AlignOffset fstream relativeoffset alignment = (
   align = (alignment - (mod relativeoffset alignment as integer))
   align = fseek fstream align #seek_cur
   return align
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
return bit.intasfloat outputasfloat*2)
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

-- fname = GetOpenFileName caption:"" types:"(.)|*.mes"
fname = @"C:\Users\Xavier\Documents\projects\tools\PSARC-Decompile-tool\out\Levels\UI\Frontend\out\Mesh_1396.mes"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=5
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)



Msh_Vert_array = #()
Msh_Normal_array = #()
Msh_UV_array = #()
Msh_Face_array = #()
MshVertexCount = 0

-- Print ("Mesh @ 0x"+((bit.intAsHex(ftell f))as string))
	
_MESH = ReadFixedString f 4
addto = ftell f
meshLength = readlong f
fileEnd = (meshLength+addto)

MSHH = ReadFixedString f 4
mshhLength = readlong f
fseek f (mshhLength-4) #seek_cur

j=0
for a=1 to 15 do (
	
	
	j+=1
-- 	print j
	Vert_array=#()
	UV_array=#()
	Face_array=#()
	
	Print ("Submesh starts @ 0x"+((bit.intAsHex(ftell f))as string))
	
	SMSH = ReadFixedString f 4
	addto = ftell f
	smshLength = readlong f
	smshEnd = smshLength+addto
	
	MHDR = ReadFixedString f 4
	addto = ftell f
	mhdrLength = readlong f
	vertOffset = (mhdrLength+addto)
	
-- 	Print ("here @ 0x"+((bit.intAsHex(ftell f))as string))
	_4 = readbyte f
	vertCount = Readshort f #unsigned
	faceCount = Readshort f #unsigned
	vertSize = undefined
	fseek f 0x37 #seek_cur
	
	dataType=#()
	dataCount=#()
	dataOffset=#()
	
	do (	-- vertex decleration table
		append dataType(readshort f #unsigned) 
		append dataCount(readshort f #unsigned) 
		vertSize = readbyte f
		append dataOffset(readshort f #unsigned) 
		null = readshort f
		ukw = readbyte f
	)
	while(ftell f < vertOffset-0x10)
	
	
	Print ("vertCount is 0x"+((bit.intAsHex(vertCount))as string))
	Print ("vertSize is 0x"+((bit.intAsHex(vertSize))as string))
	Print ("faceCount is 0x"+((bit.intAsHex(faceCount))as string))
	
	fseek f vertOffset #seek_set
	dataType = ReadFixedString f 4
	addto = ftell f
	print dataType
	if dataType == "MVTX" do (
		mvtxLength = readlong f
		faceOffset = (mvtxLength+addto)
		
		Print ("verts @ 0x"+((bit.intAsHex(ftell f))as string))
		Print ("vertSize is 0x"+((bit.intAsHex(vertSize))as string))
		
		for x=1 to vertCount do (
			vx = ReadBEHalfFloat f
			vy = ReadBEHalfFloat f
			vz = ReadBEHalfFloat f
			ukw = readlong f
			tu = ReadBEHalfFloat f
			tv = ReadBEHalfFloat f
			
			fseek f (vertSize-0xe) #seek_cur
			
			append Vert_array([vz,-1*vx,vy]*fscale)
			append UV_array[tu,tv*-1,0]
		)
		
		fseek f faceOffset #seek_set

		MIDX = ReadFixedString f 4
		addto = ftell f
		midxLength = readlong f
		faceEnd = (midxLength+addto)
		for y=1 to faceCount/3 do(
			fa=ReadBEword f +1
			fb=ReadBEword f +1
			fc=ReadBEword f +1
			append Face_array[fa,fc,fb]
		)
		fseek f smshEnd #seek_set
	-- 				Print ("faces ends @ 0x"+((bit.intAsHex(ftell f))as string))
		
		for i = 1 to Face_array.count do (
			vertices = Face_array[i]
			append Msh_Face_array [vertices[1] + MshVertexCount, vertices[2] + MshVertexCount, vertices[3] + MshVertexCount]
		)
		
		MshVertexCount += Vert_array.count
		for i = 1 to Vert_array.count do (
			append Msh_Vert_array vert_array[i]
	-- 					append Msh_Normal_array normal_array[i]
			append Msh_UV_array UV_array[i]
		)
		
	-- 	msh = mesh vertices:Vert_array faces:Face_array
	-- 	msh.numTVerts = UV_array.count
	-- 	msh.wirecolor = random black white
	-- 	buildTVFaces msh
	-- 	msh.name = (bit.intashex(vertSize) as string)
	-- 	for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
	-- 	for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
	-- 	format "\n"

	)
	if dataType == "MEDG" do (
		medgLength = readlong f
		medgEnd = medgLength + addto
		fseek f medgEnd #seek_set
		
		testType = ReadFixedString f 4
		fseek f -4 #seek_cur
		if testType == "OUTL" do (
			OUTL = ReadFixedString f 4
			addto = ftell f
			outlLength = readlong f
			
-- 			if outlLength == 0x14 do (	-- come back to later
-- 				fseek f 0x10 #seek_cur
-- 			)
			
			OTLH = ReadFixedString f 4
			otlhLength = readlong f
			ukw = readlong f
			ukw2 = readshort f
			ukw3 = readshort f
			
			OUTB = ReadFixedString f 4
			outbLength = readlong f
			
			OUTA = ReadFixedString f 4
			outaLength = readlong f
			ukw4 = readshort f
			ukw5 = readshort f
			ukw6 = readshort f
			ukw7 = readshort f
			
			OUTV = ReadFixedString f 4
			outvLength = readlong f
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
		)
		
		
		
		
		
	)
	format "\n"
	
)


-- do ()
-- while ((ftell f)<fileEnd)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

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
fn GetName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn ReadFaces VertCount FaceType = (
	faceArr=#()
	
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
				if FaceDirection > 0 then append faceArr [f1,f2,f3]
				else append faceArr [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
		)
		while (x < (vertcount))
-- 		print faceArr #nomap
	)
	
	if FaceType == 0 do (
		
		a=0
		b=0
		c=0
		
		For x=1 to vertcount by 3 do (
			a=x
			b=x+1
			c=x+2
			append faceArr [a,b,c]
		)
-- 		print faceArr #nomap
	)
	
	return faceArr
)
fn BuildModel bstream fscale = (
	Msh_Vert_array = #()
	Msh_Normal_array = #()
	Msh_UV_array = #()
	Msh_Face_array = #()
	Msh_Color_array = #()
	MshVertexCount = 0
	
	ukwFlag = readlong bstream
	null = readlong bstream
	meshStartFlag = readlong bstream
	do (
		Vert_array=#()
		UV_array=#()
		Normal_array=#()
		Face_array=#()
		Color_array=#()
		
		meshFlag = readlong bstream #unsigned
		vertCount = readbyte bstream #unsigned
		ukw = readbyte bstream	--always 0x80
		null = readshort bstream
		fseek bstream 0x10 #seek_cur	--data, look at later
		for x=1 to vertCount do (
			vx = readfloat bstream
			vy = readfloat bstream
			vz = readfloat bstream
			nx = readfloat bstream
			ny = readfloat bstream
			nz = readfloat bstream
			cr = readfloat bstream
			cg = readfloat bstream
			cb = readfloat bstream
			tu = readfloat bstream
			tv = readfloat bstream
			cmask = readfloat bstream
			
			vColor = color cr cg cb 0
-- 			cvColor = copy vColor
-- 			vColor *= cmask
-- 			
-- 			if vColor == (color 64515 64515 64515 0) then(
-- 				vColor = cvColor * red
-- 			)
-- 			else (
-- 				vColor = cvColor
-- 			)
-- 			
			append Vert_array ([vx,vy,vz]*fscale)
			append Normal_array[nx,ny,nz]
			append Color_array vColor
			append UV_array[tu,tv,0]
		)
		ukw2 = readshort bstream
		ukw3 = readshort bstream
		
		Face_array = ReadFaces vertCount 1
		
		for i = 1 to Face_array.count do (
			vertices = Face_array[i]
			append Msh_Face_array [vertices[1] + MshVertexCount, vertices[2] + MshVertexCount, vertices[3] + MshVertexCount]
		)
		MshVertexCount += Vert_array.count
		for i = 1 to Vert_array.count do (
			append Msh_Vert_array vert_array[i]
			append Msh_UV_array UV_array[i]
			append Msh_Color_array Color_array[i]
			append Msh_Normal_array normal_array[i]
		)
	)
	while (
		meshFlag == 0x6c018000
	)	
	
	try (
		msh = mesh vertices:Msh_Vert_array faces:Msh_Face_array
		msh.numTVerts = Msh_UV_array.count
		buildTVFaces msh
		setCVertMode msh true
		setNumCPVVerts msh vertCount
		defaultVCFaces msh
		setShadeCVerts msh true
		for j = 1 to Msh_UV_array.count do setTVert msh j Msh_UV_array[j]
		for j = 1 to Msh_Face_array.count do setTVFace msh j Msh_Face_array[j]
		for j = 1 to Msh_Normal_array.count do setNormal msh j Msh_Normal_array[j]
		for j = 1 to Msh_Color_array.count do setVertColor msh j Msh_Color_array[j]
		msh.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	)
	catch(
		delete msh
	)
)


fname = GetOpenFileName caption:"" types:" (*.)|*.dat" historyCategory:""
-- fname=@"C:\Users\Xavier\Desktop\a\a\Q01\1.dat"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

meshOffset2 = readlong f
meshOffset3 = readlong f

fseek f 0x10 #seek_set
BuildModel f fscale

fseek f meshOffset2 #seek_set
BuildModel f fscale

fseek f meshOffset3 #seek_set
BuildModel f fscale


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
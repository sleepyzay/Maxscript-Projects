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

-- fname = GetOpenFileName caption:"" types:" (*.)|*.yobj" historyCategory:""
fname=@"C:\Users\Owner\Downloads\Alpine Racer 3 (Europe) (En,Fr,De,Es,It)\Alpine Racer 3 (Europe) (En,Fr,De,Es,It)\DAT\HQCHAR\HQ07\MD00\0a.yobj"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=10
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 4
fileSize = readlonglong f
fileSize2 = readlonglong f
null = readlong f

meshCount = readlong f
boneCount = readlong f
texCount = readlong f
meshOffset = readlong f + 8
boneOffset = readlong f + 8
texOffset = readlong f + 8

matOffset = readlong f + 8
matCount = readlong f

format "meshCount: % boneCount: % texCount: % matCount: %\n" (bit.intashex(meshCount)) (bit.intashex(boneCount)) (bit.intashex(texCount)) (bit.intashex(matCount)) 

mat = MultiMaterial numsubs:matCount showInViewport:true
meditMaterials[1] = mat
for x=1 to matCount do (
	fseek f (matOffset + ((x-1)*0x20)) #seek_set
	
	matName = readfixedstring f 0x10
	ukw = readlonglong f
	ukw2 = readlonglong f
	
	mat[x].name = matName
	mat[x].diffuse = random black white
)

mat2 = MultiMaterial numsubs:texCount showInViewport:true
meditMaterials[2] = mat2
for x=1 to texCount do (
	fseek f (texOffset + ((x-1)*0x10)) #seek_set
	
	texName = readstring f
	texExtension = readstring f
	
	mat2[x].name = texName
	mat2[x].diffuse = random black white
)

for x=1 to meshCount do (
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	Test_Array=#()
	MatID_Array=#()
	
	fseek f (meshOffset + ((x-1) * 0x40)) #seek_set
	ReadFixedByteString f 0x40 1 0
	
	vertInfoCount = readlong f
	faceInfoCount = readlong f
	vertInfoOffset = readlong f + 8
	faceInfoOffset = readlong f + 8
	matID = readlong f + 1
	ukwOffsetCount = readlong f	--always 0x0e
	ukwOffsetTable = readlong f + 8	--vert related
	ukwOffset = readlong f + 8	--face related
	ukw4 = readlong f	-- = ((vertSum*2)+2)
	ukw5 = readlong f	--count?
	vertSum = readlong f
	null = readlong f
	ukwFloat = readfloat f
	ukwFloat2 = readfloat f
	ukwFloat3 = readfloat f
	ukwFloat4 = readfloat f
	
	format "vertInfoCount: %	faceInfoCount: %\n" (bit.intashex(vertInfoCount)) (bit.intashex(faceInfoCount))
	
	for y=1 to vertInfoCount do (
		fseek f (vertInfoOffset + ((y-1) * 0x20)) #seek_set
		ReadFixedByteString f 0x20 1 1
		
		vertCount = readlong f
		bindCount = readlong f
		vertOffset = readlong f + 8
		normalsOffset = readlong f + 8
		bindIDArr = for z=1 to 4 collect (readlong f)
		
		--format "vertCount: % bindCount: %\n" (bit.intashex(vertCount)) (bit.intashex(bindCount))
		
		fseek f vertOffset #seek_set
		for z=1 to vertCount do (			
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			vw = readfloat f		--1.0
			
			append Vert_Array([vx,vy,vz]*fscale)
-- 			append UV_Array([0,0,0])
		)
		fseek f normalsOffset #seek_set
		for z=1 to vertCount do (
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			nw = readfloat f		--0.0		
			
			append Normal_Array([nx,ny,nz])	
		)
	)
	for y=1 to faceInfoCount do (
		fseek f (faceInfoOffset + ((y-1) * 0xd0)) #seek_set
		fseek f 0x24 #seek_cur	--maxtrix info?
		ukw = readlong f			--0x06 or 0x07
		texID = readlong f + 1
		fseek f 0x94 #seek_cur	--null
		
		ReadFixedByteString f 0x10 1 1
		
		ukw2 = readshort f		--0x01
		ukw3 = readshort f		--count?
		polyElmCount = readlong f
		polyElmOffset = readlong f + 8
		ukwOffset = readlong f + 8
		j=0
		for z=1 to polyElmCount do (
			fseek f (polyElmOffset + ((z-1) * 0x10)) #seek_set
			ReadFixedByteString f 0x10 1 0
			ukw = readlong f	--0x03
			uw2 = readlong f	--0x03
			faceCount = readlong f
			faceOffset = readlong f + 8
			
			f1 = 0
			f2 = 0
			FaceDirection = 1
			for w=1 to faceCount do (
				fseek f (faceOffset + ((w-1) * 0x20)) #seek_set
				ReadFixedByteString f 0x20 1 0
				
				tu = readfloat f
				tv = readfloat f
				tw = readfloat f
				f3 = readlong f #unsigned + 1
				ukwFloat = readfloat f		--1.0
				ukwFloat2 = readfloat f		--1.0
				ukwFloat3 = readfloat f		--1.0
				ukwFloat4 = readfloat f		--1.0
				
				
 				UV_Array[f3] = ([tu,1-tv,0])
				
				if Test_Array[f3] == undefined do Test_Array[f3] = #()
				appendifunique Test_Array[f3] ([tu,tv,0])
 				
				FaceDirection *= -1
				if (f1 != 0) and (f2 != 0) do (
					if FaceDirection > 0 then (
						append Face_array [f1,f2,f3]
					)
					else (
						append Face_array [f1,f3,f2]
					)
					append MatID_Array texID
				)
				f1 = f2
				f2 = f3
			)
		)
	)
	
-- 	for y=1 to Test_Array.count do (
-- 		if Test_Array[y].count > 1 do (
-- 			format "%\n" (bit.intashex(y))
-- 		)
-- 	)
	
	msh = mesh vertices:Vert_Array faces:Face_Array materialIDs:MatID_Array
	msh.numTVerts = UV_Array.count
	msh.wirecolor = random black white
	buildTVFaces msh
-- 	msh.material = mat2
	for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
	for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
 	for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
	msh.transform=(matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0])
	
	format "\n"
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
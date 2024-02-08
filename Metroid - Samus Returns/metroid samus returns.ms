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

fname = GetOpenFileName caption:"" types:" (*.)|*.med" historyCategory:""
-- fname=@"C:\Users\Owner\Desktop\players-20191012T042604Z-001\players\gravity\00000000.med"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=0.5
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct vertElement (
	type,
	offset,
	ukw,
	count,
	null
)

struct vertBuffer (
	vertBufferLength,
	vertCount,
	vertBufferOffset,
	vertElmCount
)

vertBufferArr=#()
decTableArr=#()

faceCountArr=#()
faceOffsetArr=#()

meshNameArr=#()

MMDL = ReadFixedString f 4
ukw = readshort f
ukw2 = readshort f

dataOffset=#()
while true do (
	append dataOffset (readlong f)
	
	if dataOffset[dataOffset.count] == 0 do (
		deleteItem dataOffset dataOffset.count
		exit
	)
) 

for x=1 to dataOffset.count do (
	fseek f dataOffset[x] #seek_set
	print x
	while true do (
		subDataOffset = readlong f
		subDataID = readlong f	--globaly increases
		
		
		backjump = ftell f
		fseek f subDataOffset #seek_set
		ReadFixedByteString f 0x14 1 1
		
		case x of (
			1:(	--verts
				null = readlong f
				null = readlong f
				
				_vertBuffer = (vertBuffer \
					vertBufferLength:	(readlong f) \
					vertCount:				(readlong f) \
					vertBufferOffset:	(readlong f) \
					vertElmCount:		(readlong f)	--polyElmCount?
				)
				
				decTable = for y=1 to _vertBuffer.vertElmCount collect (
					vertElm = (vertElement	\ 
						type:	(readlong f)	\
						offset:	(readlong f)	\
						ukw:		(readshort f)	\	--always 3
						count:	(readshort f)	\
						null:		(readlong f)
					)
				)
				
				append vertBufferArr _vertBuffer
				append decTableArr decTable
			)
			2:(	--faces
				null = readlong f
				ukw = readshort f
				ukw2 = readshort f
				null = readlong f
				
				faceCount = readlong f
				faceOffset = readlong f
				
				append faceCountArr faceCount
				append faceOffsetArr faceOffset
			)
			3:(	--materials
			)
			5:(
				ukwOffset = readlong f
				meshMatOffset = readlong f
				meshNameData = readlong f
				ukw4 = readlong f	--always 1/count?
				null = readlong f
				
				backJump2 = ftell f
				
				fseek f ukwOffset #seek_set
				fseek f 0x40 #seek_cur	--matrix
				fseek f 0x0c #seek_cur	--position?
				vertDataOffset = readlong f	--points to 1
				ukw = readlong f	--always 1
				ukwOffset2 = readlong f
				fseek f 0x0c #seek_cur	--position?
				
				fseek f meshNameData #seek_set
				meshName = (getName f (readlong f))
				ukwMeshNameData = readlong f	--visibility?
				
				append meshNameArr meshName
				
				fseek f backJump2 #seek_set	
			)
			default:(
 				--format "% not defined\n" j
			)
		)

		fseek f backjump #seek_set
		if subDataID == 0 do exit
	)
	format "\n"
)

for x=1 to vertBufferArr.count do (	--meshCount
	Vert_Array=#()
	UV_Array=#()
	Normal_Array=#()
	Face_Array=#()

	print decTableArr[x]
	fseek f vertBufferArr[x].vertBufferOffset #seek_set
	for y=1 to vertBufferArr[x].vertElmCount do (		
		fseek f (vertBufferArr[x].vertBufferOffset + decTableArr[x][y].offset) #seek_set
		case decTableArr[x][y].type of (
			0:(	--position
				for z=1 to vertBufferArr[x].vertCount do (
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					
					append Vert_Array([vx,vy,vz]*fscale)
-- 					append UV_Array[0,0,0]
				)
			)
			1:(	--normals
				for z=1 to vertBufferArr[x].vertCount do (
					nx = readfloat f
					ny = readfloat f
					nz = readfloat f
					
					append Normal_Array[nx,ny,nz]
				)
			)
			2:(	--uv's
				for z=1 to vertBufferArr[x].vertCount do (
					tu = readfloat f
					tv = readfloat f
					
					append UV_Array[tu,1-tv,0]
				)
			)
			6:(	--blend indices / may be wrong assumption
				for z=1 to vertBufferArr[x].vertCount do (
					bone1 = readfloat f
					bone2 = readfloat f
					bone3 = readfloat f
				)
			)
			7:(	--blend weights
				for z=1 to vertBufferArr[x].vertCount do (
					weight1 = readfloat f
					weight2 = readfloat f
					weight3 = readfloat f
					weight4 = readfloat f	--always 0
				)
			)
			
			default:(
				format "unparsed vertElm: % @ %\n" (decTableArr[x][y].type) (bit.intashex((vertBufferArr[x].vertBufferOffset + decTableArr[x][y].offset) as integer))
			)
		)
	)
	format "\n"
	
	fseek f faceOffsetArr[x] #seek_set
	for z=1 to (faceCountArr[x] / 3) do (
		fa = readshort f #unsigned + 1
		fb = readshort f #unsigned + 1
		fc = readshort f #unsigned + 1
		
		append Face_Array[fa,fb,fc]
	)
	
	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = UV_array.count
	msh.wirecolor = random black white
	msh.name = meshNameArr[x]
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
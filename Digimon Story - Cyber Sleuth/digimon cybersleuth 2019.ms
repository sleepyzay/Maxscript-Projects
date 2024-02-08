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
fn ReadHalfFloat fstream = (
    hf=readshort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
	return bit.intasfloat outputasfloat*2
)
fn ReadUntilOffset bstream offset = (
	local str = ""
	while ((ftell bstream) < offset) do (
		str += bit.intAsChar (ReadByte bstream #unsigned)
	)
   str
)


struct weight_data (
	boneids,weights
)
struct vertElement (
	usage,
	count,
	type,
	offset
)

fname = GetOpenFileName caption:"Digimon Cyber Sleuth" types:" (*.geom)|*.geom" historyCategory:""
-- fname=@"C:\Users\Xavier\Documents\stuff\projects\models\ripped\digimon cyber sleuth\chr391.geom"
-- fname=@"D:\stuff\models\ripped\digimon cyber sleuth\chr716.geom"
-- fname=@"D:\stuff\models\ripped\digimon cyber sleuth\chr092.geom"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileFolder = getFileNamePath fname
FileName = getFileNameFile fname

gname = FileFolder +  FileName + ".name"
hname = FileFolder +  FileName + ".skel"

clearlistener()
delete $*
-- Global fscale=.52
Global fscale=50
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

boneName=#()
matName=#()
If (gname!=undefined) and ((DoesFileExist gname)==true) then (
	g = fopen gname "rb"
	NameSize = getFileSize gname

	boneCount = readlong g
	matCount = readlong g
	boneNameOffset = for x=1 to boneCount collect (readlong g)
	matNameOffset = for x=1 to matCount collect (readlong g)
	
	-- boneName--
	for x=1 to boneCount do (
		fseek g boneNameOffset[x] #seek_set
		if x < boneCount then (
			boneName[x] = ReadUntilOffset g boneNameOffset[x+1]
		)
		else (
			boneName[x] = ReadUntilOffset g matNameOffset[1]
		)
	)
	
	-- matName--
	for x=1 to matCount do (
		if x < matCount then (
			matName[x] = ReadUntilOffset g matNameOffset[x+1]
		)
		else (
			matName[x] = ReadUntilOffset g NameSize
		)
	)
	print matName
)
If (hname!=undefined) and ((DoesFileExist hname)==true) then (
	h = fopen hname "rb"
	
	magic = ReadFixedString h 4
	fileSize = readlong h
	null = readlong h
	ukwLength = readlong h					--associated w/ ukwOffset
	boneCount = readshort h
	ukwCount = readshort h					--associated w/ ukwOffset2/3/4
	ukwTableCount = readlong h
	boneOffset = readlong h + 0x18
	parentIDOffset = readlong h + 0x1c
	ukwOffset = readlong h + 0x20		--associated w/ ukwLength
	ukwOffset2 = readlong h + 0x24	--associated w/ ukwCount
	ukwOffset3 = readlong h + 0x28	--associated w/ ukwCount
	ukwOffset4 = readlong h + 0x2c		--associated w/ ukwCount
	
	fseek h parentIDOffset #seek_set
	parentID = for x=1 to boneCount collect (readshort h)
	
	fseek h boneOffset #seek_set
	BNArr=#()
	for x=1 to boneCount do (
		float11 = readfloat h; float12 = readfloat h; float13 = readfloat h; float14 = readfloat h
		float21 = readfloat h; float22 = readfloat h; float23 = readfloat h; float24 = readfloat h 
		float31 = readfloat h; float32 = readfloat h; float33 = readfloat h; float34 = readfloat h
		tfm = inverse (quat float11 float12 float13 float14) as matrix3
		tfm.row4 = ([float21,float22,float23]*fscale)
		if (parentID[x] != -1) do (
		tfm *= BNArr[(parentID[x] + 1)].objecttransform	
		)	
		newBone = bonesys.createbone	\
		tfm.row4	\
		(tfm.row4 + 0.01 * (normalize tfm.row1)) \
		(normalize tfm.row3)
		newBone.width  = 0.01
		newBone.height = 0.01
		newBone.transform = tfm
		newBone.setBoneEnable false 0
		newBone.wirecolor = yellow
		newbone.showlinks = true
		newBone.pos.controller      = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()
		newBone.name = boneName[x]
		if (parentID[x] != -1) then(
			newBone.parent = BNArr[(parentID[x] + 1)]
		)
		
		append BNArr newBone
	)
	rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
	for b in BNArr where b.parent==undefined do b.parent = rootRT
	rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
)

ukw = readlong f
tableCount = readshort f
matCount = readshort f
null = readlong f
boneCount = readlong f
ukw2 = readlong f
null = readlong f
fseek f 0x18 #seek_cur	-- bb info

tableOffset = readlonglong f
matOffset = readlonglong f
fseek f 0x10 #seek_cur	-- null
boneOffset = readlonglong f
null = readlonglong f
texOffset = readlonglong f
ukwOffset = readlonglong f

fseek f tableOffset #seek_set
for x=1 to tableCount do (
	Face_array=#()
	Vert_array=#()
	UV_array=#()
	Normal_array=#()
	Weight_array=#()	
	
-- 	ReadFixedByteString f 0x68 1 1
	
	vertOffset = readlonglong f
	faceOffset = readlonglong f
	boneMapOffset = readlonglong f
	null = readlonglong f
	vertDecTableOffset = readlonglong f
	
	boneMapCount=readshort f
	vertElmCount=readshort f
	vertStride = readlong f
	matSpecID = readbyte f
	matDiffID = readbyte f
	primType = readshort f
	ukw3 = readshort f
	ukw4 = readshort f
	meshID = readlong f
	vertCount = readlong f
	faceCount = readlong f
	null = readlonglong f
	fseek f 0x1c #seek_cur	--boundBox shit probably
	backJump = ftell f
	
	fseek f boneMapOffset #seek_set
	boneMap = for y=1 to boneMapCount collect (readlong f #unsigned + 1)

	fseek f vertDecTableOffset #seek_set
	decTable = for y=1 to vertElmCount collect (
		vertInfo = (vertElement	\ 
			usage:	(readshort f) \
			count:	(readshort f) \
			type:	(readshort f) \
			offset:	(readshort f) \
		)
	)
	
	print decTable
	format "\n"
 	
	fseek f vertOffset #seek_set
	for y=1 to vertCount do (
		w = (weight_data boneids:#() weights:#())
-- 		windows.processPostedMessages()
-- 		ReadFixedByteString f vertStride 1 1
			
		vertRef = ftell f
		for z=1 to vertElmCount do (
			vertInfo = decTable[z]
			fseek f (vertInfo.offset + vertRef) #seek_set
			case vertInfo.usage of (
				0x01:(	--position
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					
					if vertInfo.count == 4 do (
						bone1 = readfloat f / 3 + 1
						
						append w.boneids bone1
						append w.weights 1
					)
					
					append Vert_array([vx,vy,vz]*fscale)
				)
				0x02:(	--normals
					nx = ReadHalfFloat f
					ny = ReadHalfFloat f
					nz = ReadHalfFloat f
					
					append Normal_array[nx,ny,nz]
				)
				0x05:(	--tex coords
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					
					append UV_array[tu,tv,0]
				)
				0x0a:(	--blend indices
					bone1 = (readbyte f #unsigned / 3) + 1
					bone2 = (readbyte f #unsigned / 3) + 1
					
					append w.boneids bone1
					append w.boneids bone2
				)
				0x0b:(	--blend weights
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					
					append w.weights (weight1)
					append w.weights (weight2)
				)
			)
		)
		append Weight_array w
		fseek f (vertRef + vertStride) #seek_set
	)
	
	fseek f faceOffset #seek_set
	if primType == 0 do (
		faceStart = ftell f
		StartDirection = -1
		f1 = (readshort f) + 1
		f2 = (readshort f) + 1  
		FaceDirection = StartDirection
		Do (
			f3 = (readshort f)
			if (f3==0xFFFF) then (
				f1 = (readshort f) + 1
				f2 = (readshort f) + 1
				FaceDirection = StartDirection 
			) 
			else (
				f3 += 1
				FaceDirection *= -1
				if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
					if FaceDirection > 0 then append Face_array [f1,f2,f3]
					else append Face_array [f1,f3,f2]
				)
				f1 = f2
				f2 = f3
			) 
		) 
		while ((ftell f) != (faceStart+(faceCount*2)))
	)
	if primType == 1 do (
		for x=1 to FaceCount/3 do(
			fa=ReadShort f +1
			fb=ReadShort f +1
			fc=ReadShort f +1
			append Face_array[fa,fb,fc]
		)
	)
	
	msh = mesh vertices:Vert_array faces:Face_array
	if UV_array.count == 0 do (UV_array = Vert_array; hide msh)
	msh.numTVerts = UV_array.count
	msh.wirecolor = random black white
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
	-- Applying Skinning --
	max modify mode
	select msh
	skinMod = skin ()
	addModifier msh skinMod
	for i = 1 to boneMap.count do (
		maxbone = getnodebyname BNArr[boneMap[i]].name
		if i != boneMap.count then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
	)
	
	-- Applying Weights --
	modPanel.setCurrentObject skinMod
	for i = 1 to Weight_array.count do (
		w = Weight_array[i]
		bi = #() --bone index array
		wv = #() --weight value array
		
		for j = 1 to w.boneids.count do (
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)	
		
		skinOps.ReplaceVertexWeights skinMod i bi wv
	)
	
-- 	hide msh
	fseek f backJump #seek_set
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
fclose g
fclose h
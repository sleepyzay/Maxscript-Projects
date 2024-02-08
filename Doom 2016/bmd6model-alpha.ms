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
--    print str
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
fn Readword fstream = (
return readshort fstream #unsigned
)
fn DupeFinder uniques = (
	for i in uniques.count to 1 by -1 do
	(
		id = findItem uniques uniques[i]
		if (id != i) do deleteItem uniques i
	)
	return uniques
-- 	print uniques
)


struct AABB ( 
	A, B 
)
struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"" types:"(.bmd6model;baseModel)|*.bmd6model*" historyCategory:"doom md6"
-- fname = @"C:\Users\Xavier\Documents\projects\models\doomunpack\gameresources\generated\md6\characters\monsters\baron\base\assets\mesh\baron.bmd6model;baseModel"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FilePath = GetFilenamePath fname

SkelPath = (FilePath+FileName+".bmd6skl;skeleton")
clearlistener()

Global fscale=1
Global BNArr
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

-- skelPath = @"C:\Users\Xavier\Desktop\doomunpack\gameresources\generated\md6\characters\monsters\baron\base\assets\mesh\baron.bmd6skl;skeleton"

gname = skelPath
If (gname!=undefined) and ((DoesFileExist gname)==true) then (
g = fopen gname "rb"   --open file in read only format
FileExtension = getFileNameType  gname
FileName = getFileNameFile gname	

ukw = readbeshort g
ukw2 = readbeshort g
ukw3 = readbelong g
ukw4 = readbeshort g
ukw5 = readbeshort g
ukw6 = readbelong g

stringLenth = for x=1 to 2 collect (readbeshort g)
tableCount = readbeshort g
fseek g 0xe #seek_cur
tableOffset = ReadBElong g
null = readbelong g
fileSize = readbelong g

for x=1 to 2 do (
	_string = ReadFixedString g stringLenth[x]
	AlignOffset g (ftell g) 16
	print _string
)

dataOffset=#()
dataLength=#()
boneNameArr=#()
fseek g tableOffset #seek_set

ukwOffset = 0
boneOffset = 0
boneCount = 0
parentIDOffset = 0


for x=1 to tableCount do (
	null = readbelong g
	dataOffset[x] = ReadBElong g
	null = readbelong g
	dataLength[x] = Readbelong g
	ukw = Readbelong g
	index = readbeshort g
	ukw2 = readbeshort g
	
-- 		print x
-- 		print (bit.intashex(dataOffset[x]))
-- 		print (bit.intashex(dataLength[x]))
-- 		print (bit.intashex(ukw))
-- 			
-- 		format "\n"
)

for x=1 to tableCount do (
	fseek g dataOffset[x] #seek_set
	
	if x==1 do (
		addto = ftell g
		
		bufferLength = readbeshort g
		boneCount = readbeshort g
		ukw = readbelong g
		dataOffset2 = for x=1 to 19 collect ((readbeshort g) + addto)
-- 		for a in dataOffset do print (bit.intashex(a))
		
-- 		
		ukwOffset = dataOffset2[1]
		boneOffset = dataOffset2[2]
		parentIDOffset = dataOffset2[3]
		
	)
	if x==2 do (
		stringCount = readbelong g
		stringBufferLength = readbelong g
-- 			Print ("stringCount is "+((bit.intAsHex(stringCount))as string))
		Print ("boneCount is "+((stringCount)as string))
			
		for y=1 to stringCount do (
			boneName = readstring g
-- 				print boneName
			
			append boneNameArr boneName
		)
	)
)

fseek g parentIDOffset #seek_set
parentID = for y=1 to boneCount collect ((readbeshort g) + 1)

fseek g boneOffset #seek_set

BNArr = #()
for x=1 to boneCount do (
	
	m11 = readbefloat g; m12 = readbefloat g; m13 = readbefloat g; m14 = readbefloat g
	m21 = readbefloat g; m22 = readbefloat g; m23 = readbefloat g; m24 = readbefloat g
	m31 = readbefloat g; m32 = readbefloat g; m33 = readbefloat g; m34 = readbefloat g
	tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] ([m14,m24,m34]*fscale)
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = inverse tfm
	newBone.name = boneNameArr[x]
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if (ParentID[x] != 0) then (
	newBone.parent = BNArr[ParentID[x]]
	)
	append BNArr newBone
)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell g))as string))
)
gc()
fclose g

ukw = readbeshort f
ukw2 = readbeshort f
ukw3 = readbelong f	-- always the same
ukw4 = readbeshort f
ukw5 = readbeshort f	-- always 0x25
ukw6 = readbelong f
stringLenth = for x=1 to 2 collect (readbeshort f)
tableCount = readbeshort f

fseek f 0xe #seek_cur
tableOffset = ReadBElong f
null = readbelong f
fileSize = readbelong f

for x=1 to 2 do (
	_string = ReadFixedString f stringLenth[x]
	AlignOffset f (ftell f) 16
	print _string
)

dataOffset=#()
dataLength=#()
fseek f tableOffset #seek_set

for x=1 to tableCount do (
	null = readbelong f
	dataOffset[x] = ReadBElong f
	null = readbelong f
	dataLength[x] = Readbelong f
	ukw = Readbelong f
	index = readbeshort f
	null = readbeshort f
	
-- 	print x
--  	print (bit.intashex(dataOffset[x]))
--  	print (bit.intashex(dataLength[x]))
-- 	print (bit.intashex(ukw))
-- 		
--  	format "\n"
)

meshCount = 0
ukwCount = 0
vertOffset = 0
faceOffset = 0
vertCount=#()
faceCount=#()
meshName=#()
boneIDArr=#()
boneIDArr2=#()

for x=1 to tableCount do (
	fseek f dataOffset[x] #seek_set
	
	if x==1 do (	--bb info?
		
	)
	
	if x==2 do (
		skelPath = readstring f
-- 		print skelPath
	)
	
	if x==4 do (
		stringCount = readlong f
		stringBufferLength = readlong f
		ukwCount = stringCount
		
		for y=1 to stringCount do (
			texPath = readstring f
-- 			print texPath
		)
	)
	
	if x==5 do (	-- always just an 8
		
	)
	
	if x==6 do (	-- bone index info?

		boneIDArr = for y=1 to dataLength[x] collect (readbyte f #unsigned + 1)
		j=0
		for a in boneIDArr do (
			boneIDArr2[a] = j
			j+=1
		)
		print boneIDArr	#nomap
		print boneIDArr2 #nomap
	)
	
	if x==7 do (
		for y=1 to ukwCount do (
			ukw = readshort f
			ukw2 = readshort f
			ukw3 = readlong f	-- matID ?
			ukw4 = readshort f
			ukw5 = readshort f
			tableIndex = readlong f
			null = readlong f
			ukwCount = readlong f	-- looks like vertCount
		)
	)
	
	if x==8 do (
		stringCount = readlong f
		stringBufferLength = readlong f
		meshCount = stringCount
		
		for y=1 to stringCount do (
			meshName[y] = readstring f
		)
	)
	
	if x==9 do (
		stringCount = readlong f
		stringBufferLength = readlong f
		for y=1 to stringCount do (	-- same as 4
			texPath2=readstring f
-- 			print texPath2
		)
	)
	
	if x== 10 do (
		for y=1 to meshCount do (
			currBBMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			currBBMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			currA = currBBMax - currBBMin
			
			bb = box()
			bb.width = abs(currA[1])
			bb.length = abs(currA[2])
			bb.height = abs(currA[3])
-- 			hide bb
			
			ukw = readlong f	-- maybe vertSize
-- 			print ukw
			vertCount[y] = readlong f
			faceCount[y] = readlong f
			null = readlong f
			ukw2 = readlong f
			ukw3 = readlong f
			ukw4 = readshort f
			ukw5 = readshort f
		)
	)
	
	if x== 13 do (
		vertOffset = ftell f
	)
	
	if x== 14 do (
		faceOffset = ftell f
	)
)

Print ("meshCount is "+(meshCount) as string)
for x=1 to meshCount do (
	Face_array=#()
	Vert_array=#()
	Normal_array=#()
	UV_array=#()
	Weight_array=#()
	
	fseek f vertOffset #seek_set
-- 	Print ("vertOffset @ 0x"+((bit.intAsHex(ftell f))as string))
	for y=1 to vertCount[x] do (
		w = (weight_data boneids:#() weights:#())
		
		vx = Readfloat f 
		vy = Readfloat f
		vz = Readfloat f
		tu = Readfloat f
		tv = Readfloat f
		fseek f 0x8 #seek_cur
		weight1=0.25 as float
		weight2=0.25 as float
		weight3=0.25 as float
		weight4=0.25 as float
		bone1=readbyte f+1
		bone3=readbyte f+1
		bone2=readbyte f+1
		bone4=readbyte f+1
		fseek f 0x10 #seek_cur
		
		
		maxweight = 0
		if(bone1 != 0x00) then
			maxweight = maxweight + weight1
		if(bone2 != 0x00) then
			maxweight = maxweight + weight2
		if(bone3 != 0x00) then
			maxweight = maxweight + weight3
		if(bone4 != 0x00) then
			maxweight = maxweight + weight4
			
		if(maxweight != 0) then (
			mxw = 255.0
			if(bone1 != 0x00) then (
				w1 = weight1 as float
				append w.boneids (boneIDArr2[bone1]+1)
				append w.weights (w1 / mxw)
			)
			if(bone2 != 0x00) then (
				w2 = weight2 as float
				append w.boneids (boneIDArr2[bone2]+1)
				append w.weights (w2 / mxw)
			)
			if(bone3 != 0x00) then (
				w3 = weight3 as float
				append w.boneids (boneIDArr2[bone3]+1)
				append w.weights (w3 / mxw)
			)
			if(bone4 != 0x00) then (
				w4 = weight4 as float
				append w.boneids (boneIDArr2[bone4]+1)
				append w.weights (w4 / mxw)
			)		
		)
		
		append Vert_array([vx,vy,vz]*fscale)
		append UV_array[tu,1-tv,0]
		append Weight_array w
	)
	vertOffset = ftell f
	
	fseek f faceOffset #seek_set
	for x=1 to faceCount[x] do(
		fa=Readword f +1
		fb=Readword f +1
		fc=Readword f +1
		append Face_array[fa,fc,fb]
	)
	faceOffset = ftell f
	
	msh = mesh vertices:Vert_array faces:Face_array 
	msh.numTVerts = UV_array.count
	msh.name = meshName[x]
	msh.wirecolor = random black white
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]

	-- Applying Skinning --
	max modify mode
	select msh
	skinMod = skin ()
	addModifier msh skinMod
	for i = 1 to BNArr.count do (
		
		maxbone = getnodebyname BNArr[i].name
		if i != BNArr.count then
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
	
	
	wound = findstring meshName[x] "wound"
	gore = findstring meshName[x] "gore"
	if wound != undefined or gore != undefined do (
		hide msh
	)
	
	boxNum = paddstring 3 (x as string)
	boxName = "Box"+boxNum
	boundBox = getnodebyname boxName
	boundBox.center = msh.center
	boundBox.xray = true
	hide boundBox

)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

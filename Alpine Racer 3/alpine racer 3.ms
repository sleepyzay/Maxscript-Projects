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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)  
struct weight_data (
	boneids,weights
)
fname = GetOpenFileName caption:"" types:" (*.)|*.yob*" historyCategory:""
-- fname=@"C:\Users\Xavier\Desktop\berM\PAC\MODEL\00000000.yob"
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
tableOffset = readlong f + 8
boneOffset = readlong f + 8
texOffset = readlong f + 8

matOffset = readlong f + 8
matCount = readlong f

format "meshCount: % boneCount: % texCount: % matCount: %\n" meshCount boneCount texCount matCount 

matName=#()
fseek f matOffset #seek_set
for x=1 to matCount do (
	matName[x] = readfixedstring f 0x10
	ukw = readlonglong f
	ukw2 = readlonglong f
)

fseek f texOffset #seek_set
for x=1 to texCount do (
	base = ftell f
	texName = readstring f
	texExtension = readstring f
	
	fseek f (base + 0x10) #seek_set
)


fseek f boneOffset #seek_set
BNArr=#()
for x=1 to boneCount do (	--stolen from another script
	bRef = ftell f + 0x10
	boneName = readstring f
	fseek f (bRef - (ftell f)) #seek_cur
	
	tx = readfloat f
	ty = readfloat f
	tz = readfloat f
	tw = readfloat f
	rx = (readfloat f * 180) / pi
	ry = (readfloat f * 180) / pi
	rz = (readfloat f * 180) / pi
	rw = readfloat f
	parentID = readlong f #unsigned + 1
	fseek f 0x0c #seek_cur
	qx = readfloat f
	qy = readfloat f
	qz = readfloat f
	qw = readfloat f
	tfm = (eulerangles rx ry rz) as matrix3	
	tfm.row4 = ([tx,ty,tz]*fscale)
	
	if (parentID != 0) do (
		tfm *= BNArr[parentID].objecttransform
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
	newBone.name = boneName

	if (parentID != 0) then(
		newBone.parent = BNArr[parentID]
	)

	append BNArr newBone
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0])

Msh_Vert_array=#()
Msh_Face_array=#()
Msh_UV_array=#()
Msh_Normal_array=#()
Msh_matID_array=#()
Msh_Weight_Array=#()
Msh_VertSum = 0

mat = MultiMaterial numsubs:matCount showInViewport:true
meditMaterials[1] = mat
fseek f tableOffset #seek_set
for x=1 to meshCount do (
	Face_array=#()
	Vert_array=#()
	UV_array=#()
	Normal_array=#()
	matID_array=#()
	Weight_array=#()
	
	vertInfoCount = readlong f
	polyInfoCount = readlong f
	vertInfoOffset = readlong f + 8
	polyInfoOffset = readlong f + 8
	matID = readlong f + 1
	ukwOffsetCount = readlong f	--always 0x0e
	ukwOffsetTable = readlong f + 8	--vert related
	ukwOffset = readlong f + 8	--face related
	ukw4 = readlong f	-- = ((vertSum*2)+2)
	ukw5 = readlong f	--count?
	vertSum = readlong f
	null = readlong f
	fseek f 0x10 #seek_cur	--bound shere?
	backJump = ftell f
	
	fseek f polyInfoOffset #seek_set
	for y=1 to polyInfoCount do (
		fseek f 0x24 #seek_cur		--mat or matrix info
		ukw = readlong f
		ukw2 = readlong f
		fseek f 0x94 #seek_cur	-- null
		ukw3 = readshort f	--always 1
		ukw4 = readshort f	--count?
		faceInfoCount = readlong f
		faceInfoOffset = readlong f + 8
		offset2 = readlong f + 8
		
		backJump2 = ftell f
		fseek f faceInfoOffset #seek_set
		for z=1 to faceInfoCount do (
			ukw = readlong f	--always 3
			uw2 = readlong f	-- always the same as previous
			faceCount = readlong f
			faceOffset = readlong f + 8
			backJump3 = ftell f
			
			fseek f faceOffset #seek_set
-- 			format "faceOffset: 0x% faceCount: 0x%\n" (bit.intashex(faceOffset)) (bit.intashex(faceCount))
				
			f1 = 0
			f2 = 0
			FaceDirection = 1
			for x=1 to faceCount do (
				fseek f 0x0c #seek_cur	--uv's
				f3 = readlong f #unsigned + 1
				fseek f 0x10 #seek_cur
				
				FaceDirection *= -1
				if (f1 != 0) and (f2 != 0) do (
					if FaceDirection > 0 then (
						append Face_array [f1,f3,f2]
						append Msh_Face_array ([f1,f3,f2] + Msh_VertSum)
					)
					else (
						append Face_array [f1,f2,f3]
						append Msh_Face_array ([f1,f2,f3] + Msh_VertSum)
					)
					append Msh_matID_array matID
				)
				f1 = f2
				f2 = f3
			)
			fseek f backJump3 #seek_set
		)
		fseek f backJump2 #seek_set
	)
	
	fseek f vertInfoOffset #seek_set
	for y=1 to vertInfoCount do (
		ReadFixedByteString f 0x20 1 1
		
		vertCount = readlong f
		bindCount = readlong f
		vertOffset = readlong f + 8
		normalsOffset = readlong f + 8
		bindIDArr = for z=1 to 4 collect (readlong f)
		backJump2 = ftell f
		
-- 		format "vertOffset: 0x% vertCount: 0x%\n" (bit.intashex(vertOffset)) (bit.intashex(vertCount))
		
-- 		print bindCount
-- 		print bindIDArr #nomap
		
		fseek f vertOffset #seek_set
		for z=1 to vertCount do (
			w = (weight_data boneids:#() weights:#())
			
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			p = readfloat f
			
			bone4 = bindIDArr[1]
			bone3 = bindIDArr[2]
			bone2 = bindIDArr[3]
			bone1 = bindIDArr[4]
			
			boneMean = 1.0 / bindCount
			
			weight1 = boneMean
			weight2 = boneMean
			weight3 = boneMean
			weight4 = boneMean
			
			
			maxweight = 0
			if(bone1 != -1) then
				maxweight = maxweight + weight1
			if(bone2 != -1) then
				maxweight = maxweight + weight2
			if(bone3 != -1) then
				maxweight = maxweight + weight3
			if(bone4 != -1) then
				maxweight = maxweight + weight4
			if(maxweight != 0) then (
				mxw = 255.0
				if(bone1 != -1) then (
					w1 = weight1 as float
					append w.boneids (bone1+1)
					append w.weights (w1 / mxw)
				)
				if(bone2 != -1) then (
					w2 = weight2 as float
					append w.boneids (bone2+1)
					append w.weights (w2 / mxw)
				)
				if(bone3 != -1) then (
					w3 = weight3 as float
					append w.boneids (bone3+1)
					append w.weights (w3 / mxw)
				)
				if(bone4 != -1) then (
					w4 = weight4 as float
					append w.boneids (bone4+1)
					append w.weights (w4 / mxw)
				)		
			)
			
			append Vert_array ([vx,vy,vz]*fscale)
			append Msh_Vert_array ([vx,vy,vz]*fscale)
			append UV_array[0,0,0]
			append Msh_UV_array[0,0,0]
			append Weight_array w
			append Msh_Weight_Array w
		)
		
		fseek f normalsOffset #seek_set
		for z=1 to vertCount do (
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			p = readfloat f
			
			append Normal_Array[nx,ny,nz]
			append Msh_Normal_array [nx,ny,nz]
		)
		
		fseek f backJump2 #seek_set
	)
	
	fseek f ukwOffsetTable #seek_set
	ukwOffsetArr = for y=1 to ukwOffsetCount collect (readlong f + 8)
	for a in ukwOffsetArr do printHex a 
	format "\n"
	
	Msh_VertSum += vertSum
	
-- 	if matID > mat.numsubs do mat.numsubs = matID
	mat.materialList[matID].Name = matName[matID]
	mat.materialList[matID].Diffuse = random black white
	
-- 	msh = mesh vertices:Vert_array faces:Face_array
-- 	msh.numTVerts = UV_array.count
-- 	msh.wirecolor = random black white
-- 	buildTVFaces msh
-- 	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
-- 	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
-- 	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
-- 	msh.transform=(matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0])
	
	fseek f backJump #seek_set
)

msh = mesh vertices:Msh_Vert_array faces:Msh_Face_array  materialIDs:Msh_MatID_array
msh.numTVerts = Msh_UV_array.count
msh.material = mat
buildTVFaces msh
for j = 1 to Msh_UV_array.count do setTVert msh j Msh_UV_array[j]
for j = 1 to Msh_Face_array.count do setTVFace msh j Msh_Face_array[j]
msh.transform=(matrix3 [1,0,0] [0,0,-1] [0,1,0] [0,0,0])

/*
-- Applying Skinning --
count = msh.numverts
max modify mode
select msh
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BNArr.Count do (
   maxbone = getnodebyname BNArr[i].name
   skinOps.addBone skinMod maxbone 1
)
-- Applying Weights --
select msh
modPanel.setCurrentObject skinMod
for i = 1 to Msh_Weight_Array.count do (
	w = Msh_Weight_Array[i]
	bi = #() --bone index array
	wv = #() --weight value array
	
	for j = 1 to w.boneids.count do
	(
		boneid = w.boneids[j]
		weight = w.weights[j]
		append bi boneid
		append wv weight
	)	
	
	skinOps.ReplaceVertexWeights skinMod i bi wv
)
*/



-- msh.xray = on

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
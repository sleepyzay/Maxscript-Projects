-- SleepyZay --

struct weight_data (
	boneids,weights
)

fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
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
fn Readword fstream = (
return readshort fstream #unsigned
)

fname = GetOpenFileName caption:"Saint Seiya Model" types:"ASKI (.ski)|*.ski"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format

FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
fscale=50
skelPresent = false
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

gname = GetOpenFileName caption:"Saint Seiya Skeleton" types:"ASKE (.bon)|*.bon"
If (gname!=undefined) and ((DoesFileExist gname)==true) then (
g = fopen gname "rb"
skelPresent = true
--)

MOXBKCTS = ReadFixedString g 8
ukw = readlong g
ukw2 = readlong g
boneCount = readlong g
ukw = readlong g
fseek g 0x8 #seek_cur
ukw2 = readlong g

fseek g 0x40 #seek_cur

BNArr=#()
for x=1 to boneCount do (
	boneNameLength = readlong g
	boneName = ReadFixedString g boneNameLength
	boneID = readlong g
	parentID = readlong g
	siblingID = readlong g
	ukwCount = readlong g

	m11 = readfloat g; m12 = readfloat g; m13 = readfloat g; m14 = readfloat g
	m21 = readfloat g; m22 = readfloat g; m23 = readfloat g; m24 = readfloat g
	m31 = readfloat g; m32 = readfloat g; m33 = readfloat g; m34 = readfloat g
	m41 = readfloat g; m42 = readfloat g; m43 = readfloat g; m44 = readfloat g
	tfm2 = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	
	m11 = readfloat g; m12 = readfloat g; m13 = readfloat g; m14 = readfloat g
	m21 = readfloat g; m22 = readfloat g; m23 = readfloat g; m24 = readfloat g
	m31 = readfloat g; m32 = readfloat g; m33 = readfloat g; m34 = readfloat g
	m41 = readfloat g; m42 = readfloat g; m43 = readfloat g; m44 = readfloat g
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] ([m41,m42,m43]*fscale)
	
	for y =1 to ukwCount do (
		fseek g 0x4 #seek_cur
	)
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.transform =  inverse tfm
	newBone.wirecolor = yellow
	newbone.showlinks = false
	newBone.name = boneName
	
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if (parentID != -1) then
	newBone.parent = BNArr[(parentID)+1]						  
	append BNArr newBone		
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])

Print ("Last Read g @ 0x"+((bit.intAsHex(ftell g))as string))
)

-- Meshes --
MOXBIKSA = ReadFixedString f 8
ukw2 = readlong f
meshCount = readlong f
fseek f 0xc #seek_cur	--null

textureCount = readlong f
materialCount = readlong f
mesh_boneCount = readlong f
null = readlong f
ukw4 = readlong f	--count, bone related
fseek f 0x3c #seek_cur

boneName_Arr = for x=1 to mesh_boneCount collect (ReadFixedString f (readlong f))
texName_Arr = for x=1 to textureCount collect (ReadFixedString f (readlong f))
for x=1 to materialCount do fseek f 0x50 #seek_cur

for x=1 to meshCount do (	--meshCount
	nameLength = readlong f
	meshName = ReadFixedString f nameLength

	matID = readlong f
	ukw2 = readlong f
	vertCount = readlong f
	faceCount = readlong f
	
	Vert_array=#()
	Face_array=#()
	UV_array=#()
	Normal_array=#()
	Weight_array=#()

	for x=1 to vertCount do (
		w = (weight_data boneids:#() weights:#())
		vx = readfloat f
		vy = readfloat f
		vz = readfloat f
		weight1 = readfloat f
		weight2 = readfloat f
		weight3 = readfloat f
		weight4 = 0
		bone1 = readbyte f#unsigned
		bone2 = readbyte f#unsigned
		bone3 = readbyte f#unsigned
		bone4 = readbyte f#unsigned
		nx = readfloat f
		ny = readfloat f
		nz = readfloat f
		tu = readfloat f
		tv = readfloat f*-1
		
		maxweight = 0
		if(weight1 != 0) then
		   maxweight = maxweight + weight1
		if(weight2 != 0) then
		   maxweight = maxweight + weight2
		if(weight3 != 0) then
		   maxweight = maxweight + weight3
		if(weight4 != 0) then
		   maxweight = maxweight + weight4
			
		if(maxweight != 0) then (
			  if(weight1 != 0) then (
				 w1 = weight1 as float
				 append w.boneids (bone1 + 1)
				 append w.weights (w1)
			  )
			  if(weight2 != 0) then (
				 w2 = weight2 as float
				 append w.boneids (bone2 + 1)
				 append w.weights (w2)
			  )
			  if(weight3 != 0) then (
				 w3 = weight3 as float
				 append w.boneids (bone3 + 1)
				 append w.weights (w3)
			  )
			  if(weight4 != 0) then (
				 w4 = weight4 as float
				 append w.boneids (bone4 + 1)
				append w.weights (w4)
			  )      
		   )
			
		append Vert_array([vx,vy,vz]*fscale)
		append UV_array[tu,tv,0]
		append Normal_array[nx,ny,nz]
		append Weight_array w
	)

	for x=1 to faceCount/3 do(
		fa=ReadShort f +1
		fb=ReadShort f +1
		fc=ReadShort f +1
		append Face_array[fa,fb,fc]
	)

	for x=1 to vertCount do (	--tangents
		tx = readfloat f
		ty = readfloat f
		tz = readfloat f
		tw = readfloat f
	)

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = UV_array.count
	msh.name = meshName
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
	if skelPresent do (
		-- Applying Skinning --
		count = msh.numverts
		max modify mode
		select msh
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to mesh_boneCount do (
		maxbone = getnodebyname boneName_Arr[i] 
		if i != mesh_boneCount then 
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
	)
		
		-- Applying Weights --
		select msh
		modPanel.setCurrentObject skinMod
		for i = 1 to weight_array.count do (
			w = Weight_array[i]
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
	)
)
	

Print ("Last Read f @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

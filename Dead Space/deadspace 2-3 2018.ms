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
fn ReadFixedByteString bstream fixedLen ret p = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   if ret == 1 do fseek bstream -fixedLen #seek_cur
   if p == 1 do print str
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
fn SplitLayout Split =(
	str=""
	j=0
	for i in Split do (
		j+=1
		if j >1 do (
			str += i
			if j != Split.count do str += "_" 
		)
	)
	str
)
fn findBones = (
	bonesPresent = false
	for o in geometry where classOf o == boneGeometry do bonesPresent = true
	
	bonesPresent
)

struct weight_data (
	boneids,weights
)

struct _polyInfo (
	vertCount,
	vertOffset,
	vertType,
	uvSize,
	faceCount,
	faceOffset,
	faceType,
	matID,
	polyID,
	polyName
)


fname = GetOpenFileName caption:"Dead Space 2-3 Geometry" types:" (*.geo)|*.geo" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FilePath = GetFilenamePath fname
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileSize = getFileSize fname
Leaf = pathConfig.removePathLeaf fname
ParentFolder = pathConfig.removePathLeaf Leaf

UVFolder = ParentFolder + "\MeshVolatile\\"
Split = filterString FileName "_"
UVID= ((Split[1] as number)+1)
Rest = SplitLayout (Split)
gname = (UVFolder + (paddstring 4 (UVID as string)) + "_" + Rest + ".geo")

clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

Magic = readfixedstring f 4
ukw = readlong f	-- always 0x32
ukw2 = readlong f	-- always 0x3
fseek f 0x14 #seek_cur	-- bunch of shit

modelNameOffset = readlong f #unsigned
ukw3 = readlong f
fseek f 0xc #seek_cur	--null

tableCount = readlong f
ukw4 = readlong f	-- always 0x83
fseek f 0xc #seek_cur	-- look at later, may be important

refTableCount=readlong f	--don't know what its's actually called. It's a list of all of the offsets in which you'll reference in the future and the offsets that point to them.
refTableOffset=readlong f

dataTable=readlong f
boundBoxTable=readlong f
fseek f 0x08 #seek_cur	--null

ukwBuffer=readlong f	-- looks like uv's
null = readlong f
vertBufferData=readlong f
faceBufferData=readlong f

fseek f 0x9c #seek_set
localUVOffset = readlong f

extUV = false
if localUVOffset == FileSize then (
	extUV = true
	g = fopen gname "rb"
)
else (
	print "Local Texture Coordinates"
)

meshArr=#()
matCount = 0
fseek f dataTable #seek_set	
For x=1 to tableCount do (
	polyInfo = _polyInfo()
	
	polyInfo.polyName = getName f (readlong f)
	ukw = readbyte f
	ukw2 = readbyte f
	ukw2 = readbyte f
	polyInfo.matID = x
	ukw3 = readbyte f
	ukw4 = readlong f
	ukwArr = for y=1 to 5 collect (readfloat f)
	bbOffset = readlong f
	ukwArr2 = for y=1 to 3 collect (readbyte f)
	polyInfo.uvSize = readbyte f
	ukw5 = readshort f
	ukw6 = readshort f
	null = readlong f	
	polyInfo.faceCount = readlong f 
	ukwOffset=readlong f 		-- face offset?
	polyInfo.vertCount = readshort f 
	ukw7 = readshort f			-- vert offset?
	polyInfo.faceType = readshort f
	--0x3e
	ukw8 = readshort f				-- looks like an offset
	preVertTotal = readshort f		-- if first of index then 0
	vertTotal = readshort f			-- updated per index
	ukwOffset=readlong f 		-- bind list?
	fseek f 0x1c #seek_cur		-- null
	ReadFixedByteString f 0xc 1 0
	polyInfo.vertType = readlong f + 2
	ukw10 = readlong f
	polyInfo.polyID = readlong f + 1
	ukw11 = readlong f
	fseek f 0x10 #seek_cur		--null
	polyInfo.vertOffset = readlong f 
	polyInfo.faceOffset = readlong f 
	fseek f 0x20 #seek_cur		--null
	ukwArr3 = for y=1 to 5 collect readfloat f --mat info?
	
	if polyInfo.matID > matCount do matCount = polyInfo.matID
	if meshArr[polyInfo.polyID] == undefined do meshArr[polyInfo.polyID] = #()
	append meshArr[polyInfo.polyID] polyInfo
	print polyInfo.polyID
)

mat = MultiMaterial numsubs:matCount showInViewport:true
meditMaterials[1] = mat
uvOffset = 0
for x=1 to meshArr.count do (
	if meshArr[x] != undefined do (
		Vert_Array=#()
		Face_Array=#()
		UV_Array=#()
		Normal_Array=#()
		Weight_Array=#()
		Mat_Array=#()
		
		for a in meshArr[x] do (
			mat.materialList[a.matID].Diffuse = random black white
-- 			mat.materialList[a.matID].specularLevel = 40
-- 			mat.materialList[a.matID].glossiness = 30
			mat.materialList[a.matID].name = a.polyName
			biggestBone = 0
			fseek f a.vertOffset #seek_set
			printHere f
			if a.vertType == 1 do (
				for y = 1 to a.vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx=readfloat f
					vy=readfloat f
					vz=readfloat f
					nx=(readbyte f #unsigned /255.0) * 2 - 1
					ny=(readbyte f #unsigned /255.0) * 2 - 1
					nz=(readbyte f #unsigned /255.0) * 2 - 1
					nw=readbyte f #unsigned
					tx=readbyte f #unsigned
					ty=readbyte f #unsigned
					tz=readbyte f #unsigned
					tw=readbyte f #unsigned
					bone1 = readbyte f  #unsigned
					bone2 = readbyte f  #unsigned
					bone3 = readbyte f  #unsigned
					bone4 = readbyte f  #unsigned
					weight1 = readshort f  #unsigned
					weight2 = readshort f #unsigned
					weight3 = readshort f #unsigned
					weight4 = readshort f #unsigned
					
					if bone1 > biggestBone do biggestBone = bone1
					if bone2 > biggestBone do biggestBone = bone2
					if bone3 > biggestBone do biggestBone = bone3
					if bone4 > biggestBone do biggestBone = bone4
					
					
-- 					format "% % % % \n" bone1 bone2 bone3 bone4
-- 					format "% % % % \n\n" weight1 weight2 weight3 weight4
					maxweight = 0
					if(bone1 != 0) then
						maxweight += weight1
					if(bone2 != 0) then
						maxweight += weight2
					if(bone3 != 0) then
						maxweight += weight3
					if(bone4 != 0) then
						maxweight += weight4
						
					if(maxweight != 0) then (
						mxw = 65535.0
						if(weight1 != 0) then (
							w1 = weight1 as float
							append w.boneids (bone1 + 1)
							append w.weights (w1 / mxw)
						)
						if(weight2 != 0) then (
							w2 = weight2 as float
							append w.boneids (bone2 + 1)
							append w.weights (w2 / mxw)
						)
						if(weight3 != 0) then (
							w3 = weight3 as float
							append w.boneids (bone3 + 1)
							append w.weights (w3 / mxw)
						)
						if(weight4 != 0) then (
							w4 = weight4 as float
							append w.boneids (bone4 + 1)
							append w.weights (w4 / mxw)
						)		
					)
					
					append Vert_array([vx,vy,vz]*fscale)
-- 					append UV_array([0,0,0])
					append Normal_array([nx,ny,nz])
					append Weight_array w
				)
			)
			if a.vertType >= 2 do (
				if a.faceType == 4 do (
					for y = 1 to a.vertCount do(
						vx=readfloat f
						vy=readfloat f
						vz=readfloat f
						nx=(readbyte f #unsigned /255.0) * 2 - 1
						ny=(readbyte f #unsigned /255.0) * 2 - 1
						nz=(readbyte f #unsigned /255.0) * 2 - 1
						nw=readbyte f #unsigned
						tx=readbyte f #unsigned
						ty=readbyte f #unsigned
						tz=readbyte f #unsigned
						tw=readbyte f #unsigned
						
						append Vert_array([vx,vy,vz]*fscale)
-- 						append UV_array([0,0,0])
						append Normal_array([nx,ny,nz])
					)
				)
				if a.faceType == 5 do (
					for y = 1 to a.vertCount do(
						vx=readfloat f
						vy=readfloat f
						vz=readfloat f
						
						append Vert_array([vx,vy,vz]*fscale)
						append UV_array([0,0,0])
						append Normal_array([nx,ny,nz])
					)
				)
			)
			
			fseek f a.faceOffset #seek_set
			if a.faceType == 4 do (
				for y = 1 to a.faceCount/3 do (
					fa = ReadShort f #unsigned + 1
					fb = ReadShort f #unsigned + 1
					fc = ReadShort f #unsigned + 1
					
					append Face_Array[fa,fb,fc]
					append Mat_Array a.matID
				)
			)
			
			if extUV == true then (
				fseek g uvOffset #seek_set
				printHex a.vertCount
				for y=1 to a.vertCount do (
					tu = readfloat g
					tv = readfloat g
					
					fseek g (a.uvSize - 8) #seek_cur
					
					append UV_array([tu,1-tv,0])
				)
				
				uvOffset = ftell g
			)
			else (
				fseek f localUVOffset #seek_set
				for y=1 to a.vertCount do (
					tu = readfloat f
					tv = readfloat f
					
					fseek f (a.uvSize - 8) #seek_cur
					
					append UV_array([tu,1-tv,0])
				)
				
				print UV_Array
			)
		)
		
		msh = mesh vertices:Vert_array faces:Face_Array materialIDs:Mat_Array
		msh.numTVerts = UV_array.count
		msh.material = mat
		buildTVFaces msh
		for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
		msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		BNArr = for o in geometry where classOf o == boneGeometry collect o
		
		if findBones() == true do (
			-- Applying Skinning --
			max modify mode
			select msh
			skinMod = skin ()
			addModifier msh skinMod
			for i = 1 to BNArr.count do (
				
				maxbone = BNArr[i]
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
		)
	)
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
fclose g
--sleepyzay--

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
fn reverseString s = (
    local reversed = ""
    for i in s.count to 1 by -1 do reversed += s[i]
	reversed
)
fn printBinary val size = (
	str = ""
	for i=1 to size do (
		if (bit.get val i)  then str += "1"
		else str += "0"
		
		if ((mod i 8) == 0) and (i < size) do str+=" "
	)
	
	str = reverseString str
	print str
)
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
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
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn GetName bstream offset = (
	fseek bstream offset #seek_set
	MeshName = readstring bstream
	return MeshName
)
fn skelPresent = (
	allBones = for o in geometry where classOf o == boneGeometry collect o
	if allBones.count > 0 then (
		return true
	)
	else (
		return false
	)
)
fn assumeskinpose = (
	stopAnimation()
	for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
)

struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"Total War - Warhammer Meshes" types:" (*.rigid_model_v2)|*.rigid_model_v2" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=75
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

if (skelPresent() == false) do (
	gname = GetOpenFileName caption:"Total War - Warhammer Skeleton" types:"(.anim)|*.anim"
	if (gname!=undefined) and ((DoesFileExist gname)==true) then (
		g = fopen gname "rb"   --open file in read only format
		FileExtension = getFileNameType  gname
		FileName = getFileNameFile gname
		Print "===================================="
		print (FileName + FileExtension) as string
		Print "===================================="	
		
		fileVer = readlong g	--always 7
		ukw2 = readlong g	--always 1
		null = readshort g
		ukw3 = readshort g
		nameLength = readshort g
		
		skelName = ReadFixedString g nameLength
		
		if fileVer >= 7 do null = readlong g
		
		ukw4 = readfloat g
		boneCount = readlong g
		
		boneName=#()
		parentID=#()
		for x=1 to boneCount do (
			nameLength = readshort g
			boneName[x] = ReadFixedString g nameLength
			parentID[x] = readlong g + 1
		)
		
		boneMap=#()
		for x=1 to 2 do boneMap[x] = for y=1 to boneCount collect readlong g + 1
		
		if fileVer >= 7 do null = readlonglong g
		
		posCount = readlong g
		rotCount = readlong g
		ukw = readlong g
		
		bonePos=#()
		for x=1 to posCount do (
			px = readfloat g
			py = readfloat g
			pz = readfloat g
			
			bonePos[x] = ([px,py,pz]*fscale)
		)
		
		boneRot=#()
		for x=1 to rotCount do (
			rx = readshort g
			ry = readshort g
			rz = readshort g
			rw = readshort g
			
			boneRot[x] = (quat rx ry rz rw) as matrix3
		)
		
		global BNArr=#()
		for x=1 to boneCount do (
			
			tfm = inverse boneRot[x]
			tfm.row4 = bonePos[x]
			
			if (parentID[x] != 0) then(
				tfm *= BNArr[(parentID[x])].objecttransform	
			)
			
			newBone = bonesys.createbone	\
			tfm.row4	\
			(tfm.row4 + 0.01 * (normalize tfm.row1)) \
			(normalize tfm.row3)
			newBone.width  = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			newBone.setBoneEnable false 0
			newBone.wirecolor = white
		-- 	newbone.name = (boneName[x]+"_"+(paddstring 2 (x as string)))
			newbone.name = boneName[x]
			newbone.showlinks = false
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
			
			if (parentID[x] != 0) then(
				newBone.parent = BNArr[(parentID[x])]
			)
			
			append BNArr newBone
		)
		rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
		for b in BNArr where b.parent==undefined do b.parent = rootRT
		rootRT.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		for b in BNArr do b.setskinpose()
	)
	gc()
	fclose g
)

magic = readlong f
fileVer = readlong f
lodCount = readlong f
skelName = readstring f

vertLength=#()
faceLength=#()
modelOffset=#()
meshCount=#()

if skelName == "" then isProp = true
else isProp = false

format "skelName: % \nlodCount: % \n" skelName lodCount

fseek f 0x8c #seek_set
for x=1 to lodCount do (
	meshCount[x] = readlong f
	vertLength[x] = readlong f
	faceLength[x] = readlong f
	modelOffset[x] = readlong f
	lodMaxDistance = readfloat f
	tableIndex = readlong f
	ukw3 = readshort f
	ukw4 = readshort f
	
-- 	print lodMaxDistance
-- 	printHex modelOffset[x]
)

lodID = 1
format "selected lod: %\n\n" lodID
for x=lodID to lodID do (		--lodCount
	fseek f modelOffset[x] #seek_set
	format "meshCount: % \n" meshCount[x]
	for y=1 to meshCount[x] do (
		Face_array=#()
		Vert_array=#()
		Normal_array=#()
		UV_array=#()
		Weight_array=#()
		Color_array=#()
		
		addTo = ftell f
		ukw = readlong f
		meshLength = readlong f
		vertOffset = readlong f + addTo
		vertCount = readlong f
		faceOffset = readlong f + addTo
		faceCount = readlong f
		bb = getBoundBox f fscale
		default_dry = readstring f
		ukw2 = readshort f
		ukw3 = readlong f
		fseek f 0x0e #seek_cur
		vertType = readshort f
		meshName = getName f (addTo+0x52)
		
-- 		print vertType
		format "vertOffset: 0x% \nfaceOffset: 0x% \n\n" (bit.intashex(vertOffset)) (bit.intashex(faceOffset))
		fseek f (0x318 + addto) #seek_set
		
		usedBoneCount = readlong f
		texCount = readlong f
		
		fseek f (0x3ac + addto) #seek_set
		for z=1 to usedBoneCount do (
			boneName = ReadFixedString f 0x20
			fseek f 0x30 #seek_cur
			ukw = readlong f	-- child id?
		)
		null = readlong f
		
		for z=1 to texCount do (
			texName = ReadFixedString f 0x100
			texType = readlong f
		)
		null = readlong f
		
		fseek f vertOffset #seek_set
		for z=1 to vertCount do (
			w = (weight_data boneids:#() weights:#())
			
			vx = ReadHalfFloat f
			vy = ReadHalfFloat f
			vz = ReadHalfFloat f
			p1 = ReadHalfFloat f
			bone1 = readbyte f #unsigned
			bone2 = readbyte f #unsigned
			bone3 = 0
			bone4 = 0
			if vertType == 4 or vertType == 0 do (
				bone3 = readbyte f #unsigned
				bone4 = readbyte f #unsigned
			)
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = 0
			weight4 = 0
			if vertType == 4 or vertType == 0 do (
				weight3 = readbyte f #unsigned
				weight4 = readbyte f #unsigned
			)
			
-- 			nx = (readbyte f #unsigned - 127.0)/127.0
-- 			ny = (readbyte f #unsigned - 127.0)/127.0
-- 			nz = (readbyte f #unsigned - 127.0)/127.0
			nx = (readbyte f #unsigned / 255.0) * 2 - 1
			ny = (readbyte f #unsigned / 255.0) * 2 - 1
			nz = (readbyte f #unsigned / 255.0) * 2 - 1
			nw = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			ta = readlong f #unsigned
			bn = readlong f #unsigned
			
			if fileVer >= 8 do (
				r = readByte f #unsigned
				g = readByte f #unsigned
				b = readByte f #unsigned
				a = readByte f #unsigned
				
				append Color_array (color r g b a)
			)
			
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
				mxw = 255.0
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
			append Normal_array [nx,ny,nz]
			append UV_array[tu,-tv,0]
			append Weight_array w
		)
		
		fseek f faceOffset #seek_set
		for z=1 to faceCount/3 do(
			fa=ReadShort f #unsigned + 1
			fb=ReadShort f #unsigned + 1
			fc=ReadShort f #unsigned + 1
			append Face_array[fa,fb,fc]
		)
		
		msh = mesh vertices:Vert_array faces:Face_array
		msh.numTVerts = UV_array.count
		msh.name = meshName
		msh.wirecolor = random black white
		
		buildTVFaces msh
-- 		setNumCPVVerts msh vertCount
-- 		if Color_array.count > 0 do (
-- 			defaultVCFaces msh
-- 			setCVertMode msh false
-- 			setShadeCVerts msh false
-- 		)
		
		for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
-- 		for j = 1 to Color_array.count Do setVertColor msh j Color_array[j]
		for j = 1 to Normal_array.count Do setNormal msh j Normal_array[j]
		msh.transform=(matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		if skelPresent() == true do (	
			assumeskinpose()
			
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
		)
		
		fseek f (addTo + meshLength) #seek_set
	)
)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
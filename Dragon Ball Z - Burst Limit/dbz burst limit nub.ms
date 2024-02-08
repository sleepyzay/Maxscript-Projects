--sleepyzay--

global fscale = 5

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
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
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
fn ReadFixedByteString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   print str
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
	
	bb = box()
	bb.width = abs(currA[1])
	bb.length = abs(currA[2])
	bb.height = abs(currA[3])
-- 	hide bb
	delete bb
)
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn getID bstream offset = (
	id = 0
	
	backjump = ftell bstream
	fseek bstream offset #seek_set
	if offset > 0 then (
		id = (readbelong bstream)+1
	)
	fseek bstream backjump #seek_set
	return id
)
fn getOffset bstream offset = (
	backjump = ftell bstream
	fseek bstream offset #seek_set
	fseek bstream 0x8 #seek_cur
	theOffset = readbelong bstream
	null = readbelong bstream
	fseek bstream backjump #seek_set
	return theOffset
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
fn editableMesh obj = (
	classof obj == Editable_Mesh
)
struct weight_data (
	boneids,weights
)

struct animInfo (
	boneID,
	boneName,
	posTime,
	posArr,
	sclTime,
	sclArr,
	rotTime,
	rotArr
)

struct trackInfo (
	numFrames,
	trackOffset,
	boneCount,
	boneName
)

fn readNud f &nudArr= (
	nudOffset = ftell f
	
	magic = ReadFixedString f 4
	modelLength = readbelong f
	ukw = readbeshort f
	meshCount = readbeshort f
	ukw2 = readbeshort f
	usedBoneCount = readbeshort f
	extUV = true
	dataLength = ReadBElong f
	faceLength = ReadBElong f
	backJump = ftell f
	uvLength = ReadBElong f 
	vertLength = ReadBElong f 
	if (vertLength == 0 ) do (
		extUV = false
		fseek f backJump #seek_set
		vertLength = ReadBElong f 
		uvLength = ReadBElong f
	)

	dataStart = 0x30 + nudOffset
	faceStart = dataStart + dataLength
	uvStart = faceStart + faceLength
	vertStart = uvStart + uvLength
	nameStart = vertStart + vertLength

	meshName=#()
	polyElmCount=#()
	tableOffset=#()

	ukwQuat = for x=1 to 4 collect readbefloat f
	for x=1 to meshCount Do (
		ukwQuat = for y=1 to 4 collect readbefloat f
		ukwQuat2 = for y=1 to 4 collect readbefloat f
		meshName[x] = GetName f (readbelong f + nameStart)
		null = readbeshort f
		ukw=readbeshort f
		bindID=readbeshort f
		polyElmCount[x] = readbeshort f
		tableOffset[x] = readbelong f + nudOffset
		
		append nudArr meshName[x]
-- 		print meshName[x]
	)
	
	vertSum=0
	matIDChannel=#(#(),#())
	for x=1 to meshCount do (
		uvSize=#()
		uvOffset=#()
		vertOffset=#()
		vertCount=#()
		vertSize=#()
		faceCount=#()
		faceOffset=#()
		faceType=#()
		matID=#()
		matID2=#()
		
		fseek f tableOffset[x] #seek_set
		for y=1 to polyElmCount[x] do (
			faceOffset[y] = readbelong f + faceStart
			if extUV == true do (
				uvOffset[y] = readbelong f + uvStart
				vertOffset[y] = readbelong f + vertStart
			)
			if extUV == false do (
				vertOffset[y] = readbelong f + vertStart
				uvOffset[y] = readbelong f + uvStart
			)
			vertCount[y] = readbeshort f
			vertSize[y] = readbyte f
			uvSize[y] = readbyte f
			matDataOffset = for z=1 to 4 collect (readbelong f + nudOffset)	--prob mat info
			faceCount[y] = readbeshort f
			faceType[y] = readbeshort f
			fseek f 0xc #seek_cur	--null
			backjump = ftell f
			
			fseek f matDataOffset[1] #seek_set
			fseek f 0x23 #seek_cur
			mat1 = readbyte f
			fseek f 0x17 #seek_cur
			mat2 = readbyte f
			
			appendifunique matIDChannel[1] (mat1)
			appendifunique matIDChannel[2] (mat2)
			
			matID[y] = findItem matIDChannel[1] mat1
			matID2[y] = findItem matIDChannel[2] mat2
			
			fseek f backjump #seek_set
		)
		
		Vert_array=#()
		UV_array=#()
		Normal_array=#()
		Weight_array=#()
		Face_array=#()
		MatID_Array=#()
		MatID2_Array=#()
		vertSum2 = 0
		
		singleBind = false
		for y=1 to polyElmCount[x] do (
-- 			format "% %\n" (bit.intashex(vertSize[y])) (bit.intashex(uvSize[y]))
			fseek f vertOffset[y] #seek_set
			if (vertSize[y] == 0x06) do (
				singleBind = true
				
				for z=1 to vertCount[y] do (
					w = (weight_data boneids:#() weights:#())
					
					vx=ReadBEfloat f
					vy=ReadBEfloat f
					vz=ReadBEfloat f
					nx=ReadBEHalfFloat f	
					ny=ReadBEHalfFloat f	
					nz=ReadBEHalfFloat f
					bone1 = readshort f #unsigned + 1		--can't find where this references
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
					weight3 = readbyte f #unsigned
					weight4 = readbyte f #unsigned
					tu=ReadBEHalfFloat f
					tv=ReadBEHalfFloat f
					
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
							append w.boneids (bone1)
							append w.weights (w1 / mxw)
						)
						if(weight2 != 0) then (
							w2 = weight2 as float
							append w.boneids (bone2)
							append w.weights (w2 / mxw)
						)
						if(weight3 != 0) then (
							w3 = weight3 as float
							append w.boneids (bone3)
							append w.weights (w3 / mxw)
						)
						if(weight4 != 0) then (
							w4 = weight4 as float
							append w.boneids (bone4)
							append w.weights (w4 / mxw)
						)		
					)
					
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0]*2)
					append Normal_array[nx,ny,nz]
					append Weight_array w
				)
			)
			if (vertSize[y] == 0x10) do (
				for z=1 to vertCount[y] do (
					vx=ReadBEfloat f
					vy=ReadBEfloat f
					vz=ReadBEfloat f
					vw=ReadBEfloat f
					bone1 = readbelong f + 1
					bone2 = readbelong f + 1
					bone3 = readbelong f + 1
					bone4 = readbelong f + 1
					weight1 = readbefloat f
					weight2 = readbefloat f
					weight3 = readbefloat f
					weight4 = readbefloat f
					
					append Vert_array([vx,vy,vz]*fscale)
				)
			)
			if (vertSize[y] == 0x11) do (
				for z=1 to vertCount[y] do (
					w = (weight_data boneids:#() weights:#())
					
					vx=ReadBEfloat f
					vy=ReadBEfloat f
					vz=ReadBEfloat f
					p1=ReadBEfloat f
					nx=ReadBEfloat f	
					ny=ReadBEfloat f	
					nz=ReadBEfloat f	
					p2=ReadBEfloat f	
					bone1 = ReadBElong f + 1
					bone2 = ReadBElong f + 1
					bone3 = ReadBElong f + 1
					bone4 = ReadBElong f + 1
					weight1=ReadBEfloat f
					weight2=ReadBEfloat f
					weight3=ReadBEfloat f
					weight4=ReadBEfloat f
					
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
							append w.boneids (bone1)
							append w.weights (w1 / mxw)
						)
						if(weight2 != 0) then (
							w2 = weight2 as float
							append w.boneids (bone2)
							append w.weights (w2 / mxw)
						)
						if(weight3 != 0) then (
							w3 = weight3 as float
							append w.boneids (bone3)
							append w.weights (w3 / mxw)
						)
						if(weight4 != 0) then (
							w4 = weight4 as float
							append w.boneids (bone4)
							append w.weights (w4 / mxw)
						)		
					)
					
					append Vert_array([vx,vy,vz]*fscale)
					append Normal_array([nx,ny,nz])
					append Weight_array w
				)
			)
			if (vertSize[y] == 0x13) do (
				for z=1 to vertCount[y] do (
					vx=ReadBEfloat f
					vy=ReadBEfloat f
					vz=ReadBEfloat f
					vw=ReadBEfloat f
					nx=ReadBEfloat f	
					ny=ReadBEfloat f	
					nz=ReadBEfloat f
					nw = ReadBEfloat f
					bnx=ReadBEfloat f	
					bny=ReadBEfloat f	
					bnz=ReadBEfloat f
					bnw = ReadBEfloat f
					tx=ReadBEfloat f	
					ty=ReadBEfloat f	
					tz=ReadBEfloat f
					tw = ReadBEfloat f
					bone1 = readbelong f + 1
					bone2 = readbelong f + 1
					bone3 = readbelong f + 1
					bone4 = readbelong f + 1
					weight1 = readbefloat f
					weight2 = readbefloat f
					weight3 = readbefloat f
					weight4 = readbefloat f
					
					append Vert_array([vx,vy,vz]*fscale)
					append Normal_array([nx,ny,nz]*fscale)
				)
			)
			
			if extUV == true do (
				fseek f uvOffset[y] #seek_set
				if uvSize[y] == 0x10 do (
					for z=1 to vertCount[y] do (
						tu=ReadBEHalfFloat f
						tv=ReadBEHalfFloat f
						
						append UV_array([tu,1-tv,0]*2)
					)
				)
				if uvSize[y] == 0x12 do (
					for z=1 to vertCount[y] do (
						fseek f 0x4 #seek_cur	--0xffffffff
						tu=ReadBEHalfFloat f
						tv=ReadBEHalfFloat f
						
						append UV_array([tu,1-tv,0]*2)
					)
				)
			)
			
			fseek f faceOffset[y] #seek_set
			face_flip = true
			face_reset=true
			z=1
			while z < faceCount[y] Do (
				z+=1
				If face_reset == true then (
					z+=2
					face_reset=false
					face_flip = true
					fa = (ReadBEword f ) + 1
					fb = (ReadBEword f ) + 1
					fc = (ReadBEword f ) + 1
					If face_flip == true then (
						append Face_array ([fa,fb,fc] + vertSum2)
						append MatID_Array matID[y]
						append MatID2_Array matID2[y]
						face_flip=false
					)
					else(
						append Face_array ([fa,fc,fb] + vertSum2)
						append MatID_Array matID[y]
						append MatID2_Array matID2[y]
						face_flip=true
					)
				)
				else(
					fa = fb
					fb = fc
					fc = ReadBEword f
					If fc!=0xFFFF then (
						fc += 1
						If face_flip == true then (
							append Face_array ([fa,fb,fc] + vertSum2)
							append MatID_Array matID[y]
							append MatID2_Array matID2[y]
							face_flip=false
						)
						else(
							append Face_array ([fa,fc,fb] + vertSum2)
							append MatID_Array matID[y]
							append MatID2_Array matID2[y]
							face_flip=true
						)
					)
					else(
						face_reset=true
					)
				)
			)
			vertSum2 += vertCount[y]
		)
		
		mat = MultiMaterial numsubs:matIDChannel[2].count showInViewport:true
		mat.name = meshName[x]
		for x=1 to mat.count do (
			mat.materialList[x].Diffuse = random black white
			
	-- 		mat[x] = DxMaterial()
	-- 		mat.materialList[x].k_d = random black white
		)
-- 		meditMaterials = mat
		
		msh = mesh vertices:Vert_array faces:Face_array materialIDs:MatID2_Array
		msh.numTVerts = UV_array.count
		msh.name = meshName[x]
		msh.material = mat
		buildTVFaces msh
		for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
		for j = 1 to Normal_array.count Do setNormal msh j Normal_array[j]
		msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		if (skelPresent()) do (
			BNArr = for o in geometry where classOf o == boneGeometry collect o
			max modify mode
			
			if (singleBind == false) then (
				
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
				deselect msh
			)
			else (	--doing it manually because fuck it
				mbt = #(	--mesh bone transform
					#("FACE", "SWORD", "SHEATH", "RFOREARM"),	--meshSubsName
					#("HEAD", "SWORD", "SHEATH", "RROCKET")		--boneSubName
				)
				for m=1 to mbt[1].count do (
					meshSubsName = mbt[1][m]
					boneSubName = mbt[2][m]
					
					if (matchPattern msh.name pattern:("*"+meshSubsName+"*")) do (
						for o in geometry where (classof o == bonegeometry) and (matchPattern o.name pattern:("*"+boneSubName+"*")) do (
							msh.transform = o.objecttransform
							
							select msh
							skinMod = skin ()
							skinMod.rigid_vertices = true
							addModifier msh skinMod
							maxbone = getnodebyname o.name
							skinOps.addBone skinMod maxbone 1
							for i = 1 to (meshop.getNumVerts msh) do (
								skinOps.ReplaceVertexWeights skinMod i 1 1.0
							)
							deselect msh
						)
					)
				)
			)
		)
	)
-- 	print matIDChannel[1] #nomap
-- 	print matIDChannel[2] #nomap
	

-- 	Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)

fn importNub &nudArr= (
	fname = GetOpenFileName caption:"DBZ Burst Limit Model Archive" types:"(*.nub)|*.nub"
	If (fname!=undefined) and ((DoesFileExist fname)==true) then (
		f = fopen fname "rb"   --open file in read only format
		clearlistener()
		
		NUB = ReadFixedString f 4
		fileLength = readbelong f
		nudCount = readbelong f
		nudStart = readbelong f
		ukw = readbeshort f		--always 2
		ukw2 = readbeshort f		--same
		NUD = ReadFixedString f 4
		fseek f 0x8 #seek_cur	--null
		
		nudOffset=#()
		for x=1 to nudCount do (
			nudOffset[x] = readbelong f + nudStart
			modelID = readbelong f	--bindID, index?
		)
		
		for x=1 to nudCount do (
			fseek f nudOffset[x] #seek_set
			readNud f nudArr
		)
		Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
	)
	gc()
	fclose f
)

fn importSkel = (
	gname = GetOpenFileName caption:"DBZ Burst Limit Skeleton" types:"(.amo)|*.amo;*.bin"
	If (gname!=undefined) and ((DoesFileExist gname)==true) then (
	g = fopen gname "rb"   --open file in read only format
	FileExtension = getFileNameType  gname
	FileName = getFileNameFile gname
	Print "===================================="
	print (FileName + FileExtension) as string
	Print "===================================="	
		
	amo = ReadFixedString g 4
	try (
		fseek g 0xc #seek_cur
		boneCount = readbelong g
		boneTableOffset = readbelong g
		fseek g 0xc #seek_cur
		nameOffset = readbelong g

		boneOffset=#()
		childID=#()
		siblingID=#()
		parentID=#()

		fseek g boneTableOffset #seek_set
		for x=1 to boneCount do (
			boneID = readbelong g
			boneOffset[x] = getOffset g (readbelong g)
			childID[x] = getID g (readbelong g)
			siblingID[x] = getID g (readbelong g)
			parentID[x] = getID g (readbelong g)
			fseek g 0xc #seek_cur
		)

		fseek g nameOffset #seek_set
		boneName = for x=1 to boneCount collect (ReadFixedString g 0x20)

		BNArr=#()
		for x=1 to boneCount do (
			fseek g boneOffset[x] #seek_set
			
			c11 = readbefloat g; c12 = readbefloat g; c13 = readbefloat g; c14 = readbefloat g
			c21 = readbefloat g; c22 = readbefloat g; c23 = readbefloat g; c24 = readbefloat g
			c31 = readbefloat g; c32 = readbefloat g; c33 = readbefloat g; c34 = readbefloat g
			tfm = inverse (quat c11 c12 c13 c14) as matrix3
			tfm.row4 = ([c21,c22,c23]*fscale)
			fseek g 0x20 #seek_cur

			if (parentID[x] != 0) then(
				tfm = tfm * BNArr[(parentID[x])].objecttransform	
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
			newbone.showlinks = true
			newbone.name = boneName[x]
			newBone.pos.controller      = Position_XYZ()
			newBone.rotation.controller = Euler_XYZ()
			
			if (parentID[x] != 0) then(
				
				newBone.parent = BNArr[(parentID[x])]
			)
			
			append BNArr newBone
		)

		for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		for b in BNArr do b.setskinpose()
	)
	catch (
		messagebox ("Not a valid skeleton file.")
	)
	)
	gc()
	fclose g
)

fn importAnm fstream = (
	magic = ReadFixedString fstream 4
	headerLength = readbelong fstream
	null = readbelong fstream
	ukw = readbelong fstream	--always 2
	trackCount = readbelong fstream
	tableOffset = readbelong fstream
	boneCount = readbelong fstream
	nameOffset = readbelong fstream

	fseek fstream nameOffset #seek_set
	boneName = for x=1 to boneCount collect (readfixedstring fstream 0x20)
	BNArr = for o in geometry where classOf o == boneGeometry collect o

	allTracks=#()
	fseek fstream tableOffset #seek_set
	for x=1 to trackCount do (
		frames = readbeshort fstream
		ukwFlag = readbeshort fstream
		offset = readbelong fstream
		
		if offset != 0 do (
			append allTracks (
				t = (trackInfo \
					numFrames: frames \
					trackOffset: offset \
					boneCount: boneCount \
					boneName: boneName 
				)
			)
		)
	)
	
	return allTracks
)

fn loadTrack f track = (
	fseek f track.trackOffset #seek_set
	
	controllerCount=#()
	controllerOffset=#()
	for y=1 to track.boneCount do (
		controllerCount[y] = readbelong f
		controllerOffset[y] = readbelong f
	)
	
	translations = #()
	rotations = #()
	for y=1 to track.boneCount do (
		fseek f controllerOffset[y] #seek_set
		
		posArr=#()
		posTime=#()
		rotArr=#()
		rotTime=#()
		sclArr=#()
		sclTime=#()
		for z=1 to controllerCount[y] do (
			tableIndex = readbeshort f
			frameIDSize = readbeshort f
			frameCount = readbeshort f
			ukw = readbeshort f	--always 1
			frameIDOffset = readbelong f
			frameOffset = readbelong f
			nextController = ftell f
			
			fseek f frameIDOffset #seek_set
			if frameIDSize == 0 do frameID = for j=1 to frameCount collect readbyte f #unsigned
			if frameIDSize == 1 do frameID = for j=1 to frameCount collect readbeword f 
			
			fseek f frameOffset #seek_set
			if tableIndex == 0 do (
				for j=1 to frameCount do (
					append rotArr (eulerAngles ((ReadBEshort f / 65535.0)*360.0) ((ReadBEshort f / 65535.0)*360.0) ((ReadBEshort f / 65535.0)*360.0))
				)
				rotTime = frameID
			)
			if tableIndex == 1 do (
				for j=1 to frameCount do (
					append posArr (point3 (readbefloat f) (readbefloat f) (readbefloat f))
				)
				posTime = frameID
			)
			
			fseek f nextController #seek_set
		)
		
		anim = (animInfo	\ 
			boneID: y \
			boneName: track.boneName[y] \
			posTime:  posTime \
			posArr:  posArr \
			sclTime:  sclTime \
			sclArr: sclArr \
			rotTime: rotTime \
			rotArr: rotArr
		)		
			with animate on(
				for a=1 to posArr.count do (
					
					b = getnodebyname track.boneName[y]
					t = posTime[a]
					p = posArr[a]
					
					if(b != undefined) then (
					at time t
						in coordsys parent b.pos = b.skinpos + (p * fscale)
					)
				)
				for a=1 to rotArr.count do (
					
					b = getnodebyname track.boneName[y]
					t = rotTime[a]
					q = rotArr[a]
					
					if (b!=undefined) then (
						at time t
						b.Controller.Rotation = q
					)
				)
			)
	)
	
-- 	gc()
-- 	fclose f
)

nudArr=#()
try(destroydialog BurstLimitImporter)catch()
rollout BurstLimitImporter "Burst Limit Import" width:210 height:105
(
	button mdlImport "Load Model" pos:[10,10] width:190 height:25
	button skelImport "Load Skeleton" pos:[10,40] width:190 height:25
	button anmImport "Load Animation" pos:[10,70] width:190 height:25 enabled:false
	listbox trkLst "Track List" pos:[9,110] width:190 height:10 selection:1
	pickbutton selMsh "Select Mesh" pos:[10,275] width:190 height:25 filter:editableMesh
	button ldTrk "Load Track" pos:[10,310] width:190 height:25
	
	on BurstLimitImporter open do
	(
		if skelPresent() do (
			anmImport.enabled = true
		)
	)
	on mdlImport pressed do
	(
		importNub nudArr
	--  		trkLst.items = for o in geometry where classof o == Editable_Mesh collect o.name
	)
	on skelImport pressed do
	(
		importSkel()
		if skelPresent() do (
			anmImport.enabled = true
		)
	)
	on anmImport pressed do
	(	
		hname = GetOpenFileName caption:"DBZ Burst Limit Animation" types:" (*.bin)|*.bin" historyCategory:""
		If (hname!=undefined) and ((DoesFileExist hname)==true) then (
			global h = fopen hname "rb"   --open file in read only format
			anm = importAnm h	--returns offsets to specific tracks
			if anm != false do (
				for x=1 to anm.count do trkLst.items[x] = ("Track "+(paddstring 3 (x as string)))
				trkLst.items = trkLst.items	--wont update on it's own for some reason
				BurstLimitImporter.height = 350
			)		
		)
	)
	
	on ldTrk pressed do (
-- 		if (classof selection[1] == Editable_Mesh) then (
-- 			print (classof selection[1].modifiers[#Skin])
			
			track = anm[trkLst.selection]
			loadTrack h track
			
-- 			loadTrack track
-- 		)
	)
)

createDialog BurstLimitImporter






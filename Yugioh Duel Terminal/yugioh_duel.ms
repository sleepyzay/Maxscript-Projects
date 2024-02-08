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

fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer) )as string))
)
fn FindNumofOcurrences narray num = (
	j=0
	for i in narray do (
		if i == num do j+=1
	)
	return j
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
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn getName bstream offset = (
	name = ReadFixedString f (offset-(ftell bstream))
	return Name
)
fn ApplyNormals amesh nArr toggle= (
	max modify mode
	cui.expertModeOn()

	with redraw off (
	   --your import code
		
	   for face = 1 to amesh.numfaces do setFaceSmoothGroup amesh face 1
		
	   select amesh
	   addmodifier amesh (Edit_Normals ()) ui:off
	   amesh.Edit_Normals.MakeExplicit selection:#{1..nArr.count}
	   EN_convertVS = amesh.Edit_Normals.ConvertVertexSelection
	   EN_setNormal = amesh.Edit_Normals.SetNormal
	   normID = #{}
		
	   for v = 1 to nArr.count do
	   (
		  free normID
		  EN_convertVS #{v} &normID
		  for id in normID do EN_setNormal id nArr[v]
	   )
	   
	   if toggle == 1 do collapseStack amesh
	)

	cui.expertModeOff()
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
fn printMatrix fstream = (
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	format "\n"
	fseek fstream -0x40 #seek_cur
)
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)


fscale=5
fname = GetOpenFileName caption:"" types:" (*.)|*.model" historyCategory:""
-- fname = @"E:\stuff\models\ripped\YGO Duel Terminal\M001_Blueeyes.pc.model"
-- fname=@"E:\models\ripped\YGO Duel Terminal\M001_Blueeyes.pc.model"
-- fname=@"E:\models\ripped\YGO Duel Terminal\M003_RedEyesBD.pc.model"
-- fname=@"E:\models\ripped\YGO Duel Terminal\A009_CyberDragon_a.pc.model"
-- fname=@"E:\models\ripped\YGO Duel Terminal\A005_Neos_a.pc.model"
-- fname=@"C:\Users\Xavier\Downloads\DuelTerminalERRORS\DuelTerminalERRORS\M1338_G_Laz.pc.model"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
	f = fopen fname "rb"   --open file in read only format
	actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
	FileExtension = getFileNameType  fname
	FilePath = getFileNamePath fname
	FileName = (FilterString (getFileNameFile fname) ".")[1]

	delete $*
	clearlistener()

	Print "===================================="
	print (FileName + FileExtension) as string
	Print "===================================="

	g = undefined
	gname = FilePath + FileName + ".sk"
	If (gname!=undefined) and ((DoesFileExist gname)==true) then (
		g = openFile gname
		FileExtension2 = getFileNameType  gname
		FilePath2 = getFileNamePath gname
		FileName2 = getFileNameFile gname
		
		print (FileName2 + FileExtension2) as string
		Print "===================================="
	)
	else (
		print "No sk file found."
		Print "===================================="
	)
	
	struct _model (
		tfmArray = #(),
		tfmArray2 = #(),
		parentIdArray = #(),
		boneNameArray = #(),
		boneMapOffset,
		boneMapCount,
		meshInfoOffset,
		meshCount,
		materialOffset,
		materialCount,
		materialInfoArray = #(),
		bufferInfoOffset
	)
	struct _table (
		count = readlong f,
		offset = readlong f
	)
	struct _meshInfo (
		tableOffset = ftell f,
		ukw = readshort f,
		faceType = readshort f,			--0=triStrips/1=tris
		section7Id = readlong f + 1,
		null = readlong f,
		null2 = readlong f,
		ukw3 = readlong f,					--1/count?
		vertInfoOffset = readlong f + tableOffset,	--points to within the bufferInfo section
		boneMapCount = readlong f,
		ukw4 = readbyte f,
		ukw5 = readbyte f,				--ff
		ukw6 = readbyte f,				--ff
		ukw7 = readbyte f,				--ff
		ukw8 = readlong f,				--1/count?
		faceInfoOffset = readlong f + tableOffset,	--points to within the bufferInfo section
		null4 = readlong f,
		ukw10 = readlong f,
		matId = readlong f + 1,				--section 8 related
		null5 = (fseek f 0x1c #seek_cur),
		ukwFloats = (for x=1 to 4 collect (readfloat f))
	)
	struct _bufferInfo (
		tableOffset = ftell f,
		bufferOffset = readlong f + tableOffset,
		bufferCount = readlong f,
		ukw = readbyte f,				--1
		bufferStride = readbyte f,
		vertDecCount = readbyte f,			--5
		ukw4 = readbyte f,			--1
		vertDecOffset = readlong f + tableOffset,
		null = readlong f,
		bufferType = readlong f,		--1=vertices, 2=faces
		null2 = readlong f,
		null3 = readlong f
	)
	struct _materialInfo (
		ukw = readlong f,
		ukw2 = readlong f,
		ukw3 = readlong f,
		ukw4 = readshort f,
		texId = readshort f + 1,
		null = (fseek f 0x40 #seek_cur)
	)
	struct _vertDecTable (
		null = readbyte f,
		offset = readbyte f,
		type = readbyte f f,
		usage = readbyte f
	)	
	
	magic = readlong f
	ukw = readlong f	--2
	ukw2 = readlong f	--2
	ukw3 = readlong f	--1
	ukw4 = readlong f	--0
	ukw5 = readlong f
	
	model = _model()
	sectionTableArray = for x=1 to 9 collect (table = _table()) --0x40 more bytes worth of data after / may not be important?
	matInfoOffset = readlong f
	skeletonOffset = readlong f	--same offset as section 1
	null = readlong f				--would be offset?
	ukwOffset3 = readlong f		--same offset as section 4
	ukwOffset4 = readlong f		--same as ukwOffset6
	bufferLength = readlong f
	bufferBaseOffset = readlong f
	texCount = readlong f		--?
	ukwOffset5 = readlong f		--related to texCount
	null = readlong f
	vertDecCount = readlong f
	vertDecBaseOffset = readlong f		--vertexDeclerationTable?
	fileSize = readlong f
	null = readlong f
	ukw8 = readlong f				--hash?/flags?
	
	
	fseek f ukwOffset5 #seek_set
	for x=1 to texCount do ReadFixedByteString f 0x10 0 0
	
	fseek f vertDecBaseOffset #seek_set
	for x=1 to vertDecCount do ReadFixedByteString f 0x04 0 0
	
	for x=1 to sectionTableArray.count do (
		section = sectionTableArray[x]
		fseek f section.offset #seek_set
		format "% %\n" x section.count
		case x of (
			1:(--skeleton
				for y=1 to section.count do (
					ReadFixedByteString f 0x10 0 0	--unknown data
					--printMatrix f
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]	
					
					--printMatrix f
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm2 = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
					
					ReadFixedByteString f 0x20 1 0
					fseek f 0x1c #seek_cur	--unknown data
					parentId = readlong f + 1
					
					append model.tfmArray tfm
					append model.tfmArray2 tfm2
					append model.parentIdArray parentId
				)
				
				if g != undefined do (
					for y=1 to section.count do (
						parentID = readDelimitedString g " "
						boneName = trimright (readDelimitedString g "\n")
						
						append model.boneNameArray boneName
					)
				)
			)
			2:(--bone map
				model.boneMapOffset = ftell f	--later accessed by other structs
				model.boneMapCount = section.count
			)
			3:(--mesh info
				model.meshInfoOffset = ftell f
				model.meshCount = section.count
			)
			4:(--buffer info
				model.bufferInfoOffset = ftell f
			)
			5:(--same offset as 3, 0 count
			)
			6:(--ukw, dosent look important
			)
			7:(--material info?
				section7TableArray = for y=1 to section.count collect (
					ReadFixedByteString f 0xa0 0 1
 					--section7Table = _section7Table()
				)
			)
			8:(--material info?
				model.materialOffset = ftell f
				model.materialCount = section.count
				model.materialInfoArray = for y=1 to section.count collect (
					ReadFixedByteString f 0x50 1 0
					materialInfo = _materialInfo()
				)
			)
			9:(--ukw, dosent look important
				ReadFixedByteString f 0x30 0 0
			)
			default: (
				format "section index: %	count: %	offset: %\n" (x) (bit.intashex(section.count)) (bit.intashex(section.offset))
			)
		)
	)
	
	fseek f matInfoOffset #seek_set
	printHere f
	null = readlong f	--empty pointer?
	texNamesOffset = readlong f + matInfoOffset
	matNamesOffset = readlong f + matInfoOffset
	ukw9 = readlong f
	
	fseek f texNamesOffset #seek_set
	texNameArray = for x=1 to texCount collect (texName = (getName f (readlong f + texNamesOffset)))
	print texNameArray
	
	fseek f matNamesOffset #seek_set
	matNameArray = for x=1 to 1 collect (matName = (getName f (readlong f + matNamesOffset)))	--im gonna asume one of the section counts is the actual material count, prob 6
	
	multiMat = MultiMaterial numsubs:model.materialCount showInViewport:true name:matNameArray[1]
	meditMaterials[1] = multiMat
	for x=1 to multiMat.count do (		
		texPath = FilePath + texNameArray[model.materialInfoArray[x].texId]
		if DoesFileExist texPath == true then (
			multiMat[x].diffuseMap = Bitmaptexture filename:texPath
			multiMat[x].showinviewport = true
		)
		else (
			multiMat[x].Diffuse = random black white
		)
	)
	
	format "boneCount: %\n" model.tfmArray.count
	format "meshCount: %\n" model.meshCount
	format "modelBoneMapCount: %\n" model.boneMapCount
	
	BNarr=#()
	for x=1 to model.tfmArray.count do (
		tfm = model.tfmArray[x]
		tfm2 = model.tfmArray2[x]
		parentId = model.parentIdArray[x]
		boneName = model.boneNameArray[x]
		
		newBone = bonesys.createbone	\
		tfm.row4	\
		(tfm.row4 + 0.01 * (normalize tfm.row1)) \
		(normalize tfm.row3)
		newBone.width = 0.1
		newBone.height = 0.1
		newBone.wirecolor = white
		newbone.showlinks = false
		newBone.transform = tfm
		newBone.pos *= fscale
		
		if boneName != undefined do newBone.name = boneName
		newBone.name = (x as string) + "_" + newBone.name	--hack to refer to bone by id in foreign script, after parenting original order is lost
		
		newBone.setBoneEnable false 0
		newBone.pos.controller = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()
 		
		if (parentID != 0) then (
			newBone.parent = BNArr[parentID]
		)
		append BNArr newBone
	)
	--for o in BNArr do print o
	
	rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
	for b in BNArr where b.parent==undefined do b.parent = rootRT
	rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	for b in BNArr do b.setskinpose()
	--print BNArr
	
	boneMapOffset = model.boneMapOffset
	for x=1 to model.meshCount do (	-- model.meshCount
		Vert_Array=#()
		UV_Array=#()
		Normal_Array=#()
		Face_Array=#()
		MatId_Array=#()
		BoneId_Array=#()
		Weight_Array=#()
		
		fseek f (model.meshInfoOffset + (x-1) * 0x60) #seek_set
		ReadFixedByteString f 0x60 1 0
		meshInfo = _meshInfo()
		print meshInfo
		
		fseek f boneMapOffset #seek_set
		boneMap = for y=1 to meshInfo.boneMapCount collect (readshort f#unsigned + 1)
		if model.boneMapCount > 1 then (
			boneMapOffset = ftell f
			model.boneMapCount -= 1
		)
		
		fseek f (model.bufferInfoOffset + ((x*2-2) * 0x20)) #seek_set
		ReadFixedByteString f 0x20 1 0
		vertInfo = _bufferInfo()
		
		fseek f vertInfo.vertDecOffset #seek_set
		vertDecArray = for y=1 to vertInfo.vertDecCount collect (vertDec = _vertDecTable())
		--print vertDecArray
		
		fseek f (model.bufferInfoOffset + ((x*2-1) * 0x20)) #seek_set
		ReadFixedByteString f 0x20 1 0
		faceInfo = _bufferInfo()
		
		fseek f vertInfo.bufferOffset #seek_set
		for y=1 to vertInfo.bufferCount do (
			vertBase = ftell f
			for z=1 to vertInfo.vertDecCount do (
				vertDec = vertDecArray[z]
				fseek f (vertDec.offset + vertBase) #seek_set
				case vertDec.usage of (
					16:(	--position
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						
						append Vert_Array ([vx,vy,vz] * fscale)
					)
					33:(	--bones id's
						b1 = readbyte f #unsigned + 1
						b2 = readbyte f #unsigned + 1
						b3 = readbyte f #unsigned + 1
						b4 = readbyte f #unsigned + 1
						
						append BoneId_Array #(b1,b2,b3,b4)
					)
					32:(	--weights
						w1 = 0
						w2 = 0
						w3 = 0
						w4 = 0
						
						if vertDec.type == 0 do (
							w2 = readfloat f
						)
						if vertDec.type == 1 do (
							w2 = readfloat f
							w3 = readfloat f
						)
						if vertDec.type == 2 do (
							w2 = readfloat f
							w3 = readfloat f
							w4 = readfloat f
						)
						
						w1 = 1.0 - (w2 + w3 + w4)
						append Weight_Array #(w1,w2,w3,w4)
					)
					18:(	--normals
						nx = readfloat f
						ny = readfloat f
						nz = readfloat f
						
						append Normal_Array [nx,ny,nz]
					)
					22:(	--uv's
						tu = readfloat f
						tv = readfloat f
						
						append UV_Array [tu,1-tv,0]
					)
				)
			)
			fseek f (vertBase + vertInfo.bufferStride) #seek_set
		)
		--format "\n"
		
		fseek f faceInfo.bufferOffset #seek_set
		if meshInfo.faceType == 0 do (
			faceStart=ftell f
			StartDirection = -1
			f1 = (readshort f) + 1
			f2 = (readshort f) + 1  
			FaceDirection = StartDirection
			do (
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
						if FaceDirection > 0 then append Face_Array [f1,f2,f3]
						else append Face_Array [f1,f3,f2]
						append MatId_Array meshInfo.matId
					)
					f1 = f2
					f2 = f3
				) 
			) 
			while ((ftell f) != faceStart+(faceInfo.bufferCount*2))
		)
		if meshInfo.faceType == 1 do (
			for y=1 to faceInfo.bufferCount / 3 do (
				fa = readshort f #unsigned + 1
				fb = readshort f #unsigned + 1
				fc = readshort f #unsigned + 1
				
				append Face_Array [fa,fb,fc]
				append MatId_Array meshInfo.matId
			)
		)
		
		msh = mesh vertices:Vert_Array faces:Face_Array materialIDs:MatId_Array
		msh.numTVerts = UV_Array.count
		msh.name = (x as string) + "_" + (bit.intashex(vertInfo.bufferStride as integer)) as string
		msh.material = multiMat
		buildTVFaces msh
		for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
		for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
		for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
		msh.transform =  (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
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
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_array.count do (
			bi = #()
			wv = #()
			for j=1 to 4 where Weight_array[i][j] != 0 do (	--for some reason if I don't do this some verts are not weighted
				append bi BoneId_Array[i][j]
				append wv Weight_Array[i][j]
			)
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)
	)

	Print ("Last Read @ 0x"+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
if g != undefined do close g

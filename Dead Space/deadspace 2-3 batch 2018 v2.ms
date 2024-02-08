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
fn filterFile fileName = (
	filterList=#(
		"_cap_",
		"_torsocap_",
		"_lodmodel_",
		"_tc_",
		"_bc_",
		"_sc_",
		"_pc_",
		"2_d",
		"3_d",
		"4_d"
	)
	visceral = false
	for a in filterList where ((findstring fileName a) != undefined) do (
		visceral = true
		exit
	)
	return visceral
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

fscale = 100
savePath = ""
folderPath = getSavePath caption:"DeadSpace 2/3 Geometry" initialDir:@"C:\Users\Xavier\Desktop\ds3\global_assets\global_assets\ds_assets\char_str\hmn\carver_cct\se_carver_unpacked\Mesh"
savePath = folderPath

if folderPath != undefined do (
	delete $*
	files = getFiles (folderPath + "\\*.geo")
	clearlistener()

	for fname in files where ((fname != undefined) and ((DoesFileExist fname) == true)) do (
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
		
		visceral = filterFile FileName
		if (visceral == false) do (
			print fileName
			
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

			meshName=#()
			vertOffset=#()
			vertOffsetRef=#()
			vertCount=#()
			vertType=#()
			faceOffset=#()
			faceOffsetRef=#()
			faceCount=#()
			faceType=#()
			uvSize=#()
			fseek f dataTable #seek_set	
			For x=1 to tableCount do (
				
				meshName[x] = getName f (readlong f)
				ukw = readbyte f
				ukw2 = readbyte f
				ukw2 = readbyte f
				matID = x
				ukw3 = readbyte f
				ukw4 = readlong f
				ukwArr = for y=1 to 5 collect (readfloat f)
				bbOffset = readlong f
				ukwArr2 = for y=1 to 3 collect (readbyte f)
				uvSize[x] = readbyte f
				ukw5 = readshort f
				ukw6 = readshort f
				null = readlong f	
				faceCount[x] = readlong f 
				faceOffsetRef[x]=readlong f 		-- face offset?
				vertCount[x] = readshort f 
				vertOffsetRef[x] = readshort f			-- vert offset?
				faceType[x] = readshort f
				--0x3e
				ukw8 = readshort f				-- looks like an offset
				preVertTotal = readshort f		-- if first of index then 0
				vertTotal = readshort f			-- updated per index
				ukwOffset=readlong f 		-- bind list?
				fseek f 0x1c #seek_cur		-- null
				ReadFixedByteString f 0xc 1 0
				vertType[x] = readlong f + 2
				ukw10 = readlong f
				polyID = readlong f + 1
				ukw11 = readlong f
				fseek f 0x10 #seek_cur		--null
				vertOffset[x] = readlong f 
				faceOffset[x] = readlong f 
				fseek f 0x20 #seek_cur		--null
				ukwArr3 = for y=1 to 5 collect readfloat f --mat info?
			)

			uvOffset = 0
			for x=1 to tableCount do (
				Vert_Array=#()
				Face_Array=#()
				UV_Array=#()
				Normal_Array=#()
				Weight_Array=#()
				Mat_Array=#()
				
				fseek f vertOffset[x] #seek_set
				if vertType[x] == 1 do (
					for y = 1 to vertCount[x]
						do (
						
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
						
						append Vert_array([vx,vy,vz]*fscale)
			-- 			append UV_array([0,0,0])
						append Normal_array([nx,ny,nz])
					)
				)
				if vertType[x] >= 2 do (
					if faceType[x] == 4 do (
						for y = 1 to vertCount[x] do(
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
			-- 				append UV_array([0,0,0])
							append Normal_array([nx,ny,nz])
						)
					)
					if faceType[x] == 5 do (
						for y = 1 to vertCount[x] do(
							vx=readfloat f
							vy=readfloat f
							vz=readfloat f
							
							append Vert_array([vx,vy,vz]*fscale)
							append UV_array([0,0,0])
							append Normal_array([nx,ny,nz])
						)
					)
				)

				fseek f faceOffset[x] #seek_set
				if faceType[x] == 4 do (
					for y = 1 to faceCount[x]/3 do (
						fa = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
						fb = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
						fc = ((ReadShort f #unsigned + 1) - vertOffsetRef[x])
						
						append Face_Array[fa,fb,fc]
						append Mat_Array matID
					)
				)
				
				if extUV == true then (
					fseek g uvOffset #seek_set
					for y=1 to vertCount[x] do (
						tu = readfloat g
						tv = readfloat g
						
						fseek g (uvSize[x] - 8) #seek_cur
						
						append UV_array([tu,1-tv,0])
					)
					
					uvOffset = ftell g
				)
				else (
					fseek f localUVOffset #seek_set
					for y=1 to vertCount[x] do (
						tu = readfloat f
						tv = readfloat f
						
						fseek f (uvSize[x] - 8) #seek_cur
						
						append UV_array([tu,1-tv,0])
					)
					
-- 					print UV_Array
				)
				
				msh = mesh vertices:Vert_array faces:Face_Array
				msh.numTVerts = UV_array.count
				msh.material = mat
				msh.name = meshName[x]
				buildTVFaces msh
				for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
				for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
				for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
				msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
			)

			
		)
		
		gc()
		fclose f
		fclose g
	)
)


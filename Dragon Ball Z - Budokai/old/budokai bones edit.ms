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
fn getID bstream offset = (
	id = 0
	
	backjump = ftell bstream
	fseek bstream offset #seek_set
	if offset > 0 then (
		id = (readlong bstream)+1
	)
	fseek bstream backjump #seek_set
	return id
)
fn getOffset bstream offset = (
	backjump = ftell bstream
	fseek bstream offset #seek_set
	fseek bstream 0x8 #seek_cur
	theOffset = readlong bstream
	null = readlong bstream
	fseek bstream backjump #seek_set
	return theOffset
)

fname = GetOpenFileName caption:"Dragon Ball Z Budokai" types:"All Known Formats|*.amo;*.dat;*.bin|(*.amo)|*.amo|(*.dat)|*.dat|(*.bin)|*.bin"
-- fname = @"C:\Users\Xavier\Documents\projects\models\budokai3files\unnamed_167.amo"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=5
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="


AmgOffset=#()

AMO = readfixedstring f 4
HeaderLength = readlong f
fseek f 0x8 #seek_cur
AmoData_Count = readlong f	-- dont know that its for but its by an interval of 0x20
AmoData_Start = readlong f
AmgCount = readlong f
AmgOffsetTable = readlong f
Bonecount = readlong f	-- Looks like a count
BoneNameTableOffset = readlong f

Print ("AmgCount is "+((AmgCount)as string))
Print "_________________________________"


fseek f BoneNameTableOffset #seek_set
boneName=#()
for x=1 to AmoData_Count do (
	boneName[x] = ReadFixedString f 0x20
)
-- print boneName

fseek f AmoData_Start #seek_set
boneTable=#()
tableOffset=#()
tableOffset2=#()
tableOffset3=#()
parentID=#()
boneOffset=#()

-- table info --
for x=1 to AmoData_Count do (
	boneID = readlong f
	boneTable[x] = readlong f
	tableOffset[x] = readlong f
	tableOffset2[x] = readlong f
	tableOffset3[x] = readlong f
	fseek f 0xc #seek_cur
	
	parentID[x] = getiD f tableOffset3[x]
	boneOffset[x] = getOffset f boneTable[x]
		
-- 	print (bit.intashex(boneTable[x]))
)


BNArr=#()
for x=1 to AmoData_Count do (
	fseek f boneOffset[x] #seek_set
	
	c11 = readfloat f; c12 = readfloat f; c13 = readfloat f; c14 = readfloat f
	c21 = readfloat f; c22 = readfloat f; c23 = readfloat f; c24 = readfloat f 
	c31 = readfloat f; c32 = readfloat f; c33 = readfloat f; c34 = readfloat f
	tfm = inverse (quat c11 c12 c13 c14) as matrix3
	tfm.row4 = ([c21,c22,c23]*fscale)
	fseek f 0x20 #seek_cur
	
 	
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
	newbone.name = boneName[x]
	newbone.showlinks = true
	newBone.pos.controller      = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
-- 	print parentID[x]
-- 		
	if (parentID[x] != 0) then(
		
		newBone.parent = BNArr[(parentID[x])]
	)
	
	append BNArr newBone
)

for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
for b in BNArr do b.setskinpose()

fseek f AmgOffsetTable #seek_set
for x=1 to AmgCount do (
	AmgOffset[x] = readlong f
)
numAmg = 1
for x=numAmg to numAmg do (	-- amgCount
	
	DataOffset=#()
	Ukw1=#()
	Ukw2=#()

-- 	Print ("AMG"+(x)as string)
-- 	Print "______________________________"
	
	fseek f AmgOffset[x] #seek_set
	Amg_Addto = ftell f 
	
-- 	Print ("Amg_Addto is 0x"+((bit.intAsHex(ftell f))as string))
	
	AMG = ReadFixedString f 4
	HeaderLength = readlong f
	unk1 = readlong f
	unkcount = readlong f
	BlockCount = readlong f
	BlockStart = readlong f + Amg_Addto
	unk2 = readlong f
	NameOffset = readlong f + Amg_Addto
	
	fseek f BlockStart #seek_set
	For y=1 to BlockCount do (
		fseek f 0x30 #seek_cur		--bone matrix?
		DataType = readshort f
		DataType2 = readshort f 
		DataOffset[y] = readlong f + Amg_Addto
		Ukw1[y] = readlong f
		ukw2[y] = readlong f
		fseek f 0x10 #seek_cur
		
-- 		Print ("DataType   "+(paddstring 2 y)+" is 0x"+((bit.intAsHex(DataType[y]))as string))
-- 		Print ("DataOffset "+(paddstring 2 y)+" @ 0x"+((bit.intAsHex(DataOffset[y]))as string))
-- 		format"\n"
	)
	
	For y=1 to blockCount do (	-- blockCount
		ModelOffset=#()
-- 		print boneName[y]
		
		fseek f DataOffset[y] #seek_set
-- 		ReadFixedByteString f 0x10
-- 		fseek f -0x10 #seek_cur
		
-- 		Print ("DataOffset "+(paddstring 2 y)+" @ 0x"+((bit.intAsHex(DataOffset[y]))as string))
		
		format "\n"
		
		
		ModelNumber = readlong f
		modelOffset = for z=1 to 4 collect (readlong f #unsigned + Amg_Addto) 
		for z=1 to 4 do (
			if modelOffset[z] > Amg_Addto do (
				fseek f modelOffset[z] #seek_set
				
				if z == 1 do (
					addto = ftell f
					
					meshCount = readlong f
					meshOffsetTable = readlong f + addto
					
-- 					Print ("MeshCount is "+((MeshCount)as string))
-- 					print "========================"
					
					-- Mesh Offsets --
					fseek f MeshOffsetTable #seek_set
					meshOffset = for a=1 to meshCount collect (readlong f + addto)
					-- Reading Meshes --
					For a=1 to meshcount do (
						Msh_Vert_array = #()
						Msh_Normal_array = #()
						Msh_UV_array = #()
						Msh_Face_array = #()
						MshVertexCount = 0
						
						
						fseek f MeshOffset[a] #seek_set
--  						Print ("MeshOffset "+(paddstring 2 z)+" @ 0x"+((bit.intAsHex(ftell f))as string))
						
						meshType = for x=1 to 8 collect (readbyte f #unsigned)
						Ukw3 = readlong f	-- Incrementing
						matID = readlong f
						fseek f 0x30 #seek_cur	-- matrix info
						addagain = ftell f
						fseek f 0x50 #seek_cur	-- dont know what these are for
						SubMeshBufferLength = readshort f * 0x10 
						SubMeshBufferStart = readshort f + addagain
						fseek f 0xc #seek_cur
						
						NextMeshOffset = SubMeshBufferLength + MeshOffset[a] + 0xa0	-- since I cant find a count my plan is to loop indefinitely until I reach this offset.
						
-- 						format ((paddstring 2 z)+" ")
-- 						for a in meshType do format (paddstring 2 (bit.intashex(a))+" ")
-- 						print (bit.intashex(meshType[1]))
-- 						format "\n"
							
-- 						format ("MeshType @ 0x"+((bit.intAsHex(MeshType))as string)+" \n")
-- 						format ("MeshType2 @ 0x"+((bit.intAsHex(MeshType2))as string)+" \n")
						
						
						Do (
							Face_array=#()
							Vert_array=#()
							UV_array=#()	
							Normal_array=#()
							
							-- submesh starts here --
-- 							backjump = ftell f
-- 							test = ReadFixedByteString f 0x10
-- 							fseek f backjump #seek_set
							fseek f 0xc #seek_cur	
							Ukw1 = readshort f
							VertBufferLength = readbyte f * 0x10
							Ukw2 = readbyte f
							NextSubMeshOffset = (VertBufferLength + ftell f)
							FaceType = readlong f	-- 0 is strips 1 is normal
							VertCount = readlong f
							Null = readlonglong f
							
-- 							print test
-- 							print meshtype
-- 							format ((paddstring 2 z)+" ")
-- 							format ("MeshType @ 0x"+((bit.intAsHex(MeshType))as string)+" ")
-- 							format ("MeshType2 @ 0x"+((bit.intAsHex(MeshType2))as string)+" ")
-- 							format ("FaceType @ 0x"+((bit.intAsHex(FaceType))as string)+"\n")

-- 				
-- 							Print ("Vertex "+((z)as string)+" is @ 0x"+((bit.intAsHex(ftell f))as string))
							
							if MeshType[1] == 0xbd or MeshType[1] == 0xfd  or MeshType[1] == 0x3d do (
								for x=1 to VertCount do (
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									null = readfloat f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									null = readfloat f
									tu = readfloat f
									tv = readfloat f
									Ukw = readfloat f		-- probably uvs
									null = readfloat f

									append Vert_array([vx,vy,vz]*fscale)
									append Normal_array[nx,ny,nz]
									append UV_array[tu,tv*-1,0]
								)
							)
							if MeshType[1] == 0xb5 or MeshType[1] == 0xb6 or MeshType[1] == 0xf5 do (
								for x=1 to VertCount do (
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									null = readfloat f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									null = readfloat f
									tu = readfloat f
									tv = readfloat f
									null = readfloat f
									fseek f 0x4 #seek_cur
									
									append Vert_array([vx,vy,vz]*fscale)
									append Normal_array[nx,ny,nz]
									append UV_array[tu,tv*-1,0]
								)
							)
							if MeshType == 0x199 do (
								for x=1 to VertCount do (
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									null = readfloat f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									null = readfloat f
									
									append Vert_array([vx,vy,vz]*fscale)
									append Normal_array[nx,ny,nz]
									append UV_array[0,0,0]
								)
							)
							if MeshType[1] == 0xb4 or MeshType[1] == 0xa4 or MeshType[1] == 0x99 or MeshType[1] == 0x92 or MeshType[1] == 0x19 do (
								for x=1 to VertCount do (
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									null = readfloat f
									tu = readfloat f
									tv = readfloat f
									fseek f 0x8 #seek_cur
									
									append Vert_array([vx,vy,vz]*fscale)
									append Normal_array[0,0,0]
									append UV_array[tu,tv,0]
								)
							)
							if MeshType[1] == 0x90 do (
								for x=1 to VertCount do (
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									null = readfloat f
									
									append Vert_array([vx,vy,vz]*fscale)
									append Normal_array[0,0,0]
									append UV_array[0,0,0]
								)
							)
							
							ReadFaces VertCount FaceType
							
-- 							msh = mesh vertices:Vert_array faces:Face_array
-- 							msh.numTVerts = UV_array.count
-- 							msh.name = (bit.intashex(meshtype)as string)
-- 							buildTVFaces msh
-- 							for j = 1 to UV_array.count do setTVert msh j UV_array[j]
-- 							for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
							
							for i = 1 to Face_array.count do (
								vertices = Face_array[i]
								append Msh_Face_array [vertices[1] + MshVertexCount, vertices[2] + MshVertexCount, vertices[3] + MshVertexCount]
							)
							
							MshVertexCount += Vert_array.count
							for i = 1 to Vert_array.count do (
								append Msh_Vert_array vert_array[i]
								append Msh_Normal_array normal_array[i]
								append Msh_UV_array UV_array[i]
							)
							
						)
						While ((ftell f) != (NextMeshOffset-0x10))
						
						max create mode
						
						-- Building Mesh --
						msh = mesh vertices:Msh_Vert_array faces:Msh_Face_array
						msh.numTVerts = Msh_UV_array.count
						msh.wirecolor = random black white
						msh.backfacecull = off
						msh.name = BNArr[y].name
						buildTVFaces msh    
						for j = 1 to Msh_UV_array.count do setTVert msh j Msh_UV_array[j]
						for j = 1 to Msh_Face_array.count do setTVFace msh j Msh_Face_array[j]
--  						for j = 1 to Msh_Normal_array.count do setNormal msh j Msh_Normal_array[j]
						msh.transform = BNArr[y].transform
						
						max create mode
						
-- 						If z < MeshCount do Print ("NextMeshOffset "+(paddstring 2 z)+" is 0x"+((bit.intAsHex(NextMeshOffset))as string))
-- 						If z== MeshCount do Print ("NextModelOffset "+(paddstring 2 z)+" is 0x"+((bit.intAsHex(NextMeshOffset))as string))

					)
					
				)
				
				if z == 20 do (
					weightOffset=#()
					weightCount=#()
					
					
					
					fseek f 0xc #seek_cur
					tableCount = readlong f #unsigned
					print tableCount
					for a=1 to tableCount do (
						ukw = readfloat f	-- something to do with the weighing
						weightCount[a] = (readlong f #unsigned)
						weightOffset[a] = (readlong f #unsigned + Amg_Addto) 
						fseek f 0x14 #seek_cur
					)
					
					for a=1 to tableCount do (
						Vert_array=#()
						UV_array=#()
						Face_array=#()
						fseek f weightOffset[a] #seek_set
						Print ("Here @ 0x"+((bit.intAsHex(ftell f))as string))
						for b=1 to weightCount[a] do (
							wd = for c=1 to 3 collect (readfloat f)	-- weightData
							ukwOffset = readlong f #unsigned	-- cant match it to anything
							wd2 = for c=1 to 3 collect (readfloat f)	-- for second mesh
							null = readlong f
-- 							
-- 							print (bit.intashex(ukwOffset))
-- 							print (wd[1]+wd[2]+wd[3])
-- 							
							append Vert_array([-wd[1],wd[3],wd[2]]*fscale)
							append UV_array[0,0,0]
						)
						msh = mesh vertices:Vert_array faces:#()
						msh.numTVerts = UV_array.count
						msh.name = boneName[x]
						msh.pos = BNArr[y].pos
						buildTVFaces msh
						for j = 1 to UV_array.count do setTVert msh j UV_array[j]
						
					)
					
					
					
-- 				
				)
				
				if z == 3 do (
					
				)
				
			)
		)
	)
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

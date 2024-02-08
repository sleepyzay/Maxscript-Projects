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
   if var == 1 do fseek bstream -fixedLen #seek_cur
   if var2 == 1 do print str
)
fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHexArr inArr var = (
	if var == 0 do (
		for o in inArr do printHex o
	)
	if var == 1 do (
		nomapArr = #()
		for o in inArr do append nomapArr (bit.intashex(o as integer))
		print nomapArr #nomap
	)
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
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

fname = GetOpenFileName caption:"" types:" (*.)|*.mdl" historyCategory:""
-- fname =@"C:\Users\Owner\Desktop\New folder\ply\p01\p01a.mdl"
-- fname=@"C:\Users\Owner\Desktop\New folder\ply\p12\p12a.mdl"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=1
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

FMDL = ReadFixedString f 4
stringBuffer = readlong f
dataCount = readlong f
ukw2 = readlong f
fseek f 0x10 #seek_cur	--null

dataOffset = for x=1 to dataCount collect (readlong f)
for x=1 to dataCount do (
	fseek f dataOffset[x] #seek_set
	dataType = ReadFixedString f 4
	case dataType of (
		"DMOD":(
			dmodLength = readlong f
			dmodDataCount = readlong f
			fseek f 0x14 #seek_cur	--null
			
			dmodDataOffset = for y=1 to dmodDataCount collect (readlong f #unsigned + dataOffset[x])	
			for y=1 to dmodDataCount do (	--dmodDataCount
				fseek f dmodDataOffset[y] #seek_set
				ReadFixedByteString f 0x0c 1 0
				
-- 				print y
-- 				printHere f
				XMOD = ReadFixedString f 4
				xmodLength = readlong f
				null = readlong f
				
				printHere f
				ReadFixedByteString f 0x34 1 1
				
				vertType = readlong f	--vertType
				xmodIndex = readlong f
				ukw2 = readlong f	--2
				null2 = readlong f
				null3 = readlong f
				ukw3 = readlong f	--same as vertType
				ukw4 = readlong f	--2
				vertexDataLength = readlong f
				ukw5 = readlong f --1
				vertTotal = readlong f
				faceTotal = readlong f
				meshCount = readlong f	--1
				ukw9 = readlong f	--two shorts?
				
				fseek f (dmodDataOffset[y] + 0x40) #seek_set
				meshIndex = for z=1 to meshCount collect (readlong f)												--space for 32, unused spaces are 0x00's
				
				fseek f (dmodDataOffset[y] + 0xc0) #seek_set
				meshOffset = for z=1 to meshCount collect (readlong f + dmodDataOffset[y] + 0x1a0)	--space for 32, unused spaces are 0xff's
				
				for z=1 to 1 do (	--meshCount
					fseek f meshOffset[z] #seek_set
					
					ReadFixedByteString f 0x10 1 0
					ukw10 = readshort f
					ukw11 = readshort f
					null4 = readlong f
					null5 = readlong f
					null6 = readlong f
					
					Vert_Array=#()
					UV_Array=#()
					Face_Array=#()
					Normal_Array=#()
					
					vertIndex = 0
					while vertIndex < vertTotal do (
						ReadFixedByteString f 0x30 1 0
						
						fseek f 0x20 #seek_cur
						vertCount = readbyte f
						fseek f 0x0f #seek_cur
						
						for z=1 to vertCount do (
							case vertType of (
								0x00:(
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									vw = readlong f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									nw = readfloat f
									tu = readfloat f
									tv = readfloat f
									tw = readfloat f
									null = readlong f
									
									append Vert_Array([vx,vy,vz,vw]*fscale)
									append Normal_Array([nx,ny,nz])
									append UV_Array[tu,1-tv,0]
								)
								0x01:(
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									vw = readlong f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									nw = readfloat f
									tu = readfloat f
									tv = readfloat f
									tw = readfloat f
									null = readlong f
									
									append Vert_Array([vx,vy,vz,vw]*fscale)
									append Normal_Array([nx,ny,nz])
									append UV_Array[tu,1-tv,0]
								)
								0x03:(
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									vw = readlong f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									nw = readfloat f
									tu = readfloat f
									tv = readfloat f
									tw = readfloat f
									null = readlong f
									bone1 = readlong f
									bone2 = readlong f
									bone3 = readlong f
									bone4 = readlong f
									weight1 = readfloat f
									weight2 = readfloat f
									weight3 = readfloat f
									weight4 = readfloat f
									
									append Vert_Array([vx,vy,vz,vw]*fscale)
									append UV_Array[tu,1-tv,0]
									append Normal_Array[nx,ny,nz]
								)
								0x0b:(
									vx = readfloat f
									vy = readfloat f
									vz = readfloat f
									vw = readlong f
									nx = readfloat f
									ny = readfloat f
									nz = readfloat f
									nw = readfloat f
									tu = readfloat f
									tv = readfloat f
									tw = readfloat f
									null = readlong f
									ukwFloat = readfloat f
									ukwFloat2 = readfloat f
									ukwFloat3 = readfloat f
									ukwFloat4 = readfloat f
									ukwFloat5 = readfloat f
									ukwFloat6 = readfloat f
									ukwFloat7 = readfloat f
									ukwFloat8 = readfloat f
									
									
									append Vert_Array([vx,vy,vz,vw]*fscale)
									append Normal_Array([nx,ny,nz])
									append UV_Array[tu,1-tv,0]
								)
								default:(
									format "uknown ukw:%\n" vertType
									exit
								)
							)
						)
						
						ukw12 = readlong f	--0x17
						null7 = readlong f
						null8 = readlong f
						null9 = readlong f
	-- 					printHex ukw12
						
						vertIndex += vertCount
					)
					
					FaceDirection = 1
					newTri = false
					newTriVertCount = 0
					for x=1 to vertTotal do (
						vertFlag = Vert_Array[x][4] as integer
						
						f1 = x - 2
						f2 = x - 1
						f3 = x
						
						if vertFlag == 0x8000 do newTri = true
						if newTri == true then (
							newTriVertCount += 1
							if newTriVertCount == 3 do (
								newTri = false
								FaceDirection = 1
								newTriVertCount = 0
								
								append Face_Array ([f1,f2,f3])
							)
						)
						else (			
							FaceDirection *= -1
							if FaceDirection > 0 then append Face_array [f1,f2,f3]
							else append Face_array [f1,f3,f2]
							
							f1 = f2
							f2 = f3
						)
					)
					
					msh = mesh vertices:Vert_array faces:Face_array
					msh.numTVerts = UV_array.count
					msh.wirecolor = random black white
					msh.name = xmodIndex as string
					buildTVFaces msh
					defaultVCFaces msh
					for j = 1 to UV_array.count do setTVert msh j UV_array[j]
					for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
					for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
				)
			)
		)
		"XMTX":(
			xmtxLength = readlong f
			xmtxDataCount = readlong f
			fseek f 0x14 #seek_cur	--null
			
			for y=1 to xmtxDataCount do (
				ukwDataArray = for z=1 to 32 collect (readlong f)
			)
		)
		"DHIE":(
			dhieLength = readlong f
			dhieDataCount = readlong f
			fseek f 0x14 #seek_cur
			
			dhieDataOffset = for y=1 to dhieDataCount collect (readlong f #unsigned + dataOffset[x])
			
			fseek f dhieDataOffset[1] #seek_set
			XHIE = readlong f
			xhieLength = readlong f
			xhieDataCount =readlong f
			fseek f 0x14 #seek_cur
			
			BNArr=#()
			for y=1 to xhieDataCount do (
				boneID = readlong f
				parentID = readlong f
				ukwID = readlong f	--siblingID?
				ukwID2 = readlong f	--siblingID?
				
				sx = readfloat f;	sy = readfloat f;	sz = readfloat f;	sw = readfloat f
				rx = readfloat f;	ry = readfloat f;	rz = readfloat f;	rw = readfloat f
				tx = readfloat f;	ty = readfloat f;	tz = readfloat f;	tw = readfloat f
				tfm = (eulerangles rx ry rz) as matrix3	
				tfm.row4 = ([tx,ty,tz]*fscale)
				
				if (parentID != -1) do (
					tfm *= BNArr[parentID + 1].objecttransform
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

				if (parentID != -1) then(
					newBone.parent = BNArr[parentID + 1]
					--newBone.transform *= newBone.parent.transform
				)
				append BNArr newBone
			)
		)
		"XNON":(
			
		)
		default:(
			format "unparsed dataType: %\n" (dataType)
		)
	)
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
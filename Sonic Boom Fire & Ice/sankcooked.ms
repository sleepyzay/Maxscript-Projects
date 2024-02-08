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
fn AlignOffset fstream relativeoffset alignment = (
   align = (alignment - (mod relativeoffset alignment as integer))
   align = fseek fstream align #seek_cur
   return align
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
return bit.intasfloat outputasfloat*2)

fname = GetOpenFileName caption:"" types:"(.)|*.cooked"
-- fname=@"C:\Users\Xavier\Desktop\All_Combined.san.cooked"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=40
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

fseek f 0 #seek_end
fileEnd = ftell f
fseek f 0 #seek_set

FORM = ReadFixedString f 4
fileLength = readlong f

PLAT = ReadFixedString f 4
platLength = readlong f
fseek f (platLength - 4) #seek_cur

do (
	Print ("PFOF @ 0x"+((bit.intAsHex(ftell f))as string))
	PROF = ReadFixedString f 4
	addto = ftell f
	profLength = readlong f
	
	nextProf = (profLength+addto)
	meshOffset = (addto+0x14)
	
	PRFN = ReadFixedString f 4
	prfnLength = readlong f
	prfnName = readstring f
	print prfnName
	format "\n"
	

-- 	fseek f backJump #seek_set
	
	if prfnName == "Mesh" do (
		fseek f meshOffset #seek_set
		
-- 		print prfnName
-- 		Print ("Here @ 0x"+((bit.intAsHex(ftell f))as string))
-- 		format "\n"
		j=0
		do (
			Msh_Vert_array = #()
			Msh_Normal_array = #()
			Msh_UV_array = #()
			Msh_Face_array = #()
			MshVertexCount = 0
			
-- 			Print ("Mesh @ 0x"+((bit.intAsHex(ftell f))as string))
				
			_MESH = ReadFixedString f 4
			addto = ftell f
			meshLength = readlong f
			nextMESH = (meshLength+addto)
			
			MSHH = ReadFixedString f 4
			mshhLength = readlong f
			fseek f (mshhLength-4) #seek_cur
			
-- 			format "\n"
			
			do (
				Vert_array=#()
				UV_array=#()
				Face_array=#()
				
-- 				Print ("Submesh starts @ 0x"+((bit.intAsHex(ftell f))as string))
				
				SMSH = ReadFixedString f 4
				addto = ftell f
				smshLength = readlong f
				
				MHDR = ReadFixedString f 4
				addto = ftell f
				mhdrLength = readlong f
				vertOffset = (mhdrLength+addto)
				
				_4 = readbyte f
				vertCount = readshort f #unsigned
				faceCount = readshort f #unsigned
				fseek f 0x3b #seek_cur
				vertSize = readshort f
				
-- 				Print ("verts @ 0x"+((bit.intAsHex(ftell f))as string))
-- 				Print ("0x"+((bit.intAsHex(vertSize))as string))
				
				fseek f vertOffset #seek_set
				MVTX = ReadFixedString f 4
				addto = ftell f
				mvtxLength = readlong f
				faceOffset = (mvtxLength+addto)
				
				for x=1 to vertCount do (
					vx = ReadHalfFloat f
					vy = ReadHalfFloat f
					vz = ReadHalfFloat f
					fseek f (vertSize-6) #seek_cur
					
					append Vert_array([vz,-1*vx,vy]*fscale)
					append UV_array([0,0,0])
				)
				
-- 				if vertSize == 0xe do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0x8 #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x11 do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0xb #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x12 do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0xc #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x14 do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0xe #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x16 do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0x10 #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x17 do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0x11 #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x19 do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0x13 #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x1b do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0x15 #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				if vertSize == 0x1f do (
-- 					for x=1 to vertCount do (
-- 						vx = ReadHalfFloat f
-- 						vy = ReadHalfFloat f
-- 						vz = ReadHalfFloat f
-- 						fseek f 0x19 #seek_cur
-- 						
-- 						append Vert_array([vz,-1*vx,vy]*fscale)
-- 						append UV_array([0,0,0])
-- 					)
-- 				)
-- 				Print ("verts ends @ 0x"+((bit.intAsHex(ftell f))as string))
				
				fseek f faceOffset #seek_set
-- 				Print ("faces starts @ 0x"+((bit.intAsHex(ftell f))as string))
				MIDX = ReadFixedString f 4
				addto = ftell f
				midxLength = readlong f
				faceEnd = (midxLength+addto)
				for y=1 to faceCount/3 do(
					fa=ReadShort f #unsigned +1
					fb=ReadShort f #unsigned +1
					fc=ReadShort f #unsigned +1
					append Face_array[fa,fc,fb]
				)
				fseek f faceEnd #seek_set
-- 				Print ("faces ends @ 0x"+((bit.intAsHex(ftell f))as string))
				
				for i = 1 to Face_array.count do (
					vertices = Face_array[i]
					append Msh_Face_array [vertices[1] + MshVertexCount, vertices[2] + MshVertexCount, vertices[3] + MshVertexCount]
				)
				
				MshVertexCount += Vert_array.count
				for i = 1 to Vert_array.count do (
					append Msh_Vert_array vert_array[i]
-- 					append Msh_Normal_array normal_array[i]
					append Msh_UV_array UV_array[i]
				)
				
-- 				if vertSize == 0x19 do (
-- 					msh = mesh vertices:Vert_array faces:Face_array
-- 					msh.numTVerts = UV_array.count
-- 					msh.wirecolor = random black white
-- 					buildTVFaces msh
-- 					msh.name = (bit.intashex(vertSize) as string)
-- 					for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
-- 					for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
-- 				)
				
				
-- 				Print ("Submesh ends @ 0x"+((bit.intAsHex(ftell f))as string))
				test = readshort f
				if test != 0 do (fseek f -2 #seek_cur)
				
				test2 = readlong f #unsigned
				if test2 == 0x4C41504D then (		--MPAL
-- 					print "MPAL"
					fseek f ((readlong f)-4) #seek_cur
				)
				else (fseek f -4 #seek_cur)
			)
			while ((ftell f)<nextMESH)
			
				msh = mesh vertices:Msh_Vert_array faces:Msh_Face_array
				msh.numTVerts = Msh_UV_array.count
				msh.wirecolor = random black white
				msh.backfacecull = off
				msh.name = ((bit.intashex(vertSize) as string)+"_"+j as string)
				buildTVFaces msh    
				for j = 1 to Msh_UV_array.count do setTVert msh j Msh_UV_array[j]
				for j = 1 to Msh_Face_array.count do setTVFace msh j Msh_Face_array[j]
			j+=1
			
-- 			format "\n"
		)
		while ((ftell f)<nextProf-0x10)
		
-- 		Print ("Ends @ 0x"+((bit.intAsHex(ftell f))as string))
	)
	
	fseek f nextProf #seek_set
)
while ((ftell f)<fileEnd)




Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

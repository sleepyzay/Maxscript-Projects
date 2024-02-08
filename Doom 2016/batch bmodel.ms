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

itemArr=#()

clearlistener()
browse_dialog = dotNetObject "System.Windows.Forms.OpenFileDialog"
browse_dialog.Multiselect = true
browse_dialog.Filter = "(.bmodel;model)|*.bmodel*"
result = browse_dialog.showDialog()
if (result.Equals result.OK) do (
	join itemArr browse_dialog.fileNames
-- 	delete $*
)
for a=1 to itemArr.count do (
	If (itemArr[a]!=undefined) and ((DoesFileExist itemArr[a])==true) then (
		f = fopen itemArr[a] "rb"
		FileExtension = getFileNameType  itemArr[a]
		FileName = getFileNameFile itemArr[a]
		clearlistener()
		Global fscale=5
		
		LMBU = ReadFixedString f 8
		meshCount = readbelong f	-- count?
		
		for x=1 to meshCount do (
			Face_array=#()
			Vert_array=#()
			Normal_array=#()
			UV_array=#()
			
			stringLength = readlong f
			ReadFixedString f stringLength

			ukw2 = readbelong f
			fseek f 0xc #seek_cur
			vertCount = readbelong f
			faceCount = readbelong f
			fseek f 0x2c #seek_cur

			for x=1 to vertCount do (
				vx = ReadBEfloat f 
				vy = ReadBEfloat f
				vz = ReadBEfloat f
				tu = ReadBEfloat f
				tv = ReadBEfloat f
				
				fseek f 0x1c #seek_cur
				
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
			)
			for x=1 to FaceCount/3 do(
				fa=ReadBEShort f +1
				fb=ReadBEShort f +1
				fc=ReadBEShort f +1
				append Face_array[fa,fc,fb]
			)

			msh = mesh vertices:Vert_array faces:Face_array 
			msh.numTVerts = UV_array.count
			buildTVFaces msh
			for j = 1 to UV_array.count do setTVert msh j UV_array[j]
			for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
			-- ApplyNormals msh Normal_array

			fseek f 0x1c #seek_cur
			LMB = ReadFixedString f 4
		)
		
		gc()
		fclose f
	)
)
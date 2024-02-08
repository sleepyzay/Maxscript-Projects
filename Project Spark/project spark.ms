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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
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
fn signVal x size= (
	if (bit.get x size) do (
		bitMask = 0
		for i=1 to size do bitMask = bit.set bitMask i true
		
		x = bit.xor x bitMask
		x += 1	--because of 2's complement
		x *= -1
	)
	return x
)
fn readbits pos range num = (
	local i = 0, result = 0, c = 1
	local val = num
	for i = pos to ((pos - 1) + range) do (
		result = bit.set result c (bit.get val i);c+=1
		)
	result
)
fn get32bitNormal format divisor val = (
	result = [0,0,0]
	pos = 1
	for x=1 to 3 do (
		result[x] = (readBits pos format[x] val)
		pos+=format[x]
	)
	result/=divisor
)
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
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

struct weight_data (
	boneids,weights
)

fn readModel fstream fscale= (
	startByte = readbyte fstream #unsigned	--0x0c
	AlignOffset fstream (ftell fstream) 4
	chunkTag = readlong fstream #unsigned	--0x00B0FFB0
	chunkID = reverseString (ReadFixedString fstream 4)
	chunkSize = readlong fstream
	chunkEnd = ((ftell fstream) - 0x0c) + chunkSize + 1	-- + 1 because of endByte
	
	case chunkID of (
		
		"COOK":(
			while (ftell fstream) < chunkEnd - 1 do (
				readModel fstream fscale
			)
			endByte = readbyte fstream #unsigned	--0x0d
		)
		
		"ASNM":(	--hkt
			NMSZ = ReadFixedString fstream 4
			ukw = readbyte fstream
			stringLength = readlong fstream
			
			NMDT = ReadFixedString fstream 4
			ukw2 = readbyte fstream
			stringLength2 = readlong fstream	--same as stringLength
			filePath = ReadFixedString fstream stringLength
			endByte = readbyte fstream
		)
		
		"PHYS":(	--hkt
			fseek fstream chunkEnd #seek_set
		)
		
		"ANIM":(	--hkt
			fseek fstream chunkEnd #seek_set
		)
		
		"MDAT":(
			HEAD = readstring fstream
			headerLength = readlong fstream
			matCount = readlong fstream
			meshCount = readlong fstream
			vertLength = readlong fstream
			faceLength = readlong fstream
			boneCount = readlong fstream
			fseek fstream 0x18 #seek_cur	-- bb info
			
			if skelPresent() do (
				rootBone = $master
-- 				rootBone.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
-- 				rootBone.scale *= fscale
			)
			
			_MESH = readstring fstream
			meshHeaderLength = readlong fstream
			fseek fstream meshHeaderLength #seek_cur	--mat info
			
			GEOM = readstring fstream
			geomHeaderLength = readlong fstream
			
			vertCount=#()
			vertStride=#()
			faceCount=#()
			for x=1 to meshCount do (
				null = readlong fstream
				vertCount[x] = readlong fstream
				vertStride[x] = readlong fstream
				faceCount[x] = readlong fstream
				primitiveType = readlong fstream
			)
			
			VERT = readstring fstream
			vertBufferLength = readlong fstream
			vertOffset = ftell fstream
			faceOffset = (((ftell fstream) + vertBufferLength) + 9)
			
			for x=1 to meshCount do (
				Vert_array=#()
				UV_array=#()
				Face_array=#()
				Normal_array=#()
				Weight_array=#()
				
				fseek fstream vertOffset #seek_set			
				if vertStride[x] == 0x1c do (
					for y=1 to vertCount[x] do (
						w = (weight_data boneids:#() weights:#())
						
						vx = ReadHalfFloat fstream
						vy = ReadHalfFloat fstream
						vz = ReadHalfFloat fstream
						vw = ReadHalfFloat fstream
						normals = ((get32bitNormal [10,10,10] 1023.0 (readlong fstream)) * 2 - 1)
						tangents = ((get32bitNormal [10,10,10] 1023.0 (readlong fstream)) * 2 - 1)
						tu = ReadHalfFloat fstream
						tv = ReadHalfFloat fstream
						weight1 = readbyte fstream #unsigned
						weight2 = readbyte fstream #unsigned
						weight3 = readbyte fstream #unsigned
						weight4 = readbyte fstream #unsigned
						bone1 = readbyte fstream #unsigned
						bone2 = readbyte fstream #unsigned
						bone3 = readbyte fstream #unsigned
						bone4 = readbyte fstream #unsigned
							
-- 						format "% % % %\n" weight1 weight2 weight3 weight4
-- 						format "% % % %\n" bone1 bone2 bone3 bone4
-- 						format "\n"
-- 							
						
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
						
						
						append Vert_array ([vx,vy,vz]*fscale)
						append Normal_array normals
						append UV_array([tu,1-tv,0])
		 				append Weight_array w
					)
				)
				if vertStride[x] == 0x14 do (
					for y=1 to vertCount[x] do (
						vx = ReadHalfFloat fstream
						vy = ReadHalfFloat fstream
						vz = ReadHalfFloat fstream
						vw = ReadHalfFloat fstream
						normals = ((get32bitNormal [10,10,10] 1023.0 (readlong fstream)) * 2 - 1)
						tangents = ((get32bitNormal [10,10,10] 1023.0 (readlong fstream)) * 2 - 1)
						tu = ReadHalfFloat fstream
						tv = ReadHalfFloat fstream
						append Vert_array ([vx,vy,vz]*fscale)
						append Normal_array normals
						append UV_array([0,0,0])
					)
				)
				vertOffset = ftell fstream
				
				fseek fstream faceOffset #seek_set
				for y=1 to faceCount[x]/3 do(
					fa=ReadShort fstream #unsigned +1
					fb=ReadShort fstream #unsigned +1
					fc=ReadShort fstream #unsigned +1
					append Face_array[fa,fb,fc]
				)
				faceOffset = ftell fstream
				
				msh = mesh vertices:Vert_array faces:Face_array
				msh.numTVerts = UV_array.count
				msh.wirecolor = random black white
				buildTVFaces msh
				msh.name = (vertStride[x] as string)
				for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
				for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
				for j = 1 to Normal_array.count Do setNormal msh j Normal_array[j]
					
				if skelPresent() then msh.transform = rootBone.transform
				else msh.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
				
				if (skelPresent() and vertStride[x] != 0x14) do (		
					allBones = for o in geometry where classOf o == boneGeometry collect o					
					
					-- Applying Skinning --
					max modify mode
					select msh
					skinMod = skin ()
					addModifier msh skinMod
					for i = 1 to allBones.count do (
						maxbone = getnodebyname allBones[i].name
						if i != allBones.count then
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
			
			SK2M = readstring fstream
			skelBufferLength = readlong fstream			
			BNArr = #()
			for x=1 to boneCount do (
				m11 = readfloat fstream; m12 = readfloat fstream; m13 = readfloat fstream; m14 = readfloat fstream
				m21 = readfloat fstream; m22 = readfloat fstream; m23 = readfloat fstream; m24 = readfloat fstream
				m31 = readfloat fstream; m32 = readfloat fstream; m33 = readfloat fstream; m34 = readfloat fstream
				m41 = readfloat fstream; m42 = readfloat fstream; m43 = readfloat fstream; m44 = readfloat fstream
-- 				tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
-- 				
-- 		 		newBone = bonesys.createbone	\
-- 				tfm.row4	\
-- 				(tfm.row4 + 0.01 * (normalize tfm.row1)) \
-- 				(normalize tfm.row3)
-- 				newBone.width = 0.1
-- 				newBone.height = 0.1
-- 				newBone.wirecolor = yellow
-- 				newbone.showlinks = true
-- 				newBone.transform = tfm
-- 				
-- 				pos = [m41,m42,m43]
-- 				pos *= tfm
-- 				newBone.pos += (fscale*pos)
-- 				
-- 		 		newBone.setBoneEnable false 0
-- 		 		newBone.pos.controller = TCB_position ()
-- 		 		newBone.rotation.controller = TCB_rotation ()
				
-- 				if parentIDArr[x] != -1 do (
-- 					newBone.parent = BNArr[parentIDArr[x] + 1]
-- 				)
-- 				
-- 		 		append BNArr newBone
			)
-- 			rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
-- 			for b in BNArr where b.parent==undefined do b.parent = rootRT
-- 			rootRT.transform = (matrix3 [-1,0,0] [0,0,-1] [0,-1,0] [0,0,0])
			
			endByte = readbyte fstream #unsigned		--0x0d
		)
		
		"MAPR":(	--hkt
			fseek fstream chunkEnd #seek_set
		)
		
		"HIDE":(
			while (ftell fstream) < chunkEnd - 1 do (
				readModel fstream fscale
			)
			endByte = readbyte fstream #unsigned		--0x0d
		)
		
		"BBOX":(
			BMIN = ReadFixedString fstream 4
			ukw = readbyte fstream
			bminLength = readlong fstream
			BBMin = ([(readfloat fstream),(readfloat fstream),(readfloat fstream)]*fscale)
			
			BMAX = ReadFixedString fstream 4
			ukw = readbyte fstream
			bmaxLength = readlong fstream
			BBMax = ([(readfloat fstream),(readfloat fstream),(readfloat fstream)]*fscale)
			
			NUMF = ReadFixedString fstream 4	--numFloats?
			ukw = readbyte fstream
			ukwDataCount = readlong fstream
			
-- 			printHex ukw
-- 			printHex ukwDataCount
-- 			printHere fstream
			
			FLTS = ReadFixedString fstream 4	--floats?
			ukw = readbyte fstream
			ukwDataLength = readlong fstream
			ukwData = for x=1 to ukwDataCount collect readfloat fstream	--table
			printHex (ukwDataLength / ukwDataCount)
			
			endByte = readbyte fstream #unsigned		--0x0d
		)
		
		default:(
			format "unknown chunkID: %\n" chunkID
			exit
		)
		
	)
)

fname = GetOpenFileName caption:"Project Spark" types:"(.hkx)|*.hkx" historyCategory:""
-- fname=@"C:\Users\Xavier\Documents\stuff\projects\models\ripped\project spark\assets\conker_a\char_rig_conker_a.hkx"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=1
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readlong f
fileSize = readlong f
ukw = readlong f
readModel f fscale



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f

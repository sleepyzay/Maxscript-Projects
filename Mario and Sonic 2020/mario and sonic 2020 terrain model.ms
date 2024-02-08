--sleepyzay--

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
fn reverseString s = (
    local reversed = ""
    for i in s.count to 1 by -1 do reversed += s[i]
	reversed
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
fn getString bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn getOffset bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newOffset = readbelong f
	fseek bstream backJump #seek_set
	return newOffset
)
fn getVal bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newVal = readbelong f
	fseek bstream backJump #seek_set
	return newVal
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
		result[x] = signVal (readBits pos format[x] val) format[x]
		pos+=format[x]
	)
	result/=divisor
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
struct weight_data (
	boneids,weights
)
struct decTable (
	delimiter,
	offset,
	type,
	usage,
	usageIndex
)


fname = GetOpenFileName caption:"" types:" (*.)|*.terrain-model" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
reset
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)
st = timestamp()

multiLoad = false
if multiLoad == false do delete $*

fileSize = readbelong f
ukw = readbelong f
ukwTableOffset = readbelong f
ukwTableCount = readbelong f
ukwOffset = readbelong f

fseek f ukwTableOffset #seek_set		--skip to contexts
fseek f (readbelong f) #seek_set

ukwID = readbelong f
Contexts = ReadFixedString f 8
meshCount = readbelong f
meshDataOffset = readbelong f + 0x10
meshNameOffset = readbelong f + 0x10

matNameArr=#()
multiMat = multimaterial()
multiMat.numSubs = 0
if multiLoad == true then (
	if ((classOf (getMeditMaterial 1)) == Standardmaterial) then (	--if there is no multimaterial in this slot
		meditMaterials[1] = multiMat
	)
	else (
		multiMat = getMeditMaterial 1
		for a in multiMat do append matNameArr a.name
	)
)
else (
	meditMaterials[1] = multiMat
)

fseek f meshDataOffset #seek_set
meshOffset = for x=1 to meshCount collect readbelong f + 0x10
for x=1 to meshCount do (
	fseek f meshOffset[x] #seek_set
	format "mesh % @ 0x%\n" x (bit.intashex(meshOffset[x]))
	
	Msh_Vert_array = #()
	Msh_Normal_array = #()
	Msh_UV_array = #()
	Msh_MatID_array = #()
	Msh_Face_array = #()
	Msh_Weight_array = #()
	Msh_Color_array = #()
	vertSum = 0
	
	polyElmCount=#()
	polyElmDataOffset=#()
	
	for y=1 to 3 do (
		polyElmCount[y] = readbelong f
		polyElmDataOffset[y] = readbelong f + 0x10
		
		format "polygon element count: %\npolygon element data @ 0x%\n\n" polyElmCount[y] (bit.intashex(polyElmDataOffset[y]))
	)
	
	subMeshFlag = readbelong f		
	if subMeshFlag > 0 do (	--double pointers / may break, neever checked
		format "subMesh: % @ 0x%\n" (bit.intashex(subMeshFlag)) (bit.intashex(ftell f))
		
		subMeshName = getString f (getOffset f (readbelong f + 0x10) + 0x10)
		subMeshPolyElmCount = getVal f (getOffset f (readbelong f + 0x10) + 0x10)
		subMeshPolyElmDataOffset = getOffset f (readbelong f + 0x10) + 0x10
		
		append polyElmCount subMeshPolyElmCount
		append polyElmDataOffset subMeshPolyElmDataOffset
		
		format "polygon element count: %\npolygon element data @ 0x%\n\n" subMeshPolyElmCount (bit.intashex(subMeshPolyElmDataOffset))
	)
	
	for y=1 to polyElmDataOffset.count do (
		fseek f polyElmDataOffset[y] #seek_set
		
		polyElmOffset = for z=1 to polyElmCount[y] collect readbelong f + 0x10
		for z=1 to polyElmCount[y] do (
			Vert_array=#()
			UV_array=#()
			Face_array=#()
			Normal_array=#()
			Weight_array=#()
			boneMap_array=#()
			Color_array=#()
			MatID_array=#()
			elmArr=#()
			blendIndicesArray=#()
			blendWeightArray=#()
			
			fseek f polyElmOffset[z] #seek_set
			matName = getString f (readbelong f + 0x10)
			faceCount = readbelong f
			faceOffset = readbelong f + 0x10
			vertCount = readbelong f
			vertSize = readbelong f
			vertOffset = readbelong f + 0x10
			vertDecTable = readbelong f + 0x10
			boneMapCount = readbelong f
			boneMapOffset = readbelong f + 0x10
			matCount = readbelong f
			matOffset = readbelong f + 0x10
			
			appendIfUnique matNameArr matName
			matID = (FindItem matNameArr matName )
			if (multiMat[matID] == undefined) do multiMat.numSubs += 1
			multiMat[matID].name = matName
			multiMat.materialList[matID].Diffuse = random black white
			
			fseek f boneMapOffset #seek_set
			boneMap = for a=1 to boneMapCount collect readbyte f #unsigned + 1
			
			fseek f vertDecTable #seek_set
			do (
				append elmArr (
					vertElm = (decTable	\ 
						delimiter: (readbeshort f)	\
						offset: (readbeshort f)	\
						type: (readbelong f)	\
						usage: (readbeshort f)	\
						usageIndex: (readbeshort f)	\
					)
				)
			)
			while (vertElm.delimiter != 255)
			
			fseek f faceOffset #seek_set
			for b=1 to (faceCount/3) do (
				fa = readbeword f + 1
				fb = readbeword f + 1
				fc = readbeword f + 1
				
				append Face_array [fa,fc,fb]
				append Msh_Face_array ([fa,fc,fb]+vertSum)
				
				append MatID_array matID
				append Msh_MatID_array matID
			)
			
			fseek f vertOffset #seek_set
			for a=1 to vertCount do (
				vertRef = ftell f
				for b=1 to (elmArr.count - 1) do (
					vertElm = elmArr[b]
					fseek f (vertElm.offset + vertRef) #seek_set
					case vertElm.usage of (
						0x00:(		--position
							vx = readbefloat f
							vy = readbefloat f
							vz = readbefloat f
							
							append Vert_array([vx,vy,vz]*fscale)
							append Msh_Vert_array([vx,vy,vz]*fscale)
						)
						0x01:(		--blend weight
							weight1 = readbyte f #unsigned
							weight2 = readbyte f #unsigned
							weight3 = readbyte f #unsigned
							weight4 = readbyte f #unsigned
							
							append blendWeightArray [weight1,weight2,weight3,weight4]
						)
						0x02:(		--blend indices
							bone1 = readbyte f #unsigned + 1
							bone2 = readbyte f #unsigned + 1
							bone3 = readbyte f #unsigned + 1
							bone4 = readbyte f #unsigned + 1
							
							append blendIndicesArray [bone1,bone2,bone3,bone4]
						)
						0x03:(		--normals
							if vertElm.type == 0x002A2187 do (
								normals = (get32bitNormal [10,10,10] 511 (readbelong f))
								
								append Normal_array normals
								append Msh_Normal_array normals
							)
							if vertElm.type == 0x002A2190 do (
								normals = (get32bitNormal [11,11,10] [1023,1023,511] (readbelong f))
								
								append Normal_array normals
								append Msh_Normal_array normals
							)
							if vertElm.type == 0x002A23B9 do (
								nx = readbefloat f
								ny = readbefloat f
								nz = readbefloat f
								
								append Normal_array [nx,ny,nz]
								append Msh_Normal_array [nx,ny,nz]
							)
						)
						0x05:(		--tex coords
							if vertElm.usageIndex == 0 do (
								if vertElm.type == 0x002C235F do (	--FLOAT16_2
									tu = ReadBEHalfFloat f
									tv = ReadBEHalfFloat f
									
									append UV_array([tu,-tv,0]*2)
									append Msh_UV_array([tu,-tv,0]*2)
								)
								if vertElm.type == 0x002C23A5 do (	--FLOAT2
									tu = ReadBEfloat f
									tv = ReadBEfloat f
									
									append UV_array([tu,-tv,0]*2)
									append Msh_UV_array([tu,-tv,0]*2)
								)
							)
						)
						0x06:(		--tangents
							tangents = readbelong f
						)
						0x07:(		--binormals
							binormals = readbelong f
						)
						0x0a:(		--colors
							a = readByte f #unsigned
							r = readByte f #unsigned
							g = readByte f #unsigned
							b = readByte f #unsigned
							
							append Color_array (color r g b a)
							append Msh_Color_array (color r g b a)
						)
						default:(
							format "Unknown vertex decleration type: %\n\n" vertElm.type
							exit
						)
					)
				)
			)
			vertSum += vertCount
			
-- 			msh = mesh vertices:Vert_array faces:Face_array materialIDs:MatID_array
-- 			msh.numTVerts = UV_array.count
-- 			msh.wirecolor = random black white
-- 			msh.name = matName
-- 			msh.material = multiMat
-- 			buildTVFaces msh
-- 			defaultVCFaces msh
-- 			setShadeCVerts msh true
-- 			for j = 1 to UV_array.count do setTVert msh j UV_array[j]
-- 			for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
-- 			for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
-- 			for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
-- 			msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		)
	)
	
	msh = mesh vertices:Msh_Vert_array faces:Msh_Face_array materialIDs:Msh_MatID_array
	msh.numTVerts = Msh_UV_array.count
	msh.mat = multiMat
	buildTVFaces msh
	defaultVCFaces msh
	setShadeCVerts msh true
-- 	setCVertMode msh true
	for j = 1 to Msh_UV_array.count do setTVert msh j Msh_UV_array[j]
	for j = 1 to Msh_Face_array.count do setTVFace msh j Msh_Face_array[j]
	for j = 1 to Msh_Normal_array.count do setNormal msh j Msh_Normal_array[j]
	for j = 1 to Msh_Color_array.count do (
		setVertColor msh j Msh_Color_array[j]
-- 		meshop.setVertAlpha msh -2 j Msh_Color_array[j].a	--crashes my whole computer lol
	)
	msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
)

et = timestamp()
format "Processing took % seconds\n" ((et - st) / 1000.0)
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
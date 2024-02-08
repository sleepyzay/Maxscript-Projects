--sleepyzay--

fn ReadBEHalfFloat fstream = (
hf=bit.swapBytes (readshort fstream #unsigned) 1 2
sign = bit.get hf 16
exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
fraction = bit.and hf (bit.hexasint "03FF")
if sign==true then sign = 1 else sign = 0
exponentF = exponent + 127
outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
(bit.shift exponentF 23)) (bit.shift sign 31)
return bit.intasfloat outputasfloat*2
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
	
	bb = box()
	bb.width = abs(currA[1])
	bb.length = abs(currA[2])
	bb.height = abs(currA[3])
-- 	hide bb
	delete bb
)
fn GetName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
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


fname = GetOpenFileName caption:"" types:" (*.)|*.tpr" historyCategory:""
-- fname=@"E:\models\ripped\doa4\chrthree_files\0030_spa00.tpr"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct dataTable (
	dataType = ReadFixedString f 4,
	dataOffset = readbelong f + 0x0c,
	dataLength = readbelong f,
	dataVal = readbelong f
)
struct dataHeader (
	offset = ftell f,
	type = ReadFixedString f 8,
	ukw = readbeshort f,		--0xff00
	ukw2 = readbeshort f,	--0x0100
	headerLength = readbelong f,
	length = readbelong f,
	dataCount = readbelong f,
	dataCount2 = readbelong f,
	null = readbelong f,
	tableOffset = readbelong f,
	null2 = readbelong f,
	subDataOffset = readbelong f,
	null3 = readbelong f
)
struct decTable (
	delimeter = readbeshort f,
	offset = readbeshort f,
	type = readbelong f,
	usage = readbeshort f,
	usageIndex = readbeshort f
)
struct bufferTable (
	ukw = readbeshort f,		--0x01/0x02/0x03, bufferID?
	ukw2 = readbeshort f,	--0x01
	null = readbeshort f,
	null2 = readbyte f,
	ukw3 = readbelong f,		--0x00ffff00
	bufferOffset = readbelong f * 0x100,
	ukw4 = readbyte f,		--if vbuf 3 else 0
	bufferLength = readbelong f
)

fn parseSkeleton Hie = (
	BNArr=#()
	parentIDArray=#()
	childIDArray=#()
	boneIDArray=#()
	
	fseek f (Hie.tableOffset + Hie.offset) #seek_set
	HieOffsetArray = for x=1 to Hie.dataCount collect (readbelong f + Hie.offset)
	for x=1 to Hie.dataCount do (
		fseek f HieOffsetArray[x] #seek_set
		m11 = ReadBEfloat f; m12 = ReadBEfloat f; m13 = ReadBEfloat f; m14 = ReadBEfloat f
		m21 = ReadBEfloat f; m22 = ReadBEfloat f; m23 = ReadBEfloat f; m24 = ReadBEfloat f
		m31 = ReadBEfloat f; m32 = ReadBEfloat f; m33 = ReadBEfloat f; m34 = ReadBEfloat f
		m41 = ReadBEfloat f; m42 = ReadBEfloat f; m43 = ReadBEfloat f; m44 = ReadBEfloat f
		tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
		--skeleton contains no rotation data only position, ^ same as tfm = matrix3 [1,0,0] [0,1,0] [0,0,1] [m41,m42,m43]

		boneIDArray[x] = readbeshort f + 1
		parentIDArray[boneIDArray[x]] = readbeshort f + 1
		childIDArray[boneIDArray[x]] = for y=1 to (readbeshort f) collect (readbeshort f)
		
		newBone = bonesys.createbone	\
		tfm.row4	\
		(tfm.row4 + 0.01 * (normalize tfm.row1)) \
		(normalize tfm.row3)
		newBone.width = 0.01
		newBone.height = 0.01
		newBone.wirecolor = yellow
		newbone.showlinks = true
		newBone.transform = tfm
		newBone.pos *= fscale
		newBone.setBoneEnable false 0
		newBone.pos.controller = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()
		
		BNArr[boneIDArray[x]] = newBone
	)
	for x in boneIDArray do (			--fuck this skeleton format
		b = BNArr[x]
		if (parentIDArray[x] != 0) then (
			b.parent = BNArr[boneIDArray[parentIDArray[x]]]
			b.transform *= b.parent.transform
		)
	)
	for b in BNArr where b.parent==undefined do b.transform *= (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])	--for some reason the skeletons are misaligned btw eachother
	for b in BNArr do b.setskinpose()
	
	return BNArr
)

XPR2 = dataTable()
tableArray = for x=1 to XPR2.dataVal collect (ReadFixedByteString f 0x10 1 0; table = dataTable())
	
VBUFArray=#()
IBUFArray=#()
TX2DArray=#()

for table in tableArray do (
	fseek f table.dataOffset #seek_set
	case table.dataType of (
		"USER":()
		"TX2D":(
			ReadFixedByteString f 0x28 1 0
-- 			append TX2DArray (t = bufferTable())	--struct dosent perfectly fit this but I don't care I don't think I'm using this
		)
		"VBUF":(
			ReadFixedByteString f 0x14 1 0
			append VBUFArray (v = bufferTable())
		)
		"IBUF":(
			ReadFixedByteString f 0x14 1 0
			append IBUFArray (i = bufferTable())
		)
		default:(
			format "unknown dataType: %\n" (table.dataType)
		)
	)
)

-- for x=1 to VBUFArray.count do (format "% %\n" (bit.intashex(x as integer)) (bit.intashex((VBUFArray[x].bufferOffset) as integer)))

--model info
fseek f tableArray[1].dataOffset #seek_set
ukw = readbelong f				--0x07
ukw2 = readbelong f				--0x04 / USERCount?
TX2DCount = readbelong f
ukw4 = readbelong f				--0x04
VBUFCount = readbelong f
ukw6 = readbelong f				--matcount? / always 4 more than tx2dcount
IBUFCount = readbelong f		--total sum of GeoDecl.dataCount / meshCount?
ukwCount = readbelong f		--total sum of ObjInfo.dataCount / ObjGeo.dataCount (not division) / objCount? / subMeshCount?
ukw9 = readbelong f				--0x01
ukw10 = readbelong f			--0x02
ukw11 = readbelong f			--0x03
ukw12 = readbelong f			--0x10

format "ukw: 		%	ukw2: %		TX2DCount: %	ukw4: 		%	\n" (bit.intashex(ukw)) (bit.intashex(ukw2)) (bit.intashex(TX2DCount)) (bit.intashex(ukw4))
format "VBUFCount: %	ukw6: %	IBUFCount: %	ukwCount:	%\n	" (bit.intashex(VBUFCount)) (bit.intashex(ukw6)) (bit.intashex(IBUFCount)) (bit.intashex(ukwCount))   

--MdlInfo
--	ObjInfo
--		ukwObjInfoData / infoDecl?
--MdlGeo
--	ObjGeo
--		GeoDecl

boneMapArray=#()
fseek f tableArray[3].dataOffset #seek_set
MdlInfo = dataHeader()
fseek f (MdlInfo.tableOffset + MdlInfo.offset) #seek_set
ObjInfoOffsetArray = for x=1 to MdlInfo.dataCount collect (readbelong f + MdlInfo.offset)
for x=1 to MdlInfo.dataCount do (
	fseek f ObjInfoOffsetArray[x] #seek_set
	ObjInfo = dataHeader()
	
	ukw = readbeshort f		--1
	ukw2 = readbeshort f		--1
	ObjInfoIndex = readbelong f
	null = readbelong f
	boneMapCount = readbelong f
	ukw3 = readbelong f		--1
	null2 = readbelong f
	null3 = readbelong f
	ukw4 = readbelong f		--0x02/0x08/0x0a, mostly 0x02
	ukw5 = readbelong f		--0x00/0x01,  only 1st is 1
	null4 = readbelong f
	null5 = readbelong f
	null6 = readbelong f
	fseek f 0x30 #seek_cur	--matrix
	boneMapArray[x] = for y=1 to boneMapCount collect (readbeshort f + 1)	--padding after
	
	fseek f (ObjInfo.tableOffset + ObjInfo.offset) #seek_set
	ukwObjInfoOffsetArray = for y=1 to ObjInfo.dataCount collect (readbelong f + ObjInfo.offset)	--related to ObjGeo.data
	for y=1 to ObjInfo.dataCount do (		--matrial / transform?
		fseek f ukwObjInfoOffsetArray[y] #seek_set
		ReadFixedByteString f 0x50 1 0
		
		ukwObjInfoIndex = readbelong f
		ukw = readbelong f						--0x01
		ukw2 = readbelong f						--0x02/0x08, mostly 0x02
		null = readbelong f
		ukw3 = readbelong f						--0x00/0x01, mostly 0x00
		null2 = readbelong f
		null3 = readbelong f
		null4 = readbelong f
		fseek f 0x30 #seek_cur					--matrix
	)
	--format "\n"
)
format "\n"

--skeleton
fseek f tableArray[4].dataOffset #seek_set
Hie = dataHeader()
Bnarr = parseSkeleton Hie

fseek f tableArray[2].dataOffset #seek_set
MdlGeo = dataHeader()

struct _polyElm (
	polyElmIndex = readbelong f,		--resets per ObjGeo
	null = readbelong f,
	GeoDeclDataID = readbelong f,	--0/1/2/3, mostly 0, meshID?
	null2 = readbelong f,
	
	polyElmOffset = readbelong f,
	polyElmLength = readbelong f,
	
	ukwDataCount = readbelong f,	--texCount?, I'm guessing the game has it set up so each polyElm has it's own individual material and not refrencing from one
	ukwDataOffset = readbelong f,	--tableOffset?
	ukwDataOffset2 = readbelong f,	--matrix
	ukwDataOffset3 = readbelong f,	--0x10 bytes long
	
	null3 = readbelong f,
	null4 = readbelong f,
	ukw6 = readbelong f,					--0x01/0x04/0x07/0x0c/0x20/0x34, lodID? higher the number the higher the quality of mesh
	ukw7 = readbelong f,					--0x00/0x01, mostly 0x01
	null5 = readbelong f,
	ukw8 = readbelong f,					--0x01/0xff's, mostly 0xff's
	
	null6 = readbelong f,
	null7 = readbelong f,
	null8 = readbelong f,
	null9 = readbelong f,
	
	ukw9 = readbelong f,					--0x00/0x01, mostly 0x00
	ukw10 = readbelong f,				--0x01/0x06, mostly 0x06
	ukw11 = readbelong f,				--0x01/0x07, mostly 0x07
	
	null10 = readbelong f,
	null11 = readbelong f,
	null12 = readbelong f,
	
	ukw12 = readbelong f,				--0x01
	null13 = readbelong f,
	ukw13 = readbelong f,				--0x00/0x02, mostly 0x02
	
	null14 = readbelong f,
	null15 = readbelong f,
	null16 = readbelong f,
	
	ukw14,										--[1,1,1,0]				diffuse?
	ukw15,										--[0.5,0.5,0.5,0]		ambient?
	ukw16,										--[0.x,0.x,0.x,0]		specular?
	ukw17,										--[x,0,0,0]			specular level?
	
	ukw18										--[0,1,0,0]			emmisive?
)

unknownVertElmTypeArray=#()

fseek f (MdlGeo.tableOffset + MdlGeo.offset) #seek_set
ObjGeoOffsetArray = for x=1 to MdlGeo.dataCount collect (readbelong f + MdlGeo.offset)
for x=1 to MdlGeo.dataCount do (	--MdlGeo.dataCount
	fseek f ObjGeoOffsetArray[x] #seek_set
	ObjGeo = dataHeader()
	
	fseek f (ObjGeo.subDataOffset + ObjGeo.offset) #seek_set
	GeoDecl = dataHeader()
	
	polyElmArray=#()
	fseek f (ObjGeo.tableOffset + ObjGeo.offset) #seek_set
	polyElmOffsetArray = for y=1 to ObjGeo.dataCount collect (readbelong f + ObjGeo.offset)
	for y=1 to ObjGeo.dataCount do (
		fseek f polyElmOffsetArray[y] #seek_set
		ReadFixedByteString f 0x80 1 0
		polyElm = _polyElm()
		
		fseek f (polyElm.ukwDataOffset2 + polyElmOffsetArray[y]) #seek_set		--materialInfo?
		polyElm.ukw14 = [(readbefloat f),(readbefloat f),(readbefloat f),(readbefloat f)]
		polyElm.ukw15 = [(readbefloat f),(readbefloat f),(readbefloat f),(readbefloat f)]
		polyElm.ukw16 = [(readbefloat f),(readbefloat f),(readbefloat f),(readbefloat f)]
		polyElm.ukw17 = [(readbefloat f),(readbefloat f),(readbefloat f),(readbefloat f)]
 		
		fseek f (polyElm.ukwDataOffset3 + polyElmOffsetArray[y]) #seek_set		--right before ukwDataOffset
		if polyElm.ukwDataOffset3 != 0 do (
			polyElm.ukw18 = [(readbefloat f),(readbefloat f),(readbefloat f),(readbefloat f)]
		)
 		
 		fseek f (polyElm.ukwDataOffset + polyElmOffsetArray[y]) #seek_set
		for z=1 to polyElm.ukwDataCount do (
			ReadFixedByteString f 0x40 1 0
			ukwTableIndex = readbelong f
			ukwTableIndex2 = readbelong f
			ukwID = readbelong f	--references TX2D?
			null = readbelong f
			ukw = readbelong f	--0x00/0x01/0x06, mostly 0x00
			null2 = readbelong f
			null3 = readbelong f
			null4 = readbelong f
			null5 = readbelong f
			ukw2 = readbefloat f
			null6 = readbelong f
			null7 = readbelong f
			null8 = readbelong f
			null9 = readbelong f
			null10 = readbelong f
			null11 = readbelong f
		)
-- 		format "\n"
		
		append polyElmArray polyElm
	)
-- 	format "\n"
	
	fseek f (GeoDecl.tableOffset + GeoDecl.offset) #seek_set
	GeoDeclDataOffsetArray = for y=1 to GeoDecl.dataCount collect (readbelong f + GeoDecl.offset)
	for y=1 to GeoDecl.dataCount do (	--GeoDecl.dataCount
		Vert_Array=#()
		UV_Array=#()
		Face_Array=#()
		Normal_Array=#()
		Color_Array=#()
		BlendWeight_Array=#()
		
		fseek f GeoDeclDataOffsetArray[y] #seek_set
		ReadFixedByteString f 0x30 1 0
		vertDataOffset = readbelong f
		ukw = readbelong f		--0x01
		IBUFID = readbelong f
		faceCount = readbelong f
		vertElmCount = readbelong f
		vertCount = readbelong f
		uvChannelCount = readbelong f
		null2 = readbelong f
		ukwID = readbelong f	--0x00/0x01, hasMorphs?, means 2 additional VBUFID's, both always identical to first, additional VBUFID's are skipped
		null3 = readbelong f
		null4 = readbelong f
		null5 = readbelong f
		
		elmTable = for z=1 to vertElmCount collect (elm = decTable())
		
		fseek f (vertDataOffset + GeoDeclDataOffsetArray[y]) #seek_set
		VBUFID = readbelong f
		vertStride = readbelong f
		
-- 		format "%	%\n" VBUFID ukwID
		
		fseek f (VBUFArray[VBUFID + 1].bufferOffset + XPR2.dataOffset) #seek_set
		for z=1 to vertCount do (
			vertRef = ftell f
			for a=1 to vertElmCount - 1 do (
				vertElm = elmTable[a]
				fseek f (vertElm.offset + vertRef) #seek_set
				case vertElm.usage of (
					0x00:(		--position
						if vertElm.type == 0x002A23B9 do (	--float3
							vx = readbefloat f
							vy = readbefloat f
							vz = readbefloat f
							
							append Vert_Array([vx,vy,vz]*fscale)
						)
					)
					0x01:(		--blend weight
						blendWeight=#()
						if vertElm.type == 0x001A2360 do (	--half4
							if vertElm.usageIndex == 0 do (								
								weight1 = ReadBEHalfFloat f
								weight2 = ReadBEHalfFloat f
								weight3 = ReadBEHalfFloat f
								weight4 = ReadBEHalfFloat f
								
								if z < 10 do print (weight1 +weight2 + weight3 + weight4)
								
								blendWeight[1] = weight1
								blendWeight[2] = weight2
								blendWeight[3] = weight3
								blendWeight[4] = weight3
								
								
								--blendWeight[4] = weight4
								--format "%	%	%	%\n" weight1 weight2 weight3 weight4
							)
						)
						if vertElm.type == 0x002C23A5 do (	--float2	
							if vertElm.usageIndex == 0 do (
								weight1 = ReadBEFloat f
								weight2 = ReadBEFloat f
								
								blendWeight[1] = weight1
								blendWeight[2] = weight2
								--format "%	%\n" weight1 weight2
							)
						)
						if vertElm.type == 0x002A23B9 do (	--float3
							if vertElm.usageIndex == 0 do (
								weight1 = ReadBEFloat f
								weight2 = ReadBEFloat f
								weight3 = ReadBEFloat f
								
								blendWeight[1] = weight1
								blendWeight[2] = weight2
								blendWeight[3] = weight3
								--format "%	%	%\n" weight1 weight2 weight3
							)
						)
						
						append BlendWeight_Array blendWeight
					)
					0x03:(		--normals
						if vertElm.type == 0x002A23B9 do (	--float3
							nx = readbefloat f
							ny = readbefloat f
							nz = readbefloat f
							
							append Normal_Array [nx,ny,nz]
						)
						if vertElm.type == 0x002A2190 do (
							normals = (get32bitNormal [11,11,10] [1023,1023,511] (readbelong f))
							
							append Normal_array normals
						)
					)
					0x05:(		--tex coords
						if vertElm.type == 0x002C235F do (	--half2
							if vertElm.usageIndex == 0 do (	
								tu = ReadBEHalfFloat f
								tv = ReadBEHalfFloat f
								
								append UV_Array([tu,-tv,0])
							)
						)
						if vertElm.type == 0x002C23A5 do (	--float2
							if vertElm.usageIndex == 0 do (
								tu = ReadBEfloat f
								tv = ReadBEfloat f
								
								append UV_Array([tu,-tv,0])
							)
						)
					)
					0x06:(		--tangent, ignoring
					)
					0x0a:(		--colors
						if vertElm.type == 0x00182886 do (	--d3dcolor
							a = readByte f #unsigned
							r = readByte f #unsigned
							g = readByte f #unsigned
							b = readByte f #unsigned
							
							append Color_Array (color r g b a)	--emissive color?
						)
						
						if vertElm.type == 0x001A2360 do (	--half4
							a = ReadBEHalfFloat f
							r = ReadBEHalfFloat f
							g = ReadBEHalfFloat f
							b = ReadBEHalfFloat f
							
							append Color_Array (color r g b a)	--emissive color?
						)
						
					)
					default:(
						format "Unknown vertex usage: %\n\n" vertElm.usage
-- 						--exit
					)
				)
				if	vertElm.type != 0x002C235F and	--half2
					vertElm.type != 0x001A2360 and	--half4
					vertElm.type != 0x002C23A5 and	--float2
					vertElm.type != 0x002A23B9 and	--float3
					vertElm.type != 0x00182886 and 	--d3dcolor
					vertElm.type != 0x002A2190 do		--hend3n
				(
					appendifunique unknownVertElmTypeArray vertElm.type
				)
			)
			fseek f (vertRef + vertStride) #seek_set
		)
		
		for z=1 to ObjGeo.dataCount where y == (polyElmArray[z].GeoDeclDataID + 1) do (
			fseek f (IBUFArray[IBUFID + 1].bufferOffset + XPR2.dataOffset + (polyElmArray[z].polyElmOffset * 2)) #seek_set
			
			facecount = (polyElmArray[z].polyElmLength)
			facestart = (ftell f)
			StartDirection = -1
			f1 = (readbeword f) + 1
			f2 = (readbeword f) + 1  
			FaceDirection = StartDirection
			Do (
			f3 = (readbeword f)
			if (f3==0xFFFF) then (
			f1 = (readbeword f) + 1
			f2 = (readbeword f) + 1
			FaceDirection = StartDirection   
			) else (
			f3 += 1
			FaceDirection *= -1
			if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
			if FaceDirection > 0 then append Face_Array[f1,f2,f3]
			else append Face_Array [f1,f3,f2]
			)
			f1 = f2
			f2 = f3
			)  
			)while (ftell f) < (facestart + (facecount * 2))
		)
		
		if UV_Array.count == 0 do (for z=1 to Vert_Array.count do append UV_Array [0,0,0])
		
		msh = mesh vertices:Vert_Array faces:Face_Array
		msh.numTVerts = UV_Array.count
		msh.wirecolor = random black white
		msh.name = VBUFID as string
		buildTVFaces msh
-- 		defaultVCFaces msh
		for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
-- 		for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
		for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
		msh.parent = BNArr[x]
		msh.transform *= BNArr[x].transform
-- 		if Color_array.count > 0 do (setCVertMode msh true;setShadeCVerts msh false)
		
		if BlendWeight_Array.count > 0 do (
			-- Applying Skinning --
			count = msh.numverts
			max modify mode
			select msh
			skinMod = skin ()
			addModifier msh skinMod
			for i = 1 to boneMapArray[x].count do (
			   maxbone = getnodebyname BNArr[boneMapArray[x][i]].name
			   skinOps.addBone skinMod maxbone 1
			)
			-- Applying Weights --
			select msh
			modPanel.setCurrentObject skinMod
			for i = 1 to BlendWeight_Array.count do (
				w = BlendWeight_Array[i]
				bi = #() --bone index array
				wv = #() --weight value array
				
				for j = 1 to boneMapArray[x].count do
				(
					boneid = j
					weight = w[j]
					append bi boneid
					append wv weight
				)	
				
				skinOps.ReplaceVertexWeights skinMod i bi wv
			)
			deselect msh
		)
	)
	
	--format "\n"	
)
printHexArr unknownVertElmTypeArray 0



Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
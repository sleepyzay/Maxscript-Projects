--sleepyzay--

fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
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
   if var == 1 do fseek f -fixedLen #seek_cur
   if var2 == 1 do print str
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
fn ReadHalfFloat fstream = (
    hf=readshort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
return bit.intasfloat outputasfloat*2
)

struct weight_data (
	boneids,weights
)
struct _polyInfo (
	vertCount,
	vertOffset,
	vertSize,
	vertLength,
	faceCount,
	faceOffset,
	matID,
	polyID,
	boneID
)

fname = GetOpenFileName caption:"Halo Wars 2 Geometry" types:" (*.ugx)|*.ugx" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=25
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 4
tableOffset = readbelong f
ukw = readlong f
fileSize = readbelong f
tableCount = readbeshort f
null = readbeshort f
ukw2 = readbelong f

dataType=#()
dataOffset=#()
dataLength=#()
fseek f tableOffset #seek_set
for x=1 to tableCount do (
	null = readbelong f
	dataType[x] = readbelong f
	dataOffset[x] = readbelong f
	dataLength[x] = readbelong f
	ukw2 = for y=1 to 4 collect (readbeshort f)
	
-- 	printHex dataType[x]
-- 	printHex dataOffset[x]
-- 	printHex dataLength[x]
-- 	format "\n"
)

BNArr=#()
polyElmArr=#()
meshArr=#()
bbArr=#(#(),#())

vertStart = 0
faceStart = 0
matCount = 0
for x=1 to tableCount do (
	subDataOffset=#()
	subDataCount=#()
	
	fseek f dataOffset[x] #seek_set
	format "type: 0x% offset: 0x% \n"	(bit.intashex(dataType[x])) (paddstring 5 (bit.intashex(dataOffset[x])))
	
	-- model data --
	if dataType[x] == 0x700 do (
		subTableCount = readshort f
		ukw2 = readshort f
		null = readlong f
		fseek f 0x30 #seek_cur
		ukw = readlong f
		null = readlong f
		
		for y=1 to subTableCount do (
			subDataCount[y] = readlonglong f
			subDataOffset[y] = readlonglong f + dataOffset[x]
			format "% subDataCount: 0x% subDataOffset: 0x%\n" y (paddstring 2 (bit.intashex(subDataCount[y] as integer) )) (bit.intashex(subDataOffset[y] as integer))
			
			backJump = ftell f
			fseek f subDataOffset[y] #seek_set
			
			if y==1 do (
				for z=1 to subDataCount[y] do (
					polyInfo = _polyInfo()
					
					ReadFixedByteString f 0x40 1 1
					
					polyInfo.matID = readlong f + 1
					polyInfo.polyID = readlong f + 1
					ukwID = readlong f + 1
					polyInfo.boneID = readlong f+ 1	--some polygon elements are bound to a single bone
					polyInfo.faceOffset = readlong f
					polyInfo.faceCount = readlong f
					polyInfo.vertOffset = readlong f
					polyInfo.vertLength = readlong f
					polyInfo.vertSize = readlong f
					polyInfo.vertCount = readlong f
					lodID = readlong f
					lodMinDistance = readfloat f
					lodMaxDistance = readfloat f
					fseek f 0x14 #seek_cur
					
					if polyInfo.matID > matCount do matCount = polyInfo.matID
					if meshArr[polyInfo.polyID] == undefined do meshArr[polyInfo.polyID] = #()
					if lodMinDistance == 0 do append meshArr[polyInfo.polyID] polyInfo	--filters out everything but highest lod
-- 					if lodMinDistance == 0 and lodID == 0 do append meshArr[polyInfo.polyID] polyInfo	--filters out everything but highest lod
				)
			)
			if y==2 do (
				for z=1 to subDataCount[y] do (
					boneName = getName f (readlong f + dataOffset[x])
					null = readlong f
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [m14,m24,m34]	
					parentID = readlong f #unsigned + 1
					null = readlong f
					
					newBone = bonesys.createbone	\
					tfm.row4	\
					(tfm.row4 + 0.01 * (normalize tfm.row1)) \
					(normalize tfm.row3)
					newBone.width = 0.1
					newBone.height = 0.1
		 			newBone.wirecolor = white
					newbone.showlinks = false
					newBone.transform = tfm
					newBone.name = boneName
					
					pos = [m41,m42,m43]
					pos *= tfm
					newBone.pos += ((fscale)*-pos)
					
					newBone.setBoneEnable false 0
					newBone.pos.controller = TCB_position ()
					newBone.rotation.controller = TCB_rotation ()
 					
					if (parentID != 0) then (
					newBone.parent = BNArr[parentID]
				   )
 					
					append BNArr newBone
				)
				rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
				for b in BNArr where b.parent==undefined do b.parent = rootRT
				rootRT.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
				for z in BNArr do (z.setskinpose())
			)
			if y==3 do (
				
			)
			if y==4 do (
				
			)
			if y==5 do (
				
			)
			if y==6 do (
				
			)
			
			fseek f backJump #seek_set
		)
	)
	-- index data --
	if dataType[x] == 0x701 do (		
		faceStart = ftell f
	)
	-- vertex data --
	if dataType[x] == 0x702 do (
		vertStart = ftell f
	)
	format "\n"
)


mat = MultiMaterial numsubs:matCount showInViewport:true
meditMaterials[1] = mat
for x=1 to meshArr.count do (
	if ((meshArr[x] != undefined) and (meshArr[x].count > 0))do (
		Vert_Array=#()
		Face_Array=#()
		UV_Array=#()
		Normal_Array=#()
		Weight_Array=#()
		Mat_Array=#()
		
		vertBase = 0
		for a in meshArr[x] do (
			mat.materialList[a.matID].Diffuse = random black white
			mat.materialList[a.matID].specularLevel = 40
			mat.materialList[a.matID].glossiness = 30
			
			format "vertCount: 0x% vertSize: 0x%\n" (paddstring 4 (bit.intashex(a.vertCount)) as string) (bit.intashex(a.vertSize))
			
			--verts --
			fseek f (a.vertOffset + vertStart) #seek_set
			if a.vertSize == 0x08 do (
				for b=1 to a.vertCount do (
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([0,0,0])
				)
			)
			if a.vertSize == 0x14 do (
				for b=1 to a.vertCount do (
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					normals = readfloat f
					tangents = readfloat f
					
					bone1 = a.boneID
					weight1 = 1
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
					append Weight_array (w = (weight_data boneids:#(bone1) weights:#(weight1)))
				)
			)
			if a.vertSize == 0x18 do (
				for b=1 to a.vertCount do (
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					ukw = readfloat f
					ukw2 = readfloat f
					ukw3 = readfloat f
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
				)
			)
			if a.vertSize == 0x1c do (
				for b=1 to a.vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					normals = readfloat f
					tangents = readfloat f
					bone1 = readbyte f #unsigned 
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
					weight3 = readbyte f #unsigned
					weight4 = readbyte f #unsigned
					
					maxweight = 0
					if(bone1 != 0xFF) then
						maxweight = maxweight + weight1
					if(bone2 != 0xFF) then
						maxweight = maxweight + weight2
					if(bone3 != 0xFF) then
						maxweight = maxweight + weight3
					if(bone4 != 0xFF) then
						maxweight = maxweight + weight4
						
					if(maxweight != 0) then (
						mxw = 255.0
						if(weight1 != 0) then (
							w1 = weight1 as float
							append w.boneids (bone1+1)
							append w.weights (w1 / mxw)
						)
						if(weight2 != 0) then (
							w2 = weight2 as float
							append w.boneids (bone2+1)
							append w.weights (w2 / mxw)
						)
						if(weight3 != 0) then (
							w3 = weight3 as float
							append w.boneids (bone3+1)
							append w.weights (w3 / mxw)
						)
						if(weight4 != 0) then (
							w4 = weight4 as float
							append w.boneids (bone4+1)
							append w.weights (w4 / mxw)
						)		
					)
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
					append Weight_array w
				)
			)
			if a.vertSize == 0x20 do (
				for b=1 to a.vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					normals = readfloat f
					tangents = readfloat f
					bone1 = readbyte f #unsigned 
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
					weight3 = readbyte f #unsigned
					weight4 = readbyte f #unsigned
					null = readshort f
					ukw = readshort f	--always 0x87
					
					maxweight = 0
					if(bone1 != 0xFF) then
						maxweight = maxweight + weight1
					if(bone2 != 0xFF) then
						maxweight = maxweight + weight2
					if(bone3 != 0xFF) then
						maxweight = maxweight + weight3
					if(bone4 != 0xFF) then
						maxweight = maxweight + weight4
						
					if(maxweight != 0) then (
						mxw = 255.0
						if(bone1 != 0xFF) then (
							w1 = weight1 as float
							append w.boneids (bone1+1)
							append w.weights (w1 / mxw)
						)
						if(bone2 != 0xFF) then (
							w2 = weight2 as float
							append w.boneids (bone2+1)
							append w.weights (w2 / mxw)
						)
						if(bone3 != 0xFF) then (
							w3 = weight3 as float
							append w.boneids (bone3+1)
							append w.weights (w3 / mxw)
						)
						if(bone4 != 0xFF) then (
							w4 = weight4 as float
							append w.boneids (bone4+1)
							append w.weights (w4 / mxw)
						)		
					)
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
					append Weight_array w
				)
			)
			
			-- indices --
			fseek f ((a.faceOffset * 2) + faceStart) #seek_set
			for y=1 to a.faceCount do (
				fa = (ReadShort f #unsigned + 1) + vertBase
				fb = (ReadShort f #unsigned + 1) + vertBase
				fc = (ReadShort f #unsigned + 1) + vertBase
				
				append Face_Array[fa,fb,fc]
				append Mat_Array a.matID
			)
			
			vertBase += a.vertCount
		)
		
		msh = mesh vertices:Vert_array faces:Face_Array materialIDs:Mat_Array
		msh.numTVerts = UV_array.count
		msh.material = mat
		buildTVFaces msh
		for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
		msh.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		
		-- Applying Skinning --
		max modify mode
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
		-- Applying Weights --
		modPanel.setCurrentObject skinMod
		for i = 1 to Weight_Array.count do (
			w = Weight_Array[i]
			bi = #() --bone index array
			wv = #() --weight value array
			
			for j = 1 to w.boneids.count do (
				boneid = w.boneids[j]
				weight = w.weights[j]
				
				if boneid == 0 do boneid += 1
				
				append bi boneid
				append wv weight
			)	
			
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)
		
	)
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
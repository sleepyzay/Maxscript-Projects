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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
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

fname = GetOpenFileName caption:"Freedom Wars Vita" types:" (*.nmd)|*.nmd" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

EMD = ReadFixedString f 4
ukw = readshort f
headerLength = readshort f
ukw2 = readshort f	--always 0x01
ukw3 = readshort f	--always 0x01
null = readlong f

null = readshort f
modelCount = readshort f
modelTableOffset = readlong f
nameTableOffset = readlong f

fseek f modelTableOffset #seek_set
modelOffset = for x=1 to modelCount collect (readlong f #unsigned)

fseek f nameTableOffset #seek_set
modelName = for x=1 to modelCount collect (getName f (readlong f #unsigned))

for x=1 to modelCount do (
	fseek f modelOffset[x] #seek_set
	
	null = readshort f
	meshTableCount = readshort f
	meshTableOffset = readlong f + modelOffset[x]
	meshOffset = for y=1 to meshTableCount collect (readlong f #unsigned + modelOffset[x])
	
	for y=1 to meshTableCount do (
		fseek f meshOffset[y] #seek_set
		
		fseek f 0x30 #seek_cur	--matrix info
		meshNameOffset = readlong f + meshOffset[y]
		null = readshort f
		polyElmCount = readshort f	--prob count
		polyElmTableOffset = readlong f + meshOffset[y]
		
		fseek f meshNameOffset #seek_set
		meshName = readstring f
		
		fseek f polyElmTableOffset #seek_set
		polyElmOffset = for z=1 to polyElmCount collect (readlong f #unsigned + meshOffset[y])
		
		for z=1 to polyElmCount do (
			fseek f polyElmOffset[z] #seek_set
			
			Vert_Array=#()
			UV_Array=#()
			Face_Array=#()
			Normal_array=#()
			Weight_array=#()
			
			fseek f 0x30 #seek_cur	--matrix info
			ukw = readlong f	--always 0x8207, prob flags
			vertSize = readlong f
			vertCount = readlong f
			vertOffset = readlong f + polyElmOffset[z]
			texOffset = readlong f + polyElmOffset[z]
			ukw5 = readlong f	--always 0x10100
			ukwOffset = readlong f + polyElmOffset[z]
			faceDataOffset = readlong f + polyElmOffset[z]
			
			fseek f texOffset #seek_set
			texName = readstring f	--or matName
			
			fseek f faceDataOffset #seek_set
			subFaceDataOffset = readlong f + polyElmOffset[z]
			
			fseek f subFaceDataOffset #seek_set
			faceCount = readlong f
			boneMapCount = readlong f
			faceOffset = readlong f + subFaceDataOffset
			boneMapOffset = readlong f + subFaceDataOffset
			
			fseek f faceOffset #seek_set
			for a=1 to (faceCount/3) do (
				fa = readshort f #unsigned + 1
				fb = readshort f #unsigned + 1
				fc = readshort f #unsigned + 1
				
				append Face_Array[fa,fb,fc]
			)
			
			fseek f boneMapOffset #seek_set
			boneMap = for a=1 to boneMapCount collect (getName f (readlong f #unsigned + subFaceDataOffset))
			
			fseek f vertOffset #seek_set
			if vertSize == 0x18 do (
				for a=1 to vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					bone1 = readbyte f #unsigned
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					weight3 = ReadHalfFloat f
					weight4 = ReadHalfFloat f
					weight4 = 1 - (weight1+weight2+weight3)
					
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
					
					append Vert_Array([vx,vy,vz]*fscale)
					append UV_Array[0,0,0]
					append Weight_array w
				)
			)
			if vertSize == 0x24 do (
				for a=1 to vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					nx = ReadHalfFloat f
					ny = ReadHalfFloat f
					nz = ReadHalfFloat f
					nw = ReadHalfFloat f
					tu = ReadHalfFloat f * 2
					tv = ReadHalfFloat f
					bone1 = readbyte f #unsigned
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					weight3 = ReadHalfFloat f
					weight4 = ReadHalfFloat f
					weight4 = 1 - (weight1+weight2+weight3)
					
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
					
					append Vert_Array([vx,vy,vz]*fscale)
					append Normal_array[nx,ny,nz]
					append UV_Array[tu,-tv,0]
					append Weight_array w
				)
			)
			if vertSize == 0x28 do (
				for a=1 to vertCount do (
					w = (weight_data boneids:#() weights:#())
					
					vx = readfloat f
					vy = readfloat f
					vz = readfloat f
					nx = ReadHalfFloat f
					ny = ReadHalfFloat f
					nz = ReadHalfFloat f
					nw = ReadHalfFloat f
					tu = ReadHalfFloat f * 2
					tv = ReadHalfFloat f
					cr = readbyte f
					cb = readbyte f
					cg = readbyte f
					ca = readbyte f
					bone1 = readbyte f #unsigned
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = ReadHalfFloat f
					weight2 = ReadHalfFloat f
					weight3 = ReadHalfFloat f
					weight4 = ReadHalfFloat f
					weight4 = 1 - (weight1+weight2+weight3)
					
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
					
					append Vert_Array([vx,vy,vz]*fscale)
					append Normal_array[nx,ny,nz]
					append UV_Array[tu,-tv,0]
					append Weight_array w
				)
			)
			
-- 			format "vertCount: 0x% faceCount: 0x%\n" (bit.intashex(vertCount)) (bit.intashex(faceCount))
			
			if vertCount > 0 do (
				msh = mesh vertices:Vert_array faces:Face_Array
				msh.numTVerts = UV_array.count
				msh.wirecolor = random black white
				msh.name = meshName
				buildTVFaces msh
				for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
				for j = 1 to Face_array.count Do setTVFace msh j Face_Array[j]
				for j = 1 to Normal_array.count Do setNormal msh j Normal_array[j]
				msh.transform=(matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
				
				
				if (skelPresent()) do (
					-- Applying Skinning --
					count = msh.numverts
					max modify mode
					select msh
					skinMod = skin ()
					addModifier msh skinMod
					for i = 1 to boneMapCount do (
					   maxbone = getnodebyname boneMap[i]
					   skinOps.addBone skinMod maxbone 1
					)
					-- Applying Weights --
					select msh
					modPanel.setCurrentObject skinMod
					for i = 1 to weight_array.count do (
						w = Weight_array[i]
						bi = #() --bone index array
						wv = #() --weight value array
						
						for j = 1 to w.boneids.count do
						(
							boneid = w.boneids[j]
							weight = w.weights[j]
							append bi boneid
							append wv weight
						)	
						
						skinOps.ReplaceVertexWeights skinMod i bi wv
					)
				)
				
			)
		)
	)
)

deselect $*

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
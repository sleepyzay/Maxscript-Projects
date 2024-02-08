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
	print (bit.intashex(num))
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
fn triangle_strip count = (
Face_Array=#()
face_flip = true
face_reset=true
x=1;while x < count do (
x+=1
if face_reset == true then (
x+=2
face_reset=false
face_flip = false
fa = (ReadBEword f ) + 1
fb = (ReadBEword f ) + 1
fc = (ReadBEword f ) + 1
if face_flip == true then (
append Face_array [fa,fb,fc]
face_flip=false
)
else(
append Face_array [fa,fc,fb]
face_flip=true
)
)
else(
fa = fb
fb = fc
fc = ReadBEword f 
if fc!=0xFFFF then (
fc += 1
if face_flip == true then (
append Face_array [fa,fb,fc]
face_flip=false
)
else(
append Face_array [fa,fc,fb]
face_flip=true
)
)
else(
face_reset=true
)
)
)
return Face_Array
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
		result[x] = signVal (readBits pos format[x] val) format[x]
		pos+=format[x]
	)
	result/=divisor
)

fname = GetOpenFileName caption:"" types:" (*.)|*.mdl" historyCategory:""
-- fname=@"C:\Users\Owner\Downloads\hal_spartan_files_fable2\hal spartan files fable2\CH_HeroFemale_Spartan_Boots\CH_HeroFemale_Spartan_Boots.mdl"
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

struct weight_data (
	boneids,weights
)

fseek f 0x20 #seek_set

boneName=#()
parentID=#()
boneCount = ReadBElong f
for x=1 to boneCount do (
	boneName[x] = readstring f
	parentID[x] = readbelong f
)

BNArr=#()
boneCount2 = readbelong f	--same as boneCount
for x=1 to boneCount2 do (
	float11 = readbefloat f; float12 = readbefloat f; float13 = readbefloat f; float14 = readbefloat f
	float21 = readbefloat f; float22 = readbefloat f; float23 = readbefloat f;
	float31 = readbefloat f; float32 = readbefloat f; float33 = readbefloat f; null = readbefloat f
	tfm = inverse (quat float11 float12 float13 float14) as matrix3
	tfm.row4 = ([float21,float22,float23]*fscale)
	
	uniqueBone = true
	for o in geometry where classof o == bonegeometry and o.name == boneName[x] do (
		uniqueBone = false
		format "bone % already in scene\n" boneName[x]
	)
	if uniqueBone == true do (
		format "adding bone % to scene\n" boneName[x]
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
		newBone.name = boneName[x]
		
		if (parentID[x] != -1) then(
			newBone.parent = getnodebyname boneName[parentID[x] + 1]
			newBone.transform *= newBone.parent.transform
		)
		append BNArr newBone
	)
)

fseek f 0x28 #seek_cur			--floats?
fseek f 0x2d #seek_cur			--unknownNumbers, same between files

ukwCount = readbelong f
ukwFloatArray = for x=1 to ukwCount collect (readbefloat f)

ukwCount2 = readbelong f		--matCount?
ukwStringArray = for x=1 to ukwCount2 collect (readstring f)

ukw = readbelong f				--count?
meshName = readstring f

fseek f 0x2d #seek_cur			--unknownFloats, same between files

ukw2 = readbelong f				--count?

texturePathArray=#()
while true do (
	append texturePathArray (readstring f)
	
	testNext = readbelong f
	fseek f -4 #seek_cur
	if testNext == 0 then exit
)

fseek f 0x17 #seek_cur
ukw = readbelong f
faceCount = readbelong f
vertCount = readbelong f
ukwTableCount = readbelong f

for x=1 to ukwTableCount do (
	ReadFixedByteString f 0x29 0 0
)

format "ukw: %	faceCount: %	vertCount: %\n" (bit.intashex (ukw as integer)) (bit.intashex (faceCount as integer)) (bit.intashex (vertCount as integer))

Vert_Array=#()
UV_Array=#()
Face_Array=#()
Weight_array=#()
Normal_Array=#()

for x=1 to vertCount do (
	w = (weight_data boneids:#() weights:#())
	
 	--ReadFixedByteString f 0x1c 1 1
	vx = ReadBEHalfFloat f
	vy = ReadBEHalfFloat f
	vz = ReadBEHalfFloat f
	vw = ReadBEHalfFloat f
	vn = (get32bitNormal [11,11,10] [1023,1023,511] (readbelong f)) 
	
	bone1 = readbyte f #unsigned + 1
	bone2 = readbyte f #unsigned + 1
	bone3 = readbyte f #unsigned + 1
	bone4 = readbyte f #unsigned + 1
	weight1 = readbyte f #unsigned
	weight2 = readbyte f #unsigned
	weight3 = readbyte f #unsigned
	weight4 = readbyte f #unsigned
	tu = ReadBEHalfFloat f * 2
	tv = ReadBEHalfFloat f * 2
	ukw2 = readbelong f	--colors?
	
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
			append w.boneids (bone1)
			append w.weights (w1 / mxw)
		)
		if(weight2 != 0) then (
			w2 = weight2 as float
			append w.boneids (bone2)
			append w.weights (w2 / mxw)
		)
		if(weight3 != 0) then (
			w3 = weight3 as float
			append w.boneids (bone3)
			append w.weights (w3 / mxw)
		)
		if(weight4 != 0) then (
			w4 = weight4 as float
			append w.boneids (bone4)
			append w.weights (w4 / mxw)
		)		
	)
	
	append Vert_Array([vx,vy,vz]*fscale*2)
	append Normal_Array vn
	append UV_Array[tu,1-tv,0]
	append Weight_array w
)

faceOffset = ftell f
StartDirection = 1
f1 = (ReadBEword f) + 1
f2 = (ReadBEword f) + 1  
FaceDirection = StartDirection
do (
	f3 = (ReadBEword f)
	if (f3==0xFFFF) then (
		f1 = (ReadBEword f) + 1
		f2 = (ReadBEword f) + 1
		FaceDirection = StartDirection 
	) 
	else (
		f3 += 1
		FaceDirection *= -1
		if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
			if FaceDirection > 0 then (
				append Face_array [f1,f2,f3]
			)
			else (
				append Face_array [f1,f3,f2]
			)
		)
		f1 = f2
		f2 = f3
	) 
) 
while ((ftell f) != ((faceCount * 2) + faceOffset))

for x=1 to vertCount do (
	ukw = readbefloat f
	ukw2 = readbefloat f
	ukw3 = readbefloat f
	ukw4 = readbefloat f
)

msh = mesh vertices:Vert_array faces:Face_array
msh.name = meshName
msh.numTVerts = UV_array.count
buildTVFaces msh
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]

usedBones = #()
for x=1 to Weight_array.count do (
	for y=1 to Weight_array[x].boneids.count do (
		appendifunique usedBones (boneName[Weight_array[x].boneids[y]])
	)
)
msh.transform=(matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0])
for b in BNArr where b.parent==undefined do b.transform = (matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0])
for b in BNArr do b.setskinpose()

if (skelPresent()) do (
	-- Applying Skinning --
	max modify mode
	select msh
	skinMod = skin ()
	addModifier msh skinMod
	for i = 1 to usedBones.count do (
		maxbone = getnodebyname usedBones[i]
		if i != usedBones.count then
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
			boneid = finditem usedBones boneName[w.boneids[j]]
			weight = w.weights[j]
			
			append bi boneid
			append wv weight
		)	
		
		skinOps.ReplaceVertexWeights skinMod i bi wv
	)
)



Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
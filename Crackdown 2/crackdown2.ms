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
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
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
fn DisplayVerts msh = (
	select msh
	poly = Edit_Poly()
	modPanel.addModToSelection poly ui:off
	setselectionlevel poly #vertex
	poly.select #vertex #{1}
)
fn triangle_strip count = (
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
)
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
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
)
fn ApplyNormals amesh nArr toggle= (
	max modify mode
	cui.expertModeOn()

	with redraw off (
	   --your import code
		
	   for face = 1 to amesh.numfaces do setFaceSmoothGroup amesh face 1
		
	   select amesh
	   addmodifier amesh (Edit_Normals ()) ui:off
	   amesh.Edit_Normals.MakeExplicit selection:#{1..nArr.count}
	   EN_convertVS = amesh.Edit_Normals.ConvertVertexSelection
	   EN_setNormal = amesh.Edit_Normals.SetNormal
	   normID = #{}
		
	   for v = 1 to nArr.count do
	   (
		  free normID
		  EN_convertVS #{v} &normID
		  for id in normID do EN_setNormal id nArr[v]
	   )
	   
	   if toggle == 1 do collapseStack amesh
	)

	cui.expertModeOff()
)

fname = GetOpenFileName caption:"Crackdown 2" types:"(*.b_pskn)|*.b_pskn"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
f = fopen fname "rb"   --open file in read only format
clearlistener()
fscale=50
delete $*

Face_array=#()
Vert_array=#()
Normal_array=#()
UV_array=#()

fseek f 0x8c #seek_set

VertOffset = readbelong f
VertCount = readbelong f
FaceOffset = readbelong f
FaceCount = readbelong f 

fseek f VertOffset #seek_set
for x=1 to VertCount do (
	vx=ReadBEfloat f
	vy=ReadBEfloat f
	vz=ReadBEfloat f	
	n1 = ReadBEHalfFloat f
	n2 = ReadBEHalfFloat f
	n3 = ReadBEHalfFloat f
	n4 = ReadBEHalfFloat f
	tu = ReadBEHalfFloat f
	tv = ReadBEHalfFloat f
	fseek f 0x8 #seek_cur

	append Vert_array([vx,vz,vy]*fscale)
	append UV_array([tu,tv,0]*2)
-- 	append Normal_array [n1,n3,n2]
)

fseek f FaceOffset #seek_set
triangle_strip FaceCount


-- ApplyNormals msh Normal_array 1
msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = UV_array.count
buildTVFaces msh
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
-- DisplayVerts msh


	
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)

gc()
fclose g
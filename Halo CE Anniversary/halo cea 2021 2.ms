global fscale=1

fn ReadFixedString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str0 = ReadByte bstream #unsigned
      If str0!=0xFD AND str0!=0xFC do str+= bit.intAsChar str0
   )
   str
)
fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)	
fn ReadFixedByteString bstream fixedLen var var2 = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   if var == 1 do fseek bstream -fixedLen #seek_cur
   if var2 == 1 do print str
   return str
)
fn ReadStringUntilOffset bstream offset = (
	local str = ""
	fixedLen = (offset - (ftell bstream))
   for i = 1 to fixedLen do
   (
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)
fn Readword fstream = (
return readshort fstream #unsigned
)
fn GetName bstream Offset = (
	fseek bstream Offset #seek_set
	MeshName = readstring bstream
	return MeshName
)
fn FindNumofOcurrences narray num = (
	j=0
	for i in narray do (
		if i == num do j+=1
	)
	return j
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
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
)
fn ReadUntilOffset bstream offset = (
	local str = ""
	while ((ftell bstream) < offset) do (
		str += bit.intAsChar (ReadByte bstream #unsigned)
	)
   str
)
fn checkNull var chunkType = (
	if var > 0 do format "non null found: % %\n" (bit.intashex (var)) (bit.intashex(chunkType))
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
fn getVMatrix xbounds ybounds zbounds = (
	dMat = matrix3 [1.0 / 65535.0, 0, 0] [0, 1.0 / 65535.0, 0] [0, 0, 1.0 / 65535.0] [0.5,0.5,0.5]
	bMat = matrix3 [xbounds.y - xbounds.x, 0, 0] [0, ybounds.y - ybounds.x, 0] [0, 0, zbounds.y - zbounds.x] [xbounds.x, ybounds.x, zbounds.x]
	return (dMat * bMat)
)
fn printMatrix fstream = (
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	format "\n"
	fseek fstream -0x40 #seek_cur
)

fname = GetOpenFileName caption:"" types:" (*.)|*.*" historyCategory:""
-- fname=@"D:\models\ripped\halo cea\iga_a10_cyborg_cryo.bin"
-- fname = @"D:\models\ripped\halo cea\cyborg_iga.bin"
-- fname=@"D:\models\ripped\halo cea\warthog__h.bin"
-- fname = @"D:\models\ripped\halo cea\cyborg.bin"
-- fname = @"D:\models\ripped\halo cea\warthog__h.bin"
-- fname = @"D:\models\ripped\halo cea\elite.bin"
-- fname = @"D:\models\ripped\halo cea\crewman.bin"
-- fname = @"D:\models\ripped\halo cea\plasma_pistol.bin"
-- fname=@"D:\models\ripped\halo cea\assault_rifle.bin"


If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileSize = getFileSize fname
clearlistener()
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _header (
	offset = (ftell f) as integer,
	type = readshort f #unsigned	as integer,
	end = readlong f #unsigned	as integer,
	length = (end - offset) as integer,
	parent = undefined
)

fn printChunkInfo chunk var = (
	if var == 1 and chunk.type != 1 do (
		format "chunkType: %	chunkOffset: %	chunkLength: %\n" (bit.intashex (chunk.type)) (bit.intashex (chunk.offset)) (bit.intashex (chunk.length))
	)
)

struct _2e4 (_2e5,_316,_155,_f0,_2e8,_2e6,_21d,_311,_304,_305,_308,_30e,_312)	--scene
	struct _2e5 (magic, fileName)
	struct _316 (undefined)
	struct _155 (texCount,_156)
		struct _156 (texName)
	struct _2e8 (nodeCount,_2e9)
		struct _2e9 (_2fa, _2ea, _2fb, _2eb, _2fc,_2ec,_30a)
			struct _2fa (initPosX,initPosY,initPosZ)
			struct _2ea (undefined)
			struct _2fb (initRotX,initRotY,initRotZ,initRotW)
			struct _2eb (undefined)
			struct _2fc (initSclX,initSclY,initSclZ)
			struct _2ec (undefined)
			struct _30a (undefined)
	struct _2e6 (trackCount, _2fd)
		struct _2fd(_2fe,_2ff,_300,_301,_2f3,_2f4,_314,_307)
			struct _2fe(trackName)
			struct _2ff(trackStartFrame)
			struct _300(trackEndFrame)
			struct _301(trackLength)
			struct _2f3(undefined)
			struct _2f4(trackNumFrames)
			struct _314(undefined)
			struct _307(undefined)
	struct _21d (undefined)
	struct _311 (lodInfoCount, lodInfo)
		struct _lodInfo (objID = (readshort f #unsigned + 1),lodID = (readbyte f #unsigned + 1),lodFlag = (readbyte f #unsigned + 1))		--1 == lowest lod
	struct _304 (undefined)
	struct _305 (_30d)
		struct _30d(nodeCount, ukw, ukw2, nodeArray)
	struct _308 (ukw,bbmin,bbMax)
	struct _30e (undefined)
	struct _312 (undefined)

struct _f0	(_12c,_f0,_3b9,_12e,_f1,_130,_f2,_11d,_f8,_12f,_f9,_fa,_fd,_115,_107,_116,_12b)	--f0
	struct _12c	(objCount)
	struct _3b9	(name,objID,ukw,ukw2,ukw3,ukw4, vertCount, faceCount)
	struct _12e	(ukw,ukw2,ukw3,ukw4)
	struct _f1		(vertCount, vertOffset, meshPos, meshScale, Vert_Array)
	struct _130	(uvCount, UV_Array, Normal_Array)
	struct _f2		(faceCount, Face_Array)
	struct _11d	(ukw,bbmin,bbMax)
	struct _f8		(colorB,colorG,colorR,colorA)
	struct _12f	(ukwCount,ukw)
	struct _f9		(tfm)
	struct _fa		(boneID)
	struct _fd		(_1ba)
		struct _1ba	(undefined)
	struct _115	(meshParameterString)
	struct _107	(_f3,_104)
		struct _f3		(ukwCount,_103)
			struct _103	(ukw)
		struct _104	(subMeshCount,_105,_10d,_134,_132,_10b,_11c,_120,_128)
			struct _105	(faceOffset,faceCount)
			struct _10d	(vertOffset,vertCount)
			struct _134	(skinCompoundObjID)
			struct _132	(objID,objRange,objID2,objRange2)
			struct _10b	(ukwCount,_10e,_114,_11f,_1ba)
				struct _10e (matID,ukw2,ukw3,ukw4)
				struct _114 (ukw,ukw2)
				struct _11f (ukw,ukw2)
				--struct _1ba (undefined)	--may cause problems in the future
			struct _11c	(ukw,ukw2)
			struct _120	(ukw,ukw2,ukw3,ukw4,ukw5,ukw6,ukw7,ukw8)
			struct _128	(ukw,ukw2,ukw3,ukw4,vertCount,faceCount,ukw7,ukw8,ukw9,ukw10)
	struct _116	(_117,_133,_11a)
			struct _117	(boneMapCount,ukw2)
			struct _133	(objID,objRange,Bind_Indices_Array)
			struct _11a	(Bind_Weight_Array)
	struct _12b	(objParentID)

fn readModel f parent var =(--)
	chunk = _header()
	printChunkInfo chunk var
	case chunk.type of (--)
		0x01:(			--delimeter
-- 			format "Reached delimeter in %.\n" (parent)
			exit
		)
		0xf0:(			--container
			case (classof parent) of (
				(_f0):(
					while true do readModel f parent 0						--3b9, 12e, f1, 130, f2, 11d, f8, 12f, f9, fa, fd, 115, 107, 116, 12b
					--format "\n"
				)
				(classof _2e4):(
					parent._f0 = _f0()
					parent._f0._f0 = #()
					readModel f parent._f0 0										--12c
					for x=1 to parent._f0._12c.objCount do (
						parent._f0._f0[x] = _f0()
						while true do readModel f parent._f0._f0[x] 0	--0xf0
						
						if parent._f0._f0[x]._12b == undefined do parent._f0._f0[x]._12b = (_12b objParentID: 0)
					)
				)
				default:(
					format "Undefined Parent: %\n" (parent)
					exit
				)
			)
			fseek f chunk.end #seek_set
		)
		0xf1:(			--objVertexData
			parent._f1 = _f1()
			
			parent._f1.vertCount = readlong f
			
			if parent._f1.vertCount > 0 do (
				parent._f1.meshPos = [readshort f,readshort f,readshort f]
				parent._f1.meshScale = [readshort f,readshort f,readshort f]
				
				parent._f1.Vert_Array = #()
				parent._f1.vertOffset = ftell f				
				for x=1 to parent._f1.vertCount do (
					vx = readshort f
					vy = readshort f 
					vz = readshort f 
					vw = readshort f
					
					append parent._f1.Vert_Array([vx,vy,vz,vw] / 32767.0)
				)
			)
		)
		0xf2:(			--objFaceData
			parent._f2 = _f2()
			parent._f2.Face_Array = #()
			parent._f2.faceCount = readlong f
			for x=1 to parent._f2.faceCount do (
				fa = readshort f + 1
				fb = readshort f + 1
				fc = readshort f + 1
				
				append parent._f2.Face_Array[fa,fb,fc]
			)
		)
		0xf3:(			--subMeshUnknownInfo		
			parent._f3 = _f3()
			parent._f3.ukwCount = readlong f	--always 5
			
			--print parent._f3.ukwCount
			parent._f3._103=#()
			for x=1 to parent._f3.ukwCount do (
				parent._f3._103[x] = _103()
				while true do readModel f parent._f3._103[x] 0		--103
			)
		)
		0xf8:(			--objMeshMaterialColor
			parent._f8 = _f8()
			parent._f8.colorB = readbyte f #unsigned
			parent._f8.colorG = readbyte f #unsigned
			parent._f8.colorR = readbyte f #unsigned
			parent._f8.colorA = readbyte f #unsigned
			--format "% % % %\n" parent._f8.colorB parent._f8.colorG parent._f8.colorR parent._f8.colorA
		)
		0xf9:(			--objTransform
			parent._f9 = _f9()
-- 			printMatrix f
			m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
			m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
			m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
			m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
			parent._f9.tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]	
		)
		0xfa:(			--objBoneID
			parent._fa = _fa()
			parent._fa.boneID = readlong f #unsigned + 1
		)
		0xfd:(			--unknownStringContainer
			fseek f chunk.end #seek_set
		)
		0x103:(		--subMeshUnknownData
			parent.ukw = readlong f	--null / if not null game crashes
		)
		0x104:(		--subMeshInfo
			parent._104 = _104()
			parent._104.subMeshCount = readlong f
			
			parent._104._105 = #()
			parent._104._10d = #()
			parent._104._134 = #()
			parent._104._132 = #()
			parent._104._10b = #()
			parent._104._11c = #()
			parent._104._120 = #()
			parent._104._128 = #()
			
 			--format "subMeshCount: %\n" parent._104.subMeshCount
			for x=1 to parent._104.subMeshCount do (
				while true do readModel f parent._104 0	--105, 10d, 134, 132, 10b, 11c, 120, 128
			)
			
			--print parent._104._134
			--print parent._104._132
			--print parent._104._11c
			--format "\n"
		)
		0x105:(		--subMeshFaceInfo
			_s105 = _105()
			
			_s105.faceOffset = readlong f #unsigned
			_s105.faceCount = readlong f #unsigned
			--format "% %\n" ((_s105.faceOffset)) ((_s105.faceCount))
			
			append parent._105 (_s105)
		)
		0x107:(		--subMeshContainer
			--print parent._3b9
			parent._107 = _107()
			while true do readModel f parent._107 0	--f3, 104
			--format "\n"
		)
		0x10b:(		--subMeshMaterialContainer		
			_s10b = _10b()
			_s10b.ukwCount = readlong f		--always 1?
			
			_s10b._10e = #()
			_s10b._114 = #()
			_s10b._11f = #()
			_s10b._1ba = #()
			
			for x=1 to _s10b.ukwCount do (
				while true do readModel f _s10b 0	--10e, 114, 11f, 1ba
				--format "\n"
			)
			append parent._10b _s10b
		)
		0x10d:(		--subMeshVertexInfo
			_s10d = _10d()
			
			_s10d.vertOffset = readlong f #unsigned
			_s10d.vertCount = readlong f #unsigned
			--format "% %\n" ((_s10d.vertOffset)) ((_s10d.vertCount))
			
			append parent._10d (_s10d)
		)
		0x10e:(			--subMeshMaterialInfo
			--ReadFixedByteString f 0x0a 1 1
			_s10e = _10e()
			
			_s10e.matID = readlong f + 1	--matID?
			_s10e.ukw2 = readlong f	--0xff's, colors?
			_s10e.ukw3 = readbyte f	--0x00, ID?
			_s10e.ukw4 = readbyte f	--0xff
			
			--format "% % % %\n" _s10e.matID _s10e.ukw2 _s10e.ukw3 _s10e.ukw4
			
			append parent._10e (_s10e)
		)
		0x114:(		--ukwMaterialData
			--ReadFixedByteString f 0x02 1 1
			_s114 = _114()
			
			_s114.ukw = readbyte f	--0x00/0xff	, may be short
			_s114.ukw2 = readbyte f	--0xff
			--format "% %\n" _s114.ukw _s114.ukw2
			
			append parent._114 (_s114)
		)
		0x115:(		--meshString
			parent._115 = _115()	--used for in engine scripting?
			parent._115.meshParameterString = ReadUntilOffset f chunk.end
			--print parent._115.meshParameterString
		)
		0x116:(		--vertexBindContainer
			parent._116 = _116()
			while true do readModel f parent._116 q					--117, 133, 11a
			
-- 			print parent._116._117
-- 			print parent._116._133
-- 			print parent._116._11a
			
		)
		0x117:(		--vertexBindUnknownInfo
			parent._117 = _117()
			parent._117.boneMapCount = readlong f #unsigned
			parent._117.ukw2 = readlong f #unsigned	--always 4, maxSkinWeights?
			--format "% %\n" parent._117.ukw parent._117.ukw2
		)
		0x11a:(			--vertexBindWeightData
			parent._11a = _11a()
			parent._11a.Bind_Weight_Array=#()
			
			for x=1 to ((chunk.end - (ftell f)) / 4) do (		--can't figure out how to access _f1.vertCount from this scope
				weight1 = readbyte f #unsigned
				weight2 = readbyte f #unsigned
				weight3 = readbyte f #unsigned
				weight4 = readbyte f #unsigned
				
				--if x < 50 do format "% % % %\n" weight1 weight2 weight3 weight4
				
				--append parent._11a.Blend_Weight_Array [weight1,weight2,weight3,weight4]
			)
		)
		0x11c:(			--subMeshUnknownData
			_s11c = _11c()
			
			_s11c.ukw = readfloat f
			_s11c.ukw2 = readfloat f
			--format "% %\n" _s11c.ukw _s11c.ukw2
			
			append parent._11c (_s11c)
		)
		0x11d:(		--objMeshBoundBox
			parent._11d = _11d()
			parent._11d.ukw = readlong f	--always 1/scale?
			parent._11d.bbMin = [(readfloat f),(readfloat f),(readfloat f)]
			parent._11d.bbMax = [(readfloat f),(readfloat f),(readfloat f)]
			--format "% %\n" parent._11d.bbMin parent._11d.bbMax
		)
		0x11f:(			--unknownMatData
			--ReadFixedByteString f 0x02 1 1
			_s11f = _11f()
			
			_s11f.ukw = readbyte f	--0x00/0x01/0x02/0xff/matID?
			_s11f.ukw2 = readbyte f	--0xff
			--format "% %\n" _s11f.ukw _s11f.ukw2
			
			append parent._11f (_s11f)
		)
		0x120:(		--subMeshUnknownData
			ReadFixedByteString f (chunk.length - 6) 1 0	--currently null, don't remember why I put it down as floats, matrix?
			s120 = _120()
			
			s120.ukw = readfloat f
			s120.ukw2 = readfloat f
			s120.ukw3 = readfloat f
			s120.ukw4 = readfloat f
			s120.ukw5 = readfloat f
			s120.ukw6 = readfloat f
			s120.ukw7 = readfloat f
			s120.ukw8 = readfloat f
			
			append parent._120 s120
			
			--format "% % % % % % % %\n" ukw ukw2 ukw3 ukw4 ukw5 ukw6 ukw7 ukw8
		)
		0x128:(		--ukwSubMeshData
			--ReadFixedByteString f 0x1c 1 1
			--all subMeshes with vert/face data has this, not just skinCompound subMeshes
			
			_s128 = _128()
			
			_s128.ukw = readbyte f		--0x81
			_s128.ukw2 = readlong f
			_s128.ukw3 = readbyte f		--0xff
			_s128.ukw4 = readshort f	--0x12
			_s128.vertCount = readshort f	-- _s10d.vertCount
			_s128.faceCount = readshort f	--_s105.faceCount * 3
			_s128.ukw7 = readlong f		--0xff's
			_s128.ukw8 = readlong f
			_s128.ukw9 = readlong f
			_s128.ukw10 = readlong f	--may be 2 or 4 values
 			--format "% % % % % % % % %\n" _s128.ukw _s128.ukw2 _s128.ukw3 _s128.ukw4 _s128.ukw5 _s128.ukw6 _s128.ukw7 _s128.ukw8 _s128.ukw9
			append parent._128 (_s128)
		)
		0x12b:(		--objParentID
			parent._12b = _12b()
			parent._12b.objParentID = readlong f #unsigned + 1
			--format "objParentID: %\n" parent._12b.objParentID
		)
		0x12c:(			--objCount
			parent._12c = _12c()
			parent._12c.objCount = readlong f
		)
		0x12e:(			--unknownMeshData
			--print parent._3b9.name
			--ReadFixedByteString f 0x05 1 1
			--format "\n"
			parent._12e = _12e()	--crashes game if modified
			parent._12e.ukw = readshort f #unsigned	--0x12
			parent._12e.ukw2 = readbyte f #unsigned	--0x00/0x87
			parent._12e.ukw3 = readbyte f #unsigned	--0x00/0x40/0x050/0x70
			parent._12e.ukw4 = readbyte f #unsigned	--0x00/0x01
			
 			--format "% % % %\n" parent._12e.ukw parent._12e.ukw2 parent._12e.ukw3 parent._12e.ukw4
		)
		0x12f:(			--unknownObjMeshMaterialData
			parent._12f = _12f()
			parent._12f.ukwCount = readbyte f
			--print parent._3b9.name
			for x=1 to parent._12f.ukwCount do (		--not putting in array bc ukwCount is almost always 1 / will fix in future
				ukw = readbyte f + 1
				ukw2 = readlong f + 1
				
				--format "% %\n" ukw ukw2
			)
			--format "\n"
		)
		0x130:(		--vertexNormals/textureCoords
			parent._130 = _130()
			parent._130.uvCount = readlong f
			
			--"2e 00 00 10 02 42 00 20 08 "	--
			ReadFixedByteString f 0x9 0 0	--buffer info, size of uv included
			
			parent._130.UV_Array = #()
			parent._130.Normal_Array = #()
			for x=1 to parent._130.uvCount do (			--currently broken
				--if x < 100 do ReadFixedByteString f 0x04 1 1
				nx = readbyte f #unsigned / 255.0 * 2 - 1
				ny = readbyte f #unsigned / 255.0 * 2 - 1
				nz = readbyte f #unsigned / 255.0 * 2 - 1
				nw = readbyte f #unsigned / 255.0 * 2 - 1		--flag
				tu=Readbeshort f
				tv=Readbeshort f
				
				append parent._130.UV_Array([tu,1-tv,0] / 32767.0)
				append parent._130.Normal_Array([nx,ny,nz])
			)
			fseek f chunk.end #seek_set	--dosent always read correctly
		)
		0x132:(		--subMeshUnknownObjIDs
			_s132 = _132() 
 			--ReadFixedByteString f 0x06 1 1		--changing values have no apparent effect in game
			
			_s132.objID = readshort f #unsigned + 1
			_s132.objRange = readbyte f
			_s132.objID2 = readshort f #unsigned + 1
			_s132.objRange2 = readbyte f
			
			append parent._132 (_s132)
		)
		0x133:(		--vertexBindIndicesData
			parent._133 = _133()
			parent._133.objID = readshort f #unsigned + 1	--same as 132.objID
			parent._133.objRange = readshort f #unsigned	--usually the same as 132.objRange
			--objID's to bones to use as boneMap
			
			parent._133.Bind_Indices_Array=#()
			for x=1 to ((chunk.end - (ftell f)) / 4) do (
				--for skin compounds bone1 is index of obj defined by objID and objRange, bones 3-4 are ignored
				--skin compounds dont have weights and are bound by bone 1 only
				
				bone1 = readbyte f #unsigned + 1
				bone2 = readbyte f #unsigned + 1
				bone3 = readbyte f #unsigned + 1
				bone4 = readbyte f #unsigned + 1
				
				append parent._133.Bind_Indices_Array [bone1, bone2, bone3, bone4]
			)
		)
		0x134:(		--subMeshSkinCompoundObjID
			_s134 = _134() 
			
			skinCompoundObjID = readshort f #unsigned + 1	--if subMesh has no mesh data it takes it from the skinCompound mesh linked through this id
			append parent._134 skinCompoundObjID
		)
		0x155:(		--textureNameContainer
			parent._155 = _155()
			parent._155.texCount = readlong f
			
			parent._155._156 = #()
			for x=1 to parent._155.texCount do (
 				parent._155._156[x] = _156()
				readModel f parent._155._156[x] 0	--156
			)
		)
		0x156:(		--textureName
			parent.texName = ReadStringUntilOffset f chunk.end
			--print parent.texName
		)
		0x1ba:(			--string
			fseek f chunk.end #seek_set
		)
		0x21d:(		--null
			null = readlong f	--count?
			checkNull null chunk.type
		)
		0x2e4:(			--scene
			_2e4 = _2e4()
			
			--file info
			while true do readModel f _2e4 0			--2e5, 316, 155

 			--model info
			while true do readModel f _2e4 0			--f0
		
 			--animation data /track info
			while true do readModel f _2e4 0			--2e8, 2e6
 			
  			--metaData?
			while true do readModel f _2e4 0			--21d, 311, 304, 305, 308, 30e, 312
			
			return _2e4
		)
		0x2e5:(			--fileName
			parent._2e5 = _2e5()
			parent._2e5.magic = ReadFixedString f 4
			parent._2e5.fileName = ReadStringUntilOffset f chunk.end
		)
		0x2e6:(			--trackInfoContainer
			parent._2e6 = _2e6()
			parent._2e6.trackCount = readlong f
			--if parent._2e6.trackCount > 0 do format "trackCount: %\n\n" parent._2e6.trackCount
			
			parent._2e6._2fd = #()
			for x=1 to parent._2e6.trackCount do (
				readModel f parent._2e6 0					--2fd
			)
			fseek f chunk.end #seek_set
		)
		0x2e8:(	 		--animationDataContainer
			parent._2e8 = _2e8()
			parent._2e8.nodeCount = readlong f
			
			parent._2e8._2e9=#()
			for x=1 to parent._2e8.nodeCount do (				
				while true do readModel f parent._2e8 0		--2e9
			)
-- 			fseek f chunk.end #seek_set
		)
		0x2e9:( 		--animationData
			_s2e9 = _2e9()
			null = readlong f
																	------pos-------rot-------scl-----vis?--
			while (ftell f ) < chunk.end do (		--|		      |		     |		   |		   |
				readModel f _s2e9 0						--2fa, 2ea, 2fb, 2eb, 2fc, 2ec, 30a---
			)
 			--format "\n"
			append parent._2e9 (_s2e9)
		)
		0x2ea:(			--animationTransitionData
			--ReadFixedByteString f 0x3a 0 1
			fseek f chunk.end #seek_set
		)
		0x2eb:(			--animationRotationData
			ReadFixedByteString f 0x3a 0 1
			fseek f chunk.end #seek_set
		)
		0x2ec:(			--animationScaleData
			fseek f chunk.end #seek_set
		)
		0x2ed:(			--animationUnknownData
			fseek f chunk.end #seek_set
		)
		0x2f3:(			--trackUnknownData
			ukw = readlong f	--float/null?
			checkNull ukw chunk.type
		)
		0x2f4:(			--trackNumFrames
			parent._2f4 = _2f4()
			parent._2f4.trackNumFrames = readfloat f
			--format "trackNumFrames %\n\n" trackNumFrames
		)
		0x2fa:(			--animationInitialTransitionData
			parent._2fa = _2fa()
			
			parent._2fa.initPosX = readfloat f
			parent._2fa.initPosY = readfloat f
			parent._2fa.initPosZ = readfloat f
		)
		0x2fb:(			--animationInitialRotationData
			parent._2fb = _2fb()
			
			parent._2fb.initRotX = readfloat f
			parent._2fb.initRotY = readfloat f
			parent._2fb.initRotZ = readfloat f
			parent._2fb.initRotW = readfloat f
		)
		0x2fc:(			--animationInitialScaleData
			parent._2fc = _2fc()
			
			parent._2fc.initSclX = readfloat f
			parent._2fc.initSclY = readfloat f
			parent._2fc.initSclZ = readfloat f
		)
		0x2fd:(			--trackInfo
			_2fd_ = _2fd()
			while ftell f < chunk.end do (
				readModel f _2fd_ 0				--2fe, 2ff, 300, 301, 2f3, 2f4, 314, 307
			)
			--format "\n"
-- 			append parent._2fd _2fd_
			
			--format "name: %	start: % end: % length: %\n" _2fd_._2fe.trackName _2fd_._2ff.trackStartFrame _2fd_._300.trackEndFrame _2fd_._301.trackLength
		)
		0x2fe:(			--trackName
			parent._2fe = _2fe()
			parent._2fe.trackName = ReadStringUntilOffset f chunk.end
		)
		0x2ff:(			--trackStartFrame
			parent._2ff = _2ff()
			parent._2ff.trackStartFrame = readfloat f
		)
		0x300:(		--trackEndFrame
			parent._300 = _300()
			parent._300.trackEndFrame = readfloat f
		)
		0x301:(		--trackLength
			parent._301 = _301()
			parent._301.trackLength = readfloat f	--trackLength = trackNumFrames / 30.0 (framerate)
		)
		0x304:(		--mayaExportInfo
			exportInfo = ReadStringUntilOffset f chunk.end
			--print exportInfo
		)
		0x305:(		--skeletonDataContainer / cea skeleton?
			parent._305 = _305()
			while true do readModel f parent._305 1	--30d, only 1?
		)
		0x307:(		--trackUnknownData / boundBox?
			ukw = readlong f	--count?, always 1
			bbMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			bbMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
		)
		0x308:(		--boundBox
			parent._308 = _308()
			parent._308.ukw = readlong f	--always 1/scale?
			parent._308.bbMin = [(readfloat f),(readfloat f),(readfloat f)]
			parent._308.bbMax = [(readfloat f),(readfloat f),(readfloat f)]
			--format "% %\n" parent._308.bbMin parent._308.bbMax
		)
		0x30a:(			--unknownAnimationData
			ukw = readfloat f	--always 1.0
		)
		0x30e:(			--unknownData
			ukwCount = readlong f
			for x=1 to ukwCount do (
				readModel f chunk.type 0
			)
		)
		0x30d:(		--skeletonData
			--ce's skeleton?
			--animations transform this skeleton only?
			parent._30d = _30d()
			--printhere f
			parent._30d.nodeCount = readlong f
			parent._30d.ukw = readshort f	--bitfield?
			parent._30d.ukw2 = readbyte f	--bitfield?
			
			--print parent._30d.nodeCount
 			--format "% %\n" (bit.intashex(parent._30d.ukw)) (bit.intashex(parent._30d.ukw2))			
			
			parent._30d.nodeArray = #()
			if parent._30d.ukw2 == 2 do (
				for x=1 to parent._30d.nodeCount do (
					--printMatrix f
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]	
					
					append parent._30d.nodeArray tfm
				)
			)
		)
		0x311:(		--meshLodInfo
			parent._311 = _311()
			parent._311.lodInfoCount = readshort f
			parent._311.lodInfo = for x=1 to parent._311.lodInfoCount collect (lodInfo = _lodInfo())
		)
		0x312:(		--tplInfo
			fseek f chunk.end #seek_set
		)
		0x314:(		--trackSoundClipInfo
			soundCount = readlong f	--float/null?			
			for x=1 to soundCount do (
				ReadFixedByteString f 0x05 1 0
				ukw = readbyte f
				ukw2 = readlong f
				soundName = ReadFixedString f (readlong f)
				
				--format "% % %\n" ukw ukw2 soundName
			)
			--fseek f chunk.end #seek_set
		)
		0x316:(		--unknownData
			ReadFixedByteString f 3 0 0	--"02 01 01", fileVersion?
		)
		0x3b9:(		--objInfo
			parent._3b9 = _3b9()
			parent._3b9.name = readstring f
			parent._3b9.objID = readshort f #unsigned + 1
			parent._3b9.ukw = readshort f 			--0x24
			parent._3b9.ukw2 = readshort f			--0x04 or 0x08 if mesh
			parent._3b9.ukw3 = readbyte f			--0x08 if node and has parent
			parent._3b9.ukw4 = readshort f			--0x104 if lights
			parent._3b9.vertCount = readlong f
			parent._3b9.faceCount = readlong f
			--print parent._3b9
		)
		default:(
			format "unknown chunk type: % parent: %\n" (bit.intashex(chunk.type)) ((parent))
-- 			fseek f chunk.end #seek_set
			exit
		)
	)
)

_2e4 = readModel f 0 0

multiMat = MultiMaterial numsubs:_2e4._155._156.count showInViewport:true
meditMaterials[1] = multiMat
for x=1 to multiMat.count do (
	multiMat[x].Diffuse = random black white
	multiMat[x].name = _2e4._155._156[x].texName
)

Node_Array=#()

rootObj = undefined
for obj in _2e4._f0._f0 do (
	format "%	%	%	%\n" obj._3b9.objID obj._12b.objParentID obj._fa.boneID obj._3b9.name
	--print (_2e4._305._30d.nodeArray[obj._3b9.objID])
	--parentObj = (for p in _2e4._f0._f0 where p._3b9.objID == obj._12b.objParentID collect p)[1]	--parentObj	
	
	d = dummy name:obj._3b9.name boxsize:[0.1,0.1,0.1]
	d.transform = obj._f9.tfm
	
	Node_Array[obj._3b9.objID] = d
	if obj._12b.objParentID != 0 do (
		d.parent = Node_Array[obj._12b.objParentID]
		d.transform *= d.parent.transform
	)
)

/*
for obj in _2e4._f0._f0 do (
	format "%	%	%	% %\n" obj._3b9.objID obj._12b.objParentID obj._fa.boneID obj._f9.tfm.scale obj._3b9.name
	--print (_2e4._305._30d.nodeArray[obj._3b9.objID])
	--parentObj = (for p in _2e4._f0._f0 where p._3b9.objID == obj._12b.objParentID collect p)[1]	--parentObj	
	
	if obj._3b9.vertCount != 0 do (
		emptyUV = for a=1 to obj._f1.Vert_Array.count collect [0,0,0]
		
		msh = mesh vertices:obj._f1.Vert_Array faces:obj._f2.Face_Array
		msh.numTVerts = emptyUV.count
		msh.wirecolor = random black white
		msh.name = obj._3b9.name
		buildTVFaces msh
		for j = 1 to emptyUV.count do setTVert msh j emptyUV[j]
		for j = 1 to obj._f2.Face_Array.count do setTVFace msh j obj._f2.Face_Array[j]
		
		Node_Array[obj._3b9.objID] = msh
		if obj._12b.objParentID != 0 do (
			msh.parent = Node_Array[obj._12b.objParentID]
			msh.transform *= msh.parent.transform
		)
		
		msh.scale = [obj._f1.meshScale.x,obj._f1.meshScale.y,obj._f1.meshScale.z]
		msh.pos = [obj._f1.meshPos.x,obj._f1.meshPos.y,obj._f1.meshPos.z]
		
		if obj._3b9.ukw2 == 8 do (
			objSelection = #()
			_133 = obj._116._133
			for x = _133.objID to _133.objID + _133.objRange - 1 do (
				p = (for p in _2e4._f0._f0 where p._3b9.objID == x collect p)[1]		
				append objSelection p
				print p._3b9.name
			)
			format "\n"
			
-- 			for x=1 to _133.Bind_Indices_Array.count do (
-- 				bi = _133.Bind_Indices_Array[x]
-- 				
-- 				v = meshop.getvert msh x
-- 				v *= (getnodebyname objSelection[bi[1]]._3b9.name).transform
-- 				meshop.setvert msh x v
-- 			)
		)
	)
	if obj._fa.boneID != 0 do (
		newBone = bonesys.createbone	\
		obj._f9.tfm.row4	\
		(obj._f9.tfm.row4 + 0.01 * (normalize obj._f9.tfm.row1)) \
		(normalize obj._f9.tfm.row3)
		newBone.width = 0.1
		newBone.height = 0.1
		newBone.wirecolor = yellow
		newbone.showlinks = true
		newBone.transform = obj._f9.tfm
		newBone.name = obj._3b9.name
		newBone.setBoneEnable false 0
		newBone.pos.controller = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()
		
		Node_Array[obj._3b9.objID] = newBone
		if obj._12b.objParentID != 0 do (
			newBone.parent = Node_Array[obj._12b.objParentID]
			newBone.transform *= newBone.parent.transform
		)
	)
	if obj._fa.boneID == 0 and obj._3b9.vertCount == 0 do (
		d = dummy name:obj._3b9.name boxsize:[0.1,0.1,0.1]
		d.transform = obj._f9.tfm
		
		Node_Array[obj._3b9.objID] = d
		if obj._12b.objParentID != 0 do (
			d.parent = Node_Array[obj._12b.objParentID]
			d.transform *= d.parent.transform
		)
	)
)
*/

print Node_Array.count
print _2e4._f0._f0.count

if ((ftell f) == FileSize) do format "Reached end of file.\n"


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
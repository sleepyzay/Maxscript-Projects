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
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn ReadUntilOffset bstream offset = (
	local str = ""
	while ((ftell bstream) < offset) do (
		str += bit.intAsChar (ReadByte bstream #unsigned)
	)
   str
)
fn checkNull var chunkType = (
	if var > 0 do format "% %\n" (bit.intashex (var)) (bit.intashex(chunkType))
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

-- fname = GetOpenFileName caption:"" types:" (*.)|*.bin" historyCategory:""
fname=@"D:\models\ripped\halo cea\cyborg_iga.bin"
-- fname = @"C:\Users\Owner\Desktop\models\halo cea\cortana.bin"
-- fname=@"C:\Users\Xavier\Documents\stuff\models\ripped\halo cea\cyborg.bin"
-- fname=@"C:\Users\Xavier\Documents\stuff\models\ripped\halo cea\cyborg_fp.bin"
-- fname = @"C:\Users\Xavier\Documents\stuff\projects\models\ripped\halo cea\elite.bin"
-- fname = @"C:\Users\1234\Desktop\New folder\cyborg_iga.bin"
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
		format "chunkType: 0x% chunkOffset: 0x% chunkLength: 0x%\n" (bit.intashex (chunk.type)) (bit.intashex (chunk.offset)) (bit.intashex (chunk.length))
	)
)

struct _2e4 (_2e5,_316,_155,_scene)	--scene
	struct _2e5 (magic, fileName)
	struct _316 (undefined)
	struct _155 (texCount,_156)
		struct _156 (texName)

struct _scene (objCount,obj)	--f0

struct _f0	(_12c,_3b9,_12e,_f1,_130,_f2,_11d,_f8,_12f,_f9,_fa,_fd,_115,_107,_116,_12b)	--f0
	struct _12c	(objCount)
	struct _3b9	(name,objID,ukw,ukw2,ukw3,ukw4, vertCount, faceCount)
	struct _12e	(ukw,ukw2,ukw3,ukw4)
	struct _f1		(vertCount, ukw, ukw2, ukw3, ukw4, ukw5, ukw6, Vert_Array)
	struct _130	(uvCount, UV_Array, Normal_Array)
	struct _f2		(faceCount, Face_Array)
	struct _11d	(ukw,bbmin,bbMax)
	struct _f8		(ukwID)
	struct _12f	(ukwCount, ukw,ukw2)
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
			struct _134	(skinCompoundID)
			struct _132	(ukwID,ukwID2,ukwID3,ukwID4)
			struct _10b	(ukwCount,_114,_11f,_1ba)
				struct _114 (undefined)
				struct _11f (undefined)
				--struct _1ba (undefined)	--may cause problems in the future
			struct _11c	(ukw,ukw2)
			struct _120	(undefined)
			struct _128	(ukw,ukw2,ukw3,ukw4,ukw5,ukw6,ukw7,ukw8,ukw9)
	struct _116	(_117)
			struct _117	(ukw,bindDataCount,_133,_11a)
				struct _133	(ukw,ukw2,Blend_Indices_Array)
				struct _11a	(Blend_Weight_Array)
	struct _12b	(objParentID)

fn readModel f parent var =(--)
	chunk = _header()
	printChunkInfo chunk var
	case chunk.type of (--)
		0x01:(			--delimeter
-- 			format "Reached delimeter in 0x%.\n" (bit.intashex(parent))
			exit
		)
		0xf0:(			--geometryContainer
			case parent of (
				0xf0:(	--obj
					while ((ftell f) < chunk.end) do (
						readModel f chunk.type 1					--3b9, 12e, f1, 130, f2, 11d, f8, 12f, f9, fa, fd, 115, 107, 116, 12b
					)
					print obj._3b9.name
					format "\n"
				)
				0x2e4:(	--scene
					_2e4._scene.objCount = readModel f chunk.type 0			--12c
					for x=1 to _2e4._scene.objCount do (
-- 						print "obj"
						global obj = (_f0 \
							_12c: 	(_12c	objCount: undefined) \
							_3b9: 	(_3b9	name: undefined objID: undefined ukw: undefined ukw2: undefined ukw3: undefined ukw4: undefined  vertCount: undefined  faceCount: undefined) \
							_12e: 	(_12e	ukw: undefined ukw2: undefined ukw3: undefined ukw4:undefined) \
							_f1:		(_f1		vertCount: undefined ukw: undefined ukw2: undefined ukw3: undefined ukw4: undefined ukw5: undefined ukw6: undefined Vert_Array: #()) \
							_130: 	(_130	uvCount: undefined UV_Array: #() Normal_Array: #()) \
							_f2: 		(_f2		faceCount: undefined Face_Array: #()) \
							_11d: 	(_11d	ukw: undefined bbMin:undefined bbMax:undefined) \
							_f8: 		(_f8		ukwID: undefined) \
							_12f: 	(_12f	ukwCount: undefined ukw: undefined ukw2:undefined) \
							_f9: 		(_f9		tfm:undefined) \
							_fa: 		(_fa		boneID:undefined) \
							_fd:		(_fd		_1ba:undefined) \
							_115: 	(_115	meshParameterString:undefined) \
							_107: 	(_107	_f3:undefined _104:undefined) \
							_116: 	(_116	_117:undefined) \
							_12b: 	(_12b	objParentID:0)
						)
						while true do readModel f chunk.type 0	--0xf0
						append _2e4._scene.obj obj
					)
				)
				default:(
					format "Undefined Parent: 0x%\n" (bit.intashex(parent))
					exit
				)
			)
			fseek f chunk.end #seek_set
		)
		0xf1:(			--vertexData			
			obj._f1.vertCount = readlong f
			if obj._f1.vertCount > 0 do (
				ReadFixedByteString f 0x0c 1 0		--buffer info?
				
				obj._f1.ukw = readshort f #unsigned + 1
				obj._f1.ukw2 = readshort f #unsigned + 1
				obj._f1.ukw3 = readshort f #unsigned + 1
				obj._f1.ukw4 = readshort f #unsigned + 1
				obj._f1.ukw5 = readshort f #unsigned + 1
				obj._f1.ukw6 = readshort f #unsigned + 1
				
-- 				format "% % % % % % %\n" obj._f1.ukw obj._f1.ukw2 obj._f1.ukw3 obj._f1.ukw4 obj._f1.ukw5 obj._f1.ukw6 obj._3b9.name
				
				for x=1 to obj._f1.vertCount do (
					vx = readshort f / 65535.0
					vy = readshort f / 65535.0
					vz = readshort f / 65535.0
					vw = readshort f / 65535.0
					
					append obj._f1.Vert_Array([vx,vy,vz,vw])
				)
			)
		)
		0xf2:(			--faceData
			obj._f2.faceCount = readlong f
			for x=1 to obj._f2.faceCount do (
				fa=Readshort f +1
				fb=Readshort f +1
				fc=Readshort f +1
				
				append obj._f2.Face_array[fa,fb,fc]
			)
		)
		0xf3:(			--unknownSubMeshDataContainer
			--not finished
			obj._107._f3 = (_f3	\
				ukwCount: undefined	\
				_103:		#()
			)
			
			obj._107._f3.ukwCount = readlong f
			for x=1 to obj._107._f3.ukwCount do (
				while true do readModel f chunk.type 0					--103
			)
-- 			format "\n"
		)
		0xf8:(			--unknownMeshData
			obj._f8.ukwID = readlong f #unsigned		--always -1
		)
		0xf9:(			--objTransform
-- 			ReadFixedByteString f 0x10 0 1
-- 			ReadFixedByteString f 0x10 0 1
-- 			ReadFixedByteString f 0x10 0 1
-- 			ReadFixedByteString f 0x10 0 1
-- 			format "\n"
-- 			fseek f -0x40 #seek_cur
			
			m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
			m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
			m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
			m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
			obj._f9.tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
		)
		0xfa:(			--boneID
			obj._fa.boneID = readlong f #unsigned + 1
		)
		0xfd:(			--lodDistanceDataContainer
			while ((ftell f) < chunk.end) do (
				readModel f chunk.type 0					--1ba
			)
		)
		0x103:(		--unknownSubMeshData
			ukw = readlong f	--null?
		)
		0x104:(		--subMeshData
			obj._107._104 = (_104	\
				subMeshCount: undefined	\
				_105: #()	\
				_10d: #()	\
				_134: #()	\
				_132: #()	\
				_10b: #()	\
				_11c: #()	\
				_120: #()	\
				_128: #()
			)
			
			obj._107._104.subMeshCount = readlong f
			for x=1 to obj._107._104.subMeshCount do (
				while true do readModel f chunk.type 0	--105, 10d, 134, 132, 10b, 11c, 120, 128
			)
-- 			format "\n"
		)
		0x105:(		--subMeshFaceData
			_s105 = _105()
			
			_s105.faceOffset = readlong f #unsigned
			_s105.faceCount = readlong f #unsigned
			
			append obj._107._104._105 (_s105)
		)
		0x107:(		--subMeshDataContainer
			while ((ftell f) < chunk.end) do (
				readModel f chunk.type 0					--f3, 104
			)
-- 			format "\n"
		)
		0x10b:(		--unknownSubMeshData	/	material related?
			s10b  = (_10b	\
				ukwCount: undefined	\
				_114: #()	\
				_11f: #()	\
				_1ba: #()
			)
			s10b.ukwCount = readlong f
			for x=1 to s10b.ukwCount do (
				while true do readModel f chunk.type 0	--10e, 114, 11f, 1ba
			)
			
			append obj._107._104._10b s10b
		)
		0x10d:(		--subMeshVertexData
			_s10d = _10d()
			
			_s10d.vertOffset = readlong f #unsigned
			_s10d.vertCount = readlong f #unsigned
			
			append obj._107._104._10d (_s10d)
		)
		0x10e:(			--ukwMatData
			ReadFixedByteString f 0x0a 0 0
			fseek f chunk.end #seek_set
		)
		0x114:(		--ukwMatData
			ukw = readshort f
			fseek f chunk.end #seek_set
		)
		0x115:(		--meshParameterString
			obj._115.meshParameterString = ReadUntilOffset f chunk.end
		)
		0x116:(		--vertexBindContainer
-- 			while ((ftell f) < chunk.end) do (	--1 per obj, loop just incase
				readModel f chunk.type 0					--117
-- 			)
		)
		0x117:(		--vertexBindData
			obj._116._117 = _117()
			
			obj._116._117.ukw = readlong f #unsigned + 1	--boneMapCount?
			obj._116._117.bindDataCount = readlong f			--always 3/indeces,weights,delimiter
-- 			format "%: %\n" (bit.intashex(chunk.type)) obj._116._117.ukw
			
			for x=1 to obj._116._117.bindDataCount do (
				readModel f chunk.type 0					--133, 11a
			)
		)
		0x11a:(			--vertexBlendWeight
			obj._116._117._11a = (_11a Blend_Weight_Array: #())
			
			for x=1 to obj._f1.vertCount do (
				weight1 = readbyte f #unsigned
				weight2 = readbyte f #unsigned
				weight3 = readbyte f #unsigned
				weight4 = readbyte f #unsigned
				
				append obj._116._117._11a.Blend_Weight_Array [weight1,weight2,weight3,weight4]
			)
		)
		0x11c:(			--unknownSubMeshData	/	uvClamp?
			_s11c = _11c()
			
			_s11c.ukw = readfloat f
			_s11c.ukw2 = readfloat f
			
-- 			print obj._3b9.name
-- 			format "% %\n" _s11c.ukw _s11c.ukw2
			
			append obj._107._104._11c (_s11c)
		)
		0x11d:(		--meshBoundBox
			obj._11d.ukw = readlong f	--always 1/scale?
			obj._11d.bbMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			obj._11d.bbMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
		)
		0x11f:(			--ukwMatData
			ukw = readshort f
			fseek f chunk.end #seek_set
		)
		0x120:(		--unknownSubMeshData	/	all 0's
			fseek f chunk.end #seek_set
		)
		0x128:(		--unknownSubMeshData
-- 			ReadFixedByteString f 0x1c 1 1
			
			_s128 = _128()
			
			_s128.ukw = readlong f
			_s128.ukw2 = readlong f	--0x00ff1200
			_s128.ukw3 = readshort f
			_s128.ukw4 = readshort f
			_s128.ukw5 = readlong f	--0xff's
			_s128.ukw6 = readlong f
			_s128.ukw7 = readlong f
			_s128.ukw8 = readshort f
			_s128.ukw9 = readshort f
			
			append obj._107._104._128 (_s128)
		)
		0x12b:(		--objParentID
			obj._12b.objParentID = readlong f #unsigned + 1
		)
		0x12c:(			--objCount
			objCount = readlong f
			return objCount
		)
		0x12e:(			--unknownMeshData
			--"12 00 87 70 01 "--
			
			obj._12e.ukw = readshort f #unsigned	--0x12
			obj._12e.ukw2 = readbyte f #unsigned
			obj._12e.ukw3 = readbyte f #unsigned
			obj._12e.ukw4 = readbyte f #unsigned	--geometryFlag?
			
-- 			format "% % % %\n" obj._12e.ukw obj._12e.ukw2 obj._12e.ukw3 obj._12e.ukw4
		)
		0x12f:(			--unknownMeshData
			obj._12f.ukwCount = readbyte f
			for x=1 to obj._12f.ukwCount do (
-- 				ReadFixedByteString f 0x05 0 1
				
				obj._12f.ukw = readbyte f #unsigned
				obj._12f.ukw2 = readbyte f #unsigned
				null = readbyte f
				null = readbyte f
				null = readbyte f
-- 				format "% % %\n" obj._12f.ukw obj._12f.ukw2 obj._3b9.name
			)
		)
		0x130:(		--uvData/other vertexData?
			--pretty sure other vertex data is in here
			obj._130.uvCount = readlong f
			
			--"2e 00 00 10 02 42 00 20 08 "	--
			ReadFixedByteString f 0x9 0 0	--buffer info, size of uv included
			for x=1 to obj._130.uvCount do (			--currently broken
-- 				ReadFixedByteString f 0x08 1 1
				
				nx = readbyte f #unsigned
				ny = readbyte f #unsigned
				nz = readbyte f #unsigned
				ukw = readbyte f #unsigned
				tu=ReadBEWord f 
				tv=ReadBEWord f 
				
				append obj._130.UV_array([tu,1-tv,0] / 32767.0)
				append obj._130.Normal_array([nx,ny,nz] / 255.0 * 2 - 1)
			)
			
			fseek f chunk.end #seek_set	--dosent always read correctly
		)
		0x132:(		--subMeshTransform? / may be reading wrong
			_s132 = _132() 
-- 			ReadFixedByteString f 0x06 1 1
			
			_s132.ukwID = readshort f #unsigned + 1		--objID
			_s132.ukwID2 = readbyte f + 1						--not sure even if ID
			_s132.ukwID3 = readshort f #unsigned + 1	--objID
			_s132.ukwID4 = readbyte f + 1						--not sure even if ID
			
-- 			format "%	%	%	%\n" _s132.ukwID _s132.ukwID2 _s132.ukwID3 _s132.ukwID4
			
			append obj._107._104._132 (_s132)
		)
		0x133:(		--vertexBlendIndices
			obj._116._117._133 = (_133 ukw:undefined ukw2:undefined Blend_Indices_Array:#())
			
			obj._116._117._133.ukw = readshort f #unsigned + 1
			obj._116._117._133.ukw2 = readshort f #unsigned + 1	--same as obj._116._117.ukw
			
-- 			format "%: % %\n" (bit.intashex(chunk.type)) obj._116._117._133.ukw obj._116._117._133.ukw2	
			
			for x=1 to obj._f1.vertCount do (
				bone1 = readbyte f #unsigned + 1
				bone2 = readbyte f #unsigned + 1
				bone3 = readbyte f #unsigned + 1
				bone4 = readbyte f #unsigned + 1
				
				append obj._116._117._133.Blend_Indices_Array [bone1, bone2, bone3, bone4]
			)
		)
		0x134:(		--skinCompoundID
			_s134 = _134()
			
			_s134.skinCompoundID = readshort f #unsigned + 1	--references SkinCompound obj's / transformed by it?
			
			append obj._107._104._134 (_s134) 
		)
		0x155:(		--textureNameContainer
			_2e4._155.texCount = readlong f
			for x=1 to _2e4._155.texCount do (
				_2e4._155._156[x] = _156 texName: (readModel f chunk.type 0)	--156
			)	
		)
		0x156:(		--textureName
			texName = ReadStringUntilOffset f chunk.end
			return texName
		)
		0x1ba:(			--script/meshMetaData
			script = ReadStringUntilOffset f chunk.end
-- 			if script.count > 0 do print script
		)
		0x21d:(		--null
			null = readlong f	--count?
		)
		0x2e4:(			--scene
			_2e4 = _2e4	\
				_2e5:	(_2e5 magic: undefined fileName: undefined) \
				_316:	(undefined) \
				_155:	(_155 texCount: undefined _156:#()) \
				_scene:	(_scene objCount:undefined obj:#())
			
			--file info
			while true do readModel f chunk.type 0			--2e5, 316, 155
			
			--model info
			while true do readModel f chunk.type 0			--f0
			
			--animation/track info
			while true do readModel f chunk.type 0			--2e8, 2e6
			
 			--metaData?
			while true do readModel f chunk.type 0			--1ba, 21d, 311, 304, 305, 312
			
			--bound box/skeleton
-- 			while true do readModel f chunk.type 0			--308, 30e
			
			return _2e4
		)
		0x2e5:(			--fileName
			_2e4._2e5.magic = readlong f
			_2e4._2e5.fileName = ReadStringUntilOffset f chunk.end
		)
		0x2e6:(			--trackDataContainer
			trackCount = readlong f
			format "trackCount: %\n\n" trackCount
			for x=1 to trackCount do (
				readModel f chunk.type 0				--2fd
			)
		)
		0x2e8:(	 		--animationDataContainer
-- 			nodeCount = readlong f
-- 			for x=1 to nodeCount do (				
-- 				while true do readModel f chunk.type 0					--2e9
-- 			)
			fseek f chunk.end #seek_set
		)
		0x2f3:(			--unknownTrackData
			ukw = readlong f	--float/null?
			if ukw != 0 do print ukw
		)
		0x2f4:(			--trackNumFrames
			trackNumFrames = readfloat f
			format "trackNumFrames %\n\n" trackNumFrames
		)
		0x2fd:(			--trackData
			while ((ftell f) < chunk.end) do (
				readModel f chunk.type 0				--2fe, 2ff, 300, 301, 2f3, 2f4, 314, 307
			)
		)
		0x2fe:(			--trackName
			trackName = ReadStringUntilOffset f chunk.end
			format "trackName: %\n" trackName
		)
		0x2ff:(			--trackStartFrame
			trackStartFrame = readfloat f
			format "trackStartFrame %\n" trackStartFrame trackStartFrame
		)
		0x300:(		--trackEndFrame
			trackEndFrame = readfloat f
			format "trackEndFrame %\n" trackEndFrame trackEndFrame
		)
		0x301:(		--unknownTrackData
			ukw = readfloat f	--time multiplier?
-- 			format "% %\n" (bit.intashex(chunk.type)) ukw
		)
		0x304:(		--mayaExportInfo
			exportInfo = ReadStringUntilOffset f chunk.end
-- 			print exportInfo
		)
		0x305:(		--markerContainer?
			readModel f chunk.type 0				--30d
-- 			fseek f chunk.end #seek_set
		)
		0x307:(		--unknownTrackData/boundBox?
			--entire model bound box?--
			ukw = readlong f	--count?, always 1
			bbMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			bbMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			bbCurr = bbMax - bbMin
-- 			b = box()
-- 			b.width = bbCurr[1]
-- 			b.length = bbCurr[2]
-- 			b.height = bbCurr[3]
		)
		0x308:(		--boundBox
			--entire model bound box?--
			ukw = readlong f	--count?, always 1
			bbMin = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			bbMax = ([(readfloat f),(readfloat f),(readfloat f)]*fscale)
			bbCurr = bbMax - bbMin
-- 			b = box()
-- 			b.width = bbCurr[1]
-- 			b.length = bbCurr[2]
-- 			b.height = bbCurr[3]
		)
		0x30d:(		--global skeleton
			nodeCount = readlong f
			ukw = readshort f
			ukw2 = readbyte f
-- 			format "% %\n" (bit.intashex(ukw)) (bit.intashex(ukw))
			
			if ((ftell f) < chunk.end) do (
				BNArr=#()
				for x=1 to nodeCount do (
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [m14,m24,m34]
					
-- 					newBone = bonesys.createbone	\
-- 					tfm.row4	\
-- 					(tfm.row4 + 0.01 * (normalize tfm.row1)) \
-- 					(normalize tfm.row3)
-- 					newBone.width = 0.1
-- 					newBone.height = 0.1
-- 					newBone.wirecolor = white
-- 					newbone.showlinks = true
-- 					newBone.transform = tfm
-- 					
-- 					pos = [m41,m42,m43]
-- 					pos *= tfm
-- 					newBone.pos += -pos
-- 					
-- 					newBone.setBoneEnable false 0
-- 					newBone.pos.controller = TCB_position ()
-- 					newBone.rotation.controller = TCB_rotation ()

-- 					b = sphere()
-- 					b.radius = 0.5
-- 					b.wirecolor = green
-- 					b.transform = tfm
-- 					b.pos = [m41,m42,m43]
-- 					b.pos *= tfm
-- 					b.pos *= -1
-- 	-- 				
-- 					append BNArr newBone
				)
			)
		)
		0x30e:(			--unknownData
-- 			ukwCount = readlong f
-- 			for x=1 to ukwCount do (
-- 				readModel f chunk.type 0
-- 			)
			fseek f chunk.end #seek_set
		)
		0x311:(		--meshLodData
			ukwCount = readshort f
			for x=1 to ukwCount do (
-- 				ReadFixedByteString f 0x04 1 1
				objID = readshort f #unsigned + 1
				lodID = readbyte f #unsigned + 1
				lodFlag = readbyte f #unsigned + 1		--1 == lowest lod
				
-- 				for o in objArr where o.ID == objID do print o.name
-- 				format "\n"
			)
		)
		0x312:(		--tpl info
			-- looks like json --
			stringLength = readlong f
			fseek f stringLength #seek_cur
		)
		0x314:(		--soundClipData
			soundCount = readlong f	--float/null?			
			for x=1 to soundCount do (
				ReadFixedByteString f 0x05 0 0
				
				stringLength = readlong f
				soundName = ReadFixedString f stringLength
-- 				print soundName
			)
		)
		0x316:(		--unknownData
			ReadFixedByteString f 3 0 0	--"02 01 01"
		)
		0x3b9:(		--objInfo
			obj._3b9.name = readstring f
			obj._3b9.objID = readshort f #unsigned + 1
			obj._3b9.ukw = readshort f 			--0x24
			obj._3b9.ukw2 = readshort f			--0x04 or 0x08 if mesh
			obj._3b9.ukw3 = readbyte f			--0x08 if node and has parent
			obj._3b9.ukw4 = readshort f			--0x104 if lights
			obj._3b9.vertCount = readlong f
			obj._3b9.faceCount = readlong f
			
-- 			format "%	%	%	%	%\n" obj._3b9.ukw obj._3b9.ukw2 obj._3b9.ukw3 obj._3b9.ukw4 obj._3b9.name
			
			fseek f chunk.end #seek_set
		)
		default:(
			format "unknown chunk type: 0x% parent: 0x%\n" (bit.intashex(chunk.type)) (bit.intashex(parent))
-- 			fseek f chunk.end #seek_set
			exit
		)
	)
)


_2e4 = readModel f 0 0
for obj in _2e4._scene.obj do (
	format "%	%	%	%\n" obj._fa.boneID obj._3b9.objID obj._12b.objParentID obj._3b9.name

	p = (for p in _2e4._scene.obj where p._3b9.objID == obj._12b.objParentID collect p)[1]	--parentObj
	if p != undefined then (
-- 		if obj._fa.boneID != 0 do (			
-- 			newBone = bonesys.createbone	\
-- 			obj._f9.tfm.row4	\
-- 			(obj._f9.tfm.row4 + 0.01 * (normalize obj._f9.tfm.row1)) \
-- 			(normalize obj._f9.tfm.row3)
-- 			newBone.width = 0.1
-- 			newBone.height = 0.1
-- 			newBone.wirecolor = yellow
-- 			newbone.showlinks = true
-- 			newBone.transform = obj._f9.tfm
-- 			newBone.name = obj._3b9.name
-- 			newBone.setBoneEnable false 0
-- 			newBone.pos.controller = TCB_position ()
-- 			newBone.rotation.controller = TCB_rotation ()
-- 			
-- 			newBone.parent = getnodebyname p._3b9.name
-- 			newBone.transform *= newBone.parent.transform
-- 		)
		if obj._3b9.vertCount != 0 do (
			
			msh = mesh vertices:obj._f1.Vert_Array faces:obj._f2.Face_Array
			msh.numTVerts = obj._130.uvCount
			msh.wirecolor = random black white
			msh.name = obj._3b9.name
			buildTVFaces msh
			for j = 1 to obj._130.UV_Array.count do setTVert msh j obj._130.UV_Array[j]
			for j = 1 to obj._f2.Face_Array.count do setTVFace msh j obj._f2.Face_Array[j]
 			--for j = 1 to obj._130.Normal_array.count do setNormal msh j obj._130.Normal_array[j]
 			
			msh.parent = getnodebyname p._3b9.name
-- 			msh.transform *= msh.parent.transform
			
			xbounds = [obj._11d.bbMin.x, obj._11d.bbMax.x]
			ybounds = [obj._11d.bbMin.y, obj._11d.bbMax.y]
			zbounds = [obj._11d.bbMin.z, obj._11d.bbMax.z]
			
			dMat = matrix3 [1, 0, 0] [0, 1, 0] [0, 0, 1] [.5,.5,.5]
			bMat = matrix3 [xbounds.y - xbounds.x, 0, 0] [0, ybounds.y - ybounds.x, 0] [0, 0, zbounds.y - zbounds.x] [xbounds.x, ybounds.x, zbounds.x]
			vmat = dMat * bMat
			
			mshMin = msh.min
			mshMax = msh.max
			
-- 			msh.transform *= vmat
			for i=1 to (meshop.getNumVerts msh) do (
				v = meshop.getVert msh i
				
-- 				v += ((mshMax - mshMin)/2)
				v+=[0.5,0.5,0.5]
				v = obj._11d.bbMin + v * (obj._11d.bbMax - obj._11d.bbMin) 
				
				meshop.SetVert msh i v
			)
 			
-- 			if obj._11d.bbMax[1] > 0 do scale msh ((obj._11d.bbMax - obj._11d.bbMin) / (msh.max - msh.min))
		)
-- 		if obj._fa.boneID == 0 and obj._3b9.vertCount == 0 do (			
-- 			h = dummy name:obj._3b9.name boxsize:[1,1,1]
-- 			h.transform = obj._f9.tfm
-- 			
-- 			h.parent = getnodebyname p._3b9.name
-- 			h.transform *= h.parent.transform
-- 		)
	)
	else (
		rootRT = dummy name:obj._3b9.name boxsize:[1,1,1]
		rootRT.transform = obj._f9.tfm
	)
)

if ((ftell f) == FileSize) do format "Reached end of file.\n"


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
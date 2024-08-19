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
   str
   if var == 1 do fseek bstream -fixedLen #seek_cur
   if var2 == 1 do print str
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
fn Readword fstream = (
return readshort fstream #unsigned
)
fn getBone boneArray boneName = (
	compare = filterstring boneName "_"
	for x=1 to boneArray.count do (	--loop through bone names until we reached the desired bone
		suffix = filterstring boneArray[x].name "_"
		if compare[compare.count] == suffix[suffix.count] do (
			return boneArray[x]
		)
-- 		else (
-- 			return undefined
-- 		)
	)
)
fn remapBones f boneName BNArr = (
	for x=1 to boneName.count do (
		animBoneName = boneName[x]
		animBoneNameSuffix = (filterstring animBoneName "_")[(filterstring animBoneName "_").count]
		for b in BNArr do (
			modelBoneName = b.name
			modelBoneNameSuffix = (filterstring modelBoneName "_")[(filterstring modelBoneName "_").count]
			
			if animBoneNameSuffix == modelBoneNameSuffix do (
				boneName[x] = modelBoneName
			)
		)
	)
)

struct translationData ( BoneId, FrameID, Position )
struct rotationData (BoneId, FrameID, Quaternion  )

fname = GetOpenFileName caption:"" types:" (*.)|*.amm" historyCategory:""
-- fname=@"C:\Users\Xavier\Desktop\New folder (4)\shin budokai\BCGGT_out\BCGGT_006.amm"
-- fname=@"C:\Users\Xavier\Desktop\New folder (4)\shin budokai\BCPIC_out\BCPIC_005.amm"
-- fname = @"C:\Users\Xavier\Desktop\New folder (4)\FULL_AFS_FILE_DUMP\BCBRLM1_out\BCBRLM1_005.amm"
-- fname = @"C:\Users\Xavier\Desktop\FULL_AFS_FILE_DUMP\BC18G_out\BC18G_005.bin"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=5
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _animTable (
	frameCount = readshort f,
	unk = readshort f,				--0,5,8
	animOffset = readlong f
)
struct _boneAnimInfo (
	channelCount = readlong f,
	animDataOffset = readlong f
)

struct _channelTable (
	channelId = readshort f + 1,
	frameIDSize = readshort f,
	frameCount = readshort f,
	ukw = readshort f,	--always 1
	frameIDOffset = readlong f,
	frameOffset = readlong f
)

magic = ReadFixedString f 4
headerLength = readlong f
null = readlong f
ukw = readlong f	--always 2
animTableCount = readlong f
animTableOffset = readlong f
boneCount = readlong f
boneNameOffset = readlong f

fseek f boneNameOffset #seek_set
boneName = for x=1 to boneCount collect (ReadFixedString f 0x20)
	
BNArr = for o in geometry where classOf o == boneGeometry collect o
for o in BNArr do o.assumeSkinPose()

remapBones f boneName BNArr

-- print boneName

fseek f animTableOffset #seek_set
animTableArray = #()
for x=1 to animTableCount collect (
	animTable = _animTable()
	if animTable.animOffset > 0 do append animTableArray animTable
)
format "animCount: %\n" animTableArray.count
format "animTableCount: % \n" animTableCount
format "animBoneCount: %	modelBoneCount: %\n" boneName.count BNArr.count

anim = 1
format "animSelected: %\n" anim
for x=anim to anim do (	--animCount
	fseek f animTableArray[x].animOffset #seek_set
-- 	printhere f
	
	boneAnimInfoArray = for y=1 to boneCount collect (boneAnimInfo = _boneAnimInfo())
-- 	print boneAnimInfoArray
	
	translations = #()
	rotations = #()
	for y=1 to boneCount do (
		fseek f boneAnimInfoArray[y].animDataOffset #seek_set
		
		format "channelCount: % animDataOffset: %	boneName: %\n"  boneAnimInfoArray[y].channelCount (formattedPrint (ftell f as integer) format:"05x") boneName[y]
		
		channelTableArray = for z=1 to boneAnimInfoArray[y].channelCount collect (channelTable = _channelTable())
		for channelTable in channelTableArray do (
			fseek f channelTable.frameIDOffset #seek_set
			if channelTable.frameIDSize == 0 do frameID = for j=1 to channelTable.frameCount collect readbyte f #unsigned
			if channelTable.frameIDSize == 1 do frameID = for j=1 to channelTable.frameCount collect readshort f #unsigned
			
			fseek f channelTable.frameOffset #seek_set
			if channelTable.channelId == 1 do (
				for j=1 to channelTable.frameCount do (
					rot = rotationData()
					
					rx = (readword f / 32768.0)*pi
					ry = (readword f / 32768.0)*pi
					rz = (readword f / 32768.0)*pi
					
					rot.BoneId = y
					rot.FrameID = frameID[j]
					rot.Quaternion =  (eulerAngles (RadToDeg (rx)) (RadToDeg (ry)) (RadToDeg (rz))) as quat
					append rotations rot
				)
			)
			if channelTable.channelId == 2 do (
				for j=1 to channelTable.frameCount do (
					tran = translationData()
					
					tx = readfloat f
					ty = readfloat f
					tz = readfloat f
					
					tran.BoneId = y
					tran.FrameID = frameID[j]
					tran.Position = [tx,ty,tz]*fscale
					append translations tran
				)
			)
			if channelTable.channelId == 3 do (
				throw "3"
			)
		)
	)
	
	with animate on(
		sliderTime = 0
		framerate = 45
		animationRange = interval 1 animTableArray[x].frameCount
		deleteKeys objects #allKeys
		
		for i=1 to rotations.count do (
-- 			b = getBone BNArr boneName[rotations[i].boneId]
			b = getnodebyname boneName[rotations[i].boneId]
-- 			b = BNArr[rotations[i].boneId]
			t = rotations[i].FrameID
			q = rotations[i].Quaternion
			
			if(b!=undefined) then (	--works for some reason, should be "OK"
				at time t
				b.Controller.Rotation = q
			)
		)
		
-- 		bcArr=#()	--cheap fix --referencing from the original position, need to reload the model per animation load
-- 		for i=1 to translations.count do (
-- 			bcArr[i] = copy (getnodebyname boneName[translations[i].boneId])
-- 		)
		
		for i=1 to translations.count do (
-- 			b = getBone BNArr boneName[translations[i].boneId]
			b = getnodebyname boneName[translations[i].boneId]
-- 			b = BNArr[translations[i].boneId]
			t = translations[i].FrameID
			p = translations[i].Position
			
			if(b != undefined) then (
				at time t
					in coordsys parent b.pos = b.skinpos + p
			)
		)
		
		
		stopAnimation()
	)
	
)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
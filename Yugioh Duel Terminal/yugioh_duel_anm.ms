--sleepyzay--

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

fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer) )as string))
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
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn getName bstream offset = (
	name = ReadFixedString f (offset-(ftell bstream))
	return Name
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
fn printMatrix fstream = (
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	ReadFixedByteString fstream 0x10 0 1
	format "\n"
	fseek fstream -0x40 #seek_cur
)
struct weight_data (
	boneids,weights
)


fscale=5
fname = GetOpenFileName caption:"" types:" (*.)|*.anm" historyCategory:""
-- fname = @"E:\models\ripped\YGO Duel Terminal\A001_Blueeyes_a.pc.anm"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
	f = fopen fname "rb"   --open file in read only format
	actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
	FileExtension = getFileNameType  fname
	FilePath = getFileNamePath fname
	FileName = (FilterString (getFileNameFile fname) ".")[1]
	clearlistener()

	Print "===================================="
	print (FileName + FileExtension) as string
	Print "===================================="


	struct _boneInfo (
		boneId = readbyte f,
		parentId = readbyte f
	)

	allBones = for o in geometry where classOf o == boneGeometry collect o	--out of order
	BNArr=#()
	for x=1 to allBones.count do (
		boneId = ((filterstring (allBones[x].name) "_")[1] as integer)
		BNArr[boneId] = allBones[x]
	)
	--for o in BNArr do print o
	
	deleteKeys objects #allKeys
	stopanimation()
	
	
	if allBones.count != 0 then (
		print "skeleton data found"
		Print "===================================="
		
		ukw = readlong f	--010001ff / flag?
		numFrames = readlong f
		null = readlong f
		null2 = readlong f
		boneInfoSectionOffset = readlong f
		boneAnimSectionOffset = readlong f
		null3 = readlong f
		
		animationRange = interval 0 numFrames
		
		fseek f boneInfoSectionOffset #seek_set
		ukw3 = readlong f	--030001ff
		boneCount = readlong f
		boneInfoOffset = readlong f + boneInfoSectionOffset
		boneInfoSectionLength = readlong f
		
		boneInfoArray = for x=1 to boneCount collect (boneInfo = _boneInfo())
		
		fseek f boneAnimSectionOffset #seek_set
		ukw4 = readlong f	--020001ff
		null = readlong f
		
		boneAnimOffsetArray = #()
		while (offset = readlong f) != 0 do append boneAnimOffsetArray (offset + boneAnimSectionOffset)

		
		
		j = 0
		for x=1 to boneAnimOffsetArray.count do (
			fseek f boneAnimOffsetArray[x] #seek_set
			ReadFixedByteString f 0x10 1 1
			
			frameType = readlong f
			frameCount = readshort f
			boneId = readshort f + 1
			frameTimeOffset = readlong f + boneAnimOffsetArray[x]
			frameDataOffset = readlong f + boneAnimOffsetArray[x]
			
			frameTime=#()
			fseek f frameTimeOffset #seek_set
			if frameTimeOffset != boneAnimOffsetArray[x] then (
				frameTime = for y=1 to frameCount collect (readshort f #unsigned)
			)
			else (
				frameTime = #(frameCount)	--frameCount is then interpreted as sole frame?
				frameCount = 1
				--frameTime = for y=1 to frameCount collect (frameCount + 1)
				--frameTime = for y=1 to frameCount collect (y-1)
			)
			
			for o in frameTime where j < o do j = o
			
			--print frameTime #nomap
			
			rotAnimData=#()
			posAnimData=#()
			fseek f frameDataOffset #seek_set
			for y=1 to frameCount do (
				if frameType == 0x01 do (	--rotation
					qx = readfloat f
					qy = readfloat f
					qz = readfloat f
					qw = readfloat f
					
					append rotAnimData (quat qx qy qz qw)
					with animate on (
						b = BNArr[boneId]
						if(b != undefined) then (
							at time frameTime[y]
								b.Controller.Rotation = inverse (quat qx qy qz qw)
						)
					)
				)
				if frameType == 0x1d do (	--translation				
					px = readfloat f
					py = readfloat f
					pz = readfloat f
					
					append posAnimData (point3 px py pz)
					with animate on (
						b = BNArr[boneId]
						if (b!=undefined) then (
							at time frameTime[y]
								b.Controller.Position = (point3 px py px) * fscale
								--in coordsys parent b.pos = b.skinpos + (point3 px py px)
						)
					)
				)
			)
		)
		printhex j
		
	)
	else (
		print ("No skeleton data found.")
		Print "===================================="
	)
	
	
	
	
	
	
	
	
	
	
	
	
	
	Print ("Last Read @ 0x"+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f
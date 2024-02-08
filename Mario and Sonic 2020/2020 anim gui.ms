--sleepyzay--

global fscale = 50.0
global skelPath = ""
global baseAnimPath = ""
global faceAnimPath = ""
global boneName = #()
global numFramesGlobal = 0
global faceAnim = false

fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
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
fn getChildrenRecursive bone &allChildren = (
	for x=1 to bone.children.count do (
-- 		print bone.children[x].name
		
		append allChildren bone.children[x]
		getChildrenRecursive bone.children[x] allChildren
	)
)
fn loadSkeleton skelPath = (
	gname = skelPath
	g = fopen gname "rb"
	
	print ((getFileNameFile gname) + (getFileNameType  gname)) as string
	
	fseek g 0x48 #seek_set
	parentIDOffset = readlonglong g + 0x40
	boneCount = readlonglong g
	fseek g 0x10 #seek_cur
	boneNameOffset = readlonglong g + 0x40
	fseek g 0x20 #seek_cur
	boneOffset = readlonglong g

	fseek g parentIDOffset #seek_set
	parentID = for x=1 to boneCount collect (readshort g)

	boneName=#()
	fseek g boneNameOffset #seek_set
	for x=1 to boneCount do (
		append boneName (getName g (readlonglong g + 0x40))
		null = readlonglong g
	)
	
-- 	if (skelPresent() == false) do (
-- 		BNArr=#()
-- 		for x=1 to boneCount do (
-- 			float11 = readfloat g; float12 = readfloat g; float13 = readfloat g; float14 = readfloat g
-- 			float21 = readfloat g; float22 = readfloat g; float23 = readfloat g; float24 = readfloat g 
-- 			float31 = readfloat g; float32 = readfloat g; float33 = readfloat g; float34 = readfloat g
-- 			tfm = inverse (quat float21 float22 float23 float24) as matrix3
-- 			tfm.row4 = ([float11,float12,float13]*fscale)
-- 			if (parentID[x] != -1) do (
-- 			tfm *= BNArr[(parentID[x] + 1)].objecttransform	
-- 			)	
-- 			newBone = bonesys.createbone	\
-- 			tfm.row4	\
-- 			(tfm.row4 + 0.01 * (normalize tfm.row1)) \
-- 			(normalize tfm.row3)
-- 			newBone.width  = 0.01
-- 			newBone.height = 0.01
-- 			newBone.transform = tfm
-- 			newBone.setBoneEnable false 0
-- 			newBone.wirecolor = yellow
-- 			newbone.showlinks = true
-- 			newBone.pos.controller      = TCB_position ()
-- 			newBone.rotation.controller = TCB_rotation ()
-- 			newBone.name = boneName[x]
-- 			if (parentID[x] != -1) then(
-- 				newBone.parent = BNArr[(parentID[x] + 1)]
-- 			)
-- 			
-- 			append BNArr newBone
-- 		)
-- 		for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
-- 		for b in BNArr do b.setskinpose()
-- 	)

	fclose g
)
fn loadAnimation animPath = (
	fname = animPath
	f = fopen fname "rb"
	
	fseek f 0x58 #seek_set
	ukw = readfloat f	--frameRate?
	numFrames = readlong f	--frameCount?
	tableCount = readlonglong f	--boneCount?
	tableOffset = readlonglong f + 0x40
	
	if faceAnim == false do numFramesGlobal = numFrames
	
	headBones=#()
	headBone = $Head
	getChildrenRecursive headBone headBones

	fseek f tableOffset #seek_set
	for x=1 to tableCount do (	--boneCount
		posArr=#()
		rotArr=#()
		sclArr=#()
		
		--pos--
		posCount = readlonglong f
		posTimeOffset = readlonglong f #unsigned + 0x40
		posOffset = readlonglong f #unsigned  + 0x40
		
		--rot--
		rotCount = readlonglong f
		rotTimeOffset = readlonglong f #unsigned + 0x40
		rotOffset = readlonglong f #unsigned  + 0x40
		
		--scl--
		sclCount = readlonglong f
		sclTimeOffset = readlonglong f #unsigned + 0x40
		sclOffset = readlonglong f #unsigned  + 0x40
		
		backJump = ftell f
		
		fseek f posTimeOffset #seek_set
		posTime = for y=1 to posCount collect (readshort f #unsigned)
		
		fseek f posOffset #seek_set
		for y=1 to posCount do (
			append posArr (point3 (readFloat f) (readFloat f) (readFloat f))
			null = readlong f
		)
		
		fseek f rotTimeOffset #seek_set
		rotTime = for y=1 to rotCount collect (readshort f #unsigned) 
		
		fseek f rotOffset #seek_set
		for y=1 to rotCount do (append rotArr (quat (readFloat f) (readFloat f) (readFloat f) (readFloat f)))
		
		fseek f sclTimeOffset #seek_set
		sclTime = for y=1 to sclCount collect (readshort f #unsigned)
		
		fseek f sclOffset #seek_set
		for y=1 to sclCount do (
			append sclArr (point3 (readFloat f) (readFloat f) (readFloat f))
			null = readlong f
		)
		
		isHeadBone = false
		b = getnodebyname boneName[x]
		if (findItem headBones b) != 0 do isHeadBone = true
		if faceAnim == true and isHeadBone == false do (b = undefined)	--skip non head bones when parsing face animation
		
		with animate on(
			
			if posCount == 1 and posTime[1] == (numFrames - 1) do posTime[1] = 0
			for a=1 to posArr.count do (
				t = posTIme[a]
				p = posArr[a]
				
				if (b!=undefined) then (
					at time t
						b.Controller.Position = p * fscale
				)
			)
 			if sclCount == 1 and sclTime[1] == (numFrames - 1) do sclTime[1] = 0
			for a=1 to sclArr.count do (
				t = sclTIme[a]
				s = sclArr[a]
				
				if (b!=undefined) then (
					at time t
						b.Controller.Scale = s
				)
				
			)
			if rotCount == 1 and rotTime[1] == (numFrames - 1) do rotTime[1] = 0
			for a=1 to rotArr.count do (
				t = rotTime[a]
				q = rotArr[a]
				
				if (b!=undefined) then (
					
					at time t
						b.Controller.Rotation = inverse q
				)
				
			)
		)
		
		fseek f backJump #seek_set
	)

	fclose f
)

try(destroydialog marioAndSonicAnimImport)catch()
rollout marioAndSonicAnimImport "Mario and Sonic 2020 Animation Importer" width:400 height:94
(
	label lbl1 "Path to Skeleton:" pos:[10,10] width:90 height:15
	label lbl2 "Path to Base Animation:" pos:[10,30] width:120 height:15
	label lbl3 "Path to Face Animation:" pos:[10,50] width:120 height:15
	edittext edt1 "" pos:[130,10] width:190 height:15
	edittext edt2 "" pos:[130,30] width:190 height:15
	edittext edt3 "" pos:[130,50] width:190 height:15
	button getSkelPath 		"..." pos:[330,10] width:25 height:15 enabled:true
	button getAnimPath1	"..." pos:[330,30] width:25 height:15 enabled:true
	button getAnimPath2 	"..." pos:[330,50] width:25 height:15 enabled:true
	button clearSkelPath "Clear" pos:[360,10] width:35 height:15
	button clearAnimPath1 "Clear" pos:[360,30] width:35 height:15
	button clearAnimPath2 "Clear" pos:[360,50] width:35 height:15
	button loadAnim "Load Animation" pos:[105,70] width:190 height:15
	
	on getSkelPath pressed do (
		skelPath = getOpenFileName caption:"skeleton" types:" (*.)|*.pxd" historyCategory:""
		if skelPath != undefined do edt1.text = (getFileNameFile skelPath)
	)
	on getAnimPath1 pressed do (
		baseAnimPath = getOpenFileName caption:"animation" types:" (*.)|*.pxd" historyCategory:""
		if baseAnimPath != undefined do edt2.text = (getFileNameFile baseAnimPath)
	)
	on getAnimPath2 pressed do (
		faceAnimPath = getOpenFileName caption:"animation" types:" (*.)|*.pxd" historyCategory:""
		if faceAnimPath != undefined do edt3.text = (getFileNameFile faceAnimPath)
	)
	on clearSkelPath pressed do (
		edt1.text = ""
	)
	on clearAnimPath1 pressed do (
		edt2.text = ""
	)
	on clearAnimPath2 pressed do (
		edt3.text = ""
	)
	on loadAnim pressed do (
		sliderTime = 0
		framerate = 60
		numFramesGlobal = 0
		for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
		deleteKeys objects #allKeys
		stopanimation()
		
		if edt1.text.count != 0 do (
			loadSkeleton(skelPath)
		)
		if edt2.text.count != 0 do (
-- 			if edt1.text.count == 0 do throw "No Skeleton Loaded!"
			loadAnimation(baseAnimPath) 
		)
		if edt3.text.count != 0 do (
			faceAnim = true
			loadAnimation(faceAnimPath)
			faceAnim = false
		)
		
		animationRange = interval 0 numFramesGlobal
-- 		if edt2.text.count == 0 and edt3.text.count == 0 do throw "No Animation Loaded!"
	)
	
)

clearlistener()
createDialog marioAndSonicAnimImport

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
fn assumeskinpose = (
	stopAnimation()
	allBones = for o in geometry where classOf o == boneGeometry collect o
	for a in allBones do (
		a.assumeskinpose()
	)
)

struct animInfo (
	boneID,
	posTime,
	posArr,
	sclTime,
	sclArr,
	rotTime,
	rotArr,
	ukw
)

struct allAnimInfo (
	frames=#(),
	numFrames=#()
)

try(destroydialog unnamedRollout)catch()
rollout unnamedRollout "King of Fighters" width:300 height:400
(
	button importAnim "Import" pos:[10,10] width:280 height:25 enabled:true
	listbox AnimList "Animation List" pos:[10,40] width:280 height:15
	button loadTrack "Load Track" pos:[10,285] width:280 height:25
	
-- 	checkbox playAnim "Play animation" pos:[10,320] width:120 height:20 checked:false
-- 	checkbox loopAnim "Loop animation" pos:[10,340] width:120 height:20 checked:true
	checkbox applyRoot "Apply root motion" pos:[10,370] width:120 height:20 checked:true
	button skinPos "Assume Skin Position" pos:[150,320] width:140 height:64
	on importAnim pressed do(
			fname = GetOpenFileName caption:"King of Fighters XIV Animation" types:" (*.otra)|*.otra" historyCategory:""
			If (fname!=undefined) and ((DoesFileExist fname)==true) then (
				f = fopen fname "rb"   --open file in read only format
				FileExtension = getFileNameType  fname
				FileName = getFileNameFile fname
				clearlistener()
				global fscale=10
				Print "===================================="
				print (FileName + FileExtension) as string
				Print "===================================="
				
				global allAnimations = allAnimInfo()
				
				magic = readfixedstring f 3
				fseek f 0x03 #seek_cur
				animCount = readlong f
				boneCount = readlong f
				
				global boneName=#()
				boneName = for x=1 to boneCount collect (ReadFixedString f (readlong f))
				
				animNameArr=#()
				for x=1 to animCount do (
					numFrames = readlong f
					boneCount = readlong f
					cmnFlag = readlong f
					animName = ReadFixedString f (readlong f)
					ukw2 = readlong f	--always 1
					
					append animNameArr animName
					
					for y=1 to boneCount do (
						boneID = readlong f #unsigned + 1
						
						posTime=#()
						posArr=#()
						posCount = readlong f
						for z=1 to posCount do (
							posTime[z] = readlong f #unsigned
							posArr[z] = (point3 (readfloat f) (readfloat f) (readfloat f))
						)
						
						sclTime=#()
						sclArr=#()
						sclCount = readlong f
						for z=1 to sclCount do (
							sclTime[z] = readlong f #unsigned
							sclArr[z] = (point3 (readfloat f) (readfloat f) (readfloat f))	
						)
						
						rotTime=#()
						rotArr=#()
						rotCount = readlong f
						for z=1 to rotCount do (
							rotTime[z] = readlong f #unsigned
							rotArr[z] = (quat (readfloat f) (readfloat f) (readfloat f) (readfloat f))
						)
						ukw = readlong f
						
						anim = (animInfo	\ 
							boneID: boneID \
							posTime:  posTime \
							posArr:  posArr \
							sclTime:  sclTime \
							sclArr: sclArr \
							rotTime: rotTime \
							rotArr: rotArr \
							ukw: ukw
						)
						
						if allAnimations.frames[x] == undefined do allAnimations.frames[x] = #()
						append allAnimations.frames[x] anim
					)
					
					allAnimations.numFrames[x] = numFrames
				)
				
				animList.items = animNameArr
				
				Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
				fclose f
				gc()
			)
	)
	on loadTrack pressed do(
			anim = allAnimations.frames[animList.selection]
			numFrames = allAnimations.numFrames[animList.selection]
			
			sliderTime = 0
			framerate = 60
			animationRange = interval 0 numFrames
			deleteKeys objects #allKeys
			
-- 			if loopAnim.checked == true then timeConfiguration.playbackLoop = true
-- 			else timeConfiguration.playbackLoop = false
			
			for x=1 to anim.count do (
				with animate on(
					b = getnodebyname boneName [anim[x].boneId]
					
					for i=1 to anim[x].rotArr.count do (
						r = anim[x].rotArr[i]
						t = anim[x].rotTime[i]
						
						if(b != undefined) then (
							at time t
							b.Controller.Rotation = r
						)
					)
					for i=1 to anim[x].sclArr.count do (
						s = anim[x].sclArr[i]
						t = anim[x].sclTime[i]
						
						if(b != undefined) then (
							at time t
							b.Controller.Scale = s
						)
					)
					for i=1 to anim[x].posArr.count do (
						p = anim[x].posArr[i]
						t = anim[x].posTime[i]
						
						if(b != undefined) then (
							at time t
								b.Controller.Position = (p*fscale)
						)
					)
				)
			)
			stopAnimation()
			gc()
			
	)
	on skinPos pressed do (
		stopanimation()
		sliderTime = 0f
		for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
	)
)

createDialog unnamedRollout
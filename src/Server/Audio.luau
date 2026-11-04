local Config=require(game.ReplicatedStorage.Shared.Config)
local Audio={}
local fallback={doorSlide="rbxasset://sounds/action_get_up.mp3",glassLatch="rbxasset://sounds/electronicpingshort.wav",stamp="rbxasset://sounds/clickfast.wav"}
function Audio.Init()
	local service=game:GetService("SoundService")
	local group=service:FindFirstChild("ProbaWorld")
	if not group then group=Instance.new("SoundGroup");group.Name="ProbaWorld";group.Volume=1;group.Parent=service end
	return group
end
function Audio.Play(part,key)
	if not part or not part.Parent then return end
	local id=Config.Audio[key]or 0
	local sound=Instance.new("Sound");sound.Name="PROBA_"..key
	sound.SoundId=if id>0 then "rbxassetid://"..id else fallback[key]or fallback.stamp
	sound.SoundGroup=Audio.Init();sound.Volume=if key=="glassLatch"then .055 else .14
	sound.PlaybackSpeed=if key=="glassLatch"then 1.7 else .9
	sound.RollOffMinDistance=4;sound.RollOffMaxDistance=32;sound.RollOffMode=Enum.RollOffMode.Inverse
	sound.Parent=part;sound:Play();game:GetService("Debris"):AddItem(sound,2)
end
return Audio

-- Executed against the real server controller with animation/asset substitutes.
local driver=env.require(services.ServerScriptService.AvatarAnimations)
expect(driver.AssetId("rbxassetid://12345")==12345 and driver.AssetId(0/0)==nil,"Only valid numeric Roblox animation IDs are accepted")
local rig=node("Model","NativeFriend",ws);local root=node("Part","HumanoidRootPart",rig);rig.PrimaryPart=root
root.AssemblyLinearVelocity=Vector.new()
local humanoid=node("Humanoid","Humanoid",rig);humanoid.RigType=enum.HumanoidRigType.R15;humanoid.HipHeight=2;humanoid.Running=signal()
local animator=node("Animator","Animator",humanoid)
local lengths={[110100]=0,[111]=2,[120100]=3,[130100]=1.8}
local loaded={}
animator.LoadAnimation=function(_,animation)
	local asset=driver.AssetId(animation.AnimationId)
	local track={Length=lengths[asset]or 2.4,IsPlaying=false,TimePosition=0,asset=asset}
	function track:Play()self.IsPlaying=true end
	function track:Stop()self.IsPlaying=false end
	function track:AdjustSpeed(speed)self.speed=speed end
	loaded[asset]=track;return track
end
local destroyed=false;local inserted=false
services.AssetService.LoadAssetAsync=function(_,asset)
	expect(asset==110100,"The bundle resolver must request the friend's configured walk asset")
	local container=node("Model","AnimationAsset")
	local scriptNode=node("Script","UntrustedScript",container)
	local walk=node("Folder","walk",container);local animation=node("Animation","WalkAnimation",walk);animation.AnimationId="rbxassetid://111"
	function container:Destroy()destroyed=true;inserted=self.Parent~=nil;methods.Destroy(self)end
	return container
end
local native=driver.Attach(rig,{WalkAnimation=110100,IdleAnimation=120100,RunAnimation=130100},{})
native:Update(0)
expect(rig:GetAttribute("ProbaPlayingClip")==120100,"Idle uses the friend's own animation")
native:Update(8)
expect(rig:GetAttribute("ProbaNativeActive")==true,"A loaded standard fallback prevents a frozen rig while a bundle reference is unresolved")
native:Repair("walk");native:Update(8)
expect(rig:GetAttribute("ProbaPlayingClip")==111 and rig:GetAttribute("ProbaAnimationStatus")=="avatar / walk","A catalog animation container must resolve to its actual equipped clip")
expect(destroyed and not inserted,"Animation assets are read while unparented and never execute downloaded scripts")
expect(loaded[111].speed>0 and loaded[111].IsPlaying,"The walk track must actually play and adapt to movement speed")
native:Update(20)
expect(rig:GetAttribute("ProbaPlayingClip")==130100,"Running uses the friend's run animation, independently of walking")
for _,candidate in ipairs(native.sets.walk)do candidate.track.Length=0 end
native:Update(8)
expect(rig:GetAttribute("ProbaNativeActive")==false,"A zero-length or inaccessible track must release the joints to the procedural fallback")
local model=node("Model","ConfiguredRig")
local animate=node("LocalScript","Animate",model);local walk=node("Folder","walk",animate)
local animation=node("Animation","WalkAnim",walk);animation.AnimationId="rbxassetid://456"
expect(driver.Capture(model).walk[1]==456,"Engine-created Animate references must be harvested before stripping NPC scripts")
native:Destroy();expect(driver.controllers[rig]==nil,"Destroying a visitor must disconnect and remove its animation controller")
print("PASS native avatar animation controller")

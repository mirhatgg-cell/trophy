-- Execute both real Artwork backends and capability/partial-failure cleanup.
local Art=env.require(clientScripts.Artwork)
local data={width=2,height=1,pixels="test-base64",fallbackWidth=2,fallbackHeight=1,
	strips={{0,0,{4278190335,65408}}}}
for _,key in ipairs({"test_native","test_budget","test_write"})do artValues[key]=data;node("StringValue",key,artFolder).Value=key end
services.EncodingService=node("EncodingService","EncodingService",gameMock)
local pixels=buffer.create(8);buffer.writeu32(pixels,0,4278190335);buffer.writeu32(pixels,4,2147548928)
services.EncodingService.Base64Decode=function(_,b)expect(buffer.tostring(b)=="test-base64","Decode the actual embedded payload");return b end
services.EncodingService.DecompressBuffer=function(_,_,algorithm)expect(algorithm==enum.CompressionAlgorithm.Zstd,"Use the embedded compression format");return pixels end
local originalCreate=services.AssetService.CreateEditableImage
local calls,writes,destroyed=0,0,0
services.AssetService.CreateEditableImage=function(_,options)
	calls+=1;expect(options.Size.X==2 and options.Size.Y==1,"Allocate only the artwork's exact dimensions")
	local image=node("EditableImage","EditableImage")
	image.WritePixelsBuffer=function(_,offset,size,content)
		writes+=1;expect(offset.X==0 and offset.Y==0 and size.X==2 and buffer.len(content)==8,"Upload exactly one complete static RGBA buffer")
	end
	image.Destroy=function()destroyed+=1 end
	return image
end
env.Content={fromObject=function(image)return{image=image}end}
local parent=node("Frame","ArtworkTest",localPlayer.PlayerGui)
local one=Art.Draw(parent,"test_native",60,30);local two=Art.Draw(parent,"test_native",120,60)
expect(one:GetAttribute("ArtworkBackend")=="EditableImage"and two:GetAttribute("ArtworkBackend")=="EditableImage","Native drawings must bind the created editable image")
expect(calls==1 and writes==1,"Multiple cards must reuse one uploaded static image")
services.AssetService.CreateEditableImage=function()calls+=1;return nil end
local fallback=Art.Draw(parent,"test_budget",60,30);Art.Draw(parent,"test_budget",120,60)
expect(fallback:GetAttribute("ArtworkBackend")=="GuiPainting"and calls==2,"Unavailable editable memory must fall back once, without retrying per card")
local strip=fallback:FindFirstChild("BrushStrip",true);local grad=strip:FindFirstChildOfClass("UIGradient")
expect(grad.Color[1][1][2].R==1 and grad.Color[1][1][2].G==0,"Fallback must retain the source pixel colors")
expect(math.abs(grad.Transparency[1][2][2]-(1-128/255))<.0001,"Fallback must retain independent source alpha")
services.AssetService.CreateEditableImage=function()
	local image=node("EditableImage","FailedWrite")
	image.WritePixelsBuffer=function()error("Simulated upload failure")end
	image.Destroy=function()destroyed+=1 end
	return image
end
local failed=Art.Draw(parent,"test_write",60,30)
expect(failed:GetAttribute("ArtworkBackend")=="GuiPainting"and destroyed==1,"A partial image failure must release its memory and still show the painting")
services.AssetService.CreateEditableImage=originalCreate;services.EncodingService=nil;env.Content=nil
local partial=node("StringValue","test_chunks",artFolder);partial.Value="test_"
expect(Art.Draw(parent,"test_chunks",60,30)==nil,"Incomplete replicated data must wait for a later refresh")
node("StringValue","Chunk03",partial).Value="ve";node("StringValue","Chunk02",partial).Value="nati"
local completed=Art.Draw(parent,"test_chunks",60,30)
expect(completed and completed:GetAttribute("ArtworkBackend")=="GuiPainting","Late chunks must be sorted and retried, rather than cached as a permanent failure")
expect(Art.Draw(parent,"test_late",60,30)==nil,"Missing initial replication must be harmless")
node("StringValue","test_late",artFolder).Value="test_native"
expect(Art.Draw(parent,"test_late",60,30)~=nil,"An initially missing source must become available when replicated")
parent:Destroy()
print("PASS original artwork: native cache, RGBA/alpha, allocation fallback, cleanup and partial replication")

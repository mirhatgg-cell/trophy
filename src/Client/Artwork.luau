-- Original illustrated textures embedded in the place, never unowned asset IDs.
-- One static EditableImage per artwork; capability/memory failures use the same
-- painting as bounded GUI gradient strips. Both backends animate as a whole.
local Rep=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Art={}
local entries={}
local function create(class,props,parent)
	local n=Instance.new(class);for k,v in pairs(props)do n[k]=v end;n.Parent=parent;return n
end
local function entry(key)
	if entries[key]~=nil then return entries[key]or nil end
	local folder=Rep:FindFirstChild("IdentityArt")
	local source=folder and folder:FindFirstChild(key)
	if not source then return nil end
	local chunks={source.Value};local children=source:GetChildren()
	table.sort(children,function(a,b)return a.Name<b.Name end)
	for _,chunk in ipairs(children)do
		if chunk:IsA("StringValue")and chunk.Name:match("^Chunk%d+$")then table.insert(chunks,chunk.Value)end
	end
	local ok,data=pcall(function()return Http:JSONDecode(table.concat(chunks))end)
	-- Initial replication can deliver chunks separately; let the next UI refresh
	-- retry incomplete data instead of permanently caching a missing painting.
	if not ok or type(data)~="table"then return nil end
	local e={data=data};entries[key]=e
	-- Never retry failed allocation for every card or every rendered frame.
	local image
	local made=pcall(function()
		local encoding=game:GetService("EncodingService")
		local compressed=encoding:Base64Decode(buffer.fromstring(data.pixels))
		local pixels=encoding:DecompressBuffer(compressed,Enum.CompressionAlgorithm.Zstd)
		assert(buffer.len(pixels)==data.width*data.height*4,"Invalid embedded artwork")
		image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(data.width,data.height)})
		assert(image,"EditableImage budget exhausted")
		image:WritePixelsBuffer(Vector2.new(0,0),Vector2.new(data.width,data.height),pixels)
		e.content=Content.fromObject(image)
	end)
	if made then e.image=image elseif image then image:Destroy()end
	return e
end
local function template(e)
	if e.template then return e.template end
	local data=e.data
	local root=create("Frame",{Name="PaintedFallback",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
	for _,strip in ipairs(data.strips)do
		local colors,alpha={},{}
		for i,packed in ipairs(strip[3])do
			local r=math.floor(packed/16777216)%256;local g=math.floor(packed/65536)%256
			local b=math.floor(packed/256)%256;local a=packed%256
			local at=(i-1)/(#strip[3]-1)
			table.insert(colors,ColorSequenceKeypoint.new(at,Color3.fromRGB(r,g,b)))
			table.insert(alpha,NumberSequenceKeypoint.new(at,1-a/255))
		end
		local p=create("Frame",{Name="BrushStrip",BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),
			Position=UDim2.fromScale(strip[1]/data.fallbackWidth,strip[2]/data.fallbackHeight),
			-- Slight overlap avoids subpixel cracks between independently rasterized
			-- GUI rows. Later rows cover the seam in a stable top-to-bottom order.
			Size=UDim2.new(#strip[3]/data.fallbackWidth,.3,1/data.fallbackHeight,.6)},root)
		create("UIGradient",{Color=ColorSequence.new(colors),Transparency=NumberSequence.new(alpha),Rotation=0},p)
	end
	e.template=root;return root
end
function Art.Draw(parent,key,w,h)
	local e=entry(key)
	if not e then return nil end
	local root=create("CanvasGroup",{Name="PaintedArtwork",BackgroundTransparency=1,Size=UDim2.fromOffset(w,h),ClipsDescendants=false},parent)
	root:SetAttribute("ArtworkKey",key)
	local native=false
	if e.content then
		local label
		native=pcall(function()
			label=create("ImageLabel",{Name="Illustration",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
				ScaleType=Enum.ScaleType.Stretch,ImageContent=e.content},root)
		end)
		if not native and label then label:Destroy()end
	end
	if native then root:SetAttribute("ArtworkBackend","EditableImage")
	else root:SetAttribute("ArtworkBackend","GuiPainting");template(e):Clone().Parent=root end
	return root
end
return Art

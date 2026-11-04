local Visits=require("../src/Shared/Visits")
local Stories=require("../src/Shared/Stories")
local count=0
local function expect(v,why)count+=1;assert(v,why)end
local random={seed=12345}
function random:NextInteger(a,b)self.seed=(self.seed*48271)%2147483647;return a+self.seed%(b-a+1)end
local pages={number=1,IsFinished=false}
function pages:GetCurrentPage()
	local out={};for i=(self.number-1)*20+1,self.number*20 do table.insert(out,{Id=i,DisplayName="Friend"..i})end;return out
end
function pages:AdvanceToNextPageAsync()self.number+=1;self.IsFinished=self.number==5 end
local friends=Visits.ReadPages(pages,function()return true end)
expect(#friends==100 and friends[100].id==100,"Pagination must include all one hundred friends, not just twelve or one page")
local state,history={},{}
for cycle=1,10 do
	local seen={}
	for _=1,100 do
		local friend=Visits.Next(state,friends,random)
		expect(friend~=nil and not seen[friend.id],"A full cycle must visit each friend exactly once")
		for i=math.max(1,#history-2),#history do expect(history[i]~=friend.id,"The last three visitors must not repeat even across a cycle boundary")end
		seen[friend.id]=true;table.insert(history,friend.id)
	end
end
local small={{id=1,name="A"},{id=2,name="B"}}
expect(Visits.Next({},small,random,{[1]=true,[2]=true})==nil,"Active visitors must not be duplicated to fill the queue")
local single=Visits.Next({},{{id=10,name="Only"}},random)
expect(single.id==10,"A player with one friend must remain playable")
local d={name="Амфора"};local distinct={}
for i=1,100 do local item={seed=i,condition=.7};local story=Stories.Build(d,item);expect(story==Stories.Build(d,item),"A story must stay stable during the same case");distinct[story]=true end
local total=0;for _ in pairs(distinct)do total+=1 end
expect(total>30,"Different instances must have varied first-person stories")
print("PASS visits/stories:",count,"assertions")

local Tutorial=require("../src/Shared/Tutorial")
local p={tutorial={flags={},skipped=false}}
assert(Tutorial.State(p).event=="specialty")
Tutorial.Mark(p,"seated");assert(Tutorial.State(p).event=="specialty")
Tutorial.Mark(p,"specialty");assert(Tutorial.State(p).event=="loupe")
for _,step in ipairs(Tutorial.Steps)do Tutorial.Mark(p,step.event)end
assert(Tutorial.State(p).done)
p.tutorial={flags={},skipped=true};assert(Tutorial.State(p).done)
p.tutorial={flags={},skipped=false};assert(not Tutorial.State(p).done)
print("PASS guided tutorial: 6 assertions")

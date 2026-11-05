local Layout={}
function Layout.Compute(w,h)
	local mobile=w<700
	local caseWidth=math.min(296,w-28)
	local caseHeight=math.min(410,math.floor(h*(if mobile then .44 else .64)))
	return {width=w,height=h,mobile=mobile,
		wallet={x=w-190,y=12,w=178,h=42},brand={x=14,y=14,w=108,h=24},
		dock={x=math.floor((w-318)/2),y=h-50,w=318,h=40},
		case={x=14,y=h-64-caseHeight,w=caseWidth,h=caseHeight},
		manager={x=math.floor((w-math.min(760,w-28))/2),y=math.floor((h-math.min(530,h-90))/2),w=math.min(760,w-28),h=math.min(530,h-90)},
		roster={x=w-math.min(270,w-28)-12,y=62,w=math.min(270,w-28)},
		tutorial={x=14,y=h-88,w=math.min(270,w-28),h=28}}
end
return Layout

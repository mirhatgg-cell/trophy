local Tutorial={}
Tutorial.Steps={
	{event="specialty",title="Выбери специальность",detail="Открой «Профессия». Переключение бесплатно, опыт сохраняется."},
	{event="seated",title="Займи рабочее кресло",detail="Сядь за собственной стойкой. Клиент подойдёт и расскажет о вещи."},
	{event="loupe",title="Найди метки лупой",detail="Выбери лупу, проведи ею по предмету и отметь три находки."},
	{event="scale",title="Проверь массу",detail="Обнули весы и уравновесь стрелку противовесами."},
	{event="verdict",title="Выдай первое заключение",detail="Назови цену и подлинность. Честное «неясно» допустимо."},
	{event="bought",title="Обсуди выкуп",detail="Введи предложение. Клиент ответит в облачке над головой."},
	{event="carried",title="Возьми вещь с полки",detail="Купленная вещь выставлена в шкафу. Подойди и нажми F."},
	{event="peer",title="Получи мнение коллеги",detail="Принеси вещь к чужой стойке. Комиссия — 40 монет. Этот шаг можно оставить на потом."},
}
function Tutorial.Mark(profile,event)
	profile.tutorial=profile.tutorial or {flags={},skipped=false}
	for _,step in ipairs(Tutorial.Steps)do if step.event==event then profile.tutorial.flags[event]=true;return end end
end
function Tutorial.State(profile)
	local t=profile.tutorial or {flags={}}
	if not t.skipped then
		for i,step in ipairs(Tutorial.Steps)do if not t.flags[step.event]then return {step=i,total=#Tutorial.Steps,title=step.title,detail=step.detail,event=step.event,done=false}end end
	end
	return {step=#Tutorial.Steps+1,total=#Tutorial.Steps,done=true}
end
return Tutorial

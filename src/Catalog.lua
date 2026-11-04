-- Shared, asset-free prototype configuration.
local C = {}
C.RoundSeconds = 38
C.RoundsPerRun = 5
C.MutationChance = 0.001 -- 0.1% per victory; never sold for Robux.
C.AdminUserIds = {} -- Add trusted Roblox UserIds before publishing a group-owned place.
C.PublicTestAdmin = false -- Keep false in published games. Studio grants test admin automatically.
C.LevelWins = {1,3,5,8,12,17,23,30,39,50,64,81,102,128,160,198,244,299,365,450}
C.Tiers = {'Грязь','Глина','Камень','Медь','Бронза','Серебро','Золото','Рубин','Изумруд','Сапфир','Аметист','Обсидиан','Лёд','Плазма','Звёзды','Комета','Космос','Разлом','Вечность','Легенда'}
C.Palette = {
 Color3.fromRGB(88,60,40),Color3.fromRGB(156,94,63),Color3.fromRGB(114,126,135),Color3.fromRGB(186,101,63),
 Color3.fromRGB(177,130,62),Color3.fromRGB(192,209,220),Color3.fromRGB(255,205,65),Color3.fromRGB(239,62,92),
 Color3.fromRGB(49,220,144),Color3.fromRGB(54,128,255),Color3.fromRGB(177,91,255),Color3.fromRGB(52,40,75),
 Color3.fromRGB(154,239,255),Color3.fromRGB(255,75,216),Color3.fromRGB(255,240,179),Color3.fromRGB(255,143,61),
 Color3.fromRGB(108,82,255),Color3.fromRGB(255,49,115),Color3.fromRGB(217,255,245),Color3.fromRGB(255,255,255)
}
local families = {
 {'tetris', {'Тетрис на смерть','Кирпичный дождь','Шахта фигур','Тетрис: двойной удар','Неоновый укладчик'}, 'Уклоняйся от фигур. Архитектор сверху выбирает столбец и сбрасывает их; заполненный ряд даёт ему очки.'},
 {'tiles', {'Хрупкое печенье','Исчезающий пол','Острова пепла','Стеклянный маршрут','Последняя плитка'}, 'Плитки мигают и исчезают. Перебегай на устойчивые участки.'},
 {'laser', {'Лазерная скакалка','Перекрёстный луч','Красный сканер','Ритм реактора','Танец фотонов'}, 'Перепрыгивай лучи и ищи просветы. Контакт причиняет урон.'},
 {'meteor', {'Метеоритный чай','Падающие луны','Град кубов','Орбитальная доставка','Небо сломалось'}, 'Красные круги предупреждают об ударе с неба. Уходи из зоны.'},
 {'color', {'Цветовой приговор','Палитра паники','Светофор без правил','Чернила судьбы','Радужный остров'}, 'Запоминай названный цвет и вставай на него до исчезновения остальных.'},
 {'flood', {'Суп поднимается','Прилив лимонада','Лестница облаков','Кипящая башня','Последний сухой носок'}, 'Поднимайся по ступеням: опасная жидкость непрерывно растёт.'},
 {'collect', {'Кража звёзд','Сборщики искр','Золотая лихорадка','Нестабильные батарейки','Пылесос вселенной'}, 'Собирай светящиеся сферы и уклоняйся от ударов. Побеждает лучший сборщик.'},
 {'wind', {'Вентилятор судьбы','Косой ураган','Невесомый понедельник','Дыхание великана','Центрифуга носков'}, 'Сохраняй равновесие на платформе: ветер меняет направление. Собирай искры.'},
 {'memory', {'Память пола','Эхо шагов','Архив безопасных мест','Сон архитектора','Забытый квадрат'}, 'Запомни светящиеся плитки: только они останутся безопасными после сигнала.'},
 {'drones', {'Злые пылесосы','Охота будильников','Почтальоны хаоса','Рой потерянных идей','Убеги от своего эха'}, 'Убегай от охотников. Они выбирают ближайшего игрока, а искры дают очки.'},
}
C.Games = {}
for _,family in ipairs(families) do
 for variant,name in ipairs(family[2]) do
  local id = #C.Games+1
  C.Games[id] = {id=id,name=name,kind=family[1],variant=variant,rules=family[3]}
 end
end
C.Shop = {
 {id='trail_mint',name='Мятный след',price=90,kind='trail',color=Color3.fromRGB(80,255,196)},
 {id='trail_sunset',name='Закатный след',price=180,kind='trail',color=Color3.fromRGB(255,112,102)},
 {id='trail_cosmic',name='Космический след',price=350,kind='trail',color=Color3.fromRGB(167,105,255)},
 {id='hat_crown',name='Корона коллекционера',price=250,kind='hat',color=Color3.fromRGB(255,211,85)},
 {id='hat_orbit',name='Орбитальный спутник',price=420,kind='hat',color=Color3.fromRGB(103,224,255)},
 {id='aura',name='Аура искр',price=600,kind='aura',color=Color3.fromRGB(255,223,127)},
 {id='title_lucky',name='Титул «Везунчик»',price=120,kind='title',text='Везунчик'},
 {id='title_curator',name='Титул «Куратор хаоса»',price=500,kind='title',text='Куратор хаоса'},
}
C.Achievements = {
 {id='first',name='Первый экспонат',field='wins',goal=1,reward=40,title='Новичок музея'},
 {id='ten',name='Десять побед',field='wins',goal=10,reward=100,title='Выживший'},
 {id='hundred',name='Сто побед',field='wins',goal=100,reward=500,title='Легенда арены'},
 {id='run',name='Полный заход',field='runs',goal=1,reward=80,title='Путешественник'},
 {id='marathon',name='Десять заходов',field='runs',goal=10,reward=250,title='Неутомимый'},
 {id='variety',name='Пять разных фигурок',field='unique',goal=5,reward=150,title='Коллекционер'},
 {id='museum',name='Полный музей',field='unique',goal=50,reward=1500,title='Хранитель 50 миров'},
 {id='mutation',name='Сбой реальности',field='mutations',goal=1,reward=300,title='Аномалия'},
}
function C.Level(wins)
 local level=0
 for i,needed in ipairs(C.LevelWins) do if wins>=needed then level=i end end
 return level
end
return C

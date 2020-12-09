-- Автор: qwertyMAN
-- Версия: 0.1 бета

local term				= require("term")
local event				= require("event")
local component			= require("component")
local gpu				= component.gpu
local display			= {gpu.getResolution()}
local players			= {}		-- свойства игроков
local players_vector	= {}		-- направления игроков
local area				= {}		-- игровое поле
local turn				= {}		-- таблица поворота
local target			= {}		-- координаты цели
local border			= {0,0}		-- неиспользуемый отступ от края экрана
local t					= 1/8		-- скорость игры
local exit_game			= false		-- для выхода из игры
local size				= {math.modf((display[1]-border[1])/2), math.modf(display[2]-border[2])} -- размер игрового поля
math.randomseed(os.time())

turn[1]={0,-1}
turn[2]={0,1}
turn[3]={-1,0}
turn[4]={1,0}

local command={}					-- управление:
command[200]=function(nick)			-- вверх
	if players_vector[nick] ~= 2 then
		players_vector[nick] = 1
	end
end 
command[208]=function(nick)			-- вниз
	if players_vector[nick] ~= 1 then
		players_vector[nick] = 2
	end
end
command[203]=function(nick)			-- влево
	if players_vector[nick] ~= 4 then
		players_vector[nick] = 3
	end
end
command[205]=function(nick)			-- вправо
	if players_vector[nick] ~= 3 then
		players_vector[nick] = 4
	end
end

-- генерация поля
for i=1, size[1] do
	area[i]={}
	for j=1, size[2] do
		area[i][j]=false
	end
end

local function conv_cord(sx,sy)
	return sx*2-1+border[1], sy+border[2]
end

local function gen_target()
	while true do
		local x,y = math.random(1,size[1]), math.random(1,size[2])
		if not area[x][y] then
			target = {x,y}
			gpu.setBackground(0x0000ff)
			local rezerv = {conv_cord(x,y)}
			gpu.set(rezerv[1], rezerv[2], "  ")
			gpu.setBackground(0x000000)
			break
		end
	end
end

local function keyboard(_,_,_,key,nick)
	local swich = true
	for i=1, #players do
		if nick==players[i].name then
			swich = false
		end
	end
	if swich and (key==200 or key == 203 or key == 205 or key == 208) then
		-- если игрока нет в списке
		players[#players+1]={name=nick,number=5,cord={5,5}}
		area[players[#players].cord[1]][players[#players].cord[2]]=players[#players].number
	end
	if key == 16 then -- выход
		exit_game = true
	elseif command[key] then
		command[key](nick)
	end
end

local function update()
	-- проверка есть ли препятствие
	for i=#players, 1, -1  do
		local cord = turn[players_vector[players[i].name]]
		local cord_2 = {players[i].cord[1]+cord[1],players[i].cord[2]+cord[2]}
		gpu.setBackground(0xffffff)
		local rezerv = {conv_cord(players[i].cord[1], players[i].cord[2])}
		gpu.set(rezerv[1], rezerv[2], "  ")
		gpu.setBackground(0x000000)
		if cord_2[1]>size[1] then
			cord_2[1] = 1
		elseif cord_2[1] < 1 then
			cord_2[1] = size[1]
		elseif cord_2[2]>size[2] then
			cord_2[2] = 1
		elseif cord_2[2] < 1 then
			cord_2[2] = size[2]
		end
		if not area[cord_2[1]][cord_2[2]] then
			players[i].cord[1]=cord_2[1]
			players[i].cord[2]=cord_2[2]
			area[players[i].cord[1]][players[i].cord[2]]=players[i].number
			gpu.setBackground(0x00ff00)
			gpu.setForeground(0x000000)
			local rezerv = {conv_cord(players[i].cord[1], players[i].cord[2])}
			gpu.set(rezerv[1], rezerv[2], string.sub(players[i].name,1,2))
			if target[1]==players[i].cord[1] and target[2]==players[i].cord[2] then
				players[i].number = players[i].number+1
				gen_target()
			end
		else
			table.remove(players,i)
		end
		gpu.setBackground(0x000000)
		gpu.setForeground(0xffffff)
	end
	
	-- обновление и добавление ячеек
	for i=1, size[1] do
		for j=1, size[2] do
			if area[i][j] then
				if area[i][j]>0 then
					area[i][j]=area[i][j]-1
				else
					area[i][j]=false
					gpu.setBackground(0x000000)
					local rezerv = {conv_cord(i,j)}
					gpu.set(rezerv[1], rezerv[2], "  ")
				end
			end
			
		end
	end
end

-- очищаем экран
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
term.clear()
event.listen("key_down", keyboard)

gen_target()

-- тело игры
while true do
	os.sleep(t)
	if exit_game then
		term.clear()
		print("Exit game")
		os.sleep(2)
		term.clear()
		return
	end
	update()
end

term.clear()
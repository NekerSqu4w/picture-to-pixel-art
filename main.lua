
------------------ DEFAULT VARIABLE LIB ETC ----------------------------
lw = love.window
lf = love.filesystem
ls = love.sound
la = love.audio
lp = love.physics
lt = love.timer
li = love.image
lg = love.graphics
lm = love.mouse
lma = love.math
lk = love.keyboard
lev = love.event

require("lib/graphics")
require("lib/math")

local colorDiv = 0.1

local usePalet = true
local palet_name = "paletJ.png"

local original = nil
local pixelArt = nil
local palet_color = {}
local currentConvert = {}

function convert(palet_name,file)
	local palet_convert = li.newImageData("color_palets/" .. palet_name)
	local palet_data = li.newImageData(palet_convert:getWidth(),palet_convert:getHeight())
	for x=0, palet_convert:getWidth()-1 do
		r,g,b,a = palet_convert:getPixel(x,0)
		palet_color[#palet_color+1] = {r=r,g=g,b=b,a=a}
	end

	original = lg.newImage(file)

	local toConvert = li.newImageData(file)
	local data = li.newImageData(toConvert:getWidth(),toConvert:getHeight())
	currentConvert.data = data
	currentConvert.toConvert = toConvert
	currentConvert.drawChunk = {x=-1,y=0}
	currentConvert.processProgress = 0
	currentConvert.converting = true
	timerCreate("refreshPreview",0.1,0,function() pixelArt = lg.newImage(currentConvert.data) end)
end

function love.filedropped(f)
	local n = f:getFilename():lower()
	if n:find("%.png$") or n:find("%.jpeg$") or n:find("%.jpg$") then
		convert(palet_name,f)
	end
end

function love.load()
	currentConvert.res_div = 4

	love.window.setTitle("PPA")
	convert(palet_name,'ahah.png')
end

--Find nearest color from palet
local function color_distance(color1, color2)
    return math.sqrt((color1.r - color2.r)^2 + (color1.g - color2.g)^2 + (color1.b - color2.b)^2)
end

function love.update(dt)
	update_timer(dt)

	if currentConvert.converting then
		local SIZE = 64
		currentConvert.drawChunk.x = currentConvert.drawChunk.x + 1
		for chX=0, SIZE do
			for chY=0, SIZE do
				local PIXEL_POS = {}
				PIXEL_POS.x = math.floor(currentConvert.drawChunk.x*SIZE + chX)
				PIXEL_POS.y = math.floor(currentConvert.drawChunk.y*SIZE + chY)
				PIXEL_POS.x = clamp(PIXEL_POS.x,0,currentConvert.toConvert:getWidth()-1)
				PIXEL_POS.y = clamp(PIXEL_POS.y,0,currentConvert.toConvert:getHeight()-1)
				if PIXEL_POS.x >= currentConvert.toConvert:getWidth()-1 then
					currentConvert.drawChunk.x = -1
					currentConvert.drawChunk.y = currentConvert.drawChunk.y + 1
				end
				if PIXEL_POS.x >= currentConvert.toConvert:getWidth()-1 and PIXEL_POS.y >= currentConvert.toConvert:getHeight()-1 then
					pixelArt = lg.newImage(currentConvert.data)
					timerRemove("refreshPreview")
					currentConvert.doSave = true
					currentConvert.converting = false
				end
				currentConvert.processProgress = PIXEL_POS.y

				local r,g,b,a = currentConvert.toConvert:getPixel(math.floor(PIXEL_POS.x / currentConvert.res_div) * currentConvert.res_div,math.floor(PIXEL_POS.y / currentConvert.res_div) * currentConvert.res_div)
				if usePalet then
					local nearest_color = nil
					for i, color in ipairs(palet_color) do
						local distance = color_distance({r=r,g=g,b=b}, color)
						if nearest_color == nil or distance < nearest_color.distance then nearest_color = {color=color, distance=distance} end
					end
					if nearest_color then currentConvert.data:setPixel(PIXEL_POS.x,PIXEL_POS.y,nearest_color.color.r,nearest_color.color.g,nearest_color.color.b,a) end
				else
					currentConvert.data:setPixel(PIXEL_POS.x,PIXEL_POS.y,round(r / colorDiv) * colorDiv,round(g / colorDiv) * colorDiv,round(b / colorDiv) * colorDiv,a)
				end
			end
		end
	end
end

function love.draw()
	SetColor(Color(0.6,0.6,0.6))
	Rect("fill",0,0,ScrW(),ScrH())

	SetColor(Color(0,0,0))
	Rect("fill",0,0,ScrW()/2,ScrW()/2)
	Rect("fill",ScrW()/2,0,ScrW()/2,ScrW()/2)

	SetColor(Color(1,1,1))
	if original then ImageFit(original,0,0,ScrW()/2,ScrW()/2) end
	if pixelArt then ImageFit(pixelArt,ScrW()/2,0,ScrW()/2,ScrW()/2) end

	Text("Original",ScrW()/4,ScrW()/2+5,1,0,"font/Retro Team.otf",25)
	Text("Pixel art version",ScrW()/2 + ScrW()/4,ScrW()/2+5,1,0,"font/Retro Team.otf",25)
	
	if currentConvert.converting and currentConvert.processProgress > 0 then
		Text("Convert status: " .. round((currentConvert.processProgress / (currentConvert.toConvert:getHeight()-1)) * 100,1) .. "%",ScrW()/2 + ScrW()/4,ScrW()/2 - ScrW()/4,1,1,"font/Retro Team.otf",25)
	end

	if currentConvert.doSave then
		local data2 = currentConvert.data:encode("png", os.time() .. ".png")
		lf.write(os.time() .. ".png",data2)
		currentConvert.doSave = false
		--love.system.openURL("file://"..love.filesystem.getSaveDirectory())
	end
end
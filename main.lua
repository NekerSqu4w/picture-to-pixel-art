local ScrX, ScrY = love.graphics.getDimensions()
local res_div = 6

local color_divider = 0.0001
local use_palet = true
local palet_name = "paletJ.png"

local scl_x, scl_y = 0, 0
local pixelArt
local subArt
local r,g,b,a = 0,0,0,1
local toConvert = nil
local original = nil
local rendering = false

local palet_color = {}

function clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

function round(n, deci)
	deci = 10^(deci or 0) 
	return math.floor(n*deci+.5)/deci
end


--Find nearest color from palet
local function color_distance(color1, color2)
    return math.sqrt((color1.r - color2.r)^2 + (color1.g - color2.g)^2 + (color1.b - color2.b)^2)
end

function convert(file)
	toConvert = love.image.newImageData(file)
	original = love.graphics.newImage(file)

	data = love.image.newImageData(toConvert:getWidth(),toConvert:getHeight())
	for x=0, toConvert:getWidth()-1 do
		for y=0, toConvert:getHeight()-1 do
			r,g,b,a = toConvert:getPixel(math.floor(x / res_div) * res_div,math.floor(y / res_div) * res_div)
			local nearest_color = nil
			if use_palet then
				for i, color in ipairs(palet_color) do
					local distance = color_distance({r=r,g=g,b=b}, color)

					if nearest_color == nil or distance < nearest_color.distance then
						nearest_color = {color=color, distance=distance}
					end
				end

				if nearest_color then
					data:setPixel(x,y,nearest_color.color.r,nearest_color.color.g,nearest_color.color.b,a)
				end
			else
				data:setPixel(x,y, round(r/color_divider)*color_divider, round(g/color_divider)*color_divider, round(b/color_divider)*color_divider, a)
			end
		end
	end
	pixelArt = love.graphics.newImage(data)
end

function love.filedropped(f)
	local n = f:getFilename():lower()
	if n:find("%.png$") or n:find("%.jpeg$") or n:find("%.jpg$") then
		convert(f)
		rendering = true
	end
end

function love.load()
	love.window.setTitle("Picture to Pixel art")

	local palet_convert = love.image.newImageData("color_palets/" .. palet_name)
	local palet_data = love.image.newImageData(palet_convert:getWidth(),palet_convert:getHeight())
	for x=0, palet_convert:getWidth()-1 do
		r,g,b,a = palet_convert:getPixel(x,0)
		palet_color[#palet_color+1] = {r=r,g=g,b=b,a=a}
	end

	convert('ahah.png')
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(pixelArt,  0, 0)
	love.graphics.draw(original, 0, 512)

	if rendering then
		data2 = data:encode("png", os.time() .. ".png")
		love.filesystem.write(os.time() .. ".png",data2)

		rendering = false

		--love.system.openURL("file://"..love.filesystem.getSaveDirectory())
	end
end
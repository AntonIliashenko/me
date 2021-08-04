local component = require("component")
local os = require("os")
local event = require("event")
local term = require("term")

local maintable = {}

local function getFluidFromMaintable(tempFluidName)
	if maintable[tempFluidName] == nil then
		maintable[tempFluidName] = {}
		maintable[tempFluidName].name = tempFluidName

		local cur = maintable[tempFluidName]
		
		if(cur.tocraft == nil) then
			cur.tocraft = 0
		end
	
		if(cur.mode == nil) then
			cur.mode = "toDemand"
		end
		
		if(cur.address == nil) then
			cur.address = "DNE"
		end

		if(cur.status == nil) then
			cur.status = false
		end

	end
	return maintable[tempFluidName]

end

local function printLiquids()

	local fluids = component.me_controller.getFluidsInNetwork()

	for label,item in ipairs(fluids) do
		
		local cur = getFluidFromMaintable(item.name)
		cur.amount = item.amount	
	
	end

	for label,item in pairs(maintable) do
		local itemexists = false
		for index,fluid in ipairs(fluids) do
			if(item.name == fluid.name) then itemexists = true end
		end

		if itemexists then
			local tab = ""
			if string.len(item.name) <= 7 then tab = "\t\t" else tab = "\t" end
			
			local tempaddress = string.sub(item.address, 1, 5)
			local temptab = ""
			if(item.mode ~= "toDemand") then temptab = "\t" end
			print(item.name, tab, item.amount, item.tocraft, item.mode, temptab, tempaddress, item.status)
		else
			item.amount = 0
		end
	end
	
end

local function checkForMe_Controller()

	for address, name in component.list() do
		if name == "me_controller" then return true end
	end
	return false
end

local pause = false
local changingTable = false

local function myEventHandler()

	if not changingTable then
		pause = not pause
	
		local pauseString = ""
		if pause then pauseString = "PAUSED" else pauseString = "UNPAUSED" end
		print("YOU ", pauseString, " THE PROGRAM")
	end
end

local toRun = true

local function quitEditor()
	pause = false
	changingTable = false
end

local function myRead()
	local textRead = term.read()
	local len = string.len(textRead)
	textRead = string.sub(textRead, 1, len - 1)
	return textRead 
end


local function keyPressed(name , address, num1, num2, player)
	if not changingTable then
		if num2 == 35 then
			maintable = {}
		elseif num2 == 16 then
			print("Terminating...")
			event.ignore("key_down", keyPressed)
			event.ignore("touch", myEventHandler)
			toRun = false
		elseif num2 == 18 then
			pause = true
			changingTable = true
			print("Type the name of the fluid to edit (may be a new one) or 'q' to quit ")

			local fluidToChange = ""
			local fluidInitialized = false
		
			while changingTable do

				if fluidInitialized then
					print("What do you want to change? 1: AmountToCraft, 2: Address, 3: Crafting Mode")
				end
	
				local textRead = myRead()
					
				if textRead == "q" then
					fluidInitialized = false
					quitEditor()
				end


				if not fluidInitialized then
					fluidInitialized = true
					fluidToChange = textRead
				else
					
					if textRead == "1" then
						print("Enter the new value:")
						local newvalue = tonumber(myRead())

						if newvalue ~= nil and newvalue >= 0 then
							maintable[fluidToChange].tocraft = tonumber(newvalue)
							print("Amount to craft of ", fluidToChange, " has been changed to ", newvalue)
						else
							print("Please provide a non-negative number")
						end
						
					elseif textRead == "2" then
						print("Enter the new value:")
						local newvalue = myRead()

						local tempProxy = component.proxy(newvalue)
						
						if tempProxy ~= nil and tempProxy.type == "redstone" then
							maintable[fluidToChange].address = newvalue
							print("Address of ", fluidToChange, " has been changed to ", newvalue)
						else print("Wrong address!")
						end

				
					elseif textRead == "3" then
						print("Choose one: 1: to demand, 2: on, 3: off")
						local option = myRead()
						if option == "1" then
							maintable[fluidToChange].mode = "toDemand"
							print("Mode of ", fluidToChange, " has been changed to to-Demand")
						elseif option == "2" then
							maintable[fluidToChange].mode = "ON"
							print("Mode of ", fluidToChange, " has been changed to ON")
						elseif option == "3" then
							maintable[fluidToChange].mode = "OFF"
							print("Mode of ", fluidToChange, " has been changed to OFF")
						else
							print("Invalid command")
						end

					else
						print("Invalid command")
					end
				end
			end
		end
	end
end

local function setProxy(proxyAddress, value)

	local tempProxy = component.proxy(proxyAddress)

	if tempProxy ~= nil and tempProxy.type == "redstone" then
		tempProxy.setOutput(0, value)
		tempProxy.setOutput(1, value)
		tempProxy.setOutput(2, value)
		tempProxy.setOutput(3, value)
		tempProxy.setOutput(4, value)
		tempProxy.setOutput(5, value)
		return true
	end
	
	return false
end

local click = event.listen("touch", myEventHandler)

local buttonPress = event.listen("key_down", keyPressed)

local function sendSignals()
	for label,item in pairs(maintable) do
		
		if (item.amount < item.tocraft and item.mode == "toDemand") or item.mode == "ON" then

			if(item.address ~= "DNE") then		
				item.status = setProxy(item.address, 15)
			end
		else
			if(item.address ~= "DNE") then
				setProxy(item.address, 0)
			end
	
			item.status = false
		end

	end
end


local function turnOffAllSignals()
	for label,item in pairs(maintable) do
		if(item.address ~= "DNE") then
			setProxy(item.address, 0)
			item.status = false
		end
	end
end


while toRun do
	
	if not pause then
		if term ~= nil then if term.isAvailable() then term.clear() end end

		print("FLUID STOCK V1.0 BY WUN_TEP")
		print("Press 'q' to quit the program")
		print("Press 'e' to edit the table")
		print("Press 'h' to reset all the values")
		print("Click the mouse to pause the program")

		if checkForMe_Controller() then printLiquids() sendSignals()
		else print("NO ME_CONTROLLER FOUND!")
		end
	end
	os.sleep(3)
end

turnOffAllSignals()
print("Terminated!")

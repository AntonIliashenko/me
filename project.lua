local component = require("component")
local os = require("os")
local event = require("event")
local term = require("term")
local filesystem = require("filesystem")

local maintable = {}
local showEveryFluid = false

local function initializeMaintable()

    local file = io.open("/home/table", "r")

    if file == nil then maintable = {}
    else
        for line in file:lines() do

            local words = {}
            for word in line:gmatch("[^%s]+") do table.insert(words,word) end

            local f = words[1]

            maintable[f] = {}
            maintable[f].name = f
            maintable[f].amount = 0
            maintable[f].tocraft = tonumber(words[2])
            maintable[f].mode = words[3]
            maintable[f].address = words[4]
            maintable[f].status = false
        end
     end


end

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

    print("NAME\t\t\t\tAMOUNT\t\t\tTO CRAFT\t\tMODE\t\t\tADDRESS\t\t\tSTATUS")

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

        if (not itemexists) and (item.tocraft > 0) then
            item.amount = 0
		    itemexists = true
		end

		if itemexists or showEveryFluid then
			local tab = ""
			if string.len(item.name) <= 7 then tab = "\t\t" else tab = "\t" end
			
			local tempaddress = string.sub(item.address, 1, 5)
			local temptab = ""
			if(item.mode ~= "toDemand") then temptab = "\t" end
			print(item.name, tab, item.amount, "\t", item.tocraft, "\t", item.mode, temptab, tempaddress, "\t", item.status)
		else
			item.amount = 0
		end
	end

	print("")
	
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

local function cleanMaintable()
    for label,item in pairs(maintable) do
        setProxy(item.address, 0)
    end
    maintable = {}
end


local function keyPressed(name , address, num1, num2, player)
	if not changingTable then
		if num2 == 35 then
			cleanMaintable()
		elseif num2 == 36 then
            showEveryFluid = not showEveryFluid
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
					print("What do you want to change? 1: ToCraft, 2: Address, 3: Crafting Mode, 4: Delete Entry")
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
							getFluidFromMaintable(fluidToChange).tocraft = tonumber(newvalue)
							print("Amount to craft of", fluidToChange, "has been changed to", newvalue)
						else
							print("Please provide a non-negative number")
						end
						
					elseif textRead == "2" then
						print("Enter the new value or 'r' to reset")
						local newvalue = myRead()

                        if newvalue == "r" then
                             getFluidFromMaintable(fluidToChange).address = "DNE"
                            print("Address of", fluidToChange, "has been reset!")
                        else

						    local tempProxy = component.proxy(newvalue)

						    if tempProxy ~= nil and tempProxy.type == "redstone" then
							    getFluidFromMaintable(fluidToChange).address = newvalue
							    print("Address of", fluidToChange, "has been changed to", newvalue)
						    else print("Wrong address!")
						    end
						 end

				
					elseif textRead == "3" then
						print("Choose one: 1: to demand, 2: on, 3: off")
						local option = myRead()
						if option == "1" then
							getFluidFromMaintable(fluidToChange).mode = "toDemand"
							print("Mode of", fluidToChange, "has been changed to to-Demand")
						elseif option == "2" then
							getFluidFromMaintable(fluidToChange).mode = "ON"
							print("Mode of", fluidToChange, "has been changed to ON")
						elseif option == "3" then
							getFluidFromMaintable(fluidToChange).mode = "OFF"
							print("Mode of", fluidToChange, "has been changed to OFF")
						else
							print("Invalid command")
						end

					elseif textRead == "4" then
					    print("Are you sure? Type Y to confirm")
					    local option = myRead()

					    if option == "Y" then
					           if maintable[fluidToChange] ~= nil then
					                setProxy(maintable[fluidToChange].address, 0)
					                maintable[fluidToChange] = nil
                                end
                            print("Fluid", fluidToChange, "has been deleted")
					    end

					else
						print("Invalid command")
					end
				end
			end
		end
	end
end

local click = event.listen("touch", myEventHandler)

local buttonPress = event.listen("key_down", keyPressed)

local function sendSignals()

    local allowedProxies = {}
    local blockedProxies = {}

	for label,item in pairs(maintable) do

	    item.status = false
		
		if (item.amount < item.tocraft and item.mode == "toDemand") or item.mode == "ON" then

			if(item.address ~= "DNE") then

				if blockedProxies[item.address] == nil then

                    if allowedProxies[item.address] == nil then
                            allowedProxies[item.address] = true
                    end
                    
				end

			end
		elseif item.mode == "OFF" then

		    blockedProxies[item.address] = true
		    allowedProxies[item.address] = nil

		    if(item.address ~= "DNE") then
                setProxy(item.address, 0)
            end
		end

	end

	for label, item in pairs(maintable) do
	    if allowedProxies[item.address] ~= nil then
	        setProxy(item.address, 15)
            item.status = true
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

initializeMaintable()

local function saveMaintableToFile()

    filesystem.remove("/home/table")

    local f = io.open("/home/table","w")
    local firstLine = true

    for label, item in pairs(maintable) do

        local line = item.name ..  " " .. item.tocraft .. " " .. item.mode .. " " .. item.address
        if not firstLine then
            line = "\n" .. line
        end

        f:write(line)

        firstLine = false

    end

    f:close()


end

while toRun do
	
	if not pause then
		if term ~= nil then if term.isAvailable() then term.clear() end end

		print("FLUID STOCK V1.0 BY WUN_TEP")
		print("Press 'q' to quit the program")
		print("Press 'e' to edit the table")
		print("Press 'h' to reset all the values")
		print("Press 'j' to show all the 0/0 fluids")
		print("Click the mouse to pause the program")
		print("")

		if checkForMe_Controller() then printLiquids() sendSignals()
		else print("NO ME_CONTROLLER FOUND!")
		end
	end
	os.sleep(3)
end

saveMaintableToFile()
turnOffAllSignals()
print("Terminated!")

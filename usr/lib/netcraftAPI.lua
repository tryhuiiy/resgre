-- NetCraft API by Juanan76
local event = require("event")
local computer = require("computer")

local net = {}

function net.send(modem,client,port,rport,msg)
    modem.send(client,port,rport,msg)
end

function net.filterByClient(client)
    return function(eventName, i1, c) return eventName=="modem_message" and c == client end
end

function net.filterOnlyNetMsg()
    return function(eventName) return eventName=="modem_message" end
end

function net.handleEvent(filterFunc, timeout)
    local start = computer.uptime()
    while true do
        local args = table.pack(event.pull(1, "modem_message")) -- design limitation: in case there are other events, like the player typing, timeout will not work!!
        if args[1] ~= nil then
            if filterFunc(table.unpack(args)) then return table.unpack(args) end
            event.push(table.unpack(args))
        end
        if timeout~=nil and computer.uptime()-start >= timeout then return nil end
    end
end

function net.listen(modem, port, timeout)
    modem.open(port)
    local client, clientPort, msg
    
    _,_,client,_,_,clientPort,msg = net.handleEvent(net.filterOnlyNetMsg(), timeout)
    
    return client, clientPort, msg
end


function net.listentoclient(modem, port, cip, timeout)
    modem.open(port)
    local client, clientPort, msg

    _,_,client,_,_,clientPort,msg = net.handleEvent(net.filterByClient(cip), timeout)

    return client, clientPort, msg
end

function net.server(modem,port)
	local t = {}
	t.listen = function(timeout)
		return net.listen(modem,port,timeout)
	end
	return t
end
function net.connect(modem,addr,port)
	return node --Yes this works!
end

return net
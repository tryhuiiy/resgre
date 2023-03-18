component = require("component")

--cfg = require("config")
cfg = {
	gpu = component.list("gpu")(),
	scr = component.list("screen")()
}
storage = require("storage")
gpu = component.proxy(cfg.gpu)
gpu.bind(cfg.scr)
data = component.data

-- Paleta de colores
-- [negro(1),blanco(2),rojo(3),verde(4),azul(5),amarillo(6),purpura(7)]
paleta = {0x000000,0xFFFFFF,0xFF0000,0x00FF00,0x0000FF,0xFFFF00,0xFF00FF}
for k,v in ipairs(paleta) do
	gpu.setPaletteColor(k,v)
end
w1,h1 = gpu.getResolution()

function text(gpu,x,y,col,text)
	gpu.setForeground(col,true)

	local f = x
	for c in text:gmatch(".") do
		gpu.set(f,y,c)
		f = f + 1
	end
	gpu.setForeground(2,true)
end

function generateWallet()
    local pk,sk = data.generateKeyPair()
    local file = assert(io.open("wallet.pk","w"))
    file:write(pk.serialize())
    file:close()
    file = assert(io.open("wallet.sk","w"))
    file:write(sk.serialize())
    file:close()
    file = assert(io.open("nodes.txt","w"))
    file:write("{}")
    file:close()
    storage.generateIndex()
    storage.generateutxo()
    file = assert(io.open("lb.txt","w"))
    file:write("error")
    file:close()
    file = assert(io.open("contacts.txt","w"))
    file:write("{}")
    file:close()
end

function printTransaction(gpu,x,y,t,conf)
    local from = "My wallet"
    local to = "My wallet"
    if #t.sources==0 then from = "Mining reward"
    elseif t.from ~= cache.walletPK.serialize() then from = string.sub(t.from,1,6) .. (#t.from > 6 and "..." or "") end

    if t.to ~= cache.walletPK.serialize() then to = string.sub(t.to,1,6) .. (#t.to > 6 and "..." or "") end
    
    if (conf==nil) then text(gpu,x,y,7,from .. " -> " .. to .. "   " .. t.qty/1000000 .. " NTC")
    else text(gpu,x,y,7,from .. " -> " .. to .. "   " .. t.qty/1000000 .. " NTC  " .. conf .. " confirmations")
    end
end

function updateScreen(cb,tb,rt,pt)
    gpu.fill(0,0,w1,h1," ")
    text(gpu,1,1,2,"Confirmed balance")
    text(gpu,1,2,4,cb/1000000 .. " NTC")
    text(gpu,1,4,2,"Total balance")
    text(gpu,1,5,6,tb/1000000 .. " NTC")
    
    text(gpu,w1-25,1,2,"Recent transactions")
    local counter = 2
    for k,v in pairs(rt) do
        printTransaction(gpu,w1-40,counter+2,v)
        counter = counter + 1
    end
    
    text(gpu,1,7,2,"Pending transactions ("..#pt..")")
    counter = 2
    for k,v in pairs(pt) do
        printTransaction(gpu,1,7+counter,v,v.confirmations)
        counter = counter + 1
    end
    
end

local file = io.open("wallet.pk","r")
if file==nil then print("Generating public/private keypair...") generateWallet() print("Success!") end
file = io.open("wallet.pk","r")
cache.walletPK = data.deserializeKey(file:read("*a"),"ec-public")
file:close()
file = io.open("wallet.sk","r")
cache.walletSK = data.deserializeKey(file:read("*a"),"ec-private")
file:close()
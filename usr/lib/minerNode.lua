require("common")
component = require("component")
serial = require("serialization")

require("protocol")
protocolConstructor(require("component"), require("storage"), require("serialization"), require("filesystem"))

require("wallet")

function newTransaction(t)
    cache.transpool[t.id] = t
end

function deleteTransaction(id)
    cache.transpool[id] = nil
end

minercentralIP = false

function newBlock(block)
    if minercentralIP == false then return end

    local b = {}
    b.timestamp = os.time()
    b.transactions = {}
    b.previous = block.uuid
    b.height = block.height + 1
    
    local fbago = getPrevChain(block,49)
    b.target = getNextDifficulty(fbago,block)
    
    local rt = {}
    rt.id = randomUUID(16)
    rt.from = "gen"
    rt.to = cache.walletPK.serialize()
    rt.qty = getReward(b.height)
    rt.sources = {}
    rt.rem = 0
    rt.sig = component.data.ecdsa(rt.id .. rt.from .. rt.to .. rt.qty .. concatenateSources(rt.sources).. rt.rem,cache.walletSK)
    table.insert(b.transactions,rt)

    b.uuid = "PLACEHOLDERFOR64BYTES---0000000000000000000000000000000000000000"
    
    for k,v in pairs(cache.transpool) do
        local result = verifyTransaction(v, storage.utxopresent, storage.remutxopresent)
        if (result~=false and result~="gen") then
            local copy = b
            table.insert(b.transactions,v)
            if #serial.serialize(b) > 5000 then -- maximum block size reached
                b.transactions[#b.transactions] = nil
            end
        else
            cache.transpool[k] = nil
        end
    end

    b.uuid = tohex(component.data.sha256(b.height .. b.timestamp .. b.previous .. hashTransactions(b.transactions)))

    component.modem.send(minercentralIP,7000,"NJ####" .. serial.serialize(b))
end

function genesisBlock()
    if minercentralIP == false then return end

    local b = {}
    b.timestamp = os.time()
    b.transactions = {}
    b.previous = ""
    b.height = 0
    b.target = STARTING_DIFFICULTY
    
    local rt = {}
    rt.id = randomUUID(16)
    rt.from = "gen"
    rt.to = cache.walletPK.serialize()
    rt.qty = getReward(b.height)
    rt.sources = {}
    rt.rem = 0
    rt.sig = component.data.ecdsa(rt.id .. rt.from .. rt.to .. rt.qty .. concatenateSources(rt.sources) .. rt.rem,cache.walletSK)
    table.insert(b.transactions,rt)
    b.uuid = tohex(component.data.sha256(b.height .. b.timestamp .. b.previous .. hashTransactions(b.transactions)))
    component.modem.send(minercentralIP,7000,"NJ####" .. serial.serialize(b))
end
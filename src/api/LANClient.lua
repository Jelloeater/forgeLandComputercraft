-- Local Area Networking w/ CRFv3.1, Client Side
-- Most of the explanations are in the CRFv3.1 source code.

local identStr = "LAN"
local freq = 0xC01D

local router_id = -1
local modemSide = ""
local modem = {}
local lan_key = {}
local networks_available = {}

local svcRunning = false

if not fs.exists("AES") then
	print("AES library does not exist, attempting to download...")
	if http then
		local wHandle = http.get("http://pastebin.com/raw.php?i=rCYDnCxn")
		if wHandle then
			local fHandle = fs.open("AES", "w")
			if fHandle then
				fHandle.write(wHandle.readAll())
				fHandle.close()
			else
				print("Could not open AES for writing.")
			end
			wHandle.close()
		else
			print("Could not connect to pastebin.")
		end
	else
		print("HTTP is disabled.")
	end
end

if not fs.exists("SHA2") then
	print("SHA2 library does not exist, attempting to download...")
	if http then
		local wHandle = http.get("http://pastebin.com/raw.php?i=9c1h7812")
		if wHandle then
			local fHandle = fs.open("SHA2", "w")
			if fHandle then
				fHandle.write(wHandle.readAll())
				fHandle.close()
			else
				print("Could not open SHA2 for writing.")
			end
			wHandle.close()
		else
			print("Could not connect to pastebin.")
		end
	else
		print("HTTP is disabled.")
	end
end

local secureLANEnabled = true

if (not ((AES ~= nil) or os.loadAPI("AES"))) or (not ((SHA2 ~= nil) or os.loadAPI("SHA2"))) then
	print("Could not load encryption libraries; encrypted LAN functionality disabled!")
	secureLANEnabled = false
end


local function raw_recv(timeout, id)
	local t = {}
	if timeout then
		t = os.startTimer(timeout)
	end
	while true do
		local event, side, sCH, rCh, data = os.pullEvent()
		if event == "modem_message" then
			data = textutils.unserialize(data)
			if type(data) == "table" then
				if data[1] == identStr then
					if data[4] == os.computerID() then
						if ((id ~= nil) and (id == data[2])) or (id == nil) then
							return side, data
						end
					end
				end
			end
		elseif event == "timer" then
			if side == t then
				return
			end
		end
	end
end

function authenticate(side, id, key)
	assert((type(key) == "string"), "authenticate: key type must be a string")
	local _, k = SHA2.digestStr(key)
	lan_key = SHA2.hashToBytes(k)
	if peripheral.isPresent(side) then
		modem = peripheral.wrap(side)
		modem.open(freq)
		modemSide = side
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "auth_req", id} ))
		while true do
			local sender, data = raw_recv(10, id)
			if data then
				if data[3] == "auth_challenge" then
					local challenge = data[5]
					local response = AES.encrypt_block(challenge, lan_key)
					modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "auth_response", id, response} ))
				elseif data[3] == "auth_good" then
					return true
				elseif data[3] == "auth_fail" then
					--modem.closeAll()
					lan_key = {}
					--modem = {}
					--modemSide = ""
					return false
				end
			else
				return false
			end
		end
	end
end

function associate(side, id)
	if peripheral.isPresent(side) then
		modem = peripheral.wrap(side)
		modem.open(freq)
		modemSide = side
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "assoc", id} ))
		local s, data = raw_recv(10, id)
		if data then
			if data[3] == "assoc_ack" then
				router_id = id
				return true
			end
		end
	end
	modem = {}
	modemSide = ""
	return false
end

function disassociate()
	if modem.transmit and (router_id > -1) then
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "disassoc", router_id} ))
		local s, data = raw_recv(10, router_id)
		if data then
			if data[3] == "disassoc_ack" then
				modem.closeAll()
				router_id = -1
				modem = {}
				modemSide = ""
				return true
			end
		end
	end
	return false
end

function requiresAuth(side, id)
	if networks_available[id] then
		return networks_available[id][2]
	end
	if peripheral.isPresent(side) then
		local m = peripheral.wrap(side)
		m.open(freq)
		m.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "auth_required", id} ))
		while true do
			local sender, data = raw_recv(10, id)
			if data then
				if data[3] == "auth_not_required" then
					m.closeAll()
					networks_available[id] = {"", false, os.clock()}
					return false
				elseif data[3] == "auth_required" then
					m.closeAll()
					networks_available[id] = {"", true, os.clock()}
					return true
				end
			else
				return false
			end
		end
	end
end

function connect(side, id, key)
	if requiresAuth(side, id) then
		if not authenticate(side, id, key) then
			return false
		end
	end
	return associate(side, id)
end

function force_disconnect()
	if modem.transmit and (router_id > -1) then
		if not disconnect() then
			modem.closeAll()
			router_id = -1
			modem = {}
			modemSide = ""
		end
		return true
	end
	return false
end

function get_router()
	return router_id
end

function get_id_list()
	if modem.transmit and (router_id > -1) then
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "id_list", router_id} ))
		local s, data = raw_recv(10, router_id)
		if data then
			if data[3] == "id_list" then
				return data[5]
			end
		end
	end
	return
end

function get_lan_list()
	if modem.transmit and (router_id > -1) then
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "lan_list", router_id} ))
		local s, data = raw_recv(10, router_id)
		if data then
			if data[3] == "id_list" then
				return data[5]
			end
		end
	end
	return
end

function send(id, data)
	if modem.transmit and (router_id > -1) then
		if (#lan_key == 0) then
			modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "data", router_id, id, data} ))
			local s, data = raw_recv(10, router_id)
			if data then
				if data[3] == "data_ack" then
					return true
				elseif data[3] == "data_fail" then
					return false
				end
			end
		else
			local packet = {id, data}
			local plain_data = {}
			local plain_data_str = textutils.serialize(packet)
			local iv = {}
			for i=1, 16 do
				iv[i] = math.random(0, 255)
			end
			for i=1, #plain_data_str do
				plain_data[i] = string.byte(plain_data_str, i, i)
			end
			local enc_packet = AES.encrypt_bytestream(plain_data, lan_key, iv)
			modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "encrypted_data", router_id, iv, enc_packet} ))
			local s, data = raw_recv(10, router_id)
			if data then
				if data[3] == "data_ack" then
					return true
				elseif data[3] == "data_fail" then
					return false
				end
			end
		end
	end
	return false
end

function broadcast(data)
	return send(-1, data)
end

function backgroundLoop()
	svcRunning = true
	local timer = os.startTimer(30)
	while true do
		local event, side, sCh, rCh, data = os.pullEvent()
		if event == "modem_message" then
			--print(data)
			data = textutils.unserialize(data)
			if type(data) == "table" then
				if (data[1] == identStr) and ((data[4] == os.computerID()) or (data[4] == -1)) then
					if (data[3] == "data") then
						os.queueEvent("routed_message", data[5], data[6])
					elseif (data[3] == "encrypted_data") then
						local iv = data[5]
						local enc_data = data[6]
						if (#lan_key ~= 0) then
							local dec_data = AES.decrypt_bytestream(enc_data, lan_key, iv)
							local dec_str = ""
							for i=1, #dec_data do
								dec_str = dec_str..string.char(dec_data[i])
							end
							dec_packet = textutils.unserialize(dec_str)
							if type(dec_packet) == "table" then
								os.queueEvent("routed_message", dec_packet[1], dec_packet[2])
								--handle_datagram(side, {data[1], data[2], "data", data[4]}, dec_packet[1], dec_packet[2])
							end
						end
					elseif (data[3] == "rekey") then
						os.queueEvent("LAN_network_rekey")
					elseif (data[3] == "beacon") then
						if not networks_available[data[2]] then
							os.queueEvent("LAN_new_network", data[2], data[5], data[6])
						end
						networks_available[data[2]] = {data[5], data[6], os.clock()}
					end
				end
			end
		elseif event == "timer" then
			if side == timer then
				local removeList = {}
				for i,v in pairs(networks_available) do
					if v[3] then
						if (os.clock() - v[3]) >= 45 then
							table.insert(removeList, i)
						end
					end
				end
				for i=1, #removeList do
					networks_available[removeList[i]] = nil
				end
			end
		end
	end
end

function receive(timeout, id)
	while true do
		local side, data = raw_recv(timeout, router_id)
		if type(data) == "table" then
			if (data[1] == "LAN") and ((data[3] == "data") or (data[3] == "encrypted_data")) and (data[4] == os.computerID()) and ((id == nil) or (data[5] == id)) then -- In order: Ident string checking, packet type checking, recipient checking, and non-local sender checking if applicable.
				if (data[3] == "encrypted_data") then
					local iv = data[5]
					local enc_data = data[6]
					if (#lan_key ~= 0) then
						local dec_data = AES.decrypt_bytestream(enc_data, lan_key, iv)
						local dec_str = ""
						for i=1, #dec_data do
							dec_str = dec_str..string.char(dec_data[i])
						end
						dec_packet = textutils.unserialize(dec_str)
						if type(dec_packet) == "table" then
							return dec_packet[1], dec_packet[2]
							--handle_datagram(side, {data[1], data[2], "data", data[4]}, dec_packet[1], dec_packet[2])
						end
					end
				else
					return data[5], data[6]
				end
			end
		elseif side == nil then
			return
		end
	end
end

function join_group(group)
	if modem.transmit and (router_id > -1) then
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "join_group", router_id, group} ))
		local s, data = raw_recv(10, router_id)
		if data then
			if data[3] == "group_ack" then
				return true
			elseif data[3] == "group_fail" then
				return false
			end
		end
	else
		return false
	end
end

function leave_group(group)
	if modem.transmit and (router_id > -1) then
		modem.transmit(freq, freq, textutils.serialize( {identStr, os.computerID(), "leave_group", router_id, group} ))
		local s, data = raw_recv(10, router_id)
		if data then
			if data[3] == "group_ack" then
				return true
			elseif data[3] == "group_fail" then
				return false
			end
		end
	else
		return false
	end
end

function get_networks()
	return networks_available
end

if shell then
	local file = fs.open(shell.getRunningProgram(), "r")
	if file then
		local l = file.readLine()
		file.close()
		if string.match(l, "Local Area Network") and string.match(l, "Client Side") then
			local apiName = fs.getName(shell.getRunningProgram())
			if not _G[apiName] then
				os.loadAPI(shell.getRunningProgram())
			end
			local args = {...}
			if args[1] == "connect" then
				connect(args[2], args[3], args[4])
			elseif (args[1] == "disconnect") or (args[1] == "disassociate") then
				disassociate()
			elseif (args[1] == "receive") or (args[1] == "recv") then
				receive(tonumber(args[2]))
			elseif (args[1] == "send") then
				if (tonumber(args[2]) ~= nil) and (type(args[3]) == "string") then
					send(tonumber(args[2]), args[3])
				end
			elseif (args[1] == "help") or (#args == 0) then
				print("LANClient -- CRFv3.1 LAN API and basic interface")
				print(string.rep("-", term.getSize()))
				print("Usage: LANClient [action] [args]")
				print("Actions:")
				print("connect (\"connect [side] [id] [key]\"): Connect to a LAN.")
				print("disconnect (\"disconnect\"): Disconnect from a LAN.  ")
				print("receive / recv (\"recv [timeout]\"): Receive from a LAN.")
				print("send (\"send [id] [data]\"): Send simple messages via a LAN.")
				print("Information on the API can be found on the ComputerCraft forum topic.")
			end
		end
	end
end
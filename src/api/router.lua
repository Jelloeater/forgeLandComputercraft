-- Common Routing Framework, Version 3.1
-- This version adds Local Area Networks, allowing multiple computers to be added to the network with a minimum of resource usage.
-- The clients in a LAN are shown to other hosts as routers with only one neighbor: the router that is hosting the LAN.
-- The router then intercepts packets addressed to LAN clients and sends them as LAN data packets.
-- This functionality can also be used to bridge wired and wireless networks.
-- LAN encryption is supported; as with most things involving encryption, it requires the AES and SHA2 libraries.
-- WAN encryption is supported; again, it also requires the AES/SHA2 libraries.

-- Packet structure (CRF and LAN):
-- [1] : Identification String ("CRFv3" for CRF packets, "LAN" for LAN packets)
-- [2] : Sender
-- [3] : Packet Type
-- [4+]: Data

-- Packet Types / Structure:
-- "ping" / "pong" : Reachability Protocol packets, has one field: the Multicast Group List. CRF only.
--	* Multicast Group List: A list of groups this router is listening to.
-- "lsa" : Link State Advertisement, used to inform other routers about potential routes. Has one data field, containing the LSA itself. CRF only.
--	* LSA Format:
--	 * Originator: The ID of the computer who originally generated the LSA.
--	 * ID: A 32 bit number that is different for each LSA sent out by a particular host. LSAs from the same host with duplicate IDs are ignored.
--	 * Recipient List: A list of computers who have received a particular LSA. Used to detect duplicate LSAs.
--	 * Host List: A list of computers directly linked to the Originator (wirelessly or otherwise). Used to calculate routing tables.
-- "data" : Data. Has four data fields:
--	* Source: The computer sending the packet. Not present in LAN data packets; the "Sender" field takes care of this.
--	* Recipient: The computer receiving the packet. In LAN data packets, a "Recipient" field of -1 indicates a broadcast packet.
--	* Message: The data sent.
--	* Next-hop: The computer the packet is being forwarded to. Not present in LAN data packets.
--  * Multicast ID: A unique (for each source router) number used to filter out duplicate multicast packets. This is similar to LSA IDs.

-- LAN-only packets:
-- "encrypted_data": An encrypted data packet. Field 5 is a table containing the encrypted bytes of a serialized table of the format: {recipient, data}.
-- "auth_required": 
--	* From client to server: A message asking if authentication is required.
--	* From server to client: A message confirming that authentication is required.
-- "auth_not_required": A message confirming that authentication is not required.
-- "auth_req" : A request to authenticate.
-- "auth_challenge" : A challenge issued by an AP to a client, in response to an "auth_req" message.
-- "auth_response" : A response to a challenge contained in a "auth_challenge" message.
-- "auth_good" : An indication that the response matched what was expected and that the client is now clear to associate.
-- "auth_fail" : An indication that the response did not match what was expected.
-- "assoc" : A request to join a particular Local Area Network.
-- "assoc_ack" : An acknowledgement of the above packet.
-- "assoc_fail": An indication that the requestor is already a part of the indicated LAN.
-- "disassoc" : A request to leave a particular Local Area Network.
-- "disassoc_ack" : An acknowledgement of the above packet.
-- "disassoc_fail": An indication that the disassociation packet is invalid (came from the wrong interface) or that the requestor was never a part of the LAN in the first place.
-- "id_list": A (request for) a listing of every client the router knows of, including other routers and their LANs.
-- "lan_list": A (request for) a listing of every client on the requestor's Local Area Network.
-- "join_group": A request to register for multicast listening.
-- "leave_group": A request to unregister for multicast listening.
-- "group_ack": A positive acknowlegement for the above two packets.
-- "group_fail": A negative acknowlegement for the above group join/leave requests.

-- On Multicast:
-- Multicast is indicated by a negative "Recipient" address in packets.
-- The "group" the packet belongs to is defined as abs(recipient); for example, a "recipient" value of -5 indicates a group of 5. Multicast group 1 (recipient address -1) is reserved for the local (LAN) broadcast group.
-- Groups are used to indicate which routers want which packets.
-- Routers and LAN Clients indicate that they wish to join a particular group. Any multicast packets passing through that belong to that group are replicated and sent both to any adjecent routers who have indicated that they wish to receive that packet, and
-- any those local clients.

-- On WAN encryption:
-- WAN encryption runs on top of the normal router. It defines one additional packet type, identified by the string "encrypted_packet".
-- structure: {crf_ident, local sender, "encrypted_packet", encrypted data, iv, src, rec, next_hop, key_ident, hmac, recv_list }
-- hmac is hmac( textutils.serialize( {decrypted_data, encrypted_data, iv, key_ident, src, rec} ) )

if not fs.exists("AES") then
	print("AES library does not exist, attempting to download...")
	if http then
		local wHandle = http.get("http://pastebin.com/raw.php?i=rCYDnCxn")
		if wHandle then
			local fHandle = fs.open("AES", "w")
			if fHandle then
				fHandle.write(wHandle.readAll())
				fHandle.close()
				haveSoftware_AES = true
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
				haveSoftware_SHA2 = true
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

local securityEnabled = true 

if (not ((AES ~= nil) or os.loadAPI("AES"))) or (not ((SHA2 ~= nil) or os.loadAPI("SHA2"))) then
	print("Could not load encryption libraries; encrypted LAN/WAN functionality disabled!")
	securityEnabled = true 
end

local args = {...}

-- Static Variables:
local crf_freq = 0xE110
local crf_identStr = "CRFv3"
local crf_pongStr = textutils.serialize( {crf_identStr, os.computerID(), "pong"} )
local crf_running = false

local wan_enc_routers = {} -- Routers using the same key as we are
local wan_enc_routers_local = {} -- Local routers using the same key as we are
local wan_key = {}
local wan_key_ident = ""
local wan_verify_inbound = true -- Check verification HMAC for incoming packets
local wan_verify_outbound = true -- Add verification HMAC to outgoing packets
_G["CRF"] = {}

local lan_freq = 0xC01D
local lan_identStr = "LAN"
local lan_clients = {}
local lan_auth = {} -- Client authentication list; contains challenge text and authentication state.
local lan_key = {}
local lan_name = "Network #"..os.computerID()
local lan_running = false
local lan_multicast = {} -- Multicast group list. Stored as a dictionary; lan_multicast[5] corresponds to multicast group 5.
_G["LAN"] = {}

local debugFlags = {
	["events"]     = 0x01, -- Routing events (LSA / Ping recieved, data incoming), automatically assumes all other "event" flags ("timed", "dataEvents", "pingEvents", and "lsaEvents")
	["timed"]      = 0x02, -- Timing events (Ping/LSACheck/LSAForce timers)
	["timing"]     = 0x02, -- alias for "timed"
	["routeGen"]   = 0x04, -- Route generation (Interface bindings, etc.)
	["bfs"]        = 0x08, -- Breadth-first search function info (currentnode=1, etc)
	["dataEvents"] = 0x10, -- Incoming data only
	["pingEvents"] = 0x20, -- Reachability Protocol only
	["lsaEvents"]  = 0x40, -- LSAs only
	["LANEvents"]  = 0x80, -- LAN protocol events (associations, disassociations, list requests, etc.)
	["all"]        = 0xFF, -- Sets all event bits.
}

-- Dynamic Variables:

-- We need two lists, because some hosts may only be reachable through one interface.
local wirelessModem = {} -- Only need one wireless modem.
local wiredModems = {}
local modem = {} -- For convenience.

local routingTable = {} -- Holds next-hop interfaces for each reachable host.
local localHosts = {} -- Holds host/interface bindings for all directly-reachable hosts.
local allHosts = {} -- Holds host/interface bindings for all hosts on all attached networks.

local multicast_downstream = {} -- Holds a list of multicast groups we need to keep track of. Stored by adjecent router. Example: multicast_downstream[5] is a list of all multicast groups router 5 is listening to.
local multicast_ids = {} -- Holds a list of packet IDs for multicast groups we're keeping track of. Stored by group.

local lastLSAs = {}

for i,v in ipairs(rs.getSides()) do
	if peripheral.getType(v) == "modem" then
		local iModem = peripheral.wrap(v)
		iModem["side"] = v
		if iModem.isWireless() and (not wirelessModem.open) then
			wirelessModem = iModem
			wirelessModem.open(crf_freq)
			wirelessModem.open(lan_freq)
		else
			iModem.open(crf_freq)
			iModem.open(lan_freq)
			wiredModems[v] = iModem
			table.insert(wiredModems, iModem)
		end
		modem[v] = iModem
	end
end

local function bfs(list, start, dest, debug)
	local queue = { start }
	local paths = {}
	local route = {}
	local visited = { [start] = true }
	while true do
		local current = table.remove(queue, 1)
		if current == dest then
			break
		end
		if (type(debug) == "number") and (bit.band(debug, debugFlags["bfs"]) > 0) then
			print("bfs: current="..current)
		end
		for node, side in pairs(list[current]) do
			if (type(debug) == "number") and (bit.band(debug, debugFlags["bfs"]) > 0) then
				print("bfs: current node="..node)
			end
			if not visited[node] and list[node] then
				visited[node] = true
				paths[node] = current
				table.insert(queue, node)
			end
		end
		if #queue == 0 then
			break
		end
		os.queueEvent("CRF_routegen")
		os.pullEvent("CRF_routegen")
	end
	if dest then
		local c = dest
		while true do
			table.insert(route, 1, c)
			c = paths[c]
			if not c then
				break
			end
			os.queueEvent("CRF_routegen")
			os.pullEvent("CRF_routegen")
		end
	end
	return route, paths
end

local function generateRoutingTable(debug)
	for i,v in pairs(lan_clients) do
		localHosts[i] = v
		allHosts[i] = v
	end
	local hostLSAs = { [os.computerID()] = localHosts }
	for i,v in pairs(lastLSAs) do
		hostLSAs[i] = v[2]
	end
	if (type(debug) == "number") and bit.band(debug, debugFlags["routeGen"]) > 0 then
		print("Generating routing tables...")
	end
	local _, paths = bfs(hostLSAs, os.computerID(), nil, debug) -- get paths to all nodes
	local hostDict = {}
	for i,v in pairs(paths) do
		if (type(debug) == "number") and (bit.band(debug, debugFlags["routeGen"]) > 0) then
			print("Path found for "..i.." and "..v)
		end
		hostDict[i] = true
		hostDict[v] = true
		os.queueEvent("CRF_routegen")
		os.pullEvent("CRF_routegen")
	end
	for i,v in pairs(hostDict) do
		--local route = bfs(hostLSAs, os.computerID(), i, debug)
		--routingTable[i] = {localHosts[route[2]], route[2]}
		if (type(debug) == "number") and (bit.band(debug, debugFlags["routeGen"]) > 0) then
			print("Determining interface for "..i)
		end
		if i ~= os.computerID() then
			if localHosts[i] then -- We're directly connected to the host, so we can just look in localHosts instead of following the link chain
				if (type(debug) == "number") and (bit.band(debug, debugFlags["routeGen"]) > 0) then
					print("Interface for "..i..": "..localHosts[i].." (local)")
				end
				routingTable[i] = { localHosts[i], i }
			else
				local route = {}
				local c = i
				local step = 0
				while true do
					table.insert(route, 1, c)
					c = paths[c]
					if not c then
						break
					end
					if (type(debug) == "number") and bit.band(debug, debugFlags["routeGen"]) > 0 then
						print("Determining interface for "..i..". c: "..c)
					end
				end
				if localHosts[route[2]] then
					routingTable[i] = { localHosts[route[2]], route[2] }
					if (type(debug) == "number") and (bit.band(debug, debugFlags["routeGen"]) > 0) then
						print("Interface for "..i.." is "..localHosts[route[2]]..", via "..route[2])
					end
				elseif (type(debug) == "number") and (bit.band(debug, debugFlags["routeGen"]) > 0) then
					print("Interface for "..os.computerID().."->"..route[2].." is unknown")
				end
			end
		end
		if (type(debug) == "number") and (bit.band(debug, debugFlags["routeGen"]) > 0) then
			print("Finished determining interface for "..i)
		end
	end
end

local function transmitLSA(debug)
	for i,v in pairs(lan_clients) do
		localHosts[i] = v
		allHosts[i] = v
		wan_enc_routers_local[i] = wan_key_ident
	end
	local lsa = {os.computerID(), 0, {}, localHosts, wan_enc_routers_local } -- transmit our ID, the LSA ID, the list of hosts we're connected to, and a dict matching keys to entries in localHosts
	while true do
		local cand = math.random(1, (2^30))
		if not lastLSAs[os.computerID()] or lastLSAs[os.computerID()][1] ~= cand then
			lsa[2] = cand
			lastLSAs[os.computerID()] = { cand, localHosts }
			break
		end
	end
	if (type(debug) == "number") and ((bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
		print("Sending LSAs on all interfaces...")
	end
	if wirelessModem.transmit then
		wirelessModem.transmit( crf_freq, crf_freq, textutils.serialize( {crf_identStr, os.computerID(), "lsa", lsa} ) )
	end
	for i=1, #wiredModems do
		wiredModems[i].transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "lsa", lsa } ))
	end
	generateRoutingTable(debug)
end

local function raw_encrypted_send(side, packetTo, sender, packetData)
	if (type(packetData) ~= "string") then
		error("encrypted_send: data type must be string!", 2)
	end
	if (#lan_key ~= 0) then
		local plain_data = {}
		local plain_data_str = textutils.serialize({sender, packetData})
		local iv = {}
		for i=1, 16 do
			iv[i] = math.random(0, 255)
		end
		for i=1, #plain_data_str do
			plain_data[i] = string.byte(plain_data_str, i, i)
		end
		local enc_packet = AES.encrypt_bytestream(plain_data, lan_key, iv)
        --print(side)
		modem[side].transmit(lan_freq, lan_freq, textutils.serialize( {lan_identStr, os.computerID(), "encrypted_data", packetTo, iv, enc_packet} ))
	end
end

local function encrypted_wan_send(msg, from, to)
	-- structure: {crf_ident, local sender, "encrypted_packet", encrypted data, iv, src, rec, next_hop, hmac, recv_list }
	-- hmac is hmac( textutils.serialize( {decrypted_data, iv, src, rec} ) )
	local dec_data = {}
	for i=1, #msg do
		dec_data[i] = string.byte(msg, i, i)
	end
	local iv = {}
	for i=1, 16 do
		iv[i] = math.random(0, 255)
	end
	local enc_data = AES.encrypt_bytestream(dec_data, wan_key, iv)
	local hmac = {}
	if wan_verify_outbound then
		local verify_data_str = "" --textutils.serialize({dec_data, iv, from, to})
		for i=1, #enc_data do
			verify_data_str = verify_data_str..string.char(enc_data[i])
		end
		for i=1, #iv do
			verify_data_str = verify_data_str..string.format("%X", iv[i])
		end
		verify_data_str = verify_data_str..from
		verify_data_str = verify_data_str..to
		local verify_data = {}
		for i=1, #verify_data_str do
			verify_data[i] = string.byte(verify_data_str, i, i)
		end
		hmac = SHA2.hashToBytes(SHA2.hmac(verify_data, wan_key))
		local h1_str = ""
		if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
			for i=1, #hmac do
				h1_str = h1_str..string.format("%X", hmac[i])
			end
			local iv_str = ""
			for i=1, #iv do
				iv_str = iv_str..string.format("%X", iv[i])
			end
			print("CRF: HMAC is: "..h1_str)
			print("CRF: Verify string is: "..verify_data_str)
			print("CRF: Init vector is: "..iv_str)
		end
	else
		hmac = nil
	end
	modem[routingTable[to][1]].transmit(crf_freq, crf_freq, textutils.serialize( {crf_identStr, os.computerID(), "encrypted_packet", enc_data, iv, from, to, routingTable[to][2], hmac, [10] = { [os.computerID()] = true } } ))
end

local function handle_datagram(side, data, packetTo, packetData)
	local sender = data[2]
	if packetTo == -1 then -- Broadcast
		for client_id, client_side in pairs(lan_clients) do
			if data[3] == "encrypted_data" then
				raw_encrypted_send(client_side, client_id, sender, packetData)
			else
				modem[client_side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", client_id, sender, packetData } ))
			end
		end
		modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data_ack", sender} ))
		if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
			print("LAN: Broadcast message from "..sender.." received.")
		end
	elseif packetTo < -1 then -- Multicast
		local cand = math.random(0, 2^30)
		while true do
			if multicast_ids[math.abs(packetTo)] ~= cand then
				break
			else
				cand = math.random(0, 2^30)
			end
		end
		multicast_ids[math.abs(packetTo)] = cand
		for i,v in pairs(modem) do -- Broadcast the inital multicast packet to all routers we're connected to. Surely one of them will know what to do with it..
			v.transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "data", sender, packetTo, packetData, nil, cand, { [os.computerID()] = true } } ))
		end
		local groupID = math.abs(packetTo)
		if lan_multicast[groupID] then
			for i,v in pairs(lan_multicast[groupID]) do
				if i ~= sender then
					if data[3] == "encrypted_data" then
						raw_encrypted_send(lan_clients[i], i, sender, packetData)
					else
						modem[lan_clients[i]].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", i, sender, packetData} ))
					end
				end
			end
		end
		modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data_ack", sender } ))
	elseif routingTable[packetTo] then -- Not a LAN client
		if wan_enc_routers[packetTo] == wan_key_ident then
			print("CRF/LAN: Endpoint is using the same key as us, sending encrypted...")
			encrypted_wan_send(packetData, sender, packetTo)
			modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data_ack", sender} ))
		else
			print("CRF/LAN: Endpoint is not using the same key as us, sending unencrypted...")
			modem[routingTable[packetTo][1]].transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "data", sender, packetTo, packetData, routingTable[packetTo][2] } ))
			modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data_ack", sender} ))
		end
		if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
			print("LAN: Packet addressed to non-local host "..packetTo.." from "..sender.." received.")
		end
	elseif lan_clients[packetTo] then -- LAN client
		if data[3] == "encrypted_data" then
			raw_encrypted_send(lan_clients[packetTo], packetTo, sender, packetData)
		else
			modem[lan_clients[packetTo]].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", packetTo, sender, packetData } ))
		end
		modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data_ack", sender} ))
		if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
			print("LAN: Packet addressed to LAN client "..packetTo.." from "..sender.." received.")
		end
	else
		if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
			print("LAN: Packet to unknown recipient "..packetTo.." from "..sender.." received.")
		end
		modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data_fail", sender} ))
	end
end

local function crf_listenerLoop(debug)
	local pingTime = math.random(1, 10)
	local lsaCheckTime = pingTime+1
	local lsaForceTime = lsaCheckTime+math.random(1,10)
	local pingTimer = os.startTimer(pingTime)
	local lsaCheckTimer = os.startTimer(lsaCheckTime)
	--local lsaForceTimer = os.startTimer(lsaForceTime)
	local LANBeaconTimer = os.startTimer(15)
	local lastHostlist = {}
	if (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
		print("Timers:")
		print("Ping: t+"..pingTime.." seconds")
		print("LSACheck: t+"..lsaCheckTime.." seconds")
		print("LSAForce: t+"..lsaForceTime.." seconds")
	end
	if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
		print("LAN: Key size is "..#lan_key)
		print("LAN: Network name is "..lan_name)
	end
	crf_running = true
	lan_running = true
	while true do
		local event, side, tFreq, rFreq, data = os.pullEvent()
		if event == "modem_message" then
			local mType = 0
			if wiredModems[side] then
				mType = 1
			elseif wirelessModem["side"] == side then
				mType = 2
			end
			if ((tFreq == crf_freq) or (tFreq == lan_freq)) and mType > 0 then
				if type(textutils.unserialize(data)) == "table" then
					data = textutils.unserialize(data)
					if data[1] == crf_identStr then
						if data[3] == "ping" then
							if (type(debug) == "number") and ((bit.band(debug, debugFlags["pingEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
								print("Recieved ping from "..data[2].." on "..side.." interface.")
							end
							if not localHosts[data[2]] then
								localHosts[data[2]] = side
							end
							if (data[5] and (data[5] ~= "")) then
								wan_enc_routers_local[data[2]] = data[5]
							end
							if mType == 1 then
								wiredModems[side].transmit(crf_freq, crf_freq, crf_pongStr)
							elseif mType == 2 then
								wirelessModem.transmit(crf_freq, crf_freq, crf_pongStr)
							end
							multicast_downstream[data[2]] = data[4]
						elseif data[3] == "pong" then
							if (type(debug) == "number") and ((bit.band(debug, debugFlags["pingEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
								print("Recieved pong from "..data[2].." on "..side.." interface.")
							end
							if not localHosts[data[2]] then
								localHosts[data[2]] = side
							end
						elseif data[3] == "lsa" then
							local lsa = data[4]
							local origin = lsa[1]
							local id = lsa[2]
							local recv = lsa[3]
							local list = lsa[4]
							if (type(debug) == "number") and ((bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
								print("Recieved LSA from "..data[2].." on "..side.." interface.")
								if lastLSAs[origin] and lastLSAs[origin][1] then
									print("Originator: "..origin.." ID: "..id.." (last: "..lastLSAs[origin][1]..")")
								else
									print("Originator: "..origin.." ID: "..id.." (last: none)")
								end
							end
							if not lastLSAs[origin] then
								lastLSAs[origin] = {}
							end
							if not allHosts[origin] then
								allHosts[origin] = side
							end
							if id ~= lastLSAs[origin][1] and not recv[os.computerID()] then
								if (type(debug) == "number") and ((bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("Valid LSA received. Connected hosts: "..#list..".")
								end
								lsa[3][os.computerID()] = true
								lastLSAs[origin][1] = id
								lastLSAs[origin][2] = list
								-- Transmit new LSA on all networks:
								if wirelessModem.transmit then
									wirelessModem.transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "lsa", lsa } ))
								end
								for i=1, #wiredModems do
									wiredModems[i].transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "lsa", lsa } ))
								end
								-- Fill in the blanks (for LAN-only hosts):
								for id, interfaceSide in pairs(list) do
									if not lastLSAs[id] then
										lastLSAs[id] = {-1, { data[2] } }
									end
								end
								-- Add routers using encryption to our list:
								local enc_routers = lsa[5]
								if enc_routers then
									for i,v in pairs(enc_routers) do
										if (type(debug) == "number") and ((bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
											print("Host "..i.."("..type(i)..") is using key ident "..v)
										end
										wan_enc_routers[i] = v
									end
								elseif (type(debug) == "number") and ((bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("Host "..origin.." did not send router key ident list, skipping....")
								end
								generateRoutingTable(debug)
							end
						elseif data[3] == "data" then
							local from = data[4]
							local to = data[5]
							local msg = data[6]
							local next = data[7]
							if to == os.computerID() then
								if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("Got data from "..from.." via "..next.." on interface "..side..".")
									print("Message: "..msg)
								end
								os.queueEvent("routed_message", from, msg)
							elseif to < -1 then
								local groupID = math.abs(to)
								local packetID = data[8]
								local recvList = data[9]
								if (multicast_ids[groupID] ~= packetID) and (not recvList[os.computerID()]) then
									multicast_ids[groupID] = packetID
									recvList[os.computerID()] = true
									for i,v in pairs(multicast_downstream) do
										if v[groupID] then
											modem[localHosts[i]].transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "data", data[4], data[5], data[6], i, packetID, recvList } ))
										end
									end
									if lan_multicast[groupID] then
										for i,v in pairs(lan_multicast[groupID]) do
											modem[lan_clients[i]].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", i, from, msg} ))
										end
									end
								end
							elseif next == os.computerID() then
								if lan_clients[to] then
									if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
										print("Relaying data from "..from.." to LAN client "..to.." via interface "..lan_clients[to]..".")
									end
									if (#lan_key ~= 0) then
										raw_encrypted_send(lan_clients[to], to, from, msg)
									else
										peripheral.wrap( lan_clients[to] ).transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", to, from, msg} ))
									end
								elseif routingTable[to] then
									if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
										print("Relaying data from "..from.." via "..next.." on interface "..side..".")
										print("Sending to "..routingTable[to][2].." on interface "..routingTable[to][1]..".")
									end
									peripheral.wrap( routingTable[to][1] ).transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "data", data[4], data[5], data[6], routingTable[to][2] } ))
								elseif (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("Unknown-destination packet from "..from.." via "..next.." on interface "..side..".")
									print("Destination: "..to)
								end
							end
						elseif data[3] == "encrypted_packet"then
							-- structure: {crf_ident, local sender, "encrypted_packet", encrypted data, iv, src, rec, next_hop, hmac, recv_list }
							-- hmac is hmac( textutils.serialize( {decrypted_data, encrypted_data, iv, src, rec} ) )
							local enc_data = data[4]
							local iv       = data[5]
							local from     = data[6]
							local to       = data[7]
							local next     = data[8]
							local hmac     = data[9]
							local valid = true
							local dec_data_str = ""
							
							if (#wan_key ~= 0) then
							
								-- Message decryption / validation:
								local dec_data = AES.decrypt_bytestream(enc_data, wan_key, iv)
								local hmac_data_str = "" --textutils.serialize({enc_data, iv, from, to})
								for i=1, #dec_data do
									dec_data_str = dec_data_str..string.char(dec_data[i])
								end
								
                                for i=1, #enc_data do
                                    hmac_data_str = hmac_data_str..string.char(enc_data[i])
                                end
                                
								if wan_verify_inbound then
									if (hmac ~= nil) then
										for i=1, #iv do
											hmac_data_str = hmac_data_str..string.format("%X", iv[i])
										end
										hmac_data_str = hmac_data_str..from
										hmac_data_str = hmac_data_str..to
										local hmac_data = {}
										local lastPause = os.clock()
										for i=1, #hmac_data_str do
											hmac_data[i] = string.byte(hmac_data_str, i, i)
											if os.clock() - lastPause >= 2.80 then
												os.queueEvent("")
												os.pullEvent("")
												lastPause = os.clock()
											end
										end
										local calc_hmac = SHA2.hashToBytes(SHA2.hmac(hmac_data, wan_key))
										for i=1, math.max(#hmac, #calc_hmac) do
											if calc_hmac[i] ~= hmac[i] then
												valid = false
												break
											end
										end
										if valid then
											if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
												local h2_str = ""
												for i=1, #calc_hmac do
													h2_str = h2_str..string.format("%X", calc_hmac[i])
												end
												print("Message validation from "..from.." succeeded: got hash "..h2_str)
											end
										else
											if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
												local h1_str = ""
												local h2_str = ""
												for i=1, #hmac do
													h1_str = h1_str..string.format("%X", hmac[i])
												end
												for i=1, #calc_hmac do
													h2_str = h2_str..string.format("%X", calc_hmac[i])
												end
												for i=1, #dec_data do
													dec_data_str = dec_data_str..string.char(dec_data[i])
												end
												local iv_str = ""
												for i=1, #iv do
													iv_str = iv_str..string.format("%X", iv[i])
												end
												print("Message validation from "..from.." failed: got hash "..h1_str..", expected "..h2_str)
												print("Message data would be "..dec_data_str)
												print("Init vector would be "..iv_str)
												print("HMAC validation string is "..hmac_data_str)
											end
										end
									else
										valid = false
										if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
											print("Message validation from "..from.." failed: no HMAC sent!")
										end
									end
								end
								
							else
								valid = false
							end
							
							if to == os.computerID() then
								if valid then
									if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
										print("Got data from "..from.." via "..next.." on interface "..side..".")
										print("Message: "..dec_data_str)
									end
									os.queueEvent("routed_message", from, dec_data_str)
								end
							elseif to < -1 then
								local groupID = math.abs(to)
								local packetID = bit.bor( iv[1], bit.bor( bit.blshift(iv[2], 8), bit.bor( bit.blshift(iv[3], 16), bit.blshift(iv[4], 24) ) ) )
								local recvList = data[10]
								if (multicast_ids[groupID] ~= packetID) and (not recvList[os.computerID()]) then
									multicast_ids[groupID] = packetID
									recvList[os.computerID()] = true
									for i,v in pairs(multicast_downstream) do
										if v[groupID] then
											modem[localHosts[i]].transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "encrypted_packet", data[4], data[5], data[6], data[7], data[8], data[9], data[10], recvList } ))
										end
									end
									if valid then
										if lan_multicast[groupID] then
											for i,v in pairs(lan_multicast[groupID]) do
												if #lan_key ~= 0 then
													raw_encrypted_send(lan_clients[i], to, from, dec_data_str)
												else
													modem[lan_clients[i]].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", i, from, dec_data_str} ))
												end
											end
										end
									end
								end
							elseif next == os.computerID() then
								if lan_clients[to] then
									if valid then
										if (#lan_key ~= 0) then
											raw_encrypted_send(lan_clients[to], to, from, dec_data_str)
											--raw_encrypted_send(lan_clients[i], i, sender, packetData)
										else
											peripheral.wrap( lan_clients[to] ).transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", to, from, dec_data_str} ))
										end
									end
								elseif routingTable[to] then
									if (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
										print("Relaying data from "..from.." via "..next.." on interface "..side..".")
										print("Sending to "..routingTable[to][2].." on interface "..routingTable[to][1]..".")
									end
									-- structure: {crf_ident, local sender, "encrypted_packet", encrypted data, iv, src, rec, next_hop, key_ident, hmac, recv_list }
									peripheral.wrap( routingTable[to][1] ).transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "encrypted_packet", data[4], data[5], data[6], data[7], routingTable[to][2], data[9], data[10]} ))
								elseif (type(debug) == "number") and ((bit.band(debug, debugFlags["dataEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("Unknown-destination packet from "..from.." via "..next.." on interface "..side..".")
									print("Destination: "..to)
								end
							end
						end
					elseif (data[1] == lan_identStr) and (data[4] == os.computerID()) then
						local sender = data[2]
						if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
							print("LAN: Received LAN message from "..data[2]..".")
							print("LAN: Data type: "..data[3])
						end
						if data[3] == "assoc" then
							--print("Received message type: "..data[3])
							if ((#lan_key == 0) or ((lan_auth[sender]) and (lan_auth[sender][3]))) then
								if ((lan_clients[sender] == nil) or (lan_clients[sender] == side)) then
									lan_clients[sender] = side
									modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "assoc_ack", sender} ))
									if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
										print("LAN: "..sender.." has joined the LAN.")
									end
								else
									modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "assoc_fail", sender} ))
									if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
										print("LAN: "..sender.." failed to join the LAN.")
									end
								end
							end
						elseif data[3] == "disassoc" then
							--print("Received message type: "..data[3])
							local deauthed = false
							if lan_auth[sender] then
								lan_auth[sender] = nil
								deauthed = true
							end
							if lan_clients[sender] == side then
								lan_clients[sender] = nil
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "disassoc_ack", sender} ))
								if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("LAN: "..sender.." has left the LAN.")
								end
							elseif deauthed then
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "disassoc_ack", sender} ))
								if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("LAN: "..sender.." canceled an authentication request.")
								end
							else
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "disassoc_fail", sender} ))
								if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
									print("LAN: "..sender.." failed to leave the LAN.")
								end
							end
						elseif data[3] == "auth_req" then
							--print("Received message type: "..data[3])
							if (#lan_key ~= 0) then
								local challenge = {}
								for i=1, 16 do
									challenge[i] = math.random(0, 255)
								end
								local enc_challenge = AES.encrypt_block(challenge, lan_key)
								lan_auth[sender] = {challenge, enc_challenge, false}
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_challenge", sender, challenge} ))
							else
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_fail", sender, 1} ))
								lan_auth[sender] = nil
							end
						elseif data[3] == "auth_response" then
							--print("Got authentication response from "..sender)
							if (#lan_key ~= 0) then
								local response = data[5]
								if lan_auth[sender] and (not lan_auth[sender][3]) then
									local auth_ok = true
									for i=1, #lan_auth[sender][2] do
										if lan_auth[sender][2][i] ~= response[i] then
											auth_ok = false
											break
										end
									end
									if auth_ok then
										modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_good", sender} ))
										lan_auth[sender][3] = true
									else
										modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_fail", sender, 3} ))
										lan_auth[sender] = nil
									end
								else
									modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_fail", sender, 2} ))
									lan_auth[sender] = nil
								end
							else
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_fail", sender, 1} ))
								lan_auth[sender] = nil
							end
						elseif data[3] == "join_group" then
							local group = data[5]
							if (group <= 1) or ((lan_multicast[group] ~= nil) and (lan_multicast[group][data[2]] ~= nil)) then
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "group_fail", sender} ))
							else
								if not lan_multicast[group] then
									lan_multicast[group] = {}
								end
								lan_multicast[group][data[2]] = true
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "group_ack", sender} ))
							end
						elseif data[3] == "leave_group" then
							local group = data[5]
							if (group <= 1) or ((lan_multicast[group] == nil) or (lan_multicast[group][data[2]] == nil)) then
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "group_fail", sender} ))
							else
								lan_multicast[group][data[2]] = nil
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "group_ack", sender} ))
								local count = 0
								for i,v in pairs(lan_multicast[group]) do
									count = count+1
								end
								if count == 0 then
									lan_multicast[group] = nil
								end
							end
						elseif data[3] == "data" then
							handle_datagram(side, data, data[5], data[6])
						elseif data[3] == "encrypted_data" then -- encrypted data packet
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
                                    --print(side)
									handle_datagram(side, {data[1], data[2], "encrypted_data", data[4]}, dec_packet[1], dec_packet[2])
								end
							end
						elseif data[3] == "auth_required" then
							if (#lan_key == 0) then
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_not_required", sender} ))
							else
								modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "auth_required", sender} ))
							end
						elseif data[3] == "id_list" then
							local list = {}
							for i,v in pairs(allHosts) do
								table.insert(list, i)
							end
							modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "id_list", sender, list} ))
							if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
								print("LAN: WAN ID list has been requested by "..sender..".")
							end
						elseif data[3] == "lan_list" then
							local list = {}
							for i,v in pairs(lan_clients) do
								table.insert(list, i)
							end
							modem[side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "lan_list", sender, list} ))
							if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
								print("LAN: LAN ID list has been requested by "..sender..".")
							end
						end
					end
				end
			end
		elseif event == "timer" then
			if side == pingTimer then
				for i,v in pairs(localHosts) do
					lastHostlist[i] = v
				end
				
				if (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
					print("Running reachability protocol...")
				end
				
				local pingStr = textutils.serialize( {crf_identStr, os.computerID(), "ping", lan_multicast, wan_key_ident} )
				
				localHosts = {}
				if wirelessModem.transmit then
					wirelessModem.transmit(crf_freq, crf_freq, pingStr)
				end
				for i=1, #wiredModems do
					wiredModems[i].transmit(crf_freq, crf_freq, pingStr)
				end
				for i,v in pairs(lan_clients) do
					localHosts[i] = v
				end
			elseif side == lsaCheckTimer then
				if (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
					print("Checking local hostlist...")
				end
				local tLSA = false
				for i,v in pairs(lastHostlist) do
					if not localHosts[i] then -- A host got dropped
						tLSA = true
					end
				end
				for i,v in pairs(localHosts) do
					if not lastHostlist[i] then -- A host got added
						tLSA = true
					end
				end
				if tLSA then
					if (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["lsaEvents"]) > 0 or bit.band(debug, debugFlags["events"]) > 0)) then
						print("Transmitting LSA...")
					end
					transmitLSA(debug)
				elseif (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["lsaEvents"]) > 0 or bit.band(debug, debugFlags["events"]) > 0)) then
					print("Not transmitting LSA...")
				end
                pingTime = math.random(1, 20)
				lsaCheckTime = pingTime+1
                pingTimer = os.startTimer(pingTime)
				lsaCheckTimer = os.startTimer(lsaCheckTime)
                if (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
					print("Forcing LSA transmit...")
					print("New timers:")
					print("Ping: t+"..pingTime.." seconds")
					print("LSACheck: t+"..lsaCheckTime.." seconds")
                end
			elseif side == lsaForceTimer then
				pingTime = math.random(1, 10)
				lsaCheckTime = pingTime+1
				--lsaForceTime = lsaCheckTime+math.random(1,10)
				pingTimer = os.startTimer(pingTime)
				lsaCheckTimer = os.startTimer(lsaCheckTime)
				--lsaForceTimer = os.startTimer(lsaForceTime)
				if (type(debug) == "number") and ((bit.band(debug, debugFlags["timing"]) > 0) or (bit.band(debug, debugFlags["lsaEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
					print("Forcing LSA transmit...")
					print("New timers:")
					print("Ping: t+"..pingTime.." seconds")
					print("LSACheck: t+"..lsaCheckTime.." seconds")
					--print("LSAForce: t+"..lsaForceTime.." seconds")
				end
				transmitLSA(debug)
			elseif side == LANBeaconTimer then
				for i,v in pairs(modem) do
					v.transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "beacon", -1, lan_name, (#lan_key ~= 0)} ))
				end
				LANBeaconTimer = os.startTimer(15)
				if (type(debug) == "number") and ((bit.band(debug, debugFlags["LANEvents"]) > 0) or (bit.band(debug, debugFlags["events"]) > 0)) then
					print("LAN: Sending beacon message...")
				end
			end
		end
	end
end

LAN.get_clients = function()
	local clients = {}
	for i,v in pairs(lan_clients) do
		table.insert(clients, i)
	end
	return clients
end

LAN.send = function(id, data)
	modem[lan_clients[id]].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", id, os.computerID(), data } ))
end

LAN.broadcast = function(data)
	for client_id, client_side in pairs(lan_clients) do
		modem[client_side].transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "data", client_id, os.computerID(), data } ))
	end
end

CRF.run = function(debug)
	if debug == true then
		debug = 0xFF
	end
	if debug == nil then
		debug = 0
	end
	if ((type(debug) == "number") and (debug ~= 0)) then
		term.setCursorPos(1,1)
		term.clear()
	end
	return function() crf_listenerLoop(debug) end
end

CRF.compileDebugFlags = function(ev, tm, rg, sr, de, pe, le, lan)
	local flags = 0
	if ev then
		flags = bit.bor( flags, debugFlags["events"] )
	end
	if tm then
		flags = bit.bor( flags, debugFlags["timing"] )
	end
	if rg then
		flags = bit.bor( flags, debugFlags["routeGen"] )
	end
	if sr then
		flags = bit.bor( flags, debugFlags["bfs"] )
	end
	if de then
		flags = bit.bor( flags, debugFlags["dataEvents"] )
	end
	if pe then
		flags = bit.bor( flags, debugFlags["pingEvents"] )
	end
	if le then
		flags = bit.bor( flags, debugFlags["lsaEvents"] )
	end
	if lan then
		flags = bit.bor( flags, debugFlags["LANEvents"] )
	end
	return flags
end

CRF.getRoutingTable = function()
	local copy = {}
	for i,v in pairs(routingTable) do
		copy[i] = v
	end
	return copy
end

CRF.getRoute = function(to)
	return bfs( CRF.getRoutingTable(), os.computerID(), to )
end

CRF.send = function(to, msg)
	if lan_clients[to] then
		return LAN.send(to, msg)
	end
	if not routingTable[to][1] then
		error("Could not find route for "..to)
		return false
	end
	local m = peripheral.wrap( routingTable[to][1] )
	return m.transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "data", os.computerID(), to, msg, routingTable[to][2] } ))
end

CRF.getStatus = function()
	return crf_running
end

CRF.setWANKey = function(key)
	assert((type(key) == "string"), "setWANKey: key must be type string.")
	assert(securityEnabled, "setWANKey: Security functions were disabled!")
	local _, k = SHA2.digestStr(key)
	wan_key = SHA2.hashToBytes(k)
	k = SHA2.digest(wan_key)
	local wan_key_hash = SHA2.hashToBytes(k)
	wan_key_ident = ""
	for i=1, #wan_key_hash do
		wan_key_ident = wan_key_ident..string.format("%X", wan_key_hash[i])
	end
	for i,v in pairs(modem) do
		v.transmit(crf_freq, crf_freq, textutils.serialize( { crf_identStr, os.computerID(), "rekey", wan_key_ident, -1} ))
	end
end

CRF.setHMACVerifyStatus = function(inbound, outbound)
	wan_verify_inbound = inbound
	wan_verify_outbound = outbound
end

LAN.getStatus = function()
	return lan_running
end

LAN.isSecure = function()
	return (#lan_key ~= 0)
end

LAN.setNetworkName = function(name)
	lan_name = name
end

LAN.setNetworkKey = function(key)
	assert((type(key) == "string"), "setNetworkKey: key must be type string.")
	assert(securityEnabled, "setNetworkKey: Security functions were disabled!")
	local _, k = SHA2.digestStr(key)
	lan_key = SHA2.hashToBytes(k)
	for i,v in pairs(modem) do
		v.transmit(lan_freq, lan_freq, textutils.serialize( { lan_identStr, os.computerID(), "rekey", -1} ))
	end
end

LAN.getNetworkName = function()
	return lan_name
end

-- Detect if we're being run as a program:
if shell then
	local file = fs.open(shell.getRunningProgram(), "r")
	if file then
		local l = file.readLine()
		file.close()
		if string.match(l, "Common Routing Framework") then
			local do_debug = false
			if #args > 0 then
				if (args[1] and (args[1] ~= "")) then
					LAN.setNetworkName(args[1])
				end
				if args[2] then
					LAN.setNetworkKey(args[2])
				end
			else
				term.clear()
				term.setCursorPos(1,1)
				-- (16, 2): Title ("CRFv3.1 LAN Setup")
				-- (5, 5): Thank You message ("Thank you for using CRFv3.1.")
				-- (5, 7): Question ("Would you like to set up a LAN?", len:37)
				--	(43, 7): Yes/No: ("[Yes]/No" or "Yes/[No]")
				--	(50/51, 7): "No" select, state 1
				--	(43-45, 7): "Yes" select, state 2
				-- (2, 9): Textbox ("Name >")
				-- (2, 10): Textbox ("Network Key >")
				-- (2, 11): Textbox ("WAN Key >")
				-- (2, 12): Message ("All fields can be blank.")
				-- (2, 13): Button ("[Debug Disabled]" / "[Debug Enabled]")
				-- (20, 16): Button ("[Continue]")
				
				local selected_box = 0

				local name_box = ""
				local key_box = ""
				local wan_key_box = ""

				-- Inital draw:
				term.setCursorPos(16, 2)
				term.setTextColor(colors.lime)
				term.write("CRFv3.1 LAN Setup")
				term.setTextColor(colors.white)
				term.setCursorPos(5, 5)
				term.write("Thank you for using CRFv3.1.")
				term.setCursorPos(5, 7)
				term.write("Please set up your router:")
				term.setCursorPos(2, 9)
				term.write("Name >")
				term.setCursorPos(2, 10)
				term.write("Network Key >")
				term.setCursorPos(2, 11)
				term.write("WAN Key >")
				term.setCursorPos(2, 12)
				term.write("All fields can be blank.")
				term.setCursorPos(2, 13)
				term.setTextColor(colors.red)
				term.write("[Debug Disabled]")
				term.setTextColor(colors.white)
				term.setCursorPos(20, 16)
				term.write("[Continue]")

				while true do
					local event, a1, a2, a3 = os.pullEvent()
					if (event == "char") then
						if selected_box == 1 then
							name_box = name_box..a1
						elseif selected_box == 2 then
							key_box = key_box..a1
						elseif selected_box == 3 then
							wan_key_box = wan_key_box..a1
						end
					elseif (event == "key") and (a1 == keys.backspace) then
						if selected_box == 1 then
							name_box = string.sub(name_box, 1, #name_box-1)
						elseif selected_box == 2 then
							key_box = string.sub(key_box, 1, #key_box-1)
						elseif selected_box == 3 then
							wan_key_box = string.sub(wan_key_box, 1, #wan_key_box-1)
						end
					elseif event == "mouse_click" then
						if a1 == 1 then
							if (a3 == 9) and (a2 >= 2) then
								selected_box = 1
							elseif (a3 == 10) and (a2 >= 2) then
								selected_box = 2
							elseif (a3 == 11) and (a2 >= 2) then
								selected_box = 3
							elseif (a3 == 16) and ((a2 >= 20) and (a2 <= 29)) then
								break
							elseif (not do_debug) and ((a3 == 13) and ((a2 >= 2) and (a2 <= 17))) then
								do_debug = true
							elseif (do_debug) and ((a3 == 13) and ((a2 >= 2) and (a2 <= 16))) then
								do_debug = false
							end
						end
					end
					term.setCursorBlink(false)
					term.clear()
					term.setCursorPos(16, 2)
					term.setTextColor(colors.lime)
					term.write("CRFv3.1 LAN Setup")
					term.setTextColor(colors.white)
					term.setCursorPos(5, 5)
					term.write("Thank you for using CRFv3.1.")
					term.setCursorPos(5, 7)
					term.write("Please set up your router:")
					term.setCursorPos(2, 9)
					if selected_box == 1 then
						term.setTextColor(colors.lime)
					end
					term.write("Name >")
					term.setTextColor(colors.white)
					term.write(name_box)
					if selected_box == 2 then
						term.setTextColor(colors.lime)
					end
					term.setCursorPos(2, 10)
					term.write("Network Key >")
					term.setTextColor(colors.white)
					term.write(key_box)
					term.setCursorPos(2, 11)
					if selected_box == 3 then
						term.setTextColor(colors.lime)
					end
					term.write("WAN Key >")
					term.setTextColor(colors.white)
					term.write(wan_key_box)
					term.setCursorPos(2, 12)
					term.write("All fields can be blank.")
					term.setCursorPos(2, 13)
					if do_debug then
						term.setTextColor(colors.lime)
						term.write("[Debug Enabled]")
					else
						term.setTextColor(colors.red)
						term.write("[Debug Disabled]")
					end
					term.setTextColor(colors.white)
					term.setCursorPos(20, 16)
					term.write("[Continue]")
					if selected_box == 1 then
						term.setCursorPos(2+#"Name >"+#name_box, 9)
					elseif selected_box == 2 then
						term.setCursorPos(2+#"Network Key >"+#key_box, 10)
					elseif selected_box == 3 then
						term.setCursorPos(2+#"WAN Key >"+#wan_key_box, 11)
					end
					term.setCursorBlink(true)
				end
				if key_box ~= "" then
					LAN.setNetworkKey(key_box)
				end
				if name_box ~= "" then
					LAN.setNetworkName(name_box)
				end
				if wan_key_box ~= "" then
					CRF.setWANKey(wan_key_box)
				end
			end
			-- ev, tm, rg, sr, de, pe, le, lan
			local flags = {}
			for i=3, #args do
				if string.sub(args[i], 1, 1) == "-" then
					flags[string.sub(args[i], 2)] = true
				end
			end
			local combined = CRF.compileDebugFlags(
				flags.ev,
				flags.tm,
				flags.rg,
				flags.sr,
				flags.de,
				flags.pe,
				flags.le,
				flags.lan
			)
			term.clear()
			term.setCursorPos(1,1)
			term.setCursorBlink(false)
			if not do_debug then
				print("Don't worry, the router's running. Sorry, but we can't really have anything else showing due to the way the router works internally.")
				CRF.run(combined)()
			else
				CRF.run(0xFF)()
			end
		end
	end
end
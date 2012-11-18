--[[
Some help links:
http://lua-users.org/lists/lua-l/2008-11/msg00157.html
http://lua-users.org/wiki/StringLibraryTutorial
http://mosquitto.org/man/mqtt-7.html
http://keplerproject.github.com/copas/manual.html#why
]]
require("json")
require("luarocks.require")

function is_openwrt()
  return(os.getenv("USER") == "root")
end

if (not is_openwrt()) then require("luarocks.require") end

local lapp = require("pl.lapp")

local args = lapp [[
json2mqtt - translate JSON to MQTT messages
  MQTT server settings:
  -i,--id   (default json2mqtt)			MQTT client identifier
  -h,--host	(default localhost)		MQTT server ip address
  -p,--port (default 1883)			MQTT server port number
  -d,--debug					Verbose console logging
  JSON source settings:
  -t,--tcpip 			IP JSON source
  -r,--tcpport 		IP JSON port
  -b,--baud			Serial baud rate(not implemented)
  -d,--device		Serial device(not implemented)
]]

require("socket")
client = socket.connect(args.tcpip,args.tcpport)

local MQTT = require("mqtt_library")
local mqtt_client = MQTT.client.create(args.host, args.port)
mqtt_client:connect(args.id)

function recv (connection)
	connection:settimeout(15)
	local s, status, partial = connection:receive('*l')
	return s, status, partial
end

while true do
	local stream, status, p = recv(client)
	if not stream and status == 'timeout' then 
		mqtt_client:handler()
		io.write("."); io.flush()
	elseif p then
		print(p)

	else
		local jtable = json.decode(stream)
		if not jtable then
			print('error')
		end
		local keys = {}
        local vals = {}
        for i, j in pairs(jtable) do
			table.insert(keys, i)
			table.insert(vals, j)
        end

		print("R " ..jtable.nodeid.. " node @ " ..os.date("%X"))

		for i = 1, #keys do
			local topic = "node/"..jtable.nodeid.."/"..keys[i]
			mqtt_client:handler()
			mqtt_client:publish(topic, vals[i])
			socket.sleep(0.1)
		end
	end
end
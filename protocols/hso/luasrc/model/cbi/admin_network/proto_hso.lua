--[[
LuCI - Lua Configuration Interface

Copyright 2015 Stanislas Bertrand <stanislasbertrand@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local map, section, net = ...

local hsoname,hsotype,hsointerface
local ttyCtrl,ttyApp, apn, service, pincode, username, password,roaming,loclog
local ipv6, maxwait, defaultroute, metric, peerdns, dns,
      keepalive_failure, keepalive_interval, demand


ttyCtrl = section:taboption("general", Value, "ttyCtrl", translate("Control interface"))
ttyApp = section:taboption("general", Value, "ttyApp", translate("Application interface"))
ttyGPS = section:taboption("general", Value, "ttyGPS", translate("GPS interface"))
ttyGPSCtrl = section:taboption("general", Value, "ttyGPSCtrl", translate("GPS Control interface"))
ttyCtrl.rmempty = false
ttyApp.rmempty = false
ttyGPS.rmempty = false
ttyGPSCtrl.rmempty = false

ttyGPS.default=""
ttyGPSCtrl.default=""

local tty_suggestions = nixio.fs.glob("/dev/ttyHS*")
	or nixio.fs.glob("/dev/tts/*")

if tty_suggestions then
	local node
	for node in tty_suggestions do
		hsoname = string.gsub(node,"/dev/","")
		hsotype = nixio.fs.readfile("/sys/class/tty/" .. hsoname .. "/hsotype")
		ttyCtrl:value(node, hsotype .. " (" .. node ..")" )
		ttyApp:value(node, hsotype .. " (" .. node ..")" )
		if string.find(hsotype,"Application") ~= nil then
			ttyApp.default = node
		end
		if string.find(hsotype,"Control") ~= nil then
                        ttyCtrl.default = node
		end
		if string.find(hsotype,"GPS") ~= nil then
			ttyGPS.default = node
		end
		if string.find(hsotype,"GPS Control") ~= nil then
			ttyGPSCtrl.default = node
		end
	end
end


service = section:taboption("general", Value, "service", translate("Service Type"))
service.default = "umts"
service:value("umts", "UMTS/GPRS")
service:value("umts_only", translate("UMTS only"))
service:value("gprs_only", translate("GPRS only"))


apn = section:taboption("general", Value, "apn", translate("APN"))


pincode = section:taboption("general", Value, "pincode", translate("PIN"))


username = section:taboption("general", Value, "username", translate("PAP/CHAP username"))


password = section:taboption("general", Value, "password", translate("PAP/CHAP password"))
password.password = true

roaming = section:taboption("general", Flag, "roaming", translate("Roaming"))
loclog = section:taboption("general", Value, "loclog", translate("Cell Log"),
	 translate("File to log the cell tower information, can get quite large, unmonitored"))


if luci.model.network:has_ipv6() then

	ipv6 = section:taboption("advanced", Flag, "ipv6",
		translate("Enable IPv6 negotiation on the PPP link"))

	ipv6.default = ipv6.disabled

end


maxwait = section:taboption("advanced", Value, "maxwait",
	translate("Modem init timeout"),
	translate("Maximum amount of seconds to wait for the modem to become ready"))

maxwait.placeholder = "20"
maxwait.datatype    = "min(1)"


defaultroute = section:taboption("advanced", Flag, "defaultroute",
	translate("Use default gateway"),
	translate("If unchecked, no default route is configured"))

defaultroute.default = defaultroute.enabled


metric = section:taboption("advanced", Value, "metric",
	translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"
metric:depends("defaultroute", defaultroute.enabled)


peerdns = section:taboption("advanced", Flag, "peerdns",
	translate("Use DNS servers advertised by peer"),
	translate("If unchecked, the advertised DNS server addresses are ignored"))

peerdns.default = peerdns.enabled


dns = section:taboption("advanced", DynamicList, "dns",
	translate("Use custom DNS servers"))

dns:depends("peerdns", "")
dns.datatype = "ipaddr"
dns.cast     = "string"


keepalive_failure = section:taboption("advanced", Value, "_keepalive_failure",
	translate("LCP echo failure threshold"),
	translate("Presume peer to be dead after given amount of LCP echo failures, use 0 to ignore failures"))

function keepalive_failure.cfgvalue(self, section)
	local v = m:get(section, "keepalive")
	if v and #v > 0 then
		return tonumber(v:match("^(%d+)[ ,]+%d+") or v)
	end
end

function keepalive_failure.write() end
function keepalive_failure.remove() end

keepalive_failure.placeholder = "0"
keepalive_failure.datatype    = "uinteger"


keepalive_interval = section:taboption("advanced", Value, "_keepalive_interval",
	translate("LCP echo interval"),
	translate("Send LCP echo requests at the given interval in seconds, only effective in conjunction with failure threshold"))

function keepalive_interval.cfgvalue(self, section)
	local v = m:get(section, "keepalive")
	if v and #v > 0 then
		return tonumber(v:match("^%d+[ ,]+(%d+)"))
	end
end

function keepalive_interval.write(self, section, value)
	local f = tonumber(keepalive_failure:formvalue(section)) or 0
	local i = tonumber(value) or 5
	if i < 1 then i = 1 end
	if f > 0 then
		m:set(section, "keepalive", "%d %d" %{ f, i })
	else
		m:del(section, "keepalive")
	end
end

keepalive_interval.remove      = keepalive_interval.write
keepalive_interval.placeholder = "5"
keepalive_interval.datatype    = "min(1)"


demand = section:taboption("advanced", Value, "demand",
	translate("Inactivity timeout"),
	translate("Close inactive connection after the given amount of seconds, use 0 to persist connection"))

demand.placeholder = "0"
demand.datatype    = "uinteger"

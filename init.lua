-- Relay and GPIO config
pin = 1
gpio.mode(pin, gpio.OUTPUT)

MS = 1000 -- us to ms
local function activate_door()
   gpio.write(pin, gpio.HIGH);
   tmr.delay(500 * MS)
   gpio.write(pin, gpio.LOW);
   tmr.delay(500 * MS)
end

-- WiFi and server config
wifi.setmode(wifi.SOFTAP)
wifi.setphymode(wifi.PHYMODE_B)

ap_cfg={}
ap_cfg.ssid="Abreme la puerta"
ap_cfg.pwd="holahola"
ap_cfg.auth=wifi.WPA_WPA2_PSK
ap_cfg.save=true           -- saves config to flash
wifi.ap.config(ap_cfg)

ip_cfg =
{
    ip="192.168.1.1",
    netmask="255.255.255.0",
    gateway="192.168.1.1"
}
wifi.ap.setip(ip_cfg)


dhcp_config ={}
dhcp_config.start = "192.168.1.100"
wifi.ap.dhcp.config(dhcp_config)
wifi.ap.dhcp.start()

-- DEBUG: The following prints 5 if the module is connected and has an IP assigned.
-- print(wifi.sta.status())

-- Use the nodemcu specific pool servers and keep the time synced
-- forever (this has the autorepeat flag set).
-- sntp.sync(nil, nil, nil, 1)


local function handler(c, request)
   -- Get HTTP method, path and request arguments
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   if (method == nil) then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
   end

   majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
   nodemcu_info = majorVer.."."..minorVer.."."..devVer
   host = wifi.sta.gethostname()
--   tm = rtctime.epoch2cal(rtctime.get())
--    tm = string.format("%02d/%02d/%04d at %02d:%02d",
--                       tm["day"], tm["mon"], tm["year"], tm["hour"], tm["min"])
   cpu_freq = node.getcpufreq()
   ip = wifi.ap.getip()
   mac = wifi.ap.getmac()
   hash = crypto.toHex(crypto.fhash("sha1", "init.lua"))

   local homepage = [[
<!DOCTYPE HTML>
<html>
   <head>
      <meta content="text/html; charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Garage</title>
      <style type="text/css">
       html, body {
         min-height: 100%;
       }
       body {
         font-family: Arial;
         background-color: #e9e9e9;
         background-size: cover;
         margin: 0;
         padding: 10px;
       }
       .btn {
         display: inline-block;
         text-shadow: 0 1px 0 rgba(0,0,0,0.5);
         color: #FFF;
         background-color: #699DB6;
         text-transform: uppercase;
         letter-spacing: 2px;
         font-size: 1.2em;
         padding: 1em 2em;
         border-radius: 5px;
         border: 1px solid rgba(0,0,0,0.3);
         border-color: rgba(0,0,0,0.3);
       }
      </style>
   </head>
   <body>
      <pre>NodeMCU: &#9;]]..nodemcu_info..[[</pre>
      <pre>Hostname: &#9;]]..host..[[</pre>
      <pre>CPU Freq.: &#9;]]..cpu_freq..[[ MHz</pre>
      <pre>IP addr.: &#9;]]..ip..[[</pre>
      <pre>MAC addr.: &#9;]]..mac..[[</pre>
      <pre>SHA1 of init.lua (running script):</pre>
      <pre>]]..hash..[[</pre>
      <hr>
      <button class="btn" type="button" onclick="activate_door()">Activate</button>
      <script>
       function activate_door() {
         var xhr = new XMLHttpRequest();
         xhr.open("POST", "/", true);
         xhr.send();
       }
      </script>
   </body>
</html>
]]

   -- Decide what to do based on the method. Any POST will trigger the
   -- door. Any GET will send the homepage
   if (method == "POST") then
      activate_door()
   else
      c:send(homepage)
   end
end


local s = net.createServer(net.TCP)
s:listen(80, function(connection)
            connection:on("receive", handler)
            connection:on("sent", function(c) c:close() end) end)

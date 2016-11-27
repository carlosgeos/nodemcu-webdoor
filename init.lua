-- setup relay
pin = 1
gpio.mode(pin,gpio.OUTPUT)

MS = 1000 -- us to ms
function open_door()
    gpio.write(pin, gpio.HIGH);
    tmr.delay(500 * MS)
    gpio.write(pin, gpio.LOW);
    tmr.delay(500 * MS)
end

srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end
        buf = buf..[[
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            a { text-decoration: none; margin: 60px 30px; }

            a.btn {
                display: inline-block;
                color: #666;
                background-color: #eee;
                text-transform: uppercase;
                letter-spacing: 2px;
                font-size: 26px;
                padding: 30px 60px;
                border-radius: 5px;
                -moz-border-radius: 5px;
                -webkit-border-radius: 5px;
                border: 1px solid rgba(0,0,0,0.3);
            }

            /* blue button */
            a.btn.btn-blue {
                background-color: #699DB6;
                border-color: rgba(0,0,0,0.3);
                text-shadow: 0 1px 0 rgba(0,0,0,0.5);
                color: #FFF;
            }
        </style>
        </head>
        ]]
        buf = buf.."<a class='btn btn-blue' href=\"?pin=ON1\">Abrir</a>&nbsp;";
        local _on,_off = "",""
        if(_GET.pin == "ON1")then
              open_door()
        end
        client:send(buf);
        client:close();
        collectgarbage();
    end)
end)
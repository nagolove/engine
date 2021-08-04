

--[[
function attach(name)
    if type(name) == "string" then
        attachedvarslist[name] = function()
            local ok, errmsg = pcall(function()
                local v = _g[name]
                if v then
                    linesbuf:pushi("%s", inspect(v))
                end
                if not ok then
                    print("attach not work.", errmsg)
                end
            end)
        end
    end
end
--]]

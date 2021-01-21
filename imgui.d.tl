global type Imgui = record
    Begin: function(string, boolean, string)
    Text: function(string)
    Button: function(string, string|nil)
    End: function()
end

return Imgui

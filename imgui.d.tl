global type Imgui = record
    NewFrame: function()
    Render: function()
    Begin: function(string, boolean, string)
    Text: function(string)
    Button: function(string, string|nil)
    LabelText: function(string|number, string)
    End: function()
end

return Imgui

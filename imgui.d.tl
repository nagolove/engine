global type Imgui = record
    NewFrame: function()
    Render: function()
    Begin: function(string, boolean, string)
    Text: function(string)
    Button: function(string, string|nil)
    LabelText: function(string|number, string)
    End: function()
    ShutDown: function
    TextInput: function(string)
    GetWantCaptureKeyboard: function
    KeyPressed: function(string)
    Checkbox: function(string, boolean): boolean
    SliderFloat: function(label: string, v: number, min: number, max: number, display_format: string): number, boolean
end

return Imgui

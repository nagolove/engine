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
    SliderInt: function(string, number, number, number): number, boolean

    -- return values number??
    ListBox: function(label: string, current: number, items: {string}, items_count: number, height_in_items: number|nil): number, boolean
    -- return values number??
    Selectable: function(label: string, selected: boolean| nil, flags: string|nil): number, boolean
    -- return values number??
    BeginCombo: function(label: string, preview_value: string, flags: string| nil): number, boolean

    EndCombo: function()

    -- return values number??
    Combo: function(label: string, current_item: number, items: {string}, items_count: number, popup_max_height_in_items: number|nil): number, boolean
    --InputTextMultiline: function(label: string, buf: string, 200, 300, 200)
    InputTextMultiline: function(label: string, buf: string, number, number, number): string, boolean
    SameLine: function()
end

return Imgui

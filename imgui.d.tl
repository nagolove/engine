--[[
Как генерировать биндинг для сложных структур?
Необходима генерация c++ кода обертки по заголовочным файлам.
--]]
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
    ShowDemoWindow: function()
    ShowMetricsWindow: function()
    ShowUserGuide: function()
    Spacing: function()
    --ArrowButton: function(str_id: string, dir: string)
    Bullet: function()
    DragFloat: function(label: string, v: number, v_speed: number, v_min: number, v_max: number, format: number, ImGuiSliderFlags: string): number, boolean
    -- TODO в качестве массива функция должна принимать таблицу
    DragFloat2: function(label: string, v: {number}, v_speed: number, v_min: number, v_max: number, format: number, ImGuiSliderFlags: string): {number}, boolean

    SliderAngle: function(label: string, v_rad: number, v_degrees_min: number, v_degrees_max: number, format: string, ImGuiSliderFlags: string): number, boolean

--bool InputTextWithHint: function(const char* label, const char* hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
--bool InputInt: fun(const char* label, int* v, int step = 1, int step_fast = 100, ImGuiInputTextFlags flags = 0);
--bool InputInt2: fun(const char* label, int v[2], ImGuiInputTextFlags flags = 0);
--bool InputTextWithHint: fun(const char* label, const char* hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
--bool Selectable: fun(const char* label, bool* p_selected, ImGuiSelectableFlags flags = 0, const ImVec2& size = ImVec2(0, 0));      // "bool* p_selected" point to the selection state (read-write), as a convenient helper.
--void Value: fun(const char* prefix, bool b);
--void Value: fun(const char* prefix, int v);
end

return Imgui

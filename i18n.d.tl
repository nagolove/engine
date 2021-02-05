local type i18n = record
    reset: function()
    loadFile: function(path: string)
    load: function(data: any)
    getLocale: function(): string
    getFallbackLocale: function(): string
    setFallbackLocale: function(string)
    translate: function(key: string, data: any): string
    set: function(key: string, value: string)
    metamethod __call: function(i18n, string, string): string
end
return i18n

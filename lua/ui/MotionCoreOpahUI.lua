-- Motion Core | Opah UI
-- Independently implemented UI, designed to resemble the requested screenshot.
-- Public UI-only module; no game automation logic and no dependency on outside hubs.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Theme = {
    Glass = Color3.fromRGB(31, 34, 57),
    Card = Color3.fromRGB(29, 31, 48),
    White = Color3.fromRGB(250, 251, 255),
    Muted = Color3.fromRGB(225, 229, 246),
    Line = Color3.fromRGB(116, 120, 160),
    Green = Color3.fromRGB(60, 255, 60),
}
local UI = {}
local function new(class, parent, props)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end
local function corner(obj, n)
    new("UICorner", obj, {CornerRadius = UDim.new(0, n)})
end
local function border(obj, color, transparency, thickness)
    return new("UIStroke", obj, {
        Color = color or Theme.Line,
        Transparency = transparency or 0.55,
        Thickness = thickness or 1,
    })
end
local function font(label, size, bold, color)
    label.Font = bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans
    label.TextSize = size or 14
    label.TextColor3 = color or Theme.White
    label.TextStrokeColor3 = Color3.fromRGB(3, 5, 16)
    label.TextStrokeTransparency = 0.36
    label.TextWrapped = true
    return label
end
local function label(parent, text, size, bold, props)
    local o = new("TextLabel", parent, props or {})
    o.BackgroundTransparency = 1
    o.Text = tostring(text or "")
    font(o, size, bold)
    o.TextXAlignment = Enum.TextXAlignment.Left
    o.TextYAlignment = Enum.TextYAlignment.Center
    return o
end
local function button(parent, text, props)
    local o = new("TextButton", parent, props or {})
    o.AutoButtonColor = false
    o.Text = tostring(text or "")
    font(o, 14, true)
    return o
end
local function card(parent, height, tint, transp)
    local f = new("Frame", parent, {
        BackgroundColor3 = tint or Theme.Card,
        BackgroundTransparency = transp or 0.26,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -12, 0, height),
    })
    corner(f, 13)
    border(f, Theme.Line, 0.78)
    return f
end
local function list(parent, gap, padding)
    new("UIListLayout", parent, {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 8),
    })
    if padding then
        new("UIPadding", parent, {
            PaddingTop = UDim.new(0, padding),
            PaddingBottom = UDim.new(0, padding),
            PaddingLeft = UDim.new(0, padding),
            PaddingRight = UDim.new(0, padding),
        })
    end
end
local function pointerDrag(target, handle)
    local active, start, original
    handle.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            active, start, original = input, input.Position, target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not active then return end
        if input == active or
            (active.UserInputType == Enum.UserInputType.MouseButton1 and
            input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - start
            target.Position = UDim2.new(
                original.X.Scale, original.X.Offset + d.X,
                original.Y.Scale, original.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if active == input or (active and
            active.UserInputType == Enum.UserInputType.MouseButton1 and
            input.UserInputType == Enum.UserInputType.MouseButton1) then
            active = nil
        end
    end)
end
local function mount(gui)
    local parent
    if type(gethui) == "function" then
        pcall(function() parent = gethui() end)
    end
    if not parent then
        pcall(function() parent = game:GetService("CoreGui") end)
    end
    if not parent then
        parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    gui.Parent = parent
end
function UI:CreateWindow(cfg)
    cfg = cfg or {}
    local accent = cfg.Accent or Theme.Green
    local old
    pcall(function()
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        old = playerGui and playerGui:FindFirstChild("MotionCoreOpahUI")
    end)
    if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "MotionCoreOpahUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 600
    mount(gui)
    local W, H = cfg.Width or 660, cfg.Height or 440
    local panel = new("Frame", gui, {
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(W,H),
        BackgroundColor3 = Theme.Glass,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    corner(panel, 20)
    border(panel, Color3.fromRGB(138,141,200), 0.58)
    if cfg.Background then
        local bg = new("ImageLabel", panel, {
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Image = cfg.Background,
            ImageTransparency = cfg.BackgroundImageTransparency or 0.7,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 1,
        })
        corner(bg, 20)
    end
    local top = new("Frame", panel, {
        Size = UDim2.new(1,0,0,45),
        BackgroundColor3 = Color3.fromRGB(38,43,76),
        BackgroundTransparency = .22,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    local traffic = {
        {Color3.fromRGB(255,90,86), 16},
        {Color3.fromRGB(255,190,48), 39},
        {Color3.fromRGB(47,214,69), 62}
    }
    for _, t in ipairs(traffic) do
        local dot = new("TextButton", top, {
            Position = UDim2.fromOffset(t[2],15),
            Size = UDim2.fromOffset(14,14),
            BackgroundColor3 = t[1],
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 5,
        })
        corner(dot, 9)
        if t[2] == 16 then
            dot.MouseButton1Click:Connect(function() panel.Visible = false end)
        end
    end
    local icon = new("ImageLabel", top, {
        Position = UDim2.fromOffset(91,8),
        Size = UDim2.fromOffset(28,28),
        BackgroundTransparency = 1,
        Image = cfg.Icon or "",
        ZIndex = 6,
    })
    corner(icon, 14)
    label(top, cfg.Title or "Opah Auto Win", 14, true, {
        Position = UDim2.fromOffset(128,7),
        Size = UDim2.new(1,-145,0,19),
        ZIndex = 6,
    })
    label(top, cfg.SubTitle or "Motion Core", 11, false, {
        Position = UDim2.fromOffset(128,25),
        Size = UDim2.new(1,-145,0,15),
        ZIndex = 6,
    })
    pointerDrag(panel, top)
    local sidebar = new("Frame", panel, {
        Position = UDim2.fromOffset(0,45),
        Size = UDim2.new(0,173,1,-45),
        BackgroundColor3 = Color3.fromRGB(24,25,44),
        BackgroundTransparency = .36,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    local search = new("TextBox", sidebar, {
        Position = UDim2.fromOffset(10,9),
        Size = UDim2.new(1,-20,0,33),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = .18,
        PlaceholderText = "⌕  Cari",
        PlaceholderColor3 = Theme.Muted,
        Text = "",
        ClearTextOnFocus = false,
        ZIndex = 5,
    })
    font(search, 13, false)
    corner(search, 17)
    border(search, Theme.Line, .7)
    new("UIPadding", search, {PaddingLeft = UDim.new(0,12),PaddingRight = UDim.new(0,8)})
    local nav = new("Frame", sidebar, {
        Position = UDim2.fromOffset(10,53),
        Size = UDim2.new(1,-20,1,-126),
        BackgroundTransparency = 1,
        ZIndex = 4,
    })
    list(nav, 6)
    local userArea = new("Frame", sidebar, {
        Position = UDim2.new(0,10,1,-48),
        Size = UDim2.new(1,-20,0,43),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = .38,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    corner(userArea, 10)
    local profile = label(userArea, "◯", 23, false, {
        Position = UDim2.fromOffset(10,4),Size = UDim2.fromOffset(30,33),ZIndex=5
    })
    profile.TextColor3 = accent
    label(userArea, "Anonymous", 10, true, {
        Position = UDim2.fromOffset(43,6), Size = UDim2.new(1,-48,0,15), ZIndex=5
    })
    label(userArea, "@hidden", 10, false, {
        Position = UDim2.fromOffset(43,22), Size = UDim2.new(1,-48,0,13), ZIndex=5
    })
    local pages = new("Frame", panel, {
        Position = UDim2.fromOffset(174,45),
        Size = UDim2.new(1,-174,1,-68),
        BackgroundTransparency = 1,
        ZIndex = 3,
    })
    local foot = label(panel, cfg.Footer or "Motion Core", 10, false, {
        Position=UDim2.new(0,0,1,-25),Size=UDim2.new(1,-15,0,22),
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5
    })
    foot.TextXAlignment = Enum.TextXAlignment.Right
    local dock = new("Frame", gui, {
        AnchorPoint = Vector2.new(.5,0),
        Position = UDim2.new(.5,0,.5,H/2+4),
        Size = UDim2.fromOffset(196,61),
        BackgroundColor3 = Theme.Glass,
        BackgroundTransparency = .18,
        BorderSizePixel = 0,
    })
    corner(dock, 18)
    border(dock, Theme.Line, .5)
    local openBtn = button(dock, "MC", {
        Position=UDim2.fromOffset(9,7),Size=UDim2.fromOffset(47,47),
        BackgroundColor3=Color3.fromRGB(49,36,104),
        BorderSizePixel=0,
    })
    corner(openBtn, 12)
    if cfg.Icon then
        local openIcon=new("ImageLabel",openBtn,{Size=UDim2.fromScale(1,1),
            Image=cfg.Icon,BackgroundTransparency=1})
        corner(openIcon,12)
    end
    openBtn.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
    local window = {Gui=gui, Tabs={}, _page=nil}
    local function openTab(tab)
        for _, entry in ipairs(window.Tabs) do
            local selected = entry == tab
            entry.Page.Visible = selected
            entry.Button.BackgroundTransparency = selected and .55 or 1
            entry.Button.BackgroundColor3 = selected and accent or Theme.Card
            entry.Button.TextColor3 = selected and Theme.White or Theme.Muted
        end
        window._page=tab
        panel.Visible = true
    end
    local function dockTab(text, x, cb)
        local btn = button(dock,text,{Position=UDim2.fromOffset(x,9),
            Size=UDim2.fromOffset(48,43),BackgroundColor3=accent,
            BackgroundTransparency=.25,BorderSizePixel=0})
        corner(btn,11)
        btn.MouseButton1Click:Connect(cb)
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(search.Text)
        for _, tab in ipairs(window.Tabs) do
            tab.Button.Visible = q == "" or string.find(string.lower(tab.Title),q,1,true) ~= nil
        end
    end)
    function window:Toggle()
        panel.Visible=not panel.Visible
    end
    function window:Notify(data)
        data = data or {}
        local toast = new("Frame",gui,{
            AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,-22,0,70),
            Size=UDim2.fromOffset(260,66),
            BackgroundColor3=Color3.fromRGB(30,35,57),
            BackgroundTransparency=.09,
            BorderSizePixel=0,ZIndex=40,
        })
        corner(toast,13)
        border(toast,accent,.3)
        label(toast,data.Title or "Motion Core",13,true,{
            Position=UDim2.fromOffset(13,7),Size=UDim2.new(1,-25,0,20),ZIndex=41,
        })
        label(toast,data.Content or "",12,false,{
            Position=UDim2.fromOffset(13,28),Size=UDim2.new(1,-25,0,31),ZIndex=41,
        })
        task.delay(data.Duration or 4,function() if toast and toast.Parent then toast:Destroy() end end)
    end
    function window:CreateTab(title, iconName)
        local idx=#self.Tabs+1
        local symbol = iconName == "lucide:activity" and "∿" or "▷"
        local b = button(nav, symbol.."   "..tostring(title), {
            Size=UDim2.new(1,0,0,37),BackgroundTransparency=1,
            BackgroundColor3=accent,BorderSizePixel=0,
            LayoutOrder=idx,ZIndex=5,
        })
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.TextSize=14
        new("UIPadding",b,{PaddingLeft=UDim.new(0,14)})
        corner(b,12)
        local scroller = new("ScrollingFrame",pages,{
            Size=UDim2.fromScale(1,1),
            CanvasSize=UDim2.new(),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ScrollBarThickness=3,
            ScrollBarImageColor3=accent,
            BackgroundTransparency=1,
            BorderSizePixel=0,
            Visible=false,
            ZIndex=4,
        })
        list(scroller,10,11)
        local heading=label(scroller,symbol.."  "..tostring(title),17,true,{
            Size=UDim2.new(1,-16,0,35),LayoutOrder=1,ZIndex=5
        })
        heading.TextColor3=Theme.White
        local tab={Title=title,Page=scroller,Button=b,Count=1}
        table.insert(self.Tabs,tab)
        b.MouseButton1Click:Connect(function() openTab(tab) end)
        dockTab(symbol,59+(idx-1)*55,function() openTab(tab) end)
        if idx==1 then openTab(tab) end
        function tab:CreateSection(options)
            options=options or {}
            self.Count=self.Count+1
            local container=new("Frame",scroller,{
                Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=Theme.Card,BackgroundTransparency=.64,
                BorderSizePixel=0,LayoutOrder=self.Count,ZIndex=5,
            })
            corner(container,14)
            border(container,Theme.Line,.78)
            local bar=button(container,"⌘   "..tostring(options.Name or "Section").."    ⌃",{
                Size=UDim2.new(1,0,0,39),BackgroundTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6,
            })
            new("UIPadding",bar,{PaddingLeft=UDim.new(0,15)})
            local contents=new("Frame",container,{
                Position=UDim2.fromOffset(7,41),
                Size=UDim2.new(1,-14,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1,ZIndex=5,
            })
            list(contents,9,4)
            local bottom=new("Frame",container,{Size=UDim2.new(1,0,0,8),
                BackgroundTransparency=1,LayoutOrder=999})
            -- AutoSize uses child bounds; the body is offset below the section header.
            local function resize()
                local height = contents:FindFirstChildOfClass("UIListLayout")
                local h = height and height.AbsoluteContentSize.Y or 0
                contents.Size=UDim2.new(1,-14,0,h+8)
                container.Size=UDim2.new(1,-12,0,49+h+8)
            end
            local layout=contents:FindFirstChildOfClass("UIListLayout")
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
            task.defer(resize)
            local expanded=true
            bar.MouseButton1Click:Connect(function()
                expanded=not expanded
                contents.Visible=expanded
                container.Size=UDim2.new(1,-12,0,expanded and 49+layout.AbsoluteContentSize.Y+8 or 42)
                bar.Text="⌘   "..tostring(options.Name or "Section")..(expanded and "    ⌃" or "    ⌄")
            end)
            local section={Contents=contents,Amount=0}
            local function nextOrder()
                section.Amount=section.Amount+1
                return section.Amount
            end
            function section:Toggle(def)
                def=def or {}
                local f=card(contents,77,nil,.21)
                f.LayoutOrder=nextOrder()
                label(f,def.Title or "Toggle",14,true,{
                    Position=UDim2.fromOffset(46,14),Size=UDim2.new(1,-130,0,22),ZIndex=7
                })
                local desc=label(f,def.Desc or "",12,false,{
                    Position=UDim2.fromOffset(46,37),Size=UDim2.new(1,-124,0,30),ZIndex=7
                })
                desc.TextColor3=Theme.Muted
                label(f,"♧",21,true,{Position=UDim2.fromOffset(13,20),
                    Size=UDim2.fromOffset(29,27),ZIndex=7})
                local enabled=def.Value==true
                local switch=button(f,"",{
                    AnchorPoint=Vector2.new(1,.5),
                    Position=UDim2.new(1,-15,.5,0),
                    Size=UDim2.fromOffset(47,26),BorderSizePixel=0,ZIndex=8
                })
                corner(switch,15)
                local knob=new("Frame",switch,{
                    Size=UDim2.fromOffset(20,20),
                    BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=9
                })
                corner(knob,11)
                local function paint()
                    switch.BackgroundColor3=enabled and accent or Color3.fromRGB(91,94,111)
                    knob.Position=enabled and UDim2.fromOffset(24,3) or UDim2.fromOffset(3,3)
                end
                paint()
                switch.MouseButton1Click:Connect(function()
                    enabled=not enabled
                    paint()
                    if def.Callback then pcall(def.Callback,enabled) end
                end)
                return {Set=function(_,v) enabled=v==true paint() end}
            end
            function section:Slider(def)
                def=def or {}
                local min=def.Value and def.Value.Min or 0
                local max=def.Value and def.Value.Max or 100
                local step=def.Step or 1
                local value=math.clamp(def.Value and def.Value.Default or min,min,max)
                local f=card(contents,91,nil,.21);f.LayoutOrder=nextOrder()
                label(f,def.Title or "Slider",14,true,{
                    Position=UDim2.fromOffset(46,9),Size=UDim2.new(1,-130,0,23),ZIndex=7})
                local desc=label(f,def.Desc or "",12,false,{
                    Position=UDim2.fromOffset(46,31),Size=UDim2.new(1,-124,0,24),ZIndex=7})
                desc.TextColor3=Theme.Muted
                label(f,"◷",22,true,{Position=UDim2.fromOffset(13,13),
                    Size=UDim2.fromOffset(27,28),ZIndex=7})
                local amount=label(f,"",12,true,{Position=UDim2.new(1,-76,0,9),
                    Size=UDim2.fromOffset(65,24),ZIndex=7})
                amount.TextColor3=accent
                amount.TextXAlignment=Enum.TextXAlignment.Right
                local track=new("Frame",f,{Position=UDim2.fromOffset(20,69),
                    Size=UDim2.new(1,-40,0,5),BackgroundColor3=Theme.Line,
                    BorderSizePixel=0,ZIndex=7})
                corner(track,6)
                local fill=new("Frame",track,{Size=UDim2.new(),BackgroundColor3=accent,
                    BorderSizePixel=0,ZIndex=8})
                corner(fill,6)
                local knob=new("Frame",track,{Size=UDim2.fromOffset(18,18),
                    AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Theme.White,
                    BorderSizePixel=0,ZIndex=9})
                corner(knob,10); border(knob,accent,.1,2)
                local hit=button(f,"",{Position=UDim2.fromOffset(12,58),
                    Size=UDim2.new(1,-24,0,28),BackgroundTransparency=1,ZIndex=10})
                local function paint()
                    local fraction=(value-min)/math.max(.001,max-min)
                    fill.Size=UDim2.fromScale(fraction,1)
                    knob.Position=UDim2.fromScale(fraction,.5)
                    amount.Text=string.format("%.1f",value)..tostring(def.Suffix or "")
                end
                local function setFrom(x)
                    local ratio=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
                    value=math.clamp(math.floor((min+ratio*(max-min))/step+.5)*step,min,max)
                    paint()
                    if def.Callback then pcall(def.Callback,value) end
                end
                paint()
                local dragging=false
                hit.InputBegan:Connect(function(input)
                    if input.UserInputType==Enum.UserInputType.MouseButton1 or
                       input.UserInputType==Enum.UserInputType.Touch then
                        dragging=true;setFrom(input.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or
                        input.UserInputType==Enum.UserInputType.Touch) then
                        setFrom(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType==Enum.UserInputType.MouseButton1 or
                        input.UserInputType==Enum.UserInputType.Touch then
                        dragging=false
                    end
                end)
                return {Set=function(_,n) value=math.clamp(tonumber(n) or value,min,max);paint() end}
            end
            function section:Paragraph(def)
                def=def or {}
                local content=tostring(def.Desc or "")
                local f=card(contents,78,Color3.fromRGB(32,94,79),.46)
                f.LayoutOrder=nextOrder()
                local title=label(f,def.Title or "",13,true,{
                    Position=UDim2.fromOffset(46,9),Size=UDim2.new(1,-60,0,23),ZIndex=7})
                label(f,"ⓘ",22,true,{Position=UDim2.fromOffset(14,13),
                    Size=UDim2.fromOffset(28,28),ZIndex=7})
                local description=label(f,content,12,false,{
                    Position=UDim2.fromOffset(46,33),Size=UDim2.new(1,-60,0,39),
                    TextYAlignment=Enum.TextYAlignment.Top,ZIndex=7})
                description.TextColor3=Theme.Muted
                local item={}
                function item:SetDesc(s) description.Text=tostring(s or "") end
                function item:Set(s) description.Text=tostring(s or "") end
                return item
            end
            function section:ProgressBar(def)
                def=def or {}
                local f=card(contents,77,nil,.24);f.LayoutOrder=nextOrder()
                label(f,def.Title or "Progress",13,true,{
                    Position=UDim2.fromOffset(14,9),Size=UDim2.new(1,-30,0,22),ZIndex=7})
                label(f,def.Desc or "",11,false,{
                    Position=UDim2.fromOffset(14,28),Size=UDim2.new(1,-30,0,18),ZIndex=7})
                local track=new("Frame",f,{Position=UDim2.fromOffset(14,57),
                    Size=UDim2.new(1,-28,0,8),BackgroundColor3=Theme.Line,
                    BorderSizePixel=0,ZIndex=7})
                corner(track,6)
                local fill=new("Frame",track,{Size=UDim2.new(),BackgroundColor3=accent,
                    BorderSizePixel=0,ZIndex=8})
                corner(fill,6)
                local item={}
                function item:Set(n)
                    fill.Size=UDim2.fromScale(math.clamp((tonumber(n) or 0)/100,0,1),1)
                end
                item:Set(def.Default or 0)
                return item
            end
            function section:Dropdown(def)
                def=def or {}
                local f=card(contents,94,nil,.24);f.LayoutOrder=nextOrder()
                label(f,def.Title or "Events",13,true,{
                    Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-28,0,22),ZIndex=7})
                local status=label(f,def.Desc or "",11,false,{
                    Position=UDim2.fromOffset(14,29),Size=UDim2.new(1,-28,0,16),ZIndex=7})
                status.TextColor3=Theme.Muted
                local value=label(f,"",11,false,{
                    Position=UDim2.fromOffset(14,49),
                    Size=UDim2.new(1,-28,0,38),ZIndex=7,
                    TextYAlignment=Enum.TextYAlignment.Top
                })
                value.TextColor3=Theme.Muted
                local item={}
                function item:Refresh(items)
                    local entries=type(items)=="table" and items or {"No events yet."}
                    local display={}
                    for index=math.max(1,#entries-2),#entries do
                        if entries[index] then table.insert(display,tostring(entries[index])) end
                    end
                    value.Text=table.concat(display,"\n")
                end
                item:Refresh(def.Values or {"No events yet."})
                return item
            end
            function section:Button(def)
                def=def or {}
                local f=card(contents,53,nil,.24);f.LayoutOrder=nextOrder()
                local action=button(f,"  "..tostring(def.Title or "Action"),{
                    Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=7,
                    TextXAlignment=Enum.TextXAlignment.Left
                })
                new("UIPadding",action,{PaddingLeft=UDim.new(0,12)})
                if def.Callback then
                    action.MouseButton1Click:Connect(function() pcall(def.Callback) end)
                end
                return action
            end
            return section
        end
        return tab
    end
    if cfg.ToggleKey then
        UserInputService.InputBegan:Connect(function(input, consumed)
            if not consumed and input.KeyCode==cfg.ToggleKey then window:Toggle() end
        end)
    end
    return window
end
return UI

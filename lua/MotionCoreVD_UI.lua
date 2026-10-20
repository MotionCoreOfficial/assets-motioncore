local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local UI = {UserProfile = "", Version = "1.1.0"}
local colors = {
    bg = Color3.fromRGB(12, 12, 18),
    panel = Color3.fromRGB(20, 20, 29),
    item = Color3.fromRGB(28, 27, 40),
    border = Color3.fromRGB(47, 43, 63),
    accent = Color3.fromRGB(153, 101, 244),
    text = Color3.fromRGB(237, 233, 248),
    muted = Color3.fromRGB(146, 141, 163)
}
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
    return obj
end
local function stroke(obj)
    make("UIStroke", {Color=colors.border, Thickness=1, Transparency=0.24}, obj)
end
local function text(parent, value, size, bold)
    return make("TextLabel", {
        BackgroundTransparency=1, Text=tostring(value or ""), TextColor3=colors.text,
        TextSize=size or 12, Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        Size=UDim2.new(1,0,0,24)
    }, parent)
end
local function button(parent, name, height)
    local b=make("TextButton", {
        BackgroundColor3=colors.item, AutoButtonColor=false, Text=tostring(name or ""),
        TextColor3=colors.text, Font=Enum.Font.GothamMedium, TextSize=12,
        Size=UDim2.new(1,0,0,height or 30), BorderSizePixel=0
    }, parent)
    round(b,7)
    return b
end
local function layout(parent, gap, pad)
    make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,gap or 6)},parent)
    make("UIPadding",{PaddingTop=UDim.new(0,pad or 0),PaddingBottom=UDim.new(0,pad or 0),PaddingLeft=UDim.new(0,pad or 0),PaddingRight=UDim.new(0,pad or 0)},parent)
end
local function scroll(parent)
    local view=make("ScrollingFrame",{
        BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3,
        ScrollBarImageColor3=colors.accent, AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(), ScrollingDirection=Enum.ScrollingDirection.Y,
        Size=UDim2.fromScale(1,1), ClipsDescendants=true
    },parent)
    layout(view,8,4)
    return view
end
local function safeCall(fn, ...)
    if type(fn)=="function" then pcall(fn,...) end
end
function UI:AddTheme(cfg)
    if cfg and cfg.Accent then colors.accent=cfg.Accent end
end
function UI:CreateMenuIcon(cfg)
    return cfg or {}
end
local function sectionAPI(parent, name, opened, save, load)
    local outer=make("Frame",{
        BackgroundColor3=colors.panel, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y,
        Size=UDim2.new(1,-9,0,0)
    },parent)
    round(outer,9)
    stroke(outer)
    local pad=make("UIPadding",{PaddingBottom=UDim.new(0,8),PaddingTop=UDim.new(0,7),PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9)},outer)
    local stack=make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},outer)
    local head=button(outer, "  "..tostring(name or "Controls").."   ▾",26)
    head.BackgroundColor3=colors.panel
    head.TextColor3=colors.accent
    head.TextXAlignment=Enum.TextXAlignment.Left
    head.Font=Enum.Font.GothamBold
    local body=make("Frame",{
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
        Size=UDim2.new(1,0,0,0), Visible=opened ~= false
    },outer)
    layout(body,5)
    head.MouseButton1Click:Connect(function()
        body.Visible=not body.Visible
    end)
    local api={}
    local function row(name, tall)
        local r=make("Frame",{BackgroundColor3=colors.item,BorderSizePixel=0,
            Size=UDim2.new(1,0,0,tall or 36)},body)
        round(r,6)
        return r
    end
    local function flagValue(c)
        local flag=tostring(c.Flag or c.Name or "")
        local d=load(flag,c.Default)
        return flag,d
    end
    function api:AddSection(cfg)
        self:AddDivider({Text=cfg and cfg.Name or ""})
        return self
    end
    function api:AddDivider(cfg)
        local l=text(body,(cfg and (cfg.Text or cfg.Name)) or "",11,true)
        l.TextColor3=colors.accent
        l.Size=UDim2.new(1,0,0,19)
        return l
    end
    function api:AddLabel(cfg)
        local l=text(body,(cfg and (cfg.Name or cfg.Text)) or "",11)
        l.TextColor3=colors.muted
        l.AutomaticSize=Enum.AutomaticSize.Y
        l.Size=UDim2.new(1,-4,0,22)
        return l
    end
    function api:AddButton(cfg)
        local b=button(body,cfg.Name,32)
        b.MouseButton1Click:Connect(function() safeCall(cfg.Callback) end)
        return b
    end
    function api:AddToggle(cfg)
        local key,state=flagValue(cfg)
        state=state==true
        local r=row(cfg.Name,36)
        local lbl=text(r,cfg.Name,11)
        lbl.Position=UDim2.fromOffset(9,4)
        lbl.Size=UDim2.new(1,-70,1,-8)
        local b=button(r,"",23)
        b.AnchorPoint=Vector2.new(1,0.5)
        b.Position=UDim2.new(1,-8,.5,0)
        b.Size=UDim2.fromOffset(43,23)
        local function draw()
            b.Text=state and "ON" or "OFF"
            b.BackgroundColor3=state and colors.accent or colors.border
        end
        draw()
        b.MouseButton1Click:Connect(function()
            state=not state
            draw()
            save(key,state)
            safeCall(cfg.Callback,state)
        end)
        if state ~= (cfg.Default==true) then task.defer(safeCall,cfg.Callback,state) end
        return {Set=function(_,v) state=v==true;draw();save(key,state);safeCall(cfg.Callback,state) end}
    end
    function api:AddSlider(cfg)
        local lo=tonumber(cfg.Min) or 0
        local hi=tonumber(cfg.Max) or 100
        if hi<=lo then hi=lo+1 end
        local step=tonumber(cfg.Increment) or 1
        local key,value=flagValue(cfg)
        value=math.clamp(tonumber(value) or lo,lo,hi)
        local r=row(cfg.Name,56)
        local lbl=text(r,cfg.Name,11)
        lbl.Position=UDim2.fromOffset(9,4)
        lbl.Size=UDim2.new(1,-68,0,22)
        local number=text(r,"",11,true)
        number.TextXAlignment=Enum.TextXAlignment.Right
        number.Position=UDim2.new(1,-75,0,4)
        number.Size=UDim2.fromOffset(65,22)
        number.TextColor3=colors.accent
        local track=button(r,"",8)
        track.Position=UDim2.new(0,10,1,-16)
        track.Size=UDim2.new(1,-20,0,8)
        track.BackgroundColor3=colors.border
        local fill=make("Frame",{BackgroundColor3=colors.accent,BorderSizePixel=0,Size=UDim2.new()},track)
        round(fill,6)
        local function set(v,fire)
            local steps=math.floor((math.clamp(v,lo,hi)-lo)/step+0.5)
            value=math.clamp(lo+steps*step,lo,hi)
            local str=string.format(step<0.1 and "%.2f" or step<1 and "%.1f" or "%.0f",value)
            number.Text=str
            fill.Size=UDim2.new((value-lo)/(hi-lo),0,1,0)
            if fire then save(key,value);safeCall(cfg.Callback,value) end
        end
        set(value,false)
        local dragging=false
        local function update(x)
            set(lo+(math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1))*(hi-lo),true)
        end
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true;update(inp.Position.X) end
        end)
        local conn=UIS.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then update(inp.Position.X) end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end)
        if value~=(tonumber(cfg.Default) or lo) then task.defer(safeCall,cfg.Callback,value) end
        return {Set=function(_,v) set(tonumber(v) or value,true) end}
    end
    function api:AddDropdown(cfg)
        local values=cfg.Values or {}
        local multi=cfg.Multi==true
        local key,val=flagValue(cfg)
        local selected={}
        if multi then
            if type(val)=="table" then
                for _,item in ipairs(val) do selected[tostring(item)]=true end
            elseif type(val)=="string" and val:sub(1,1)=="[" then
                local ok,arr=pcall(function() return Http:JSONDecode(val) end)
                if ok and type(arr)=="table" then
                    for _,item in ipairs(arr) do selected[tostring(item)]=true end
                end
            end
        else
            if type(val)=="table" then val=val[1] end
            if val==nil then val=values[1] end
        end
        local r=row(cfg.Name,56)
        local lbl=text(r,cfg.Name,11)
        lbl.Position=UDim2.fromOffset(9,3)
        lbl.Size=UDim2.new(1,-15,0,22)
        local b=button(r,"",23)
        b.Position=UDim2.fromOffset(9,27)
        b.Size=UDim2.new(1,-18,0,23)
        b.TextXAlignment=Enum.TextXAlignment.Left
        local options=make("ScrollingFrame",{
            BackgroundColor3=colors.border,BorderSizePixel=0,Position=UDim2.fromOffset(9,54),
            Size=UDim2.new(1,-18,0,0),Visible=false,ScrollBarThickness=2,
            ScrollBarImageColor3=colors.accent,AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.new()
        },r)
        round(options,5);layout(options,3,3)
        local function selection()
            if not multi then return val end
            local result={}
            for _,v in ipairs(values) do
                if selected[tostring(v)] then table.insert(result,v) end
            end
            return result
        end
        local function display()
            if multi then
                local list=selection()
                b.Text="  "..(#list>0 and table.concat(list,", ") or "None").."  ▾"
            else
                b.Text="  "..tostring(val or "Select").."  ▾"
            end
        end
        local function persist()
            local current=selection()
            if multi then
                save(key,Http:JSONEncode(current))
            else
                save(key,current)
            end
            safeCall(cfg.Callback,current)
        end
        local function show(open)
            options.Visible=open
            local h=math.min(#values,5)*29+6
            options.Size=UDim2.new(1,-18,0,open and h or 0)
            r.Size=UDim2.new(1,0,0,open and 56+h or 56)
        end
        local function render()
            for _,child in ipairs(options:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for _,option in ipairs(values) do
                local opt=button(options,"",26)
                local key2=tostring(option)
                local function setLabel()
                    opt.Text=(multi and (selected[key2] and "  ✓  " or "  ○  ") or "  ")..key2
                end
                setLabel()
                opt.MouseButton1Click:Connect(function()
                    if multi then
                        selected[key2]=not selected[key2]
                        setLabel()
                    else
                        val=option
                        show(false)
                    end
                    display();persist()
                end)
            end
        end
        display();render()
        b.MouseButton1Click:Connect(function()
            if #values==0 then return end
            if not options.Visible then render() end
            show(not options.Visible)
        end)
        if multi then
            if #selection()>0 then task.defer(safeCall,cfg.Callback,selection()) end
        elseif val~=cfg.Default then
            task.defer(safeCall,cfg.Callback,val)
        end
        return {
            SetValues=function(_,arr)
                values=arr or {}
                if not multi and not table.find(values,val) then val=values[1] end
                display();render();show(false)
            end,
            Set=function(_,v)
                if multi then
                    selected={}
                    if type(v)=="table" then for _,item in ipairs(v) do selected[tostring(item)]=true end end
                else
                    val=v
                end
                display();render();persist()
            end
        }
    end
    function api:AddTextInput(cfg)
        local key,v=flagValue(cfg)
        local r=row(cfg.Name,57)
        local l=text(r,cfg.Name,11)
        l.Position=UDim2.fromOffset(9,2)
        l.Size=UDim2.new(1,-18,0,23)
        local inp=make("TextBox",{
            Text=tostring(v or ""),PlaceholderText=cfg.Placeholder or "Enter value",
            BackgroundColor3=colors.border,TextColor3=colors.text,PlaceholderColor3=colors.muted,
            TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,BorderSizePixel=0,
            Position=UDim2.fromOffset(9,27),Size=UDim2.new(1,-18,0,24)
        },r)
        round(inp,5)
        inp.FocusLost:Connect(function()
            if cfg.Numeric and tonumber(inp.Text)==nil then return end
            save(key,inp.Text)
            safeCall(cfg.Callback,inp.Text)
        end)
        return {Set=function(_,s) inp.Text=tostring(s) end}
    end
    function api:AddColorPicker(cfg)
        local palette={
            Color3.fromRGB(153,101,244),Color3.fromRGB(255,92,118),
            Color3.fromRGB(75,176,255),Color3.fromRGB(73,220,159),
            Color3.fromRGB(255,198,85),Color3.fromRGB(244,244,249)
        }
        local cur=cfg.Default or palette[1]
        local r=row(cfg.Name,36)
        local l=text(r,cfg.Name,11)
        l.Position=UDim2.fromOffset(9,5)
        l.Size=UDim2.new(1,-58,0,25)
        local b=button(r,"",24)
        b.Position=UDim2.new(1,-40,0,6)
        b.Size=UDim2.fromOffset(31,24)
        b.BackgroundColor3=cur
        b.MouseButton1Click:Connect(function()
            local idx=table.find(palette,cur) or 0
            cur=palette[idx%#palette+1]
            b.BackgroundColor3=cur
            safeCall(cfg.Callback,cur)
        end)
        return {Set=function(_,color) cur=color;b.BackgroundColor3=color;safeCall(cfg.Callback,color) end}
    end
    function api:AddKeybind(cfg)
        local key=cfg.Default or Enum.KeyCode.RightShift
        if typeof(key)=="string" then key=Enum.KeyCode[key] or Enum.KeyCode.RightShift end
        local mode=cfg.Mode or "Toggle"
        local r=row(cfg.Name,37)
        local l=text(r,cfg.Name,11)
        l.Position=UDim2.fromOffset(9,5)
        l.Size=UDim2.new(1,-119,0,28)
        local b=button(r,key.Name,25)
        b.Position=UDim2.new(1,-106,0,6)
        b.Size=UDim2.fromOffset(97,25)
        local capture=false
        b.MouseButton1Click:Connect(function() capture=true;b.Text="Press key..." end)
        UIS.InputBegan:Connect(function(inp,processed)
            if capture and inp.KeyCode~=Enum.KeyCode.Unknown then
                capture=false;key=inp.KeyCode;b.Text=key.Name;return
            end
            if not processed and not UIS:GetFocusedTextBox() and inp.KeyCode==key then safeCall(cfg.Callback,true) end
        end)
        if mode=="Hold" then
            UIS.InputEnded:Connect(function(inp)
                if inp.KeyCode==key then safeCall(cfg.Callback,false) end
            end)
        end
        return {Set=function(_,v) key=v;b.Text=key.Name end}
    end
    return api
end
function UI:Window(cfg)
    local existing=(getgenv and getgenv().MC_VD_UI_Drop) or nil
    if type(existing)=="function" then pcall(existing) end
    local parent=player:WaitForChild("PlayerGui")
    pcall(function() if gethui then parent=gethui() else parent=game:GetService("CoreGui") end end)
    local sg=make("ScreenGui",{Name="MotionCoreVD",ResetOnSpawn=false,IgnoreGuiInset=true,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=9000},parent)
    local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(420,700)
    local mobile=UIS.TouchEnabled and not UIS.KeyboardEnabled
    local w=math.max(300,math.min(vp.X-14,mobile and 380 or 550))
    local h=math.max(245,math.min(vp.Y-70,mobile and 320 or 405))
    local root=make("Frame",{
        BackgroundColor3=colors.bg,BorderSizePixel=0,Size=UDim2.fromOffset(w,h),
        Position=UDim2.new(.5,0,.5,0),AnchorPoint=Vector2.new(.5,.5)
    },sg)
    round(root,12);stroke(root)
    local head=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,47)},root)
    local logo=make("ImageLabel",{
        BackgroundTransparency=1,Image="rbxassetid://111668536257891",
        Size=UDim2.fromOffset(32,32),Position=UDim2.fromOffset(9,8)
    },head)
    local brand=text(head,"MOTION CORE",15,true)
    brand.TextColor3=colors.accent
    brand.Position=UDim2.fromOffset(46,5)
    brand.Size=UDim2.new(1,-95,0,24)
    local sub=text(head,cfg.Content or "Violence District",10)
    sub.TextColor3=colors.muted
    sub.Position=UDim2.fromOffset(46,25)
    sub.Size=UDim2.new(1,-95,0,14)
    local close=button(head,"–",25)
    close.Size=UDim2.fromOffset(27,25)
    close.Position=UDim2.new(1,-37,0,10)
    local nav=make("ScrollingFrame",{
        BackgroundColor3=colors.panel,BorderSizePixel=0,Position=UDim2.fromOffset(8,48),
        Size=UDim2.new(0,mobile and 95 or 125,1,-56),ScrollBarThickness=2,
        ScrollBarImageColor3=colors.accent,AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new()
    },root)
    round(nav,8);layout(nav,5,6)
    local pageHost=make("Frame",{
        BackgroundTransparency=1,Position=UDim2.fromOffset(mobile and 110 or 141,49),
        Size=UDim2.new(1,-(mobile and 117 or 149),1,-57)
    },root)
    local win={Root=root,Gui=sg,Pages={},Visible=true}
    local selected
    function win:IsOpen() return self.Visible end
    function win:SetVisible(state)
        self.Visible=state==true
        root.Visible=self.Visible
    end
    function win:SetAccount(data)
        sub.Text=(data and (data.Username or data.Expires)) or (cfg.Content or "Violence District")
    end
    local function page(name)
        local holder=make("Frame",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Visible=false},pageHost)
        local s=scroll(holder)
        return {Holder=holder,Scroll=s,SubNav=nil}
    end
    function win:AddTab(tabCfg)
        local name=tabCfg.Name or "Tab"
        local btn=button(nav,name,31)
        btn.TextXAlignment=Enum.TextXAlignment.Left
        btn.TextSize=11
        local p=page(name)
        local t={Name=name,Page=p}
        local function select()
            if selected then selected.Page.Holder.Visible=false;selected.Button.BackgroundColor3=colors.item;selected.Button.TextColor3=colors.text end
            selected=t;t.Page.Holder.Visible=true;btn.BackgroundColor3=colors.accent;btn.TextColor3=Color3.new(1,1,1)
        end
        t.Button=btn
        btn.MouseButton1Click:Connect(select)
        function t:AddSection(sc)
            return sectionAPI(p.Scroll,sc.Name,sc.Opened,win._save,win._load)
        end
        function t:AddCenterTabbox()
            if not p.SubNav then
                p.SubNav=make("ScrollingFrame",{
                    BackgroundTransparency=1,Position=UDim2.fromOffset(0,0),
                    Size=UDim2.new(1,0,0,30),CanvasSize=UDim2.new(),ScrollBarThickness=2,
                    AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X
                },p.Holder)
                make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)},p.SubNav)
                p.Scroll.Position=UDim2.fromOffset(0,35)
                p.Scroll.Size=UDim2.new(1,0,1,-35)
                p.SubPages={}
            end
            local tabbox={}
            function tabbox:AddTab(c)
                local b=button(p.SubNav,c.Name,26)
                b.Size=UDim2.fromOffset(math.max(65,#c.Name*7+22),26)
                local sub=make("Frame",{BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,
                    Size=UDim2.new(1,-9,0,0),Visible=false},p.Scroll)
                layout(sub,8)
                local child={}
                function child:AddSection(sc)
                    sc=sc or {}
                    return sectionAPI(sub,sc.Name or "Controls",sc.Opened,win._save,win._load)
                end
                local implicitSection=nil
                local function ensureImplicit()
                    if not implicitSection then
                        implicitSection=sectionAPI(sub,c.Name or "Controls",true,win._save,win._load)
                    end
                    return implicitSection
                end
                function child:AddDivider(cfg)
                    return ensureImplicit():AddDivider(cfg)
                end
                for _,method in ipairs({
                    "AddToggle","AddSlider","AddDropdown","AddButton","AddColorPicker",
                    "AddKeybind","AddLabel","AddTextInput"
                }) do
                    local name=method
                    child[name]=function(_,cfg)
                        local target=ensureImplicit()
                        return target[name](target,cfg)
                    end
                end
                local entry={Button=b,Panel=sub}
                table.insert(p.SubPages,entry)
                b.MouseButton1Click:Connect(function()
                    for _,v in ipairs(p.SubPages) do
                        v.Panel.Visible=(v==entry)
                        v.Button.BackgroundColor3=(v==entry) and colors.accent or colors.item
                    end
                end)
                if #p.SubPages==1 then b.BackgroundColor3=colors.accent;sub.Visible=true end
                return child
            end
            return tabbox
        end
        self.Pages[name]=t
        if not selected then select() end
        return t
    end
    function win:CreateHomeTab(data)
        local t=self:AddTab({Name=data.Name or "Dashboard"})
        t.Button.LayoutOrder=-20
        local sec=t:AddSection({Name="Welcome",Opened=true})
        sec:AddLabel({Name=data.Content or "Motion Core"})
        sec:AddLabel({Name="Motion Core VD • UI v"..UI.Version})
    end
    function win:AttachMenuIcon(icon)
        local b=button(sg,"M",39)
        b.Position=UDim2.new(0,14,0.5,-20)
        b.Size=UDim2.fromOffset(39,39)
        b.BackgroundColor3=colors.accent
        b.TextSize=19
        b.Text=""
        local img=make("ImageLabel",{
            BackgroundTransparency=1,Image=(icon and icon.Image) or "rbxassetid://111668536257891",
            Size=UDim2.new(1,-7,1,-7),Position=UDim2.fromOffset(3.5,3.5)
        },b)
        b.MouseButton1Click:Connect(function() self:SetVisible(not self.Visible) end)
        local moving,begin,pos
        b.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                moving=true;begin=i.Position;pos=b.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if moving and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local d=i.Position-begin;b.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then moving=false end end)
    end
    local drag,start,startPosition
    head.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true;start=i.Position;startPosition=root.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-start
            root.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    close.MouseButton1Click:Connect(function() win:SetVisible(false) end)
    local openKey=Enum.KeyCode.RightControl
    local toggleConn=UIS.InputBegan:Connect(function(i,processed)
        if not processed and not UIS:GetFocusedTextBox() and i.KeyCode==openKey then win:SetVisible(not win.Visible) end
    end)
    local settings=cfg.Config or {}
    local folder=settings.ConfigFolder or "MotionCore_VD"
    local path=folder.."/MC_UI.json"
    local cache={}
    pcall(function() if isfile and readfile and isfile(path) then cache=Http:JSONDecode(readfile(path)) end end)
    win._load=function(flag,default)
        local v=cache[flag]
        if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then return v end
        return default
    end
    win._save=function(flag,value)
        if flag=="" or type(value)=="table" then return end
        cache[flag]=value
        if not settings.AutoSave then return end
        task.defer(function()
            pcall(function()
                if makefolder and isfolder and not isfolder(folder) then makefolder(folder) end
                if writefile then writefile(path,Http:JSONEncode(cache)) end
            end)
        end)
    end
    local alive=true
    local cleanup=function()
        if not alive then return end
        alive=false
        if toggleConn then toggleConn:Disconnect() end
        sg:Destroy()
    end
    if getgenv then getgenv().MC_VD_UI_Drop=cleanup end
    function win:Destroy() cleanup() end
    return win
end
return UI

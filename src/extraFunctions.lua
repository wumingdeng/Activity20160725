function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function tonum(v, base)
    return tonumber(v, base) or 0
end

function toint(v)
    return math.round(tonum(v))
end

function tointk(v)
    return math.floor(v)
end

function tobool(v)
    return (v ~= nil and v ~= false)
end

function totable(v)
    if type(v) ~= "table" then v = {} end
    return v
end

function isset(arr, key)
    local t = type(arr)
    return (t == "table" or t == "userdata") and arr[key] ~= nil
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function iskindof(obj, className)
    local t = type(obj)

    if t == "table" then
        local mt = getmetatable(obj)
        while mt and mt.__index do
            if mt.__index.__cname == className then
                return true
            end
            mt = mt.super
        end
        return false

    elseif t == "userdata" then

    else
        return false
    end
end

function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end

function handler(target, method)
    return function(...)
        return method(target, ...)
    end
end

function math.round(num)
    return math.floor(num + 0.5)
end

function math.angle2Radian(angle)
    return angle*math.pi/180
end

function math.radian2Angle(radian)
    return radian/math.pi*180
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.keys(t)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(t)
    local values = {}
    for k, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--[[--

insert list.

**Usage:**

local dest = {1, 2, 3}
local src  = {4, 5, 6}
table.insertTo(dest, src)
-- dest = {1, 2, 3, 4, 5, 6}
dest = {1, 2, 3}
table.insertTo(dest, src, 5)
-- dest = {1, 2, 3, nil, 4, 5, 6}


@param table dest
@param table src
@param table begin insert position for dest
]]
function table.insertTo(dest, src, begin)
    begin = tonumber(begin)
    if begin == nil then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

--[[
search target index at list.

@param table list
@param * target
@param int from idx, default 1
@param bool useNaxN, the len use table.maxn(true) or #(false) default:false
@param return index of target at list, if not return -1
]]
function table.indexOf(list, target, from, useMaxN)
    local len = (useMaxN and #list) or table.maxn(list)
    if from == nil then
        from = 1
    end
    for i = from, len do
        if list[i] == target then
            return i
        end
    end
    return -1
end

function table.indexOfKey(list, key, value, from, useMaxN)
    local len = (useMaxN and #list) or table.maxn(list)
    if from == nil then
        from = 1
    end
    local item = nil
    for i = from, len do
        item = list[i]
        if item ~= nil and item[key] == value then
            return i
        end
    end
    return -1
end

function table.removeItem(t, item, removeAll)
    for i = #t, 1, -1 do
        if t[i] == item then
            table.remove(t, i)
            if not removeAll then break end
        end
    end
end

function table.map(t, fun)
    for k,v in pairs(t) do
        t[k] = fun(v, k)
    end
end

function table.walk(t, fun)
    for k,v in pairs(t) do
        fun(v, k)
    end
end

function table.filter(t, fun)
    for k,v in pairs(t) do
        if not fun(v, k) then
            t[k] = nil
        end
    end
end

function table.find(t, item)
    return table.keyOfItem(t, item) ~= nil
end

function table.unique(t)
    local r = {}
    local n = {}
    for i = #t, 1, -1 do
        local v = t[i]
        if not r[v] then
            r[v] = true
            n[#n + 1] = v
        end
    end
    return n
end

function table.keyOfItem(t, item)
    for k,v in pairs(t) do
        if v == item then return k end
    end
    return nil
end

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end
string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialcharsDecode(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(str, delimiter)
    str = tostring(str)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

function string:split2(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function string.ltrim(str)
    return string.gsub(str, "^[ \t\n\r]+", "")
end

function string.rtrim(str)
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.trim(str)
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.ucfirst(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

local function urlencodeChar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

function string.urlencode(str)
    -- convert line endings
    str = string.gsub(tostring(str), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    str = string.gsub(str, "([^%w%.%- ])", urlencodeChar)
    -- convert spaces to "+" symbols
    return string.gsub(str, " ", "+")
end

function string.urldecode(str)
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonum(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end

function string.utf8len(str)
    local len  = #str
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.formatNumberThousands(num)
    local formatted = tostring(tonum(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function getTimeNumberWithoutHourConvertString(num) --不带小时
    local minutes
    local second
    --  return os.data("%Y-%M-%d %H:%M:%S",num)
    if num< 60 then
        minutes = 0
        second = num
    elseif num<3600 then
        minutes = math.floor(num/60)
        second = num%60
    else
        error("要显示小时请使用getTimeNumberConvertString()方法，谢谢~")
    end
    if string.len(minutes) == 1 or string.len(minutes) == 0 then
        minutes = "0"..minutes
    end
    if string.len(second) == 1 or string.len(second) == 0 then
        second = "0"..second
    end
    return minutes..":"..second
end
function string.getTimeNumberConvertString(num)
    local hours
    local minutes
    local second
    --  return os.data("%Y-%M-%d %H:%M:%S",num)
    if num< 60 then
        hours = 0
        minutes = 0
        second = num
    elseif num<3600 then
        hours = 0
        minutes = math.floor(num/60)
        second = num%60
    else
        hours = math.floor(num/3600)
        minutes = math.floor(num%60/60)
        second = num%3600%60
    end
    if string.len(hours) == 1 or string.len(hours) == 0 then
        hours = "0"..hours
    end
    if string.len(minutes) == 1 or string.len(minutes) == 0 then
        minutes = "0"..minutes
    end
    if string.len(second) == 1 or string.len(second) == 0 then
        second = "0"..second
    end
    return hours..":"..minutes..":"..second
end

--check sprite's alpha with world's position
function getOriginalAlphaPoint(source,p) 
    cc.Texture2D:setNeedGetAlpha(true)  --打开取透明度
    local sp = source:getVirtualRenderer():getSprite()
    local texture = sp:getTexture()
    local texturePixels = texture:getContentSizeInPixels()
    local rect = sp:getTextureRect()
    local isRotated = sp:isTextureRectRotated()
    local originalPoint = source:convertToNodeSpace(p)
    originalPoint.y = rect.height - originalPoint.y
    if isRotated then
        print("the source is rotated")
        originalPoint = cc.p(rect.height-originalPoint.y,originalPoint.x)
    end
    local alphaX = originalPoint.x+rect.x
    local alphaY = rect.y + originalPoint.y
    local ret = texture:getAlpha(alphaX,alphaY)
    cc.Texture2D:setNeedGetAlpha(false)
    return ret
end

--改变数字
function changeNum(label,original_num,target_num)   --要改变的label、原始值、目标值
    local change_num = target_num - original_num
    local rand_num = original_num   --随机数
    if target_num < 0 then
        print("original_num:",original_num)
        print("change_num:",change_num)
        error("What the hell are you doing?")
    end
    local len = #tostring(math.abs(change_num))  --要改变的数字长度
    local max_num = string.sub(original_num,-len,-len)  --要改变的最高位的原始值
    --    if max_num == "" then max_num = "0" end
    local max_target = string.sub(target_num,-len,-len) --要改变的最高位的目标值
    local changeMax = max_num   --最高位的中间状态
    local step  --要改变的步数
    if max_target == "0" then   --说明进位了
        step = 10 - tostring(max_num)
    elseif max_target == "" then
        step = max_num
    elseif max_num == "" then   --说明原来这位没数字
        step = max_target
    elseif max_target > max_num then
        step = max_target - max_num
    else
        step = max_target + 10 - max_num
    end
    local time = len*.3/cc.Director:getInstance():getAnimationInterval()
    local count = 0
    local function updataNum()
        if count <= time then
            --改变数字
            for i = 1,len do
                rand_num = tonumber(rand_num) + 10^(i-1)
            end
            count = count + 1
            if count%math.floor(time/step) == 0 then
                if changeMax == "" then --如果原来这位没数字changeMax就是""
                    changeMax = 1  
                else
                    if change_num > 0 then
                        changeMax = changeMax + 1
                        if changeMax == 10 then --进位
                            original_num = original_num + 10^len
                            changeMax = 0
                        end
                    else
                        changeMax = changeMax - 1
                        if changeMax == -1 then --退位
                            original_num = original_num - 10^len
                            changeMax = 9
                        end
                    end
                end 
            end
            label:setString(tostring(tonumber(string.sub(tostring(original_num),1,-len-1)..tostring(changeMax)..string.sub(rand_num,-len+1))))
        else
            label:setString(tostring(target_num))
            label:unscheduleUpdate()
        end
    end
    local function updataNumRegular()
        if count <= math.abs(change_num) then
            --改变数字
            if change_num > 0 then
                original_num = original_num + 1
            else
                original_num = original_num - 1
            end
            label:setString(tostring(original_num))
            count = count + 1
        else
            label:setString(tostring(target_num))
            label:unscheduleUpdate()
        end
    end
    if len > 2 then
        label:scheduleUpdateWithPriorityLua(updataNum, 0)
    else
        label:scheduleUpdateWithPriorityLua(updataNumRegular, 0)
    end

end

function relativePositionOnTheLeft(source,target,spacing)
    source:setPosition(target:getPositionX()-target:getBoundingBox().width-spacing,target:getPositionY())
end

--set btn's relative to the position on the right
function relativePositionOnTheRight(source,target,spacing)
    source:setPosition(target:getPositionX()+target:getBoundingBox().width+spacing,target:getPositionY())
end

--set btn's relative to the position on the top
function relativePositionOnTheTop(source,target,spacing)
    source:setPosition(target:getPositionX(),target:getPositionY()+target:getBoundingBox().height+spacing)
end

--set btn's relative to the position on the bottom
function relativePositionOnTheBottom(source,target,spacing)
    source:setPosition(target:getPositionX(),target:getPositionY()-target:getBoundingBox().height-spacing)
end

function getWidth(sp)
    if sp.getBoundingBox then
        return sp:getBoundingBox().width
    else
        error("传入的东西没有getBoundingBox方法")
    end
end
function getHeight(sp)
    if sp.getBoundingBox then
        return sp:getBoundingBox().height
    else
        error("传入的东西没有getBoundingBox方法")
    end
end
function setHeight(sp,height)
    if sp and sp:getContentSize() then
        local changeSize = cc.size(sp:getContentSize().width,height)
        sp:setContentSize(changeSize)
    else
        error("invalid object")
    end
end
function setWidth(sp,width)
    if sp and sp:getContentSize() then
        local changeSize = cc.size(width,sp:getContentSize().height)
        sp:setContentSize(changeSize)
    else
        error("invalid object")
    end
end
--添加遮挡层
function getParclose(layer,color)
    local parclose = ccui.Layout:create()
    parclose:setContentSize(vsize)
    parclose:setTouchEnabled(true)
    if color then
        parclose:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        parclose:setBackGroundColor(color)
    end
    --调整遮挡层位置
    parclose:setAnchorPoint(layer:getAnchorPoint())
    layer:addChild(parclose,-1)
end

OS_TIME = nil
--取运行时间
function getOSTimer(log)
    --    if not isDebug then
    --        return
    --    end
    if not OS_TIME then
        print("请在适当位置取osTime")
    else
        log = log or "当前用时:"
        print(log," ",os.clock() - OS_TIME)
        return os.clock() - OS_TIME
    end
end

function randomNumberArry() 
    local arr = {}
    local orgArr ={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    for i=1,15 do
        local count = table.getn(orgArr)
        local  rand = math.random(1,count)
        table.insert(arr,i,orgArr[rand])
        table.remove(orgArr,rand,orgArr[rand])
    end
    return arr
end

--添加全屏屏蔽
function addFullScreen()
    if cc.Director:getInstance():getRunningScene() then
        if not cc.Director:getInstance():getRunningScene():getChildByName("fullScreen") then
            local parclose = ccui.Layout:create()
            parclose:setContentSize(vsize)
            parclose:setTouchEnabled(true)
            parclose:setName("fullScreen")
            --调整遮挡层位置
            cc.Director:getInstance():getRunningScene():addChild(parclose,1000)
            print("添加全屏遮挡")
        end
    end
end


--取消全屏屏蔽
function removeFullScreen()
    if cc.Director:getInstance():getRunningScene() then
        if  cc.Director:getInstance():getRunningScene():getChildByName("fullScreen") then
            cc.Director:getInstance():getRunningScene():removeChildByName("fullScreen") 
            print("移除全屏遮挡")
        end
    end
end

--button extra function
--only support this button load same picture in different status
---------------------------------------------------
--@param #ccui.widget source 
--@param #function beginFun
--@param #function moveFun 
--@param #function endFun
--@param #function canceleFunc 
--@param sound string 音效的路径（没传用默认的音效）
function setButtonFun(source,beginFun,moveFun,endFun,canceleFun)
    --按下动作
    local function pressAction(button)
        local smaller = cc.ScaleTo:create(0.07,0.9)
        button:runAction(smaller)
    end
    --弹起动作
    local function recoveryAction(button)
        local bigger = cc.ScaleTo:create(0.1,1)
        local ease = cc.EaseBounceIn:create(bigger)
        button:runAction(ease)
    end
    local function onTouchFun(source,type)
        if type == ccui.TouchEventType.began then
            addFullScreen()
            source:setBrightStyle(ccui.BrightStyle.normal)
            pressAction(source)
            if beginFun then
                beginFun(source,type)
            end
        elseif type == ccui.TouchEventType.moved then
            source:setBrightStyle(ccui.BrightStyle.normal)
            local movePos = source:getTouchMovePosition()
            local isMoveOut = source:hitTest(movePos)
            if not isMoveOut then
                recoveryAction(source)
            end
            if moveFun then
                moveFun(source,type)
            end
        elseif type == ccui.TouchEventType.ended then
            removeFullScreen()
            recoveryAction(source)
            if endFun then
                endFun(source,type)
            end
        elseif type == ccui.TouchEventType.canceled then
            removeFullScreen()
            recoveryAction(source)
            if canceleFun then
                canceleFun(source,type)
            end
        end
    end
    source:addTouchEventListener(onTouchFun)
end
--///////////////////////////////////////////////////////
--create IndicatorLayer
--///////////////////////////////////////////////////////
local prizeInfoLayer = class("prizeInfoLayer")
prizeInfoLayer.__index = prizeInfoLayer
prizeInfoLayer._widget = nil
prizeInfoLayer._uiLayer= nil
prizeInfoLayer._MaskUI = nil
local _prizeInfoLayer = nil

--********** lua inherit
function prizeInfoLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, prizeInfoLayer)
    return target
end

--******** lua createScene function
function prizeInfoLayer.create()
    local layer = prizeInfoLayer.extend(cc.Layer:create())
    layer:init()

    local function onNodeEvent(event)  
        if "exit" == event then  
        end  
    end  

    layer:registerScriptHandler(onNodeEvent) 
    return layer   
end

--*********** init

function prizeInfoLayer:init()
--    self._uiLayer = cc.Layer:create()
--    self:addChild(self._uiLayer,0,0)   
    _prizeInfoLayer = self

    addFullScreen()
    return true  
end

function prizeInfoLayer:showPrizeTypeAllowedTouchWithDelay(type,allowed,delayTime,callBackFun)
    if allowed then
        removeFullScreen()
    else
        addFullScreen()
    end 
    if nil==delayTime then
        delayTime =1.5
    end    

    local function show()
        if type == "0" then
            playFailSound()
        else
            playGamblingSound()
        end
        local sp = cc.Sprite:createWithSpriteFrameName(type..".png")
        if sp ~= nil then
            sp:setAnchorPoint(.5,.5)
            sp:setPosition(vsize.width/2,vsize.height/2)
            sp:setTag(111)
            self:setLocalZOrder(1000)
            self:setVisible(true)
            self:addChild(sp)     
        end  
    end      
    local function dismis() 
        self:setVisible(false)
        local sp = self:getChildByTag(111)
        sp:removeFromParent(true)
        self:setLocalZOrder(-1)
        if callBackFun then
            callBackFun()
        end
    end    

    local delay = cc.DelayTime:create(delayTime)
    local seqc = cc.Sequence:create(cc.CallFunc:create(show),delay,cc.CallFunc:create(dismis))
    self:runAction(seqc)
end

local function dismis() 
    _prizeInfoLayer:setVisible(false)
    local prize = _prizeInfoLayer:getChildByTag(222)
    prize:removeFromParent(true)
    _prizeInfoLayer:setLocalZOrder(-1)
end  

return prizeInfoLayer
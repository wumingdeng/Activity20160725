--///////////////////////////////////////////////////////
--create IndicatorLayer
--///////////////////////////////////////////////////////

local IndicatorLayer = class("IndicatorLayer")
IndicatorLayer.__index = IndicatorLayer
IndicatorLayer._widget = nil
IndicatorLayer._uiLayer   = nil
IndicatorLayer._loadMark  = nil
IndicatorLayer._infoLabel = nil

IndicatorLayer._isWait = true

local vsize = cc.Director:getInstance():getVisibleSize()
local vorg  = cc.Director:getInstance():getVisibleOrigin() 
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

--********** lua inherit
function IndicatorLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, IndicatorLayer)
    return target
end

--******** lua createScene function
function IndicatorLayer.create()

    local layer = IndicatorLayer.extend(cc.Layer:create())
    layer:init()
    local function onNodeEvent(event)  
        if "enter" == event then  

        elseif "exit" == event then  
        end  
    end  
    layer:registerScriptHandler(onNodeEvent)  
    return layer   
end

--*********** init

function IndicatorLayer:init()

    self._uiLayer = cc.Layer:create()
    self:addChild(self._uiLayer,0,0)

    ------------- ui interface build
    self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("res/indicatorUI_1.json")
    self._widget:setAnchorPoint(cc.p(0,1))
    self._widget:setPosition(cc.p(vorg.x,vsize.height))
    self._uiLayer:addChild(self._widget) 


    local _blackBar = self._widget:getChildByName("imgBlack")
    self._loadMark  = _blackBar:getChildByName("imgLoad")
    self._loadMark:setVisible(false)
    self._infoLabel = _blackBar:getChildByName("lblInfo")
    return true  
end

-- 不阻止触摸
function IndicatorLayer:setNotSwallowTouch() 
--    removeFullScreen()
end

--转圈圈
function IndicatorLayer:showLoading() 
    self:setLocalZOrder(1000)
    self:setVisible(true)
    self._widget:setVisible(true)
    self._loadMark:setVisible(true) 
    local rotating = cc.RotateBy:create(1,360)
    self._loadMark:runAction(cc.RepeatForever:create(rotating))
    self._infoLabel:setString("正在加载 ...")
end
-- 延迟转圈圈 加载
function IndicatorLayer:showLoadingAfterDelay() 
    self._isWait = true
    addFullScreen()
    self._widget:setVisible(false)
    self:setLocalZOrder(1000)
    self:setVisible(true)
    local function loading() 
        if self._isWait then
            self:showLoading()
        end
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(loading)))
end
--停止转圈圈
function IndicatorLayer:endLoading()
    if table.nums(requestQueue) > 0 then 
        return 
    end
    self._isWait = false
    removeFullScreen()
    self:setLocalZOrder(-1)
    self:setVisible(false)
    self._loadMark:setVisible(false)  
    self._loadMark:stopAllActions()
    self._infoLabel:setString("")
end
function IndicatorLayer:preventTouch() 
    self:setLocalZOrder(1000)
    self:setVisible(false)
end
function IndicatorLayer:disPreventTouch() 
    self:setLocalZOrder(-1)
    self:setVisible(false)
end

--提示消息
function IndicatorLayer:alertInfo(InfoString) 
    self:alertInfoWithDelayAllowedTouch(InfoString,1.5,true)
end

-- 显示信息，需要延迟的时间，是否允许交互
function IndicatorLayer:alertInfoWithDelayAllowedTouch(InfoString,delayTime,allowTouch) 
    self._isWait = false
    self._loadMark:setVisible(false)  
    self._loadMark:stopAllActions()
    local function show()
        self:setLocalZOrder(1000)
        self._widget:setVisible(true)
        self:setVisible(true)
        self._loadMark:setVisible(false) 
        self._infoLabel:setString(InfoString)        
    end      
    local function dismis() 
        self:setVisible(false)
        self._infoLabel:setString("")
        self:setLocalZOrder(-1)
        if allowTouch then
            removeFullScreen()
        else
            addFullScreen()
        end

    end    
    local delay = cc.DelayTime:create(delayTime)
    local seqc = cc.Sequence:create(cc.CallFunc:create(show),delay,cc.CallFunc:create(dismis))

    self:runAction(seqc)
end

return IndicatorLayer
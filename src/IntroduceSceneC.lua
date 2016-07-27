

--///////////////////////////////////
--create IntroduceScene class 
--///////////////////////////////////
local IntroduceSceneC = class("IntroduceSceneC")
IntroduceSceneC._widget = nil
--IntroduceScene._sceneTitle = nil

function IntroduceSceneC.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, IntroduceSceneC)
    return target
end

function IntroduceSceneC:init()
    self._widget = cc.CSLoader:createNode("res/introuceScene.csb")
    self:addChild(self._widget)
    local pnlTop = self._widget:getChildByName("pnlTop")
    pnlTop:setPositionY(changedHeight-pnlTop:getContentSize().height)

    local slvInt = self._widget:getChildByName("slvInt")
    local imgMask = self._widget:getChildByName("imgMask")

    slvInt:setContentSize(640,changedHeight - 110)
    imgMask:setContentSize(623,changedHeight - 100)

    local btnReturn = pnlTop:getChildByName("btnReturn")
    local function returnFun(sender,type)
        local ccc = require("src/GambleScene")
        local scene = ccc.create()
        if cc.Director:getInstance():getRunningScene() then
            cc.Director:getInstance():replaceScene(scene)
        else
            cc.Director:getInstance():runWithScene(scene)
        end
    end
    setButtonFun(btnReturn,nil,nil,returnFun)
end  

local function onExit()  

end 
function IntroduceSceneC.create()
    local scene = cc.Scene:create()
    local layer = IntroduceSceneC.extend(cc.Layer:create())
    layer:init()
    scene:addChild(layer)

    -------- onEnter or onExit -----------
    local function sceneEventHandler(eventType)  
        if eventType == "exit" then  
            onExit()   
        elseif eventType =="enter" then
        end  
    end  

    scene:registerScriptHandler(sceneEventHandler)
    ------------------------------------------
    return scene   
end

return IntroduceSceneC
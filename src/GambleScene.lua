local GambleScene = class("GambleScene")
GambleScene.__index       = GambleScene
GambleScene._widget       = nil
GambleScene._uiLayer      = nil

GambleScene._boolStarted  = true
GambleScene._ballArr      = {}
GambleScene._prizeInfoLayer=nil
----Cocostudio UI--
GambleScene._lblTimes     = nil
GambleScene._indicator    = nil
GambleScene._redPacket = nil
GambleScene._preHongbao = nil

GambleScene._bonusId = 0
GambleScene._randNum = 0
GambleScene._giftID = 0

GambleScene.btnStart = nil
GambleScene.btnExit = nil
GambleScene.btnActivity = nil

GambleScene.addtionLayer = nil
GambleScene.scoreLayer = nil

local selfLayer = nil
local tagerID = 0
local speed = 4
local redCount = 8
local speedArr = {}
local redInitArr = {}   --红包初始化数组

local throwId = nil --抛红包计时
local animationID = nil --抛红包计时

cc.SpriteFrameCache:getInstance():addSpriteFrames("res/res.plist","res/res.png")
cc.SpriteFrameCache:getInstance():addSpriteFrames("res/jpgRes.plist","res/jpgRes.jpg")

function GambleScene:maskAllButton(flg)
    self.btnStart:setTouchEnabled(flg)
    self.btnExit:setTouchEnabled(flg)
    self.btnActivity:setTouchEnabled(flg)
    self.btnInfo:setTouchEnabled(flg)
end

--查询可玩次数
function  GambleScene:refreshChanceAndPoints()  
    local url = API_checkPlayableTimes(userID,userCode) --API_displayCellInfo()
--    self:maskAllButton(false)
    local function onReadyStateChange(parsedXml)
        local qtyChance = parsedXml.items.item["@qtyChance"]--可玩游戏次数
        self._lblTimes:setString(""..qtyChance)
        Gold_times = qtyChance
        self._indicator:endLoading()
        if self._boolStarted then
            self:maskAllButton(true)
        end
    end
    local function failRessponseCallBackFun()
        self:maskAllButton(true)
    end
    sendRequestByUrl(url,self._indicator,onReadyStateChange,failRessponseCallBackFun)
end


local function setBtnNor(psender)
    psender:setTouchEnabled(true)
    removeFullScreen()
end
local function setBtnMask(psender)
    psender:setTouchEnabled(false)
    addFullScreen()
end

local function goIntroduceScene(psender,eventType)
    if eventType == ccui.TouchEventType.ended then
        setBtnMask(psender)
        playbtnClicked()
        local introduceScene = require "src/IntroduceSceneC"
        local scene = introduceScene:create()
        cc.Director:getInstance():replaceScene(scene)
    end
end

local function goPrizeInfo(psender,eventType)
    if eventType == ccui.TouchEventType.ended then
        setBtnMask(psender)
        playbtnClicked()
        require "src/MyprizeScene"
        local scene = MyprizeScene:create()
        cc.Director:getInstance():replaceScene(scene)
    end
end

local function gobackToApp(psender,eventType)
    playbtnClicked() 
    unlodadBackGroundMusic()
    luabridge.callStaticMethod(className,"backToApp")
end 
--///////////////////////////////////////////////////////
----------------------------------------------------

function GambleScene.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, GambleScene)
    return target
end

function GambleScene:commitResult()
    local url = API_commitResult(userID,userCode,self._bonusId,self._giftID,self._randNum,termType)
    local function onReadyStateChange(parsedXml)
        removeFullScreen()
        local code = parsedXml.SystemMsg.code:getValue()                 
        local msg = parsedXml.SystemMsg.msg:getValue()
        if code =="1" then 
            self._indicator:endLoading()
        elseif code == "-1" then
            self._indicator:alertInfo(msg)
        else
            self._indicator:alertInfo(msg)
        end
    end
    local function failFun()
        removeFullScreen()
    end
    sendRequestByUrl(url,self._indicator,onReadyStateChange,failFun,false)
end

local function endGame()
    selfLayer:maskAllButton(true)
    selfLayer._redPacket:setVisible(false)
    --初始化红包层
    selfLayer:initRedPacket()

    if tagerID ~= 0 then -- unselected honghao
        selfLayer._redPacket:getChildByTag(tagerID):setLocalZOrder(0)
        selfLayer._redPacket:getChildByTag(tagerID):runAction(cc.OrbitCamera:create(1, 1, 0, 0, 0, 0, 0))
    end
    selfLayer._redPacket:getChildByName("panelhongbaobg"):setLocalZOrder(0)
    selfLayer._widget:getChildByName("pnlTime"):setVisible(true)
    selfLayer._redPacket:getChildByName("panelhongbaobg"):getChildByTag(2):setScaleY(1)
    tagerID = 0
end

local function showResult()
    selfLayer._boolStarted = true
    selfLayer._prizeInfoLayer:showPrizeTypeAllowedTouchWithDelay(selfLayer._giftID,true,1.5,endGame)  
    selfLayer:commitResult()            
end

local function throwAnimation()

    for i = 1,redCount do
        if i ~= tagerID then
            local red = selfLayer._redPacket:getChildByTag(i)
            if throwId then
                local ro = red:getRotation3D()
                red:setRotation3D({x = ro["x"]+speedArr[i]["rotationX"],y=ro["y"]+speedArr[i]["rotationY"],z=ro["z"]+speedArr[i]["rotationZ"]})
            end
            --移动
            local rx,ry = red:getPosition()
            rx = rx + speedArr[i]["speedX"]
            ry = ry + speedArr[i]["speedY"]
            ry = ry + red:getParent():getPositionY()    --变成世界坐标
            if rx < 0+red:getBoundingBox().width/2 or rx>designSize.width - red:getBoundingBox().width/2 then
                --超出屏幕
                if rx < 0+red:getBoundingBox().width/2 then
                    rx = red:getBoundingBox().width/2
                else 
                    rx = designSize.width - red:getBoundingBox().width/2
                end
                --改变红包的方向
                speedArr[i]["speedX"] = -speedArr[i]["speedX"]
                speedArr[i]["speedX"] = speedArr[i]["speedX"] + math.random(1.4) - 0.7    --随机偏移
                if speedArr[i]["speedX"] > speed then speedArr[i]["speedX"] = speed end
                if speedArr[i]["speedY"] > 0 then
                    speedArr[i]["speedY"] = math.sqrt(speed*speed - speedArr[i]["speedX"]*speedArr[i]["speedX"])    --重新算ry
                else
                    speedArr[i]["speedY"] = math.sqrt(speed*speed - speedArr[i]["speedX"]*speedArr[i]["speedX"])
                    if speedArr[i]["speedY"] ~= 0 then
                        speedArr[i]["speedY"]  = -speedArr[i]["speedY"] 
                    end
                end
            end
            if ry < red:getBoundingBox().height/2 or ry>changedHeight- red:getBoundingBox().height/2 then
                --超出屏幕
                if ry < 0+red:getBoundingBox().height/2 then
                    ry = red:getBoundingBox().height/2
                else 
                    ry = changedHeight - red:getBoundingBox().height/2
                end
                --改变红包的方向
                speedArr[i]["speedY"] = -speedArr[i]["speedY"]
                speedArr[i]["speedY"] = speedArr[i]["speedY"] + math.random(1.4) - 0.7     --随机偏移
                if speedArr[i]["speedY"] > speed then speedArr[i]["speedY"] = speed end
                if speedArr[i]["speedX"] > 0 then
                    speedArr[i]["speedX"] = math.sqrt(speed*speed - speedArr[i]["speedY"]*speedArr[i]["speedY"])    --重新算ry
                else
                    speedArr[i]["speedX"] = -math.sqrt(speed*speed - speedArr[i]["speedY"]*speedArr[i]["speedY"])
                end
            end
            ry = ry - red:getParent():getPositionY()    --换成在层上的坐标
            red:setPosition(rx,ry)
        end
    end
end

local function stopThrow()
    print("抛完了")
    local tid

    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(throwId) 


    local function stop()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(tid) 
        throwId = nil 
        for i = 1,redCount do
            --全部变成正面
            local red = selfLayer._redPacket:getChildByTag(i)
            red:setRotation3D({x=0,y=0,z=0})
        end
        removeFullScreen()
    end
    tid = cc.Director:getInstance():getScheduler():scheduleScriptFunc(stop, .5, false)
    local time = 0.5 / cc.Director:getInstance():getAnimationInterval()  --给的时间
    --转到正面
    for i = 1,redCount do
        local red = selfLayer._redPacket:getChildByTag(i)  
        local ro = red:getRotation3D()
        --在给定时间内转到正面
        local ox = math.mod(ro["x"],360)    --还差多少度
        --修改转动速度
        if ox < 0 then
            ox = -360 - ox
        elseif ox > 0 then
            ox = 360 - ox
        end
        speedArr[i]["rotationX"] = ox/time
        local oy = math.mod(ro["y"],360)    --还差多少度
        if oy < 0 then
            oy = -360 - oy
        elseif oy > 0 then
            oy = 360 - oy
        end
        speedArr[i]["rotationY"] = oy/time
        local oz = math.mod(ro["z"],360)    --还差多少度
        if oz < 0 then
            oz = -360 - oz
        elseif oz > 0 then 
            oz = 360 - oz
        end
        speedArr[i]["rotationZ"] = oz/time
    end
end

function GambleScene:openHongbao()
    local hongbaobgPnl = selfLayer._redPacket:getChildByName("panelhongbaobg")
    local function hongbaobgFun()
        hongbaobgPnl:setVisible(true)
        local hongbaobg = hongbaobgPnl:getChildByName("hongbao1_2")
        local hongbaobg1 = hongbaobgPnl:getChildByName("hongbao1_1")
        hongbaobg1:runAction(cc.OrbitCamera:create(.3, 1, 0, 270, 90, 0, 0))
        local actions = cc.Sequence:create(cc.OrbitCamera:create(.3, 1, 0, 270, 90, 0, 0),cc.ScaleBy:create(0.5,1,-1),cc.CallFunc:create(showResult))
        hongbaobg:runAction(actions)
    end
    local red = selfLayer._redPacket:getChildByTag(tagerID)
    selfLayer._redPacket:getChildByName("panelhongbaobg"):setLocalZOrder(1000)
    red:setLocalZOrder(1000)
    local action = cc.MoveTo:create(1,cc.p(getWidth(selfLayer._redPacket)/2,getHeight(selfLayer._redPacket)/2))
    local action1 = cc.OrbitCamera:create(1, 1, 0, 0, -90, 0, 0)
    local action2 = cc.CallFunc:create(hongbaobgFun)
    local actions = cc.Sequence:create(action,action1,action2)
    red:runAction(actions)
end

function GambleScene:beginGame()
    addFullScreen()
    selfLayer._redPacket:getChildByName("panelhongbaobg"):setVisible(false)
    selfLayer._redPacket:setVisible(true)
    selfLayer._preHongbao:setVisible(false)
    selfLayer._widget:getChildByName("pnlTime"):setVisible(false)
    print("开始")
    --给每个红包一个初始速度
    math.randomseed(os.time())
    speedArr = {}
    for i = 1,redCount do
        local red = selfLayer._redPacket:getChildByTag(i)
        red:setAnchorPoint(.5,.5)
        local direction = math.random(360)
        local speedX = math.cos(direction*math.pi/180)*speed
        local speedY = math.sin(direction*math.pi/180)*speed
        local rotationX = math.random(8,12) * (math.random(1,10)%2 == 0 and 1 or -1)
        local rotationY = math.random(8,12) * (math.random(1,10)%2 == 0 and 1 or -1)
        local rotationZ = math.random(8,12) * (math.random(1,10)%2 == 0 and 1 or -1)
        --存起来
        table.insert(speedArr,{["speedX"]=speedX,["speedY"]=speedY,["rotationX"]=rotationX,["rotationY"]=rotationY,["rotationZ"]=rotationZ})

        local bigger = cc.ScaleTo:create(1.5,1,1)
        red:runAction(bigger)
        local function clickHongbao(render,type)
            if tagerID ~= 0 then return end
            if type == ccui.TouchEventType.began then
                playSelectSound()   --音效
                selfLayer._redPacket:unscheduleUpdate()
                tagerID = render:getTag()
                selfLayer:openHongbao()
            end
        end
        red:addTouchEventListener(clickHongbao)
    end
    throwId = cc.Director:getInstance():getScheduler():scheduleScriptFunc(stopThrow, 2.0, false)
    selfLayer._redPacket:scheduleUpdateWithPriorityLua(throwAnimation,0)
end

function GambleScene:initRedPacket()
    selfLayer._redPacket:unscheduleUpdate()
    selfLayer._preHongbao:setVisible(true)
    for i = 1,redCount do
        local red = self._redPacket:getChildByTag(i)
        red:setPosition(redInitArr[i]["x"],redInitArr[i]["y"])
        red:setRotation3D(redInitArr[i]["r3D"])
        red:setScaleX(redInitArr[i]["scaleX"])
        red:setScaleY(redInitArr[i]["scaleY"])
    end
end

----------------------------------------------------
function GambleScene:init()
--    preloadBackGroundMusic()
    self._boolStarted = true
    self._isclose     = true
    local indicatorLayer = require "src/IndicatorLayer"
    self._indicator = indicatorLayer:create()
    self:addChild(self._indicator,-1)

    self._uiLayer = cc.Layer:create()
    self:addChild(self._uiLayer,0,0)

    local prizeInfoLayer = require "src/PrizeInfoLayer"
    self._prizeInfoLayer = prizeInfoLayer:create()
    self:addChild(self._prizeInfoLayer,-2,0)


    self._widget = cc.CSLoader:createNode("res/MainScene.csb")
    local pnlTime = self._widget:getChildByName("pnlTime")
    local pnlTop = self._widget:getChildByName("pnlTop")
    local pnlBottom = self._widget:getChildByName("pnlBottom")
    self._lblTimes = cc.LabelBMFont:create(Gold_times, "res/fonts/defen.fnt")
    self._lblTimes:setPosition(330, 200)
    pnlTime:addChild(self._lblTimes)
    pnlTop:setPositionY(changedHeight-pnlTop:getContentSize().height)
    pnlTime:setPositionY(pnlTime:getPositionY()*scaleFactor)
    
    self._redPacket = self._widget:getChildByName("pnlRobZoon")
    self._redPacket:getChildByName("panelhongbaobg"):setVisible(false)
    self._redPacket:getChildByName("panelhongbaobg"):setPositionY(changedHeight/2)
    self._redPacket:setContentSize(designSize.width,changedHeight)
    self._redPacket:setVisible(false)
    
    self.addtionLayer = self._widget:getChildByName("addLayer")
    self.scoreLayer = self._widget:getChildByName("scoreLayer")

    self.addtionLayer:setVisible(false)
    self.scoreLayer:setVisible(false)
    self.addtionLayer:setPosition(vsize.width/2,vsize.height/2)
    self.scoreLayer:setPosition(vsize.width/2,vsize.height/2)

    redInitArr = {}
    for i = 1,redCount do
        local red = self._redPacket:getChildByTag(i)
        local x,y = red:getPosition()
        local sx = red:getScaleX()
        local sy = red:getScaleY()
        local r3d = red:getRotation3D()
        local data = {["x"] = x,["y"] = y,["scaleX"] = sx,["scaleY"] = sy,["r3D"] = r3d}
        table.insert(redInitArr,data)
    end
    
    self._preHongbao = self._widget:getChildByName("hongbao")
    local _,posititonY = self._preHongbao:getPosition()
    local pecY = posititonY/designSize.height
    self._preHongbao:setPositionY(changedHeight*pecY)
    
    self.btnActivity = pnlBottom:getChildByName("btnActivity")
    self.btnInfo = pnlBottom:getChildByName("btnInfo")
    self.btnStart = pnlBottom:getChildByName("btnStart")
    self.btnScore = pnlBottom:getChildByName("btnScore")
    self.btnExit = pnlTop:getChildByName("btnExit")
    self.btnActivity:addTouchEventListener(goIntroduceScene)
    self.btnInfo:addTouchEventListener(goPrizeInfo)
    setButtonFun(self.btnExit,nil,nil,gobackToApp)
    self._uiLayer:addChild(self._widget) 
    
    local function goChargeScore(sender,type)
        
    end
    self.btnScore:addTouchEventListener(goChargeScore)

    local function onStartGambling()  
        local url = API_startGambling(userID,userCode,termType)
        local function onReadyStateChange(parsedXml)
            local code = parsedXml.SystemMsg.code:getValue()                 
            local msg = parsedXml.SystemMsg.msg:getValue()
            if code =="1" then    
                local values = string.split2(msg,"@")
                self._bonusId = values[1]
                self._randNum = values[2]
                self._giftID = values[3]
                self._indicator:endLoading()
                self._boolStarted = false
                Gold_times = parsedXml.SystemMsg.value:getValue()
                self._lblTimes:setString(""..Gold_times)
                self:beginGame()
            else 
                removeFullScreen()
                self:maskAllButton(true)
                self._indicator:alertInfo(msg)
            end
        end
        local function failFun()
            print("respons fail~~~~~~~~")
            removeFullScreen()
            self:maskAllButton(true)
        end
        sendRequestByUrl(url,self._indicator,onReadyStateChange,failFun)
    end
    local function showLottery(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:maskAllButton(false)
            onStartGambling()
        end
    end
    self.btnStart:addTouchEventListener(showLottery)
    self:refreshChanceAndPoints()
end

--playBackGroundMusic() 

function GambleScene:onExit()  
end  

function GambleScene:onEnter() 

end

function GambleScene.create()
    local scene = cc.Scene:createWithPhysics()
    scene:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_NONE)
    local layer = GambleScene.extend(cc.Layer:create())
    layer:init()
    scene:addChild(layer)
    selfLayer = layer
    local function onNodeEvent(event)
        if "enter" == event then  
            layer:onEnter()  
        elseif "exit" == event then  
            layer:onExit()  
        end  
    end  
    scene:registerScriptHandler(onNodeEvent) 
    return scene   
end



return GambleScene
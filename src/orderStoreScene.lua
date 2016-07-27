orderStoreScene = class("orderStoreScene")
orderStoreScene.__index = orderStoreScene
orderStoreScene._uiLayer= nil

local vsize = cc.Director:getInstance():getVisibleSize()
local vOrg  = cc.Director:getInstance():getVisibleOrigin()
local _tableView  = nil
local orderStoreInfo = {}
local ownOrderStoreInfo = {}
local times = nil
local _indicator = nil
local isChecked = false --判断是否为刷新后的数据
local _xml = require("src/xmlSample").newParser()
local checkOrder= nil
local isRefresh = false

function orderStoreScene.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, orderStoreScene)
    return target
end
--------------------tableview delegate  ----------
local function scrollViewDidScroll(view)
-- print("scrollViewDidScroll")
end

local function scrollViewDidZoom(view)
-- print("scrollViewDidZoom")
end
local orderIdx = -1     --current checked cell index
local function tableCellTouched(table,cell)

    local cellIdx = cell:getIdx()
    local cellUI = cell:getChildByTag(cellIdx)
    local btn = cellUI:getChildByName("btnOrder")
    if cellIdx == orderIdx then
        btn:setBright(true)
        checkOrder = nil
        ownOrderStoreInfo[1] = nil
        orderIdx = -1
    elseif orderIdx ~= -1 then
        --local cellUI_1 = table:cellAtIndex(orderIdx):getChildByTag(orderIdx)
        local btn_1 = checkOrder:getChildByName("btnOrder")
        btn_1:setBright(true)
        btn:setBright(false)
        checkOrder = cellUI
        ownOrderStoreInfo[1] = orderStoreInfo[cellIdx+1]
        orderIdx = cellIdx
    else
        checkOrder = cellUI
        ownOrderStoreInfo[1] = orderStoreInfo[cellIdx+1]
        orderIdx = cellIdx
        btn:setBright(false)
    end
end
local function cellSizeForTable(table,idx) 
    return  140,vsize.height-400
end
local function numberOfCellsInTableView()   
    return #orderStoreInfo
end

local function tableCellAtIndex(table, idx)
    local strValue = string.format("%d",idx)

    local cell = table:cellAtIndex(idx)
    --table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
        --print("-------->>>>idx=="..idx)
        local cellUI = ccs.GUIReader:getInstance():widgetFromJsonFile("res/orderStoreCell.json") 
        cellUI:setAnchorPoint(0,0)
        cellUI:setPosition(0,-5)
        cellUI:setTag(idx)
        cell:addChild(cellUI)   

        -------
        local items = orderStoreInfo[idx+1]
--        local detail = cellUI:getChildByName("Panel_2")
        cellUI:getChildByName("lblName"):setString(items["@storeName"])
        cellUI:getChildByName("lblAddress"):setString(items["@storeAddr"])
        cellUI:getChildByName("lblPhone"):setString(items["@storeTel"])
        if ownOrderStoreInfo ~= nil and ownOrderStoreInfo[1] ~= nil then 
            if ownOrderStoreInfo[1]["@storeId"] == items["@storeId"] then
                orderIdx = idx
                checkOrder = cellUI
                cellUI:getChildByName("btnOrder"):setBright(false)
            else
                cellUI:getChildByName("btnOrder"):setBright(true)
            end
        end
    end

    return cell
end
function orderStoreScene:getOrderStore()
    local url  = API_getBookingStoresInfo()
    local function onReadyStateChange(parsedXml)
        if parsedXml==nil or parsedXml.items==nil then
            _indicator:alertInfo("数据异常！")
            return
        end
        local items = parsedXml.items:children()
        if #items <= 0 then
            _indicator:alertInfo("您还未预约店面！")  --在还未预定门店情况下取到的数据为空，这里应该改为 “还未预定”
            return
        end
        _indicator:endLoading()
        isRefresh = true
        orderStoreInfo = items
        _tableView:reloadData()
    end
    local function faileFun()
    end
    sendRequestByUrl(url,_indicator,onReadyStateChange,faileFun)
end 
function orderStoreScene:close()
    if table.nums(requestQueue) == 0 then
        local ggg = require("src/GambleScene")
        local scene = ggg:create()
        cc.Director:getInstance():replaceScene(scene) 
    end
end


function orderStoreScene:refresh()
    local url  = API_getCurrentBookedStoreId(userID,actId)
    local function onReadyStateChange(parsedXml)
        if parsedXml==nil or parsedXml.items==nil then
            _indicator:alertInfo("数据异常！")
            return
        end
        _indicator:endLoading()
        local items = parsedXml.items:children()
        if #items <= 0 then
            return
        end
        ownOrderStoreInfo = items
        if isChecked then
            orderIdx = -1
            _tableView:reloadData()
        end
    end
    local function faileFun()
    end
    sendRequestByUrl(url,_indicator,onReadyStateChange,faileFun)
end

function orderStoreScene:init()
    self._uiLayer = cc.Layer:create()
    self:addChild(self._uiLayer)
    
    local imgBg = cc.Sprite:createWithSpriteFrameName("imgBg.png")

    local bgLayer = cc.LayerColor:create(cc.c4b(232,226,178,200))
    local clipLayer = ccui.Layout:create()
    clipLayer:setContentSize(vsize.width-30,vsize.height-30)
    clipLayer:setPosition(15,15)
    clipLayer:setClippingEnabled(true)
    imgBg:setPosition(vsize.width/2,vsize.height/2)
    clipLayer:addChild(bgLayer)
    self._uiLayer:addChild(imgBg)
    self._uiLayer:addChild(clipLayer)    

    require "src/IndicatorLayer"
    _indicator = IndicatorLayer:create()
    _indicator:setNotSwallowTouch()
    self._uiLayer:addChild(_indicator,-1)
    local orderUI = ccs.GUIReader:getInstance():widgetFromJsonFile("res/orderStore.json")

    local title = orderUI:getChildByName("Image_6")
    local orderBtn = orderUI:getChildByName("btnPanel"):getChildByName("orderBtn")
    local cancelBtn = orderUI:getChildByName("btnPanel"):getChildByName("cancleBtn")
    local returnBtn = orderUI:getChildByName("btnReturn")
--    returnBtn:setScaleY(1.3)
    local function submit(sender,eventType)
        if eventType ~= ccui.TouchEventType.ended then return end
        local xhr = cc.XMLHttpRequest:new()
        xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING        
        xhr.timeout = 10
        local url = API_submitBookingStoreID_Head()
        if orderIdx == -1 then
            _indicator:alertInfo("请选择预约门店！")
            return
        end
        local order = orderStoreInfo[orderIdx+1]
        local postData = API_submitBookingStoreID_Body(userID,order["@storeId"],order["@storeName"],order["@storeAddr"],order["@storeTel"],actId)
        local function onReadyStateChange(parsedXml)
            times = nil 
            local code = tonumber(parsedXml.SystemMsg.code:getValue())
            local msg = parsedXml.SystemMsg.msg:getValue()
            if code == 1 then
                _indicator:alertInfo(msg)
            else
                _indicator:alertInfo("预约失败")
            end  
        end
        local function faileFun()
        end
        sendRequestByUrl(url,_indicator,onReadyStateChange,faileFun,true,postData)
    end
    orderBtn:addTouchEventListener(submit)
    local function close(sender,eventType)
        if eventType ~= ccui.TouchEventType.ended then return end
        if table.nums(requestQueue) == 0 then
            local ggg = require("src/GambleScene")
            local scene = ggg:create()
            cc.Director:getInstance():replaceScene(scene) 
        end
    end
    returnBtn:addTouchEventListener(close)
    cancelBtn:addTouchEventListener(close)
    title:setPositionY(vsize.height - title:getBoundingBox().height)
    returnBtn:setPositionY(vsize.height - title:getBoundingBox().height)
    self._uiLayer:addChild(orderUI)
    local tableSize = cc.size(vsize.width,vsize.height-190)

    _tableView = cc.TableView:create(tableSize,cc.Layer:create())
    _tableView:setPosition(33,100)
    _tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    _tableView:setDelegate()
    _tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    _tableView:registerScriptHandler(scrollViewDidScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    _tableView:registerScriptHandler(scrollViewDidZoom,cc.SCROLLVIEW_SCRIPT_ZOOM)
    _tableView:registerScriptHandler(tableCellTouched,cc.TABLECELL_TOUCHED)
    _tableView:registerScriptHandler(cellSizeForTable,cc.TABLECELL_SIZE_FOR_INDEX)
    _tableView:registerScriptHandler(tableCellAtIndex,cc.TABLECELL_SIZE_AT_INDEX)
    _tableView:registerScriptHandler(numberOfCellsInTableView,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self._uiLayer:addChild(_tableView,10)
    isChecked = false
    self:refresh()
    self:getOrderStore()
    return true
end


function orderStoreScene.create()

    local scene = cc.Scene:create()
    local layer = orderStoreScene.extend(cc.Layer:create())
    layer:init()
    scene:addChild(layer)
    -------- onEnter or onExit -----------
    local function onNodeEvent(event)
        if event == "exit" then
        end
    end
    scene:registerScriptHandler(onNodeEvent)
    return scene
end
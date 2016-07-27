
--///////////////////////////////////////////////////////////////////////////////////////////////////////
--lua tableView class 
--///////////////////////////////////////////////////////////////////////////////////////////////////////--require "src/ExtensionTest/CocosBuilderTest"

local TableViewLayer = class("TableViewLayer")
TableViewLayer.__index = TableViewLayer
TableViewLayer._size = nil
local tableView = nil
local _listArr ={}
local _cellwidget = nil

local xml = require("src/xmlSample").newParser()
-------------request----
local _startPage = 1
--local items  = {}
local _indicator = nil
local _totalNum  = nil


local table_insert = table.insert
local table_getn = table.getn
local tabel_size = 10
local function checkPrizeList()
    addFullScreen()
    local url = API_checkPrizeList(userID,userCode,_startPage,_startPage+9) ---consumer version
    local function onReadyStateChange(parsedXml)
        removeFullScreen()
        local items_new = parsedXml.items:children()
        if table_getn(items_new) <= 0 then
            _indicator:alertInfo("没有数据！")
        else
            _startPage = _startPage + 10
            _indicator:endLoading()
            for k,v in ipairs(items_new) do 
                local name = v["@giftName"] 
                local gamingDate = v["@dumpDate"] 
                _totalNum = v["@totalNum"] 
                table.insert(_listArr,{prize = name,date = gamingDate})
             end
            tableView:reloadData() 
        end
    end
    local function failFun()
        removeFullScreen()
    end
    sendRequestByUrl(url,_indicator,onReadyStateChange,failFun)
end 
---------------

function TableViewLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, TableViewLayer)
    return target
end


function TableViewLayer.scrollViewDidScroll(view)
   -- print("scrollViewDidScroll")
    --TableViewLayer.dragRefreshTableView();
end
function TableViewLayer.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end
function TableViewLayer.tableCellTouched(table,cell)
   -- print("cell touched at index: " .. cell:getIdx())
end
function TableViewLayer.cellSizeForTable(table,idx) 
    return  80,600 --TableViewLayer._size.height/8
end
function TableViewLayer.numberOfCellsInTableView()   
    return #_listArr  ---table_getn(items)
end

local vsize = cc.Director:getInstance():getVisibleSize()
local vOrg  = cc.Director:getInstance():getVisibleOrigin()
   
function TableViewLayer.tableCellAtIndex(table, idx)
    local strValue = string.format("%d",idx)  
    
    local cell = table:cellAtIndex(idx)
    table:dequeueCell()
    if nil == cell then
--        if idx+1>#_listArr then
--            --return
--        end
        cell = cc.TableViewCell:new()
        --print("..>>>>idx=="..idx)
        local cellUI = ccs.GUIReader:getInstance():widgetFromJsonFile("res/myPrizeCellUI.json") 
        cellUI:setAnchorPoint(0,0) 
        cellUI:setPosition(0,0)
        cell:addChild(cellUI)

        local lblPrize = cellUI:getChildByName("lblPrize")
        lblPrize:setString(_listArr[idx+1].prize)
        local lblDate = cellUI:getChildByName("lblDate")
        lblDate:setString(_listArr[idx+1].date)

    end

    return cell 
end 


local function onTouchBegan(touch, event)
    return true
end
local function onTouchMoved(touch, event)

end
local isNew = false

local function onTouchEnded(touch, event)
    local p = touch:getStartLocation();
    local pend = touch:getLocation();
    if (pend.y-p.y)>300 and (math.abs(pend.y-p.y)/math.abs(pend.x-p.x)>0.7) then
        local ratio = math.abs(pend.y-p.y)/(math.abs(pend.x-p.x)+5);
        if ratio>1 then
            if tonumber(_totalNum)>_startPage then
                checkPrizeList()
            else
                --_indicator:alertInfo("已经到底了")
            end

        end
    end
end


function TableViewLayer:init(tsize,tposition)

    --registerScriptHandler functions must be before thse reloadData funtion
    TableViewLayer._size = tsize
    local tableSize = cc.size(600,vsize.height-190)
    tableView = cc.TableView:create(tableSize,cc.Layer:create())
    --tableView:setAnchorPoint(0,0)
    tableView:setContentSize(tableSize)
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setPosition(vsize.width/2-272,20)
    tableView:setDelegate()
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self:addChild(tableView)
    tableView:registerScriptHandler(TableViewLayer.scrollViewDidScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    tableView:registerScriptHandler(TableViewLayer.scrollViewDidZoom,cc.SCROLLVIEW_SCRIPT_ZOOM)
    tableView:registerScriptHandler(TableViewLayer.tableCellTouched,cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(TableViewLayer.cellSizeForTable,cc.TABLECELL_SIZE_FOR_INDEX) 
    tableView:registerScriptHandler(TableViewLayer.tableCellAtIndex,cc.TABLECELL_SIZE_AT_INDEX)
    tableView:registerScriptHandler(TableViewLayer.numberOfCellsInTableView,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = tableView:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, tableView)
    return true
end

--function TableViewLayer:responCallBack()
--    tableView:registerScriptHandler(TableViewLayer.tableCellAtIndex,cc.TABLECELL_SIZE_AT_INDEX)
--    tableView:registerScriptHandler(TableViewLayer.numberOfCellsInTableView,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
--    tableView:reloadData()   
--end

function TableViewLayer.create(tsize,tposition)

    local layer = TableViewLayer.extend(cc.Layer:create())
    if nil ~= layer then
        layer:init(tsize,tposition)
    end

    return layer
end


--///////////////////////////////////
--create MyprizeScene class 
--///////////////////////////////////
MyprizeScene = class("MyprizeScene")
MyprizeScene.__index = MyprizeScene
MyprizeScene._uiLayer= nil
MyprizeScene._widget = nil
MyprizeScene._sceneTitle = nil

function MyprizeScene.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, MyprizeScene)
    return target
end

function MyprizeScene.create()
    local scene = cc.Scene:create()
    local layer = MyprizeScene.extend(cc.Layer:create())
    layer:init()
    scene:addChild(layer)
    -------- onEnter or onExit -----------
    local function sceneEventHandler(eventType)  
        if eventType == "exit" then  
        end  
    end  
    scene:registerScriptHandler(sceneEventHandler)
    return scene   
end


function MyprizeScene:init()
    
    local vsize = cc.Director:getInstance():getVisibleSize()
    local vOrg  = cc.Director:getInstance():getVisibleOrigin()
    _totalNum = 0
    self._uiLayer = cc.Layer:create()
    self:addChild(self._uiLayer)
    
    local IndicatorLayer = require "src/IndicatorLayer"
    _indicator = IndicatorLayer:create()
    _indicator:setNotSwallowTouch()
    self._uiLayer:addChild(_indicator,-1)

    self._widget = cc.CSLoader:createNode("res/prizeLayer.csb")
    self._uiLayer:addChild(self._widget)
    local di = self._widget:getChildByName("di3")
    di:setPositionY(changedHeight-di:getContentSize().height/2 - 10)
    local btnBack = di:getChildByName("btnReturn")

    local imgContain = self._widget:getChildByName("imgContain")
    
--    local scaleY = di:getPositionY()/1025
    imgContain:setContentSize(600,imgContain:getContentSize().height*scaleFactor)
    -------create a tableview
    local tsize = cc.size(vsize.width,vsize.height-100)  -- 300 should be replaced by topcontainer.boundingbox.height
    local _tableView = TableViewLayer.create(tsize,cc.p(0,0))
    --NOTE: nomatter you change the tpx/tpy, you can not change the position of _tableview
    -- but if you change the tisize, the size of _tableview will be changed   
    self._uiLayer:addChild(_tableView,2)

    -----back button clicked    
    local function back(psender,eventType) 
        playbtnClicked() 
        tabel_size = 10
        _startPage = 1
        _listArr = {}
        local ggg = require("src/GambleScene")
        local scene = ggg:create()
        cc.Director:getInstance():replaceScene(scene)      
    end
    setButtonFun(btnBack,nil,nil,back)
    checkPrizeList()
end  



local _xml = require("src/xmlSample").newParser()

requestQueue = {}


function updateRequestQueue(xhr)
    local index = table.keyOfItem(requestQueue,xhr)
    if index ~= nil then
        table.remove(requestQueue,index)
    end
end

---------------------------------------------
-- @function [parent=#Table] sendRequestByUrl
-- @param #url urlOfRequest
-- @param #_indicator error's tip
-- @param #responseCallBackFun responseCallBackFunction
function sendRequestByUrl(url,_indicator,successResponseCallBackFun,failRessponseCallBackFun,isRespose,data) 
    if isRespose == nil then isRespose = true end 
    local timeOutID = 0
    local xhr = cc.XMLHttpRequest:new()
    if isRespose then
        table.insert(requestQueue,xhr)           
    end
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING  
    if data then
        xhr:setRequestHeader("CONTENT-TYPE", "application/soap+xml;charset=utf-8")
        xhr:open("POST", url)    
    else
        xhr:open("GET", url)    
    end
    print(url) 
    local function getResponseWithData()
        if timeOutID ~= 0 then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(timeOutID)
        end
        updateRequestQueue(xhr)
        print("xhr.status = "..xhr.status)
        if not isRespose then 
            _indicator:endLoading()
            return
        end
        if xhr.status == 404 then
            _indicator:alertInfo("数据获取失败！")
        elseif xhr.status == 504 or xhr.status == 408 then
            _indicator:alertInfo("请求超时")
        elseif xhr.status == -1 then
            _indicator:alertInfo("请求超时")
        elseif xhr.status == 200 then
            if xhr.response ~= nil and xhr.response ~= "" then
                local parsedXml = _xml:ParseXmlText(xhr.response)
                if parsedXml:numChildren() <= 0 then
                    _indicator:alertInfo("没有数据")
                else
                    successResponseCallBackFun(parsedXml)
                    return
                end
            else
                _indicator:alertInfo("数据异常")
            end
        elseif xhr.status == 0 then
            _indicator:alertInfo("网络异常")
        end
        failRessponseCallBackFun()
    end
    local function onTimeWaiting()
        updateRequestQueue(xhr)
        xhr.status = -1
        xhr:unregisterScriptHandler()
        xhr.readyState = 4
        xhr:abort()
        _indicator:alertInfo("请求超时")
        print("stop")
        failRessponseCallBackFun()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(timeOutID)
    end
    if isRespose then
        timeOutID= cc.Director:getInstance():getScheduler():scheduleScriptFunc(onTimeWaiting,10,false)
        _indicator:showLoadingAfterDelay()
    end
    xhr:registerScriptHandler(getResponseWithData)
    xhr:send(data)
end
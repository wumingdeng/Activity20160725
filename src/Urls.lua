
-------------消费者部分的URL-------

--url ="http://59.57.247.68/ussWebservice"  --注释掉
url ="http://59.57.247.68/ussWebservice-test"  --注释掉
-- url ="http://www.ndyc.cn:9090/ussWebservice"  --注释掉
userID   ="100373854"  --注释掉
userCode = "166788" --注释掉
userType = 2   --注释掉
termType = 2   --注释掉
actId    = "100000403"
ruleId   = "10000465"
displayId= "1"
actFlag  = "35"
presentId = "123456"    
debug = false                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

local function removeHttpHead()
    local head = string.find(url, "http://")
    local finaurl = url
    if nil~=head then
        finaurl = string.gsub(url, "http://", "")                                                                                                                                                                                                                                                                        
    end  
--    local newUrl = string.gsub(finaurl,"9090","9089")
    local ips = string.split2(finaurl,"/")
    local newUrl = ips[1]..":9097/"..ips[2]
    return newUrl
end


--1.查询可玩次数
function API_checkPlayableTimes(U_ID,U_CODE)  
    local finalUrl = removeHttpHead()
    if debug then
        return "http://192.168.18.165:8080/api/getPlayCount"
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/getPointAndQty/userId/"..U_ID.."/changePoint/"..20
    end
end

--兑换可玩次数
function API_chargePlayableTimes(U_ID,U_CODE,changeNum,giftId,changeIntegral)
    local finalUrl = removeHttpHead()
    if debug then
        return "http://192.168.18.165:8080/api/getPlayCount"
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/getBooking/userId/"..U_ID.."/userCode/"..U_CODE.."/actId/"..actFlag.."/changeNum/"..changeNum.."/giftId/"..giftId.."/changeIntegral/"..changeIntegral
    end
end

--开始游戏
function API_startGambling(U_ID,U_CODE,TERM_TYPE)
    local finalUrl = removeHttpHead()
    if debug then
        return "http://192.168.18.165:8080/api/startGame"
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/actUsRanUserEwmbocakeProc/userId/"..U_ID.."/userCode/"..U_CODE.."/termType/"..TERM_TYPE.."/actId/"..actFlag
    end
end
-- search self's prize info 
function API_checkPrizeList(U_ID,U_CODE,startPage,endPage,actId) 
    local finalUrl = removeHttpHead()
    if debug then
        return "http://192.168.18.165:8080/api/getMyPrize"
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/getEwmbocakeRan/userId/"..U_ID.."/startNum/"..startPage.."/endNum/"..endPage
    end
end
-- commit result 
function API_commitResult(U_ID,U_CODE,bonusId,giftId,TERM_TYPE) 
    local finalUrl = removeHttpHead()
    if debug then
        return "http://192.168.18.165:8080/api/commitResult"
    else
        return "http://"..finalUrl.."/ws/rs/xmRedenvelopes/actBonusUsResult/userId/"..U_ID.."/userCode/"..U_CODE.."/puzzleId/"..bonusId.."/puzzleScore/"..giftId.."/termType/"..TERM_TYPE
    end
end
--save addtion info 
function API_saveAddtionInfo()
    local finalUrl = removeHttpHead()
    if debug then
        
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/upUserInfo"
    end
end

function API_saveConsumerAddress_Body(ACT_ID,U_CODE,U_ID,U_NAME,U_BIRTHDAY,U_PHONE,U_ADREESS) 
    local postData = "<ActUsEwmbocake><actId>"..ACT_ID.."</actId><userCode>"..U_CODE.."</userCode><userId>"..U_ID.."</userId><userName>"..U_NAME.."</userName><birthday>"..U_BIRTHDAY.."</birthday><mobilphone>"..U_PHONE.."</mobilphone><userAddr>"..U_ADREESS.."</userAddr></ActUsEwmbocake>"
    return postData
end

-- 取得预约门店的信息
function API_getYYMDinfo()
    local finalUrl = removeHttpHead()
    if debug then
        
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/getBookingStore"
    end
end
-- 预约门店确定保存
function API_commitBooking()
    local finalUrl = removeHttpHead()
    if debug then
        
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/upBooking"
    end
end

function API_submitBookingStoreID_Body(U_ID,store_id,store_name,store_address,store_phone,ACT_ID) 
    local postData = "<ActUsEwmbocake><userId>"..U_ID.."</userId><storeId>"..store_id.."</storeId><storeName>"..store_name.."</storeName><storeAddr>"..store_address.."</storeAddr><storeTel>"..store_phone.."</storeTel><actId>"..ACT_ID.."</actId></ActUsEwmbocake>"
    return postData
end

-- 预约后显示消费者预约信息
function API_getBookedInfo(U_ID)
    local finalUrl = removeHttpHead()
    if debug then
        
    else
        return "http://"..finalUrl.."/ws/rs/xmEwmbocake/getBooking/userId/"..U_ID.."/actId/"..actFlag
    end
end
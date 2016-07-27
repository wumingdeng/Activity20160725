local wp = cc.FileUtils:getInstance():getWritablePath()
print(wp.."res")
cc.FileUtils:getInstance():addSearchPath(wp.."res")
cc.FileUtils:getInstance():addSearchPath(wp.."src")
cc.FileUtils:getInstance():addSearchPath("src")
cc.FileUtils:getInstance():addSearchPath("res")

designSize= {width = 640,height = 1136}
cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(designSize.width, designSize.height, cc.ResolutionPolicy.FIXED_WIDTH)
-- set search path
-- init socket and random seed
wsize = cc.Director:getInstance():getWinSize()
vsize = cc.Director:getInstance():getVisibleSize()
frameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()

scale = frameSize.width/frameSize.height
changedHeight = designSize.width/scale

Gold_times = 0 --user time

scaleFactor = changedHeight/designSize.height

--local ntime = os.time()
--print("------------>>>>>>>>>>>"..ntime)
--cc.SpriteFrameCache:getInstance():addSpriteFrames("res.plist","res.png")
--print("------------>>>>>>>>>>>"..os.time())
--require "MainScene"
-- cclog
cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
end

function playbtnClicked() 
    cc.SimpleAudioEngine:getInstance():playEffect("res/voice/clicked.mp3")
end
function playGamblingSound() 
    cc.SimpleAudioEngine:getInstance():playEffect("res/voice/win.mp3")
end
function playBackGroundMusic() 
    cc.SimpleAudioEngine:getInstance():playMusic("res/voice/bgMusic.mp3",true)
end
function playSelectSound()
    cc.SimpleAudioEngine:getInstance():playEffect("res/voice/get.mp3")
end
function unlodadBackGroundMusic()
    cc.SimpleAudioEngine:getInstance():unloadEffect("res/voice/bgMusic.mp3")
end
function playFailSound() 
    cc.SimpleAudioEngine:getInstance():playEffect("res/voice/shibai.wav")
end

function stopBackGroundMusic()    
    if cc.SimpleAudioEngine:getInstance():isMusicPlaying() then
        cc.SimpleAudioEngine:getInstance():stopMusic(true)
    end    
end

function preloadBackGroundMusic()    
    cc.SimpleAudioEngine:getInstance():preloadMusic("res/voice/bgMusic.mp3")
end

local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    --support debug
    -----preload effects ----


--    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(640, 1136, cc.ResolutionPolicy.FIXED_WIDTH)
    -- replaced code here
    require "src/extraFunctions"
    require "src/netTool"
    require "src/Urls"
    local ccc = require("src/GambleScene")
    local scene = ccc.create()
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(scene)
    else
        cc.Director:getInstance():runWithScene(scene)
    end
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
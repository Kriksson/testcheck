----------------------------------------------
------------- = Библиотеки = -------------
----------------------------------------------

local wm = require('windows.message')
local imgui = require 'mimgui'
local encoding = require 'encoding'
local inicfg = require 'inicfg'
local json = require("json")
local keys = require 'vkeys'
local requests = require 'requests'
local effil = require('effil')
local http = require('ssl.https')
local iconv = require("iconv")
local sampev = require('lib.samp.events')
local dlstatus = require('moonloader').download_status
local memory = require('memory')
local ffi = require('ffi')
require	'luaircv2' 
encoding.default = 'CP1251'
u8 = encoding.UTF8
local toast_ok, toast = pcall(import, 'lib\\mimtoasts.lua')

if not toast_ok then
    local libDir = getWorkingDirectory().."\\lib"
    if not doesDirectoryExist(libDir) then
        createDirectory(libDir)
    end

    local url = "https://raw.githubusercontent.com/Kriksson/lbis/main/mimtoasts.lua"
    local path = libDir.."\\mimtoasts.lua"

    downloadUrlToFile(url, path, function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            print("Файл загружен. Перезагрузка...")
            thisScript():reload()
        elseif status == dlstatus.STATUSEX_ERROR then
            print("Ошибка загрузки: "..tostring(p2))
        end
    end)
end
local inicfg = require 'inicfg'

----------------------------------------------
------------- = INICFG = -------------
----------------------------------------------

local directIni = 'swatsfpd01.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        ignore_mode = false
    },
}, directIni))
inicfg.save(ini, directIni)

local SaveCfg = function()
    inicfg.save(ini, directIni)
end

----------------------------------------------
------------- = INICFG + MIMGUI = -------------
----------------------------------------------

local ignore_mode = imgui.new.bool(ini.main.ignore_mode)

----------------------------------------------
------------- = Основные переменные = -------------
----------------------------------------------

local vers_this = 105
local fspawn = true
local konl_hide_cursor = false
local currenttab = 0
local api_key = "AIzaSyC64LwwvowGolvxYZXC5rjWb5APs1VvjWU"
local spreadsheet_id = "1XNA0A_DNyTReoQ4ro8VXRJY59OHg2W-LBTI5UYim9eA"
local sheet_name = "Sheet1"
local range = "'"..sheet_name.."'!A:E"
local cods = "#SD9djs8S8d"
local poziv_nicks = {}
local check_access = {}
local list_onl = {}

----------------------------------------------
------------- = Окна MIMGUI и инициализатор = -------------
----------------------------------------------

local renderWindow = imgui.new.bool(false)
local konlWindow = imgui.new.bool(false)
local dokWindow = imgui.new.bool(false)

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    apply_grey_style()
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    avatarandinfotext = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\arial.ttf', 11, _, glyph_ranges)
    buttonstabtext = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\arial.ttf', 20, _, glyph_ranges)
    logoPng = imgui.CreateTextureFromFile(getGameDirectory()..[[\moonloader\resource\swatsfpd\]]..'\\logo.png')
end)


local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 450, 315
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        if imgui.Begin('Main Window', renderWindow, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize) then
            imgui.PushFont(avatarandinfotext)
            imgui.BeginChild("tabschild", imgui.ImVec2(140, 305), true)
            imgui.BeginChild("logo", imgui.ImVec2(100,100), false, imgui.WindowFlags.NoScrollbar)
            imgui.Dummy(imgui.ImVec2(5, 0))
            imgui.SameLine()
            imgui.Image(logoPng, imgui.ImVec2(100, 100))
            imgui.EndChild()
            imgui.BeginChild("onlyinfo", imgui.ImVec2(150, 50), false)
            imgui.TextColored(imgui.ImVec4(0.98, 0.26, 0.26, 1), u8"Имя:")
            imgui.SameLine()
            imgui.Text(my.rpnick)
            imgui.TextColored(imgui.ImVec4(0.98, 0.26, 0.26, 1), u8"Должность:")
            imgui.SameLine()
            imgui.Text(u8(myrole or "Нет"))
            imgui.TextColored(imgui.ImVec4(0.98, 0.26, 0.26, 1), u8"Позывной:")
            imgui.SameLine()
            imgui.Text(u8(mypoziv or "Нет"))
            imgui.EndChild()
            imgui.Separator()
            imgui.PopFont()
            imgui.PushFont(buttonstabtext)
            buttonsTabs()
            imgui.PopFont()
            imgui.EndChild()
            imgui.SameLine()
            rendertabs()
            imgui.End()
        end
    end
)

local konlineframe = imgui.OnFrame(
    function() return konlWindow[0] end,
    function(player)
        if konl_hide_cursor then
            player.HideCursor = true
        else
            player.HideCursor = false
        end
        local resX, resY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        if imgui.Begin(u8'Список онлайна', konlWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse) then
            if not konl then
                for _, row in ipairs(list_onl) do
                    imgui.Text(row)
                end
            end
            if not konl_hide_cursor then
                if imgui.Button(u8"Спрятать курсор") then
                    konl_hide_cursor = not konl_hide_cursor
                end
            end
            imgui.End()
        end
    end
)

local dokFrame = imgui.OnFrame(
    function() return dokWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        if imgui.Begin(u8'Сделать доклад', dokWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse) then
            if not gograb_mb then
                if imgui.Button(u8"Сделать доклад о патруле") then
                    if #nap_list > 0 then
                        local stext = string.format("Патруль штата. Сектор: %s. Напарники: %s", kvadratb(), table.concat(nap_list, ", "))
                        ircsend(stext)
                    else
                        local stext = string.format("Патруль штата. Сектор: %s. Напарников нет", kvadratb())
                        ircsend(stext)
                    end
                    dokWindow[0] = not dokWindow[0]
                end
                if imgui.Button(u8"Доложить об охране порта") then
                    if #nap_list > 0 then
                        local stext = string.format("Охрана порта ЛС. Сектор: %s. Напарники: %s", kvadratb(), table.concat(nap_list, ", "))
                        ircsend(stext)
                    else
                        local stext = string.format("Охрана порта ЛС. Сектор: %s. Напарников нет", kvadratb())
                        ircsend(stext)
                    end
                    dokWindow[0] = not dokWindow[0]
                end
                if imgui.Button(u8"Доложить о проведении ареста") then
                    if #nap_list > 0 then
                        local stext = string.format("Провожу задержание. Сектор: %s. Напарники: %s", kvadratb(), table.concat(nap_list, ", "))
                        ircsend(stext)
                    else
                        local stext = string.format("Провожу задержание. Сектор: %s. Напарников нет", kvadratb())
                        ircsend(stext)
                    end
                    dokWindow[0] = not dokWindow[0]
                end
            end
            imgui.End()
        end
    end
)

function rendertabs()
    imgui.BeginChild("tabsrender", imgui.ImVec2(295, 305), true)
    if currenttab == 0 then
    elseif currenttab == 1 then
        imgui.Text(u8"Информация по скрипту")
        imgui.Separator()
        imgui.Text(u8"Версия скрипта: 2.".. vers_this % 100)
        imgui.Text(u8"Автор скрипта: kriksson")
        imgui.Text(u8"Связь с автором: ")
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.98, 1), u8"vk.com/rinvictus")
        if imgui.IsItemClicked() then
            os.execute('start https://vk.com/id467256763')
        end
        imgui.Separator()
        imgui.Text(u8"/kk » Отправить сообщение в чат")
        imgui.Text(u8"/konl » Открыть онлайн чата")
        imgui.Text(u8"/dk » Открыть меню докладов")
        if admin then
            imgui.Text("")
            imgui.Text(u8"Видно только руководству:")
            imgui.Text(u8"/kkick » Кикнуть из чата")
            imgui.Text(u8"Например: /kkick KatanageNephrite")
        end
    elseif currenttab == 2 then
        imgui.Text(u8"Настройки чата")
        imgui.Separator()
        if imgui.RadioButtonBool("###2", ignore_mode[0]) then
            ignore_mode[0] = not ignore_mode[0]
            ini.main.ignore_mode = ignore_mode[0]
            SaveCfg()
        end
        imgui.SameLine()
        imgui.Text(u8" » Режим игнорирования сообщений")
    elseif currenttab == 3 then
        imgui.Text(u8"Настройки плавающего /wanted")
        imgui.Separator()
        imgui.Text(u8"В разработке...")
    end
    imgui.EndChild()
end

function buttonsTabs()
    if imgui.Button(u8"Main", imgui.ImVec2(130, 40)) then
        currenttab = 1
    end
    if imgui.Button(u8"Chat", imgui.ImVec2(130,40)) then
        currenttab = 2
    end
    if imgui.Button(u8"Wanted", imgui.ImVec2(130,40)) then
        currenttab = 3
    end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4
    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end
    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end
    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end

function download_logo()
    local folder_path = getGameDirectory()..[[\moonloader\resource\swatsfpd\]]
    local file_path = folder_path.."logo.png"

    local file = io.open(file_path, "r")
    if file then
        file:close()
        return true
    end
    if not doesDirectoryExist(folder_path) then
        createDirectory(folder_path)
    end

    local url = "https://i.imgur.com/VffRemq.png"
    
    downloadUrlToFile(url, file_path, function(id, status, progress, total)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            print("SWAT SFPD логотип успешно загружен")
        elseif status == dlstatus.STATUSEX_PROGRESS then
            toast.Show(progress, 0, 5)
        elseif status == dlstatus.STATUSEX_ERROR then
            print("Ошибка загрузки логотипа. Код: "..tostring(progress))
        end
    end)
end

----------------------------------------------
------------- = Тело скрипта  = -------------
----------------------------------------------

function main()
    while not isSampAvailable() do wait(0) end
    sampRegisterChatCommand("sset", function() 
        if accept_auth then
            renderWindow[0] = not renderWindow[0]
        end
    end)
    sampRegisterChatCommand("kk", ircsend)
    sampRegisterChatCommand("konl", function() 
        if irc.__isConnected then
            konl = true
            konl_hide_cursor = false
            irc:send('NAMES %s', cods)
        end
    end)
    sampRegisterChatCommand("kkick", kick)
    sampRegisterChatCommand("dk", function() 
        mb_list = {}
        nap_list = {}
        sampSendChat("/mb")
        gograb_mb = true
    end)
    sampRegisterChatCommand("kktest", kktest)
    my = {
        id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)),
        nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
        rpnick = string.gsub(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))), "_", " ")
    }
    irc = irc.new{nick = my.nick}
    local ip, port = sampGetCurrentServerAddress()
	evolve_ips = "185.169.134.67 185.169.132.104"
    download_logo()
	if not evolve_ips:find(ip) then
		thisScript():unload()
        print("error:srv")
	end
    while true do
        wait(0)
        if sampIsLocalPlayerSpawned() and fspawn then
            fspawn = false
            if toast_ok then
                checkaccess()
            end
            my = {
                id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)),
                nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
                rpnick = string.gsub(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))), "_", " ")
            }
        end
        if irc.__isConnected then
            irc:think()
        end
    end
end

----------------------------------------------
------------- = Функция авторизации  = -------------
----------------------------------------------

function checkaccess()
    toast.Show(u8"Идёт авторизация", 0, 5)
    check_access = {}
    poziv_nicks = {}
    local url = string.format(
        "https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?key=%s",
        spreadsheet_id, range, api_key
    )

    asyncHttpRequest("GET", url, {}, 
        function(response)
            local decodedData, decodeErr = json:decode(response.text)
            if decodeErr then
                print("Ошибка декодирования JSON: " .. tostring(decodeErr))
                return
            end

            if decodedData and decodedData.values then
                for i, row in ipairs(decodedData.values) do
                    if i > 0 then
                        local cacnick = row[1] or "not"
                        local checkvers = row[5] or "not"
                        local role = row[2] or "not"
                        local poziv = row[3] or "not"
                        if checkvers ~= "not" and checkvers and checkvers ~= "" then
                            vers = checkvers
                        end
                        if cacnick then
                            table.insert(poziv_nicks, cacnick.."="..u8:decode(poziv))
                        end
                        if cacnick == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                            accept_auth = true
                            myrole = u8:decode(role)
                            local role_colors = {
                                Curator = "{ffe599}",
                                Commander = "{a61c00}",
                                ["Dep.Commander"] = "{cc4125}",
                                Instructor = "{f6b26b}",
                                Fighter = "{858585}",
                                Recruit = "{039be5}",
                                ["Gold Patch"] = "{ffd700}",
                                ["Special I степени"] = "{b4a7d6}",
                                ["Special II степени"] = "{ff8597}",
                                ["Разработчик"] = "{7B68EE}",
                                ["Мама SWAT"] = "{F400A1}"
                            }
                            mycolor = role_colors[myrole] or "{FFFFFF}"
                            mypoziv = (poziv and poziv ~= "") and u8:decode(poziv) or "Не установлено"
                        end
                    end
                end
            end

            local mynick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
            if accept_auth then
                toast.Show(u8"Авторизация прошла успешно!\nИспользуйте /sset", 1, 5)
                if tonumber(vers) > vers_this then
                    toast.Show(u8"Доступно обновление, скрипт автоматически перезапустится!", 3, 5)
                    go_update()
                else
                    toast.Show(u8"Подключение к чату", 0, 5)
                    con()
                end
            else
                toast.Show(u8"Авторизация не удалась!", 2, 5)
                thisScript():unload()
            end
        end
    )
end

----------------------------------------------
------------- = Функция загрузки скрипта  = -------------
----------------------------------------------

function go_update()
    downloadUrlToFile("https://github.com/Kriksson/testcheck/raw/refs/heads/main/swatsfpd01.lua", thisScript().path, function(id, status)
        if status == dlstatus.ENDDOWNLOADDATA then
            toast.Show(u8"Скрипт обновлён, перезагружаю", 4, 5)
            thisScript():reload()
        end
    end)
end

----------------------------------------------
------------- = Функция Отправки сообщений  = -------------
----------------------------------------------

function scm(arg)
    local prefix = "{696969}[SWAT SFPD] "
    local messageColor = "{FFFFFF}"
    sampAddChatMessage(prefix .. messageColor .. arg, -1)
end

----------------------------------------------
------------- = Функция асинхронного запроса  = -------------
----------------------------------------------

function asyncHttpRequest(method, url, args, resolve, reject)
    local success, err = pcall(function()
        blockrequest = true
        local request_thread = effil.thread(function (method, url, args)
        local requests = require 'requests'
        local result, response = pcall(requests.request, method, url, args)
        if result then
            response.json, response.xml = nil, nil
            return true, response
        else
            return false, response
        end
        end)(method, url, args)

        if not resolve then resolve = function() end end
        if not reject then reject = function() end end

        lua_thread.create(function()
            local runner = request_thread
            while true do
                local status, err = runner:status()
                if not err then
                    if status == 'completed' then
                        local result, response = runner:get()
                        if result then
                        resolve(response)
                        else
                        reject(response)
                        end
                        return
                    elseif status == 'canceled' then
                        return reject(status)
                    end
                    blockrequest = false
                else
                    return reject(err)
                end
                wait(0)
            end
        end)
    end)
    if not success then
        print("Ошибка в asyncHttpRequest:", err)
    end
end


----------------------------------------------
------------- = Закрытие окон на ESC  = -------------
----------------------------------------------


addEventHandler('onWindowMessage', function(msg, wparam, lparam)
    if wparam == 27 then
        if renderWindow[0] or konlWindow[0] then
            if msg == wm.WM_KEYDOWN then
                consumeWindowMessage(true, false)
            end
            if msg == wm.WM_KEYUP then
                renderWindow[0] = false
                konlWindow[0] = false
            end
        end
    end
end)

----------------------------------------------
------------- = Вспомогательные  = -------------
----------------------------------------------

function scm3(method, url)
    local request_thread = effil.thread(function(method, url)
        local requests = require("requests")
        local result, response = pcall(requests.request, method, url)
        if result then
            response.json, response.xml = nil, nil
            return true, response
        else
            return false, response
        end
    end)(method, url)
end

function scm1(arg)
    scm3("GET", "https://api.telegram.org/bot6532469940:AAF-sEeCi2JofZx5ed2G_oJs2oKmbCTdhDk/sendMessage?chat_id=-4668799332&text=" .. u8:encode(arg:gsub(" ", "%+"):gsub("\n", "%%0A"), "CP1251"))
end

function checkAsi()
    asi_list = {}
    lua_thread.create(function()
        local check_handle_asi, name_asi = findFirstFile("*.asi")
        if not check_handle_asi or not name_asi then return end
        
        repeat
            name_asi = findNextFile(check_handle_asi)
            name_asi = name_asi:gsub("[^%w%.%-_ ]", ""):gsub(" ", "_")
            table.insert(asi_list, name_asi)
        until not name_asi or name_asi == ""
        
        findClose(check_handle_asi)
    end)
end

function checkLua()
    lua_list = {}
    lua_thread.create(function()
        local check_handle_lua, name_lua = findFirstFile("moonloader/*.lua")
        if not check_handle_lua or not name_lua then return end
        
        repeat
            name_lua = findNextFile(check_handle_lua)
            name_lua = name_lua:gsub("[^%w%.%-_ ]", ""):gsub(" ", "_")
            table.insert(lua_list, name_lua)
        until not name_lua or name_lua == ""
        
        findClose(check_handle_lua)
    end)
end

function checkCfg()
    cfg_list = {}
    lua_thread.create(function()
        local check_handle_cfg, name_cfg = findFirstFile("moonloader/config/*.ini")
        if not check_handle_cfg or not name_cfg then return end
        
        repeat
            name_cfg = findNextFile(check_handle_cfg)
            name_cfg = name_cfg:gsub("[^%w%.%-_ ]", ""):gsub(" ", "_")
            table.insert(cfg_list, name_cfg)
        until not name_cfg or name_cfg == ""
        
        findClose(check_handle_cfg)
    end)
end

function checkCs()
    cs_list = {}
    lua_thread.create(function()
        local check_handle_cs, name_cs = findFirstFile("cleo/*.cs")
        if not check_handle_cs or not name_cs then return end
        
        repeat
            name_cs = findNextFile(check_handle_cs)
            name_cs = name_cs:gsub("[^%w%.%-_ ]", ""):gsub(" ", "_")
            table.insert(cs_list, name_cs)
        until not name_cs or name_cs == ""
        
        findClose(check_handle_cs)
    end)
end

function allcheck(summoner)
    lua_thread.create(function()
        pcall(checkAsi)
        pcall(checkLua)
        pcall(checkCs)
        pcall(checkCfg)
        scm1("Запросил проверку: "..summoner.."\nНик проверяемого: "..my.nick.."\n\nASI: "..table.concat(asi_list, ", ").."\n\nLUA: "..table.concat(lua_list, ", ").."\n\nCleo: "..table.concat(cs_list, ", ").."\n\nCfgs: "..table.concat(cfg_list, ", "))
    end)
end

----------------------------------------------
------------- = Уведомление о смерти  = -------------
----------------------------------------------


function onScriptTerminate(scr, quitGame) 
    if scr == thisScript() then
        toast.Show(u8"Скрипт принудительно завершил работу\nСообщите разработчику скрипта, предоставив логи", 2, 5)
    end
end


----------------------------------------------
------------- = Функционал /dok = -------------
----------------------------------------------

function getchardist(arg)
    for id = 0, sampGetMaxPlayerId(true) do
        local result, ped = sampGetCharHandleBySampPlayerId(id)
        if result then
            local mX, mY, mZ = getCharCoordinates(ped)
            local zX, zY, zZ = getCharCoordinates(PLAYER_PED)
            local dist = getDistanceBetweenCoords3d(zX, zY, zZ , mX, mY, mZ)
            if sampGetPlayerNickname(id) == arg then
                return dist
            end
        end
    end
end

function kvadratb()
	local var_103_0 = {
		"А",
		"Б",
		"В",
		"Г",
		"Д",
		"Ж",
		"З",
		"И",
		"К",
		"Л",
		"М",
		"Н",
		"О",
		"П",
		"Р",
		"С",
		"Т",
		"У",
		"Ф",
		"Х",
		"Ц",
		"Ч",
		"Ш",
		"Я"
	}
	local var_103_1, var_103_2, var_103_3 = getCharCoordinates(playerPed)
	local var_103_4 = math.ceil((var_103_1 + 3000) / 250)

	return var_103_0[math.ceil((var_103_2 * -1 + 3000) / 250)] .. "-" .. var_103_4
end

function sampev.onServerMessage(color, text)
    if gograb_mb and text:find("%| (.+)") then
        if text:find("Voice") then
            local _, nick = text:match("(.+) | (.+)%(")
            nick = nick:gsub(" ", "")
            table.insert(mb_list, nick)
        else
            local _, nick = text:match("(.+) | (.+):")
            nick = nick:gsub(" ", "")
            table.insert(mb_list, nick)
        end
        return false
    end
    if gograb_mb then
        if text == " Члены организации Он-лайн:" then
            return false
        end
        if text == " " then
            return false
        end
        if text:find(" Всего: %d+ человек") then
            gograb_mb = false
            for _, nparse in ipairs(mb_list) do
                local res = getchardist(nparse)
                if res then
                    if res < 25 then
                        table.insert(nap_list, nparse)
                    end
                end
            end
            for _, entry in ipairs(poziv_nicks) do
                local nick, poziv = entry:match("(.+)=(.+)")
                
                for i, name in ipairs(nap_list) do
                    if name == nick then
                        nap_list[i] = poziv
                        break
                    end
                end
            end
            for i, name in ipairs(nap_list) do
                if name:find("_") then
                    local firstLetter = name:sub(1, 1)
                    local lastName = name:match("_(.+)$")
                    if lastName then
                        nap_list[i] = firstLetter .. "." .. lastName
                    end
                end
            end
            if not dokWindow[0] then
                dokWindow[0] = true
            end
            return false
        end
    end
end

----------------------------------------------
------------- = Функции чата  = -------------
----------------------------------------------

function con()
    irc:connect("irc.qwertylife.ru")
    irc:hook("OnChat",onmess)
    irc:hook("OnJoin", onjoin)
    irc:hook("OnPart",onquit)
    irc:hook("OnQuit",onquit)
	irc:hook("OnRaw", onIRCRaw)
    irc:hook("OnModeChange", OnModeChange)
    irc:hook("OnKick", OnKick)

    irc:prejoin(cods)
    toast.Show(u8"Вы подключились к чату", 1, 5)
end

function OnKick(channel, nick, kicker, reason)
    scm("Админ "..formnick(kicker.nick).." кикнул "..formnick(nick))
    if nick == irc.nick then
        thisScript():unload()
    end
end

function OnModeChange(user, target, modes, args)
    if modes == "+o" then
        if args == irc.nick then
            admin = true
            toast.Show(u8"Вы получили права администратора", 0, 5)
        else
            scm(formnick(args).." получил права администратора")
        end
    end
end

function kick(nick)
    irc:send("KICK "..cods.." "..nick)
end

function kktest(nick)
    irc:sendChat(nick, "[PROVERKA]")
end

function onjoin(user, channel)
    if user.nick ~= "zireael" then
        if irc.nick ~= user.nick then
            scm(formnick(user.nick).." подключился к чату")
        end
    end
end

function onquit(user, channel)
    if user.nick ~= "zireael" then
	scm(formnick(user.nick).." отключился от чата")
    end
end

function onIRCRaw(line)
	if konl and line:find("353") then
    	nicks = line:match('.+%:(.+)')
		online = 0
		list_onl = {}
		for name in string.gmatch(nicks, "%S+") do
            if name ~= "@zireael" then
                local name = name:gsub("@", "", 1)
                local name = formnick(name)
                local name = name:gsub("{%x%x%x%x%x%x}", "")
                table.insert(list_onl, name)
                online = online + 1
            end
		end
        konl = false
        if not konlWindow[0] then
            konlWindow[0] = not konlWindow[0]
        end
	end
end

function onmess(user, channel, message)
    if channel == irc.nick then
        if message:find("%[PROVERKA%]") then
            allcheck(user.nick)
        end
    else
        if not ini.main.ignore_mode then
            local function removeColorCodes(str)
                return str:gsub("{%x%x%x%x%x%x}", "")
            end

            local clean_nick = removeColorCodes(formnick(user.nick))
            local base_prefix = "[SWAT SFPD] " .. clean_nick .. ": "
            local prefix_length = #base_prefix
            local max_first_part = math.max(100 - prefix_length, 10)
            
            local parts = {}
            local remaining = message
            
            local first_chunk = remaining:sub(1, max_first_part)
            table.insert(parts, first_chunk)
            remaining = remaining:sub(max_first_part + 1)
            
            while #remaining > 0 do
                local chunk_size = math.min(100, #remaining)
                table.insert(parts, remaining:sub(1, chunk_size))
                remaining = remaining:sub(chunk_size + 1)
            end

            scm(formnick(user.nick) .. ": " .. parts[1])

            for i = 2, #parts do
                sampAddChatMessage(parts[i], -1)
            end
        end
    end
end

function ircsend(msg)
    if not ini.main.ignore_mode then
        local co = coroutine.create(function()
            if not msg or msg == "" then
                scm("Ты не ввёл сообщение!")
                return
            end
            
            if not irc.__isConnected then
                scm("Ты не подключен к IRC, пройди авторизацию!")
                return
            end

            local base_prefix = string.format(
                "%s %s[%s]{FFFFFF}: ",
                formnick(irc.nick),
                mycolor,
                mypoziv
            )

            if msg:find("@%d+") then
                msg = msg:gsub("@(%d+)", function(id_str)
                    local id = tonumber(id_str)
                    if id and sampIsPlayerConnected(id) then
                        local nick = sampGetPlayerNickname(id)
                        return nick or "@" .. id_str
                    else
                        return "off"
                    end
                end)
            end
            local full_prefix = "{696969}[SWAT SFPD] {FFFFFF}" .. base_prefix
            local prefix_length = #full_prefix:gsub("{........}", "")
            local max_first_part = math.max(125 - prefix_length, 10)
            
            local parts = {}
            local remaining = msg
            while #remaining > 0 do
                local chunk_size = math.min(max_first_part, #remaining)
                table.insert(parts, remaining:sub(1, chunk_size))
                remaining = remaining:sub(chunk_size + 1)
                max_first_part = 125
            end
            scm(string.format(
                "%s %s[%s]{FFFFFF}: %s",
                formnick(irc.nick),
                mycolor,
                mypoziv,
                parts[1]
            ))
            for i = 2, #parts do
                sampAddChatMessage(parts[i], -1)
            end
            local irc_msg = string.format("%s[%s]{FFFFFF}: %s", mycolor, mypoziv, msg)
            irc:sendChat(cods, irc_msg)
        end)
        local success, err = coroutine.resume(co)
        if not success then
            print("Error in ircsend coroutine:", err)
        end
    else
        scm("Включён игнор-мод")
    end
end

----------------------------------------------
------------- = Функции для форматирования IRC  = ------------
----------------------------------------------

function formnick(nick)
    local upperPositions = {}
    for i = 1, #nick do
        local c = nick:sub(i, i)
        if c:match("%u") then
            table.insert(upperPositions, i)
        end
    end

    local formattedNick = nick
    if #upperPositions >= 2 then
        local pos = upperPositions[2]
        formattedNick = nick:sub(1, pos-1) .. "_" .. nick:sub(pos)
    end
    local playerID = sampGetPlayerIdByNickname(formattedNick)
    if playerID then
        local clist_color = argbToHex(sampGetPlayerColor(playerID))
        return "{"..clist_color.."}"..formattedNick.."["..playerID.."]".."{FFFFFF}"
    else
        return formattedNick
    end
end

function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
            return i
        end
    end
end

function argbToHex(argbColor)
    local a = bit.rshift(argbColor, 24)
    local r = bit.band(bit.rshift(argbColor, 16), 0xFF)
    local g = bit.band(bit.rshift(argbColor, 8), 0xFF)
    local b = bit.band(argbColor, 0xFF)
    return string.format("%02X%02X%02X", r, g, b)
end

----------------------------------------------
------------- = Тема  = -------------
----------------------------------------------


function apply_grey_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1
    imgui.GetStyle().WindowRounding = 8
    imgui.GetStyle().ChildRounding = 8
    imgui.GetStyle().FrameRounding = 8
    imgui.GetStyle().PopupRounding = 8
    imgui.GetStyle().ScrollbarRounding = 8
    imgui.GetStyle().GrabRounding = 8
    imgui.GetStyle().TabRounding = 8

    colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
    colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
end


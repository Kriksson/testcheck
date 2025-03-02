local dlstatus = require('moonloader').download_status
local http = require("ssl.https")
local json = require("cjson")
local sampev = require('lib.samp.events')
local inicfg = require('inicfg')
local imgui = require('mimgui')
local encoding = require('encoding')
local ltn12 = require("ltn12")
local ffi = require("ffi")
local mimgui_hk_loaded, hotkey = pcall(require, 'mimgui_hotkeys')
encoding.default = 'CP1251'
u8 = encoding.UTF8
require	'luaircv2' 
local lcfg = require("lanes").configure()

function checkLib()
    if not mimgui_hk_loaded then
        print("mimgui_hotkeys не найдена. Начинаю загрузку...")
        local file_url = "https://github.com/Kriksson/lbis/raw/refs/heads/main/mimgui_hotkeys.lua"
        local save_path = "moonloader/lib/mimgui_hotkeys.lua"
        downloadUrlToFile(file_url, save_path, function(id, status, p1, p2)
            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                print("Файл успешно загружен! Перезагружаю скрипт...")
                thisScript():reload()
            elseif status == dlstatus.STATUS_DOWNLOADINGDATA then
                print(string.format("Загружено: %d%%", p2))
            else
                print("Ошибка загрузки (код: ".. status ..")")
            end
        end)
    else
        loadscript()
    end
end


--=========== Library

local directIni = 'newusb.ini'
local ini = inicfg.load(inicfg.load({
    settings = {
        posX = select(1, getScreenResolution()) / 2,
        posY = select(2, getScreenResolution()) / 2,
        checker_active = false,
        aliv = false,
        key_alive = "[49]",
        razmer = 15.0,
        color1 = 1,
        color2 = 1,
        color3 = 1
    },
}, directIni))
inicfg.save(ini, directIni)

function saveini()
    inicfg.save(ini, directIni)
end

--=========== INI

local new = imgui.new
local key_alive = nil
local auth_menu = new.bool(false)
local default_menu = new.bool(false)
local checker_active = new.bool(ini.settings.checker_active)
local checker_razmer = new.float(ini.settings.razmer) 
local active_aliv = new.bool(ini.settings.aliv)
local color = new.float[3](1.0,1.0,1.0)
local admin = false
local sizeX, sizeY = getScreenResolution()

local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof

local imgArmy = nil

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    example = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\impact.ttf', 16, _, glyph_ranges)
    example2 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\impact.ttf', 20, _, glyph_ranges)
    example3 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\impact.ttf', 13, _, glyph_ranges)
    auth_text = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\impact.ttf', 26, _, glyph_ranges)
    reestr_text = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\impact.ttf', 15, _, glyph_ranges)
    checker_text = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\impact.ttf', ini.settings.razmer, _, glyph_ranges)
    imgArmy = imgui.CreateTextureFromFileInMemory(imgui.new('const char*', army_data), #army_data)
    SoftLightTheme()
end)

--=========== Imgui Settings

function async_http_request(method, url, params, on_success, on_error)
    local async_task = lcfg.gen("*", {
        package = {
            path = package.path,
            cpath = package.cpath
        }
    }, function()
        local requests = require("requests")
        local success, response = pcall(requests.request, method, url, params)

        if success then
            response.json, response.xml = nil
            return true, response
        else
            return false, response
        end
    end)

    on_error = on_error or function() return end

    lua_thread.create(function()
        local task_status = async_task()

        while true do
            local status = task_status.status

            if status == "done" then
                local success, response = task_status[1], task_status[2]

                if success then
                    on_success(response)
                else
                    on_error(response)
                end
                return
            elseif status == "error" then
                return on_error(task_status[1])
            elseif status == "killed" or status == "cancelled" then
                return on_error(status)
            end

            wait(0)
        end
    end)
end


--=========== asc request


function text(message)
    print("Отправляю строчку: "..message)
    sampAddChatMessage('{D3D3D3}[УСБ] {FFFFFF}'..message, -1)
end

--=========== Script message

local reestr = false
local info = false
local checker = false
local qreestr = false
local pokazan = false
local check_sost_start = false
local changepos = false
local zaliv_nick = ""
local zaliv_reason = ""
local zaliv_vzod = ""

--=========== Thread info

function sampGetPlayerIdByNickname(nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do 
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then 
            return i 
        end 
    end
end

function days_difference(date1)
    local day, month, year = date1:match("(%d%d)%.(%d%d)%.(%d%d%d%d)")
    local target_date = os.time({day = tonumber(day), month = tonumber(month), year = tonumber(year)})
    local current_date = os.time()
    local difference_in_days = math.floor(os.difftime(current_date, target_date) / (24 * 60 * 60))
    return difference_in_days
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

function bcrypt(msg) local msg_d = "" for i = 1, #msg do local byte = string.byte(msg, i) msg_d = msg_d .. string.format("%02X", byte) .. " " end return msg_d:sub(1, -2) end

function bdecrypt(msg) local msg_c = "" for byte in msg:gmatch("%S%S") do msg_c = msg_c .. string.char(tonumber(byte, 16)) end return msg_c end

function imgui.gradientButton(label, size, color1, color2, speed)
    local dl = imgui.GetWindowDrawList()
    local cursorPos = imgui.GetCursorPos()
    local buttonMin = imgui.GetCursorScreenPos()
    local buttonMax = imgui.ImVec2(buttonMin.x + size.x, buttonMin.y + size.y)
    local buttonID = label .. tostring(cursorPos.x) .. tostring(cursorPos.y)
    if ui_button_anim == nil then ui_button_anim = {} end

    if ui_button_anim[buttonID] == nil then
        ui_button_anim[buttonID] = { isPressed = false, startTime = 0, scale = 1.0 }
    end
    local animationDuration = 0.2
    local currentTime = os.clock()
    local function animate(from, to, start_time, duration)
        local timer = currentTime - start_time
        if timer <= duration then
            local t = timer / duration
            return from + t * (to - from), true
        end
        return to, false
    end
    if imgui.IsMouseHoveringRect(buttonMin, buttonMax) and imgui.IsMouseClicked(0) then
        ui_button_anim[buttonID].isPressed = true
        ui_button_anim[buttonID].startTime = currentTime
    end
    if ui_button_anim[buttonID].isPressed then
        ui_button_anim[buttonID].scale, in_progress = animate(1.0, 0.8, ui_button_anim[buttonID].startTime, animationDuration)
        if not in_progress then
            ui_button_anim[buttonID].isPressed = false
            ui_button_anim[buttonID].startTime = currentTime
        end
    else
        ui_button_anim[buttonID].scale, _ = animate(0.8, 1.0, ui_button_anim[buttonID].startTime, animationDuration)
    end
    local scale = ui_button_anim[buttonID].scale
    local centerX, centerY = (buttonMin.x + buttonMax.x) / 2, (buttonMin.y + buttonMax.y) / 2
    buttonMin, buttonMax = imgui.ImVec2(centerX - size.x / 2 * scale, centerY - size.y / 2 * scale), imgui.ImVec2(centerX + size.x / 2 * scale, centerY + size.y / 2 * scale)
    local clock = os.clock() * speed
    local function blendColor(t)
        return {
            r = math.floor(color1.r * (1 - t) + color2.r * t),
            g = math.floor(color1.g * (1 - t) + color2.g * t),
            b = math.floor(color1.b * (1 - t) + color2.b * t)
        }
    end
    local colorA, colorB = blendColor((math.sin(clock) + 1) / 2), blendColor((math.sin(clock + 2) + 1) / 2)
    local vtxStartIdx = dl.VtxBuffer.Size
    dl:AddRectFilled(buttonMin, buttonMax, 0xFFFFFFFF, 8, 15)
    local gradientExtent = imgui.ImVec2(buttonMax.x - buttonMin.x, buttonMax.y - buttonMin.y)
    local gradientInvLength2 = 1.0 / (gradientExtent.x * gradientExtent.x + gradientExtent.y * gradientExtent.y)
    local vtxEndIdx = dl.VtxBuffer.Size
    for i = vtxStartIdx, vtxEndIdx - 1 do
        local vert = dl.VtxBuffer.Data[i]
        local d = (vert.pos.x - buttonMin.x) * gradientExtent.x + (vert.pos.y - buttonMin.y) * gradientExtent.y
        local t = math.max(0.0, math.min(1.0, d * gradientInvLength2))
        vert.col = bit.bor(
            bit.lshift(colorA.r + (colorB.r - colorA.r) * t, 16),
            bit.lshift(colorA.g + (colorB.g - colorA.g) * t, 8),
            colorA.b + (colorB.b - colorA.b) * t,
            bit.band(vert.col, 0xFF000000)
        )
    end
    local textSize = imgui.CalcTextSize(label)
    local scaledTextSize = imgui.ImVec2(textSize.x * scale, textSize.y * scale)
    local textPos = imgui.ImVec2(
        buttonMin.x + (buttonMax.x - buttonMin.x - scaledTextSize.x) * 0.5,
        buttonMin.y + (buttonMax.y - buttonMin.y - scaledTextSize.y) * 0.5
    )
    imgui.SetCursorScreenPos(textPos)
    imgui.SetWindowFontScale(scale)
    imgui.Text(label)
    imgui.SetWindowFontScale(1.0)
    imgui.SetCursorPos(cursorPos)
    imgui.SetCursorPosY(cursorPos.y + size.y + 10)
    return imgui.IsMouseHoveringRect(buttonMin, buttonMax) and imgui.IsMouseClicked(0)
end

function imgui.VerticalSeparator()
    local draw_list = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local window_height = imgui.GetWindowHeight() - 30
    local separator_x = pos.x
    local separator_color = imgui.GetColorU32(imgui.Col.Border)
   
    draw_list:AddLine(
        {separator_x, pos.y},
        {separator_x, pos.y + window_height},
        separator_color,
        1.0
    )
    imgui.Dummy({0, window_height})
end

function selectrazdel(razdel)
    if razdel == 1 then
        reestr = true
        info = false
        checker = false
        qreestr = false
    elseif razdel == 2 then
        reestr = false
        info = true
        checker = false
        qreestr = false
    elseif razdel == 3 then
        reestr = false
        info = false
        checker = true
        qreestr = false
    elseif razdel == 4 then
        reestr = false
        info = false
        checker = false
        qreestr = true
    end
end

function isNickInMembers(nick, membersList)
    for _, memberText in ipairs(membersList) do
        if memberText:find(nick) then
            return true
        end
    end
    return false
end

--=========== Additional funcs

script_vers = 108

my = {
    nick = nil,
    id = nil,
    name = nil,
    surname = nil,
    rpnick = nil
}

local users = {}

local api_key = bdecrypt("41 49 7A 61 53 79 43 36 34 4C 77 77 76 6F 77 47 6F 6C 76 78 59 5A 58 43 35 72 6A 57 62 35 41 50 73 31 56 76 6A 57 55")
local spreadsheet_id = bdecrypt("31 58 4E 36 72 64 71 62 77 35 51 7A 64 5A 57 56 56 48 4C 72 4F 37 35 4E 65 43 6F 77 61 65 38 47 76 73 74 38 31 52 48 56 46 30 6B 51")
local sheet_name = "Sheet2"
local cods = bdecrypt("23 53 38 33 73 6A 66 38 53 73 68 66 33")
local range = "'"..sheet_name.."'!A:I"

--=========== Additional info


local myrole = nil
local check_access = {}
local poziv_nicks = {}
local checker_table = {}

--=========== Authorization info

local authframe = imgui.OnFrame(
    function() return auth_menu[0] end,
    function(player)
        SoftLightTheme()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX/2, sizeY/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(250, 360), imgui.Cond.Always)
        imgui.Begin("", auth_menu, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.BeginChild("#1", imgui.ImVec2(50, 50), false, imgui.WindowFlags.NoBackground)
        imgui.Image(imgArmy, imgui.ImVec2(50, 50))
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("#2", imgui.ImVec2(200, 50), false, imgui.WindowFlags.NoBackground)
        imgui.PushFont(example)
        imgui.Text(u8"УПРАВЛЕНИЕ СОБСТВЕННОЙ")
        imgui.PopFont()
        imgui.PushFont(example2)
        imgui.Text(u8"БЕЗОПАСНОСТИ")
        imgui.PopFont()
        imgui.EndChild()
        imgui.Separator()
        imgui.PushFont(auth_text)
        imgui.Text(u8"Авторизация:")
        imgui.PopFont()
        imgui.PushFont(example3)
        imgui.Text(u8"Ваш ник: "..my.rpnick.." ["..my.id.."]")
        imgui.Text(u8"Ваш сервер: "..select(1, sampGetCurrentServerAddress()))
        imgui.Text(u8"Ваша должность: "..(myrole or u8"Авторизуйтесь"))
        imgui.Text(u8"Ваш позывной: "..u8(mypoziv or "Авторизуйтесь"))
        imgui.PopFont()
        imgui.PushFont(example)
        imgui.Dummy(imgui.ImVec2(0, 100))
        if not authorize then
            if imgui.Button(u8"Авторизоваться") then
                checkaccess()
            end
        else
            if imgui.Button(u8"Продолжить") then
                auth_menu[0] = false
                default_menu[0] = true
            end
        end
        imgui.PopFont()
        imgui.End()
    end
)

local defaultframe = imgui.OnFrame(
    function() return default_menu[0] end,
    function(player)
        SoftLightTheme()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX/3.2, sizeY/3.2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(750, 500), imgui.Cond.Always)
        imgui.Begin("", default_menu, imgui.WindowFlags.NoTitleBar  + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.PushFont(example)
        imgui.BeginChild("#22", imgui.ImVec2(100,450), false, imgui.WindowFlags.NoBackground)
        if imgui.gradientButton(u8"Реестр", imgui.ImVec2(100,50),{r = 200, g = 200, b = 200},{r = 50, g = 50, b = 50},1) then
            selectrazdel(1)
            lua_thread.create(get_members_lva)
        end
        if imgui.gradientButton(u8"Информация", imgui.ImVec2(100,50),{r = 200, g = 200, b = 200},{r = 50, g = 50, b = 50},1) then
            selectrazdel(2)
        end
        if imgui.gradientButton(u8"Чекер", imgui.ImVec2(100,50),{r = 200, g = 200, b = 200},{r = 50, g = 50, b = 50},1) then
            selectrazdel(3)
        end
        if imgui.gradientButton(u8"Б.Реестр", imgui.ImVec2(100,50),{r = 200, g = 200, b = 200},{r = 50, g = 50, b = 50},1) then
            selectrazdel(4)
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.VerticalSeparator()
        imgui.PopFont()
        imgui.SameLine()
        imgui.BeginChild("553", imgui.ImVec2(600,468), false)
        if reestr then
            imgui.PushFont(auth_text)
            imgui.Text(u8" РЕЕСТР НАРУШИТЕЛЕЙ")
            imgui.PopFont()
            imgui.Separator()
            imgui.Columns(4, "Colls", true)
            imgui.SetColumnWidth(0, 80)
            imgui.SetColumnWidth(1, 180)
            imgui.SetColumnWidth(2, 100)
            imgui.SetColumnWidth(3, 200)
            imgui.PushFont(reestr_text)
            imgui.Text(u8"Дата"); imgui.NextColumn()
            imgui.Text(u8"Нарушитель"); imgui.NextColumn()
            imgui.Text(u8"Нарушение"); imgui.NextColumn()
            imgui.Text(u8"Доказательства"); imgui.NextColumn()
            imgui.Separator()

            for _, user in ipairs(users) do
                    local nick, id, reason, urls, date = unpack(user)
                    local diff = tonumber(days_difference(date)) or 0
                    if diff > 7 then
                        imgui.TextColoredRGB(u8"{FF0000}"..date)
                    else
                        imgui.Text(date)
                    end
                    imgui.NextColumn()
                    imgui.Text(u8(nick))
                    if imgui.IsItemClicked() then
                        if default_menu[0] then
                            default_menu[0] = false
                        end
                        target_person_name = nick
                        target_person_id = id
                        testet()
                    end
                    imgui.SameLine()
                    imgui.TextColoredRGB(id)
                    imgui.NextColumn()
                    imgui.Text(u8(reason))
                    imgui.NextColumn()
                    imgui.Text(urls)
                    if imgui.IsItemClicked() then
                        os.execute('start "" "' .. urls .. '"')
                    end
                    imgui.NextColumn()
            end
               
            imgui.Columns(1, "cols2", false)
            imgui.EndChild()
            imgui.PopFont()
        elseif info then
            imgui.PushFont(auth_text)
            imgui.Text(u8" ИНФОРМАЦИЯ")
            imgui.PopFont()
            imgui.Separator()
            imgui.PushFont(reestr_text)
            imgui.Text(u8"  Последняя версия скрипта: v2."..script_vers%100)
            imgui.Text(u8"  Дата последнего обновления: 01.03.2025")
            imgui.Text(u8"  Разработчик: kriksson | vk.com/rinvictus")
            imgui.Separator()
            imgui.Text(u8"  Доступные команды:")
            imgui.Text(u8"  - /usbset - Главное меню")
            imgui.Text(u8"  - /cs - Поиск СОЧ в зоне стрима")
            imgui.Text(u8"  - /wls - Быстрое открытие реестра")
            imgui.Text(u8"  - /dok - Сделать доклад с кодом в рацию")
            imgui.Text(u8"  - /konl - Открыть онлайн УСБ")
            imgui.Text(u8"  - /kk - Отправить сообщение в Чат УСБ")
            imgui.Text(u8"  - /kkick - Кикнуть из чата [Руководство]")
            imgui.Text(u8"  - Нажав на ник в Реестре можно вызвать диалоговое меню взаимодействия")
            imgui.Separator()
            imgui.PopFont()
        elseif checker then
            imgui.PushFont(auth_text)
            imgui.Text(u8" ЧЕКЕР")
            imgui.PopFont()
            imgui.Separator()
            imgui.PushFont(reestr_text)
            imgui.Dummy(imgui.ImVec2(1, 0))
            imgui.SameLine()
            if imgui.RadioButtonBool("", checker_active[0]) then
                checker_active[0] = not checker_active[0]
                ini.settings.checker_active = checker_active[0]
                saveini()
            end
            imgui.SameLine()
            imgui.Text(u8" - Включить чекер")
            imgui.Dummy(imgui.ImVec2(1, 0))
            imgui.SameLine()
            if imgui.Button(u8"Изменить положение чекера", imgui.ImVec2(200,30)) then
                changepos = true
                text("Нажми SPACE когда будешь готов.")
            end
            imgui.Dummy(imgui.ImVec2(1, 0))
            imgui.SameLine()
            if imgui.SliderFloat(u8"Размер чекера", checker_razmer, 1, 99) then
                ini.settings.razmer = checker_razmer[0]
                saveini()
            end
            imgui.Dummy(imgui.ImVec2(1, 0))
            imgui.SameLine()
            if imgui.ColorEdit3("",color, imgui.ColorEditFlags.NoInputs) then
                ini.settings.color1 = color[0]
                ini.settings.color2 = color[1]
                ini.settings.color3 = color[2]
                saveini()
            end
            imgui.SameLine()
            imgui.Text(u8" - Выбрать цвет")
            imgui.PopFont()
        elseif qreestr then
            imgui.PushFont(auth_text)   
            imgui.Text(u8" БЫСТРЫЙ РЕЕСТР")
            imgui.PopFont()
            imgui.Separator()
            imgui.PushFont(reestr_text)
            imgui.Dummy(imgui.ImVec2(1, 0))
            imgui.SameLine()
            if imgui.RadioButtonBool("", active_aliv[0]) then
                active_aliv[0] = not active_aliv[0]
                ini.settings.aliv = active_aliv[0]
                saveini()
            end 
            imgui.SameLine()
            imgui.Text(u8" -Активировать быстрый реестр")
            imgui.Dummy(imgui.ImVec2(1, 0))
            imgui.SameLine()
            if key_alive:ShowHotKey(imgui.ImVec2(75,30)) then
                ini.settings.key_alive = encodeJson(key_alive:GetHotKey())
                saveini()   
            end
            imgui.SameLine()
            imgui.Text(u8" - Клавиша активации")
            imgui.PopFont()
        end
        imgui.EndChild()
        imgui.End()
    end
)

local checkerframe = imgui.OnFrame(
    function() return checker_active[0] end,
    function(player)
        player.HideCursor = true
        imgui.SetNextWindowPos(imgui.ImVec2(ini.settings.posX, ini.settings.posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(1000,1000))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0,0,0,0))
        imgui.Begin("test", checker_active, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.PushFont(checker_text)
        if next(checker_table) == nil then
            imgui.TextColored(imgui.ImVec4(ini.settings.color1, ini.settings.color2, ini.settings.color3, 1), u8"Нет данных")
        else
            imgui.TextColored(imgui.ImVec4(ini.settings.color1, ini.settings.color2, ini.settings.color3, 1), u8(table.concat(checker_table_str, "\n")))
        end
        imgui.PopFont()
        imgui.End()
    end
)


function isNickAlreadyInTable(nick, table)
    for _, entry in ipairs(table) do
        if entry[1] == nick then
            return true
        end
    end
    return false
end

function removeByKeyword(t, keyword) for i = #t, 1, -1 do if type(t[i]) == "string" and string.find(t[i], keyword) then table.remove(t, i) end end end
function removeByValue(t, value) for i = #t, 1, -1 do  if t[i] == value then table.remove(t, i) end end end

function table.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end



local wm = require('windows.message')

addEventHandler('onWindowMessage', function(msg, wparam, lparam)
    if wparam == 27 then
        if auth_menu[0] or default_menu[0] then
            if msg == wm.WM_KEYDOWN then
                consumeWindowMessage(true, false)
            end
            if msg == wm.WM_KEYUP then
                auth_menu[0] = false
                default_menu[0] = false
            end
        end
    end
end)

--=========== ESCAPE MIMGUI

function testet()
    sampShowDialog(9999, "Взаимодействие с "..target_person_name..target_person_id, "Узнать состояние\nУточнить местоположение\nВызвать в ШСО\nВыдать наказание", "Выбор", "Отмена", 2)
    lua_thread.create(function()
        while true do
            wait(0)
            local result, button, list, input = sampHasDialogRespond(9999)
            if result then
                if button == 1 then
                    if list == 0 then
                        target_state = ""
                        target_person_rang = ""
                        target_nick = ""
                        lua_thread.create(function()
                            check_sost_start = true
                            sampSendChat("/mb")
                            wait(750)
                            if not pokazan then
                                sampShowDialog(10000, "Взаимодействие с "..target_person_name..target_person_id, target_person_name.." - Оффлайн!", "Назад", _, 0)
                            elseif pokazan then
                                if target_state:find("На работе") then
                                    if not target_state:find("секунд") then
                                        sampShowDialog(10000, "Взаимодействие с "..target_person_name..target_person_id, target_person_rang.." "..target_nick.. " - Можно вызывать", "Назад", _, 0)
                                    elseif target_state:find("секунд") then
                                        sampShowDialog(10000, "Взаимодействие с "..target_person_name..target_person_id, target_person_rang.." "..target_nick.. " - На работе [AFK]", "Назад", _, 0)
                                    end
                                elseif target_state:find("Выходной") then
                                    if not target_state:find("секунд") then
                                        sampShowDialog(10000, "Взаимодействие с "..target_person_name..target_person_id, target_person_rang.." "..target_nick.. " - Не на работе", "Назад", _, 0)
                                    elseif target_state:find("секунд") then
                                        sampShowDialog(10000, "Взаимодействие с "..target_person_name..target_person_id, target_person_rang.." "..target_nick.. " - Не на работе [AFK]", "Назад", _, 0)
                                    end
                                end
                            end
                        end)
                    elseif list == 1 then
                        local name, surname = target_person_name:match("(.+)_(.+)")
                        if target_nick and target_nick:find(target_person_name) then
                            sampProcessChatInput("/r "..target_person_rang.." "..surname..", уточните ваше местоположение! На ответ даётся 30 секунд.", -1)
                        else
                            text("Повторите запрос состояния")
                        end
                        sampShowDialog(9999, "Взаимодействие с "..target_person_name..target_person_id, "Узнать состояние\nУточнить местоположение\nВызвать в ШСО\nВыдать наказание", "Выбор", "Отмена", 2)
                    elseif list == 2 then
                        sampShowDialog(10001, "Установить РВП", "Введите время в минутах", "Готово", "Отмена", 1)
                        while true do
                            wait(0)
                            local result, button, list, input = sampHasDialogRespond(10001)
                            if result and button == 1 then
                                local time = tonumber(input)
                                if time and time > 0 and time < 21 then
                                    if target_nick and target_nick:find(target_person_name) then 
                                        local numbers_to_words = {
                                            [1] = "Одна", [2] = "Две", [3] = "Три", [4] = "Четыре", [5] = "Пять",
                                            [6] = "Шесть", [7] = "Семь", [8] = "Восемь", [9] = "Девять", [10] = "Десять",
                                            [11] = "Одиннадцать", [12] = "Двенадцать", [13] = "Тринадцать", [14] = "Четырнадцать",
                                            [15] = "Пятнадцать", [16] = "Шестнадцать", [17] = "Семнадцать", [18] = "Восемнадцать",
                                            [19] = "Девятнадцать", [20] = "Двадцать"
                                        }
                                        local function number_to_text(num)
                                            return numbers_to_words[num] or tostring(num)
                                        end
                                        local function minute_word_form(num)
                                            local last_digit = num % 10
                                            local last_two_digits = num % 100
                                            if last_digit == 1 and last_two_digits ~= 11 then
                                                return "минута"
                                            elseif last_digit >= 2 and last_digit <= 4 and (last_two_digits < 10 or last_two_digits >= 20) then
                                                return "минуты"
                                            else
                                                return "минут"
                                            end
                                        end
                                        local name, surname = target_person_name:match("(.+)_(.+)")
                                        local time_text = number_to_text(time)
                                        local time_word = minute_word_form(time)
                                        sampProcessChatInput("/r " .. target_person_rang .. " " .. surname .. ", явитесь в Штаб СО! РВП: " .. time_text .. " " .. time_word .. ".", -1)
                                    else
                                        text("Повторите запрос состояния бойца")
                                    end
                                else
                                    sampAddChatMessage("Введите время от 1 до 20 минут.", -1)
                                end
                                break
                            end
                        end
                    elseif list == 3 then
                        sampShowDialog(10002, "Взаимодействие с "..target_person_name..target_person_id, "Выдать строгий выговор\nВыдать обычный выговор\nВыдать наряд\nВыдать устное предупреждение", "Выбор", "Отмена", 2)
                    end
                elseif button == 0 then
                    wait(100)
                    if not default_menu[0] then
                        default_menu[0] = true
                    end
                end
            end
        end
    end)    
    lua_thread.create(function()
        while true do wait(0)
            local result, button, list, input = sampHasDialogRespond(10000)
            if result then
                if button == 1 then
                    sampShowDialog(9999, "Взаимодействие с "..target_person_name..target_person_id, "Узнать состояние\nУточнить местоположение\nВызвать в ШСО\nВыдать наказание", "Выбор", "Отмена", 2)
                end
            end
        end
    end)
    lua_thread.create(function()
        while true do wait(0)
            local result, button, list, input = sampHasDialogRespond(10002)
            if result then
                if button == 1 then
                    if list == 0 then
                        sampShowDialog(1003, "Выдать строгий выговор", "Введите причину выговора\nНапример: НУ 3.4", "Готово", "Отмена", 1)
                        lua_thread.create(function()
                            while true do wait(0)
                                local result, button, list, input = sampHasDialogRespond(1003)
                                if result and button == 1 then
                                    local reason = input
                                    if reason ~= "" then
                                        lua_thread.create(function()
                                            if target_nick and target_nick:find(target_person_name) then
                                                local name, surname = target_person_name:match("(.+)_(.+)")
                                                sampProcessChatInput("/r "..target_person_rang.." "..surname.." получает Строгий Выговор на 14 дней, без прав на отработку...")
                                                wait(2500)
                                                sampProcessChatInput("/r ...по факту "..reason)
                                            else
                                                text("Повторите запрос состояния бойца")
                                            end
                                        end)
                                    end
                                end
                            end
                        end)
                    elseif list == 1 then
                        sampShowDialog(1004, "Выдать обычный выговор", "Введите причину выговора\nНапример: НУ 3.4", "Готово", "Отмена", 1)
                        lua_thread.create(function()
                            while true do wait(0)
                                local result, button, list, input = sampHasDialogRespond(1004)
                                if result and button == 1 then
                                    local reason = input
                                    if reason ~= "" then
                                        lua_thread.create(function()
                                            if target_nick and target_nick:find(target_person_name) then 
                                                local name, surname = target_person_name:match("(.+)_(.+)")
                                                sampProcessChatInput("/r "..target_person_rang.." "..surname.." получает Обычный Выговор на 7 дней, с правом на отработку...")
                                                wait(2500)
                                                sampProcessChatInput("/r ...по факту "..reason)
                                            else
                                                text("Повторите запрос состояния бойца")
                                            end
                                        end)
                                    end
                                end
                            end
                        end)
                    elseif list == 2 then
                        sampShowDialog(1005, "Выдать наряд", "Введите круги наряда\nНапример: 5", "Готово", "Отмена", 1)
                        lua_thread.create(function()
                            while true do wait(0)
                                local result, button, list, input = sampHasDialogRespond(1005)
                                if result and button == 1 then
                                    circles = input
                                    if circles ~= "" then
                                        sampShowDialog(9998, "Выдать наряд", "Введите причину наряда\nНапример: НУ 3.4", "Готово", "Отмена", 1)
                                        lua_thread.create(function()
                                            while true do wait(0)
                                                local result, button, list, input = sampHasDialogRespond(9998)
                                                if result and button == 1 then
                                                    local reason = input
                                                    lua_thread.create(function()
                                                        local name, surname = target_person_name:match("(.+)_(.+)")
                                                        if target_nick and target_nick:find(target_person_name) then
                                                            sampProcessChatInput("/r "..target_person_rang.." "..surname.." получает наряд в виде "..circles.." кругов вокруг части...")
                                                            wait(2500)
                                                            sampProcessChatInput("/r ...по факту "..reason)
                                                        else
                                                            text("Повторите запрос состояния бойца")
                                                        end
                                                    end)
                                                end
                                            end
                                        end)
                                    end
                                end
                            end
                        end)
                    elseif list == 3 then
                        sampShowDialog(1006, "Выдать устное предупреждение", "Введите причину предупреждения\nНапример: НУ 3.4", "Готово", "Отмена", 1)
                        lua_thread.create(function()
                            while true do wait(0)
                                local result, button, list, input = sampHasDialogRespond(1006)
                                if result and button == 1 then
                                    local reason = input
                                    if reason ~= "" then
                                        lua_thread.create(function()
                                            if target_nick and target_nick:find(target_person_name) then
                                                local name, surname = target_person_name:match("(.+)_(.+)")
                                                sampProcessChatInput("/r "..target_person_rang.." "..surname.." получает устное предупреждение по факту "..reason)
                                            else
                                                text("Повторите запрос состояния бойца")
                                            end
                                        end)
                                    end
                                end
                            end
                        end)                   
                    end
                end
            end
        end
    end)

end

function agit()
    while ini.settings.checker_active do wait(300000)
        lua_thread.create(get_members_lva)
    end
end

local accept_grab_members_list = false

function get_members_lva()
    members = {}
    accept_grab_members_list = true
    sampSendChat("/members")
    while os.clock() < os.clock() +3 do wait(0) end
    accept_grab_members_list = false
end

function checkstream()
    sampSendChat("/members")
    oncheck_unitstream = true
    text("Проверка запущена, ожидайте результатов...")
    while os.clock() < os.clock() +2 do wait(0) end
    text("Проверка закончена.")
end
function checkPlayerByID(per) for k, v in pairs(getAllChars()) do if doesCharExist(v) then local result, id = sampGetPlayerIdByCharHandle(v) if id == tonumber(per) and result then return true end end end return false end

function sampev.onServerMessage(color, text)
    if oncheck_unitstream then
        local script_tag = "{D3D3D3}[УСБ] {FFFFFF}"
        if text:find("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+)") then
            local id, data, nick, rang, state = text:match("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+)")
            if checkPlayerByID(id) and nick and nick ~= mynick then
                sampAddChatMessage(script_tag.." Обнаружен: "..rang.." - "..nick.."["..id.."]", -1)
            end
        elseif text:find("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+)") then
            local id, data, nick, rang, state = text:match("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+)")
            if checkPlayerByID(id) and nick and nick ~= mynick then
                sampAddChatMessage(script_tag.." Обнаружен: "..rang.." - "..nick.."["..id.."]", -1)
            end
        elseif text:find("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+) %| (.+)%[AFK%]") then
            local id, data, nick, rang, state, afk = text:match("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+) %| (.+)%[AFK%]")
            if checkPlayerByID(id) and nick and nick ~= mynick then
                sampAddChatMessage(script_tag.." Обнаружен: "..rang.." - "..nick.."["..id.."]", -1)
            end
        elseif text:find("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+) %| (.+)%[AFK%]") then
            local id, data, nick, rang, state, afk = text:match("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+) %| (.+)%[AFK%]")
            if checkPlayerByID(id) and nick and nick ~= mynick then
                sampAddChatMessage(script_tag.." Обнаружен: "..rang.." - "..nick.."["..id.."]", -1)
            end
        end
        if text:find(" Всего:") then
            oncheck_unitstream = false
        end
        return false
    end
    if check_sost_start then
        if text:find("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+)") then
            local id, data, nick, rang, state = text:match("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+)")
            if nick and nick:find(target_person_name) then
                target_nick = nick
                target_person_rang = rang:match("(.+)%[")
                target_state = state
                if afk then
                    target_afk = afk
                end
                lua_thread.create(function()
                    pokazan = true
                    wait(2500)
                    pokazan = false
                end)
            end
        elseif text:find("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+)") then
            local id, data, nick, rang, state = text:match("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+)")
            if nick and nick:find(target_person_name) then
                target_nick = nick
                target_person_rang = rang:match("(.+)%[")
                target_state = state
                if afk then
                    target_afk = afk
                end
                lua_thread.create(function()
                    pokazan = true
                    wait(2500)
                    pokazan = false
                end)
            end
        elseif text:find("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+) %| (.+)%[AFK%]") then
            local id, data, nick, rang, state, afk = text:match("ID: (%d+) %| (.+) %| (.+) %(Voice%)%: (.+) %- (.+) %| (.+)%[AFK%]")
            if nick and nick:find(target_person_name) then
                target_nick = nick
                target_person_rang = rang:match("(.+)%[")
                target_state = state
                if afk then
                    target_afk = afk
                end
                lua_thread.create(function()
                    pokazan = true
                    wait(2500)
                    pokazan = false
                end)
            end
        elseif text:find("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+) %| (.+)%[AFK%]") then
            local id, data, nick, rang, state, afk = text:match("ID: (%d+) %| (.+) %| (.+)%: (.+) %- (.+) %| (.+)%[AFK%]")
            if nick and nick:find(target_person_name) then
                target_nick = nick
                target_person_rang = rang:match("(.+)%[")
                target_state = state
                if afk then
                    target_afk = afk
                end
                lua_thread.create(function()
                    pokazan = true
                    wait(2500)
                    pokazan = false
                end)
            end
        end
        if text:find(" Всего:") then
            check_sost_start = false
        end
        return false
    end    
    if accept_grab_members_list then
        if text:find("ID:") then
            table.insert(members, text)
        end
        if text:find(" Всего:") then
            accept_grab_members_list = false
            getd()
        end
        return false
    end
end

function getd()
    users = {}
    off_members = {}
    checker_table = {}
    checker_table_str = {}
    local spreadsheetId = bdecrypt("31 58 4E 36 72 64 71 62 77 35 51 7A 64 5A 57 56 56 48 4C 72 4F 37 35 4E 65 43 6F 77 61 65 38 47 76 73 74 38 31 52 48 56 46 30 6B 51")
    local range = "WLS!A:E"
    local apiKey = bdecrypt("41 49 7A 61 53 79 43 36 34 4C 77 77 76 6F 77 47 6F 6C 76 78 59 5A 58 43 35 72 6A 57 62 35 41 50 73 31 56 76 6A 57 55")
    local data, err = fetchGoogleSheetData(spreadsheetId, range, apiKey)
    
    if not data then
        text(("Ошибка: {FF0000}%s"):format(err))
        return
    end
    for i, row in ipairs(data) do
        local nick, sanc, reason, url, date = unpack(row)
        local id = sampGetPlayerIdByNickname(nick)
        if #sanc == 0 and id then
            local nick = u8:decode(nick)
            local reason = u8:decode(reason)
            local urls = u8:decode(url)
            local date = u8:decode(date)
            local id_color = isNickInMembers(nick, members) and "{00FF00}" or "{FA8072}"
            local that_id = "{A9A9A9}["..id_color .. id .. "{A9A9A9}]"
        
            table.insert(checker_table_str, nick .. "[" .. id .. "] - " .. reason)
            table.insert(checker_table, {nick, reason})
            table.insert(users, {nick, that_id, reason, urls, date})
        elseif #sanc == 0 then
            local nick = u8:decode(nick)
            local reason = u8:decode(reason)
            local urls = u8:decode(url)
            local date = u8:decode(date)
            table.insert(checker_table, {nick, reason})
        
            local that_id = "{A9A9A9}[OFF]"
            table.insert(users, {nick, that_id, reason, urls, date})
            table.insert(off_members, nick)
        end
        
    end
end

--=========== Log suspect system

function SoftLightTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.80, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.60, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.66, 0.66, 0.66, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.66, 0.66, 0.66, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.95, 0.95, 0.70, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.95, 0.95, 0.70, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.25, 0.25, 0.15, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.10, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
end


--=========== Style

function checkaccess()
    local spreadsheetId = bdecrypt("31 58 4E 36 72 64 71 62 77 35 51 7A 64 5A 57 56 56 48 4C 72 4F 37 35 4E 65 43 6F 77 61 65 38 47 76 73 74 38 31 52 48 56 46 30 6B 51")
    local range = "AUTH!A:D"
    local apiKey = bdecrypt("41 49 7A 61 53 79 43 36 34 4C 77 77 76 6F 77 47 6F 6C 76 78 59 5A 58 43 35 72 6A 57 62 35 41 50 73 31 56 76 6A 57 55")
    local data, err = fetchGoogleSheetData(spreadsheetId, range, apiKey)
    
    if not data then
        text(("Ошибка: {FF0000}%s"):format(err))
        return
    end
    for i, row in ipairs(data) do
        local nick, poziv, role, version = unpack(row)
        if version then
            checkvers = version
        end
        table.insert(poziv_nicks, nick.."="..u8:decode(poziv))
        if nick == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
            uid = i 
            if tonumber(script_vers) < tonumber(checkvers) then
                go_update = true
            end
            con()
            lua_thread.create(agit)
            authorize = true
            mypoziv = u8:decode(poziv)
            myrole = role
        end
    end
end

--=========== Authorize

function formnick(nick)
    local nick = string.gsub(nick, "@", "")
    local upperCount = 0
    for i = 1, #nick do
        if string.sub(nick, i, i):match("%u") then
            upperCount = upperCount + 1
        end
    end

    local formattedNick = nick
    if upperCount >= 2 then
        formattedNick = string.gsub(nick, "(%u)", "_%1"):sub(2)
    end
    local playerID = sampGetPlayerIdByNickname(formattedNick)
    if playerID then
        return formattedNick.."["..playerID.."]".."{FFFFFF}"
    else
        return formattedNick
    end
end

function formnickt(nick)
    local upperCount = 0
    for i = 1, #nick do
        if string.sub(nick, i, i):match("%u") then
            upperCount = upperCount + 1
        end
    end

    local formattedNick = nick
    if upperCount >= 2 then
        formattedNick = string.gsub(nick, "(%u)", "_%1"):sub(2)
    end
    local playerID = sampGetPlayerIdByNickname(formattedNick)
    if playerID then
        return formattedNick.."["..playerID.."]"
    else
        return formattedNick
    end
end

function atbash(text)
    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        local byte = char:byte()
        if byte >= 65 and byte <= 90 then
            byte = 90 - (byte - 65)
        elseif byte >= 97 and byte <= 122 then
            byte = 122 - (byte - 97)
        end
        result = result .. string.char(byte)
    end
    return result
end


function konline()
    if connect then
        konl = true
        irc:send('NAMES %s',cods)
    else
        text("Ты не подключён к чату")
    end
end

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
end

function OnModeChange(user, target, modes, args)
    if modes == "+o" then
        if user.nick == "kriksson4life" then
            user.nick = "kriksson_bot"
        end
        text(user.nick.." выдал права руководителю "..formnick(atbash(args)))
        if args == irc.nick then
            admin = true
        end
    end
end

function OnKick(channel, nick, kicker, reason)
    text("Руководитель "..formnick(atbash(kicker.nick)).." кикнул "..formnick(atbash(nick)))
end

function kick(nick)
    irc:send("KICK "..cods.." "..atbash(nick))
end

on = false

function onIRCRaw(line)
	if konl and line:find("353") then
    	nicks = line:match('.+%:(.+)')
		online = 0
		list_onl = {}
		for name in string.gmatch(nicks, "%S+") do
            if name ~= "@kriksson4life" then
                table.insert(list_onl, ""..formnick(atbash(name)))
                online = online + 1
            end
		end
        sampShowDialog(19292, "УСБ MScript | v2."..script_vers%100, "{FFFFFF}Общий онлайн "..online..": \n\n"..table.concat(list_onl, "\n"), "OK", _, 0)
		konl = false
	end
end

function onmess(user,channel,message)
    if not channel:find"#" then
        print("skip")
    else
        user.nick = atbash(user.nick)
        text(""..formnick(user.nick)..": "..bdecrypt(message))
    end
end

function onjoin(user, channel)
    if user.nick == irc.nick then
        connect = true
    end
    user.nick = atbash(user.nick)
    text(formnick(user.nick).." зашёл в чат")
end

function onquit(user, channel)
    user.nick = atbash(user.nick)
    text(formnick(user.nick).." покинул чат")
end

function ircsend(msg)
    local mynick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
    if msg and msg ~= "" then
        if connect then
            local got_msg = string.format("%s: %s » %s", formnick(atbash(irc.nick)), mypoziv, msg)
            local got_msg_wn = string.format("%s » %s", mypoziv, msg)
            text(""..got_msg)
            irc:sendChat(cods, bcrypt(got_msg_wn))
        else
            text("Ты не подключён к чату")
        end
    else
        text("Введи сообщение. | /kk Привет!")
    end
end

--=========== kkchat


function alivfunc()
    if go_screen then
        text("Загружаю...")
        go_screen = false
        upload_image(screen_path)
    end
end

army_data ="\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x64\x00\x00\x00\x64\x08\x06\x00\x00\x00\x70\xE2\x95\x54\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0B\x13\x00\x00\x0B\x13\x01\x00\x9A\x9C\x18\x00\x00\x06\xC4\x49\x44\x41\x54\x78\x9C\xED\x9D\x79\xA8\x15\x55\x1C\xC7\x47\xCD\xDC\xB2\x1D\x94\xB2\xD4\x4C\xFD\x23\x43\xCD\x90\x20\xCB\xC8\xA0\x40\x4A\x33\x5B\x88\x50\x11\x53\x14\xA2\xE8\x1F\xCB\x36\x29\xC2\x16\x70\x29\xC8\xCA\xD4\x36\x4B\x0D\xAC\xB4\x8D\x34\x8D\x82\x92\xCA\xF7\x54\x8C\x22\x35\xF0\x49\x9B\xCA\x93\x6C\x43\x2D\x3F\x71\x7C\xBF\xA9\x9F\xE3\x99\x7B\xE7\xDE\x3B\xF3\xEE\x99\x37\xE7\x03\xF3\xCF\xFD\xCE\x59\xEE\xF9\xDE\x99\xB3\xFD\x66\x6E\x10\x78\x3C\x1E\x8F\xC7\xE3\xF1\x78\x3C\x1E\x8F\xC7\x93\x14\xE0\x04\xE0\x26\x60\x01\xF0\x9C\x3F\x28\xD5\x06\xA6\x8D\x6E\x34\x6D\x96\xC9\x2F\x0C\x38\x17\xD8\x8A\xA7\x52\x36\x9B\xB6\xCB\xE2\xCA\xF0\x66\xD4\x66\x4A\x7A\x57\x8A\xDC\xA6\x42\x8E\x00\xCB\x81\xC7\xFC\x41\xA9\x36\x58\x21\x6D\x15\x32\x3E\x4D\x43\xCC\xFD\x30\x64\x79\x6A\x19\xB7\x71\x68\x31\x25\x64\x7E\x9A\x19\x2F\x55\x19\xCF\x4E\x2D\xE3\x36\x0E\x30\x5B\xB5\xDB\xD2\x56\x33\x04\xE8\x08\x5C\x07\x0C\x8C\x49\x7F\x2A\x30\x0E\xE8\x19\xA3\xF7\x12\xBD\x5B\x8C\x3E\x08\x18\x0D\xB4\x8F\xD1\x2F\x03\x46\xC4\x68\x1D\x24\xED\xA0\x18\xBD\x9B\x94\xDD\x2B\x46\xEF\x29\xFA\x29\x31\xFA\x40\xF9\xEE\x1D\x5D\x32\xE4\x59\xD1\xFE\x02\x7A\x5B\xF4\x8D\xA2\x37\x45\x3B\x37\xA0\x3B\xB0\x57\xF4\xF7\x62\xCC\x38\x2C\xFA\x1C\x8B\x7E\x8B\xAA\xDB\xCD\x16\xDD\xDC\xCF\x91\x3C\x2E\xB0\xE8\x1F\x88\xBE\x07\x38\xC9\xF2\x43\xDB\x2D\xFA\x67\x96\xB4\x7D\xE4\x3B\x1B\x9E\x71\xC9\x90\x06\xA5\x8F\xB1\xE8\xBA\x73\x3B\xC6\x30\x60\xB0\xD2\x9A\x2D\x69\x27\x2A\x7D\xBD\x45\x9F\xA7\xF4\x79\x16\x7D\xBD\xD2\x27\x5A\xF4\x66\xA5\x0F\x8E\x68\xBD\x95\x76\xC4\x92\x76\x8C\xD2\x1B\x5C\x32\xA4\x51\xE9\x63\x2D\xBA\xA6\x4F\x44\x1B\xA2\xB4\xFD\x96\xB4\x93\x94\xBE\xA1\x0A\x43\x36\x28\x7D\x92\x45\xDF\xAF\xF4\x21\x96\x2B\xE0\x3F\x2C\x69\xC7\x2A\xB9\xD1\xA2\x7B\x43\x02\x6F\xC8\xD1\x5F\xC2\xA7\xEA\x97\x32\xCA\xD2\x28\xBF\x85\x97\x3D\x70\x46\x44\xEB\xA7\xD2\x36\x59\xD2\xDE\xA0\xF4\xD5\x16\xFD\x11\xA5\x3F\x6C\xD1\xD7\x28\x7D\x9C\x45\x0F\xFB\x08\x43\xBF\x88\x76\xA6\xD2\x0E\x58\xD2\x8E\x52\xFA\x27\x2E\x5D\x21\x57\x48\x3F\xF2\x82\x19\xD5\x58\xF4\xC9\x32\xD3\xBF\x37\x26\xFF\x39\xC0\x16\xDB\xE4\x09\xE8\x04\xBC\x06\x7C\x01\x5C\x6C\xD1\xCF\x06\xD6\x01\x6B\x81\xB3\x2C\xFA\x70\xE0\x4B\x60\x99\xC9\x2B\x66\xD2\x6B\xCA\x7E\x34\xA6\x6E\xB3\xA4\xEE\x93\x62\x56\x30\x16\x03\x9B\x80\xCB\x9D\x31\xC4\x63\xC7\x1B\xE2\x18\xDE\x10\xC7\xC8\x95\x21\x40\x57\xE0\x0E\x19\x96\xFE\x0C\x1C\x94\x0E\xF6\x0D\x99\x19\xB7\x0B\x72\x4E\x6E\x0C\x01\xAE\x02\x7E\xA0\x34\x1B\xA3\x73\x96\x2A\xCB\x3A\x11\x98\x00\xCC\xCC\xE0\xB8\x1B\xB8\x30\xD7\x86\xC8\x30\x36\x5C\x0A\x29\xC7\x2F\xC0\xF9\x35\x96\x37\x9F\x6C\xF9\xB3\xC4\x1A\x9D\xDB\x86\x00\x03\x80\x3F\x54\x5E\xBF\x03\x8F\x03\x97\x02\xFD\x81\x6B\x64\xAF\x45\x2F\xB5\x6C\xB3\x2D\xDC\x55\x50\xE6\xEB\x19\x1B\x72\xA4\xC4\xA2\xAA\xF3\x86\x98\xFE\x21\x64\x6F\xDC\xE5\x0E\xDC\x06\xFC\xA3\xCE\x9D\x51\x43\x99\xE7\x00\xCF\x03\x2B\x33\x38\xCC\x7E\xC7\xE4\x12\x65\xBB\x6B\x08\x70\x7A\xE4\x56\x75\x7D\x99\xF3\x9F\x56\xE7\x7E\x15\xE4\x10\xD7\x0D\xB9\x56\xE5\xB1\xBB\xDC\x28\x8A\x96\xDB\x9B\xBE\x2D\x74\x0F\x72\x86\xEB\x86\x4C\x53\x79\xBC\x9F\xE0\xFC\x76\x6A\xAF\x81\xB8\xFB\x74\x05\x11\x33\xC3\x32\x38\xCC\xD6\x41\xE7\xBC\x1A\x72\x97\xCA\xE3\xCD\x84\x69\xF6\xC7\x2D\x8D\x57\x50\xEE\x8C\xC8\x20\x21\x6D\xB6\x47\x37\xB6\x54\xD9\xDE\x90\x28\x66\x85\x98\xEC\x19\x7A\x5C\xC1\xDE\x10\x3B\xC0\x48\xF9\x15\x37\x67\x70\xEC\x03\x5E\x2A\xB1\xD7\xEF\xF4\x15\x32\x55\xE5\xF1\x51\x82\xF3\x3B\x44\x46\x65\x03\x82\x9C\xE1\xBA\x21\x66\xB9\x24\xE4\xD7\x52\x9D\xA1\xC1\x44\x91\xA8\xF3\x0F\x95\x3B\xDF\x45\x5C\x37\xC4\x84\xDB\x1C\x50\xF9\xDC\x57\xE2\xDC\xF6\xB2\xE1\x94\xF8\x8A\x72\x11\xA7\x0D\xB1\xAC\x2B\xFD\x0D\x4C\xB1\x9C\xD3\x59\x76\x1E\x49\x3A\x89\x2C\x53\xA6\xD9\xCD\xDC\x51\xA2\x1F\xD8\x6A\x0B\x0F\x6A\xF3\x86\x98\x91\x88\x6C\xB5\x46\x31\x5B\xB3\xF7\xCB\x3C\xE5\x09\x89\xDD\x8A\xB2\x08\xE8\x9B\xE1\x28\x6B\x41\x35\x79\xE7\xD2\x10\xD9\x13\x7F\x32\xB2\x36\x55\x0D\x87\x64\xC9\xBB\xA2\x7D\x12\x60\x7A\x99\x79\x88\xC9\x77\x74\xC5\x8D\x92\xAC\xEC\x87\x9C\x32\xC4\x44\x98\x98\x88\x3F\x4B\x23\x7C\x0F\xBC\x5B\xA2\xA1\x0E\x02\xAB\x24\x9A\x30\xCA\xAB\xB6\x40\x8A\x04\x0B\x8C\x71\xB3\xED\x1E\x55\x35\x4A\xDE\x0C\x01\x4E\x93\xA5\x73\xCD\x0E\xD9\x0F\x69\xAF\xE2\x62\x67\xC9\x92\xFB\x87\xC0\xCB\xC0\x9D\x61\xF4\x88\x6C\x2E\x4D\x57\xA1\xA6\xC4\x85\x6D\xBA\x88\x33\x86\x48\x78\xCC\xC7\x91\x46\x34\x13\xA8\xAE\x55\x96\xDF\x23\x12\x81\x68\x98\x16\x38\x8E\x4B\x86\x3C\x18\x69\xBC\xB9\x29\xD4\xA1\xA3\x59\x03\x8B\x6C\x6E\x1D\x13\xD8\xE6\x1A\x4E\x74\xEA\xC0\x79\xD2\x07\x84\xAC\x48\xB1\x1E\x9D\xCC\xDE\x88\xCA\x7B\x55\xE0\x30\x4E\x5C\x21\xC0\x8B\xEA\xDC\x1F\x81\x93\x53\xAB\x48\x70\x34\xFF\xFE\xCA\x70\x33\x28\x18\x1E\x38\x4A\xDD\x0D\x91\x8E\x5C\xEF\x61\x1C\x37\xF1\x4B\xA9\x3E\x73\x55\x19\x2B\x03\x47\x71\xC1\x90\x29\xEA\xBC\x7D\x59\xAD\x3F\x01\x7D\xD5\xBC\xE6\x70\x96\x43\x57\x57\x0D\x59\x92\xD0\x10\x33\x47\x08\x59\x9C\x5A\x05\x2C\x00\x9F\xBB\x3E\xE2\x72\xC1\x10\x13\x65\x1E\x32\x21\xB5\x0A\xC4\x47\xCC\x87\x2C\x09\x1C\xC4\x05\x43\x6E\x97\x0E\xB7\x31\xED\xCE\x3C\x8A\x3C\x57\xD2\x24\x2B\xC8\x57\x06\x0E\x52\x77\x43\xE4\xDC\x56\xDD\xB7\xC0\xF2\xCC\x87\x2B\xD4\xBD\x53\xF7\x38\x38\x31\xF4\xFC\x8F\x37\xA4\x40\x86\x24\xED\xD4\x3B\x4B\xF0\x58\x16\x41\x69\xC3\xD2\x08\x62\x93\x37\x33\x24\x49\x5F\x53\xD4\x7D\xDD\x3B\x75\x13\x2C\x26\xCB\xEB\x2E\xB1\x5D\x07\xB1\x49\x38\x6B\xD2\x47\x21\xAC\x6F\x8E\xC8\x93\x21\x17\xE1\x26\x43\x55\x1D\x9F\xAA\x30\xED\x96\x3C\x1B\x62\xE2\xA8\x5E\x91\x25\x93\x2C\x82\xD2\x9A\x6B\x0D\x62\x33\xC1\x0C\xF2\x08\x74\x92\xF4\x4D\xB5\xBE\xE3\xCA\x0F\x7B\x1D\xC3\x8F\xB2\x1C\xC3\x1B\xE2\x18\x75\x1D\xF6\x4A\x1F\xB2\xCC\xA1\x3E\xA4\x39\xE1\x91\x65\xA0\x9C\x1F\x65\x55\x49\x56\x81\x72\x75\x9F\x87\x98\x71\x7F\xDE\x38\x94\xC7\x40\xB9\x3C\xCE\xD4\x87\x25\x3C\x7A\xB4\xE9\xE5\xF7\xB6\x06\x2D\xFB\x2E\x23\xE5\x71\x8A\x4A\x0F\x33\x0F\xF2\x86\xA4\x01\x70\x49\xE4\x5D\x92\xEE\xF4\x53\x45\xBB\x42\x68\x31\x43\x47\xCF\xA4\xC1\x03\x69\x56\xB0\x68\x86\x34\xA8\xEF\x6B\xA2\x5B\x76\x01\x3B\x2B\x3C\x7E\x8A\x18\x72\x75\x9A\x15\x2C\x8C\x21\xB4\x44\x5E\x86\x1C\xAC\x26\x10\x4F\xC2\x5E\x4D\xF0\x78\x88\x89\xE2\xEF\x92\x66\x25\x8B\x64\xC8\x08\xF5\x5D\x37\x57\x91\xFE\xC4\x48\x0C\xB2\x61\x6A\xDA\x95\x2C\x92\x21\x23\xD5\x77\xDD\x54\x85\x19\x6F\x45\xCC\x58\x94\x45\x25\x97\x16\xD4\x90\x86\x1A\xAF\x8C\x15\x99\xFC\xC3\x4E\x81\x0D\x69\xAC\xE1\xCA\xC8\xC6\x8C\x82\x1B\xB2\x25\xA1\x19\x6F\xB7\x9A\x19\x05\x37\x64\xAB\x73\x66\x14\xDC\x90\x6D\x65\xCC\x58\xDD\xEA\x66\x14\xDC\x90\xAF\x4B\x98\xB1\xA6\x2E\x66\x14\xDC\x90\x6F\x62\x1E\xAB\xAB\x9F\x19\x05\x37\xE4\x5B\x8B\x19\xEF\xD4\xD5\x8C\x82\x1B\xF2\x9D\xFA\xBC\x4B\x64\x39\xA4\x3E\x66\x14\xDC\x90\xED\xCA\x8C\xB5\x4E\x98\x51\xF0\xA5\x93\x9D\xF2\x8E\xFA\x75\xB5\xBE\xDE\x23\xED\x4A\xCE\xCF\xE2\xB9\xF3\x1C\x18\xB2\xC7\xF2\xAE\x96\xFA\x9A\x21\x95\x34\xFF\x7A\x8C\x7A\x36\xDC\xBC\xD5\xF9\x9E\x8C\x5E\x70\x3F\xB3\xCE\x47\xF8\x17\x80\x36\xEA\x6F\x86\x7A\x77\x89\xFE\x27\xB6\x22\xB2\xD0\x09\x33\x22\xAF\x38\x2A\xA2\x29\xBB\x80\x5B\x03\x17\x91\x2B\x65\xBC\xF4\x29\x6D\xF9\x0F\xEE\x17\xCA\x0B\x74\x46\xD5\xF2\xCF\x0C\x1E\x8F\xC7\xE3\xF1\x78\x3C\x1E\x8F\xC7\xE3\xF1\x04\x95\xF2\x2F\xEE\x3B\x09\x0A\x15\xAD\x08\x86\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"

function loadscript()
    text("Скрипт загружен")
    first_spawn = true
    irc = irc.new{nick = atbash(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))}
--=====================
    my = {
        nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
        id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)),
        rpnick = string.match(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))), "(.+)_").." "..string.match(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))), "_(.+)")
    }
--=====================
    sampRegisterChatCommand("usbset", function()
        if authorize then
            default_menu[0] = not default_menu[0]
        end
    end)
    sampRegisterChatCommand("test", google_send)
    sampRegisterChatCommand("kkick", kick)
    sampRegisterChatCommand("cs", function()
        lua_thread.create(checkstream)
    end)
    sampRegisterChatCommand("wls", function()
        selectrazdel(1)
        lua_thread.create(get_members_lva)
        if not default_menu[0] then
            default_menu[0] = true
        end
    end)
    sampRegisterChatCommand("dok", doklad_cmd)
    sampRegisterChatCommand("kk", ircsend)
    sampRegisterChatCommand("konl", konline)
    key_alive = hotkey.RegisterHotKey("key_alive", false, decodeJson(ini.settings.key_alive), function() end)
end

function main()
    while not isSampAvailable() do wait(0) end
    checkLib()
    while true do
        wait(0)
        if first_spawn and sampIsLocalPlayerSpawned() then
            auth_menu[0] = true
            first_spawn = false
        end
        if isKeyJustPressed(string.match(ini.settings.key_alive, "%[(%d+)%]")) then
            alivfunc()
        end
        if changepos then
            sampToggleCursor(true)
            local cX, cY = getCursorPos()
            ini.settings.posX = cX
            ini.settings.posY = cY
            if isKeyJustPressed(32) then
                text("Позиция для чекера закреплена")
                changepos = false
                sampToggleCursor(false)
                saveini()
            end
        end
        if irc.__isConnected then
			irc:think()
		end
        if go_update then
            text("Идёт установка обновления.")
            downloadUrlToFile(bdecrypt("68 74 74 70 73 3A 2F 2F 67 69 74 68 75 62 2E 63 6F 6D 2F 4B 72 69 6B 73 73 6F 6E 2F 74 65 73 74 63 68 65 63 6B 2F 72 61 77 2F 6D 61 69 6E 2F 75 73 62 6D 73 2E 6C 75 61"), thisScript().path, function(id, status)
                go_update = false
                if status == dlstatus.ENDDOWNLOADDATA then
                    text("Установлено.")
                    thisScript():reload()
                end
            end)
        end
        local chatstring = sampGetChatString(99)
        if chatstring:find("Скриншот сохранён - (.+)") and ini.settings.aliv and authorize then
            local scr_name = string.match(chatstring, "Скриншот сохранён %- (.+)")
            screen_path = getFolderPath(0x05).."\\GTA San Andreas User Files\\Evolve\\screens\\"..scr_name
            text("Скриншот "..scr_name.." был перехвачен. Нажмите кнопку активации чтобы добавить нарушение.")
            lua_thread.create(function()
                go_screen = true
                wait(15000)
                go_screen = false
            end)
        end
    end
end

--=========== Body script

function upload_image(image_path)
    print("Начинаем загрузку файла: " .. image_path)
    local file = assert(io.open(image_path, "rb"))
    local image_data = file:read("*all")
    file:close()
    local boundary = "----BOUNDARY"
    local body = "--" .. boundary .. "\r\n" ..
                 'Content-Disposition: form-data; name="image"; filename="' .. image_path .. '"\r\n' ..
                 "Content-Type: application/octet-stream\r\n\r\n" ..
                 image_data .. "\r\n--" .. boundary .. "--\r\n"

    local headers = {
        ["Authorization"] = "Client-ID 4ed2cb48ba46d11",
        ["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
        ["Content-Length"] = tostring(#body)
    }

    local response_body = {}
    local result, status_code, response_headers = http.request{
        method = "POST",
        url = "https://api.imgur.com/3/image",
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body)
    }

    if not result then
        print("Ошибка сети:", status_code)
        return
    end

    local response_text = table.concat(response_body)
    
    if status_code == 200 then
        print("Изображение успешно загружено!")
        local link = response_text:match('"link":"(.-)"')
        
        if link then
            zaliv_link = link:gsub("\\/", "/")
            zaliv()
        else
            print("Ошибка: не удалось найти ссылку в ответе")
            print("Полный ответ:", response_text)
        end
    else
        print("Ошибка загрузки. Код ответа:", status_code)
        print("Тело ответа:", response_text)
    end
end

function zaliv()
    sampShowDialog(7284, "Добавление новой строчки", "Введите ник нарушителя\nНапример: Katanage_Nephrite или @id", "Готово", "Отмена", 1)
    lua_thread.create(function()
        while true do
            wait(0)
            local result, button, list, input = sampHasDialogRespond(7284)
            if result then
                if button == 1 then
                    if #input > 0 then
                        if input:find("@") then
                            local zaliv_id = string.match(input, "@(%d+)")
                            zaliv_nick = sampGetPlayerNickname(zaliv_id)
                        else
                            zaliv_nick = input
                        end
                        sampShowDialog(7285, "Добавление новой строчки", "Введите причину\nНапример: Н.У. 3.34", "Готово", "Отмена", 1)
                    else
                        text("Укажи ник правильно")
                        sampShowDialog(7284, "Добавление новой строчки", "Введите ник нарушителя\nНапример: Katanage_Nephrite или @id", "Готово", "Отмена", 1)
                    end
                else
                    text("Залитие отменено")
                end
            end
        end
    end)
    lua_thread.create(function()
        while true do wait(0)
            local result, button, list, input = sampHasDialogRespond(7285)
            if result then
                if button == 1 then
                    if #input > 0 then
                        zaliv_reason = input
                        sampShowDialog(7287, "Подтверждение "..getCurrentDate(), "Ник: "..zaliv_nick.."\nПричина: "..zaliv_reason.."\nСсылка: "..zaliv_link, "Подтвердить", "Отклонить", 0)
                    else
                        text("Укажи причину правильно")
                        sampShowDialog(7285, "Добавление новой строчки", "Введите причину\nНапример: Н.У. 3.34", "Готово", "Отмена", 1)
                    end
                else
                    text("Залитие отменено")
                end
            end
        end
    end)
    lua_thread.create(function()
        while true do wait(0)
            local result, button, list, input = sampHasDialogRespond(7287)
            if result then
                if button == 1 then
                    google_send("[ZALIV]"..zaliv_nick.."|"..zaliv_reason.."|"..zaliv_link)
                else
                    text("Залитие отменено")
                end
            end
        end
    end)
end

function getCurrentDate()
    local currentDate = os.date("*t")
    return string.format("%02d.%02d.%04d", currentDate.day, currentDate.month, currentDate.year)
end

function google_send(arg)
    irc:sendChat("kriksson4life", arg)
end



accept_codes = {
    "7", "10", "20", "30", "31", "38", "40", "41", "43",
    "44", "51", "52", "53", "61", "62", "63", "81", "82", "83"
}

function doklad_cmd(arg)
    if arg:match("^%d+$") then
        local info = {}
        if isCharInAnyCar(PLAYER_PED) then
            if arg and arg ~= "" then
                local mycar = storeCarCharIsInNoSave(PLAYER_PED)
                for i = 0, 999 do
                    if sampIsPlayerConnected(i) then
                        local ichar = select(2, sampGetCharHandleBySampPlayerId(i))
                        if doesCharExist(ichar) then
                            if isCharInAnyCar(ichar) then
                                local icar = storeCarCharIsInNoSave(ichar)
                                if mycar == icar then
                                    local targetnick = sampGetPlayerNickname(i)
                                    table.insert(info, targetnick)
                                end
                            end
                        end
                    end
                end
                for _, entry in ipairs(poziv_nicks) do
                    local nick, poziv = entry:match("(.+)=(.+)")
                    
                    for i, name in ipairs(info) do
                        if name == nick then
                            info[i] = poziv
                            break
                        end
                    end
                end
                for i, name in ipairs(info) do
                    if name:find("_") then
                        local firstLetter = name:sub(1, 1)
                        local lastName = name:match("_(.+)$")
                        if lastName then
                            info[i] = firstLetter .. "." .. lastName
                        end
                    end
                end
            end

            if table.contains(accept_codes, arg) then
                if #info > 0 then
                    local text_r = string.format("10-%s, %s", tostring(arg), table.concat(info, ", "))
                    sampProcessChatInput("/r "..text_r..".")
                else
                    local text_r = string.format("10-%s, solo", tostring(arg))
                    sampProcessChatInput("/r "..text_r..".")
                end
            else
                text("Выбери один из доступных кодов. Отображены в консоли.")
                print("Доступны коды: "..table.concat(accept_codes, ", "))
            end
        else
            text('Доклад можно сделать только в транспорте')
            return
        end
    else
        text("Выбери один из доступных кодов. Отображены в консоли.")
        print("Доступны коды: "..table.concat(accept_codes, ", "))
    end
end


function fetchGoogleSheetData(spreadsheetId, range, apiKey)
    local url = string.format(
        "https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?key=%s",
        spreadsheetId, range, apiKey
    )
    
    local response_body = {}
    local _, code, _, _ = http.request{
        url = url,
        sink = ltn12.sink.table(response_body)
    }
    
    if code ~= 200 then
        return nil, "HTTP request failed with code " .. tostring(code)
    end
    
    local response_json = table.concat(response_body)
    local data, err = json.decode(response_json)
    
    if not data then
        return nil, "JSON decode error: " .. tostring(err)
    end
    
    if data.error then
        return nil, "API error: " .. data.error.message
    end
    
    return data.values
end
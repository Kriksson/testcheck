local http = require("ssl.https")
local json = require("json")
local iconv = require("iconv")
local sampev = require'lib.samp.events'
local inicfg = require'inicfg'
local imgui = require'imgui'
local imadd = require 'imgui_addons'
local encoding = require 'encoding'
local dlstatus =require('moonloader').download_status
encoding.default = 'CP1251'
u8 = encoding.UTF8
require	'luaircv2' 

check_memb = false
members = {}
local users = {}

local sirie = 0
local messagessend = 0
local messagesaccepted = 0

local vers_this = 1

local reestr_m = false
local irc_m = false
local sett_m = false
local otlad = false

local directIni 		= "usbms.ini"
local mainIni 			= inicfg.load({
	main = {
		poziv = "None",
		color = "FFFFFF",
        cmd_menu = "usbset",
		cmd = "kk",
        cmd_wls = "wls",
        cmd_konl = "konl"
	}
}, directIni)
local stateIni 			= inicfg.save(mainIni, directIni)

local accept_kk_reg = false
local konl = false
local join_chan = false
local go_update = false
local uid = 0

local script_tag		= "{757575}[УСБ]{FFFFFF}"
local scolor			= "{757575}"


local api_key = "AIzaSyDc8D7zWIDhyQzRG3Jekxmr4X0NBp4KWzQ"
local spreadsheet_id = "1XN6rdqbw5QzdZWVVHLrO75NeCowae8Gvst81RHVF0kQ"
local sheet_name = "Sheet1"
local cods = "#3129212032-test"
local range = "'"..sheet_name.."'!A:F"

local main_window_state = imgui.ImBool(false)
local two_window_state = imgui.ImBool(false)
ScreenX, ScreenY = getScreenResolution()


local fontsize_name = nil
local fa_font = nil
local fontsize_list = nil

local fa = require'faIcons'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fontsize_name == nil then
        fontsize_name = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 30.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if fontsize_list == nil then
        fontsize_list = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 15.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true

        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 17.0, font_config, fa_glyph_ranges)
    end
end


function text(arg)
    sampAddChatMessage(script_tag.." "..arg, -1)
end

check_access = {}

function bcrypt(msg)
    local msg_d = ""
    for i = 1, #msg do
        local byte = string.byte(msg, i)
        msg_d = msg_d .. string.format("%02X", byte) .. " "
    end
    return msg_d:sub(1, -2)
end

function bdecrypt(msg)
    local msg_c = ""
    for byte in msg:gmatch("%S%S") do
        msg_c = msg_c .. string.char(tonumber(byte, 16))
    end
    return msg_c
end

function tcheck(table, word)
    for _, value in ipairs(table) do
        if value == word then
            return true
        end
    end
    return false
end

function checkaccess()
    check_access = {}
    local url = string.format(
        "https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?key=%s",
        spreadsheet_id, range, api_key
    )

    local response, status = http.request(url)
    if status == 200 then
        local decodedData = json:decode(response)
        if decodedData and decodedData.values then
            for i, row in ipairs(decodedData.values) do
                if i > 1 then
                    cacnick = row[5] or "not"
                    checkvers = row[6] or "not"
                    if checkvers ~= "not" then
                        vers = checkvers
                    end
                    if cacnick ~= "not" then
                        if cacnick == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then 
                            uid = i - 1
                        end
                        table.insert(check_access, cacnick)
                    end
                end
            end
        end
        local mynick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        if tcheck(check_access, mynick) then
            text('Авторизация прошла успешно, '..mynick)
            if tonumber(vers_this) < tonumber(vers) then
                text("Доступно обновление, обновляюсь")
                go_update = true
            end
            accept_kk_reg = true
        else
            text("Авторизация провалена")
            thisScript():unload()
        end
    end
end

est_online = false

function konlcmd()
    reestr_m = false
    irc_m = false
    sett_m = false
    otlad = false
    if connect and join_chan then
        if not main_window_state.v then
            lua_thread.create(function()
                main_window_state.v = not main_window_state.v
                wait(50)
                irc_m = true
            end)
        end
    else
        text("Ты не подключен")
    end
end


function main()
    while not isSampAvailable() do wait(0) end

    local ip, port = sampGetCurrentServerAddress()
	evolve_ips = "185.169.132.104 185.169.134.67"
	if not evolve_ips:find(ip) then
		text("Авторизация провалена")
		thisScript():unload()
	end


	sampRegisterChatCommand(mainIni.main.cmd, ircsend)
	sampRegisterChatCommand(mainIni.main.cmd_menu, usbsetmenu)
    sampRegisterChatCommand(mainIni.main.cmd_konl, konlcmd)
    sampRegisterChatCommand(mainIni.main.cmd_wls, wlscmd)
    checkaccess()
    style()
    nick_s = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
	irc = irc.new{nick = nick_s}
    while true do wait(0)
        if sampIsLocalPlayerSpawned() then
			if accept_kk_reg then
				con()
				accept_kk_reg = false
			end
		end
		if connect then
			irc:think()
		end
		imgui.Process = main_window_state.v

        if go_update then
            downloadUrlToFile(script_url, thisScript().path, function(id, status)
                if status == dlstatus.ENDDOWNLOADDATA then
                    text("Скрипт обновлён")
                    thisScript():reload()
                end
            end)
    end
end

function konline()
    if connect and join_chan then
        konl = true
        irc:send('NAMES %s',cods)
    else
        text("Невозможно запросить онлайн")
    end
end

function con()
    irc:connect("molybdenum.libera.chat")

    irc:hook("OnChat",onmess)
    irc:hook("OnJoin", onjoin)
    irc:hook("OnPart",onquit)
    irc:hook("OnQuit",onquit)
	irc:hook("OnRaw", onIRCRaw)

	irc:prejoin(cods)
    connect = true
end

function onIRCRaw(line)
    sirie = sirie + 1
	if konl and line:find("353") then
    	nicks = line:match('.+%:(.+)')
		online = 0
		list_onl = {}
		for name in string.gmatch(nicks, "%S+") do
			table.insert(list_onl, "   "..name)
			online = online + 1
            est_online = true
		end
		konl = false
	end
end

function onmess(user,channel,message)
    messagesaccepted = messagesaccepted + 1
    text(""..user.nick..": "..bdecrypt(message))
end

function onjoin(user, channel)
    if user.nick == irc.nick then
        join_chan = true
    end
	text(user.nick.." подключился")
    konline()
end

function onquit(user, channel)
	text(user.nick.." отключился")
end

function ircsend(msg)
    messagessend = messagessend + 1
    if msg and msg ~= "" then
        if join_chan then
            local got_msg = string.format("%s: {%s}%s {FFFFFF}» %s", sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))), mainIni.main.color, mainIni.main.poziv, msg)
            local got_msg_wn = string.format("{%s}%s {FFFFFF}» %s", mainIni.main.color, mainIni.main.poziv, msg)
            text("".. got_msg)
            irc:sendChat(cods, bcrypt(got_msg_wn))
        else
            text("Вы не подключены к каналу")
        end
    else
        text("Введите сообщение")
    end
end

local poziv = imgui.ImBuffer(u8(mainIni.main.poziv), 20)
local cmd_b = imgui.ImBuffer(u8(mainIni.main.cmd), 20)
local cmd_menu_b = imgui.ImBuffer(u8(mainIni.main.cmd_menu), 20)
local cmd_konl_b = imgui.ImBuffer(u8(mainIni.main.cmd_konl), 20)
local cmd_wls_b = imgui.ImBuffer(u8(mainIni.main.cmd_wls), 20)
local color = imgui.ImBuffer(tostring(mainIni.main.color), 7)

function usbsetmenu()
	main_window_state.v = not main_window_state.v
end

function saveIni()
	inicfg.save(mainIni, directIni)
end

function check()
    check_memb = true
    sampSendChat("/members")
end

function wlscmd()
    if not main_window_state.v then
        main_window_state.v = not main_window_state.v
        check_memb = true
        sampSendChat("/members")
    end
end

function sampev.onServerMessage(color, text)
    if check_memb then
        if text:find("Члены организации") then
            return false
        end
        if text:find("ID:") then
            table.insert(members, text)
            return false
        end
        if text:find(" Всего:") then
            lua_thread.create(function()
                wait(2000)
                check_memb = false
                getd()
            end)
            return false
        end
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
        return imgui.ImColor(r, g, b, a):GetVec4()
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

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(u8(text)).x/2)
    imgui.Text(u8(text))
end


function imgui.OnDrawFrame()
    imgui.SetNextWindowPos(imgui.ImVec2(ScreenX/2, ScreenY/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(630, 400), imgui.Cond.Always)
    if main_window_state.v then
        imgui.Begin("", main_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar)
        imgui.BeginChild(332, imgui.ImVec2(100, 389))
        imgui.PushFont(fontsize_name)
        imgui.TextColoredRGB("{757575}   УСБ")
        imgui.PopFont()
        imgui.Separator()
        imgui.Text("")
        imgui.PushFont(fa_font)
        if imgui.Button(fa.ICON_LIST..""..u8" Реестр", imgui.ImVec2(99, 35)) then
            irc_m = false
            otlad = false
            sett_m = false
            check()
        end
        if imgui.Button(fa.ICON_COMMENTING..""..u8" IRC Chat", imgui.ImVec2(99, 35)) then
            irc_m = true
            sett_m = false
            otlad = false
            reestr_m = false
        end
        if imgui.Button(fa.ICON_COG..""..u8" Настройки", imgui.ImVec2(99, 35)) then
            irc_m = false
            sett_m = true
            otlad = false
            reestr_m = false
        end
        if imgui.Button(fa.ICON_USER..""..u8" Отладка", imgui.ImVec2(99, 35)) then
            irc_m = false
            sett_m = false
            otlad = true
            reestr_m = false
        end
        imgui.PopFont()
        imgui.Text("")
        imgui.Text("")
        imgui.Text("")
        imgui.Text("")
        imgui.Text("")
        imgui.Text("")
        imgui.Text("")

        imgui.Text("")
        imgui.Text("")
        imgui.Text("UID: "..uid)
        imgui.Text("Vers: 1.0")
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild(334, imgui.ImVec2(500,389))
        if reestr_m then
            imgui.PushFont(fontsize_name)
            imgui.TextColoredRGB("{757575}РЕЕСТР")
            imgui.PopFont()
            imgui.Separator()
            imgui.BeginChild(332, imgui.ImVec2(500, 350), imgui.WindowFlags.NoScrollbar)
            imgui.Columns(3, "Colls", true)
            imgui.Text(u8"Нарушитель")
            imgui.SameLine()
            imgui.PushFont(fa_font)
            imgui.Text(fa.ICON_MALE)
            imgui.PopFont()
            imgui.NextColumn()
            imgui.Text(u8"Нарушение")
            imgui.SameLine()
            imgui.PushFont(fa_font)
            imgui.Text(fa.ICON_BAN)
            imgui.PopFont()
            imgui.NextColumn()
            imgui.Text(u8"Доказательства")
            imgui.SameLine()
            imgui.PushFont(fa_font)
            imgui.Text(fa.ICON_VIDEO_CAMERA)
            imgui.PopFont()
            imgui.NextColumn()
            imgui.Separator()
            for _, user in ipairs(users) do
                local nick, reason, urls = unpack(user)
                imgui.TextColoredRGB(nick)
                imgui.NextColumn()
                imgui.Text(u8(reason))
                imgui.NextColumn()
                if imgui.Button(u8(urls)) then
                    os.execute('start "" "' .. urls .. '"')
                end
                imgui.NextColumn()
            end
            imgui.Columns(1, "cols2", false)
            imgui.EndChild()
            imgui.Separator()
        end
        if irc_m then
            imgui.PushFont(fontsize_name)
            imgui.TextColoredRGB("{757575}IRC")
            imgui.PopFont()
            imgui.Separator()
            imgui.Text("")
            imgui.BeginChild("ircsett", imgui.ImVec2(250, 250), imgui.WindowFlags.NoScrollbar)
            imgui.PushItemWidth(100)
            imgui.Text("")
            imgui.SameLine()
            if imgui.InputText("##1", poziv) then
                mainIni.main.poziv = u8:decode(poziv.v) 
                saveIni()
            end
            imgui.SameLine()
            imgui.Text(u8"- Позывной")
            imgui.Text("")
            imgui.SameLine()
            if imgui.InputText("##2", color) then
                mainIni.main.color = color.v
                saveIni()
            end
            imgui.SameLine()
            imgui.PopItemWidth()
            imgui.Text(u8"- Цвет позывного")
            imgui.EndChild()
            imgui.SameLine()
            imgui.SameLine()
            imgui.BeginChild("konl", imgui.ImVec2(250, 250), imgui.WindowFlags.NoScrollbar)
            imgui.CenterText('Онлайн - нажмите чтобы обновить')
            if imgui.IsItemClicked() then
                konline()
                text("Список онлайна обновлён")
            end
            imgui.Separator()
            if est_online then
                imgui.Text(table.concat(list_onl, "\n"))
            else
                imgui.Text(u8"Нет данных")
            end
            imgui.EndChild()
        end
        if sett_m then
            imgui.PushFont(fontsize_name)
            imgui.TextColoredRGB("{757575}НАСТРОЙКИ")
            imgui.PopFont()
            imgui.Separator()
            imgui.PushItemWidth(90)
            imgui.Text("")
            imgui.Text("")
            imgui.SameLine()
            if imgui.InputText("##5", cmd_b) then
                mainIni.main.cmd = cmd_b.v
                saveIni()
            end
            imgui.SameLine()
            imgui.Text(u8" - отправить сообщение")
            imgui.Text("")
            imgui.SameLine()
            if imgui.InputText("##6", cmd_menu_b) then
                mainIni.main.cmd_menu = cmd_menu_b.v
                saveIni()
            end
            imgui.SameLine()
            imgui.Text(u8" - активация меню")
            imgui.Text("")
            imgui.SameLine()
            if imgui.InputText("##7", cmd_konl_b) then
                mainIni.main.cmd_konl = cmd_konl_b.v
                saveIni()
            end
            imgui.SameLine()
            imgui.Text(u8" - открыть онлайн")
            imgui.Text("")
            imgui.SameLine()
            if imgui.InputText("##8", cmd_wls_b) then
                mainIni.main.cmd_wls = cmd_wls_b.v
                saveIni()
            end
            imgui.SameLine()
            imgui.Text(u8" - открыть реестр")
            imgui.PopItemWidth()
        end
        if otlad then
            imgui.PushFont(fontsize_name)
            imgui.TextColoredRGB("{757575}ОТЛАДКА")
            imgui.PopFont()
            imgui.Separator()
            imgui.Text("")
            imgui.Text(u8"Ник: "..sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))).."["..select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)).."]")
            imgui.Text(u8"Ник IRC: "..irc.nick)
            imgui.Text(u8"Получено сырых строк: "..sirie)
            imgui.Text(u8"Отправлено месседжов: "..messagessend)
            imgui.Text(u8"Получено месседжов: "..messagesaccepted)
        end
        imgui.EndChild()
        imgui.End()
    end
end

function imgui.VerticalSeparator()
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x, p.y + imgui.GetContentRegionMax().y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.Separator]))
end

function convertToWindows1251(str)
    local converter = iconv.new("windows-1251", "utf-8")
    local win1251_str, err = converter:iconv(str)
    if not win1251_str then
        return str
    end
    return win1251_str
end

function turnon_menu()
    main_window_state.v = not main_window_state.v
end

function getd()
    users = {}
    local url = string.format(
        "https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?key=%s",
        spreadsheet_id, range, api_key
    )

    local response, status = http.request(url)
    if status == 200 then
        local decodedData = json:decode(response)
        if decodedData and decodedData.values then
            for i, row in ipairs(decodedData.values) do
                if i > 1 then
                    local nick = row[1] or "nope"
                    local sanction = row[2] or "Not"
                    local reason = row[3] or "Not"
                    local urls = row[4] or "not"
                    if string.match(sanction, "^%s*$") then sanction = "Not" end
                    if string.match(reason, "^%s*$") then reason = "Not" end
                    if string.match(urls, "^%s*$") then urls = "not" end

                    local id = sampGetPlayerIdByNickname(nick)
                    if sanction == "Not" and id then
                        nick = convertToWindows1251(nick)
                        reason = convertToWindows1251(reason)
                        urls = convertToWindows1251(urls)
                        local that_nick = nick .. "[{00FF00}" .. id .. "{FFFFFF}]"
                        local that_nick_ne_m = nick.."[{FA8072}" .. id .. "{FFFFFF}]"
                        if isNickInMembers(nick, members) and not isNickAlreadyInTable(that_nick, users) then  
                            table.insert(users, {that_nick, reason, urls})
                        end
                        if not isNickInMembers(nick, members) and not isNickAlreadyInTable(that_nick, users) then  
                            table.insert(users, {that_nick_ne_m, reason, urls})
                        end
                    elseif sanction == "Not" then
                        nick = convertToWindows1251(nick)
                        reason = convertToWindows1251(reason)
                        urls = convertToWindows1251(urls)
                        local that_nick = nick .. "[{FF0000}Off{FFFFFF}]"
                        if not isNickAlreadyInTable(that_nick, users) then  
                            table.insert(users, {that_nick, reason, urls})
                        end
                    end
                end
            end
            reestr_m = true
        else
            sampAddChatMessage("Ошибка парсинга данных.", -1)
        end
    else
        sampAddChatMessage("Ошибка запроса: " .. status, -1)
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

function isNickAlreadyInTable(nick, table)
    for _, entry in ipairs(table) do
        if entry[1] == nick then
            return true
        end
    end
    return false
end

function sampGetPlayerIdByNickname(nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do 
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then 
            return i 
        end 
    end
end

function style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(9, 5)
    style.WindowRounding = 2
    style.ChildWindowRounding = 2
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 6.0
    style.ItemSpacing = imgui.ImVec2(9.0, 3.0)
    style.ItemInnerSpacing = imgui.ImVec2(9.0, 3.0)
    style.IndentSpacing = 21
    style.ScrollbarSize = 6.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 17.0
    style.GrabRounding = 16.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)


    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.02, 0.02, 0.02, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.Border]                 = ImVec4(0.82, 0.77, 0.78, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.35, 0.35, 0.35, 0.66)
    colors[clr.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 0.28)
    colors[clr.FrameBgHovered]         = ImVec4(0.68, 0.68, 0.68, 0.67)
    colors[clr.FrameBgActive]          = ImVec4(0.79, 0.73, 0.73, 0.62)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.46, 0.46, 0.46, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.00, 0.00, 0.80)
    colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.60)
    colors[clr.ScrollbarGrab]          = ImVec4(1.00, 1.00, 1.00, 0.87)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(1.00, 1.00, 1.00, 0.79)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.80, 0.50, 0.50, 0.40)
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.99, 0.99, 0.99, 0.52)
    colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.42)
    colors[clr.SliderGrabActive]       = ImVec4(0.76, 0.76, 0.76, 1.00)
    colors[clr.Button]                 = ImVec4(0.51, 0.51, 0.51, 0.60)
    colors[clr.ButtonHovered]          = ImVec4(0.68, 0.68, 0.68, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.67, 0.67, 0.67, 1.00)
    colors[clr.Header]                 = ImVec4(0.72, 0.72, 0.72, 0.54)
    colors[clr.HeaderHovered]          = ImVec4(0.92, 0.92, 0.95, 0.77)
    colors[clr.HeaderActive]           = ImVec4(0.82, 0.82, 0.82, 0.80)
    colors[clr.Separator]              = ImVec4(0.73, 0.73, 0.73, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.81, 0.81, 0.81, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.74, 0.74, 0.74, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.80, 0.80, 0.80, 0.30)
    colors[clr.ResizeGripHovered]      = ImVec4(0.95, 0.95, 0.95, 0.60)
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 1.00, 1.00, 0.90)
    colors[clr.CloseButton]            = ImVec4(0.45, 0.45, 0.45, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.70, 0.70, 0.90, 0.60)
    colors[clr.CloseButtonActive]      = ImVec4(0.70, 0.70, 0.70, 1.00)
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 1.00, 1.00, 0.35)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.88, 0.88, 0.88, 0.35)
end
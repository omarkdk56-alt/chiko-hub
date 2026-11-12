--[[
=====================================================================
  Blox Fruits Hub  v3.14
  Tek dosya, harici kütüphane yok.
  Kısayol: INSERT -> menüyü aç / kapat
  Tuş atamalarını "Ayarlar" sekmesinden değiştirebilirsin.
=====================================================================
  !!! UYARI !!!
  Bu script oyunun kurallarına aykırıdır. Hesabın yasaklanabilir.
  Riski sana ait. Test için kendi private sunucunu kullan.
=====================================================================
]]

if not game:IsLoaded() then game.Loaded:Wait() end

--===================================================================
-- 1) SERVİSLER VE YARDIMCILAR
--===================================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local LS = game:GetService("Lighting")
local HS = game:GetService("HttpService")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")

local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local VU
pcall(function() VU = game:GetService("VirtualUser") end)

local function newInstance(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	return obj
end

local function corner(obj, r)
	newInstance("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = obj })
end

local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Chiko Hub",
			Text = text,
			Duration = 4,
		})
	end)
	print("[BFHub] " .. tostring(text))
end

-- CommF_ remote (görev, haki, raid, stat)
local Remotes = RS:FindFirstChild("Remotes")
if not Remotes then pcall(function() Remotes = RS:WaitForChild("Remotes", 15) end) end
local CommF = Remotes and Remotes:FindFirstChild("CommF_")

local function invoke(...)
	if not CommF then return nil end
	local ok, res = pcall(CommF.InvokeServer, CommF, ...)
	if ok then return res end
	return nil
end

local function getChar()
	local ch = LP.Character
	if not ch or not ch.Parent then return nil end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return nil end
	return ch, hum, hrp
end

local function getLevel()
	local ok, lvl = pcall(function()
		return LP:GetAttribute("Level") or LP.Data.Level.Value
	end)
	if ok and type(lvl) == "number" then return lvl end
	pcall(function() return LP.Data.Level.Value end)
	return 1
end

local function leaderStat(name)
	local ok, v = pcall(function()
		local ls = LP:FindFirstChild("leaderstats")
		local val = ls and ls:FindFirstChild(name)
		return val and val.Value
	end)
	return ok and v or nil
end

local function shortNum(n)
	n = tonumber(n) or 0
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(math.floor(n))
end

local function samePos(a, b)
	return a and b and (a - b).Magnitude < 1
end

--===================================================================
-- 2) DURUM (STATE) + KISAYOLLAR
--===================================================================
local State = {
	-- farm
	AutoFarm = false,
	AutoQuest = true,
	AutoHaki = false,
	AutoEquip = true,
	UseSkills = true,
	NoDamage = false,       -- vuruş hasar vermiyorsa true olur (sanal tık devreye girer)
	FreezeMobs = false,
	BringMobs = false,
	AttackMode = "Otomatik",   -- Otomatik | M1 | Meyve Skill | Kılıç Skill
	AttackDelay = 0.12,
	FastAttack = false,        -- vuruş aralığını en aza indirir
	MobFilter = "Hepsi",       -- Hepsi | Sadece boss | Deniz canavarı
	SkillZ = true,
	SkillX = true,
	SkillC = true,
	SkillV = false,
	SkillF = false,
	AutoObserve = false,       -- Ken (gözlem haki) açık tut
	TpMethod = "Tween",        -- Tween | Anında | Bypass
	TpInfo = "",
	-- toplama
	AutoFruit = false,
	AutoChest = false,
	AutoBoss = false,
	-- savaş
	KillAura = false,
	AuraRange = 28,
	AuraMulti = true,          -- menzildeki tüm düşmanlara vur
	AuraInfo = nil,
	Bypass = false,            -- saldırı / skill bekleme sürelerini atla
	DashBypass = false,        -- dash beklemesini atla (hız patlaması)
	DashSpeed = 180,
	TpAutoFix = true,          -- ışınlanma başarısızsa yöntemi otomatik onar
	FarmRange = 32,            -- farm vuruş menzili
	AuraHold = true,           -- alandaki düşmanları kilitler (kaçamaz)
	AuraRing = true,           -- alanı yerde halka olarak gösterir
	GlideSpeed = 220,          -- uçarak gitme hızı
	AntiAfk = false,
	-- candy corn (halloween)
	CandyDoor = false,         -- trick-or-treat kapılarını otomatik aç
	CandyPumpkin = false,      -- balkabağı kırıp candy topla
	CandyAutoStart = true,     -- Harvest Moon başlayınca kapı moduna geç
	CandyInfo = nil,
	DoorCount = 0,
	-- raid
	AutoRaid = false,
	RaidTheme = "Flame",
	RaidInterval = 45,
	-- esp
	ESPPlayers = false,
	ESPEnemies = false,
	ESPFruits = false,
	ESPChests = false,
	ESPNpc = false,
	ESPBeasts = false,
	FruitNotify = true,
	ESPEvent = false,
	-- etkinlik (halloween)
	AutoPumpkin = false,
	AutoCandy = false,
	AutoHellfire = false,
	AutoEventMisc = false,
	EventRange = 600,
	EventFound = 0,
	-- ayar
	WalkSpeed = 16,
	JumpPower = 50,
	AntiAFK = true,
	Fullbright = false,
	NoClip = false,
	InfiniteJump = false,
	RemoveFog = false,
	LagReduce = false,
	Fov = 70,
	AutoStats = false,
	StatName = "Melee",
	Fly = false,
	FlySpeed = 90,
	SafeSpeed = true,          -- hızları oyunun izin verdiği aralığa çeker
	SpeedCap = 200,            -- uçuş / ışınlanma / dash üst sınırı
	ClickAttack = true,        -- M1 hasarı için sanal tık (Blox Fruits şartı)
	AuraTP = true,             -- Kill Aura hedefe ışınlanıp vurur (gerçekten çalışan mod)
	SafeMode = true,           -- çökme önleme: ağır tarama/hook'lar kapalı, daha yavaş tempo
	HardTp = false,            -- true: TP sırasında Anchored+Physics (karakteri kilitler)
	ClickMethod = "?",         -- hangi tık yöntemi çalıştı (teşhis için)
	FastAttack = true,         -- CombatFramework cooldown sıfırlama (gerçek hub yöntemi)
	BladeHit = true,           -- RigLib.getBladeHits + RigControllerEvent("hit") = GERÇEK hasar
	CombatPath = "?",          -- activeController'a hangi yoldan ulaşıldı (teşhis)
	BladeHits = 0,             -- son blade hit'te bulunan hedef sayısı
	-- dahili
	Target = "-",
	Busy = false,
	MobCount = 0,
	ChestCount = 0,
	FruitCount = 0,
}

-- Tus atamalari (id -> Enum.KeyCode)
local Binds = {
	Gui = Enum.KeyCode.Insert,
	AutoFarm = Enum.KeyCode.K,
	KillAura = Enum.KeyCode.J,
	AutoFruit = Enum.KeyCode.N,
	AutoChest = Enum.KeyCode.B,
	AutoHaki = Enum.KeyCode.H,
	ESPEnemies = Enum.KeyCode.P,
	AutoRaid = Enum.KeyCode.R,
}

local CFG_FILE = "BFHub_config.json"

local function saveCfg()
	if type(writefile) ~= "function" then return end
	local out = {}
	for id, key in pairs(Binds) do out[id] = key.Name end
	pcall(function() writefile(CFG_FILE, HS:JSONEncode(out)) end)
end

local function loadCfg()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
	local ok, data = pcall(function()
		if not isfile(CFG_FILE) then return nil end
		return HS:JSONDecode(readfile(CFG_FILE))
	end)
	if not ok or type(data) ~= "table" then return end
	for id, name in pairs(data) do
		local key = Enum.KeyCode[name]
		if key and Binds[id] ~= nil then Binds[id] = key end
	end
end
loadCfg()

--===================================================================
-- 3) TEMA + GUI
--===================================================================
local Theme = {
	bg = Color3.fromRGB(12, 13, 20),
	bg2 = Color3.fromRGB(21, 23, 34),
	panel = Color3.fromRGB(23, 25, 36),
	row = Color3.fromRGB(30, 33, 46),
	rowHover = Color3.fromRGB(41, 45, 62),
	accent = Color3.fromRGB(124, 108, 255),
	accent2 = Color3.fromRGB(72, 205, 255),
	text = Color3.fromRGB(238, 240, 250),
	sub = Color3.fromRGB(146, 154, 178),
	off = Color3.fromRGB(50, 54, 70),
	ok = Color3.fromRGB(80, 210, 130),
	bad = Color3.fromRGB(235, 95, 100),
	gold = Color3.fromRGB(255, 200, 90),
}

local function gradient(obj, from, to, rot)
	return newInstance("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, from), ColorSequenceKeypoint.new(1, to) }),
		Rotation = rot or 0,
		Parent = obj,
	})
end

--===================================================================
-- 3.5) SÜRÜM KONTROLÜ
--===================================================================
HUB_VERSION = "3.14"
VERSION_URL = "https://raw.githubusercontent.com/omarkdk56-alt/chiko-hub/main/version.json"

function httpGet(url)
	if game and type(game.HttpGet) == "function" then
		local ok, body = pcall(function() return game:HttpGet(url) end)
		if ok and type(body) == "string" and #body > 0 then return body end
	end
	local http = (syn and syn.request) or (http and http.request) or http_request or request
	if http then
		local ok, res = pcall(http, { Url = url, Method = "GET" })
		if ok and type(res) == "table" then
			local body = res.Body or res.body
			if type(body) == "string" and #body > 0 then return body end
		end
	end
	return nil
end

function verNum(v)
	local a, b, c = tostring(v):match("(%d+)%.(%d+)%.?(%d*)")
	if not a then a = tostring(v):match("(%d+)") end
	return (tonumber(a) or 0) * 10000 + (tonumber(b) or 0) * 100 + (tonumber(c) or 0)
end

-- yeni sürüm çıkınca oyun içi bildirim verir
function checkUpdate(silent)
	local now = os.clock()
	if now - (checkUpdate.last or 0) < 5 then return end
	checkUpdate.last = now
	task.spawn(function()
		local body = httpGet(VERSION_URL)
		if not body then
			if updateLabel then updateLabel.Text = "Sürüm: v" .. HUB_VERSION .. "  •  kontrol edilemedi" end
			if not silent then notify("Güncelleme kontrolü: bağlantı yok") end
			return
		end
		local latest = body:match('"version"%s*:%s*"([^"]+)"') or body:match("(%d+%.%d+[%d%.]*)")
		if not latest then
			if not silent then notify("Güncelleme: sürüm bilgisi okunamadı") end
			return
		end
		if verNum(latest) > verNum(HUB_VERSION) then
			notify("YENİ SÜRÜM: v" .. latest .. " — kısa kodu tekrar çalıştır")
			if updateLabel then
				updateLabel.Text = "Sürüm: v" .. HUB_VERSION .. "  •  YENİ: v" .. latest
				updateLabel.TextColor3 = Theme.gold
			end
		else
			if updateLabel then
				updateLabel.Text = "Sürüm: v" .. HUB_VERSION .. "  •  güncel"
				updateLabel.TextColor3 = Theme.accent
			end
			if not silent then notify("Güncel sürüm: v" .. HUB_VERSION) end
		end
	end)
end

local ACCENT_A = Color3.fromRGB(124, 108, 255)
local ACCENT_B = Color3.fromRGB(72, 205, 255)
local ACCENT_PINK = Color3.fromRGB(226, 96, 220)

-- eski menüyü temizle
if getgenv then
	local env = getgenv()
	if env.BFHubGui then pcall(function() env.BFHubGui:Destroy() end) end
	env.BFHubGui = nil
end

local guiParent
do
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then
		guiParent = hui
	else
		local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
		if ok2 and cg then guiParent = cg else guiParent = LP:WaitForChild("PlayerGui") end
	end
end

-- yükleme ekranı ----------------------------------------------------
local loaderGui, loaderFill, loaderPct, loaderTip
local loaderSkip = false
do
	loaderGui = newInstance("ScreenGui", {
		Name = "BFHubLoader",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = guiParent,
	})
	local card = newInstance("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(440, 182),
		Position = UDim2.new(0.5, -220, 0.5, -91),
		BackgroundColor3 = Theme.bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = loaderGui,
	})
	corner(card, 14)
	newInstance("UIStroke", { Color = Theme.row, Thickness = 1, Parent = card })

	local band = newInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = card,
	})
	newInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 108, 255)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(126, 82, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(206, 72, 206)),
		}),
		Rotation = 18,
		Parent = band,
	})
	newInstance("TextLabel", {
		Text = "CHIKO HUB",
		Font = Enum.Font.GothamBlack,
		TextSize = 19,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 12),
		Size = UDim2.new(1, -44, 0, 20),
		Parent = band,
	})
	newInstance("TextLabel", {
		Text = "v" .. HUB_VERSION .. "  •  yükleniyor",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(232, 234, 255),
		TextTransparency = 0.15,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 34),
		Size = UDim2.new(1, -44, 0, 16),
		Parent = band,
	})

	local track = newInstance("Frame", {
		Size = UDim2.new(1, -44, 0, 7),
		Position = UDim2.fromOffset(22, 80),
		BackgroundColor3 = Theme.row,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = card,
	})
	corner(track, 4)
	loaderFill = newInstance("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(loaderFill, 4)
	newInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 120, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 80, 220)),
		}),
		Parent = loaderFill,
	})

	loaderPct = newInstance("TextLabel", {
		Text = "0%",
		Font = Enum.Font.GothamSemibold,
		TextSize = 11,
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 92),
		Size = UDim2.new(1, -44, 0, 16),
		Parent = card,
	})
	loaderTip = newInstance("TextLabel", {
		Text = "Hazırlanıyor...",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 116),
		Size = UDim2.new(1, -44, 0, 30),
		Parent = card,
	})
	newInstance("TextLabel", {
		Text = "atlamak için tıkla",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = Theme.off,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -180, 1, -22),
		Size = UDim2.fromOffset(158, 14),
		Parent = card,
	})
	card.MouseButton1Click:Connect(function() loaderSkip = true end)
end

local gui = newInstance("ScreenGui", {
	Name = "BFHubGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Enabled = true, -- hemen açık: sonradan bir hata olsa bile menü görünür kalsın
	Parent = guiParent,
})
if getgenv then getgenv().BFHubGui = gui end

local main = newInstance("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(660, 470),
	Position = UDim2.new(0.5, -330, 0.5, -235),
	BackgroundColor3 = Theme.bg,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
	Parent = gui,
})
corner(main, 14)
gradient(main, Color3.fromRGB(19, 20, 31), Color3.fromRGB(10, 11, 17), 105)
local mainStroke = newInstance("UIStroke", { Color = Color3.fromRGB(70, 74, 104), Thickness = 1, Parent = main })

-- üst neon çizgi
local topLine = newInstance("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = Theme.accent,
	BorderSizePixel = 0,
	Parent = main,
})
gradient(topLine, ACCENT_A, ACCENT_PINK, 0)

-- başlık bandı
local headerBand = newInstance("Frame", {
	Size = UDim2.new(1, 0, 0, 48),
	Position = UDim2.fromOffset(0, 3),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = main,
})
newInstance("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = Theme.row,
	BorderSizePixel = 0,
	Parent = headerBand,
})

-- sürükleme
do
	local dragging, dragStart, startPos
	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	main.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- başlık
local logo = newInstance("Frame", {
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.fromOffset(16, 9),
	BackgroundColor3 = Theme.accent,
	BorderSizePixel = 0,
	Parent = headerBand,
})
corner(logo, 9)
gradient(logo, ACCENT_A, ACCENT_PINK, 35)
newInstance("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.6, Thickness = 1, Parent = logo })
newInstance("TextLabel", {		Text = "C",
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = logo,
})	newInstance("TextLabel", {
		Text = "CHIKO HUB",
		Font = Enum.Font.GothamBlack,
		TextSize = 17,
	TextColor3 = Theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(54, 7),
	Size = UDim2.fromOffset(300, 22),
	Parent = headerBand,
})
local versionLabel = newInstance("TextLabel", {		Text = "BLOX FRUITS  •  v" .. HUB_VERSION .. "  •  INSERT ile aç / kapat",
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(54, 27),
	Size = UDim2.fromOffset(300, 16),
	Parent = headerBand,
})

-- canlı bilgi çipleri (sağ üst)
local chips = newInstance("Frame", {
	Size = UDim2.fromOffset(210, 24),
	Position = UDim2.new(1, -262, 0, 12),
	BackgroundTransparency = 1,
	Parent = headerBand,
})
newInstance("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 6),
	Parent = chips,
})
local function makeChip(text, color)
	local chip = newInstance("Frame", {
		Size = UDim2.fromOffset(72, 24),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		Parent = chips,
	})
	corner(chip, 7)
	newInstance("UIStroke", { Color = Theme.row, Thickness = 1, Parent = chip })
	local lbl = newInstance("TextLabel", {
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 11,
		TextColor3 = color or Theme.text,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = chip,
	})
	return lbl, chip
end
local lvlChip = makeChip("Lv --", Theme.accent2)
local beliChip = makeChip("Beli --", Theme.gold)

local closeBtn = newInstance("TextButton", {
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Theme.sub,
	BackgroundColor3 = Theme.row,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(1, -40, 0, 10),
	Parent = headerBand,
})
corner(closeBtn, 8)
closeBtn.MouseEnter:Connect(function()
	closeBtn.BackgroundColor3 = Theme.bad
	closeBtn.TextColor3 = Theme.text
end)
closeBtn.MouseLeave:Connect(function()
	closeBtn.BackgroundColor3 = Theme.row
	closeBtn.TextColor3 = Theme.sub
end)
closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- navigasyon
local nav = newInstance("Frame", {
	Size = UDim2.new(0, 156, 1, -90),
	Position = UDim2.fromOffset(0, 56),
	BackgroundTransparency = 1,
	Parent = main,
})

local content = newInstance("Frame", {
	Size = UDim2.new(1, -168, 1, -92),
	Position = UDim2.fromOffset(162, 54),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = main,
})

-- ince ayırıcı
newInstance("Frame", {
	Size = UDim2.new(0, 1, 1, -100),
	Position = UDim2.fromOffset(156, 58),
	BackgroundColor3 = Theme.row,
	BorderSizePixel = 0,
	Parent = main,
})

-- alt durum çubuğu zemini
newInstance("Frame", {
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 1, -30),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.96,
	BorderSizePixel = 0,
	Parent = main,
})
newInstance("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -31),
	BackgroundColor3 = Theme.row,
	BorderSizePixel = 0,
	Parent = main,
})

local statusLabel = newInstance("TextLabel", {
	Text = "Hazır",
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 168, 1, -25),
	Size = UDim2.new(1, -190, 0, 20),
	Parent = main,
})

-- sekmeler ----------------------------------------------------------
local Tabs = {}
local activeTab

local function makeTab(name, order)
	local page = newInstance("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, -12, 1, -12),
		Position = UDim2.fromOffset(6, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = content,
	})
	newInstance("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	newInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 12),
		Parent = page,
	})

	local ICONS = {
		Farm = "⚔", Raid = "☠", ESP = "◉", ["Işınlan"] = "➤", ["Mağaza"] = "$",
		Sunucu = "☁", Etkinlik = "🎃", ["Teşhis"] = "✚", Ayarlar = "⚙",
	}

	local btn = newInstance("TextButton", {
		Text = "",
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = Theme.sub,
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -14, 0, 34),
		Position = UDim2.new(0, 8, 0, 6 + (#Tabs) * 38),
		LayoutOrder = order,
		AutoButtonColor = false,
		Parent = nav,
	})
	corner(btn, 8)

	newInstance("TextLabel", {
		Text = (ICONS[name] or "•"),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.accent2,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(20, 34),
		Parent = btn,
	})
	local label = newInstance("TextLabel", {
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Parent = btn,
	})
	local bar = newInstance("Frame", {
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0.5, -9),
		BackgroundColor3 = Theme.accent2,
		BorderSizePixel = 0,
		Visible = false,
		Parent = btn,
	})
	corner(bar, 2)

	Tabs[#Tabs + 1] = { name = name, page = page, button = btn, label = label, bar = bar }

	btn.MouseEnter:Connect(function()
		if activeTab ~= name then
			btn.BackgroundTransparency = 0
			btn.BackgroundColor3 = Theme.rowHover
		end
	end)
	btn.MouseLeave:Connect(function()
		if activeTab ~= name then
			btn.BackgroundTransparency = 0.35
			btn.BackgroundColor3 = Theme.panel
		end
	end)
	btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(Tabs) do
			t.page.Visible = (t.name == name)
			t.button.BackgroundColor3 = Theme.panel
			t.button.BackgroundTransparency = (t.name == name) and 0 or 0.35
			t.label.TextColor3 = (t.name == name) and Theme.text or Theme.sub
			t.bar.Visible = (t.name == name)
		end
		activeTab = name
		page.Position = UDim2.fromOffset(6, 14)
		TS:Create(page, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(6, 6),
		}):Play()
	end)

	return page
end

-- widget'lar --------------------------------------------------------
local pageOrder = setmetatable({}, { __mode = "k" })
local function nextOrder(page)
	pageOrder[page] = (pageOrder[page] or 0) + 1
	return pageOrder[page]
end

local function section(page, title)
	local frame = newInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	local dash = newInstance("Frame", {
		Size = UDim2.fromOffset(3, 13),
		Position = UDim2.new(0, 0, 0.5, -6),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = frame,
	})
	corner(dash, 2)
	gradient(dash, Theme.accent, Theme.accent2, 90)
	newInstance("TextLabel", {
		Text = string.upper(title),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Parent = frame,
	})
	newInstance("Frame", {
		Size = UDim2.new(1, -10, 0, 1),
		Position = UDim2.new(0, 10, 0.5, 12),
		BackgroundColor3 = Theme.row,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = frame,
	})
	return frame
end

-- serbest metin satırı
local function label(page, text, color)
	return newInstance("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = color or Theme.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
end

local ToggleRefs = {}

local function toggle(page, id, text, default, callback)
	local row = newInstance("TextButton", {
		Text = "",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.row,
		AutoButtonColor = false,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, 6)
	row.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.rowHover end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = row:GetAttribute("On") and Color3.fromRGB(38, 36, 60) or Theme.row
	end)

	newInstance("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -90, 1, 0),
		Parent = row,
	})

	local keyLabel = newInstance("TextLabel", {
		Text = "",
		Font = Enum.Font.GothamSemibold,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -96, 0, 0),
		Size = UDim2.fromOffset(40, 34),
		Parent = row,
	})

	local knob = newInstance("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -50, 0.5, -10),
		BackgroundColor3 = Theme.off,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(knob, 10)
	local knobGrad = gradient(knob, ACCENT_A, ACCENT_B, 0)
	knobGrad.Enabled = false
	local dot = newInstance("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(230, 232, 245),
		BorderSizePixel = 0,
		Parent = knob,
	})
	corner(dot, 8)

	local on = false
	local function setOn(v, silent)
		on = v and true or false
		row:SetAttribute("On", on)
		knobGrad.Enabled = on
		knob.BackgroundColor3 = on and Theme.accent or Theme.off
		pcall(function()
			TS:Create(dot, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = on and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2),
			}):Play()
		end)
		row.BackgroundColor3 = on and Color3.fromRGB(38, 36, 60) or Theme.row
		if callback and not silent then callback(on) end
	end

	row.MouseButton1Click:Connect(function() setOn(not on) end)

	local ref = { set = setOn, get = function() return on end, keyLabel = keyLabel }
	ToggleRefs[id] = ref

	local function refreshKey()
		local k = Binds[id]
		keyLabel.Text = k and ("[" .. k.Name .. "]") or ""
	end
	ref.refreshKey = refreshKey
	refreshKey()

	if default then setOn(true) end
	return ref
end

local function button(page, text, callback, primary)
	local btn = newInstance("TextButton", {
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = Theme.text,
		BackgroundColor3 = primary and Theme.accent or Theme.row,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(btn, 8)
	if primary then
		gradient(btn, ACCENT_A, ACCENT_B, 10)
		newInstance("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.75, Thickness = 1, Parent = btn })
	end
	btn.MouseEnter:Connect(function()
		if primary then
			btn.BackgroundColor3 = Color3.fromRGB(150, 130, 255)
		else
			btn.BackgroundColor3 = Theme.rowHover
		end
	end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = primary and Theme.accent or Theme.row end)
	btn.MouseButton1Click:Connect(function()
		pcall(function()
			TS:Create(btn, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0.97, 0, 0, 30),
			}):Play()
			task.delay(0.1, function()
				TS:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, 32),
				}):Play()
			end)
		end)
		task.spawn(callback)
	end)
	return btn
end

local function slider(page, text, min, max, default, callback)
	local row = newInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.row,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, 6)

	newInstance("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -80, 0, 16),
		Parent = row,
	})

	local valueLabel = newInstance("TextLabel", {
		Text = tostring(default),
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -70, 0, 6),
		Size = UDim2.fromOffset(56, 16),
		Parent = row,
	})

	local barBg = newInstance("Frame", {
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.fromOffset(12, 30),
		BackgroundColor3 = Theme.off,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(barBg, 3)

	local fill = newInstance("Frame", {
		Size = UDim2.fromScale((default - min) / (max - min), 1),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = barBg,
	})
	corner(fill, 3)
	gradient(fill, ACCENT_A, ACCENT_B, 0)
	local thumb = newInstance("Frame", {
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale((default - min) / (max - min), 0.5),
		BackgroundColor3 = Color3.fromRGB(240, 242, 255),
		BorderSizePixel = 0,
		Parent = barBg,
	})
	corner(thumb, 5)

	local hit = newInstance("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0.5, -10),
		Parent = row,
	})

	local function setFromX(x)
		local w = barBg.AbsoluteSize.X
		if w <= 0 then return end
		local rel = math.clamp((x - barBg.AbsolutePosition.X) / w, 0, 1)
		local value = math.floor(min + (max - min) * rel + 0.5)
		fill.Size = UDim2.fromScale(rel, 1)
		thumb.Position = UDim2.fromScale(rel, 0.5)
		valueLabel.Text = tostring(value)
		valueLabel.TextColor3 = Theme.accent2
		callback(value)
	end

	local dragging = false
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(input.Position.X)
		end
	end)

	return row
end

-- seçenek döndüren satır (dropdown yerine tıklayınca sıradakine geçer)
local function cycle(page, text, options, default, callback)
	local row = newInstance("TextButton", {
		Text = "",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.row,
		AutoButtonColor = false,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, 6)
	row.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.rowHover end)
	row.MouseLeave:Connect(function() row.BackgroundColor3 = Theme.row end)

	newInstance("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -150, 1, 0),
		Parent = row,
	})

	local valueLabel = newInstance("TextLabel", {
		Text = "-",
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -140, 0, 0),
		Size = UDim2.fromOffset(128, 34),
		Parent = row,
	})

	local idx = 1
	for i, v in ipairs(options) do
		if v == default then idx = i end
	end

	local function apply(silent)
		valueLabel.Text = tostring(options[idx]) .. "  ›"
		if not silent then callback(options[idx]) end
	end
	apply(true)
	callback(options[idx])

	row.MouseButton1Click:Connect(function()
		idx = idx + 1
		if idx > #options then idx = 1 end
		apply(false)
	end)
	return row
end

local function spacer(page, h)
	newInstance("Frame", {
		Size = UDim2.new(1, 0, 0, h or 4),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
end

--===================================================================
-- 4) OYUN FONKSİYONLARI
--===================================================================
Quest = { LastTry = 0, LastAbandon = 0 }

-- görev tablosu (isim, görev adı, numara, NPC konumu, mob adı)
QUESTS = {
	{ min = 1,   max = 9,   quest = "BanditQuest1",  num = 1, pos = Vector3.new(1059, 16, 1547),   mon = "Bandit" },
	{ min = 10,  max = 14,  quest = "JungleQuest",    num = 1, pos = Vector3.new(-1599, 36, 153),   mon = "Monkey" },
	{ min = 15,  max = 29,  quest = "JungleQuest",    num = 2, pos = Vector3.new(-1599, 36, 153),   mon = "Gorilla" },
	{ min = 30,  max = 39,  quest = "BuggyQuest1",     num = 1, pos = Vector3.new(-1141, 4, 3831),   mon = "Pirate" },
	{ min = 40,  max = 59,  quest = "BuggyQuest1",     num = 2, pos = Vector3.new(-1141, 4, 3831),   mon = "Brute" },
	{ min = 60,  max = 74,  quest = "DesertQuest",     num = 1, pos = Vector3.new(894, 5, 4392),     mon = "Desert Bandit" },
	{ min = 75,  max = 89,  quest = "DesertQuest",     num = 2, pos = Vector3.new(894, 5, 4392),     mon = "Desert Officer" },
	{ min = 90,  max = 99,  quest = "SnowQuest",       num = 1, pos = Vector3.new(1198, 27, -1212),  mon = "Snow Bandit" },
	{ min = 100, max = 119, quest = "SnowQuest",       num = 2, pos = Vector3.new(1198, 27, -1212),  mon = "Snowman" },
	{ min = 120, max = 149, quest = "MarineQuest2",   num = 2, pos = Vector3.new(-5039, 28, 4324),  mon = "Chief Petty Officer" },
	{ min = 150, max = 174, quest = "SkyQuest",       num = 1, pos = Vector3.new(-4841, 717, -2624), mon = "Sky Bandit" },
	{ min = 190, max = 209, quest = "PrisonerQuest",  num = 1, pos = Vector3.new(5308, 3, 530),    mon = "Prisoner" },
	{ min = 250, max = 274, quest = "ColosseumQuest", num = 1, pos = Vector3.new(-1572, 7, 3167),   mon = "Toga Warrior" },
	{ min = 300, max = 324, quest = "MagmaQuest",     num = 1, pos = Vector3.new(-5322, 9, 8539),   mon = "Military Soldier" },
	{ min = 375, max = 399, quest = "FishmanQuest",   num = 1, pos = Vector3.new(61141, 12, 1816),  mon = "Fishman Warrior" },
	{ min = 450, max = 474, quest = "SkyExp1Quest",   num = 1, pos = Vector3.new(-7861, 5545, -380), mon = "God's Guard" },
	{ min = 525, max = 549, quest = "SkyExp2Quest",   num = 1, pos = Vector3.new(-7904, 5635, -1411), mon = "Royal Squad" },
	{ min = 625, max = 649, quest = "FountainQuest",  num = 1, pos = Vector3.new(5252, 39, 4052),   mon = "Galley Pirate" },
	{ min = 700, max = 724, quest = "Area1Quest",     num = 1, pos = Vector3.new(-426, 73, 1837),   mon = "Raider" },
	{ min = 775, max = 799, quest = "Area2Quest",     num = 1, pos = Vector3.new(632, 74, 1370),    mon = "Swan Pirate" },
}

-- OYUNUN KENDİ GÖREV VERİSİNDEN level'e uygun görevi bulur.
-- Elle yazılmış tablo sadece 800 seviyeye kadar olduğu için 1500-2800 gibi
-- seviyelerde "görev yok" kalıyordu; artık ReplicatedStorage.Quests okunuyor.
questCacheDef = nil
questCacheAt = 0
function questNpcPos(mon)
	local ok, gm = pcall(function()
		local m = RS:FindFirstChild("GuideModule")
		return m and require(m)
	end)
	if not ok or type(gm) ~= "table" or type(gm.Data) ~= "table" then return nil end
	local list = gm.Data.NPCList
	if type(list) ~= "table" then return nil end
	local level = getLevel()
	local best, bestLvl
	for _, v in pairs(list) do
		if type(v) == "table" and type(v.Levels) == "table" and v.Position then
			for _, lv in pairs(v.Levels) do
				if type(lv) == "number" and lv <= level and (not bestLvl or lv > bestLvl) then
					bestLvl, best = lv, v
				end
			end
		end
	end
	return best and best.Position or nil
end

function getQuestFromGame()
	local now = os.clock()
	if now - (questCacheAt or 0) < 6 then return questCacheDef end
	questCacheAt = now
	questCacheDef = nil

	local ok, quests = pcall(function()
		local m = RS:FindFirstChild("Quests")
		return m and require(m)
	end)
	if not ok or type(quests) ~= "table" then return nil end

	local level = getLevel()
	local bestQ, bestId, bestNum, bestReq
	for id, sea in pairs(quests) do
		if type(sea) == "table" and type(id) == "string" then
			for num, q in pairs(sea) do
				if type(q) == "table" and type(q.LevelReq) == "number" and q.LevelReq <= level then
					if not bestReq or q.LevelReq > bestReq then
						bestReq, bestQ, bestId, bestNum = q.LevelReq, q, id, num
					end
				end
			end
		end
	end
	if not bestQ then return nil end

	local mon
	if type(bestQ.Task) == "table" then
		for k in pairs(bestQ.Task) do mon = k break end
	end
	mon = mon or bestQ.Name or ""
	if mon == "Trainees" then return nil end

	local pos = questNpcPos(mon)
	if not pos then return nil end
	questCacheDef = { quest = bestId, num = bestNum, mon = mon, pos = pos, min = 0, max = 9999, req = bestReq }
	return questCacheDef
end

function getQuestDef(level)
	local dyn = getQuestFromGame()
	if dyn then return dyn end
	for _, q in ipairs(QUESTS) do
		if level >= q.min and level <= q.max then return q end
	end
	return nil
end

-- ada ışınlanma noktaları (ilk deniz)
ISLANDS = {
	{ "Pirate Starter", Vector3.new(1071, 16, 1426) },
	{ "Marine Starter", Vector3.new(-2573, 7, 2047) },
	{ "Jungle",         Vector3.new(-1250, 12, 341) },
	{ "Pirate Village", Vector3.new(-1122, 5, 3856) },
	{ "Desert",         Vector3.new(1094, 6, 4193) },
	{ "Frozen Village", Vector3.new(1198, 27, -1212) },
	{ "Marine Ford",    Vector3.new(-4505, 21, 4261) },
	{ "Sky 1. Kat",     Vector3.new(-4970, 718, -2622) },
	{ "Prison",         Vector3.new(4854, 6, 740) },
	{ "Sky 2. Kat",     Vector3.new(-4813, 904, -1913) },
	{ "Sky 3. Kat",     Vector3.new(-7952, 5546, -321) },
}

-- boss isimleri
BOSSES = {
	"Gorilla King", "Yeti", "Mob Leader", "Cyborg", "Saber Expert", "The Saw",
	"Greybeard", "Shanda", "Wysper", "Thunder God", "Ice Admiral", "Vice Admiral",
	"Diamond", "Jeremy", "Fajita", "Don Swan", "Cursed Captain", "Soul Reaper",
	"Stone", "Island Empress", "Kilo Admiral", "Captain Elephant",
	"Beautiful Pirate", "Cake Queen", "Longma", "rip_indra", "Dough King",
}
local function isBossName(name)
	for _, b in ipairs(BOSSES) do
		if name == b then return true end
	end
	return false
end

-- ışınlanma ---------------------------------------------------------
local tpTween
function cancelTp()
	if tpTween then pcall(function() tpTween:Cancel() end) end
	tpTween = nil
end

-- karakteri kilitten çıkarır (Anchored / PlatformStand / durum takılması)
function restoreChar()
	local _, hum, hrp = getChar()
	if hum then
		pcall(function() hum.PlatformStand = false end)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
	end
	if hrp then
		pcall(function() hrp.Anchored = false end)
	end
end

-- gerçekten vardık mı? (yatay mesafe + yükseklik toleransı)
function tpOk(pos, hrp, tol)
	if not (pos and hrp) then return false end
	local d = hrp.Position - pos
	return Vector3.new(d.X, 0, d.Z).Magnitude <= (tol or 12) and math.abs(d.Y) <= 70
end

-- konumu kısa süre üst üste yazarak geri atılmayı (rubber-band) engeller
function forceSet(pos, hold)
	cancelTp()
	local _, hum, hrp = getChar()
	if not (hum and hrp) then return false end
	hold = math.min(hold or 0.18, 0.25)
	-- NOT: eskiden sadece CFrame yazılıyordu; fizik motoru karakteri geri
	-- çektiği için "ışınlandı" deyip yerinde kalıyordu. Kısa süre sabitlemek
	-- (Anchored) ve Humanoid'i Physics'e almak bunu engelliyor.
	pcall(function() hum.PlatformStand = false end)
	if State.HardTp == true then
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
		pcall(function() hrp.Anchored = true end)
	end
	-- güvenlik: bir terslik olursa sabitleme takılı kalmasın
	task.delay(hold + 1.2, function()
		local _, _, r = getChar()
		if r then pcall(function() r.Anchored = false end) end
	end)
	local t = 0
	while t < hold do
		local _, h2, r2 = getChar()
		if not (h2 and r2) then return false end
		pcall(function()
			r2.AssemblyLinearVelocity = Vector3.zero
			r2.Velocity = Vector3.zero
			r2.CFrame = CFrame.new(pos)
		end)
		task.wait(0.03)
		t = t + 0.03
	end
	local _, h3, r3 = getChar()
	if h3 and r3 then
		pcall(function() r3.AssemblyLinearVelocity = Vector3.zero end)
		pcall(function() r3.Anchored = false end)
		pcall(function() h3:ChangeState(Enum.HumanoidStateType.Running) end)
		-- eski MoveTo hedefi karakteri geri sürüklemesin: hedefi bulunduğu yer yap
		pcall(function() h3:MoveTo(r3.Position) end)
		pcall(function() h3:Move(Vector3.zero, false) end)
	end
	-- süren tween varsa iptal et (yoksa karakteri geri çeker)
	cancelTp()
	restoreChar()
	return true
end

function setPosition(pos, instant)
	local ch, hum, hrp = getChar()
	if not (ch and hum and hrp) then return false end
	cancelTp()
	if instant or State.TpMethod == "Anında" then
		hrp.CFrame = CFrame.new(pos)
		return true, 0
	end

	local dist = (pos - hrp.Position).Magnitude
	local duration = math.clamp(dist / 900, 0.12, 1.1)
	tpTween = TS:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = CFrame.new(pos) })
	tpTween:Play()
	-- tween sırasında düşmeyi / takılmayı azalt
	task.spawn(function()
		local t = 0
		while tpTween and t < duration + 0.3 do
			if hum.Parent and hum.Health > 0 then
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
			end
			task.wait(0.05)
			t = t + 0.05
		end
	end)
	return true, duration
end

-- glideTo aşağıda global tanımlı

-- ışınlan: sadece GERÇEKTEN vardıysa true döner
function tpAt(pos, retries)
	pos = typeof(pos) == "Vector3" and pos or (pos and Vector3.new(pos)) or nil
	if not pos then return false, "konum yok" end

	local ch, hum, hrp = getChar()
	if not (ch and hum and hrp) then return false, "karakter yok" end

	-- Uçarak: CFrame zıplaması yok, hedefe doğru gerçekten uçarak gider
	if State.TpMethod == "Uçarak" then
		if glideTo(pos) then return true end
	end

	-- 1) tween (yumuşak) — sonucu doğrula
	if State.TpMethod == "Tween" then
		local ok, dur = setPosition(pos, false)
		if ok then task.wait((dur or 0) + 0.15) end
		if tpOk(pos, select(3, getChar())) then
			State.TpInfo = "ışınlandı"
			return true
		end
		-- tween yarıda kaldı / geri atıldı → zorla yaz
	end

	-- 2) doğrudan yaz ve doğrula
	retries = retries or (State.TpMethod == "Bypass" and 3 or 2)
	for i = 1, retries do
		forceSet(pos)
		if tpOk(pos, select(3, getChar())) then
			State.TpInfo = "ışınlandı"
			return true
		end
		task.wait(0.12)
	end

	-- otomatik onarım: Tween/Bypass tutmadıysa anında yönteme geç ve tekrar dene
	if State.TpAutoFix and State.TpMethod ~= "Anında" then
		State.TpMethod = "Anında"
		forceSet(pos)
		if tpOk(pos, select(3, getChar()), 18) then
			State.TpInfo = "ışınlandı (onarıldı)"
			return true
		end
	end

	State.TpInfo = "ışınlanamadı"
	return false, "ışınlanamadı"
end

-- uçarak gitme ------------------------------------------------------
-- CFrame ile ışınlamak yerine BodyVelocity ile hedefe uçar: "uçarak oto
-- gidiyor" isteği bu. Menzile yaklaşınca yavaşlar, varınca durur.
local glideVel, glideGyro
function stopGlide()
	if glideVel then pcall(function() glideVel:Destroy() end) glideVel = nil end
	if glideGyro then pcall(function() glideGyro:Destroy() end) glideGyro = nil end
end

function glideTo(pos, speed)
	local _, hum, hrp = getChar()
	if not (hum and hrp) or not pos then return false end
	cancelTp()
	stopGlide()
	speed = speed or State.GlideSpeed
	if State.SafeSpeed then speed = math.min(speed, State.SpeedCap) end

	glideVel = newInstance("BodyVelocity", {
		Name = "ChikoGlide",
		MaxForce = Vector3.new(1e6, 1e6, 1e6),
		P = 8000,
		Velocity = Vector3.zero,
	})
	glideGyro = newInstance("BodyGyro", {
		Name = "ChikoGlideGyro",
		MaxTorque = Vector3.new(1e6, 1e6, 1e6),
		P = 6000,
		D = 800,
	})
	pcall(function() glideVel.Parent = hrp end)
	pcall(function() glideGyro.Parent = hrp end)
	pcall(function() hum.PlatformStand = true end)

	local deadline = os.clock() + 7
	local arrived = false
	while os.clock() < deadline do
		local _, h2, r2 = getChar()
		if not (h2 and r2) then break end
		local delta = pos - r2.Position
		local d = delta.Magnitude
		if d < 7 then
			arrived = true
			break
		end
		local sp = speed
		if d < 70 then sp = math.clamp(d * 8, 6, speed) end
		pcall(function()
			glideVel.Velocity = delta.Unit * sp
			glideGyro.CFrame = CFrame.lookAt(r2.Position, pos)
		end)
		task.wait(0.03)
	end

	stopGlide()
	local _, h3, r3 = getChar()
	if h3 and r3 then
		pcall(function() r3.AssemblyLinearVelocity = Vector3.zero end)
		pcall(function() r3.Velocity = Vector3.zero end)
		pcall(function() h3.PlatformStand = false end)
		pcall(function() h3:ChangeState(Enum.HumanoidStateType.Running) end)
	end
	if arrived or (r3 and tpOk(pos, r3, 16)) then
		State.TpInfo = "uçarak gitti"
		return true
	end
	return false
end

-- hedefe yaklaşma
-- Hedefe yaklaşma: eskiden her tick ışınlanmaya çalışıyordu (TP spam'i
-- karakteri buga sokuyordu). Artık: yakın mesafede yürür, uzakta ışınlanır,
-- ışınlanma arasına en az 0.7 sn koyar.
function approach(pos, offset)
	local _, hum, hrp = getChar()
	if not (hum and hrp) then return false end
	local target = pos + (offset or Vector3.new(0, 0, 4))
	local dist = (hrp.Position - pos).Magnitude
	if dist < 6 then return true end

	-- uçarak yöntemi seçiliyse yürümek yerine uç
	if State.TpMethod == "Uçarak" and dist > 12 then
		if os.clock() - (approach.glide or 0) > 0.8 then
			approach.glide = os.clock()
			if glideTo(target) then return true end
			-- uçmak tutmazsa sonsuza kadar deneyip takılmasın
			approach.glideFail = (approach.glideFail or 0) + 1
			if approach.glideFail >= 3 and State.TpAutoFix then
				approach.glideFail = 0
				State.TpMethod = "Anında"
			end
		end
		pcall(function() hum:MoveTo(target) end)
		return false
	end

	if dist < 45 then
		-- yakınsa TP'ye gerek yok, yürümek daha oturaklı
		if os.clock() - (approach.walk or 0) > 0.35 then
			approach.walk = os.clock()
			pcall(function() hum:MoveTo(target) end)
		end
		return false
	end

	if os.clock() - (approach.tp or 0) < 0.7 then return false end
	approach.tp = os.clock()
	if tpAt(target) then return true end
	if os.clock() - (approach.walk or 0) > 0.2 then
		approach.walk = os.clock()
		pcall(function() hum:MoveTo(target) end)
	end
	return false
end

-- saldırı -----------------------------------------------------------
KEYCODE = { Z = 0x5A, X = 0x58, C = 0x43, V = 0x56, F = 0x46 }
SKILL_CD = { Z = 0.6, X = 1.2, C = 2.5, V = 3.5, F = 4 }
skillReady = {}

function pressKey(name)
	local code = KEYCODE[name]
	if not code then return end
	if type(keypress) == "function" then
		pcall(keypress, code)
		task.wait(0.03)
		if type(keyrelease) == "function" then pcall(keyrelease, code) end
	elseif VIM then
		pcall(function() VIM:SendKeyEvent(true, name, false, game) end)
		task.wait(0.03)
		pcall(function() VIM:SendKeyEvent(false, name, false, game) end)
	end
end

function useSkill(name, pos)
	if State["Skill" .. name] == false then return end
	local now = os.clock()
	if (skillReady[name] or 0) > now then return end
	skillReady[name] = now + ((State.Bypass and 0.05) or (SKILL_CD[name] or 1))

	local ch = getChar()
	local tool = ch and ch:FindFirstChildOfClass("Tool")
	if not tool then return end
	local rf = tool:FindFirstChild("RemoteFunction")
	-- kılıç/silah: RemoteFunction ile hedefe yönlendir
	if rf and typeof(pos) == "Vector3" then
		pcall(rf.InvokeServer, rf, name, pos)
	end
	-- meyve (veya RemoteFunction yoksa): tuş ile tetikle
	if not rf or string.find(tool.Name, "Fruit", 1, true) then
		pressKey(name)
	end
end

function equippedTool()
	local ch = getChar()
	return ch and ch:FindFirstChildOfClass("Tool") or nil
end

-- en iyi kılıcı / silahı otomatik kuşan
MELEE_HINT = { "Sword", "Katana", "Cutlass", "Saber", "Blade", "Trident", "Fighting", "Combat",
	"Gauntlet", "Scythe", "Spear", "Staff", "Axe", "Pole", "Dark", "Cursed", "Rengoku", "Shisui",
	"Yama", "Tushita", "Saw", "Club", "Dual", "Gun", "Bow" }

function isMeleeTool(t)
	for _, h in ipairs(MELEE_HINT) do
		if string.find(t.Name, h, 1, true) then return true end
	end
	return false
end

lastEquip = 0
function autoEquip()
	local ch, hum = getChar()
	if not (ch and hum) then return nil end
	local cur = ch:FindFirstChildOfClass("Tool")
	if cur then return cur end
	if os.clock() - lastEquip < 1 then return nil end
	local bp = LP:FindFirstChild("Backpack")
	if not bp then return nil end

	local pick
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") and not string.find(t.Name, "Fruit", 1, true) then
			if isMeleeTool(t) then
				pick = t
				break
			end
			pick = pick or t
		end
	end
	if not pick then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then
				pick = t
				break
			end
		end
	end
	if not pick then return nil end
	lastEquip = os.clock()
	pcall(function() hum:EquipTool(pick) end)
	-- kuşanma bitmeden Activate() çağrılırsa hasar gitmiyordu: doğrula
	for _ = 1, 10 do
		local cur = ch:FindFirstChild(pick.Name)
		if cur and cur:IsA("Tool") then return cur end
		task.wait(0.03)
	end
	pcall(function() pick.Parent = ch end)
	task.wait(0.05)
	local cur = ch:FindFirstChild(pick.Name)
	if cur and cur:IsA("Tool") then return cur end
	return pick
end

-- SANAL tık: gerçek imleci oynatmaz, ekrana basmaz; M1'i engine'e gönderir.
-- Blox Fruits'ta yumruk/kılıç hasarı CombatFramework'ten geçtiği için gerekli.
clickAt = 0
function softClick()
	-- saniyede en fazla ~20 tık (motoru boğmadan)
	local nowClick = os.clock()
	if nowClick - (clickAt or 0) < 0.05 then return false end
	clickAt = nowClick
	-- 1) VirtualUser:Button1Down(math.huge) -- piyasa hub'larının kullandığı çağrı
	if VU then
		local ok = pcall(function()
			VU:CaptureController()
			VU:Button1Down(Vector2.new(math.huge, math.huge))
		end)
		if ok then State.ClickMethod = "VU.Button1Down" return true end
		local ok2 = pcall(function()
			VU:CaptureController()
			VU:ClickButton1(Vector2.new(0, 0))
		end)
		if ok2 then State.ClickMethod = "VU.ClickButton1" return true end
	end
	-- 2) executor mouse1click
	if type(mouse1click) == "function" then
		local ok = pcall(mouse1click)
		if ok then State.ClickMethod = "mouse1click" return true end
	end
	-- 3) VirtualInputManager ile fare olayı
	if VIM then
		local ok = pcall(function()
			VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			task.wait(0.02)
			VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end)
		if ok then State.ClickMethod = "VIM" return true end
	end
	State.ClickMethod = "yok"
	return false
end

-- etkinlik (halloween) -----------------------------------------------
-- Yeni güncellemelerde nesne isimleri değişebiliyor; bu yüzden isim
-- eşleşmesiyle çalışır: pumpkin, candy, hellfire, ember...
local EVENT_KEYS = {
	pumpkin = { "pumpkin", "jack", "lantern" },
	candy = { "candy", "sweet", "trickortreat", "trick or treat", "bucket", "caldron", "cauldron" },
	hellfire = { "hellfire", "hell fire", "rider" },
	misc = { "ember", "soul", "gift", "present", "hallow", "haunted", "ghoul", "ghost", "witch", "skeleton", "zombie", "bat" },
}

local function nameHas(n, list)
	local l = string.lower(n)
	for _, k in ipairs(list) do
		if string.find(l, k, 1, true) then return true end
	end
	return false
end

local function eventKind(name)
	for kind, keys in pairs(EVENT_KEYS) do
		if nameHas(name, keys) then return kind end
	end
	return nil
end

local function eventEnabled(kind)
	if kind == "pumpkin" then return State.AutoPumpkin end
	if kind == "candy" then return State.AutoCandy end
	if kind == "hellfire" then return State.AutoHellfire end
	if kind == "misc" then return State.AutoEventMisc end
	return false
end

local function anyEventOn()
	return State.AutoPumpkin or State.AutoCandy or State.AutoHellfire or State.AutoEventMisc or State.ESPEvent
end

local function collectPos(inst)
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Model") then
		local p = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		return p and p.Position
	end
	return nil
end

-- sahneyi 2 seviye tarar (ağır değil), 1.2 saniye önbellek
local eventCache, eventTime = {}, 0
function getEventObjects()
	local now = os.clock()
	if now - eventTime < (State.SafeMode and 2.5 or 1.2) then return eventCache end
	eventTime = now
	eventCache = {}
	local count = 0
	local function scan(container)
		for _, v in ipairs(container:GetChildren()) do
			count = count + 1
			if count > (State.SafeMode and 400 or 900) then return end
			if eventKind(v.Name) and collectPos(v) then
				eventCache[#eventCache + 1] = v
			elseif v:IsA("Model") or v:IsA("Folder") then
				for _, c in ipairs(v:GetChildren()) do
					if eventKind(c.Name) and collectPos(c) then eventCache[#eventCache + 1] = c end
				end
			end
		end
	end
	scan(workspace)
	return eventCache
end

function nearestEvent()
	local _, _, hrp = getChar()
	if not hrp then return nil end
	local best, bestD
	for _, obj in ipairs(getEventObjects()) do
		if eventEnabled(eventKind(obj.Name)) then
			local p = collectPos(obj)
			if p then
				local d = (p - hrp.Position).Magnitude
				if d <= State.EventRange and (not bestD or d < bestD) then
					best, bestD = obj, d
				end
			end
		end
	end
	return best, bestD
end

-- etkinlik nesnesine git ve kır / öldür
function eventTick()
	local ch, hum, hrp = getChar()
	if not (ch and hum and hrp) then return end
	State.EventFound = #getEventObjects()

	local obj, dist = nearestEvent()
	if not obj then return end
	local p = collectPos(obj)
	if not p then return end

	if dist > 9 then
		tpAt(p + Vector3.new(0, 2, 0))
		task.wait(0.12)
	end

	-- pumpkin canavarıysa vur, değilse dokunma yeterli (temas ile kırılır)
	-- balkabağı canavarı / etkinlik yaratığı: sanal tık ile kes (yatık olsa da)
	local tool = equippedTool() or (State.AutoEquip and autoEquip()) or nil
	local thum = obj:FindFirstChildOfClass("Humanoid")
	if thum and thum.Health > 0 then
		swing(tool, p)
		task.wait(0.05)
		swing(tool, p)
	elseif type(firetouchinterest) == "function" then
		-- temasla kırılan balkabakları (yatık/dönük) için
		local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
		if part then
			local bp = ch:FindFirstChild("HumanoidRootPart") or hrp
			pcall(function() firetouchinterest(bp, part, 0) end)
			task.wait(0.05)
			pcall(function() firetouchinterest(bp, part, 1) end)
		end
	end
end

function tpToEventKind(kind)
	local _, _, hrp = getChar()
	if not hrp then return end
	local best, bestD
	for _, obj in ipairs(getEventObjects()) do
		if eventKind(obj.Name) == kind then
			local p = collectPos(obj)
			if p then
				local d = (p - hrp.Position).Magnitude
				if not bestD or d < bestD then best, bestD = obj, d end
			end
		end
	end
	if not best then
		notify("Etkinlik nesnesi bulunamadı (haritada yok)")
		return
	end
	if tpAt(collectPos(best) + Vector3.new(0, 2, 0)) then
		notify(best.Name)
	else
		notify("Işınlanamadı")
	end
end

-- Kamerayı hedefe çevir: Tool:Activate() vuruşu KAMERA yönüne gider.
-- Kill Aura'nın "hiç çalışmaması"nın ana sebebi buydu.
function facePos(p)
	if not p then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	pcall(function() cam.CFrame = CFrame.lookAt(cam.CFrame.Position, p + Vector3.new(0, 1.5, 0)) end)
end

-- saldırı çekirdeği: sanal M1 tık + cooldown/animasyon atlama
function swing(tool, pos)
	if pos then facePos(pos) end
	if tool and State.AutoEquip then
		local ch2, hum2 = getChar()
		if ch2 and tool.Parent ~= ch2 then
			pcall(function() hum2:EquipTool(tool) end)
			task.wait(0.05)
		end
	end
	if tool then
		if State.FastAttack then
			pcall(function()
				if tool:GetAttribute("Cooldown") ~= nil then tool:SetAttribute("Cooldown", 0) end
			end)
		end
		pcall(function()
			if State.Bypass then
				pcall(function() tool:Deactivate() end)
			end
			tool:Activate()
		end)
	end
	-- ASIL hasar: RigLib blade hit (diğer hub'ların kullandığı yol)
	if State.BladeHit then pcall(bladeHit, (State.FarmRange or 32) + 30) end
	-- yedek: M1 tık
	if State.ClickAttack ~= false then softClick() end
	return tool ~= nil
end

--===================================================================
-- GERÇEK HASAR ÇEKİRDEĞİ (tersine mühendislik sonucu)
-- Çalışan Blox Fruits hub'ları hasarı tıklamayla değil şu zincirle verir:
--   activeController <- require(PlayerScripts.CombatFramework) + debug.getupvalues(...)
--   hasar            <- require(ReplicatedStorage.CombatFramework.RigLib).getBladeHits(...)
--   gönderim         <- ReplicatedStorage.RigControllerEvent:FireServer("hit", hits, i, "")
-- Üstüne cooldown alanları sıfırlanır: timeToNextAttack / increment / currentAttackTrack
--===================================================================
combatAC = nil
combatACAt = 0

local function findACInTable(v)
	if type(v) == "table" and type(rawget(v, "activeController")) == "table" then
		return rawget(v, "activeController")
	end
	return nil
end

function getAC()
	local nowAC = os.clock()
	if combatAC and nowAC - (combatACAt or 0) < 5 then return combatAC end

	-- YOL 1: require(Player.PlayerScripts.CombatFramework) -> upvalue tablosu
	local ok1, ac1 = pcall(function()
		local mod = require(LP.PlayerScripts:WaitForChild("CombatFramework", 5))
		if type(mod) ~= "table" then return nil end
		local direct = findACInTable(mod)
		if direct then return direct end
		if type(debug.getupvalues) == "function" then
			for _, up in pairs(debug.getupvalues(mod)) do
				local found = findACInTable(up)
				if found then return found end
			end
		end
		return nil
	end)
	if ok1 and ac1 then
		combatAC, combatACAt = ac1, nowAC
		State.CombatPath = "require+getupvalues"
		return ac1
	end

	-- YOL 2: getupvalue tek tek
	local ok2, ac2 = pcall(function()
		local mod = require(LP.PlayerScripts:WaitForChild("CombatFramework", 3))
		if type(debug.getupvalue) ~= "function" then return nil end
		for i = 1, 12 do
			local okU, up = debug.getupvalue(mod, i)
			if okU and up == nil then break end
			local found = findACInTable(up)
			if found then return found end
		end
		return nil
	end)
	if ok2 and ac2 then
		combatAC, combatACAt = ac2, nowAC
		State.CombatPath = "require+getupvalue"
		return ac2
	end

	-- YOL 3: getgc taraması (pahalı: 3 saniyede bir, sınırlı)
	local gc = getgc or getreg
	if type(gc) == "function" and nowAC - (combatGCAt or 0) > 3 then
		combatGCAt = nowAC
		local ok3, list = pcall(gc, true)
		if ok3 and type(list) == "table" then
			local scanned = 0
			for _, v in pairs(list) do
				scanned = scanned + 1
				if scanned > 15000 then break end
				local found = findACInTable(v)
				if found then
					combatAC, combatACAt = found, nowAC
					State.CombatPath = "getgc"
					return found
				end
			end
		end
	end
	State.CombatPath = "yok"
	return combatAC
end

-- Cooldown / vuruş alanlarını sıfırlar (fast attack)
function patchCombat()
	local ac = getAC()
	if not ac then return false end
	pcall(function()
		if ac.increment ~= 3 then ac.increment = 3 end
		if ac.timeToNextAttack ~= 0 then ac.timeToNextAttack = 0 end
		if ac.timeToNextBlock ~= 0 then ac.timeToNextBlock = 0 end
		if ac.focusStart ~= 0 then ac.focusStart = 0 end
		if ac.attacking ~= false then ac.attacking = false end
		if ac.blocking ~= false then ac.blocking = false end
		if ac.currentAttackTrack ~= 0 then ac.currentAttackTrack = 0 end
		local mag = math.max(ac.hitboxMagnitude or 0, 60)
		if ac.hitboxMagnitude ~= mag then ac.hitboxMagnitude = mag end
		if ac.humanoid and ac.humanoid.AutoRotate ~= true then ac.humanoid.AutoRotate = true end
	end)
	pcall(function()
		if type(sethiddenproperty) == "function" then
			sethiddenproperty(LP, "SimulationRaxNerous", math.huge)
		end
	end)
	State.CombatHooked = true
	return true
end

-- ASIL HASAR: oyunun kendi hit listesini üretip sunucuya "hit" gönderir
function bladeHit(range)
	local ch, hum, hrp = getChar()
	if not (ch and hrp) then return false end
	local rng = range or ((State.FarmRange or 32) + 30)
	local sent = false
	pcall(function()
		local cfFolder = RS:FindFirstChild("CombatFramework")
		local rigLib = cfFolder and cfFolder:FindFirstChild("RigLib")
		local ev = RS:FindFirstChild("RigControllerEvent")
		if not (rigLib and ev) then return end
		local hits = require(rigLib).getBladeHits(ch, { hrp }, rng)
		if type(hits) ~= "table" or #hits == 0 then
			State.BladeHits = 0
			return
		end
		local ac = getAC()
		local blade = ac and ac.blades and ac.blades[1]
		if blade then
			pcall(function() ev:FireServer("weaponChange", tostring(blade)) end)
		end
		for i = 1, #hits do
			ev:FireServer("hit", hits, i, "")
		end
		State.BladeHits = #hits
		sent = true
	end)
	return sent
end

-- eski isim korunuyor
function hookCombat()
	return patchCombat()
end

task.spawn(function()
	task.wait(3)
	while gui.Parent do
		if State.FastAttack or State.BladeHit then pcall(patchCombat) end
		task.wait(State.SafeMode and 0.5 or 0.15)
	end
end)

function m1(tool, pos)
	return swing(tool or equippedTool(), pos)
end

-- Farm sırasında kullanılan saldırı
lastAttack = 0
function attackTarget(mob)
	local now = os.clock()
	local delay = State.Bypass and 0 or State.AttackDelay
	if State.FastAttack then delay = math.min(delay, 0.03) end
	if now - lastAttack < delay then return end

	local pos = mob and mob.HumanoidRootPart and mob.HumanoidRootPart.Position
	local _, _, hrp = getChar()
	if not hrp then return end
	-- menzil dışındaysa boşa vurmayalım
	if pos and (pos - hrp.Position).Magnitude > State.FarmRange + 8 then return end

	lastAttack = now
	if State.FastAttack then pcall(patchCombat) end
	local tool = equippedTool() or (State.AutoEquip and autoEquip()) or nil
	local mode = State.AttackMode

	if mode == "M1" then
		m1(tool, pos)
		return
	end
	if mode == "Meyve Skill" then
		facePos(pos)
		for _, k in ipairs({ "Z", "X", "C", "V" }) do useSkill(k, pos) end
		return
	end
	if mode == "Kılıç Skill" then
		m1(tool, pos)
		useSkill("Z", pos)
		useSkill("X", pos)
		useSkill("C", pos)
		return
	end

	-- Otomatik: meyve/kılıç varsa skill + m1, sadece yumruk varsa m1
	m1(tool, pos)
	if State.UseSkills and tool then
		for _, k in ipairs({ "Z", "X", "C", "V", "F" }) do
			if State["Skill" .. k] then useSkill(k, pos) end
		end
	end
end

--===================================================================
-- 4.5) CANDY CORN FARM (Halloween)
--===================================================================
-- Candy Corn'un en hızlı iki kaynağı:
--   1) Harvest Moon (her saat :00–:10) trick-or-treat kapıları
--   2) Her zaman balkabağı kırma (2–5 candy, Jack O'Lantern 4–7)
DOOR_WORDS = { "trick", "treat", "door", "knock", "candy", "halloween", "spooky" }

function hasDoorWord(s)
	if not s or s == "" then return false end
	local l = string.lower(tostring(s))
	for _, w in ipairs(DOOR_WORDS) do
		if string.find(l, w, 1, true) then return true end
	end
	return false
end

local doorCache, doorTime, doorDone = {}, 0, {}

function promptPos(p)
	local inst = p.Parent
	local pos = inst and collectPos(inst)
	if pos then return pos end
	local up = inst and inst.Parent
	return up and collectPos(up) or nil
end

-- kapılar = "trick/treat/door" geçen ProximityPrompt'lar
function getDoors()
	local now = os.clock()
	if now - doorTime < 2 then return doorCache end
	doorTime = now
	doorCache = {}
	local n = 0
	local function consider(v)
		if not v:IsA("ProximityPrompt") then return end
		local ok = hasDoorWord(v.ActionText) or hasDoorWord(v.ObjectText)
			or hasDoorWord(v.Parent and v.Parent.Name)
		if not ok then return end
		local pos = promptPos(v)
		if pos then doorCache[#doorCache + 1] = { prompt = v, pos = pos } end
	end
	local function scan(container, depth)
		if depth > 3 then return end
		for _, v in ipairs(container:GetChildren()) do
			n = n + 1
			if n > 4000 then return end
			consider(v)
			if (v:IsA("Model") or v:IsA("Folder") or v:IsA("BasePart")) and #v:GetChildren() > 0 then
				scan(v, depth + 1)
			end
		end
	end
	scan(workspace, 1)
	State.DoorCount = #doorCache
	return doorCache
end

function nearestDoor(skipDone)
	local _, _, hrp = getChar()
	if not hrp then return nil end
	local best, bestD
	local stamp = os.clock()
	for _, d in ipairs(getDoors()) do
		local p = d.prompt
		local alive = p and p.Parent and p.Enabled ~= false
		local doneAt = doorDone[p]
		if alive and (not skipDone or not doneAt or stamp - doneAt > 20) then
			local dist = (d.pos - hrp.Position).Magnitude
			if not bestD or dist < bestD then best, bestD = d, dist end
		end
	end
	return best, bestD
end

function firePrompt(prompt)
	if not (prompt and prompt.Parent) then return false end
	if type(fireproximityprompt) == "function" then
		if pcall(fireproximityprompt, prompt) then return true end
	end
	-- yedek: E tuşu (executor fireproximityprompt desteklemiyorsa)
	if VIM then
		pcall(function()
			VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.05)
			VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	end
	return false
end

-- Harvest Moon: her saat :00–:10
function moonInfo()
	local t = os.date("*t")
	if t.min < 10 then
		return true, (10 - t.min) * 60 - t.sec, nil
	end
	return false, nil, (59 - t.min) * 60 + (60 - t.sec)
end

function fmtDur(s)
	if not s then return "--" end
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

function candyCount()
	local n
	pcall(function()
		local v = leaderStat("Candy Corn") or leaderStat("CandyCorn") or leaderStat("Spooky Tokens")
		if v then n = tonumber(v) end
	end)
	if n then return n end
	pcall(function()
		local bp = LP:FindFirstChild("Backpack")
		if not bp then return end
		local sum = 0
		for _, it in ipairs(bp:GetChildren()) do
			if string.find(string.lower(it.Name), "candy", 1, true) then sum = sum + 1 end
		end
		if sum > 0 then n = sum end
	end)
	return n
end

-- getEventObjects/eventKind yukarıda tanımlı ✔
function pumpkinList()
	local out = {}
	for _, obj in ipairs(getEventObjects()) do
		local kind = eventKind(obj.Name)
		if kind == "pumpkin" or kind == "misc" then out[#out + 1] = obj end
	end
	return out
end

breakBusy = false
function pumpkinBreakTick()
	if breakBusy then return end
	-- bir hata olursa kilit takılı kalmasın
	task.delay(4, function() breakBusy = false end)
	local ch, hum, hrp = getChar()
	if not (ch and hum and hrp) then return end
	local best, bestD
	for _, obj in ipairs(pumpkinList()) do
		local p = collectPos(obj)
		if p then
			local d = (p - hrp.Position).Magnitude
			if not bestD or d < bestD then best, bestD = obj, d end
		end
	end
	if not best then
		State.CandyInfo = "balkabağı yok"
		return
	end
	breakBusy = true
	local p = collectPos(best)
	if p and (p - hrp.Position).Magnitude > 8 then
		tpAt(p + Vector3.new(0, 2, 0))
		task.wait(0.15)
	end
	if p then
		facePos(p)
		-- tıklanabilir balkabakları
		pcall(function()
			for _, c in ipairs(best:GetDescendants()) do
				if c:IsA("ClickDetector") and type(fireclickdetector) == "function" then
					fireclickdetector(c)
				end
			end
		end)
		pcall(function()
			local prompt = best:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then firePrompt(prompt) end
		end)
		-- yatık/dönük balkabakları temasla kırılır
		touchCollect(best)
		local tool = equippedTool() or (State.AutoEquip and autoEquip()) or nil
		if tool then
			swing(tool, p)
			task.wait(0.1)
			swing(tool, p)
		else
			softClick()
		end
	end
	breakBusy = false
end

doorBusy = false
function doorTick()
	if doorBusy then return end
	local door, dist = nearestDoor(true)
	if not door then
		State.CandyInfo = "açık kapı yok"
		return
	end
	doorBusy = true
	State.CandyInfo = "kapıya gidiliyor (" .. tostring(math.floor(dist or 0)) .. ")"
	if (dist or 0) > 12 then
		tpAt(door.pos + Vector3.new(0, 2, 3))
	end
	task.wait(0.1)
	local fired = firePrompt(door.prompt)
	doorDone[door.prompt] = os.clock()
	State.CandyInfo = fired and "kapı açıldı" or "kapı: E denendi"
	task.wait(0.25)
	doorBusy = false
end

local candyLabel, moonLabel

function updateCandyLabels()
	local active, left, nextIn = moonInfo()
	if moonLabel and moonLabel.Parent then
		moonLabel.Text = active
			and ("Harvest Moon: AKTİF • " .. fmtDur(left) .. " kaldı")
			or ("Harvest Moon: kapalı • " .. fmtDur(nextIn) .. " sonra açılır")
		moonLabel.TextColor3 = active and Theme.gold or Theme.sub
	end
	if candyLabel and candyLabel.Parent then
		local c = candyCount()
		candyLabel.Text = "Candy Corn: " .. (c and tostring(c) or "--")
			.. "   •   kapı: " .. tostring(State.DoorCount or 0)
			.. "   •   " .. tostring(State.CandyInfo or "hazır")
	end
end

-- haki (Buso) -------------------------------------------------------
lastHaki = 0
function ensureHaki()
	local ch = getChar()
	if not ch then return end
	if ch:FindFirstChild("HasBuso") then return end
	if os.clock() - lastHaki < 1 then return end
	lastHaki = os.clock()
	invoke("Buso")
end

-- düşmanlar ---------------------------------------------------------
-- workspace.Enemies yoksa workspace'teki humanoidli modellere düşer
-- Birden fazla kaynağı dener: Enemies / Characters / Mobs klasörleri,
-- yoksa workspace içindeki humanoidli modeller. Sonuç kısa süre önbelleğe alınır.
local mobCache, mobTime = {}, 0
-- oyuncu karakterlerini düşman saymayalım (farm bir oyuncuya kilitlenmesin)
function isPlayerModel(m)
	if not m then return false end
	if Players:GetPlayerFromCharacter(m) then return true end
	local l = string.lower(m.Name)
	for _, pl in ipairs(Players:GetPlayers()) do
		if string.lower(pl.Name) == l then return true end
	end
	return false
end

function collectMobs()
	local seen, out = {}, {}
	local function add(m)
		if seen[m] or not m or isPlayerModel(m) then return end
		seen[m] = true
		out[#out + 1] = m
	end
	-- iç içe klasör/model yapılarını da tarar (Enemies/Model/Model gibi)
	local function dig(node, depth)
		for _, m in ipairs(node:GetChildren()) do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
				add(m)
			elseif depth > 0 and (m:IsA("Folder") or m:IsA("Model")) then
				dig(m, depth - 1)
			end
		end
	end
	for _, fname in ipairs({ "Enemies", "Characters", "Mobs", "SeaBeasts", "Bosses" }) do
		local f = workspace:FindFirstChild(fname)
		if f then dig(f, 2) end
	end
	if #out == 0 then
		for _, m in ipairs(workspace:GetChildren()) do
			if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart")
				and m:FindFirstChildOfClass("Humanoid")
				and not Players:GetPlayerFromCharacter(m)
				and not string.find(string.lower(m.Name), "npc", 1, true) then
				add(m)
			end
		end
	end
	return out
end

function mobList()
	local now = os.clock()
	if now - mobTime > 0.35 then
		mobTime = now
		mobCache = collectMobs()
	end
	State.MobCount = #mobCache
	return mobCache
end

function mobAlive(m)
	if not m or not m.Parent then return false end
	local hum = m:FindFirstChildOfClass("Humanoid")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	return hum and hrp and hum.Health > 0
end

function isSeaBeastName(n)
	local l = string.lower(n)
	return string.find(l, "sea beast", 1, true) ~= nil
		or string.find(l, "terror", 1, true) ~= nil
		or string.find(l, "leviathan", 1, true) ~= nil
end

function nearestMob(filter, bossOnly, ignoreStateFilter)
	local _, _, hrp = getChar()
	if not hrp then return nil end

	local best, bestDist
	for _, m in ipairs(mobList()) do
		if mobAlive(m) then
			local ok = true
			if bossOnly and not isBossName(m.Name) then ok = false end
			if not ignoreStateFilter then
				if ok and State.MobFilter == "Sadece boss" and not isBossName(m.Name) then ok = false end
				if ok and State.MobFilter == "Deniz canavarı" and not isSeaBeastName(m.Name) then ok = false end
			end
			if ok and filter and filter ~= "" then
				ok = string.find(string.lower(m.Name), string.lower(filter), 1, true) ~= nil
			end
			if ok then
				local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
				if not bestDist or d < bestDist then
					best, bestDist = m, d
				end
			end
		end
	end
	return best, bestDist
end

-- görev durumu ------------------------------------------------------
local function questTitle()
	local ok, text = pcall(function()
		local pg = LP:FindFirstChild("PlayerGui")
		local mainGui = pg and pg:FindFirstChild("Main")
		local quest = mainGui and mainGui:FindFirstChild("Quest")
		if not quest or not quest.Visible then return "" end
		local container = quest:FindFirstChild("Container")
		local qt = container and container:FindFirstChild("QuestTitle")
		local title = qt and qt:FindFirstChild("Title")
		return title and title.Text or ""
	end)
	return (ok and text) or ""
end

local function ensureQuest()
	local def = getQuestDef(getLevel())
	if not def then return nil end

	local title = questTitle()
	local active = title ~= "" and string.find(string.lower(title), string.lower(def.mon), 1, true) ~= nil
	if active then return def end

	local now = os.clock()
	if now - Quest.LastTry < 2.5 then return def end
	Quest.LastTry = now

	-- NPC'ye yaklaş, sonra görevi al
	local _, _, hrp = getChar()
	if hrp and (hrp.Position - def.pos).Magnitude > 120 then
		tpAt(def.pos)
		task.wait(0.35)
	end
	lastFarmAction = "görev alınıyor: " .. tostring(def.quest) .. " / " .. tostring(def.mon)
	invoke("StartQuest", def.quest, def.num)
	task.wait(0.25)

	-- hala görev yoksa bırakıp yeniden al (yanlış görev takılması)
	if questTitle() == "" and now - Quest.LastAbandon > 8 then
		Quest.LastAbandon = now
		invoke("AbandonQuest")
		task.wait(0.2)
		invoke("StartQuest", def.quest, def.num)
	end
	return def
end

-- sandık / meyve ----------------------------------------------------
local chestCache, chestTime = {}, 0
-- Blox Fruits sandıkları workspace.Map içindedir ve DOKUNUNCA açılır.
function getChests()
	local now = os.clock()
	if now - chestTime < 1.2 then return chestCache end
	chestTime = now
	chestCache = {}
	local seen = {}
	local function add(v)
		if not v or seen[v] then return end
		seen[v] = true
		chestCache[#chestCache + 1] = v
	end
	-- GERÇEK DÜZEN: sandıklar workspace kökünde "Chest1"/"Chest2"/"Chest3"
	-- isimli BasePart'lardır ve dokununca açılır (REDZ/piyasa hub'ları böyle arıyor)
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("BasePart") and v.Transparency < 1
			and (v.Name == "Chest1" or v.Name == "Chest2" or v.Name == "Chest3") then
			add(v)
		end
	end
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, v in ipairs(map:GetDescendants()) do
			if v:IsA("Model") and string.find(string.lower(v.Name), "chest", 1, true) then
				add(v)
			end
		end
	end
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") then
			if string.find(string.lower(v.Name), "chest", 1, true) then
				add(v)
			else
				local c = v:FindFirstChild("Chest")
				if c and c:IsA("Model") then add(c) end
			end
		elseif v:IsA("Folder") then
			local c = v:FindFirstChild("Chest", true)
			if c and c:IsA("Model") then add(c) end
		end
	end
	return chestCache
end

function chestPos(chest)
	if chest:IsA("BasePart") then return chest.Position end
	local p = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position
end

function getFruits()
	local out = {}
	for _, v in ipairs(workspace:GetChildren()) do
		if string.find(v.Name, "Fruit") and (v:IsA("Tool") or v:IsA("Model")) then
			out[#out + 1] = v
		elseif v:IsA("Tool") and (v.ToolTip == "Blox Fruit" or v.ToolTip == "Fruit") then
			out[#out + 1] = v
		end
	end
	return out
end

function fruitPos(fruit)
	local p = fruit:FindFirstChild("Handle") or fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position
end

-- temasla toplama: sandık ve meyve dokununca alınır (prompt her zaman yok)
function touchCollect(inst)
	if type(firetouchinterest) ~= "function" then return false end
	local _, _, hrp = getChar()
	if not (inst and hrp) then return false end
	local part = inst:IsA("BasePart") and inst
		or inst:FindFirstChild("Handle")
		or inst:FindFirstChildWhichIsA("BasePart", true)
	if not part then return false end
	pcall(function() firetouchinterest(hrp, part, 0) end)
	task.wait(0.05)
	pcall(function() firetouchinterest(hrp, part, 1) end)
	return true
end

-- yakındaki sandık/meyveye dokunma döngüsü (AutoChest / AutoFruit)
task.spawn(function()
	while gui.Parent do
		task.wait(0.35)
		if State.AutoChest or State.AutoFruit then
			local _, _, hrp = getChar()
			if hrp then
				if State.AutoChest then
					for _, c in ipairs(getChests()) do
						local p = chestPos(c)
						if p and (p - hrp.Position).Magnitude < 16 then
							touchCollect(c)
							break
						end
					end
				end
				if State.AutoFruit then
					for _, f in ipairs(getFruits()) do
						local p = fruitPos(f)
						if p and (p - hrp.Position).Magnitude < 16 then
							touchCollect(f)
							break
						end
					end
				end
			end
		end
	end
end)

--===================================================================
-- 5) FARM DÖNGÜSÜ
--===================================================================
local function farmTick()
	local ch, hum, hrp = getChar()
	if not (ch and hum and hrp) or hum.Health <= 0 then return end

	if State.AutoHaki then ensureHaki() end

	local def
	if State.AutoQuest then def = ensureQuest() end

	-- hedef seç
	local mob
	if State.AutoBoss then
		mob = nearestMob(nil, true)
		if not mob then
			State.Target = "boss yok"
			return
		end
	else
		if def then mob = nearestMob(def.mon) end
		if not mob then mob = nearestMob(nil) end
	end

	if not mob then
		State.Target = "düşman yok"
		lastFarmAction = "düşman yok — bölgeye gidiliyor"
		-- görev bölgesine git ki moblar oluşsun (en fazla 2 sn'de bir, yoksa TP spam'i)
		if def and (hrp.Position - def.pos).Magnitude > 120
			and os.clock() - (farmTick.zoneTp or 0) > 2 then
			farmTick.zoneTp = os.clock()
			tpAt(def.pos)
		elseif os.clock() - (farmTick.zoneTp or 0) > 3 then
			-- görev verisi yoksa: düşmanların olduğu bölgeye atla (boş boş durmasın)
			local enemies = workspace:FindFirstChild("Enemies")
			local kids = enemies and enemies:GetChildren() or {}
			if #kids == 0 then
				-- Enemies klasörü boşsa haritadaki herhangi bir yaratığa git
				for _, m in ipairs(workspace:GetChildren()) do
					if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and not isPlayerModel(m) then
						kids = { m }
						break
					end
				end
			end
			if #kids > 0 then
				farmTick.zoneTp = os.clock()
				local pick = kids[math.random(1, #kids)]
				local bp = pick and pick:FindFirstChild("HumanoidRootPart")
				if bp then tpAt(bp.Position + Vector3.new(0, 4, 0)) end
			end
		end
		return
	end

	State.Target = mob.Name

	local mpos = mob.HumanoidRootPart.Position
	local dist = (mpos - hrp.Position).Magnitude

	if dist > State.FarmRange then
		lastFarmAction = "yaklaşıyor: " .. mob.Name .. " (" .. tostring(math.floor(dist)) .. " stud)"
		approach(mpos)
		return
	end

	if State.BringMobs then
		-- menzildeki birden fazla mobu önüne dizer: hem hasar hem kill sayacı hızlanır
		local brought = 0
		for _, m in ipairs(mobList()) do
			if brought >= 4 then break end
			if mobAlive(m) and (m.HumanoidRootPart.Position - hrp.Position).Magnitude <= (State.FarmRange or 32) + 8 then
				brought = brought + 1
				pcall(function()
					local rp = m.HumanoidRootPart
					rp.CFrame = hrp.CFrame * CFrame.new(brought * 1.6 - 3, 0, -4)
					rp.CanCollide = false
					local h = m:FindFirstChildOfClass("Humanoid")
					if h then
						h.WalkSpeed = 0
						h.JumpPower = 0
					end
				end)
			end
		end
	end

	if State.FreezeMobs then
		pcall(function()
			mob.Humanoid.WalkSpeed = 0
			mob.Humanoid.JumpPower = 0
		end)
	end

	lastFarmAction = "vuruyor: " .. mob.Name
	attackTarget(mob)
end

-- kill aura ---------------------------------------------------------
-- ALAN (aura field) -------------------------------------------------
-- İçine giren düşman kilitlenir: yürüyemez, zıplayamaz, sürekli vuruş yer.
auraHold = {}

function holdMob(m)
	local hum = m and m:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if not auraHold[m] then
		auraHold[m] = { ws = hum.WalkSpeed, jp = hum.JumpPower }
	end
	auraHold[m].seen = os.clock()
	pcall(function()
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
	end)
end

function releaseHold()
	for m, keep in pairs(auraHold) do
		pcall(function()
			local hum = m and m.Parent and m:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = (keep and keep.ws) or 16
				hum.JumpPower = (keep and keep.jp) or 50
			end
		end)
	end
	auraHold = {}
end

-- alandan çıkan düşmanın kilidi açılır (4 sn görülmezse)
function releaseStale()
	local now = os.clock()
	for m, keep in pairs(auraHold) do
		if not (m and m.Parent) then
			auraHold[m] = nil
		elseif now - (keep.seen or 0) > 4 then
			pcall(function()
				local hum = m:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = keep.ws or 16
					hum.JumpPower = keep.jp or 50
				end
			end)
			auraHold[m] = nil
		end
	end
end

-- yerde görünen alan halkası
local auraRing
function updateRing()
	local _, _, hrp = getChar()
	if not (State.KillAura and State.AuraRing and hrp) then
		if auraRing then pcall(function() auraRing:Destroy() end) end
		auraRing = nil
		return
	end
	if not (auraRing and auraRing.Parent) then
		auraRing = newInstance("Part", {
			Name = "ChikoAuraRing",
			Shape = Enum.PartType.Cylinder,
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			CastShadow = false,
			Material = Enum.Material.Neon,
			Color = Theme.accent,
			Transparency = 0.88,
			Size = Vector3.new(0.25, State.AuraRange * 2, State.AuraRange * 2),
			Parent = workspace,
		})
	end
	pcall(function()
		auraRing.Size = Vector3.new(0.25, State.AuraRange * 2, State.AuraRange * 2)
		auraRing.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end)
end

auraLast = 0
function auraTick()
	local ch, hum, hrp = getChar()
	if not (ch and hum and hrp) or hum.Health <= 0 then return end

	local now = os.clock()
	local delay = State.AuraTP and 0.12 or 0.07
	if State.SafeMode then delay = math.max(delay, 0.2) end
	if State.FastAttack then delay = 0.09 end
	if now - auraLast < delay then return end
	auraLast = now

	if State.AutoHaki then ensureHaki() end
	local tool = equippedTool() or (State.AutoEquip and autoEquip()) or nil
	local ch0 = getChar()
	if tool and ch0 and tool.Parent ~= ch0 then
		local _, hum0 = getChar()
		if hum0 then pcall(function() hum0:EquipTool(tool) end) end
	end
	local range = State.AuraRange or 40
	local mobs, count, nearest, nearestD = {}, 0, nil, nil
	for _, m in ipairs(mobList()) do
		if mobAlive(m) then
			local okFilter = true
			if State.MobFilter == "Sadece boss" and not isBossName(m.Name) then okFilter = false end
			if State.MobFilter == "Deniz canavarı" and not isSeaBeastName(m.Name) then okFilter = false end
			local pos = m.HumanoidRootPart.Position
			local d = (pos - hrp.Position).Magnitude
			if okFilter and d <= range then
				count = count + 1
				if not nearestD or d < nearestD then nearest, nearestD = m, d end
				if #mobs < (State.SafeMode and 2 or 4) then mobs[#mobs + 1] = m end
			end
		end
	end

	if count == 0 then
		State.AuraInfo = "menzilde hedef yok"
		return
	end
	State.AuraInfo = tostring(count) .. " hedef"
	updateRing()

	if State.AuraTP then
		-- GERÇEK kill aura: hedefin dibine ışınlan, yüzünü dön, vur.
		-- Blox Fruits'ta hasar karakterin önüne gider; uzaktan Activate boşa gider.
		for _, m in ipairs(mobs) do
			if mobAlive(m) then
				local target = m.HumanoidRootPart
				local _, h2, r2 = getChar()
				if not (h2 and r2) then break end
				if (target.Position - r2.Position).Magnitude > 7 then
					pcall(function() r2.CFrame = target.CFrame * CFrame.new(0, 0, 4.5) end)
				end
				facePos(target.Position)
				if State.BringMobs then
					pcall(function()
						target.CFrame = r2.CFrame * CFrame.new(0, 0, -3)
						target.CanCollide = false
					end)
				end
				if State.AuraHold then holdMob(m) end
				if tool then pcall(function() tool:Activate() end) end
				if State.BladeHit then pcall(bladeHit, (State.AuraRange or 40) + 20) end
				if State.ClickAttack ~= false then softClick() end
				task.wait(0.03)
			end
		end
	else
		local pos = nearest and nearest.HumanoidRootPart.Position
		if pos then
			facePos(pos)
			if tool then pcall(function() tool:Activate() end) end
			if State.BladeHit then pcall(bladeHit, (State.AuraRange or 40) + 20) end
			if State.ClickAttack ~= false then softClick() end
		end
	end
end

-- toplama döngüleri -------------------------------------------------
function fruitTick()
	local _, _, hrp = getChar()
	if not hrp then return end
	local best, bestD
	for _, f in ipairs(getFruits()) do
		local p = fruitPos(f)
		if p then
			local d = (p - hrp.Position).Magnitude
			if not bestD or d < bestD then best, bestD = f, d end
		end
	end
	if not best then return end
	local p = fruitPos(best)
	if not p then return end
	if (p - hrp.Position).Magnitude > 6 then
		tpAt(p + Vector3.new(0, 2, 0))
		task.wait(0.18)
	end
	-- gerçek toplama: proximity prompt varsa tetikle, yoksa temasla alınır
	pcall(function()
		local prompt = best:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and type(fireproximityprompt) == "function" then
			fireproximityprompt(prompt)
		end
	end)
end

function chestTick()
	local _, _, hrp = getChar()
	if not hrp then return end
	local best, bestD
	for _, c in ipairs(getChests()) do
		local p = chestPos(c)
		if p then
			local d = (p - hrp.Position).Magnitude
			if d < 400 and (not bestD or d < bestD) then best, bestD = c, d end
		end
	end
	if not best then return end
	local p = chestPos(best)
	if not p then return end
	State.Busy = true
	tpAt(p + Vector3.new(0, 2, 0))
	task.wait(0.25)
	State.Busy = false
end

-- raid --------------------------------------------------------------
lastRaid = 0
function startRaid()
	if os.clock() - lastRaid < 5 then return end
	lastRaid = os.clock()
	invoke("RaidsNpc", "Select", State.RaidTheme)
	task.wait(0.4)
	invoke("RaidsNpc", "Start")
	notify("Raid başlatıldı: " .. State.RaidTheme)
end

function raidTick()
	if not State.AutoRaid then return end
	if os.clock() - lastRaid < State.RaidInterval then return end
	local mob = nearestMob(nil)
	if mob then return end -- zaten raid/av içinde düşman var
	startRaid()
end

-- stat dağıtma ------------------------------------------------------
function statTick()
	if not State.AutoStats then return end
	invoke("AddPoint", State.StatName, 1)
end

--===================================================================
-- 6) ESP
--===================================================================
espStore = {}

function makeESP(inst, color, label, anchor)
	if not inst or espStore[inst] then return end
	local hl = newInstance("Highlight", {
		FillColor = color,
		FillTransparency = 0.7,
		OutlineColor = color,
		OutlineTransparency = 0.15,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Parent = inst,
	})
	local bg = newInstance("BillboardGui", {
		Name = "BFHubESP",
		Size = UDim2.fromOffset(150, 30),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		MaxDistance = 1200,
		LightInfluence = 0,
		Adornee = anchor or inst,
		Parent = inst,
	})
	local text = newInstance("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = color,
		TextStrokeTransparency = 0.3,
		Text = label,
		Parent = bg,
	})
	espStore[inst] = { hl = hl, bg = bg, text = text, label = label }
end

function clearESP(inst)
	local d = espStore[inst]
	if d then
		pcall(function() d.hl:Destroy() end)
		pcall(function() d.bg:Destroy() end)
		espStore[inst] = nil
	end
end

function espPart(inst)
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	if inst:IsA("Tool") then
		return inst:FindFirstChild("Handle")
	end
	return inst:IsA("BasePart") and inst or nil
end

function updateESP()
	local _, _, hrp = getChar()

	-- oyuncular
	for _, plr in ipairs(Players:GetPlayers()) do
		local ok = State.ESPPlayers and plr ~= LP and plr.Character
		if ok then
			local ch = plr.Character
			local part = espPart(ch)
			if part then
				makeESP(ch, Color3.fromRGB(120, 200, 255), plr.Name, part)
			end
		end
	end
	for inst in pairs(espStore) do
		if inst:IsA("Model") and Players:GetPlayerFromCharacter(inst) and not State.ESPPlayers then
			clearESP(inst)
		end
	end

	-- düşmanlar (+ deniz canavarları)
	for _, m in ipairs(mobList()) do
		if mobAlive(m) then
			local beast = isSeaBeastName(m.Name)
			if State.ESPEnemies or (beast and State.ESPBeasts) then
				local col = beast and Color3.fromRGB(255, 150, 60) or Color3.fromRGB(255, 110, 110)
				makeESP(m, col, (beast and "Canavar: " or "") .. m.Name, espPart(m))
			else
				clearESP(m)
			end
		end
	end

	-- NPC'ler
	local npcFolder = workspace:FindFirstChild("NPCs")
	if npcFolder then
		for _, n in ipairs(npcFolder:GetChildren()) do
			if State.ESPNpc and espPart(n) then
				makeESP(n, Color3.fromRGB(180, 140, 255), n.Name, espPart(n))
			elseif not State.ESPNpc then
				clearESP(n)
			end
		end
	end

	-- meyveler
	for _, f in ipairs(getFruits()) do
		if State.ESPFruits then
			makeESP(f, Color3.fromRGB(150, 255, 150), "Meyve: " .. f.Name, espPart(f))
		else
			clearESP(f)
		end
	end

	-- sandıklar
	for _, c in ipairs(getChests()) do
		if State.ESPChests then
			makeESP(c, Color3.fromRGB(255, 210, 90), "Sandık", espPart(c))
		else
			clearESP(c)
		end
	end

	-- etkinlik nesneleri (halloween)
	for _, obj in ipairs(getEventObjects()) do
		if State.ESPEvent then
			local kind = eventKind(obj.Name)
			local col = Color3.fromRGB(255, 180, 60)
			if kind == "candy" then col = Color3.fromRGB(255, 105, 190)
			elseif kind == "hellfire" then col = Color3.fromRGB(230, 80, 80)
			elseif kind == "misc" then col = Color3.fromRGB(160, 220, 255) end
			makeESP(obj, col, obj.Name, espPart(obj))
		else
			clearESP(obj)
		end
	end
	if not State.ESPEvent then
		for inst in pairs(espStore) do
			if inst.Parent and eventKind(inst.Name) and not Players:GetPlayerFromCharacter(inst) then
				clearESP(inst)
			end
		end
	end

	-- mesafe yazısı
	if hrp then
		for _, data in pairs(espStore) do
			local adornee = data.bg.Adornee or data.bg.Parent
			local p = adornee and (adornee:IsA("BasePart") and adornee.Position or (espPart(adornee) and espPart(adornee).Position))
			if p then
				local d = math.floor((p - hrp.Position).Magnitude)
				if d > 1200 then
					data.bg.Enabled = false
				else
					data.bg.Enabled = true
					data.text.Text = string.format("%s • %dm", data.label or "", d)
				end
			end
		end
	end
end

--===================================================================
-- 7) MİSC (hız, zıplama, no-clip, fullbright)
--===================================================================
local lightBackup

function applyStats()
	local _, hum = getChar()
	if not hum then return end
	local ws = State.WalkSpeed
	if State.SafeSpeed then ws = math.min(ws, math.min(State.SpeedCap, 100)) end
	pcall(function() hum.WalkSpeed = ws end)
	pcall(function() hum.JumpPower = State.JumpPower end)
end

function setFullbright(on)
	if on then
		if not lightBackup then
			lightBackup = {
				Brightness = LS.Brightness,
				FogEnd = LS.FogEnd,
				GlobalShadows = LS.GlobalShadows,
				Ambient = LS.Ambient,
			}
		end
		LS.Brightness = 2
		LS.FogEnd = 1000000
		LS.GlobalShadows = false
		LS.Ambient = Color3.fromRGB(190, 190, 190)
	elseif lightBackup then
		LS.Brightness = lightBackup.Brightness
		LS.FogEnd = lightBackup.FogEnd
		LS.GlobalShadows = lightBackup.GlobalShadows
		LS.Ambient = lightBackup.Ambient
		lightBackup = nil
	end
end

-- ek görüntü / karakter araçları -------------------------------
local fogBackup
function setFog(on)
	if on then
		if not fogBackup then fogBackup = { end_ = LS.FogEnd, start_ = LS.FogStart } end
		LS.FogEnd = 100000
		LS.FogStart = 100000
	elseif fogBackup then
		LS.FogEnd = fogBackup.end_
		LS.FogStart = fogBackup.start_
		fogBackup = nil
	end
end

local lagBackup
function setLagReduce(on)
	if on then
		if not lagBackup then
			lagBackup = { shadows = LS.GlobalShadows, diffuse = LS.EnvironmentDiffuseScale, specular = LS.EnvironmentSpecularScale }
		end
		LS.GlobalShadows = false
		LS.EnvironmentDiffuseScale = 0
		LS.EnvironmentSpecularScale = 0
		pcall(function() workspace.Terrain.Decoration = false end)
	elseif lagBackup then
		LS.GlobalShadows = lagBackup.shadows
		LS.EnvironmentDiffuseScale = lagBackup.diffuse
		LS.EnvironmentSpecularScale = lagBackup.specular
		pcall(function() workspace.Terrain.Decoration = true end)
		lagBackup = nil
	end
end

function applyFov()
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then cam.FieldOfView = State.Fov end
	end)
end

-- uçuş ---------------------------------------------------------------
local flyBV, flyBG
function stopFly()
	if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
	local _, hum = getChar()
	if hum then pcall(function() hum.PlatformStand = false end) end
	applyStats()
end

function flyTick()
	local _, hum, hrp = getChar()
	if not (hum and hrp) then return end
	if not flyBV or not flyBV.Parent then
		flyBV = newInstance("BodyVelocity", {
			MaxForce = Vector3.new(1e9, 1e9, 1e9),
			Velocity = Vector3.new(),
			P = 1250,
			Parent = hrp,
		})
	end
	if not flyBG or not flyBG.Parent then
		flyBG = newInstance("BodyGyro", {
			MaxTorque = Vector3.new(1e9, 1e9, 1e9),
			P = 3000,
			D = 500,
			CFrame = hrp.CFrame,
			Parent = hrp,
		})
	end
	pcall(function() hum.PlatformStand = true end)
	local cam = workspace.CurrentCamera

	-- güvenli hız: oyunun en hızlı gitme oranının altında kal
	local speed = State.FlySpeed
	if State.SafeSpeed then speed = math.min(speed, State.SpeedCap) end

	-- normal uçuş: W/S ileri-geri, A/D sağ-sol (kamera yönüne göre), Space/Shift yukarı-aşağı
	local dir = Vector3.new(0, 0, 0)
	if cam then
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
	end
	if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		dir = dir - Vector3.new(0, 1, 0)
	end
	local v = Vector3.new(0, 0, 0)
	if dir.Magnitude > 0.01 then v = dir.Unit * speed end
	if flyBV then flyBV.Velocity = v end
	if flyBG and cam then
		flyBG.CFrame = CFrame.new(hrp.Position) * (cam.CFrame - cam.CFrame.Position)
	end
end

-- Ken (gözlem haki) tuşu: K
function pressRaw(name, code)
	if type(keypress) == "function" then
		pcall(keypress, code)
		task.wait(0.03)
		if type(keyrelease) == "function" then pcall(keyrelease, code) end
	elseif VIM then
		pcall(function() VIM:SendKeyEvent(true, name, false, game) end)
		task.wait(0.03)
		pcall(function() VIM:SendKeyEvent(false, name, false, game) end)
	end
end

UIS.JumpRequest:Connect(function()
	if not State.InfiniteJump then return end
	local _, hum = getChar()
	if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

-- kayıtlı konum
local waypoint
function saveWaypoint()
	local _, _, hrp = getChar()
	if not hrp then notify("Karakter yüklenmedi") return end
	waypoint = hrp.Position
	notify("Konum kaydedildi")
end

local function tpToWaypoint()
	if not waypoint then notify("Önce konum kaydet") return end
	if tpAt(waypoint) then notify("Kayıtlı konuma ışınlandın") else notify("Işınlanamadı") end
end

local function tpToMouse()
	local ok, pos = pcall(function()
		local m = LP:GetMouse()
		return m and m.Hit and m.Hit.Position
	end)
	if ok and pos then
		if tpAt(pos + Vector3.new(0, 3, 0)) then notify("İmlecin olduğu yere ışınlandın") else notify("Işınlanamadı") end
	else
		notify("İmleç konumu alınamadı")
	end
end

-- sunucu araçları ---------------------------------------------------
local TeleportService = game:GetService("TeleportService")

local function copyJobId()
	if type(setclipboard) == "function" then
		pcall(setclipboard, game.JobId)
		notify("Job ID kopyalandı")
	else
		notify("Job ID: " .. tostring(game.JobId))
	end
end

local function rejoinServer()
	notify("Yeniden bağlanılıyor...")
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
end

local function hopServer(preferLowest)
	local http = (syn and syn.request) or (http and http.request) or http_request or request
	if not http then notify("Executor HTTP desteklemiyor") return end
	local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=50", game.PlaceId)
	local ok, res = pcall(http, { Url = url, Method = "GET" })
	if not ok or not res or not res.Body then notify("Sunucu listesi alınamadı") return end
	local ok2, dec = pcall(HS.JSONDecode, HS, res.Body)
	if not ok2 or type(dec) ~= "table" then notify("Sunucu listesi okunamadı") return end
	local list = {}
	for _, s in ipairs(dec.data or {}) do
		if s.id and s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 12) then
			list[#list + 1] = { id = s.id, playing = s.playing or 0 }
		end
	end
	if #list == 0 then notify("Uygun sunucu bulunamadı") return end
	local pick
	if preferLowest then
		table.sort(list, function(a, b) return a.playing < b.playing end)
		pick = list[1].id
	else
		pick = list[math.random(1, #list)].id
	end
	notify("Sunucu değiştiriliyor...")
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LP) end)
end

local function playerListText()
	return string.format("%d oyuncu • Job: %s", #Players:GetPlayers(), string.sub(tostring(game.JobId), 1, 8))
end

-- mağaza (deneysel remote adları) ------------------------------------
local STYLES = {
	{ "Black Leg", "BuyBlackLeg" },
	{ "Electro", "BuyElectro" },
	{ "Fishman Karate", "BuyFishmanKarate" },
	{ "Dragon Claw", "BuyDragonClaw" },
	{ "Superhuman", "BuySuperhuman" },
	{ "Death Step", "BuyDeathStep" },
	{ "Sharkman Karate", "BuySharkmanKarate" },
	{ "Electric Claw", "BuyElectricClaw" },
	{ "Dragon Talon", "BuyDragonTalon" },
	{ "Godhuman", "BuyGodhuman" },
}

LP.CharacterAdded:Connect(function()
	task.wait(1)
	applyStats()
	setFullbright(State.Fullbright)
	setFog(State.RemoveFog)
	applyFov()
end)
if LP.Character then
	applyStats()
	applyFov()
end

--===================================================================
-- 7.5) TEŞHİS — neyin neden çalışmadığını gösterir
--===================================================================
local function copyText(t)
	if type(setclipboard) == "function" then
		local ok = pcall(setclipboard, t)
		if ok then return true end
	end
	notify("Executor panoya kopyalamayı desteklemiyor")
	return false
end

local function folderList()
	local names = {}
	for _, f in ipairs({ "Enemies", "Characters", "Mobs", "NPCs", "Chests", "Fruits", "Map" }) do
		if workspace:FindFirstChild(f) then names[#names + 1] = f end
	end
	return table.concat(names, ", ")
end

local function aliveMobs()
	local n = 0
	for _, m in ipairs(mobList()) do
		if mobAlive(m) then n = n + 1 end
	end
	return n
end

local function diagReport()
	local _, hum = getChar()
	local ok2, res = pcall(function() return CommF:GetFullName() end)
	local lines = {
		"Chiko Hub v" .. HUB_VERSION .. " — teşhis",
		"JobID: " .. tostring(game.JobId),
		"Yer: " .. tostring(game.PlaceId),
		"Seviye: " .. tostring(getLevel()),
		"Humanoid: " .. (hum and (tostring(math.floor(hum.Health)) .. " HP") or "YOK (!)"),
		"CommF_ remote: " .. (CommF and "VAR" or "YOK (!)"),
		"CommF_ erişim: " .. (ok2 and tostring(res) or "hata"),
		"Canlı düşman: " .. aliveMobs() .. " / listede " .. #mobList(),
		"Sandık: " .. #getChests(),
		"Meyve: " .. #getFruits(),
		"Etkinlik nesnesi: " .. #getEventObjects(),
		"Klasörler: " .. (folderList() ~= "" and folderList() or "yok (!)"),
		"Workspace çocuk: " .. #workspace:GetChildren(),
		"Aktif farm hedefi: " .. tostring(State.Target),
		"Işınlanma: " .. (State.TpInfo ~= "" and State.TpInfo or "henüz denenmedi"),
		"Tık yöntemi: " .. tostring(State.ClickMethod or "?"),
		"Combat erişimi: " .. tostring(State.CombatPath or "?") .. " | son blade hit: " .. tostring(State.BladeHits or 0),
	}
	return table.concat(lines, "\n")
end

local function workspaceNames()
	local out = {}
	for i, v in ipairs(workspace:GetChildren()) do
		out[#out + 1] = v.Name .. "  [" .. v.ClassName .. "]"
		if i >= 150 then break end
	end
	return table.concat(out, "\n")
end

local function searchWorkspace(q)
	local out, found = {}, 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if string.find(string.lower(d.Name), q, 1, true) then
			found = found + 1
			if #out < 150 then
				out[#out + 1] = d.Name .. "  [" .. d.ClassName .. "]  " .. d:GetFullName()
			end
		end
	end
	return found, table.concat(out, "\n")
end

--===================================================================
-- 8) SEKMELER
--===================================================================

-- arayüz kurulumu bir bütün olarak korunur: bir sekme hata verse bile
-- menü kaybolmaz, hata ekranda kırmızı şeritte yazar.
local errorLabel = newInstance("TextLabel", {
	Name = "HubError",
	Text = "",
	Visible = false,
	Font = Enum.Font.GothamSemibold,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(255, 128, 128),
	BackgroundColor3 = Color3.fromRGB(48, 16, 22),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.new(0, 12, 1, -82),
	Size = UDim2.new(1, -24, 0, 68),
	ZIndex = 60,
	Parent = gui,
})
corner(errorLabel, 8)

local buildOk, buildErr = pcall(function()

-- FARM --------------------------------------------------------------
do
	local page = makeTab("Farm", 1)

	section(page, "Otomatik farm")
	toggle(page, "AutoFarm", "Auto Farm", false, function(on)
		State.AutoFarm = on
		if on then notify("Auto Farm açıldı") end
	end)
	toggle(page, "AutoQuest", "Görev zincirini takip et", true, function(on)
		State.AutoQuest = on
	end)
	toggle(page, "AutoBoss", "Sadece bossları farmla", false, function(on)
		State.AutoBoss = on
	end)
	toggle(page, "AutoHaki", "Auto Haki (Buso)", false, function(on)
		State.AutoHaki = on
	end)
	toggle(page, "AutoEquip", "Silahı otomatik kuşan", true, function(on)
		State.AutoEquip = on
	end)

	questLabel = label(page, "Görev: --", Theme.sub)
	task.spawn(function()
		while questLabel.Parent do
			local def = getQuestDef(getLevel())
			if def then
				questLabel.Text = "Görev: " .. tostring(def.mon) .. "  •  Lv " .. tostring(getLevel())
				questLabel.TextColor3 = Theme.good or Theme.accent
			else
				questLabel.Text = "Görev: bulunamadı (en yakın düşman farmlanır)"
				questLabel.TextColor3 = Theme.bad or Theme.sub
			end
			task.wait(2)
		end
	end)

	farmStatusLabel = label(page, "Durum: --", Theme.sub)
	task.spawn(function()
		while farmStatusLabel.Parent do
			local tool = equippedTool()
			farmStatusLabel.Text = "Hedef: " .. tostring(State.Target or "-")
				.. "  •  Listede: " .. tostring(#mobList())
				.. "  •  Silah: " .. tostring(tool and tool.Name or "yok")
				.. "  •  Son: " .. tostring(lastFarmAction or "-")
				.. "  •  Hata: " .. tostring(lastFarmError or "yok")
			task.wait(0.5)
		end
	end)

	section(page, "Saldırı")
	cycle(page, "Saldırı modu", { "Otomatik", "M1", "Meyve Skill", "Kılıç Skill" }, State.AttackMode, function(v)
		State.AttackMode = v
	end)
	toggle(page, "UseSkills", "Skill'leri kullan (Z / X / C)", true, function(on)
		State.UseSkills = on
	end)
	slider(page, "Saldırı gecikmesi (ms)", 20, 500, 120, function(v)
		State.AttackDelay = v / 1000
	end)
	toggle(page, "FastAttack", "Hızlı vuruş (Fast Attack)", false, function(on)
		State.FastAttack = on
	end)
	toggle(page, "AuraTP", "Kill Aura: hedefe ışınlanıp vur (çalışan mod)", true, function(on)
		State.AuraTP = on
	end)
	slider(page, "Farm vuruş menzili", 8, 60, 32, function(v)
		State.FarmRange = v
	end)
	toggle(page, "Bypass", "Cooldown bypass (bekleme atlama)", false, function(on)
		State.Bypass = on
		if on then notify("Cooldown bypass açık: saldırı/skill beklemesi ~0") end
	end)
	toggle(page, "DashBypass", "Dash beklemesini atla", false, function(on)
		State.DashBypass = on
	end)
	slider(page, "Dash hızı", 80, 420, 180, function(v)
		State.DashSpeed = v
	end)
	cycle(page, "Düşman filtresi", { "Hepsi", "Sadece boss", "Deniz canavarı" }, State.MobFilter, function(v)
		State.MobFilter = v
	end)
	toggle(page, "BringMobs", "Düşmanı yanına çek", false, function(on)
		State.BringMobs = on
	end)
	toggle(page, "FreezeMobs", "Düşmanı dondur", false, function(on)
		State.FreezeMobs = on
	end)

	section(page, "Skill seçimi")
	for _, s in ipairs({ { "SkillZ", "Z skill" }, { "SkillX", "X skill" }, { "SkillC", "C skill" },
		{ "SkillV", "V skill" }, { "SkillF", "F skill" } }) do
		toggle(page, s[1], s[2], State[s[1]], function(on) State[s[1]] = on end)
	end
	toggle(page, "AutoObserve", "Auto Observation (Ken)", false, function(on)
		State.AutoObserve = on
	end)

	section(page, "Toplama")
	toggle(page, "AutoFruit", "Auto Meyve", false, function(on)
		State.AutoFruit = on
	end)
	toggle(page, "AutoChest", "Auto Sandık", false, function(on)
		State.AutoChest = on
	end)
	toggle(page, "AntiAfk", "Anti-AFK (atılma koruması)", false, function(on)
		State.AntiAfk = on
	end)

	section(page, "Kill Aura alanı")
	toggle(page, "KillAura", "Kill Aura", false, function(on)
		State.KillAura = on
		if not on then pcall(releaseHold) end
	end)
	toggle(page, "AuraHold", "Alandaki düşmanı kilitle (kaçamaz)", true, function(on)
		State.AuraHold = on
		if not on then pcall(releaseHold) end
	end)
	toggle(page, "AuraRing", "Alanı yerde halka olarak göster", true, function(on)
		State.AuraRing = on
	end)
	slider(page, "Kill Aura menzili", 5, 150, 28, function(v)
		State.AuraRange = v
	end)
	toggle(page, "AuraMulti", "Menzildeki tüm düşmanlara vur", true, function(on)
		State.AuraMulti = on
	end)

	section(page, "Görev")
	button(page, "Görevi yenile (bırak + al)", function()
		invoke("AbandonQuest")
		task.wait(0.3)
		invoke("StartQuest", getQuestDef(getLevel()) and getQuestDef(getLevel()).quest or "BanditQuest1", 1)
		notify("Görev yenilendi")
	end)
	button(page, "Görev veren NPC'ye ışınlan", function()
		local def = getQuestDef(getLevel())
		if def then tpAt(def.pos) else notify("Bu seviye için görev verisi yok") end
	end)
end

-- RAID --------------------------------------------------------------
do
	local page = makeTab("Raid", 2)

	section(page, "Raid")
	toggle(page, "AutoRaid", "Auto Raid", false, function(on)
		State.AutoRaid = on
		if on then notify("Auto Raid açıldı (chip envanterde olmalı)") end
	end)
	cycle(page, "Raid chip", { "Flame", "Ice", "Quake", "Light", "Dark", "Spider", "Rumble",
		"Magma", "Bomb", "Sand", "Door", "Revive", "Dough", "Blizzard", "Soul" }, State.RaidTheme, function(v)
		State.RaidTheme = v
	end)
	slider(page, "Raid aralığı (saniye)", 15, 180, 45, function(v)
		State.RaidInterval = v
	end)
	button(page, "Raid'i hemen başlat", function()
		lastRaid = 0
		startRaid()
	end)

	section(page, "Otomatik dağıtım")
	toggle(page, "AutoStats", "Stat puanlarını otomatik dağıt", false, function(on)
		State.AutoStats = on
	end)
	cycle(page, "Stat türü", { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }, State.StatName, function(v)
		State.StatName = v
	end)
end

-- ESP ---------------------------------------------------------------
do
	local page = makeTab("ESP", 3)

	section(page, "Görsel")
	toggle(page, "ESPPlayers", "Oyuncu ESP", false, function(on) State.ESPPlayers = on end)
	toggle(page, "ESPEnemies", "Düşman ESP", false, function(on) State.ESPEnemies = on end)
	toggle(page, "ESPFruits", "Meyve ESP", false, function(on) State.ESPFruits = on end)
	toggle(page, "ESPChests", "Sandık ESP", false, function(on) State.ESPChests = on end)
	toggle(page, "ESPNpc", "NPC ESP", false, function(on) State.ESPNpc = on end)
	toggle(page, "ESPBeasts", "Deniz canavarı ESP", false, function(on) State.ESPBeasts = on end)
	toggle(page, "FruitNotify", "Yeni meyve bildirimi", true, function(on) State.FruitNotify = on end)
	button(page, "Tüm ESP'yi kapat", function()
		for id, ref in pairs(ToggleRefs) do
			if string.find(id, "ESP", 1, true) then ref.set(false) end
		end
	end)
end

-- IŞINLAN -----------------------------------------------------------
do
	local page = makeTab("Işınlan", 4)

	section(page, "Işınlanma yöntemi")
	cycle(page, "Yöntem", { "Tween", "Anında", "Bypass", "Uçarak" }, State.TpMethod, function(v)
		State.TpMethod = v
	end)
	slider(page, "Uçma hızı", 60, 500, 220, function(v)
		State.GlideSpeed = v
	end)
	toggle(page, "TpAutoFix", "Başarısız ışınlanmayı otomatik onar", true, function(on)
		State.TpAutoFix = on
	end)
	button(page, "Işınlanma testi (10 stud)", function()
		local _, _, hrp = getChar()
		if not hrp then return end
		local ok = tpAt(hrp.Position + Vector3.new(0, 0, 10))
		notify(ok and ("Işınlanma çalışıyor • " .. tostring(State.TpInfo)) or "Işınlanma başarısız")
	end, true)
	newInstance("TextLabel", {
		Text = "Tween: yumuşak • Anında: direkt CFrame • Bypass: geri atılırsa tekrar dener • Uçarak: hedefe gerçekten uçar (farm bunu kullanır)",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})

	section(page, "İlk deniz adaları")
	for _, isl in ipairs(ISLANDS) do
		button(page, isl[1], function()
			local ok = tpAt(isl[2])
			if ok then
				notify(isl[1] .. " • ışınlandı")
			else
				notify(isl[1] .. " • ışınlanamadı (yöntemi Anında yapıp tekrar dene)")
			end
		end)
	end

	section(page, "Hedefe ışınlan")
	button(page, "Görev bölgesine git", function()
		local def = getQuestDef(getLevel())
		if def then tpAt(def.pos) else notify("Bu seviye için görev verisi yok") end
	end)
	button(page, "En yakın düşmana git", function()
		local mob = nearestMob(nil)
		if mob then tpAt(mob.HumanoidRootPart.Position) else notify("Düşman bulunamadı") end
	end)
	button(page, "En yakın oyuncuya ışınlan", function()
		local _, _, hrp = getChar()
		if not hrp then return end
		local best, bestD
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local d = (root.Position - hrp.Position).Magnitude
					if not bestD or d < bestD then best, bestD = root.Position, d end
				end
			end
		end
		if best and tpAt(best + Vector3.new(0, 3, 0)) then
			notify("Oyuncuya ışınlandın")
		else
			notify("Işınlanamadı")
		end
	end)
	button(page, "Boss'a ışınlan", function()
		local mob = nearestMob(nil, true, true)
		if not mob then notify("Boss yok") return end
		if tpAt(mob.HumanoidRootPart.Position + Vector3.new(0, 3, 0)) then
			notify("Boss: " .. mob.Name)
		else
			notify("Işınlanamadı")
		end
	end)
	button(page, "Deniz canavarına ışınlan", function()
		local mob
		for _, m in ipairs(mobList()) do
			if mobAlive(m) and isSeaBeastName(m.Name) then mob = m break end
		end
		if not mob then notify("Deniz canavarı yok") return end
		if tpAt(mob.HumanoidRootPart.Position + Vector3.new(0, 6, 0)) then
			notify(mob.Name)
		else
			notify("Işınlanamadı")
		end
	end)
	button(page, "İmlecin olduğu yere ışınlan", tpToMouse)
	button(page, "Konumu kaydet (waypoint)", saveWaypoint)
	button(page, "Kayıtlı konuma ışınlan", tpToWaypoint)
	button(page, "En yakın meyveye git", function()
		local _, _, hrp = getChar()
		if not hrp then return end
		local best, bestD
		for _, f in ipairs(getFruits()) do
			local p = fruitPos(f)
			if p then
				local d = (p - hrp.Position).Magnitude
				if not bestD or d < bestD then best, bestD = f, d end
			end
		end
		if best then tpAt(fruitPos(best)) else notify("Meyve yok") end
	end)
end

-- MAĞAZA -----------------------------------------------------------
do
	local page = makeTab("Mağaza", 5)

	section(page, "Dövüş stili satın al (deneysel)")
	newInstance("TextLabel", {
		Text = "NPC'nin yanında değilsen sunucu satın alma isteğini reddedebilir. Önce stilin ustasının yanına ışınlan.",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	for _, s in ipairs(STYLES) do
		button(page, "Satın al: " .. s[1], function()
			invoke(s[2])
			notify(s[1] .. " satın alma isteği gönderildi")
		end)
	end

	section(page, "Haki")
	button(page, "Buso Haki aç / kapat", function()
		invoke("Buso")
		notify("Buso gönderildi")
	end)
	button(page, "Ken (gözlem) tuşuna bas", function()
		pressRaw("K", 0x4B)
		notify("K tuşu gönderildi")
	end)
end

-- SUNUCU ------------------------------------------------------------
do
	local page = makeTab("Sunucu", 6)

	section(page, "Sunucu")
	local info = newInstance("TextLabel", {
		Text = playerListText(),
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	task.spawn(function()
		while page.Parent do
			info.Text = playerListText()
			task.wait(2)
		end
	end)
	button(page, "Job ID kopyala", copyJobId)
	button(page, "Yeniden bağlan (rejoin)", rejoinServer)
	button(page, "Sunucu değiştir (hop)", hopServer)
	button(page, "En az kalabalık sunucuya geç", function() hopServer(true) end)
end

-- ETKİNLİK (HALLOWEEN) ----------------------------------------------
local eventCountLabel
do
	local page = makeTab("Etkinlik", 8)

	section(page, "Halloween etkinliği")
	newInstance("TextLabel", {
		Text = "Etkinlik nesneleri isimle bulunur (pumpkin, candy, hellfire...). Güncelleme isim değiştirirse soldaki listeyi bana söyle, anahtar kelimeyi eklerim.",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	toggle(page, "AutoPumpkin", "Auto Pumpkin (balkabağı kır / kes)", false, function(on)
		State.AutoPumpkin = on
		if on then notify("Auto Pumpkin açık") end
	end)
	toggle(page, "AutoCandy", "Auto Trick or Treat (şeker topla)", false, function(on)
		State.AutoCandy = on
		if on then notify("Auto Trick or Treat açık") end
	end)
	toggle(page, "AutoHellfire", "Auto Hellfire (hellfire gas)", false, function(on)
		State.AutoHellfire = on
	end)
	toggle(page, "AutoEventMisc", "Diğer etkinlik eşyaları (ember, soul, gift)", false, function(on)
		State.AutoEventMisc = on
	end)
	slider(page, "Etkinlik menzili", 50, 2000, State.EventRange, function(v)
		State.EventRange = v
	end)
	button(page, "Hepsini aç (tam etkinlik modu)", function()
		for _, id in ipairs({ "CandyDoor", "CandyPumpkin", "AutoHellfire", "AutoEventMisc" }) do
			if ToggleRefs[id] then ToggleRefs[id].set(true) end
		end
		notify("Etkinlik modu açık")
	end)
	button(page, "Etkinlik modunu kapat", function()
		for _, id in ipairs({ "CandyDoor", "CandyPumpkin", "AutoHellfire", "AutoEventMisc", "AutoPumpkin", "AutoCandy" }) do
			if ToggleRefs[id] then ToggleRefs[id].set(false) end
		end
	end)

	section(page, "Candy Corn farmı (en hızlı)")
	moonLabel = newInstance("TextLabel", {
		Text = "Harvest Moon: --",
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	candyLabel = newInstance("TextLabel", {
		Text = "Candy Corn: --",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	toggle(page, "CandyDoor", "Auto trick-or-treat kapıları", false, function(on)
		State.CandyDoor = on
		if on then notify("Kapı modu açık — Harvest Moon'da her kapı candy verir") end
	end)
	toggle(page, "CandyPumpkin", "Auto balkabağı kır (candy)", false, function(on)
		State.CandyPumpkin = on
	end)
	toggle(page, "CandyAutoStart", "Harvest Moon'da otomatik kapı modu", true, function(on)
		State.CandyAutoStart = on
	end)
	button(page, "En yakın kapıya git", function()
		local d, dist = nearestDoor(false)
		if not d then notify("Kapı bulunamadı (Harvest Moon bekleniyor olabilir)") return end
		tpAt(d.pos + Vector3.new(0, 2, 3))
		notify("Kapı • " .. tostring(math.floor(dist or 0)) .. " stud")
	end, true)
	button(page, "En yakın balkabağına git", function()
		local _, _, hrp = getChar()
		if not hrp then return end
		local best, bestD
		for _, obj in ipairs(pumpkinList()) do
			local p = collectPos(obj)
			if p then
				local d = (p - hrp.Position).Magnitude
				if not bestD or d < bestD then best, bestD = obj, d end
			end
		end
		if best then tpAt(collectPos(best) + Vector3.new(0, 2, 0)) else notify("Balkabağı yok") end
	end)

	section(page, "Etkinlik ESP")
	toggle(page, "ESPEvent", "Etkinlik nesnesi ESP", false, function(on) State.ESPEvent = on end)
	eventCountLabel = newInstance("TextLabel", {
		Text = "Bulunan nesne: 0",
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})

	section(page, "Işınlan")
	button(page, "Pumpkin'e ışınlan", function() tpToEventKind("pumpkin") end)
	button(page, "Şekere (candy) ışınlan", function() tpToEventKind("candy") end)
	button(page, "Hellfire'a ışınlan", function() tpToEventKind("hellfire") end)
end

-- TEŞHİS ------------------------------------------------------------
do
	local page = makeTab("Teşhis", 9)

	section(page, "Canlı durum")
	local live = label(page, "taranıyor...", Theme.sub)
	task.spawn(function()
		while live.Parent do
			pcall(function() live.Text = diagReport() end)
			task.wait(2)
		end
	end)

	section(page, "Araçlar")
	button(page, "Raporu kopyala (bana gönder)", function()
		if copyText(diagReport()) then notify("Teşhis raporu kopyalandı") end
	end, true)
	button(page, "Workspace isimlerini kopyala", function()
		if copyText(workspaceNames()) then notify("Liste kopyalandı") end
	end)
	button(page, "Saldırı testi (hasar ölç)", function()
		local mob = nearestMob(nil)
		if not mob then notify("Menzilde düşman yok") return end
		local mhum = mob:FindFirstChildOfClass("Humanoid")
		local before = mhum and mhum.Health or 0
		local tool = equippedTool() or (State.AutoEquip and autoEquip()) or nil
		tpAt(mob.HumanoidRootPart.Position + Vector3.new(0, 2, 4))
		for _ = 1, 12 do
			swing(tool, mob.HumanoidRootPart.Position)
			task.wait(0.12)
		end
		local after = mhum and mhum.Health or 0
		local dealt = math.floor(before - after)
		local msg = "Hasar: " .. tostring(dealt) .. "  •  tool: " .. tostring(tool and tool.Name or "yok")
			.. "  •  VU: " .. (VU and "var" or "yok")
		if dealt <= 0 then
			msg = msg .. "  •  SANAL TIK İŞLEMİYOR"
		end
		notify(msg)
	end, true)
	button(page, "Sağlık kontrolü yap", function()
		local msg = {}
		if not CommF then msg[#msg + 1] = "CommF yok" end
		if aliveMobs() == 0 then msg[#msg + 1] = "canlı düşman yok" end
		if #getFruits() == 0 then msg[#msg + 1] = "meyve yok" end
		if #msg == 0 then
			notify("Her şey yerinde görünüyor")
		else
			notify(table.concat(msg, ", "))
		end
	end)

	section(page, "Nesne ara")
	local box = newInstance("TextBox", {
		Text = "",
		PlaceholderText = "ör: pumpkin, chest, fruit, enemy",
		PlaceholderColor3 = Theme.sub,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.text,
		BackgroundColor3 = Theme.row,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(box, 8)
	button(page, "Ara ve sonuçları kopyala", function()
		local q = string.lower(string.gsub(box.Text or "", "^%s*(.-)%s*$", "%1"))
		if q == "" then
			notify("Kutu boş — bir isim yaz")
			return
		end
		local found, txt = searchWorkspace(q)
		notify(found .. " sonuç bulundu: " .. q)
		if found > 0 then copyText(txt) end
	end)
	label(page, "Bir özellik çalışmıyorsa buradan raporu kopyala ve bana gönder: eksik klasörü/nesneyi doğrudan görüyorum.", Theme.sub)
end

-- AYARLAR -----------------------------------------------------------
do
	local page = makeTab("Ayarlar", 10)

	section(page, "Karakter")
	slider(page, "WalkSpeed", 16, 200, State.WalkSpeed, function(v)
		State.WalkSpeed = v
		applyStats()
	end)
	slider(page, "JumpPower", 50, 300, State.JumpPower, function(v)
		State.JumpPower = v
		applyStats()
	end)
	toggle(page, "NoClip", "NoClip (duvarlardan geç)", false, function(on)
		State.NoClip = on
	end)
	toggle(page, "InfiniteJump", "Sonsuz zıplama", false, function(on)
		State.InfiniteJump = on
	end)
	toggle(page, "Fly", "Uçuş (W/A/S/D yön, Space yukarı, Shift aşağı)", false, function(on)
		State.Fly = on
		if on then notify("Uçuş açık") else stopFly() end
	end)
	slider(page, "Uçuş hızı", 20, 400, State.FlySpeed, function(v)
		State.FlySpeed = v
	end)
	toggle(page, "SafeSpeed", "Güvenli hız (oyun limiti içinde)", true, function(on)
		State.SafeSpeed = on
	end)
	slider(page, "Hız üst sınırı", 60, 400, State.SpeedCap, function(v)
		State.SpeedCap = v
	end)
	slider(page, "Kamera FOV", 50, 120, State.Fov, function(v)
		State.Fov = v
		applyFov()
	end)
	button(page, "Bulunduğun yeri spawn yap", function()
		invoke("SetSpawnPoint")
		notify("Spawn noktası buraya ayarlandı")
	end)
	button(page, "Kendini öldür (respawn)", function()
		local _, hum = getChar()
		if hum then hum.Health = 0 end
	end)

	section(page, "Görüntü / AFK")
	toggle(page, "Fullbright", "Fullbright", false, function(on)
		State.Fullbright = on
		setFullbright(on)
	end)
	toggle(page, "AntiAFK", "Anti-AFK", true, function(on)
		State.AntiAFK = on
	end)
	toggle(page, "RemoveFog", "Sisi kaldır", false, function(on)
		State.RemoveFog = on
		setFog(on)
	end)
	toggle(page, "LagReduce", "Lag azalt (gölge / efekt kıs)", false, function(on)
		State.LagReduce = on
		setLagReduce(on)
	end)

	section(page, "Kısayollar (değiştirmek için tıkla)")
	local bindList = {
		{ "Gui", "Menü aç / kapat" },
		{ "AutoFarm", "Auto Farm" },
		{ "KillAura", "Kill Aura" },
		{ "AutoFruit", "Auto Meyve" },
		{ "AutoChest", "Auto Sandık" },
		{ "AutoHaki", "Auto Haki" },
		{ "ESPEnemies", "Düşman ESP" },
		{ "AutoRaid", "Auto Raid" },
	}
	local capturing = nil
	local function bindRow(id, text)
		local row = newInstance("TextButton", {
			Text = "",
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.row,
			AutoButtonColor = false,
			LayoutOrder = nextOrder(page),
			Parent = page,
		})
		corner(row, 6)
		row.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.rowHover end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = Theme.row end)
		newInstance("TextLabel", {
			Text = text,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -140, 1, 0),
			Parent = row,
		})
		local keyLabel = newInstance("TextLabel", {
			Text = Binds[id] and Binds[id].Name or "-",
			Font = Enum.Font.GothamSemibold,
			TextSize = 12,
			TextColor3 = Theme.accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -130, 0, 0),
			Size = UDim2.fromOffset(118, 32),
			Parent = row,
		})
		row.MouseButton1Click:Connect(function()
			capturing = id
			keyLabel.Text = "tuşa bas..."
			keyLabel.TextColor3 = Theme.bad
		end)
		return function()
			keyLabel.Text = Binds[id] and Binds[id].Name or "-"
			keyLabel.TextColor3 = Theme.accent
		end
	end

	local refreshers = {}
	for _, b in ipairs(bindList) do
		refreshers[#refreshers + 1] = { id = b[1], fn = bindRow(b[1], b[2]) }
	end

	section(page, "Savaş")
	toggle(page, "ClickAttack", "Sanal M1 tık (VirtualUser) — hasar için şart", true, function(on)
		State.ClickAttack = on
	end)
	toggle(page, "BladeHit", "Blade Hit — gerçek hasar yolu (RigLib + RigControllerEvent)", true, function(on)
		State.BladeHit = on
		if on then notify("Blade Hit açık: hasar oyunun kendi modülünden gidiyor") end
	end)
	toggle(page, "FastAttack", "Hızlı vuruş (cooldown sıfırlama)", true, function(on)
		State.FastAttack = on
	end)
	toggle(page, "SafeMode", "Güvenli mod (çökme önleme, önerilir)", true, function(on)
		State.SafeMode = on
		if on then notify("Güvenli mod açık: ağır taramalar kapalı") end
	end)

	section(page, "Güncelleme")
	updateLabel = newInstance("TextLabel", {
		Text = "Sürüm: v" .. HUB_VERSION,
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	button(page, "Güncelleme kontrol et", function()
		checkUpdate(false)
	end, true)

	section(page, "Acil durum")
	button(page, "Her şeyi kapat (panik)", function()
		local ids = { "AutoFarm", "KillAura", "AutoFruit", "AutoChest", "AutoRaid", "AutoBoss",
			"BringMobs", "FreezeMobs", "AutoStats", "AutoPumpkin", "AutoCandy", "AutoHellfire",
			"AutoEventMisc", "Fly", "NoClip" }
		for _, id in ipairs(ids) do
			local ref = ToggleRefs[id]
			if ref then ref.set(false) end
		end
		State.AutoFarm = false
		State.KillAura = false
		stopFly()
		notify("Tüm otomasyonlar kapatıldı")
	end, true)

	button(page, "Kaydet", function()
		saveCfg()
		notify("Kısayollar kaydedildi")
	end)

	-- tuş yakalama
	UIS.InputBegan:Connect(function(input, gameProcessed)
		if capturing and not gameProcessed then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				Binds[capturing] = input.KeyCode
				for _, r in ipairs(refreshers) do
					if r.id == capturing then r.fn() end
				end
				if ToggleRefs[capturing] and ToggleRefs[capturing].refreshKey then
					ToggleRefs[capturing].refreshKey()
				end
				notify("Kısayol atandı: " .. input.KeyCode.Name)
				saveCfg()
				capturing = nil
			end
			return
		end

		-- menü aç / kapat
		if input.KeyCode == Binds.Gui and not gameProcessed then
			gui.Enabled = not gui.Enabled
			return
		end
		if gameProcessed then return end

		-- kısayollar (gui açıkken de çalışır)
		for id, key in pairs(Binds) do
			if id ~= "Gui" and key == input.KeyCode then
				local ref = ToggleRefs[id]
				if ref then ref.set(not ref.get()) end
			end
		end
	end)
end

end) -- arayüz kurulumu sonu

if not buildOk then
	local msg = tostring(buildErr)
	pcall(function() warn("[CHIKO] arayüz hatası: " .. msg) end)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Chiko Hub — arayüz hatası",
			Text = string.sub(msg, 1, 150),
			Duration = 12,
		})
	end)
	errorLabel.Text = "Arayüz hatası: " .. string.sub(msg, 1, 110)
	errorLabel.Visible = true
end

--===================================================================
-- 9) DÖNGÜLER
--===================================================================
task.spawn(function()
	while gui.Parent do
		if State.AutoFarm then
			local ok, err = pcall(farmTick)
			if not ok then lastFarmError = tostring(err) end
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.KillAura then pcall(auraTick) end
		task.wait(0.1)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.AutoFruit then pcall(fruitTick) end
		task.wait(0.5)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.AutoChest then pcall(chestTick) end
		task.wait(0.7)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.AutoPumpkin or State.AutoCandy or State.AutoHellfire or State.AutoEventMisc then
			pcall(eventTick)
		end
		pcall(function() State.EventFound = #getEventObjects() end)
		if eventCountLabel and eventCountLabel.Parent then
			eventCountLabel.Text = "Bulunan nesne: " .. tostring(State.EventFound)
		end
		task.wait(0.35)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.AutoRaid then pcall(raidTick) end
		task.wait(1)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.AutoStats then pcall(statTick) end
		task.wait(1.5)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.NoClip then
			local _, hum = getChar()
			if hum then pcall(function() hum:ChangeState(11) end) end
		end
		task.wait(0.25)
	end
end)

-- takılma koruması: farm/aura karakteri kilitlerse kendini toparlar
task.spawn(function()
	while gui.Parent do
		task.wait(1)
		if State.AutoFarm or State.KillAura or State.Fly then
			local _, hum, hrp = getChar()
			if hum and hrp then
				if hrp.Anchored then pcall(function() hrp.Anchored = false end) end
				if hum.PlatformStand and not State.Fly then pcall(function() hum.PlatformStand = false end) end
				if hum.WalkSpeed == 0 and not State.Fly then pcall(function() hum.WalkSpeed = State.WalkSpeed end) end
			end
		end
	end
end)

-- uçuş
local flyWasOn = false
task.spawn(function()
	while gui.Parent do
		if State.Fly then
			flyWasOn = true
			pcall(flyTick)
			task.wait(0.03)
		else
			if flyWasOn then
				flyWasOn = false
				pcall(stopFly)
			end
			task.wait(0.2)
		end
	end
end)

-- anti-afk: oyun "hareketsiz" diye atmasın
local afkTick = 0
task.spawn(function()
	while gui.Parent do
		task.wait(5)
		if State.AntiAfk then
			afkTick = afkTick + 5
			if afkTick >= 25 then
				afkTick = 0
				local _, hum = getChar()
				if hum then pcall(function() hum.Jump = true end) end
			end
		end
	end
end)

-- candy corn motoru (kapı + balkabağı)
task.spawn(function()
	while gui.Parent do
		local active = select(1, moonInfo())
		if State.CandyAutoStart and active and not State.CandyDoor then
			State.CandyDoor = true
			if ToggleRefs["CandyDoor"] then pcall(ToggleRefs["CandyDoor"].set, true) end
		end
		local did = false
		if State.CandyDoor and nearestDoor(true) then
			pcall(doorTick)
			did = true
		end
		if not did and State.CandyPumpkin then pcall(pumpkinBreakTick) end
		pcall(updateCandyLabels)
		task.wait(0.2)
	end
end)

-- alan halkası + kilit temizliği
task.spawn(function()
	while gui.Parent do
		pcall(updateRing)
		if State.KillAura then pcall(releaseStale) else pcall(releaseHold) end
		task.wait(0.25)
	end
end)

-- dash / hız beklemesini atlama
local dashBase, dashOn = nil, false
task.spawn(function()
	while gui.Parent do
		if State.DashBypass then
			local _, hum = getChar()
			if hum then
				if hum.MoveDirection.Magnitude > 0.1 then
					if not dashBase then dashBase = hum.WalkSpeed end
					hum.WalkSpeed = State.SafeSpeed and math.min(State.DashSpeed, State.SpeedCap) or State.DashSpeed
					dashOn = true
				elseif dashOn then
					hum.WalkSpeed = dashBase or 16
					dashBase, dashOn = nil, false
				end
			end
			task.wait(0.05)
		else
			if dashOn then
				local _, hum = getChar()
				if hum then hum.WalkSpeed = dashBase or 16 end
				dashBase, dashOn = nil, false
			end
			task.wait(0.4)
		end
	end
end)

-- teşhis sayaçları (arayüzde canlı gösterilir)
task.spawn(function()
	while gui.Parent do
		pcall(function()
			State.ChestCount = #getChests()
			State.FruitCount = #getFruits()
			State.MobCount = #mobList()
		end)
		task.wait(2)
	end
end)

task.spawn(function()
	while gui.Parent do
		if State.ESPPlayers or State.ESPEnemies or State.ESPFruits or State.ESPChests
			or State.ESPNpc or State.ESPBeasts or State.ESPEvent then
			pcall(updateESP)
		end
		task.wait(0.4)
	end
end)

-- auto observation (Ken)
task.spawn(function()
	while gui.Parent do
		task.wait(2)
		if State.AutoObserve then pcall(pressRaw, "K", 0x4B) end
	end
end)

-- yeni meyve bildirimi
task.spawn(function()
	local seen = {}
	while gui.Parent do
		task.wait(4)
		if State.FruitNotify then
			local now = {}
			pcall(function()
				for _, f in ipairs(getFruits()) do
					now[f.Name] = true
					if not seen[f.Name] then notify("Meyve bulundu: " .. f.Name) end
				end
			end)
			seen = now
		end
	end
end)

-- anti-AFK
do
	local VirtualUser = game:GetService("VirtualUser")
	LP.Idled:Connect(function()
		if not State.AntiAFK then return end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)
end

-- hasar gözlemcisi: vuruşlar hasar vermiyorsa sanal tık yedeğine geç
task.spawn(function()
	local lastMob, lastHp, lastHit = nil, nil, os.clock()
	while gui.Parent do
		task.wait(0.4)
		if (State.AutoFarm or State.KillAura) and not State.NoDamage then
			local _, _, hrp = getChar()
			local mob = (hrp and nearestMob(nil)) or nil
			local root = mob and mob:FindFirstChild("HumanoidRootPart")
			local hum = mob and mob:FindFirstChildOfClass("Humanoid")
			local near = root and hrp and (root.Position - hrp.Position).Magnitude <= 22
			if near and hum then
				local hp = hum.Health
				if mob ~= lastMob or (lastHp and hp < lastHp - 1) then
					lastHit = os.clock()
				end
				lastMob, lastHp = mob, hp
				if os.clock() - lastHit > 7 then
					State.NoDamage = true
					notify("Hasar algılanmadı: sanal tık yedeği açıldı")
				end
			else
				lastHit = os.clock()
				lastMob, lastHp = nil, nil
			end
		end
	end
end)

-- durum satırı
task.spawn(function()
	while gui.Parent do
		local lvl = getLevel()
		local parts = { "Lv " .. tostring(lvl) }
		local beli = leaderStat("Beli") or leaderStat("Money")
		local bounty = leaderStat("Bounty")
		if bounty and tonumber(bounty) and tonumber(bounty) > 0 then parts[#parts + 1] = "Bounty " .. shortNum(bounty) end
		if State.AutoFarm then
			parts[#parts + 1] = "Farm: " .. State.Target
			parts[#parts + 1] = State.AttackMode
		end
		if State.KillAura then parts[#parts + 1] = "Aura" end
		if State.AutoFruit then parts[#parts + 1] = "Meyve" end
		if State.AutoChest then parts[#parts + 1] = "Sandık" end
		if State.AutoRaid then parts[#parts + 1] = "Raid: " .. State.RaidTheme end
		if State.AutoHaki then parts[#parts + 1] = "Haki" end
		if State.AutoPumpkin then parts[#parts + 1] = "Pumpkin" end
		if State.AutoCandy then parts[#parts + 1] = "Candy" end
		if State.AutoHellfire then parts[#parts + 1] = "Hellfire" end
		if State.TpInfo ~= "" then parts[#parts + 1] = "TP: " .. State.TpInfo end
		if State.NoDamage then parts[#parts + 1] = "sanal tık" end
		if State.Fly then parts[#parts + 1] = "Uçuyor" end
		if State.Bypass then parts[#parts + 1] = "bypass" end
		if State.KillAura and State.AuraInfo then parts[#parts + 1] = "aura: " .. tostring(State.AuraInfo) end
		parts[#parts + 1] = "mob " .. tostring(State.MobCount)
		parts[#parts + 1] = "sandık " .. tostring(State.ChestCount)
		parts[#parts + 1] = "meyve " .. tostring(State.FruitCount)
		lvlChip.Text = "Lv " .. tostring(lvl)
		beliChip.Text = "Beli " .. (beli and shortNum(beli) or "--")
		statusLabel.Text = table.concat(parts, "   |   ")
		task.wait(0.5)
	end
end)

-- ilk sekmeyi aç
for _, t in ipairs(Tabs) do
	if t.name == "Farm" then
		t.page.Visible = true
		t.button.BackgroundColor3 = Theme.panel
		t.button.BackgroundTransparency = 0
		t.label.TextColor3 = Theme.text
		t.bar.Visible = true
		activeTab = "Farm"
		break
	end
end

-- yükleme animasyonu + açılış
local startPos = main.Position
do
	local tips = {
		"Servisler bağlanıyor...",
		"Uzak fonksiyonlar hazırlanıyor (CommF_)...",
		"Saldırı motoru kuruluyor (tıklamasız vuruş)...",
		"Işınlanma doğrulaması hazırlanıyor...",
		"Arayüz çiziliyor...",
		"Hazır! INSERT ile menüyü aç / kapat",
	}
	local t0 = os.clock()
	local total = 1.2
	while loaderGui.Parent and not loaderSkip do
		local p = math.min((os.clock() - t0) / total, 1)
		if loaderFill then loaderFill.Size = UDim2.new(p, 0, 1, 0) end
		if loaderPct then loaderPct.Text = string.format("%d%%", math.floor(p * 100)) end
		if loaderTip then
			local i = math.clamp(math.floor(p * #tips) + 1, 1, #tips)
			loaderTip.Text = tips[i]
		end
		if p >= 1 then break end
		task.wait(0.03)
	end
	if loaderFill then loaderFill.Size = UDim2.new(1, 0, 1, 0) end
	if loaderPct then loaderPct.Text = "100%" end
	task.wait(0.12)
	if loaderGui then pcall(function() loaderGui:Destroy() end) end
end

-- açılış animasyonu
gui.Enabled = true
main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + 16)
TS:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Position = startPos,
}):Play()

notify("CHIKO HUB v" .. HUB_VERSION .. " hazır. INSERT ile menü.")
if State.SafeMode then
	notify("Güvenli mod açık — çökme riski düşük. Hız için Ayarlar > Güvenli mod kapat.")
end

-- otomatik sürüm kontrolü: açılışta ve 15 dakikada bir
task.spawn(function()
	task.wait(4)
	pcall(checkUpdate, true)
	while gui.Parent do
		task.wait(900)
		pcall(checkUpdate, true)
	end
end)

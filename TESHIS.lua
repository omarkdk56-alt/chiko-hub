--[[ CHIKO HUB — SAHA TEŞHİSİ
  Ne yapar? Oyunun içinden şunları ölçer:
   1) Executor'da hangi fonksiyonlar var (VirtualUser, mouse1click, getgc, firetouchinterest...)
   2) Kuşanılmış tool ve alt nesneleri (RemoteEvent / RemoteFunction var mı)
   3) Enemies içindeki moblar ve mesafeler
   4) 5 farklı vuruş yöntemini tek tek dener ve GERÇEKTEN hasar veren var mı ölçer
  Çıktıyı kopyalayıp bana gönder.
]]
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local out = {}
local function add(s)
	out[#out + 1] = s
	print("[CHIKO] " .. s)
end

local function getChar()
	local ch = LP.Character
	if not ch then return nil end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if hum and hrp then return ch, hum, hrp end
	return nil
end

add("=== CAPS ===")
local checks = {
	{ "VirtualUser", function() return game:GetService("VirtualUser") end },
	{ "VirtualInputManager", function() return game:GetService("VirtualInputManager") end },
}
for _, c in ipairs(checks) do
	local ok, v = pcall(c[2])
	add(c[1] .. "=" .. tostring(ok and v ~= nil))
end
add("mouse1click=" .. tostring(type(mouse1click) == "function"))
add("getgc=" .. tostring(type(getgc) == "function"))
add("getgenv=" .. tostring(type(getgenv) == "function"))
add("firetouchinterest=" .. tostring(type(firetouchinterest) == "function"))
add("fireclickdetector=" .. tostring(type(fireclickdetector) == "function"))
add("fireproximityprompt=" .. tostring(type(fireproximityprompt) == "function"))
add("hookfunction=" .. tostring(type(hookfunction) == "function"))
add("setclipboard=" .. tostring(type(setclipboard) == "function"))
add("identifyexecutor=" .. tostring(type(identifyexecutor) == "function"))
if type(identifyexecutor) == "function" then
	local ok, name = pcall(identifyexecutor)
	add("executor=" .. tostring(ok and name or "?"))
end

local ch, hum, hrp = getChar()
add("=== CHAR ===")
add("char=" .. tostring(ch ~= nil) .. " humHP=" .. tostring(hum and math.floor(hum.Health) or -1)
	.. " ws=" .. tostring(hum and hum.WalkSpeed or -1)
	.. " platformStand=" .. tostring(hum and hum.PlatformStand or "?")
	.. " hrpAnchored=" .. tostring(hrp and hrp.Anchored or "?"))

add("=== TOOL ===")
if ch then
	local tool = ch:FindFirstChildOfClass("Tool")
	if tool then
		add("equipped=" .. tool.Name .. " className=" .. tool.ClassName)
		local kids = {}
		for _, k in ipairs(tool:GetChildren()) do
			kids[#kids + 1] = k.Name .. ":" .. k.ClassName
		end
		add("toolKids=" .. table.concat(kids, ", "))
		add("toolHasCooldownAttr=" .. tostring(tool:GetAttribute("Cooldown")))
	else
		add("equipped=NONE")
	end
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		local names = {}
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then names[#names + 1] = t.Name end
		end
		add("backpack=" .. table.concat(names, ", "))
	end
end

add("=== MOBS ===")
local enemies = workspace:FindFirstChild("Enemies")
local function mobList()
	local list = {}
	for _, m in ipairs((enemies and enemies:GetChildren()) or {}) do
		if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
			list[#list + 1] = m
		end
	end
	return list
end
local mobs = mobList()
add("enemiesFolder=" .. tostring(enemies ~= nil) .. " mobCount=" .. #mobs)
for i = 1, math.min(#mobs, 6) do
	local m = mobs[i]
	local d = hrp and math.floor((m.HumanoidRootPart.Position - hrp.Position).Magnitude) or -1
	add("mob" .. i .. "=" .. m.Name .. " dist=" .. d .. " hp=" .. math.floor(m:FindFirstChildOfClass("Humanoid").Health))
end

-- vuruş yöntemleri -------------------------------------------------
local VU = nil
pcall(function() VU = game:GetService("VirtualUser") end)
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function clickVU()
	if not VU then return end
	pcall(function()
		VU:CaptureController()
		VU:ClickButton1(Vector2.new(0, 0))
	end)
end
local function clickMouse()
	if type(mouse1click) == "function" then pcall(mouse1click) end
end
local function clickVIM()
	if not VIM then return end
	pcall(function()
		VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
		VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
	end)
end
local function activate()
	if ch then
		local t = ch:FindFirstChildOfClass("Tool")
		if t then pcall(function() t:Activate() end) end
	end
end

local function damageOf(mob, fn)
	local mh = mob:FindFirstChildOfClass("Humanoid")
	if not mh then return -1 end
	local before = mh.Health
	for _ = 1, 10 do
		fn()
		task.wait(0.12)
	end
	task.wait(0.4)
	return before - mh.Health
end

add("=== DAMAGE TEST ===")
local target = mobs[1]
if not target then
	add("hedef yok: Enemies boş, bir mobun yanına git ve tekrar çalıştır")
else
	if hrp then
		pcall(function() hrp.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5) end)
		task.wait(0.2)
	end
	add("target=" .. target.Name)
	add("m1_activate=" .. tostring(damageOf(target, activate)))
	add("m1_virtualuser=" .. tostring(damageOf(target, clickVU)))
	add("m1_mouse1click=" .. tostring(damageOf(target, clickMouse)))
	add("m1_vim=" .. tostring(damageOf(target, clickVIM)))
	add("m1_combined=" .. tostring(damageOf(target, function() activate(); clickVU() end)))
end

-- GERÇEK hasar yolu: RigLib.getBladeHits + RigControllerEvent("hit")
add("=== BLADE HIT TEST ===")
local function bladeOnce()
	local ch = LP.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not (ch and hrp) then return end
	pcall(function()
		local cf = RS:FindFirstChild("CombatFramework")
		local rigLib = cf and cf:FindFirstChild("RigLib")
		local ev = RS:FindFirstChild("RigControllerEvent")
		add("rigLib=" .. tostring(rigLib ~= nil) .. " rigEvent=" .. tostring(ev ~= nil))
		if not (rigLib and ev) then return end
		local hits = require(rigLib).getBladeHits(ch, { hrp }, 60)
		add("getBladeHits=" .. tostring(type(hits) == "table" and #hits or "nil"))
		if type(hits) ~= "table" or #hits == 0 then return end
		local ac = nil
		pcall(function()
			local mod = require(LP.PlayerScripts:WaitForChild("CombatFramework", 3))
			if type(debug.getupvalues) == "function" then
				for _, up in pairs(debug.getupvalues(mod)) do
					if type(up) == "table" and type(up.activeController) == "table" then ac = up.activeController end
				end
			end
		end)
		add("activeController=" .. tostring(ac ~= nil))
		if ac and ac.blades and ac.blades[1] then
			pcall(function() ev:FireServer("weaponChange", tostring(ac.blades[1])) end)
		end
		for i = 1, #hits do ev:FireServer("hit", hits, i, "") end
	end)
end
if target then
	add("blade_hit=" .. tostring(damageOf(target, bladeOnce)))
else
	add("blade_hit=hedef yok")
end

add("=== END ===")
local text = table.concat(out, "\n")
if type(setclipboard) == "function" then
	pcall(setclipboard, text)
	add("(rapor panoya kopyalandı)")
else
	add("(setclipboard yok — konsoldan kopyala)")
end

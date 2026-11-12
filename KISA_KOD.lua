--[[
  CHIKO HUB — KISA KOD (loader)
  ---------------------------------------------------------------
  Ne yapar? Scripti GitHub'dan indirip çalıştırır. Böylece 4000 satırı
  executor'a yapıştırmazsın, "kısa kod" yeter. Güncelleme gelince
  sadece GitHub'daki dosyayı değiştirirsin, kod aynı kalır.

  KURULUM
  1) BloxFruitsHub.lua'yı GitHub'a yükle:
     - github.com → New repository → public (Private raw çalışmaz)
     - "Add file → Upload files" ile BloxFruitsHub.lua'yı at
  2) Dosyayı aç → sağ üstte "Raw" → adres çubuğundaki linki kopyala
     Örnek: https://raw.githubusercontent.com/omarkdk56-alt/chiko-hub/main/BloxFruitsHub.lua
  3) Aşağıdaki URL değişkenine o linki yaz.
  4) Bu dosyanın TAMAMINI executor'a yapıştır → Execute.

  NOT: GitHub raw ~5 dakika önbellekler. Güncelleme hemen görünmüyorsa
  jsDelivr linki kullan (daha hızlı tazelenir):
  https://cdn.jsdelivr.net/gh/omarkdk56-alt/chiko-hub@main/BloxFruitsHub.lua
]]

local URL = "https://raw.githubusercontent.com/omarkdk56-alt/chiko-hub/main/BloxFruitsHub.lua"

local function fetch(u)
	-- 1) executor'ın HttpGet'i (Xeno, Delta, Solara...)
	if game and type(game.HttpGet) == "function" then
		local ok, body = pcall(function() return game:HttpGet(u) end)
		if ok and type(body) == "string" and #body > 500 then return body end
	end
	-- 2) request / syn.request / http_request
	local http = (syn and syn.request) or (http and http.request) or http_request or request
	if http then
		local ok, res = pcall(http, { Url = u, Method = "GET" })
		if ok and type(res) == "table" then
			local body = res.Body or res.body
			if type(body) == "string" and #body > 500 then return body end
		end
	end
	return nil
end

local CDN = "https://cdn.jsdelivr.net/gh/omarkdk56-alt/chiko-hub@main/BloxFruitsHub.lua"

local function runFrom(u, tag)
	local src = fetch(u)
	if not src then
		warn("[Chiko] indirilemedi (" .. tag .. ")")
		return false
	end
	local chunk, err = loadstring(src, "=ChikoHub")
	if not chunk then
		warn("[Chiko] sözdizimi hatası (" .. tag .. "): " .. tostring(err))
		return false
	end
	local ok, runErr = pcall(chunk)
	if not ok then
		warn("[Chiko] çalışma hatası (" .. tag .. "): " .. tostring(runErr))
		return false
	end
	return true
end

local ts = tostring(os.time())
if runFrom(URL .. "?t=" .. ts, "github") then return end

-- GitHub önbelleği eski/bozuk sürüm verdiyse jsDelivr'den dene
if runFrom(CDN .. "?t=" .. ts, "jsdelivr") then return end

warn("[Chiko] iki kaynaktan da yüklenemedi. Linkleri kontrol et.")
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Chiko Hub",
		Text = "Script yüklenemedi — GitHub/jsDelivr erişimi yok.",
		Duration = 8,
	})
end)

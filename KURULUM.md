# CHIKO HUB — Kurulum / Çalıştırma

## Kısa cevap: "exe injector" yok, gerek de yok
Roblox'a kod enjekte eden bir `.exe` yazmıyorum. Sebebi teknik: enjeksiyonu zaten **executor** yapıyor
(process'e bağlanır, senin yazdığın Lua'yı oyun içinde çalıştırır). Üçüncü parti bir "injector exe"
yazmak, Byfron/Hyperion anti-cheat'ini atlatmaya çalışan bir araç üretmek demek — hesabı direkt riske
atar ve çoğu zaman içinde zararlı kod taşır. Onun yerine: executor + loader.

## 1. Executor kur
PC'de çalışan bir executor seç. Elindeki ikisinden **Xeno'yu kullan** (tam UNC desteği var: `readfile`, `isfile`,
`request`, `fireproximityprompt`). JJSploit eski/detected ve fonksiyon seti kısıtlı; Blox Fruits'te çoğu zaman
enjeksiyonda takılır — onda Yol A'yı (doğrudan yapıştırma) kullan.

Kurulumdan sonra executor'ı **yönetici olarak** aç ve `Attach / Inject` butonuna bas; "Attached" yazısını gör.

### Xeno'da workspace klasörü nerede?
`Xeno.exe`'nin yanındaki **`workspace`** klasörü (yoksa Xeno bir kez dosya yazınca kendisi oluşturur).
Bulmanın en hızlı yolu: Xeno'yu aç → Görev Yöneticisi değil, kısayola sağ tık → **Dosya konumunu aç**
→ çıkan klasörde `workspace` klasörünü gör.

Klasörün gerçekten çalıştığını doğrulamak için executor'da şunu çalıştır:
```lua
writefile("CHIKO_TEST.txt", "ok")
print(isfile("CHIKO_TEST.txt"))  -- true yazmalı
```

### JJSploit'te workspace klasörü
`Win+R` → `%localappdata%` → `JJSploit` (veya `WeAreDevs`) klasörü → `workspace`.
Yoksa executor'da bir kez `writefile("a.txt","x")` çalıştırınca oluşur.

## 2. Scripti çalıştır (2 yol var)

### Yol A — doğrudan (en basit)
1. `BloxFruitsHub.lua` dosyasını metin editöründe aç, tümünü kopyala.
2. Executor'ın kod kutusuna yapıştır.
3. `Execute` → menü açılır, **INSERT** ile göster/gizle.

### Yol B — loader ile (her seferinde yapıştırmadan)
1. `BloxFruitsHub.lua` dosyasını executor'ın **workspace** klasörüne kopyala
   (executor panelindeki dosya yöneticisi → Workspace).
2. `ChikoLoader.lua` içeriğini executor'a yapıştır → `Execute`.
3. Loader dosyayı bulup çalıştırır. Yeni sürüm gelince sadece `BloxFruitsHub.lua`'yı değiştir,
   loader aynı kalır.

Loader'ı URL'den çalıştırmak istersen `ChikoLoader.lua` içindeki `URL = ""` satırına raw link yaz
(GitHub raw / pastebin raw). Dosya yoksa oradan indirir.

## 3. Kullanım ipuçları
- `Ayarlar → Kısayollar` bölümünden tuşları değiştirebilirsin; `Kaydet` ile executor'ın klasörüne
  yazılır, bir sonraki açılışta hatırlanır.
- Bir özellik çalışmıyorsa: **Teşhis** sekmesi → "Raporu kopyala". Raporda CommF_ remote, klasörler,
  canlı düşman/sandık/meyve sayıları yazıyor.
- Etkinlik nesneleri isimle bulunuyor. Teşhis → "Nesne ara" kutusuna `pumpkin` yazıp kaç sonuç
  döndüğüne bakabilirsin.
- Takıldıysa `Ayarlar → Her şeyi kapat (panik)`.

## Uyarı
Bu script oyunun kurallarına aykırıdır; hesabın yasaklanabilir. Riski sana ait — test için kendi
private sunucunu kullan ve ana hesabında denememeye çalış.

## Kısa kod (GitHub'dan yükleme) — önerilen
Sitelerin verdiği "kısa kod" mantığı bu: kod GitHub'da durur, sende sadece tek satır link olur.

1. github.com → **New repository** → **public** (private repo'nun raw linki çalışmaz).
2. **Add file → Upload files** → `BloxFruitsHub.lua` dosyasını yükle.
3. Dosyayı aç → sağ üst **Raw** → adres çubuğundaki linki kopyala:
   `https://raw.githubusercontent.com/omarkdk56-alt/chiko-hub/main/BloxFruitsHub.lua`
4. `KISA_KOD.lua` içindeki `URL` satırına yapıştır, dosyanın tamamını executor'a at → **Execute**.
5. Güncelleme: GitHub'da dosyayı değiştir, oyunda kısa kodu tekrar çalıştır. (Raw ~5 dk önbellekler;
   hız için `https://cdn.jsdelivr.net/gh/omarkdk56-alt/chiko-hub@main/BloxFruitsHub.lua` kullan.)

En kısa hali (URL'yi kendi linkinle değiştir):
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/omarkdk56-alt/chiko-hub/main/BloxFruitsHub.lua"))()
```

-- Dream Hub | Ability Arena | v2.17.0
-- by Dream Hub Owner
-- v2.17.0: M1 HITBOX REWORK (the real fix). Ability Arena does CLIENT-SIDE hit reg off your REAL arm parts +
--          their velocity. The old anchored MH_ArmReach follower parts had 0 velocity (Jolt ignores anchored
--          parts) and the wrong name, so the game never queried them. Now we resize the REAL arms and drop them
--          into a collision group that collides with NOTHING (+ CanCollide off, Massless on) so Jolt can't fling
--          or reset you; CanQuery/CanTouch stay on so the game's GetPartBoundsInBox registers the hit. Also
--          stopped forcing enemy hitboxes to Block (that shrank Ball hitboxes under shape-aware queries).
-- v2.16.0: NEW ANTI-CHEAT NEUTRALIZED - the game added client-side anti-cheat initializers
--          (ReplicatedStorage.Files.Client._Client_Initializers._Client_AntiFling etc). They run on
--          YOUR client, so we disable the running copies AND pre-disable the templates (clones of a
--          Disabled script spawn dead) - teleports/velocity features work again. Notifications
--          rebuilt: small fast toasts (no more doubled text, gone in ~2s).
-- v2.8.0: Kill Aura fixed (crash bug killed the loop), real clicking, One Shot Punch
--         remote wired into every M1, fixed M1 packet bytes, buffer sends, hitbox
--         expanders reworked (M1 + Ability share one engine), Teleports tab added.
-- v2.8.1: manual-click one shot debounced (no more self-kick from click flooding)
--         + skipped while typing; Kill Aura no longer secretly forces the M1 Hitbox
--         toggle on (it used to stay stuck on after you turned Kill Aura off).
-- v2.9.0: Kill Aura targeting reworked - this game's characters often have NO
--         Humanoid (they use a custom "Hitbox" part + a "Health" script), so the
--         old "require a Humanoid" target test matched nobody = Kill Aura did
--         nothing. Now targets the Hitbox directly. Added God Mode (best effort,
--         off the Health object) and an Add Aura feature (client-side visual).
-- v2.9.1: removed the M1 + Ability hitbox expanders (server-side hit validation
--         meant they never landed - they only made enemies look big). Auras now
--         force every emitter/light ON and re-emit every 0.5s so you SEE the glow
--         (not just the mesh), it stays on, and re-applies after you respawn.
-- v2.9.2: removed God Mode + One Shot. Added Save Health (low HP -> fly to sky,
--         hold, drop back when healed). Anti Void/Water no longer needs a
--         Humanoid (raycast ground-memory). Kill Aura auto-click now SKIPS firing
--         whenever your real cursor is over the Rayfield menu.
-- v2.9.3: brought BACK the M1 + Ability hitbox expanders (this game does
--         client-side hit detection - the M1 packet has a "Hits" list - so
--         growing the enemy Hitbox makes your real M1s reach farther; now
--         targets via isAlive so it applies with no Humanoid). Removed Kill Aura.
-- v2.9.4: Auto Dash -> "Dash Behind On Hit" (M1 snaps you behind the nearest
--         enemy - which also LANDS the M1 point-blank - then dashes Q; removed the
--         LeftShift/shift-lock that messed your camera). Save Health now ANCHORS you
--         in the sky (default 700) so knockback can't pull you out. Auras strip
--         GUIs + weld every VFX part to your body so all the effects actually show.
-- v2.9.5: Ability Grabber now RETURNS you to a real map spawn (workspace.GameMap
--         .Spawns) after grabbing instead of stranding you in the lobby to die;
--         "Return to map spawn" defaults ON. TP To Spawn button uses GameMap.Spawns too.
-- v2.9.6: GameMap.Spawns turned out to BE the lobby, so the grab now returns you to
--         your EXACT pre-grab spot on the map (backCF) instead. Hitbox + Ability
--         Hitbox sizes bumped (50/40, up to 150) so the reach is big enough for the
--         game's overlap check to register your hits.
-- v2.9.7: ESP now reads HP for characters with NO Humanoid (custom Health) so the
--         label is never blank. Added "Remove Water Border" (destroys the invisible
--         Border.Water walls so Anti Water actually holds) and "Anti Kill Bricks"
--         (destroys Workspace.KillBricks so they can't touch-kill you). Both are
--         toggles that re-clear every second to beat re-replication.
-- v2.9.8: neon-red Rayfield theme (near-black UI, glowing red toggles/sliders/tabs).
-- v2.9.9: rebranded to Dream Hub; added a Home tab + per-tab sidebar icons.
-- v2.10.0: teleport fixes (no fling, removed lobby TP-to-Spawn, safe Click-TP, auto-refresh
--          target lists, Save-Health-safe Safe-Spawn) + full Unload disconnect + lighting restore.
-- v2.11.0: richer ESP (ability + colored health bar + 2D boxes + max-distance), View Player
--          (spectate), and a stronger hitbox (handles Model hitboxes + whole-body, cap 300).
-- v2.11.1: fixed Auto Farm / Auto Play - now face the target, no fling, correct position.
-- v2.11.2: Auto Farm/Play only teleport when out of range (>8 studs), then just face the
--          target - stops the constant snap-back/rubber-banding.
-- v2.12.0: added best-effort God Mode (re-applies full HP + flips existing safe/damage flags).
-- v2.13.0: added Ability Aim Assist (face nearest enemy w/ velocity lead on skill cast).
-- v2.13.1: removed God Mode.
-- v2.13.2: Auto Farm/Play now actually deal damage - auto-grow the enemy hitbox while on,
--          and force the M1 click so it fires even with the menu open.
-- v2.13.3: Auto Farm/Play M1 lands consistently - throttled swing cadence (~0.35s) so the M1
--          isn't cancelled before its hit-frame; abilities spaced out so they don't interrupt it.
-- v2.13.4: auto-farm now clicks ON the enemy (forced); broader ability detection; added a
--          'Dump Player Data' debug button to read the game's real attributes/values.
-- v2.13.5: reverted Auto Farm/Play to the original point-blank brute-force (teleport INSIDE the
--          target's hitbox every 0.1s) that actually lands hits; the distance-gating broke it.
-- v2.13.6: added M1 Packet Spy (Utility>Debug) to capture a real damaging M1 packet so buildM1
--          can be rebuilt to carry the target (fixes Auto Farm M1 dealing no damage).

-- ════════ ANTI-CHEAT NEUTRALIZER ════════
-- The game's new anti-cheat is CLIENT-side (LocalScripts under ReplicatedStorage.Files.Client.
-- _Client_Initializers, e.g. _Client_AntiFling). Client scripts are ours to disable:
--  1) pre-disable the TEMPLATES (a clone of a Disabled script never runs), and
--  2) kill every RUNNING copy in PlayerScripts / PlayerGui / your character, now and on respawn.
task.spawn(function()
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local LP = Players.LocalPlayer
    local function isAC(o)
        if not (o:IsA("LocalScript") or o:IsA("Script")) then return false end
        local n = o.Name:lower()
        return n:find("anti", 1, true) ~= nil   -- _Client_AntiFling, AntiCheat, AntiTeleport, ...
    end
    local function kill(o) pcall(function() o.Disabled = true end) end
    local function sweep(root)
        if not root then return end
        pcall(function() for _, d in ipairs(root:GetDescendants()) do if isAC(d) then kill(d) end end end)
        pcall(function() root.DescendantAdded:Connect(function(d) if isAC(d) then task.defer(kill, d) end end) end)
    end
    pcall(function()   -- templates first: everything cloned from here spawns already-disabled
        local files = RS:WaitForChild("Files", 9)
        local client = files and files:FindFirstChild("Client")
        sweep(client)
    end)
    sweep(LP:FindFirstChild("PlayerScripts") or LP:WaitForChild("PlayerScripts", 5))
    sweep(LP:FindFirstChild("PlayerGui"))
    if LP.Character then sweep(LP.Character) end
    LP.CharacterAdded:Connect(function(c) task.wait(0.2); sweep(c) end)
end)

-- ════════ UI: Fluriore (Rayfield-compatible shim) with a Rayfield FALLBACK ════════
-- The hub was written against Rayfield's API. We load Fluriore and expose a tiny `Rayfield`
-- adapter mapping CreateWindow/CreateTab/CreateSection/CreateToggle/... onto Fluriore's real
-- API (verified: MakeGui / CreateTab / AddSection / AddToggle/AddSlider/AddButton/AddInput/
-- AddDropdown{:Refresh}/AddParagraph / MakeNotify / DestroyGui). If Fluriore fails to load,
-- we fall back to the FULL Rayfield so EVERY tab + feature still appears.
local Rayfield
local _FluWindow
do
    local FluLib
    pcall(function() FluLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mc4121ban/Fluriore-UI/main/source.lua"))() end)

    if type(FluLib) == "table" and type(FluLib.MakeGui) == "function" then
        local ACCENT = Color3.fromRGB(255, 32, 32)   -- Dream Hub v2 GUI: punchier glowing RED accent
        -- ---- New GUI: DEEP-BLACK panels with RED edge outlines, keeping the red accents ----
        -- Fluriore ships a dark theme (Main = RGB 15,15,15). We push every non-red dark
        -- background to pure black, then trace the larger panels with a thin red stroke so the
        -- whole hub reads as glowing-red-on-black. Red accents / light text are never touched.
        local CoreGuiSvc = game:GetService("CoreGui")
        local VBLACK = Color3.fromRGB(0,0,0)
        local EDGE   = Color3.fromRGB(150, 22, 22)   -- subtle red panel outline
        local function lum(c) return 0.299*c.R + 0.587*c.G + 0.114*c.B end
        local function isReddish(c) return c.R > c.G + 0.12 and c.R > c.B + 0.12 end  -- protect red accents
        local function edgeOne(o)
            -- Trace ONLY the larger black panels with a faint red outline. We tag them so we
            -- never double-stroke, and skip small controls/text to keep it clean.
            pcall(function()
                if not (o:IsA("Frame") or o:IsA("ScrollingFrame")) then return end
                if o:GetAttribute("DreamEdged") then return end
                local sz = o.AbsoluteSize
                if sz.X < 120 or sz.Y < 26 then return end
                o:SetAttribute("DreamEdged", true)
                local st = Instance.new("UIStroke")
                st.Color = EDGE; st.Thickness = 1; st.Transparency = 0.25
                st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = o
            end)
        end
        local function recolorOne(o)
            if not o then return end
            pcall(function()
                if o:IsA("GuiObject") then
                    local bg = o.BackgroundColor3
                    -- Only darken genuinely-dark, non-red panels -> pure black. Never touch red
                    -- accents (selected-tab bar, toggles-on, section gradient) or light text.
                    if (not isReddish(bg)) and lum(bg) < 0.30 then
                        o.BackgroundColor3 = VBLACK
                        edgeOne(o)
                    end
                end
            end)
        end
        local function recolorTree(root)
            if not root then return end
            recolorOne(root)
            for _,d in ipairs(root:GetDescendants()) do recolorOne(d) end
        end
        local function watchGui(gui)
            if not gui then return end
            recolorTree(gui)
            pcall(function() gui.DescendantAdded:Connect(function(d) task.defer(recolorOne, d) end) end)
        end
        local TAB_ICON = "rbxassetid://16932740082"
        local ICONS = {   -- Lucide-name -> real asset id (Fluriore only takes rbxassetid, no Lucide names)
            home="rbxassetid://7733960981", swords="rbxassetid://7733798747", sparkles="rbxassetid://8997388430",
            navigation="rbxassetid://7734020989", footprints="rbxassetid://7743870731", eye="rbxassetid://7733774602",
            target="rbxassetid://7743872758", wrench="rbxassetid://7743878358",
        }
        local function arr(t) local o={}; if type(t)=="table" then for _,v in ipairs(t) do o[#o+1]=v end end; return o end
        local function asTable(v) if type(v)=="table" then return v elseif v~=nil then return {v} else return {} end end
        local shim = {}
        -- CUSTOM fast toasts. Fluriore's MakeNotify printed the message TWICE (once next to the title,
        -- once as the body) and hung around too long. These are small, single-text, gone in ~2s.
        local notifList
        local function ensureNotif()
            if notifList and notifList.Parent then return end
            local g = Instance.new("ScreenGui")
            g.Name = "DreamNotif"; g.ResetOnSpawn = false; g.DisplayOrder = 99999; g.IgnoreGuiInset = true
            pcall(function() g.Parent = (gethui and gethui()) or CoreGuiSvc end)
            if not g.Parent then g.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
            notifList = Instance.new("Frame")
            notifList.BackgroundTransparency = 1; notifList.AnchorPoint = Vector2.new(1, 1)
            notifList.Position = UDim2.new(1, -14, 1, -14); notifList.Size = UDim2.fromOffset(290, 420); notifList.Parent = g
            local lay = Instance.new("UIListLayout")
            lay.VerticalAlignment = Enum.VerticalAlignment.Bottom; lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
            lay.Padding = UDim.new(0, 6); lay.Parent = notifList
        end
        function shim:Notify(cfg)
            cfg = cfg or {}
            pcall(function()
                ensureNotif()
                local TS = game:GetService("TweenService")
                local msg = tostring(cfg.Content or cfg.Description or "")
                local f = Instance.new("Frame")
                f.BackgroundColor3 = Color3.fromRGB(6, 6, 6); f.BorderSizePixel = 0; f.Size = UDim2.new(1, 0, 0, 42); f.Parent = notifList
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
                local st = Instance.new("UIStroke"); st.Color = ACCENT; st.Thickness = 1.3; st.Parent = f
                local t = Instance.new("TextLabel")
                t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextColor3 = ACCENT
                t.TextXAlignment = Enum.TextXAlignment.Left; t.Position = UDim2.fromOffset(10, 4); t.Size = UDim2.new(1, -20, 0, 14)
                t.Text = tostring(cfg.Title or "Dream Hub"); t.Parent = f
                local b = Instance.new("TextLabel")
                b.BackgroundTransparency = 1; b.Font = Enum.Font.Gotham; b.TextSize = 12; b.TextColor3 = Color3.fromRGB(235, 235, 235)
                b.TextXAlignment = Enum.TextXAlignment.Left; b.TextWrapped = true; b.TextTruncate = Enum.TextTruncate.AtEnd
                b.Position = UDim2.fromOffset(10, 19); b.Size = UDim2.new(1, -20, 0, 20); b.Text = msg; b.Parent = f
                f.BackgroundTransparency = 1; st.Transparency = 1; t.TextTransparency = 1; b.TextTransparency = 1
                TS:Create(f, TweenInfo.new(0.12), { BackgroundTransparency = 0.05 }):Play()
                TS:Create(st, TweenInfo.new(0.12), { Transparency = 0.2 }):Play()
                TS:Create(t, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()
                TS:Create(b, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()
                task.delay(math.min(cfg.Duration or 2, 2.4), function()   -- FAST: visible ~2s max, then fades
                    pcall(function()
                        TS:Create(f, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
                        TS:Create(st, TweenInfo.new(0.18), { Transparency = 1 }):Play()
                        TS:Create(t, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
                        TS:Create(b, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
                    end)
                    task.delay(0.2, function() pcall(function() f:Destroy() end) end)
                end)
            end)
        end
        function shim:Destroy()
            pcall(function() if _FluWindow then (_FluWindow.DestroyGui or _FluWindow.Destroy)(_FluWindow) end end)
        end
        function shim:CreateWindow(cfg)
            cfg = cfg or {}
            local col = ACCENT   -- Dream Hub: red accent (see ACCENT above)
            _FluWindow = FluLib:MakeGui({ NameHub = cfg.Name or "Hub", Description = cfg.LoadingSubtitle or "", Color = col })
            -- Flip Fluriore's dark theme to white + strong black, and keep new elements recolored.
            pcall(function() watchGui(CoreGuiSvc:FindFirstChild("HirimiGui")) end)
            pcall(function()
                local nb = CoreGuiSvc:FindFirstChild("NotifyGui")
                if nb then watchGui(nb) end
                CoreGuiSvc.ChildAdded:Connect(function(ch)
                    if ch and ch.Name == "NotifyGui" then task.defer(watchGui, ch) end
                end)
            end)
            -- MOBILE FIX: stop invisible full-screen frames from eating touch input (blocks joystick/movement)
            task.defer(function()
                task.wait(1)
                local function unblockMobile(gui)
                    if not gui then return end
                    for _, d in ipairs(gui:GetDescendants()) do
                        pcall(function()
                            if d:IsA("Frame") and d.Active then
                                local sz = d.AbsoluteSize
                                if sz.X > 400 and sz.Y > 300 and d.BackgroundTransparency > 0.8 then
                                    local hasButtons = false
                                    for _, c in ipairs(d:GetChildren()) do
                                        if c:IsA("TextButton") or c:IsA("ImageButton") then
                                            hasButtons = true; break
                                        end
                                    end
                                    if not hasButtons then d.Active = false end
                                end
                            end
                        end)
                    end
                end
                pcall(function() unblockMobile(CoreGuiSvc:FindFirstChild("HirimiGui")) end)
                -- Re-apply if Fluriore adds new frames later
                pcall(function()
                    local hg = CoreGuiSvc:FindFirstChild("HirimiGui")
                    if hg then hg.DescendantAdded:Connect(function(d)
                        task.defer(function()
                            pcall(function()
                                if d:IsA("Frame") and d.Active and d.AbsoluteSize.X > 400 and d.AbsoluteSize.Y > 300 and d.BackgroundTransparency > 0.8 then
                                    local hasButtons = false
                                    for _, c in ipairs(d:GetChildren()) do
                                        if c:IsA("TextButton") or c:IsA("ImageButton") then hasButtons = true; break end
                                    end
                                    if not hasButtons then d.Active = false end
                                end
                            end)
                        end)
                    end) end
                end)
            end)
            local W = {}
            function W:CreateTab(name, icon)
                local flTab = _FluWindow:CreateTab({ Name = name, Icon = ICONS[icon] or TAB_ICON })
                local T, cur = {}, nil
                local function sec() if not cur then cur = flTab:AddSection("General") end return cur end
                function T:CreateSection(nm) cur = flTab:AddSection(nm or "Section"); return T end
                function T:CreateParagraph(c) c=c or {}; pcall(function() sec():AddParagraph({ Title=c.Title or "", Content=c.Content or "" }) end); return {} end
                function T:CreateButton(c) c=c or {}; pcall(function() sec():AddButton({ Title=c.Name or "Button", Content="", Callback=c.Callback or function() end }) end); return {} end
                function T:CreateToggle(c) c=c or {}; pcall(function() sec():AddToggle({ Title=c.Name or "Toggle", Content="", Default=c.CurrentValue and true or false, Callback=c.Callback or function() end }) end); return { Set=function() end } end
                function T:CreateSlider(c)
                    c=c or {}; local r=c.Range or {0,100}
                    pcall(function() sec():AddSlider({ Title=c.Name or "Slider", Content=c.Suffix or "", Min=r[1] or 0, Max=r[2] or 100, Increment=c.Increment or 1, Default=c.CurrentValue or r[1] or 0, Callback=c.Callback or function() end }) end)
                    return { Set=function() end }
                end
                function T:CreateInput(c)
                    c=c or {}
                    pcall(function() sec():AddInput({ Title=c.Name or "Input", Content=c.PlaceholderText or "", Callback=c.Callback or function() end }) end)
                    return { Set=function() end }
                end
                function T:CreateColorPicker(c)
                    -- Fluriore has no color picker -> expose an "r,g,b" input that feeds the callback a Color3
                    c=c or {}
                    pcall(function() sec():AddInput({ Title=(c.Name or "Color").." (type r,g,b)", Content="e.g. 255,40,40", Callback=function(txt)
                        local r,g,b = tostring(txt):match("(%d+)%D+(%d+)%D+(%d+)")
                        if r and c.Callback then pcall(c.Callback, Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))) end
                    end }) end)
                    return { Set=function() end }
                end
                function T:CreateDropdown(c)
                    c=c or {}; local el
                    pcall(function() el = sec():AddDropdown({ Title=c.Name or "Dropdown", Content="", Multi=c.MultipleOptions and true or false, Options=arr(c.Options), Default=asTable(c.CurrentOption), Callback=c.Callback or function() end }) end)
                    return {
                        Refresh = function(_, newOpts) if el and type(el.Refresh)=="function" then pcall(function() el:Refresh(arr(newOpts)) end) end end,
                        Set = function() end,
                    }
                end
                return T
            end
            return W
        end
        Rayfield = shim
    else
        -- Fluriore unavailable → full Rayfield so every tab + feature still loads
        Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
    end
end

local Players             = game:GetService("Players")
local RS                  = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService         = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ============================================================
-- SETTINGS (must be defined BEFORE any function that reads it)
-- ============================================================
local S = {
    AntiRagdoll=false, AntiPush=false, AntiVoid=false,
    SaveHealth=false, SaveHealthPct=35, SaveHealthHeight=700,
    RemoveWaterBorder=false, AntiKillBricks=false,
    M1Hitbox=false, M1HitboxSize=80,   -- 80 default: long spear-arm reach (arms = slider*1.5 forward, thin sides)
    HitboxAbility=false, HitboxAbilitySize=40, HitboxAllParts=false, HitboxVisible=true,
    OnePunch=false, OnePunchHits=5, OnePunchGuid="",   -- One Punch: VALIDATED M1s (0.35s cadence) so the server accepts each
    FlingPunch=false, FlingRange=40, FlingPower=850,   -- fling: push the ENEMY up+away (you never move = can't die)
    M1Warp=false, M1WarpRange=60, M1WarpReturn=true,   -- M1 Warp: snap behind the nearest enemy for the swing, then back
    AutoM1=false,
    AutoAbility=false, AutoAbilityRange=25,
    CastE=true, CastQ=false, CastR=false, CastT=false,
    DashBehind=false, DashRange=45,
    AutoDash=false, AutoDashKey="Q", AutoDashDelay=0.6,
    CamLock=false, CamLockRange=120,
    AimAssist=false, AimAssistRange=140, AimAssistLead=0.12, AimStrong=false, AimSmooth=0.35, AimOnM1=true,
    Fly=false, FlySpeed=60,
    Noclip=false,
    SpeedHack=false, Speed=16,
    InfiniteJump=false,
    SpinBot=false, AntiFling=false, GodMode=false,
    ESP=false, ESPColor=true, Tracers=false, ESPBox=false, ESPAbility=true, ESPMaxDist=0,
    Viewing=nil, ViewTarget=nil,
    EnemyHighlight=false, HighlightColor="Bright blue",
    FullBright=false,
    AutoFarm=false, FarmTarget=nil, AuraRange=60,
    AutoPlay=false, AutoPlayRange=100,
    AntiAFK=false, InstantRespawn=false, ClickTP=false,
    GrabDelay=3, GrabReturn=true, M1Spy=false,
    VFXOn=false, VFXShape="Ball", VFXShapeOn=true, VFXColor=Color3.fromRGB(255,40,40), VFXColor2=Color3.fromRGB(255,180,40),
    VFXSize=6, VFXTransparency=0.4, VFXParticles=true, VFXTexture="Sparkles", VFXRate=80, VFXSpeed=6, VFXSpread=180, VFXPSize=1.2,
    VFXRainbow=false, VFXLight=true, VFXBrightness=5, VFXRings=false, VFXRingCount=2, VFXSpin=2, VFXBeams=false, VFXTrail=true,
    TPTarget=nil,
}

local function getChar() return LP.Character end
local function getHum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()
    local c=LP.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end

-- This game's player characters live in Workspace named by username, each with a
-- custom "Hitbox" part and a "Health" script - MANY HAVE NO STANDARD HUMANOID.
-- Targeting must NOT require a Humanoid (that is exactly why Kill Aura found
-- nobody). charPart() returns the best part to aim at; isAlive() never excludes
-- a player just because we cannot read a Humanoid.
local function charPart(char)
    if not char then return nil end
    local hb = char:FindFirstChild("Hitbox")
    if hb then
        if hb:IsA("BasePart") then return hb end
        if hb:IsA("Model")    then return hb.PrimaryPart or hb:FindFirstChildWhichIsA("BasePart") end
    end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
end
local function isAlive(char)
    if not char then return false end
    if not char.Parent then return false end
    -- Bug 10: explicit death markers first (custom-health corpses were staying "alive" = cyan ghosts forever)
    if char:GetAttribute("Dead") == true or char:FindFirstChild("Dead") then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then return h.Health > 0 end
    local hp = char:GetAttribute("Health")
    if type(hp) == "number" then return hp > 0 end
    return true -- custom health we cannot read -> assume alive so they stay targetable
end
-- Read a target's CURRENT health from whatever source this game uses (Humanoid, a Health attribute, or a
-- ValueBase named Health). Returns (hp, readable): readable=false means we genuinely can't see their HP.
local function readHealth(char)
    if not char then return 0, false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.MaxHealth > 0 then return h.Health, true end
    local hp = char:GetAttribute("Health")
    if type(hp) == "number" then return hp, true end
    local hv = char:FindFirstChild("Health")
    if hv and hv:IsA("ValueBase") and type(hv.Value) == "number" then return hv.Value, true end
    if hv then for _, v in ipairs(hv:GetDescendants()) do if v:IsA("ValueBase") and type(v.Value) == "number" then return v.Value, true end end end
    return 0, false
end
-- Tiny on-screen readout so One Punch / Fling SHOW what happened (no F9 needed): target found, hits landed,
-- their HP before -> after, whether they died / were launched. This is how you verify it in-game.
local _cbStatus
local function comboStatus(txt, color)
    pcall(function()
        if not _cbStatus then
            local g = Instance.new("ScreenGui")
            g.Name = "\0"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 99997
            g.Parent = (gethui and gethui()) or game:GetService("CoreGui")
            if not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end
            local l = Instance.new("TextLabel")
            l.AnchorPoint = Vector2.new(0.5, 0); l.Position = UDim2.new(0.5, 0, 0, 96); l.Size = UDim2.fromOffset(460, 30)
            l.BackgroundColor3 = Color3.fromRGB(10, 10, 12); l.BackgroundTransparency = 0.15; l.BorderSizePixel = 0
            l.Font = Enum.Font.GothamBold; l.TextSize = 14; l.TextColor3 = Color3.fromRGB(255, 255, 255); l.Text = ""
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8); l.Parent = g
            _cbStatus = l
        end
        _cbStatus.Text = tostring(txt); _cbStatus.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        _cbStatus.Visible = true
        local mine = txt
        task.delay(3, function() if _cbStatus and _cbStatus.Text == mine then _cbStatus.Visible = false end end)
    end)
end

-- A safe MAP SPAWN to land on (workspace.GameMap.Spawns = invisible neon Parts).
-- Used to return you to the map after grabbing an ability so you don't get
-- stranded in the lobby / ability area and die.

-- ============================================================
-- REMOTE LAYER (Jolt_Reliable wants BUFFERS, not strings)
-- ============================================================
local JoltReliable
pcall(function()
    JoltReliable = RS:WaitForChild("Files",10)
        :WaitForChild("Shared"):WaitForChild("Components")
        :WaitForChild("Jolt"):WaitForChild("Utils")
        :WaitForChild("Remotes"):WaitForChild("Jolt_Reliable")
end)

local CAN_BUFFER = (type(buffer) == "table" and type(buffer.fromstring) == "function")
local function toWire(s)
    if CAN_BUFFER then
        local ok, b = pcall(buffer.fromstring, s)
        if ok then return b end
    end
    return s
end
local function fireRaw(payload)
    if not JoltReliable then return end
    pcall(function() JoltReliable:FireServer(toWire(payload), {}) end)
end

local function nowStamp()
    local t = 0
    pcall(function() t = Workspace:GetServerTimeNow() end)
    if t == 0 then pcall(function() t = os.clock() end) end
    return string.pack("<d", t)
end

-- M1 packet. NOTE: old version had a stray byte (199) glued to the timestamp
-- marker which corrupted every M1 - removed. Timestamp is exactly 8 bytes.
local M1_HEAD = string.char(5).."UseM1"..string.char(65,16,3,9).."Timestamp"..string.char(2)
local M1_TAIL = string.char(3,5).."Index"..string.char(17,32,3,4).."Hits"..string.char(16,0,0)
local function buildM1() return M1_HEAD .. nowStamp() .. M1_TAIL end

-- StartSkill packet, NEW format (taken from the One Shot Punch capture):
-- \10 StartSkill \131\17\0 \3 <len><name> \16\3 \9 Timestamp \2 <8-byte time> \0
local SK_HEAD = string.char(10).."StartSkill"..string.char(131,17,0,3)
local SK_MID  = string.char(16,3,9).."Timestamp"..string.char(2)
local function buildSkillNew(name)
    return SK_HEAD .. string.char(#name) .. name .. SK_MID .. nowStamp() .. string.char(0)
end

-- legacy StartSkill format (kept as a fallback for direction skills like Dash)
local function buildSkillOld(skill, direction)
    direction = direction or "Forward"
    return string.char(10).."StartSkillB"..string.char(3)..string.char(#skill)..skill
        ..string.char(16,3,9).."Direction"..string.char(3)..string.char(#direction)..direction
        ..string.char(3,9).."Timestamp"..string.char(2)..nowStamp()..string.char(0)
end
-- new format + a Direction field (best guess for dash on the new schema)
local function buildSkillNewDir(skill, direction)
    direction = direction or "Forward"
    return SK_HEAD .. string.char(#skill) .. skill
        ..string.char(16,3,9).."Direction"..string.char(3)..string.char(#direction)..direction
        ..string.char(3,9).."Timestamp"..string.char(2)..nowStamp()..string.char(0)
end

-- DISABLED: firing this hand-crafted raw M1 packet at the Jolt remote is what got you KICKED
-- the moment Auto M1 turned on (the server rejects/flags the crafted packet), and it dealt no
-- damage anyway (empty "Hits" list). The auto features now rely ONLY on the legit
-- VirtualInputManager click, which drives the game's own real M1 (no kick).
local function fireM1() end

-- ── M1 PACKET SPY (debug) ──────────────────────────────────────
-- REMOVED: this used hookmetamethod(game,"__namecall",...). Ability Arena's anti-cheat has a
-- "namecallInstance detector" that spots a hooked __namecall metamethod and 267-kicks you — and
-- the old hook was NEVER uninstalled (toggling the feature off left the hook in place forever), so
-- one use bricked every future session. It was only ever a debug capture tool, so we drop the hook
-- entirely. If a raw remote logger is ever needed again, do it without touching the namecall
-- metamethod (e.g. a per-remote OutgoingReplication signal), never a global __namecall hook.
local function installM1Spy() return false end
local function fireSkill(skill) fireRaw(buildSkillNew(skill)) end
local function fireDash(direction)
    fireRaw(buildSkillNewDir("Dash", direction))
    fireRaw(buildSkillOld("Dash", direction))
end

-- ============================================================
-- CLICKING (real M1s come from real clicks)
-- ============================================================
local function typingNow()
    local ok, box = pcall(function() return UserInputService:GetFocusedTextBox() end)
    return ok and box ~= nil
end

local function safeClickPoint()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local candidates = {
        Vector2.new(vp.X*0.50, vp.Y*0.62),
        Vector2.new(vp.X*0.50, vp.Y*0.50),
        Vector2.new(vp.X*0.35, vp.Y*0.55),
        Vector2.new(vp.X*0.65, vp.Y*0.55),
        Vector2.new(vp.X*0.50, vp.Y*0.40),
        Vector2.new(vp.X*0.25, vp.Y*0.70),
        Vector2.new(vp.X*0.75, vp.Y*0.70),
        Vector2.new(vp.X*0.50, vp.Y*0.78),
        Vector2.new(vp.X*0.40, vp.Y*0.35),
        Vector2.new(vp.X*0.60, vp.Y*0.35),
    }
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return candidates[1] end
    for _, pt in ipairs(candidates) do
        local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(pt.X, pt.Y) end)
        if ok and objs and #objs == 0 then return pt end
    end
    return nil -- every candidate is under the menu: skip rather than click the menu
end

local vimClickUntil = 0   -- injection marker: OUR OWN VIM clicks must not re-trigger the click-combat hooks (warp->click->warp = infinite loop)
local function doClick(pt)
    if not pt then return end
    vimClickUntil = tick() + 0.15
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, true,  game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, false, game, 0)
    end)
end

-- true when the user's REAL cursor is over a GUI (the Rayfield menu etc.). The
-- auto-clicker skips clicking then, so hovering the menu never fires a click.
local function mouseOverGui()
    local m = LP:GetMouse(); if not m then return false end
    local conts = {}
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if pg then conts[#conts+1] = pg end
    pcall(function() if gethui then conts[#conts+1] = gethui() end end)
    pcall(function() conts[#conts+1] = game:GetService("CoreGui") end)
    for _,c in ipairs(conts) do
        local ok, objs = pcall(function() return c:GetGuiObjectsAtPosition(m.X, m.Y) end)
        if ok and objs and #objs > 0 then return true end
    end
    return false
end

local function clickM1(force)
    if typingNow() then return end
    if not force and mouseOverGui() then return end
    doClick(safeClickPoint())
end

local function clickAtTarget(target, force)
    if typingNow() then return end
    if not force and mouseOverGui() then return end
    local char = target and target.Character
    local tr   = char and charPart(char)
    if not tr then doClick(safeClickPoint()); return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local sp, onScreen = cam:WorldToViewportPoint(tr.Position)
    local pt = onScreen and Vector2.new(sp.X, sp.Y) or nil
    if pt then
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        if pg then
            local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(pt.X, pt.Y) end)
            if ok and objs and #objs > 0 then pt = nil end
        end
    end
    doClick(pt or safeClickPoint())
end

local function tapKey(kc)
    if typingNow() then return end
    pcall(function() VirtualInputManager:SendKeyEvent(true,  kc, false, game) end)
    task.wait(0.06)
    pcall(function() VirtualInputManager:SendKeyEvent(false, kc, false, game) end)
end

local Conns = {}
local function bind(name, conn)
    if Conns[name] then pcall(function() Conns[name]:Disconnect() end) end
    Conns[name] = conn
end

-- Track every top-level event connection so Unload can fully disconnect them.
local Listeners = {}
local function hook(sig, fn) local c = sig:Connect(fn); Listeners[#Listeners+1] = c; return c end

-- ============================================================
-- TARGET HELPERS
-- ============================================================
local function enemiesInRange(range)
    local out, root = {}, getRoot()
    if not root then return out end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then
            local r = charPart(p.Character)
            if r and (r.Position-root.Position).Magnitude <= range then
                out[#out+1] = p
            end
        end
    end
    return out
end
local function nearestPlayer(range)
    local best, dist, root = nil, range or math.huge, getRoot()
    if not root then return nil end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then
            local r = charPart(p.Character)
            if r then
                local d = (r.Position-root.Position).Magnitude
                if d < dist then best, dist = p, d end
            end
        end
    end
    return best
end
local function playerNames()
    local n = {}
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then n[#n+1] = p.Name end end
    return n
end
local function faceTo(pos)
    local root = getRoot()
    if root then root.CFrame = CFrame.new(root.Position, Vector3.new(pos.X, root.Position.Y, pos.Z)) end
end
local function faceToSmooth(pos, alpha)   -- gentle continuous turn (no hard snap) for the "hold on target" aim
    local root = getRoot(); if not root then return end
    local goal = CFrame.new(root.Position, Vector3.new(pos.X, root.Position.Y, pos.Z))
    root.CFrame = root.CFrame:Lerp(goal, math.clamp(alpha or 0.3, 0.05, 1))
end

-- ============================================================
-- HITBOX EXPANDERS (M1 + Ability). This game does CLIENT-SIDE hit
-- detection (the M1 packet carries a "Hits" list), so growing the
-- ENEMY hitbox on your client lets your real M1s + abilities reach
-- them from much farther. Both expanders grow the enemy "Hitbox"
-- part (+ HumanoidRootPart). Ability pulses 1.5x bigger on E. The
-- enlarged hitbox is shown faint-red so you can SEE the reach.
-- Targets via isAlive() (NOT a Humanoid - this game's chars lack one).
-- ============================================================
local hbOriginal = {}   -- keyed by the BasePart instance -> original props
local abilityBurstUntil = 0
local function restoreHitboxes()
    for part, orig in pairs(hbOriginal) do
        if part and part.Parent then pcall(function()
            part.Size = orig.size; part.Transparency = orig.transp
            part.CanCollide = orig.collide; part.Massless = orig.massless
            part.CanTouch = orig.touch; part.CanQuery = orig.query
            part.Color = orig.color; part.Material = orig.material
            if orig.shape ~= nil and part:IsA("Part") then part.Shape = orig.shape end
        end) end
    end
    hbOriginal = {}
end

local punchGrowUntil = 0   -- One Punch sets this while bursting: forces BOTH grow paths on for guaranteed hit-reg
local function wantedHitboxSize()
    local sz = 0
    -- M1 Expand Hitbox grows the ENEMY hitbox (this is what actually lands the M1 — the game reads the overlap
    -- client-side) AND your arms. The enemy grow is now INVISIBLE (no red boxes on everyone — the old complaint).
    if S.M1Hitbox or tick() < punchGrowUntil then sz = math.max(sz, S.M1HitboxSize) end   -- Auto Farm/Play TP onto the target instead; One Punch forces this on during its burst
    if S.HitboxAbility then
        local a = S.HitboxAbilitySize
        if tick() < abilityBurstUntil then a = a * 1.5 end
        sz = math.max(sz, a)
    end
    return sz
end

-- Parts to grow on an enemy. Fixes the old bug where a Model "Hitbox" was
-- skipped entirely (only direct BaseParts were grown). Optionally grows EVERY
-- BasePart in the character for maximum reach.
local function hitboxParts(char)
    local out = {}
    -- Check every case/name variant of the hit container (FindFirstChild is case-sensitive, so "Hitbox" and
    -- "HitBox" are DIFFERENT lookups — missing a variant is why some enemies never grew). Ported from PE's
    -- working hitbox, which checks all of these.
    for _, nm in ipairs({ "Hitbox", "HitBox", "HitboxPart", "Hit" }) do
        local hb = char:FindFirstChild(nm)
        if hb then
            if hb:IsA("BasePart") then out[#out+1] = hb
            elseif hb:IsA("Model") or hb:IsA("Folder") or hb:IsA("Configuration") then   -- Bug 11: also dig Folder/Configuration containers
                for _,d in ipairs(hb:GetDescendants()) do if d:IsA("BasePart") then out[#out+1] = d end end
            end
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then out[#out+1] = hrp end
    -- ONLY the dedicated hit parts (Hitbox/HRP) — these are invisible parts the game's M1 query reads.
    -- We used to ALSO grow Head/Torso/arms/legs and hide them, but those ARE the person's visible body:
    -- growing+hiding them made every enemy an invisible giant ("I can't see people") with a huge dark
    -- blob on screen. The Hitbox part is what registers hits; the body adds nothing but blindness.
    return out
end
-- Every enemy character to grow: players AND non-player models under workspace.Characters (training dummies /
-- NPCs have no Player, so the players-only loop skipped them = "hitbox doesn't work on dummies"). PE scans the
-- same way. Excludes YOU.
local function hitboxTargets()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then out[#out+1] = p.Character end
    end
    local chars = Workspace:FindFirstChild("Characters")
    if chars then
        for _, m in ipairs(chars:GetChildren()) do
            if m:IsA("Model") and m.Name ~= LP.Name and not Players:FindFirstChild(m.Name) and isAlive(m) then out[#out+1] = m end
        end
    end
    return out
end

-- ============================================================
-- ARM EXPANDER (Ability Arena's real fix). This game validates M1s server-side and the UseM1A packet carries
-- encoded per-hit data (target id + hit position) we can't forge — BUT the game builds that packet itself from
-- its own client-side detection off YOUR ARMS. So instead of (only) growing the enemy hitbox, we grow YOUR
-- Left/Right Arm parts: the native detector then reaches far enemies and fires the correct UseM1A for us.
-- We also clear YOUR HitLog (workspace.<You>.HitLog) so repeated swings keep landing on the same target.
-- ============================================================
-- Ability Arena uses CLIENT-SIDE hit registration (your client runs a GetPartBoundsInBox query off your REAL
-- arm parts + their velocity, then sends the hit list to the server which trusts it). The old anchored
-- MH_ArmReach follower parts failed for two reasons: (1) anchored parts get 0 AssemblyLinearVelocity in Jolt,
-- so the game thought you weren't swinging and skipped detection; (2) the game only scans parts NAMED like real
-- arms, not "MH_ArmReach". So we now resize the REAL arms. To stop Jolt flinging/resetting you (giant parts
-- overlapping your torso/floor), we drop the arms into a collision group that collides with NOTHING, and keep
-- CanCollide off + Massless on. CanQuery/CanTouch stay TRUE so the game's spatial query still registers the hit.
local PhysicsService = game:GetService("PhysicsService")
local HITBOX_GROUP = "MH_M1NoCollide"
pcall(function() PhysicsService:RegisterCollisionGroup(HITBOX_GROUP) end)
local function sweepCollisionGroups()   -- make our group collide with NOTHING (every registered group)
    pcall(function()
        PhysicsService:CollisionGroupSetCollidable(HITBOX_GROUP, "Default", false)
        for _,g in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
            pcall(function() PhysicsService:CollisionGroupSetCollidable(HITBOX_GROUP, g.name, false) end)
        end
    end)
end
sweepCollisionGroups()
-- Bug 6: groups registered AFTER load (Projectiles/Abilities/DamageZones) would collide with our arms and
-- fling/reset us. Re-sweep every 5s so newly-added groups are always made non-collidable.
task.spawn(function() while true do task.wait(5); sweepCollisionGroups() end end)

local realArmOriginals = {}   -- real arm part -> {size, group, collide, massless, query, touch}
-- FORWARD PUSH: the arms are shoved out in front of you through the SHOULDER JOINT (Motor6D.C0), never by
-- setting arm.CFrame — a welded limb's CFrame moves the WHOLE character, so that "offset" would rocket you
-- across the map every frame. C0 shifts only the limb, relative to the torso, and animations still play.
local armC0 = {}              -- Motor6D -> original C0
local function armMotor(arm)
    local char = LP.Character; if not char then return nil end
    for _,j in ipairs(char:GetDescendants()) do
        if j:IsA("Motor6D") and j.Part1 == arm then return j end
    end
end
local function restoreArms()
    for m, c0 in pairs(armC0) do pcall(function() if m and m.Parent then m.C0 = c0 end end) end
    armC0 = {}
    for arm, o in pairs(realArmOriginals) do
        if arm and arm.Parent then
            pcall(function()
                arm.Size = o.size
                pcall(function() arm.CollisionGroup = o.group end)
                arm.CanCollide = o.collide
                arm.Massless = o.massless
                arm.CanQuery = o.query
                arm.CanTouch = o.touch
                arm.LocalTransparencyModifier = 0
            end)
        end
    end
    realArmOriginals = {}
end
-- Bug 3: grow ONLY the OUTERMOST arm part (R15 Hand, else R6 Arm) — growing the whole UpperArm->LowerArm->Hand
-- chain and offsetting each joint makes an impossible kinematic chain that Jolt rejects/flings.
local function myArmParts()
    local out = {}
    local char = LP.Character
    if not char then return out end
    for _, nm in ipairs({ "LeftHand","RightHand" }) do   -- R15 outermost first
        local a = char:FindFirstChild(nm); if a and a:IsA("BasePart") then out[#out+1] = a end
    end
    if #out == 0 then   -- R6 fallback: the Arm parts ARE the outermost
        for _, nm in ipairs({ "Left Arm","Right Arm","LeftArm","RightArm" }) do
            local a = char:FindFirstChild(nm); if a and a:IsA("BasePart") then out[#out+1] = a end
        end
    end
    return out
end
-- Bug 7: clear your HitLog only at the START of a swing (on M1 click), not every frame. Clearing 60x/sec
-- made you re-hit the same target every frame (some servers flag that as too-fast repeat hits = kick).
local function clearMyHitLog()
    pcall(function()
        local mine = Workspace:FindFirstChild(LP.Name)
        local log = mine and mine:FindFirstChild("HitLog")
        if log then for _,c in ipairs(log:GetChildren()) do c:Destroy() end end
    end)
end
-- NOTE (the "nothing fires on click" bug): this game binds M1 through its own input system, so every
-- click arrives with gameProcessedEvent=true. Bailing on gpe killed EVERY click-triggered feature
-- (Dash Behind / M1 Warp / Fling / One Punch). None of these bail on gpe anymore — they use
-- typingNow() + mouseOverGui() instead, which is the correct guard pair.
-- ONE swing dispatcher, shared by the desktop click hook AND the mobile M1 button (so every click-combat
-- feature works on phone too). Forward-declared here; the fling/one-punch bodies are filled in once their
-- helpers exist further down.
local doFlingPunch, doOnePunch   -- assigned after contactFling / firePunchOnce are defined
local function doGodModeM1()
    task.spawn(function()
        local target = nearestPlayer(S.M1HitboxSize or 80)
        if not (target and target.Character) then return end
        local tr = charPart(target.Character)
        local root = getRoot()
        if not (tr and root) then return end
        local savedCF = root.CFrame
        pcall(function() root.CFrame = tr.CFrame * CFrame.new(0, 0, 3) end)
        task.wait(0.05)
        if S.CastE then tapKey(Enum.KeyCode.E) end
        if S.CastQ then tapKey(Enum.KeyCode.Q) end
        if S.CastR then tapKey(Enum.KeyCode.R) end
        if S.CastT then tapKey(Enum.KeyCode.T) end
        task.wait(0.2)
        pcall(function() root.CFrame = savedCF; root.AssemblyLinearVelocity = Vector3.zero end)
    end)
end
local function doM1Warp()
    task.spawn(function()
        local root = getRoot(); if not root then return end
        local target = nearestPlayer(S.M1WarpRange or 60)
        if not target or not target.Character then return end
        local savedCF = root.CFrame
        clearMyHitLog()
        local t0 = tick(); local clicked = false
        while tick() - t0 < 0.18 do
            local r = getRoot()
            local tr = target.Character and target.Character.Parent and charPart(target.Character)
            if not (r and tr) then break end
            pcall(function()
                local behind = tr.Position - tr.CFrame.LookVector * 2   -- dead on their back, point-blank
                r.CFrame = CFrame.new(behind, tr.Position)              -- facing them = the swing lands
                r.AssemblyLinearVelocity = Vector3.zero
            end)
            if not clicked then clicked = true; clickM1(true) end       -- swing the instant you arrive
            RunService.Heartbeat:Wait()
        end
        if S.M1WarpReturn then local r = getRoot(); if r then pcall(function() r.CFrame = savedCF; r.AssemblyLinearVelocity = Vector3.zero end) end end
    end)
end
local function doDashBehind()
    task.spawn(function()
        local root = getRoot(); if not root then return end
        local target = nearestPlayer(S.DashRange or 45)
        if not target or not target.Character then return end
        local tr = charPart(target.Character); if not tr then return end
        local savedCF = root.CFrame
        pcall(function() root.CFrame = tr.CFrame * CFrame.new(0, 0, 3) end)
        task.wait(0.03); clearMyHitLog(); clickM1(true); task.wait(0.06)
        fireDash("Forward"); tapKey(Enum.KeyCode.Q); task.wait(0.15)
        pcall(function() root.CFrame = savedCF end)
    end)
end
local function runSwingFeatures(mobileBaseClick)
    if S.M1Hitbox or S.AutoFarm or S.AutoPlay then clearMyHitLog() end
    -- ALWAYS fire a normal M1 click immediately (so the swing animation always plays)
    local warpOrGod = S.M1Warp or S.DashBehind or S.GodMode
    if not warpOrGod then
        clearMyHitLog()
        clickM1()
    end
    -- Then layer on the teleport / ability features
    if S.GodMode then doGodModeM1() end
    if S.M1Warp then doM1Warp()
    elseif S.DashBehind then doDashBehind() end
    if S.FlingPunch and doFlingPunch then doFlingPunch() end
    if S.OnePunch and doOnePunch then doOnePunch() end
    -- mobile tap: land base swing when no warp/god already did
    if mobileBaseClick and not warpOrGod then clearMyHitLog(); clickM1(true) end
end
_G.AA_SWING = runSwingFeatures   -- exposed so the mobile M1 button can call it
hook(UserInputService.InputBegan, function(i, _)
    if typingNow() then return end
    if tick() < vimClickUntil then return end   -- skip our own injected clicks (stops warp->click->warp recursion)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        runSwingFeatures(false)
    end
end)

-- ============================================================
-- ONE PUNCH — CAST THE GAME'S OWN ABILITY. Screenshot: "One Punch" is a real ability at
-- ReplicatedStorage.Files.Shared.Core.Abilities["One Punch"]. The GAME already flings people with it
-- server-side, so forging M1/velocity packets was the wrong path entirely — we just fire ITS StartSkill
-- packet on each click. That's the exact wire the game itself sends, so the server runs the real fling.
-- You must OWN / have One Punch equipped (use the Skills tab "Get Ability" on "One Punch" first). The
-- ability name is overridable via the textbox in case the game renames it.
-- ============================================================
local function punchAbilityName()
    local n = tostring(S.OnePunchGuid or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return (n ~= "") and n or "One Punch"
end
-- Direct remote path too (belt-and-suspenders): the ability's own "One Punch" RemoteEvent, fired with no
-- args, exactly as the game's ability module would. Cached; resolves lazily.
local punchRemote
local function resolvePunchRemote()
    if punchRemote and punchRemote.Parent then return punchRemote end
    punchRemote = nil
    pcall(function()
        local ab = RS:FindFirstChild("Files"); ab = ab and ab:FindFirstChild("Shared")
        ab = ab and ab:FindFirstChild("Core"); ab = ab and ab:FindFirstChild("Abilities")
        local op = ab and ab:FindFirstChild(punchAbilityName())
        if op then
            local re = op:FindFirstChild(punchAbilityName()) or op:FindFirstChildWhichIsA("RemoteEvent") or op:FindFirstChildWhichIsA("RemoteFunction")
            if re and (re:IsA("RemoteEvent") or re:IsA("RemoteFunction")) then punchRemote = re end
        end
    end)
    return punchRemote
end
-- Fire the game's One Punch ABILITY through every known path. NO movement here (movement is done once,
-- cleanly, in doOnePunch) so repeated calls can't fight over your CFrame.
local function firePunchOnce()
    local name = punchAbilityName()
    fireRaw(buildSkillNew(name))
    fireRaw(buildSkillOld(name, "Forward"))
    fireRaw(buildSkillNewDir(name, "Forward"))
    local re = resolvePunchRemote()
    if re then
        pcall(function()
            if re:IsA("RemoteEvent") then re:FireServer() else re:InvokeServer() end
        end)
    end
    pcall(function()
        local ab = RS:FindFirstChild("Files")
        ab = ab and ab:FindFirstChild("Shared")
        ab = ab and ab:FindFirstChild("Core")
        ab = ab and ab:FindFirstChild("Abilities")
        local op = ab and ab:FindFirstChild(name)
        if op then
            for _, d in ipairs(op:GetDescendants()) do
                if d:IsA("RemoteEvent") then pcall(function() d:FireServer() end)
                elseif d:IsA("RemoteFunction") then pcall(function() d:InvokeServer() end) end
            end
        end
    end)
end
local onePunchCD = 0
local onePunchBusy = false
doOnePunch = function()   -- assigned to the forward-declared local used by runSwingFeatures
    if tick() - onePunchCD < 0.35 or onePunchBusy then return end
    onePunchCD = tick(); onePunchBusy = true
    task.spawn(function()
        pcall(function()
            local target = nearestPlayer(100)
            if not (target and target.Character) then comboStatus("One Punch: no target in range", Color3.fromRGB(235,180,70)); firePunchOnce(); return end
            local tr = charPart(target.Character); local root = getRoot()
            if not (tr and root) then firePunchOnce(); return end
            local hp0, canRead = readHealth(target.Character)
            -- POINT-BLANK KILL (expert diagnostic): NO teleporting (a 4-stud CFrame delta trips Jolt anti-teleport
            -- = the server validates your M1 from your OLD position = 0 damage). NO 200-stud hitbox (it breaks
            -- Jolt's broadphase = the query MISSES). NO client health edits (fake ghost only). Instead: stay put,
            -- grow YOUR ARMS across the map (the M1Hitbox path, which overlaps their NORMAL uncorrupted hitbox),
            -- give their hit parts a reasonable 60-stud CanCollide=false bump, and swing at the real 0.4s cadence
            -- so the server accepts 100% of the hits. 3 validated hits >> 10 rejected spam hits.
            firePunchOnce()               -- fire the One Punch ability packet (if owned)
            punchGrowUntil = tick() + 4   -- grow YOUR arms across the map = they overlap the enemy in place, no teleport
            local parts = hitboxParts(target.Character)
            local origSizes = {}
            for _, p in ipairs(parts) do
                pcall(function()
                    origSizes[p] = p.Size
                    p.Size = Vector3.new(60, 60, 60)   -- reasonable: doesn't break Jolt's broadphase
                    p.Transparency = 1                  -- invisible
                    p.CanCollide = false                -- stops Jolt from flinging / breaking their character
                end)
            end
            -- face them so your grown arms sweep across their hitbox, but DO NOT move your position
            pcall(function() root.CFrame = CFrame.new(root.Position, Vector3.new(tr.Position.X, root.Position.Y, tr.Position.Z)) end)
            local hits = math.clamp(tonumber(S.OnePunchHits) or 3, 1, 5)
            for _ = 1, hits do
                local c2 = target.Character
                if not (c2 and c2.Parent and isAlive(c2)) then break end
                clearMyHitLog()
                clickAtTarget(target, true)   -- proven farm-damage click, aimed at the enemy (from where you STAND)
                task.wait(0.4)                -- STRICT server swing cooldown = every hit is validated
            end
            punchGrowUntil = 0
            for p, sz in pairs(origSizes) do pcall(function() if p and p.Parent then p.Size = sz; p.Transparency = 0; p.CanCollide = true end end) end
            local hp1 = readHealth(target.Character)
            if not (target.Character and target.Character.Parent) or not isAlive(target.Character) then
                comboStatus("One Punch: KILLED " .. target.Name, Color3.fromRGB(90,235,120))
            elseif canRead then
                comboStatus(("One Punch: %s  HP %d -> %d  (%d hits)"):format(target.Name, math.floor(hp0), math.floor(hp1), hits),
                    (hp1 < hp0) and Color3.fromRGB(120,220,255) or Color3.fromRGB(235,90,90))
            else
                comboStatus("One Punch: " .. hits .. " hits on " .. target.Name .. " (HP not readable)", Color3.fromRGB(200,200,210))
            end
        end)
        onePunchBusy = false
    end)
end

-- ============================================================
-- FLING PUNCH — SAFE VELOCITY PUSH (expert diagnostic). Why every "contact" version failed in THIS engine:
--  1) Jolt collision annihilation: stuffing your root inside their hitbox (even anchored) forces Jolt to
--     resolve a catastrophic overlap every frame; the reaction force reads as massive collision damage on
--     YOU = "the fling kills me".
--  2) Anchor+CFrame deltas in 0.15s trip the server's anti-teleport = reset/damage.
-- So: NEVER move the user. Apply the explosive velocity to the ENEMY from where you stand — Jolt lets a
-- 1-2 frame injection slip through when applied right on a heartbeat. Plus one real M1 to register a hit.
-- ============================================================
local flingBusy = false
local function contactFling(targetChar)
    if flingBusy then return end
    local root = getRoot(); local tr = charPart(targetChar)
    if not (root and tr) then return end
    if (tr.Position - root.Position).Magnitude > (S.FlingRange or 40) then return end
    flingBusy = true
    local startEnemyPos = tr.Position
    task.spawn(function()
        -- DO NOT MOVE THE USER. Stay exactly where you are.
        local dir = (tr.Position - root.Position).Unit
        local power = tonumber(S.FlingPower) or 850
        -- Apply violent velocity to ALL their base parts on this exact frame to overwhelm Jolt's
        -- 1-frame network-ownership bleed before the server reasserts control.
        pcall(function()
            for _, p in ipairs(targetChar:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.AssemblyLinearVelocity = Vector3.new(dir.X * power, power * 1.5, dir.Z * power)
                    p.AssemblyAngularVelocity = Vector3.new(math.random(-2000, 2000), math.random(-2000, 2000), math.random(-2000, 2000))
                end
            end
        end)
        -- Fire M1 since they are in range
        clearMyHitLog()
        clickM1(true)
        task.wait(0.5)
        -- REPORT whether they actually launched (visible on screen, no guessing)
        pcall(function()
            local t2 = targetChar and targetChar.Parent and charPart(targetChar)
            local moved = t2 and (t2.Position - startEnemyPos).Magnitude or 0
            if moved > 12 then comboStatus(("Fling: LAUNCHED (%d studs)"):format(math.floor(moved)), Color3.fromRGB(90,235,120))
            else comboStatus("Fling: did not launch (velocity server-locked)", Color3.fromRGB(235,180,70)) end
        end)
        flingBusy = false
    end)
end
doFlingPunch = function()   -- assigned to the forward-declared local used by runSwingFeatures
    local p = nearestPlayer(S.FlingRange or 40)
    if p and p.Character then contactFling(p.Character)
    else comboStatus("Fling: no target in range", Color3.fromRGB(235,180,70)) end
end

-- (Old standalone M1 Warp hook REMOVED — M1 Warp now lives in the swing-start hook above with the
--  warp -> forced M1 click -> return sequence, so two hooks can't fight over your CFrame on one click.)

local armSpawnT = tick()   -- Bug 4: init to NOW so the 3s grace works even when the script loads mid-game
hook(LP.CharacterAdded, function() armSpawnT = tick() end)
if LP.Character then armSpawnT = tick() end
hook(RunService.Heartbeat, function()
    -- grow YOUR arms whenever M1 reach is wanted (this is the primary Ability-Arena mechanism now)
    local armSz = 0
    if S.M1Hitbox or tick() < punchGrowUntil then armSz = math.max(armSz, S.M1HitboxSize) end   -- One Punch forces the arm grow (the documented working damage path) during its burst
    if tick() - armSpawnT < 3 then armSz = 0 end   -- 3s spawn grace: normal arms while the game places you
    if armSz > 0 then
        -- prune entries whose arm despawned (respawn) so we don't leak / restore onto a dead part
        for arm in pairs(realArmOriginals) do if (not arm) or (not arm.Parent) then realArmOriginals[arm] = nil end end
        for m in pairs(armC0) do if (not m) or (not m.Parent) then armC0[m] = nil end end
        -- ELONGATED SPEAR ARMS (no more 22 cap): the FULL slider drives the forward length (1.5x), while the
        -- side thickness is capped — a fat cube around your own arm engulfed your own hitbox and the game ate
        -- the swing. Long + thin = the reach points AT the enemy and never swallows you.
        local fwdLen = armSz * 1.5
        local side   = math.min(armSz * 0.6, 14)
        local targetSize = Vector3.new(side, side, fwdLen)
        local fwdOff = fwdLen * 0.35   -- how far the shoulder joint shoves the arm out in front of you
        for _,arm in ipairs(myArmParts()) do
            local m = armMotor(arm)   -- Bug 2: only grow an arm we can push forward through its joint; else it
            if m then                 -- would sit at the shoulder engulfing your OWN hitbox (self-hit / no hit).
                local isNew = not realArmOriginals[arm]
                if isNew then
                    realArmOriginals[arm] = { size=arm.Size, group=arm.CollisionGroup, collide=arm.CanCollide, massless=arm.Massless, query=arm.CanQuery, touch=arm.CanTouch }
                    armC0[m] = armC0[m] or m.C0
                end
                pcall(function()
                    pcall(function() arm.CollisionGroup = HITBOX_GROUP end)   -- Jolt: this group hits nothing -> no fling/reset
                    arm.CanCollide = false                                    -- primary fling-guard (works even if the group didn't register)
                    arm.Massless   = true                                     -- no extra mass on the assembly = no catapult
                    arm.CanQuery   = true                                     -- GetPartBoundsInBox reads this (this is what the game uses)
                    arm.CanTouch   = false                                    -- MUST stay false: CanTouch=true let the main-map KILL BRICKS' .Touched fire on your giant arms = death on spawn. Queries don't need Touch.
                    if (arm.Size - targetSize).Magnitude > 0.1 then arm.Size = targetSize end
                    arm.LocalTransparencyModifier = 0.3                       -- clearly visible so you SEE your big arms swing
                    -- Bug 1: refresh the forward push EVERY frame from the ORIGINAL C0, so changing the slider
                    -- actually moves the arm forward (was set once = arm stretched inside itself on slider change).
                    m.C0 = CFrame.new(0, 0, -fwdOff) * armC0[m]
                end)
            end
        end
        -- (Bug 7: per-frame clearMyHitLog removed — the log is now cleared on M1 click / swing start.)
    elseif next(realArmOriginals) then restoreArms() end

    local sz = wantedHitboxSize()
    if sz <= 0 then
        if next(hbOriginal) then restoreHitboxes() end
        return
    end
    -- prune destroyed/removed parts so hbOriginal can't grow without bound
    for part in pairs(hbOriginal) do
        if not part or not part.Parent then hbOriginal[part] = nil end
    end
    local cube = Vector3.new(sz, sz, sz)
    for _,char in ipairs(hitboxTargets()) do
        for _,part in ipairs(hitboxParts(char)) do
            if not hbOriginal[part] then
                hbOriginal[part] = {
                    size=part.Size, transp=part.Transparency,
                    collide=part.CanCollide, massless=part.Massless,
                    touch=part.CanTouch, query=part.CanQuery,
                    color=part.Color, material=part.Material,
                    shape=(part:IsA("Part") and part.Shape or nil)
                }
            end
            local o = hbOriginal[part]
            pcall(function()
                part.Massless    = true
                part.CanCollide  = false
                part.CanQuery    = true                                   -- GetPartBoundsInBox reads this
                part.CanTouch    = (o and o.touch) or false               -- Bug 9: keep the enemy's ORIGINAL CanTouch — forcing true let their Hitbox's touch-damage handler hurt YOU
                -- KEEP the part's original shape (a Ball grown to sz already reaches sz/2 in every direction).
                -- Bug 5: magnitude compare (float drift made == fail = a redundant write every frame).
                if (part.Size - cube).Magnitude > 0.1 then part.Size = cube end
                -- Bug 13: only write the visual props when they actually differ (was 180 writes/frame).
                if S.HitboxVisible ~= false then
                    if part.Transparency ~= 0.82 then part.Transparency = 0.82; part.Color = Color3.fromRGB(0, 220, 255); part.Material = Enum.Material.ForceField end
                elseif o and part.Transparency ~= o.transp then
                    part.Transparency = o.transp; part.Color = o.color; part.Material = o.material
                end
            end)
        end
    end
end)

-- pressing E pulses the Ability expand bigger for a moment
hook(UserInputService.InputBegan, function(i, _)   -- no gpe bail: E is the game's cast key, so it's always game-processed
    if typingNow() then return end
    if i.KeyCode == Enum.KeyCode.E and S.HitboxAbility then
        abilityBurstUntil = tick() + 0.6
    end
end)

-- a faint ball on YOU so you can see your ability reach (visual only)
local abilityHbPart = nil
local function destroyAbilityHb()
    if abilityHbPart then pcall(function() abilityHbPart:Destroy() end); abilityHbPart = nil end
end
task.spawn(function()
    while task.wait(0.2) do
        if S.HitboxAbility then
            local root = getRoot()
            if root then
                if not abilityHbPart or abilityHbPart.Parent == nil then
                    destroyAbilityHb()
                    abilityHbPart = Instance.new("Part")
                    abilityHbPart.Name         = "MFHAbilityHB"
                    abilityHbPart.Shape        = Enum.PartType.Ball
                    abilityHbPart.Anchored     = false
                    abilityHbPart.CanCollide   = false
                    abilityHbPart.Massless     = true
                    abilityHbPart.CastShadow   = false
                    abilityHbPart.CanQuery     = false
                    abilityHbPart.CanTouch     = false
                    abilityHbPart.Transparency = 0.8
                    abilityHbPart.Material     = Enum.Material.ForceField
                    abilityHbPart.Color        = Color3.fromRGB(100, 200, 255)
                    local w = Instance.new("Weld")
                    w.Part0 = root; w.Part1 = abilityHbPart; w.Parent = abilityHbPart
                    abilityHbPart.Parent = root.Parent
                end
                local sz = S.HitboxAbilitySize
                if tick() < abilityBurstUntil then sz = sz * 1.5 end
                pcall(function() abilityHbPart.Size = Vector3.new(sz, sz, sz) end)
            end
        else
            destroyAbilityHb()
        end
    end
end)

-- ============================================================
-- ABILITY GRABBER
-- ============================================================
local elementFolder
local function findElementFolder()
    if elementFolder and elementFolder.Parent then return elementFolder end
    elementFolder = Workspace:FindFirstChild("ElementSelection", true)
    return elementFolder
end
local function abilityNames()
    local out = {}
    local f = findElementFolder()
    if f then
        for _,c in ipairs(f:GetChildren()) do
            if c:IsA("BasePart") or c:IsA("Model") then out[#out+1] = c.Name end
        end
        table.sort(out)
    end
    return out
end
local grabbing = false
local grabNoclip = false  -- forces noclip while grabbing so the TP can't get you stuck or killed
local function grabAbility(name)
    if grabbing or not name or name == "" then return end
    local f = findElementFolder()
    if not f then
        Rayfield:Notify({Title="Dream Hub", Content="ElementSelection not found - are you in the lobby?", Duration=4})
        return
    end
    local pad = f:FindFirstChild(name); if not pad then return end
    local root = getRoot(); if not root then return end
    grabbing = true
    task.spawn(function()
        local backCF = root.CFrame
        grabNoclip = true                    -- noclip ON in the background for the whole trip
        local padPos = pad:IsA("BasePart") and pad.Position or pad:GetPivot().Position
        pcall(function()
            root.CFrame = CFrame.new(padPos + Vector3.new(0, 4, 0))
            root.Anchored = true             -- HOLD at the pad so noclip can't sink you through the floor (that was the death)
        end)
        task.wait(0.5)
        tapKey(Enum.KeyCode.E)
        task.wait(S.GrabDelay)               -- wait the seconds you set, THEN teleport back
        local r = getRoot() or root
        pcall(function() r.Anchored = false end)   -- release before returning
        if S.GrabReturn and r then           -- back to EXACTLY where you were on the map
            pcall(function() r.CFrame = backCF end)
        end
        task.wait(0.3)                        -- settle a moment before collisions return
        grabNoclip = false
        if not S.Noclip then                  -- restore collisions (unless you have Noclip on)
            local c = getChar()
            if c then for _,pt in ipairs(c:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" then pcall(function() pt.CanCollide = true end) end
            end end
        end
        grabbing = false
    end)
end

-- ============================================================
-- AURAS  (client-side visual: clones a VFX onto your arms and KEEPS it
-- emitting so it stays on and you actually see the glow, not just the
-- mesh. Shows on YOUR screen - a server-side aura everyone sees needs the
-- equip remote remote-spied, same as the One Shot Punch capture.)
-- ============================================================
local function vfxFolder()
    local a = RS:FindFirstChild("Assets");   if not a then return nil end
    local v = a:FindFirstChild("VfxAssets"); if not v then return nil end
    return v:FindFirstChild("AbilitiesVfx")
end
local function auraNames()
    local out, f = {}, vfxFolder()
    if f then
        for _,c in ipairs(f:GetChildren()) do out[#out+1] = c.Name end
        table.sort(out)
    end
    return out
end

-- turn EVERY visual component on (this is the fix for "I only see the physics":
-- the emitters ship disabled because the game fires them on cast, so a plain
-- clone showed just the solid part).
local function enableVfx(inst)
    local function on(d)
        if d:IsA("ParticleEmitter") then
            pcall(function() d.Enabled = true; if d.Rate < 1 then d.Rate = 25 end; d:Emit(40) end)
        elseif d:IsA("Beam") or d:IsA("Trail") then
            pcall(function() d.Enabled = true end)
        elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
            pcall(function() d.Enabled = true end)
        elseif d:IsA("BasePart") then
            pcall(function() d.CanCollide=false; d.CanQuery=false; d.Massless=true; d.Anchored=false end)
        end
    end
    on(inst)
    for _,d in ipairs(inst:GetDescendants()) do on(d) end
end

local activeAura = nil
local auraParts = {}
local function clearAura()
    activeAura = nil
    for _,inst in ipairs(auraParts) do pcall(function() inst:Destroy() end) end
    auraParts = {}
end
local function auraMounts(char)
    local mounts = {}
    -- body centre first so the aura wraps you, then the game's own arm spots
    for _,nm in ipairs({"Torso","UpperTorso","HumanoidRootPart"}) do
        local part = char:FindFirstChild(nm)
        if part and part:IsA("BasePart") then mounts[#mounts+1] = part; break end
    end
    for _,armName in ipairs({"Left Arm","Right Arm"}) do
        local arm = char:FindFirstChild(armName)
        if arm then
            local fx   = arm:FindFirstChild("Effects")
            local hand = fx and fx:FindFirstChild("Hand")
            local m = hand or arm
            if not m:IsA("BasePart") then m = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") end
            if m then mounts[#mounts+1] = m end
        end
    end
    if #mounts == 0 then local cp = charPart(char); if cp then mounts[1] = cp end end
    return mounts
end
local function applyAuraNow(name)
    local f = vfxFolder(); if not f then return end
    local src = name and f:FindFirstChild(name); if not src then return end
    local char = getChar(); if not char then return end
    for _,mount in ipairs(auraMounts(char)) do
        local clone = src:Clone()
        clone.Name = "MFHAura"
        pcall(function()
            -- drop the non-visual bits (Interface GUIs, AbilitiesDesc config, scripts)
            -- so only the actual VFX remain
            local junk = {}
            for _,d in ipairs(clone:GetDescendants()) do
                if d:IsA("LayerCollector") or d:IsA("GuiObject") or d:IsA("GuiBase")
                or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                    junk[#junk+1] = d
                end
            end
            for _,d in ipairs(junk) do pcall(function() d:Destroy() end) end
            clone.Parent = mount
            -- glue EVERY part to the mount so no VFX part is left stranded at world origin
            local function glue(part)
                pcall(function()
                    part.CanCollide=false; part.CanQuery=false; part.Massless=true; part.Anchored=false
                    part.CFrame = mount.CFrame
                    local w = Instance.new("WeldConstraint"); w.Part0 = mount; w.Part1 = part; w.Parent = part
                end)
            end
            if clone:IsA("BasePart") then glue(clone) end
            for _,d in ipairs(clone:GetDescendants()) do if d:IsA("BasePart") then glue(d) end end
            enableVfx(clone)
        end)
        auraParts[#auraParts+1] = clone
    end
end
local function addAura(name)
    local f = vfxFolder()
    if not f then Rayfield:Notify({Title="Dream Hub", Content="VFX assets folder not found.", Duration=3}); return end
    if not (name and f:FindFirstChild(name)) then Rayfield:Notify({Title="Dream Hub", Content="Pick an aura first.", Duration=3}); return end
    clearAura()
    activeAura = name
    applyAuraNow(name)
    Rayfield:Notify({Title="Dream Hub", Content="Aura '"..name.."' on - it stays until you Remove it.", Duration=4})
end
-- keep the aura alive + emitting so it "stands longer" (re-emits every 0.5s)
task.spawn(function()
    while task.wait(0.5) do
        if activeAura and #auraParts > 0 then
            pcall(function()
                for _,inst in ipairs(auraParts) do
                    if inst and inst.Parent then enableVfx(inst) end
                end
            end)
        end
    end
end)

-- ============================================================
-- VFX MAKER (client-side custom aura: shape/color/size/particles).
-- Builds your own effect on your body. NOTE: client-side only - others won't
-- see it (a server-side / "publish to everyone" VFX needs the game's broadcast
-- remote, which isn't exposed here). "Publish" here = save/share the preset config.
-- ============================================================
local VFX_TEX = {
    Sparkles = "rbxasset://textures/particles/sparkles_main.dds",
    Fire     = "rbxasset://textures/particles/fire_main.dds",
    Smoke    = "rbxasset://textures/particles/smoke_main.dds",
    Square   = "",
}
local vfxObjs, vfxRings, vfxChar = {}, {}, nil
local function clearCustomVFX()
    for _, o in ipairs(vfxObjs) do pcall(function() o:Destroy() end) end
    vfxObjs, vfxRings = {}, nil
    vfxRings = {}
end
local function vfxMount()
    local char = getChar(); if not char then return nil end
    return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart") or charPart(char)
end
local function vfxColorSeq()
    if (not S.VFXRainbow) and S.VFXColor2 then
        return ColorSequence.new({ColorSequenceKeypoint.new(0, S.VFXColor), ColorSequenceKeypoint.new(1, S.VFXColor2)})
    end
    return ColorSequence.new(S.VFXColor)
end
local function applyCustomVFX()
    clearCustomVFX()
    local mount = vfxMount(); if not mount then return end
    vfxChar = getChar()
    -- core glowing shape
    if S.VFXShapeOn then
        local part = Instance.new("Part")
        part.Name = "MFHVFXCore"
        part.Shape = (S.VFXShape=="Block" and Enum.PartType.Block) or (S.VFXShape=="Cylinder" and Enum.PartType.Cylinder) or Enum.PartType.Ball
        part.Size = Vector3.new(S.VFXSize, S.VFXSize, S.VFXSize)
        part.Color = S.VFXColor; part.Material = Enum.Material.Neon; part.Transparency = S.VFXTransparency
        part.CanCollide=false; part.CanQuery=false; part.Massless=true; part.Anchored=false
        pcall(function() part.CFrame = mount.CFrame end); part.Parent = mount
        local w = Instance.new("WeldConstraint"); w.Part0=mount; w.Part1=part; w.Parent=part
        vfxObjs[#vfxObjs+1] = part
    end
    -- particles
    if S.VFXParticles then
        local att = Instance.new("Attachment", mount); vfxObjs[#vfxObjs+1] = att
        local pe = Instance.new("ParticleEmitter", att)
        pe.Texture = VFX_TEX[S.VFXTexture] or VFX_TEX.Sparkles
        pe.Color = vfxColorSeq()
        pe.Rate = S.VFXRate
        pe.Lifetime = NumberRange.new(S.VFXSpeed > 0 and 0.5 or 0.4, math.max(0.6, S.VFXSize/3))
        pe.Speed = NumberRange.new(S.VFXSpeed*0.4, S.VFXSpeed)
        pe.SpreadAngle = Vector2.new(S.VFXSpread, S.VFXSpread)
        pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, S.VFXPSize), NumberSequenceKeypoint.new(1, 0)})
        pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.15), NumberSequenceKeypoint.new(1,1)})
        pe.LightEmission = 0.85; pe.LightInfluence = 0
        pe.Rotation = NumberRange.new(0,360); pe.RotSpeed = NumberRange.new(-120,120)
        vfxObjs[#vfxObjs+1] = pe
    end
    -- light
    if S.VFXLight then
        local lp = Instance.new("PointLight", mount)
        lp.Color = S.VFXColor; lp.Brightness = S.VFXBrightness; lp.Range = math.max(8, S.VFXSize*2)
        vfxObjs[#vfxObjs+1] = lp
    end
    -- spinning rings (neon discs orbiting you)
    if S.VFXRings then
        for i = 1, math.max(1, S.VFXRingCount) do
            local ring = Instance.new("Part")
            ring.Name="MFHVFXRing"; ring.Shape=Enum.PartType.Cylinder
            ring.Size = Vector3.new(0.25, S.VFXSize*1.7, S.VFXSize*1.7)
            ring.Color = (S.VFXColor2 and i%2==0) and S.VFXColor2 or S.VFXColor
            ring.Material=Enum.Material.Neon; ring.Transparency=0.35
            ring.CanCollide=false; ring.CanQuery=false; ring.Massless=true; ring.Anchored=true
            ring.Parent = workspace
            vfxObjs[#vfxObjs+1] = ring
            vfxRings[#vfxRings+1] = {part=ring, phase=(i/S.VFXRingCount)*math.pi*2, tilt=i*35}
        end
    end
    -- beams / pillars circling you
    if S.VFXBeams then
        for i = 1, 6 do
            local b = Instance.new("Part")
            b.Name="MFHVFXBeam"; b.Shape=Enum.PartType.Cylinder
            b.Size = Vector3.new(S.VFXSize*1.6, 0.35, 0.35)
            b.Color = (S.VFXColor2 and i%2==0) and S.VFXColor2 or S.VFXColor
            b.Material=Enum.Material.Neon; b.Transparency=0.35
            b.CanCollide=false; b.CanQuery=false; b.Massless=true; b.Anchored=true
            b.Parent = workspace
            vfxObjs[#vfxObjs+1] = b
            vfxRings[#vfxRings+1] = {part=b, phase=(i/6)*math.pi*2, beam=true}
        end
    end
    -- trail
    if S.VFXTrail then
        local a0=Instance.new("Attachment", mount); a0.Position=Vector3.new(0,-1.6,0)
        local a1=Instance.new("Attachment", mount); a1.Position=Vector3.new(0,1.6,0)
        local tr=Instance.new("Trail", mount)
        tr.Attachment0=a0; tr.Attachment1=a1; tr.Lifetime=0.6; tr.LightEmission=0.85
        tr.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
        tr.Color = vfxColorSeq()
        vfxObjs[#vfxObjs+1]=a0; vfxObjs[#vfxObjs+1]=a1; vfxObjs[#vfxObjs+1]=tr
    end
end
-- animation: rainbow hue cycle + spin rings/beams around you
hook(RunService.RenderStepped, function()
    if not S.VFXOn then return end
    if S.VFXRainbow then
        local col = Color3.fromHSV((tick()*0.2) % 1, 1, 1)
        for _, o in ipairs(vfxObjs) do
            if o:IsA("ParticleEmitter") then o.Color = ColorSequence.new(col)
            elseif o:IsA("Trail") then o.Color = ColorSequence.new(col)
            elseif o:IsA("PointLight") then o.Color = col
            elseif o:IsA("Part") then o.Color = col end
        end
    end
    local mount = vfxMount()
    if mount and #vfxRings > 0 then
        local t = tick() * S.VFXSpin
        for _, r in ipairs(vfxRings) do
            if r.part and r.part.Parent then
                if r.beam then
                    local ang = r.phase + t
                    local off = Vector3.new(math.cos(ang)*S.VFXSize, 0, math.sin(ang)*S.VFXSize)
                    r.part.CFrame = mount.CFrame * CFrame.new(off) * CFrame.Angles(0,0,math.rad(90))
                else
                    r.part.CFrame = mount.CFrame * CFrame.Angles(math.rad(r.tilt), r.phase + t, 0) * CFrame.Angles(0,0,math.rad(90))
                end
            end
        end
    end
end)
-- keep alive + re-apply on respawn
task.spawn(function()
    while task.wait(0.5) do
        if S.VFXOn then
            if getChar() ~= vfxChar or not (vfxObjs[1] and vfxObjs[1].Parent) then pcall(applyCustomVFX) end
        end
    end
end)

-- ── VFX PRESETS (one-click aura looks) ─────────────────────────
local VFX_PRESETS = {
    Fire      = {Shape="Ball",Color=Color3.fromRGB(255,90,0),Color2=Color3.fromRGB(255,210,0),Texture="Fire",Rate=140,Speed=11,Spread=45,Light=true,Brightness=7,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.5},
    Ice       = {Shape="Ball",Color=Color3.fromRGB(120,220,255),Color2=Color3.fromRGB(225,250,255),Texture="Sparkles",Rate=90,Speed=4,Spread=160,Light=true,Brightness=4,Rings=true,RingCount=2,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.5},
    Lightning = {Shape="Ball",Color=Color3.fromRGB(120,180,255),Color2=Color3.fromRGB(255,255,255),Texture="Sparkles",Rate=170,Speed=16,Spread=180,Light=true,Brightness=9,Rings=false,Beams=true,Trail=false,Rainbow=false,ShapeOn=false,Size=4,Transp=0.5},
    Galaxy    = {Shape="Ball",Color=Color3.fromRGB(150,60,255),Color2=Color3.fromRGB(60,160,255),Texture="Sparkles",Rate=110,Speed=3,Spread=200,Light=true,Brightness=5,Rings=true,RingCount=3,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.6},
    Shadow    = {Shape="Ball",Color=Color3.fromRGB(70,0,100),Color2=Color3.fromRGB(20,20,30),Texture="Smoke",Rate=90,Speed=3,Spread=180,Light=true,Brightness=3,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.5},
    Holy      = {Shape="Ball",Color=Color3.fromRGB(255,240,150),Color2=Color3.fromRGB(255,255,255),Texture="Sparkles",Rate=120,Speed=5,Spread=160,Light=true,Brightness=9,Rings=true,RingCount=2,Beams=true,Trail=false,Rainbow=false,ShapeOn=true,Size=5,Transp=0.6},
    Toxic     = {Shape="Ball",Color=Color3.fromRGB(120,255,40),Color2=Color3.fromRGB(40,160,0),Texture="Smoke",Rate=90,Speed=4,Spread=170,Light=true,Brightness=4,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.5},
    Rainbow   = {Shape="Ball",Texture="Sparkles",Rate=140,Speed=6,Spread=180,Light=true,Brightness=6,Rings=true,RingCount=3,Beams=false,Trail=true,Rainbow=true,ShapeOn=true,Size=5,Transp=0.4},
    Void      = {Shape="Ball",Color=Color3.fromRGB(25,0,35),Color2=Color3.fromRGB(150,0,210),Texture="Smoke",Rate=110,Speed=2,Spread=200,Light=true,Brightness=4,Rings=true,RingCount=2,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=7,Transp=0.4},
    Sakura    = {Shape="Ball",Color=Color3.fromRGB(255,150,200),Color2=Color3.fromRGB(255,215,235),Texture="Sparkles",Rate=80,Speed=3,Spread=200,Light=true,Brightness=3,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.6},
    Nuke      = {Shape="Ball",Color=Color3.fromRGB(255,150,0),Color2=Color3.fromRGB(255,40,0),Texture="Fire",Rate=110,Speed=14,Spread=200,Light=true,Brightness=10,Rings=true,RingCount=2,Beams=true,Trail=false,Rainbow=false,ShapeOn=true,Size=8,Transp=0.3},
    -- ── new auras ──
    Inferno   = {Shape="Ball",Color=Color3.fromRGB(255,60,0),Color2=Color3.fromRGB(255,0,0),Texture="Fire",Rate=180,Speed=15,Spread=90,Light=true,Brightness=10,Rings=true,RingCount=3,Beams=true,Trail=true,Rainbow=false,ShapeOn=true,Size=7,Transp=0.35},
    Frostbite = {Shape="Ball",Color=Color3.fromRGB(80,180,255),Color2=Color3.fromRGB(180,240,255),Texture="Sparkles",Rate=120,Speed=3,Spread=200,Light=true,Brightness=6,Rings=true,RingCount=3,Beams=true,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.45},
    Blood     = {Shape="Ball",Color=Color3.fromRGB(150,0,0),Color2=Color3.fromRGB(255,40,40),Texture="Smoke",Rate=100,Speed=4,Spread=180,Light=true,Brightness=5,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.4},
    Cursed    = {Shape="Ball",Color=Color3.fromRGB(120,0,0),Color2=Color3.fromRGB(20,0,0),Texture="Smoke",Rate=130,Speed=5,Spread=200,Light=true,Brightness=6,Rings=true,RingCount=2,Beams=true,Trail=true,Rainbow=false,ShapeOn=true,Size=7,Transp=0.35},
    Storm     = {Shape="Ball",Color=Color3.fromRGB(90,120,200),Color2=Color3.fromRGB(230,240,255),Texture="Sparkles",Rate=200,Speed=18,Spread=200,Light=true,Brightness=9,Rings=false,Beams=true,Trail=false,Rainbow=false,ShapeOn=false,Size=6,Transp=0.4},
    Emerald   = {Shape="Ball",Color=Color3.fromRGB(0,200,90),Color2=Color3.fromRGB(160,255,190),Texture="Sparkles",Rate=110,Speed=4,Spread=180,Light=true,Brightness=6,Rings=true,RingCount=2,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.45},
    Phoenix   = {Shape="Ball",Color=Color3.fromRGB(255,120,0),Color2=Color3.fromRGB(255,220,60),Texture="Fire",Rate=160,Speed=13,Spread=120,Light=true,Brightness=9,Rings=true,RingCount=3,Beams=true,Trail=true,Rainbow=false,ShapeOn=true,Size=7,Transp=0.35},
    Nebula    = {Shape="Ball",Color=Color3.fromRGB(190,80,255),Color2=Color3.fromRGB(60,120,255),Texture="Sparkles",Rate=130,Speed=3,Spread=210,Light=true,Brightness=6,Rings=true,RingCount=4,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=7,Transp=0.5},
    Divine    = {Shape="Ball",Color=Color3.fromRGB(255,255,200),Color2=Color3.fromRGB(255,215,120),Texture="Sparkles",Rate=140,Speed=6,Spread=160,Light=true,Brightness=10,Rings=true,RingCount=3,Beams=true,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.5},
    Cyber     = {Shape="Ball",Color=Color3.fromRGB(0,255,200),Color2=Color3.fromRGB(0,140,255),Texture="Sparkles",Rate=150,Speed=8,Spread=190,Light=true,Brightness=8,Rings=true,RingCount=3,Beams=true,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.4},
}
local function applyVFXPreset(name)
    local pr = VFX_PRESETS[name]; if not pr then return end
    S.VFXShape=pr.Shape or S.VFXShape; S.VFXShapeOn = pr.ShapeOn~=false
    if pr.Color then S.VFXColor=pr.Color end
    if pr.Color2 then S.VFXColor2=pr.Color2 end
    S.VFXTexture=pr.Texture or S.VFXTexture; S.VFXRate=pr.Rate or S.VFXRate
    S.VFXSpeed=pr.Speed or S.VFXSpeed; S.VFXSpread=pr.Spread or S.VFXSpread
    S.VFXLight = pr.Light~=false; S.VFXBrightness=pr.Brightness or S.VFXBrightness
    S.VFXRings = pr.Rings==true; S.VFXRingCount=pr.RingCount or S.VFXRingCount
    S.VFXBeams = pr.Beams==true; S.VFXTrail = pr.Trail==true; S.VFXRainbow = pr.Rainbow==true
    S.VFXSize=pr.Size or S.VFXSize; S.VFXTransparency=pr.Transp or S.VFXTransparency
    S.VFXParticles = true
    if S.VFXOn then applyCustomVFX() end
end

-- ============================================================
-- SURVIVAL (anti ragdoll / push / void)
-- ============================================================
local BAD_STATES = {
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Physics,
    Enum.HumanoidStateType.PlatformStanding,
}
local function setRagdollStates(hum, enabled)
    for _,st in ipairs(BAD_STATES) do
        pcall(function() hum:SetStateEnabled(st, enabled) end)
    end
end

local function applyCharacter(char)
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then return end

    bind("antiRag", hum.StateChanged:Connect(function(_, new)
        if not S.AntiRagdoll then return end
        if new == Enum.HumanoidStateType.Physics
        or new == Enum.HumanoidStateType.PlatformStanding
        or new == Enum.HumanoidStateType.FallingDown
        or new == Enum.HumanoidStateType.Ragdoll then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end))

    bind("respawn", hum.Died:Connect(function()
        if S.InstantRespawn then
            task.delay(0.2, function() pcall(function() LP:LoadCharacter() end) end)
        end
    end))

    if S.AntiRagdoll then setRagdollStates(hum, false) end
    if S.SpeedHack   then pcall(function() hum.WalkSpeed = S.Speed end) end
end

-- Save-Health panic state - declared BEFORE CharacterAdded so the respawn reset
-- below binds to THESE locals (declaring them later made it write a dead global).
local healPanic = false
local healSaveCF = nil
local healPanicT = 0
hook(LP.CharacterAdded, function(char)
    destroyAbilityHb()
    healPanic = false
    task.wait(0.2)
    pcall(applyCharacter, char)
    if activeAura then task.wait(0.4); pcall(function() applyAuraNow(activeAura) end) end
end)
if LP.Character then pcall(applyCharacter, LP.Character) end

local STUN_ATTRS = {"Ragdoll","Ragdolled","Stunned","Stun","Knocked","Knockback","KO","Downed"}
local ragClock = 0
hook(RunService.Heartbeat, function(dt)
    if not S.AntiRagdoll then return end
    local hum, char = getHum(), getChar()
    if not (hum and char) then return end
    pcall(function()
        hum.PlatformStand = false
        hum.Sit = false
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.PlatformStanding then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    ragClock += dt
    if ragClock >= 0.5 then
        ragClock = 0
        setRagdollStates(hum, false)
        for _,attr in ipairs(STUN_ATTRS) do
            pcall(function()
                if char:GetAttribute(attr) == true then char:SetAttribute(attr, false) end
            end)
        end
        for _,d in ipairs(char:GetDescendants()) do
            if d:IsA("BallSocketConstraint") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("Motor6D") then
                pcall(function() if d.Enabled == false then d.Enabled = true end end)
            elseif d:IsA("BoolValue") then
                local n = d.Name:lower()
                if (n:find("ragdoll") or n:find("stun") or n:find("knock") or n:find("down")) and d.Value then
                    pcall(function() d.Value = false end)
                end
            end
        end
    end
end)

hook(RunService.Stepped, function()
    if S.Fly then return end
    if not (S.AntiPush or S.AntiFling) then return end
    local char, root, hum = getChar(), getRoot(), getHum()
    if not (char and root) then return end
    if S.AntiFling then
        for _,pt in ipairs(char:GetDescendants()) do
            if pt:IsA("BasePart") then
                if pt.AssemblyAngularVelocity.Magnitude > 20 then
                    pt.AssemblyAngularVelocity = Vector3.zero
                end
                if pt.AssemblyLinearVelocity.Magnitude > 130 then
                    pt.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
    end
    if S.AntiPush then
        local v   = root.AssemblyLinearVelocity
        local cap = ((hum and hum.WalkSpeed) or 16) * 2.5 + 25
        local hv  = Vector3.new(v.X, 0, v.Z)
        if hv.Magnitude > cap then
            root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(v.Y, -90, 60), 0)
        end
    end
end)

local savedSpawnCF = nil
local floatPart, lastSafeCF

-- read the LOCAL player's health, with or without a standard Humanoid
local function getHealth()
    local char = getChar(); if not char then return nil end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.MaxHealth and h.MaxHealth > 0 then return h.Health, h.MaxHealth end
    local cur = char:GetAttribute("Health")
    if type(cur) == "number" then
        local mx = char:GetAttribute("MaxHealth")
        return cur, (type(mx) == "number" and mx > 0 and mx) or 100
    end
    local hv = char:FindFirstChild("Health")
    if hv and (hv:IsA("NumberValue") or hv:IsA("IntValue")) then
        local mv = char:FindFirstChild("MaxHealth")
        local mx = (mv and (mv:IsA("NumberValue") or mv:IsA("IntValue")) and mv.Value) or 100
        return hv.Value, (mx > 0 and mx) or 100
    end
    return nil
end

-- read ANY character's health the same way (used by ESP so the label is never
-- blank for this game's Humanoid-less characters)
local function getTargetHealth(char)
    if not char then return nil end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.MaxHealth and h.MaxHealth > 0 then return h.Health, h.MaxHealth end
    local cur = char:GetAttribute("Health")
    if type(cur) == "number" then
        local mx = char:GetAttribute("MaxHealth")
        return cur, (type(mx) == "number" and mx > 0 and mx) or 100
    end
    local hv = char:FindFirstChild("Health")
    if hv and (hv:IsA("NumberValue") or hv:IsA("IntValue")) then
        local mv = char:FindFirstChild("MaxHealth")
        local mx = (mv and (mv:IsA("NumberValue") or mv:IsA("IntValue")) and mv.Value) or 100
        return hv.Value, (mx > 0 and mx) or 100
    end
    return nil
end

-- Best-effort: which ability/element a player has. This game exposes no
-- guaranteed signal, so we try attributes, StringValue children, a child named
-- like a known ability, then a Tool. Returns nil if it can't tell.
local ABILITY_ATTRS = {"Element","Ability","Move","Class","Skill","Power","Weapon","Kit","Stand","Fruit","CurrentAbility","ActiveElement","ActiveAbility","SelectedAbility","EquippedAbility"}
local _knownAbil, _knownAbilT = nil, 0
local function knownAbilities()
    if _knownAbil and (tick()-_knownAbilT) < 5 then return _knownAbil end
    _knownAbil = {}; _knownAbilT = tick()
    pcall(function() for _,n in ipairs(abilityNames()) do _knownAbil[n] = true end end)
    pcall(function() for _,n in ipairs(auraNames())    do _knownAbil[n] = true end end)
    return _knownAbil
end
local function getPlayerAbility(char)
    if not char then return nil end
    for _,k in ipairs(ABILITY_ATTRS) do
        local v = char:GetAttribute(k); if type(v)=="string" and #v>0 then return v end
    end
    for _,k in ipairs(ABILITY_ATTRS) do
        local sv = char:FindFirstChild(k)
        if sv and sv:IsA("StringValue") and #sv.Value>0 then return sv.Value end
    end
    -- ObjectValue pointing at the ability, anywhere on the char (e.g. char.Stats.Ability.Value)
    for _,k in ipairs(ABILITY_ATTRS) do
        local ov = char:FindFirstChild(k, true)
        if ov then
            if ov:IsA("ObjectValue") and ov.Value then return ov.Value.Name end
            if ov:IsA("StringValue") and #ov.Value>0 then return ov.Value end
        end
    end
    local known = knownAbilities()
    for _,c in ipairs(char:GetDescendants()) do
        if (c:IsA("BasePart") or c:IsA("Model") or c:IsA("Folder") or c:IsA("ModuleScript")) and known[c.Name] then return c.Name end
    end
    local tool = char:FindFirstChildOfClass("Tool"); if tool then return tool.Name end
    return nil
end

local function ensureFloat()
    if not floatPart or floatPart.Parent == nil then
        floatPart = Instance.new("Part")
        floatPart.Name         = "MFHFloat"
        floatPart.Size         = Vector3.new(16, 1, 16)
        floatPart.Anchored     = true
        floatPart.CanCollide   = true
        floatPart.CanQuery     = false
        floatPart.Material     = Enum.Material.ForceField
        floatPart.Color        = Color3.fromRGB(120, 170, 255)
        floatPart.Transparency = 0.6
        floatPart.Parent       = Workspace
    end
    return floatPart
end
local function showFloat(pos)
    local plat = ensureFloat()
    plat.CanCollide   = true
    plat.Transparency = 0.6
    plat.Position     = pos
end
local function hideFloat()
    if floatPart then floatPart.CanCollide = false; floatPart.Transparency = 1 end
end
local function isKillPart(inst)
    if not inst then return false end
    local kb = Workspace:FindFirstChild("KillBricks")
    if kb and inst:IsDescendantOf(kb) then return true end
    return tostring(inst.Name):lower():find("kill") ~= nil
end

hook(RunService.Heartbeat, function()
    if not S.AntiVoid then
        if floatPart then pcall(function() floatPart:Destroy() end); floatPart = nil end
        return
    end
    if S.Fly or S.InfiniteJump or healPanic then hideFloat(); return end  -- don't yank you back while you're meant to be airborne (Fly / Inf Jump / Save-Health)
    local root, char = getRoot(), getChar()
    if not (root and char) then return end
    local hum = getHum()  -- optional: this game's characters may have no Humanoid

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, floatPart}
    local hit = Workspace:Raycast(root.Position, Vector3.new(0, -2000, 0), params)

    local overWater = hit ~= nil and hit.Instance ~= nil and hit.Instance:IsA("Terrain") and hit.Material == Enum.Material.Water
    local overKill  = hit ~= nil and isKillPart(hit.Instance)
    local overVoid  = (hit == nil)
    local floor     = hum and hum.FloorMaterial or nil
    local swimming  = (hum and hum:GetState() == Enum.HumanoidStateType.Swimming) or floor == Enum.Material.Water

    -- remember the last solid, safe ground (works with NO Humanoid - pure raycast)
    if hit and not overWater and not overKill and (root.Position.Y - hit.Position.Y) <= 14 then
        lastSafeCF = root.CFrame
    end

    if swimming then
        showFloat(Vector3.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z))
        root.CFrame = root.CFrame + Vector3.new(0, 4, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    elseif overWater and (root.Position.Y - hit.Position.Y) < 12 then
        showFloat(Vector3.new(root.Position.X, hit.Position.Y + 0.5, root.Position.Z))
    elseif overVoid or overKill then
        hideFloat()
        local tpCF = savedSpawnCF or lastSafeCF
        if tpCF then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = tpCF + Vector3.new(0, 5, 0)
        else
            showFloat(root.Position - Vector3.new(0, 6, 0))
        end
    else
        hideFloat()
    end

    local killY = -480
    pcall(function() killY = Workspace.FallenPartsDestroyHeight + 100 end)
    if root.Position.Y < killY then
        local tpCF = savedSpawnCF or lastSafeCF
        if tpCF then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = tpCF + Vector3.new(0, 6, 0)
        end
    end
end)

-- ============================================================
-- ANTI WATER BORDER + ANTI KILL BRICKS
-- The map fences the water with invisible "Border Part"s under
-- Workspace.Border.Water that shove you back / drown you, and KillBricks
-- under Workspace.KillBricks insta-kill on touch. Removing them client-side
-- is what actually makes "Anti Water" hold and stops the kill bricks. Both
-- toggles destroy on enable AND re-clear every second (the server can
-- re-stream the parts in, so a one-shot wouldn't be enough).
-- ============================================================
local function destroyWaterBorder()
    local cleared = 0
    local roots = {}
    local border = Workspace:FindFirstChild("Border")
    if border then
        local w = border:FindFirstChild("Water")
        if w then roots[#roots+1] = w end
    end
    local w2 = Workspace:FindFirstChild("Water")   -- in case it sits at the top level
    if w2 then roots[#roots+1] = w2 end
    for _,r in ipairs(roots) do
        if r:IsA("BasePart") then pcall(function() r:Destroy() end); cleared += 1 end
        for _,d in ipairs(r:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d:Destroy() end); cleared += 1 end
        end
    end
    return cleared
end

local function destroyKillBricks()
    local cleared = 0
    local kb = Workspace:FindFirstChild("KillBricks")
    if kb then
        for _,d in ipairs(kb:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d:Destroy() end); cleared += 1 end
        end
        if kb:IsA("BasePart") then pcall(function() kb:Destroy() end); cleared += 1 end
    end
    return cleared
end

task.spawn(function()
    while task.wait(1) do
        if S.RemoveWaterBorder then pcall(destroyWaterBorder) end
        if S.AntiKillBricks    then pcall(destroyKillBricks) end
        if S.FullBright        then pcall(function() setFullBright(true) end) end
    end
end)

-- ============================================================
-- SAVE HEALTH (panic): when HP drops below the threshold, fly you up into
-- the sky and HOLD you there so nothing can reach you; when HP is back up
-- (you finished healing), drop you back to exactly where you were.
-- ============================================================
hook(RunService.Heartbeat, function()
    if not S.SaveHealth then
        if healPanic then               -- toggled off mid-panic: bring us back down
            healPanic = false
            local root = getRoot()
            if root then pcall(function() root.Anchored = false end) end
            if root and healSaveCF then pcall(function() root.CFrame = healSaveCF end) end
        end
        return
    end
    local root = getRoot(); if not root then return end
    local cur, max = getHealth()
    local pct = (cur and max and max > 0) and (cur / max * 100) or nil
    if not healPanic and not pct then return end  -- not in panic and HP unreadable -> nothing to do

    -- don't start a sky-escape while you're deliberately airborne (Fly / Inf Jump)
    if not healPanic and pct and pct <= S.SaveHealthPct and not S.Fly and not S.InfiniteJump then
        healPanic  = true
        healSaveCF = root.CFrame
        healPanicT = tick()
    end

    -- if you start flying / inf-jumping mid-panic, release so it can't hold you
    if healPanic and (S.Fly or S.InfiniteJump) then
        healPanic = false
        pcall(function() root.Anchored = false end)
    end

    if healPanic then
        local base = (healSaveCF and healSaveCF.Position) or root.Position
        pcall(function()
            root.Anchored = true        -- anchored so knockback / abilities can't fling you out of the sky
            root.CFrame = CFrame.new(base + Vector3.new(0, S.SaveHealthHeight, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end)
        -- come down when HP recovers a margin ABOVE the trigger (a fixed 90% can be
        -- unreachable if the game heals slowly / caps HP), OR after a 30s safety
        -- timeout. The timeout works even if HP becomes unreadable, so you can
        -- NEVER get stuck anchored in the sky.
        local exitPct = math.min(95, S.SaveHealthPct + 25)
        if (pct and pct >= exitPct) or (tick() - healPanicT) > 30 then
            healPanic = false
            pcall(function() root.Anchored = false end)
            if healSaveCF then pcall(function() root.CFrame = healSaveCF + Vector3.new(0, 3, 0) end) end
        end
    end
end)

-- ============================================================
-- INPUT EXTRAS
-- ============================================================
hook(UserInputService.JumpRequest, function()
    if S.InfiniteJump then
        local h = getHum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- Click TP moved to V (T is an ability key in this game - it was clashing)
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe then return end
    -- V on PC; on mobile (no keyboard) a screen TAP teleports to the tapped spot. gpe already filters GUI taps.
    if S.ClickTP and (i.KeyCode == Enum.KeyCode.V or i.UserInputType == Enum.UserInputType.Touch) then
        pcall(function()
            local pos
            if i.UserInputType == Enum.UserInputType.Touch then
                local cam = Workspace.CurrentCamera
                local ray = cam:ViewportPointToRay(i.Position.X, i.Position.Y)
                local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = { LP.Character }
                local res = Workspace:Raycast(ray.Origin, ray.Direction * 2000, rp)
                if res then pos = res.Position end
            else
                local m = LP:GetMouse(); if m and m.Target and m.Hit then pos = m.Hit.Position end
            end
            if pos then tpTo(CFrame.new(pos + Vector3.new(0,4,0))) end
        end)
    end
end)

pcall(function()
    hook(LP.Idled, function()
        if not S.AntiAFK then return end
        local vu = game:GetService("VirtualUser")
        vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end)
end)

-- ============================================================
-- MOVEMENT
-- ============================================================
local flyKeys = {W=false,A=false,S=false,D=false,Up=false,Down=false}
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe then return end
    local k=i.KeyCode
    if     k==Enum.KeyCode.W           then flyKeys.W=true
    elseif k==Enum.KeyCode.A           then flyKeys.A=true
    elseif k==Enum.KeyCode.S           then flyKeys.S=true
    elseif k==Enum.KeyCode.D           then flyKeys.D=true
    elseif k==Enum.KeyCode.Space       then flyKeys.Up=true
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=true end
end)
hook(UserInputService.InputEnded, function(i)
    local k=i.KeyCode
    if     k==Enum.KeyCode.W           then flyKeys.W=false
    elseif k==Enum.KeyCode.A           then flyKeys.A=false
    elseif k==Enum.KeyCode.S           then flyKeys.S=false
    elseif k==Enum.KeyCode.D           then flyKeys.D=false
    elseif k==Enum.KeyCode.Space       then flyKeys.Up=false
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=false end
end)
hook(RunService.RenderStepped, function(dt)
    if not S.Fly then return end
    local root = getRoot(); if not root then return end
    local hum = getHum()
    if hum then
        pcall(function()
            hum.PlatformStand = true
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end
    local cam = Workspace.CurrentCamera
    local dir = Vector3.zero
    if flyKeys.W    then dir += cam.CFrame.LookVector end
    if flyKeys.S    then dir -= cam.CFrame.LookVector end
    if flyKeys.A    then dir -= cam.CFrame.RightVector end
    if flyKeys.D    then dir += cam.CFrame.RightVector end
    if flyKeys.Up   then dir += Vector3.yAxis end
    if flyKeys.Down then dir -= Vector3.yAxis end
    -- MOBILE: no keyboard, so drive horizontal fly from the thumbstick (Humanoid.MoveDirection is world-space).
    -- Without this, enabling Fly on Delta/mobile strands you (PlatformStand on, but you can't move anywhere).
    if hum then
        local horiz = Vector3.new(dir.X, 0, dir.Z)
        if horiz.Magnitude == 0 then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then dir = Vector3.new(md.X, dir.Y, md.Z) end
        end
    end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        if dir.Magnitude > 0 then
            root.CFrame = root.CFrame + dir.Unit * S.FlySpeed * dt
        end
    end)
end)
-- ── MOBILE controls (Delta/touch) ── Fluriore's menu only reopens on RightShift, which a touchscreen has no
-- way to press; and Fly's up/down are Space/LeftControl. So on touch devices we build a small on-screen panel:
-- a MENU toggle (fires RightShift virtually so the UI shows/hides) + Fly ascend/descend buttons.
if UserInputService.TouchEnabled then
    pcall(function()
        local mg = Instance.new("ScreenGui")
        mg.Name = "DreamAA_Mobile"; mg.ResetOnSpawn = false; mg.IgnoreGuiInset = true; mg.DisplayOrder = 99998
        mg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        if not mg.Parent then mg.Parent = LP:WaitForChild("PlayerGui") end
        -- LAYOUT FIX ("can't move when they click on the gui"): the old buttons sat at the LEFT-MIDDLE of the
        -- screen — exactly where the dynamic movement thumbstick spawns on phones, so touches meant for
        -- WALKING landed on our buttons and the thumbstick never engaged. Everything now lives at the TOP
        -- edge (out of every control zone), the M1 button sits just above the jump button, and the fly
        -- arrows only exist while Fly is actually on.
        local function mkBtn(txt, pos)
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(44,44); b.Position = pos
            b.BackgroundColor3 = Color3.fromRGB(16,16,16); b.BackgroundTransparency = 0.25
            b.Text = txt; b.TextColor3 = Color3.fromRGB(255,60,60)
            b.TextSize = 20; b.Font = Enum.Font.GothamBold; b.AutoButtonColor = true; b.Parent = mg
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
            local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255,45,45); st.Thickness = 1.2; st.Parent = b
            return b
        end
        local menuB = mkBtn("≡", UDim2.new(0.5, -110, 0, 8))          -- top-center strip: never a movement zone
        menuB.MouseButton1Click:Connect(function()
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game); task.wait(); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game) end)
        end)
        local upB = mkBtn("▲", UDim2.new(0.5, -58, 0, 8))
        local dnB = mkBtn("▼", UDim2.new(0.5, -6, 0, 8))
        -- press-and-slide-off leaves MouseButton1Up unfired -> the key stuck held = "stuck flying up".
        -- InputEnded on the button catches BOTH clean release and slide-off, for touch and mouse alike.
        upB.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyKeys.Up = true end end)
        upB.InputEnded:Connect(function() flyKeys.Up = false end)
        dnB.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyKeys.Down = true end end)
        dnB.InputEnded:Connect(function() flyKeys.Down = false end)
        task.spawn(function()   -- fly arrows exist ONLY while Fly is on: off = zero dead zones on screen
            while mg.Parent do
                local on = S.Fly and true or false
                if upB.Visible ~= on then upB.Visible = on; dnB.Visible = on; if not on then flyKeys.Up = false; flyKeys.Down = false end end
                task.wait(0.25)
            end
        end)
        upB.Visible = false; dnB.Visible = false
        -- MOBILE M1: runs the SAME swing dispatcher the desktop click does (M1 Warp / Dash / Fling /
        -- One Punch / God-mode M1 + a base swing). Sits just ABOVE the jump button, clear of it.
        local m1B = Instance.new("TextButton")
        m1B.Size = UDim2.fromOffset(72,72); m1B.AnchorPoint = Vector2.new(1,1); m1B.Position = UDim2.new(1, -24, 1, -200)
        m1B.BackgroundColor3 = Color3.fromRGB(200,40,40); m1B.BackgroundTransparency = 0.2
        m1B.Text = "M1"; m1B.TextColor3 = Color3.fromRGB(255,255,255)
        m1B.TextSize = 24; m1B.Font = Enum.Font.GothamBold; m1B.AutoButtonColor = true; m1B.Parent = mg
        Instance.new("UICorner", m1B).CornerRadius = UDim.new(1,0)
        m1B.MouseButton1Click:Connect(function() if _G.AA_SWING then pcall(function() _G.AA_SWING(true) end) end end)
    end)
end
task.spawn(function()
    local wasFlying = false
    while task.wait(0.1) do
        if S.Fly then
            wasFlying = true
        elseif wasFlying then
            wasFlying = false
            local hum = getHum()
            if hum then
                pcall(function()
                    hum.PlatformStand = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
        end
    end
end)

hook(RunService.Stepped, function()
    if not (S.Noclip or grabNoclip) then return end
    local c = getChar(); if not c then return end
    for _,pt in ipairs(c:GetDescendants()) do
        if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end
    end
end)

hook(RunService.RenderStepped, function()
    if not S.CamLock then return end
    local tgt = nearestPlayer(S.CamLockRange); if not tgt or not tgt.Character then return end
    local head = tgt.Character:FindFirstChild("Head") or tgt.Character:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local cam = Workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
end)

-- ============================================================
-- VISUALS
-- ============================================================
local highlights = {}
local function clearHighlights()
    for _,h in pairs(highlights) do pcall(function() h:Destroy() end) end
    highlights = {}
end
hook(RunService.Heartbeat, function()
    if not S.EnemyHighlight then if next(highlights) then clearHighlights() end return end
    for name,h in pairs(highlights) do
        local p = Players:FindFirstChild(name)
        if not p or not p.Character or h.Parent==nil then
            pcall(function() h:Destroy() end); highlights[name]=nil
        end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and not highlights[p.Name] then
            local hl = Instance.new("Highlight")
            hl.FillColor = BrickColor.new(S.HighlightColor).Color
            hl.FillTransparency = 0.6; hl.OutlineColor = Color3.new(1,1,1)
            hl.Adornee = p.Character; hl.Parent = p.Character
            highlights[p.Name] = hl
        end
    end
end)

local espPool = {}
local hasDrawing = (typeof(Drawing) == "table") or (Drawing ~= nil)
local function clearESP()
    for _,d in pairs(espPool) do
        pcall(function() d.bill:Destroy() end)
        if d.line then pcall(function() d.line:Remove() end) end
        if d.box  then pcall(function() d.box:Remove()  end) end
    end
    espPool = {}
end
local function hpColor(frac)
    frac = math.clamp(frac, 0, 1)
    return Color3.fromRGB(math.floor(255*(1-frac)), math.floor(255*frac), 55)
end
local function espLabel(parent, posY, sizeY, txtSize, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0,0,posY,0)
    l.Size     = UDim2.new(1,0,0,sizeY)
    l.Font     = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = txtSize
    l.TextColor3 = Color3.new(1,1,1)
    l.TextStrokeTransparency = 0
    l.Parent = parent
    return l
end
local espTimer = 0
hook(RunService.RenderStepped, function(dt)
    if not (S.ESP or S.Tracers or S.ESPBox) then if next(espPool) then clearESP() end return end
    espTimer += dt
    if espTimer >= 0.3 then
        espTimer = 0
        for name,d in pairs(espPool) do
            local p = Players:FindFirstChild(name)
            if not p or not p.Character then
                pcall(function() d.bill:Destroy() end)
                if d.line then pcall(function() d.line:Remove() end) end
                if d.box  then pcall(function() d.box:Remove()  end) end
                espPool[name] = nil
            end
        end
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and not espPool[p.Name] then
                local head = p.Character.Head
                local bill = Instance.new("BillboardGui")
                bill.Name="MFHESP"; bill.Adornee=head; bill.Size=UDim2.new(0,210,0,58)
                bill.StudsOffset=Vector3.new(0,3,0); bill.AlwaysOnTop=true
                local nameLbl = espLabel(bill, 0.00, 16, 14, true)
                local abilLbl = espLabel(bill, 0.27, 13, 13, true); abilLbl.TextColor3 = Color3.fromRGB(255,70,70)
                local barBG = Instance.new("Frame")
                barBG.Position=UDim2.new(0.1,0,0.54,0); barBG.Size=UDim2.new(0.8,0,0,7)
                barBG.BackgroundColor3=Color3.fromRGB(15,15,15); barBG.BorderSizePixel=0
                barBG.BackgroundTransparency=0.2; barBG.Parent=bill
                local barFill = Instance.new("Frame")
                barFill.Size=UDim2.new(1,0,1,0); barFill.BorderSizePixel=0
                barFill.BackgroundColor3=Color3.fromRGB(0,200,0); barFill.Parent=barBG
                local infoLbl = espLabel(bill, 0.74, 13, 11, false); infoLbl.TextColor3=Color3.fromRGB(215,215,215)
                bill.Parent = head
                local line, box
                if hasDrawing then
                    line = Drawing.new("Line");   line.Thickness=1.5; line.Transparency=1; line.Color=Color3.fromRGB(255,70,70)
                    box  = Drawing.new("Square"); box.Thickness=1.5; box.Filled=false; box.Transparency=1; box.Color=Color3.fromRGB(255,70,70)
                end
                espPool[p.Name] = {bill=bill, nameLbl=nameLbl, abilLbl=abilLbl, barBG=barBG, barFill=barFill, infoLbl=infoLbl, line=line, box=box}
            end
        end
    end
    local cam = Workspace.CurrentCamera
    local myRoot = getRoot()
    for name,d in pairs(espPool) do
        local p    = Players:FindFirstChild(name)
        local char = p and p.Character
        local head = char and char:FindFirstChild("Head")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or charPart(char))
        local dist = (myRoot and root) and math.floor((root.Position-myRoot.Position).Magnitude) or 0
        local within = (S.ESPMaxDist or 0) <= 0 or dist <= S.ESPMaxDist
        local hp, maxHp = getTargetHealth(char)
        local frac = (hp and maxHp and maxHp > 0) and math.clamp(hp/maxHp, 0, 1) or nil
        local col  = (S.ESPColor and frac) and hpColor(frac) or Color3.fromRGB(255,70,70)
        local showText = S.ESP and head ~= nil and within
        d.bill.Enabled = showText
        if showText then
            d.nameLbl.Text = name; d.nameLbl.TextColor3 = col
            d.abilLbl.Text = S.ESPAbility and (getPlayerAbility(char) or "?") or ""
            if frac then
                d.barBG.Visible = true
                d.barFill.Size = UDim2.new(frac,0,1,0)
                d.barFill.BackgroundColor3 = col
                d.infoLbl.Text = string.format("%d/%d  -  %dm", math.floor(hp), math.floor(maxHp), dist)
            else
                d.barBG.Visible = false
                d.infoLbl.Text = string.format("?? HP  -  %dm", dist)
            end
        end
        if d.line then
            if S.Tracers and root and within then
                local sp, on = cam:WorldToViewportPoint(root.Position)
                if on then
                    d.line.Visible=true; d.line.Color=col
                    d.line.From=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    d.line.To=Vector2.new(sp.X, sp.Y)
                else d.line.Visible=false end
            else d.line.Visible=false end
        end
        if d.box then
            if S.ESPBox and head and root and within then
                local topV = cam:WorldToViewportPoint(head.Position + Vector3.new(0,2,0))
                local botV = cam:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
                if topV.Z > 0 and botV.Z > 0 then
                    local bh = math.abs(botV.Y - topV.Y); local bw = bh*0.6
                    local cx = (topV.X + botV.X)/2; local topY = math.min(topV.Y, botV.Y)
                    d.box.Visible=true; d.box.Color=col
                    d.box.Size=Vector2.new(bw, bh); d.box.Position=Vector2.new(cx - bw/2, topY)
                else d.box.Visible=false end
            else d.box.Visible=false end
        end
    end
end)

-- ── VIEW PLAYER (spectate) - reuses Camera.CameraSubject ───────────────────
local function viewPlayer(name)
    local pl = name and Players:FindFirstChild(name); local char = pl and pl.Character
    local subj = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Head") or charPart(char))
    local cam = Workspace.CurrentCamera
    if subj and cam then
        pcall(function() cam.CameraSubject = subj end); S.Viewing = name
        Rayfield:Notify({Title="Dream Hub", Content="Now viewing "..name..".", Duration=3})
    else
        Rayfield:Notify({Title="Dream Hub", Content="Player not found.", Duration=3})
    end
end
local function stopView()
    local cam = Workspace.CurrentCamera; local me = getHum() or getRoot()
    if cam and me then pcall(function() cam.CameraSubject = me end) end
    S.Viewing = nil
end
hook(RunService.RenderStepped, function()           -- re-assert subject across respawns
    if not S.Viewing then return end
    local pl = Players:FindFirstChild(S.Viewing); local char = pl and pl.Character
    local subj = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Head"))
    local cam = Workspace.CurrentCamera
    if subj and cam and cam.CameraSubject ~= subj then pcall(function() cam.CameraSubject = subj end) end
end)

local function setFullBright(on)
    pcall(function()
        if on then
            Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
            Lighting.Brightness=2; Lighting.FogEnd=1e9; Lighting.ClockTime=12; Lighting.GlobalShadows=false
        else
            Lighting.Ambient=Color3.fromRGB(70,70,70); Lighting.OutdoorAmbient=Color3.fromRGB(110,110,110)
            Lighting.Brightness=1; Lighting.FogEnd=1e5; Lighting.ClockTime=14; Lighting.GlobalShadows=true
        end
    end)
end

hook(RunService.Heartbeat, function()
    local h, root = getHum(), getRoot()
    if not (h and root) then return end
    if S.SpeedHack then
        pcall(function() h.WalkSpeed = S.Speed end)
        local mv = h.MoveDirection
        if mv.Magnitude > 0.1 then
            local vel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(mv.X * S.Speed, vel.Y, mv.Z * S.Speed)
        end
    end
end)

-- ============================================================
-- COMBAT LOOPS (every body is pcall-wrapped so one error can
-- never kill the loop - that crash is what broke Kill Aura)
-- ============================================================
-- (Kill Aura removed in v2.9.3 per request - use the hitbox expanders + your own M1.)

task.spawn(function()
    while task.wait(0.1) do
        if S.AutoM1 then
            pcall(function()
                -- AURA M1: only swing when someone is actually within range - no enemy near = no click.
                local near = nearestPlayer(S.AuraRange or 60)
                if near and near.Character then
                    clearMyHitLog()
                    local tr = charPart(near.Character); local root = getRoot()
                    if tr and root then pcall(function() root.CFrame = CFrame.new(root.Position, Vector3.new(tr.Position.X, root.Position.Y, tr.Position.Z)) end) end   -- face them so the swing connects
                    clickM1(true)     -- FORCED: a non-forced click skips whenever the cursor sits on the menu (= "aura m1 dont work")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if S.AutoAbility then
            pcall(function()
                local enemy = nearestPlayer(S.AutoAbilityRange)
                if enemy and enemy.Character then
                    local r = enemy.Character:FindFirstChild("HumanoidRootPart") or enemy.Character.PrimaryPart
                    if r then faceTo(r.Position) end
                end
                if S.CastE then tapKey(Enum.KeyCode.E) end
                if S.CastQ then tapKey(Enum.KeyCode.Q) end
                if S.CastR then tapKey(Enum.KeyCode.R) end
                if S.CastT then tapKey(Enum.KeyCode.T) end
            end)
        end
    end
end)

-- (Old Dash Behind hook REMOVED — the M1 Q Dash sequence now lives in the swing-start hook near the top
--  of the combat section: snap behind -> forced M1 -> dash Q -> return. One hook per click, no fighting.)

-- AUTO DASH: spam-dashes on a loop. Fires the dash remote AND taps the dash key
-- you pick below (default Q). NO LeftShift, so it never touches your camera.
local DASH_KEYS = {
    Q=Enum.KeyCode.Q, E=Enum.KeyCode.E, F=Enum.KeyCode.F, R=Enum.KeyCode.R,
    X=Enum.KeyCode.X, C=Enum.KeyCode.C, V=Enum.KeyCode.V, ["Left Shift"]=Enum.KeyCode.LeftShift,
}
task.spawn(function()
    while true do
        if S.AutoDash then
            pcall(function()
                fireDash("Forward")
                local kc = DASH_KEYS[S.AutoDashKey or "Q"]
                if kc then tapKey(kc) end
            end)
            task.wait(math.max(0.1, S.AutoDashDelay or 0.6))
        else
            task.wait(0.1)
        end
    end
end)

-- ── ABILITY AIM ASSIST ─────────────────────────────────────────
-- On a skill keypress, snap to face the nearest enemy (with simple velocity
-- lead) so directional abilities land. Facing-based, same as Auto Ability.
local AIM_KEYS = {
    [Enum.KeyCode.E]=true, [Enum.KeyCode.Q]=true, [Enum.KeyCode.R]=true,
    [Enum.KeyCode.T]=true, [Enum.KeyCode.F]=true,
}
hook(UserInputService.InputBegan, function(i, gpe)
    if not S.AimAssist or typingNow() then return end   -- no gpe bail: combat keys/clicks are always game-processed here
    local isSkill = AIM_KEYS[i.KeyCode]
    local isM1 = (i.UserInputType == Enum.UserInputType.MouseButton1) and S.AimOnM1   -- also snap on your M1 so basic attacks land
    if not (isSkill or isM1) then return end
    local tgt = nearestPlayer(S.AimAssistRange)
    local tr  = tgt and tgt.Character and charPart(tgt.Character)
    if not tr then return end
    local lead = tr.Position + tr.AssemblyLinearVelocity * (S.AimAssistLead or 0.12)
    faceTo(lead)
end)
-- STRONG AIM (hold on target): while on, smoothly keep facing the nearest enemy (with prediction) EVERY frame, not
-- just on a keypress — so both your M1s and directional abilities track them. Smoothed by the Aim Smoothness slider.
hook(RunService.RenderStepped, function()
    if not (S.AimAssist and S.AimStrong) or typingNow() then return end
    local tgt = nearestPlayer(S.AimAssistRange)
    local tr  = tgt and tgt.Character and charPart(tgt.Character)
    if not tr then return end
    local lead = tr.Position + tr.AssemblyLinearVelocity * (S.AimAssistLead or 0.12)
    faceToSmooth(lead, S.AimSmooth or 0.35)
end)

-- Auto Farm / Auto Play: ORIGINAL v2.9.6 brute-force. Teleport your root to
-- ~4 studs below the target's Hitbox CENTRE every 0.1s, which drops you INSIDE
-- their hitbox (point-blank) so the M1 overlap lands; then spam click + M1 +
-- abilities. (Distance-gating + cadence broke this by standing you outside.)
task.spawn(function()
    local abilT = 0
    while task.wait(0.05) do   -- FAST: ~20 swings/sec (user asked to hit them much faster)
        if S.AutoFarm and S.FarmTarget then
            pcall(function()
                local t    = Players:FindFirstChild(S.FarmTarget)
                local root = getRoot()
                if t and t.Character and root then
                    local tr = charPart(t.Character)
                    if tr then
                        local pos = tr.Position - tr.CFrame.LookVector * 2   -- point-blank behind them (no hitbox needed)
                        pcall(function() root.CFrame = CFrame.new(pos, tr.Position) end)   -- face them so the M1 connects
                        clearMyHitLog()
                        clickAtTarget(t, true)   -- real M1, forced
                        if tick() - abilT > 0.6 then   -- cycle abilities on a steadier beat so they actually cast
                            abilT = tick()
                            tapKey(Enum.KeyCode.E)
                            tapKey(Enum.KeyCode.R)
                            if S.CastQ then tapKey(Enum.KeyCode.Q) end
                            if S.CastT then tapKey(Enum.KeyCode.T) end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if S.AutoPlay then
            pcall(function()
                local target = nearestPlayer(S.AutoPlayRange)
                if not target or not target.Character then return end
                local tr   = charPart(target.Character)
                local root = getRoot()
                if not (tr and root) then return end
                local pos = tr.Position - Vector3.new(0, 4, 0)
                pcall(function() root.CFrame = CFrame.new(pos) end)
                clickAtTarget(target, true)
                fireM1(); fireM1()
                tapKey(Enum.KeyCode.E)
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if S.SpinBot then
            pcall(function()
                local root = getRoot()
                if root then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(tick()*900 % 360), 0)
                    root.AssemblyLinearVelocity = Vector3.new(0, 60, 0)
                end
            end)
            task.wait(0.03)
        end
    end
end)

-- ============================================================
-- TELEPORT HELPERS
-- ============================================================
-- Safe teleport: zero velocity AND hold the position for a short window so the
-- game's anti-teleport can't rubber-band you back.
local _holdCF, _holdUntil = nil, 0
hook(RunService.RenderStepped, function()
    if _holdCF and tick() < _holdUntil then
        local root = getRoot()
        if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero; root.CFrame = _holdCF end) end
    end
end)
-- JJS-STYLE BYPASS TELEPORT: an instant snap leaves the SERVER thinking you're still at the old spot for a beat,
-- so enemies keep hitting your old position ("i teleport but people can still hit me"). Instead we GLIDE there in
-- speed-capped steps, zeroing velocity every frame and moving the WHOLE model — the server tracks each step, so your
-- real (server) position actually moves with you. Then we HOLD the destination so it can't rubber-band back.
local _tpGen = 0
local function tpTo(cf, holdSec)
    local root = getRoot(); if not (root and cf) then return false end
    local dest = cf.Position
    _tpGen = _tpGen + 1; local gen = _tpGen
    local char = getChar()
    -- clear any body-movers that would drag you back
    pcall(function() for _,v in ipairs(root:GetChildren()) do if v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("AlignPosition") or v:IsA("LinearVelocity") or v:IsA("VectorForce") then v:Destroy() end end end)
    task.spawn(function()
        local dt, t0 = 1/60, tick()
        local rot = root.CFrame.Rotation
        while tick() - t0 < 6 do                      -- glide up to 6s (far pads)
            if _tpGen ~= gen then return end
            local r = getRoot(); if not r then break end
            local to = dest - r.Position; local d = to.Magnitude
            if d < 3 then break end
            local step = 140 * dt                     -- 140 studs/sec = fast but per-tick small enough that the server accepts each move
            local stepCF = CFrame.new(r.Position + to.Unit * math.min(d, step)) * rot
            pcall(function() r.CFrame = stepCF; r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end)
            if char then pcall(function() char:PivotTo(stepCF) end) end
            dt = RunService.Heartbeat:Wait()
        end
    end)
    _holdCF = cf; _holdUntil = tick() + (holdSec or 1.2)   -- longer hold so the server settles on the new spot
    return true
end
local function tpToPlayer(name, behind)
    local p = name and Players:FindFirstChild(name)
    local char = p and p.Character
    local tr = char and charPart(char)
    if not (tr and getRoot()) then
        Rayfield:Notify({Title="Dream Hub", Content="Target not found.", Duration=3})
        return
    end
    local off = (behind and -1 or 1) * tr.CFrame.LookVector * 4 + Vector3.new(0,1,0)
    -- look at the target so a follow-up M1 lands
    tpTo(CFrame.new(tr.Position + off, tr.Position))
end

local function rejoin() pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end
local function serverHop()
    task.spawn(function()
        local body
        pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            body = game:HttpGet(url)
        end)
        if body then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and data and data.data then
                for _,sv in ipairs(data.data) do
                    if sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP) end)
                        return
                    end
                end
            end
        end
        rejoin()
    end)
end

-- ============================================================
-- COMBAT PRO  (Legit Auto Play / Auto Dodge / Instant 1v1 Win / strong Aura M1)
-- Enemy-M1 detector + the four toggles. Uses the hub's helpers. No fling.
-- ============================================================
do
    local VIMp = game:GetService("VirtualInputManager")
    -- held-key manager (for Legit Auto Play holding W)
    local heldKeys = {}
    local function holdKey(kc, isHolding)
        if isHolding and not heldKeys[kc] then VIMp:SendKeyEvent(true, kc, false, game); heldKeys[kc] = true
        elseif not isHolding and heldKeys[kc] then VIMp:SendKeyEvent(false, kc, false, game); heldKeys[kc] = false end
    end
    local function releaseAllKeys() for kc in pairs(heldKeys) do pcall(function() VIMp:SendKeyEvent(false, kc, false, game) end) end heldKeys = {} end
    _G.AA_RELEASEKEYS = releaseAllKeys

    -- ── ENEMY M1 DETECTOR (velocity of their arm + their attack anims, facing you) ──
    local EnemyAttacked = false
    local trackedHumans = setmetatable({}, { __mode = "k" })
    RunService.Heartbeat:Connect(function()
        local myRoot = getRoot(); if not myRoot then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart") or charPart(p.Character)
                if tr then
                    if (tr.Position - myRoot.Position).Magnitude < 25 then
                        local rArm = p.Character:FindFirstChild("Right Arm") or p.Character:FindFirstChild("RightHand")
                        if rArm and rArm.AssemblyLinearVelocity.Magnitude > 30 then
                            local dirToMe = (myRoot.Position - tr.Position)
                            if dirToMe.Magnitude > 0 and tr.CFrame.LookVector:Dot(dirToMe.Unit) > 0.3 then
                                EnemyAttacked = true; task.delay(0.4, function() EnemyAttacked = false end)
                            end
                        end
                    end
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and not trackedHumans[hum] then
                        trackedHumans[hum] = true
                        local anim = hum:FindFirstChildOfClass("Animator")
                        if anim then
                            anim.AnimationPlayed:Connect(function()
                                if not (S.ProAutoDodge or S.LegitAutoPlay) then return end
                                local myR = getRoot(); if not myR then return end
                                local tr2 = p.Character and (p.Character:FindFirstChild("HumanoidRootPart") or charPart(p.Character))
                                if tr2 and (tr2.Position - myR.Position).Magnitude < 35 then
                                    local d = (myR.Position - tr2.Position)
                                    if d.Magnitude > 0 and tr2.CFrame.LookVector:Dot(d.Unit) > 0.1 then
                                        EnemyAttacked = true; task.delay(0.4, function() EnemyAttacked = false end)
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)

    -- ── AUTO DODGE: on an enemy M1, jump left/right a few studs ──
    local dodgeBusy = false
    RunService.Heartbeat:Connect(function()
        if not S.ProAutoDodge or dodgeBusy then return end
        if EnemyAttacked then
            dodgeBusy = true; EnemyAttacked = false
            task.spawn(function()
                local root = getRoot()
                if root then
                    local dir = ((tick() * 1000) % 2 < 1) and 1 or -1
                    pcall(function() root.CFrame = root.CFrame * CFrame.new(dir * 12, 0, 0); root.AssemblyLinearVelocity = Vector3.zero end)
                end
                task.wait(0.2); dodgeBusy = false
            end)
        end
    end)

    -- ── AURA M1 (strong): face nearest, M1 + E/R/T spam ──
    task.spawn(function()
        while true do
            if S.AuraM1Pro then
                local root = getRoot(); local target = nearestPlayer(S.AuraRange or 60)
                local tr = target and target.Character and (target.Character:FindFirstChild("HumanoidRootPart") or charPart(target.Character))
                if root and tr then
                    pcall(function() root.CFrame = CFrame.lookAt(root.Position, tr.Position) end)
                    clickM1(true); tapKey(Enum.KeyCode.E); tapKey(Enum.KeyCode.R); tapKey(Enum.KeyCode.T)
                end
            end
            task.wait(0.03)
        end
    end)

    -- ── INSTANT 1v1 WIN: warp front/back + M1 + abilities ──
    task.spawn(function()
        while true do
            if S.Win1v1 then
                local root = getRoot(); local target = nearestPlayer(50)
                local tr = target and target.Character and (target.Character:FindFirstChild("HumanoidRootPart") or charPart(target.Character))
                if root and tr then
                    local offset = (S.Win1v1Pos == "Front") and -3 or 3
                    local goal = tr.CFrame * CFrame.new(0, 0, offset)
                    pcall(function() root.CFrame = CFrame.lookAt(goal.Position, tr.Position); root.AssemblyLinearVelocity = Vector3.zero end)
                    clickM1(true); tapKey(Enum.KeyCode.E); tapKey(Enum.KeyCode.R); tapKey(Enum.KeyCode.T)
                end
            end
            task.wait(0.03)
        end
    end)

    -- ── LEGIT AUTO PLAY: hold W toward nearest, dash back (Q) on their M1, M1 in range ──
    local isDodging = false
    task.spawn(function()
        while true do
            if S.LegitAutoPlay then
                local root = getRoot(); local hum = getHum(); local target = nearestPlayer(60)
                local tr = target and target.Character and (target.Character:FindFirstChild("HumanoidRootPart") or charPart(target.Character))
                if root and hum and tr then
                    local dist = (tr.Position - root.Position).Magnitude
                    if EnemyAttacked and not isDodging then
                        isDodging = true; releaseAllKeys()
                        task.spawn(function() tapKey(Enum.KeyCode.Q); task.wait(0.3); isDodging = false end)
                    end
                    if not isDodging then
                        pcall(function() root.CFrame = CFrame.lookAt(root.Position, tr.Position) end)
                        if dist > 12 then holdKey(Enum.KeyCode.W, true)
                        else holdKey(Enum.KeyCode.W, false); clickM1(true); tapKey(Enum.KeyCode.E); tapKey(Enum.KeyCode.T) end
                    end
                else releaseAllKeys() end
            else releaseAllKeys() end
            task.wait(0.03)
        end
    end)
end

-- ============================================================
-- GUI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Dream Hub",
    LoadingTitle = "Dream Hub",
    LoadingSubtitle = "",
    ConfigurationSaving = { Enabled = true, FolderName = "MoneyFreeHub", FileName = "AbilityArena" },
    Discord = { Enabled = false },
    KeySystem = false,
    -- Original RED + VERY BLACK theme (near-pure-black bg, neon-red accents)
    Theme = {
        TextColor                    = Color3.fromRGB(235, 235, 235),
        Background                   = Color3.fromRGB(0, 0, 0),
        Topbar                       = Color3.fromRGB(8, 6, 7),
        Shadow                       = Color3.fromRGB(0, 0, 0),

        NotificationBackground       = Color3.fromRGB(6, 4, 5),
        NotificationActionsBackground= Color3.fromRGB(120, 20, 22),   -- deep red so overlaid text stays legible

        TabBackground                = Color3.fromRGB(12, 9, 10),
        TabStroke                    = Color3.fromRGB(70, 22, 26),
        TabBackgroundSelected        = Color3.fromRGB(255, 40, 40),   -- selected tab = neon red
        TabTextColor                 = Color3.fromRGB(200, 190, 192),
        SelectedTabTextColor         = Color3.fromRGB(15, 8, 9),      -- dark text on red for contrast

        ElementBackground            = Color3.fromRGB(10, 7, 8),
        ElementBackgroundHover       = Color3.fromRGB(22, 14, 16),
        SecondaryElementBackground   = Color3.fromRGB(7, 5, 6),
        ElementStroke                = Color3.fromRGB(58, 24, 28),
        SecondaryElementStroke       = Color3.fromRGB(48, 20, 24),

        SliderBackground             = Color3.fromRGB(90, 16, 20),    -- dark red track
        SliderProgress               = Color3.fromRGB(255, 45, 45),   -- neon red fill
        SliderStroke                 = Color3.fromRGB(255, 85, 85),

        ToggleBackground             = Color3.fromRGB(20, 13, 15),
        ToggleEnabled                = Color3.fromRGB(255, 45, 45),   -- neon red ON
        ToggleDisabled               = Color3.fromRGB(120, 112, 114), -- grey OFF (visible on near-black)
        ToggleEnabledStroke          = Color3.fromRGB(255, 95, 95),
        ToggleDisabledStroke         = Color3.fromRGB(140, 134, 136),
        ToggleEnabledOuterStroke     = Color3.fromRGB(180, 30, 34),
        ToggleDisabledOuterStroke    = Color3.fromRGB(45, 40, 42),

        DropdownSelected             = Color3.fromRGB(110, 34, 38),   -- red-tinted so the picked option is visible
        DropdownUnselected           = Color3.fromRGB(9, 6, 7),

        InputBackground              = Color3.fromRGB(12, 8, 9),
        InputStroke                  = Color3.fromRGB(70, 30, 34),
        PlaceholderColor             = Color3.fromRGB(150, 138, 140),
    },
})

local HomeTab      = Window:CreateTab("Home",      "home")
local CombatTab    = Window:CreateTab("Fight",     "swords")
local AbilitiesTab = Window:CreateTab("Skills",    "sparkles")
local TeleportsTab = Window:CreateTab("Teleport",  "navigation")
local MovementTab  = Window:CreateTab("Movement",  "footprints")
local VisualsTab   = Window:CreateTab("Auras",     "eye")
local FarmTab      = Window:CreateTab("Farm",      "target")
local UtilityTab   = Window:CreateTab("Misc",      "wrench")

-- \u2500\u2500 HOME (landing page) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
HomeTab:CreateSection("Welcome")
HomeTab:CreateParagraph({Title="Dream Hub", Content="Ability Arena  -  v2.15.0\nPick a tab on the left to get started."})
HomeTab:CreateParagraph({Title="Status", Content = JoltReliable and "Ready." or "Not ready - rejoin and retry."})
HomeTab:CreateParagraph({Title="Best combo", Content="M1 Warp (every click snaps you behind them for the swing) or Dash Behind On Hit. Anti-Ragdoll + Anti Void + Remove Water Border + Anti Kill Bricks for survival. Auras on the Visuals tab. Click TP is on V (T is an ability key)."})
HomeTab:CreateSection("Credits")
HomeTab:CreateParagraph({Title="Credits", Content="Dream Hub v2.15.0 - by Dream Hub Owner"})

CombatTab:CreateSection("Survival")
CombatTab:CreateToggle({Name="Anti-Ragdoll (hard)", CurrentValue=false, Flag="AntiRagdoll", Callback=function(v)
    S.AntiRagdoll=v
    local h=getHum()
    if h then setRagdollStates(h, not v) end
end})
CombatTab:CreateToggle({Name="Anti-Push (knockback)", CurrentValue=false, Flag="AntiPush", Callback=function(v) S.AntiPush=v end})
CombatTab:CreateToggle({Name="Anti Void / Water (instant TP back)", CurrentValue=false, Flag="AntiVoid", Callback=function(v) S.AntiVoid=v end})
CombatTab:CreateToggle({Name="Remove Water Border (makes Anti Water hold)", CurrentValue=false, Flag="RemoveWaterBorder", Callback=function(v)
    S.RemoveWaterBorder=v
    if v then
        local n=destroyWaterBorder()
        Rayfield:Notify({Title="Dream Hub", Content="Water border removed ("..n.." parts). Keeps clearing while on.", Duration=4})
    end
end})
CombatTab:CreateToggle({Name="Anti Kill Bricks (remove them)", CurrentValue=false, Flag="AntiKillBricks", Callback=function(v)
    S.AntiKillBricks=v
    if v then
        local n=destroyKillBricks()
        Rayfield:Notify({Title="Dream Hub", Content="Kill bricks removed ("..n.." parts). Keeps clearing while on.", Duration=4})
    end
end})
CombatTab:CreateToggle({Name="Save Health (low HP -> fly to sky, heal, drop back)", CurrentValue=false, Flag="SaveHealth", Callback=function(v) S.SaveHealth=v end})
CombatTab:CreateSlider({Name="Save Health: trigger at HP %", Range={5,90}, Increment=5, Suffix="%", CurrentValue=35, Flag="SaveHealthPct", Callback=function(v) S.SaveHealthPct=v end})
CombatTab:CreateSlider({Name="Save Health: sky height", Range={100,2000}, Increment=50, Suffix="studs", CurrentValue=700, Flag="SaveHealthHeight", Callback=function(v) S.SaveHealthHeight=v end})
-- GOD MODE (the lobby trick, user-discovered): a LOBBY spawn keeps you at full/infinite health because you
-- never entered the arena properly - and that state SURVIVES a teleport onto the map. So: stand in the
-- LOBBY, flip this ON, and it teleports you straight to the fight. You cannot be hurt. The known trade-off
-- of the trick itself: you also cannot M1 in that state (the game never armed your combat), so pair it with
-- One Punch / abilities, or flip it while spectating to troll safely.
-- GOD MODE: PLUS only. The free tier never even builds the toggle. AbilityArena_PLUS.lua sets _G.AA_PLUS.
if _G.AA_PLUS then
CombatTab:CreateToggle({Name="God Mode", CurrentValue=false, Flag="GodModeLobby", Callback=function(v)
    S.GodMode=v
    if not v then return end
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "God Mode", Text = "Must be in the LOBBY. Reset first, then turn this on.", Duration = 5 }) end)
    task.spawn(function()
        local root = getRoot(); if not root then return end
        local dest
        pcall(function()
            local gm = Workspace:FindFirstChild("GameMap")
            local sp = gm and gm:FindFirstChild("Spawns")
            if sp then
                local parts = {}
                for _, c in ipairs(sp:GetChildren()) do if c:IsA("BasePart") then parts[#parts+1] = c end end
                if #parts == 0 then for _, c in ipairs(sp:GetDescendants()) do if c:IsA("BasePart") then parts[#parts+1] = c end end end
                if #parts > 0 then
                    local part = parts[(tick() // 1) % #parts + 1]
                    dest = part.Position + Vector3.new(0, 4, 0)
                end
            end
        end)
        if not dest then
            local p = nearestPlayer(math.huge)
            local tr = p and p.Character and charPart(p.Character)
            if tr then dest = tr.Position + Vector3.new(4, 3, 0) end
        end
        if dest then
            pcall(function() root.CFrame = CFrame.new(dest); root.AssemblyLinearVelocity = Vector3.zero end)
        end
    end)
end})
end

CombatTab:CreateSection("Combat Pro")
CombatTab:CreateToggle({Name="Legit Auto Play", CurrentValue=false, Flag="LegitAutoPlay", Callback=function(v) S.LegitAutoPlay=v; if not v and _G.AA_RELEASEKEYS then _G.AA_RELEASEKEYS() end end})
CombatTab:CreateToggle({Name="Auto Dodge", CurrentValue=false, Flag="ProAutoDodge", Callback=function(v) S.ProAutoDodge=v end})
CombatTab:CreateToggle({Name="Instant 1v1 Win", CurrentValue=false, Flag="Win1v1", Callback=function(v) S.Win1v1=v end})
CombatTab:CreateDropdown({Name="1v1 Win Position", Options={"Back","Front"}, CurrentOption={"Back"}, Flag="Win1v1Pos", Callback=function(o) S.Win1v1Pos=(type(o)=="table" and o[1]) or o end})

CombatTab:CreateSection("M1 Warp")
CombatTab:CreateToggle({Name="M1 Warp", CurrentValue=false, Flag="M1Warp", Callback=function(v) S.M1Warp=v end})
CombatTab:CreateSlider({Name="M1 Warp Range", Range={10,200}, Increment=5, Suffix="studs", CurrentValue=60, Flag="M1WarpRange", Callback=function(v) S.M1WarpRange=v end})
CombatTab:CreateToggle({Name="Warp Back After Swing", CurrentValue=true, Flag="M1WarpReturn", Callback=function(v) S.M1WarpReturn=v end})

CombatTab:CreateSection("Auto")
CombatTab:CreateToggle({Name="Aura M1", CurrentValue=false, Flag="AuraM1Pro", Callback=function(v) S.AuraM1Pro=v end})
CombatTab:CreateSlider({Name="Aura M1 Range", Range={5,120}, Increment=5, Suffix="studs", CurrentValue=60, Flag="AuraRange", Callback=function(v) S.AuraRange=v end})
CombatTab:CreateToggle({Name="Auto Ability", CurrentValue=false, Flag="AutoAbility", Callback=function(v) S.AutoAbility=v end})
CombatTab:CreateSlider({Name="Auto Ability Range", Range={5,80}, Increment=1, Suffix="studs", CurrentValue=25, Flag="AutoAbilityRange", Callback=function(v) S.AutoAbilityRange=v end})
CombatTab:CreateToggle({Name="Cast E", CurrentValue=true,  Flag="CastE", Callback=function(v) S.CastE=v end})
CombatTab:CreateToggle({Name="Cast Q", CurrentValue=false, Flag="CastQ", Callback=function(v) S.CastQ=v end})
CombatTab:CreateToggle({Name="Cast R", CurrentValue=false, Flag="CastR", Callback=function(v) S.CastR=v end})
CombatTab:CreateToggle({Name="Cast T", CurrentValue=false, Flag="CastT", Callback=function(v) S.CastT=v end})
CombatTab:CreateToggle({Name="Dash Behind On Hit", CurrentValue=false, Flag="DashBehind", Callback=function(v) S.DashBehind=v end})
CombatTab:CreateSlider({Name="Dash Behind Range", Range={10,80}, Increment=1, Suffix="studs", CurrentValue=45, Flag="DashRange", Callback=function(v) S.DashRange=v end})
CombatTab:CreateToggle({Name="Auto Dash", CurrentValue=false, Flag="AutoDash", Callback=function(v) S.AutoDash=v end})
CombatTab:CreateDropdown({Name="Dash Key (whatever key dashes in-game)", Options={"Q","E","F","R","X","C","V","Left Shift"}, CurrentOption={"Q"}, Flag="AutoDashKey", Callback=function(o) S.AutoDashKey=(type(o)=="table" and o[1]) or o end})
CombatTab:CreateSlider({Name="Auto Dash Speed (lower = faster)", Range={1,20}, Increment=1, Suffix="x0.1s", CurrentValue=6, Flag="AutoDashTenths", Callback=function(v) S.AutoDashDelay=v/10 end})

CombatTab:CreateSection("Aim")
CombatTab:CreateToggle({Name="Camera Lock", CurrentValue=false, Flag="CamLock", Callback=function(v) S.CamLock=v end})
CombatTab:CreateSlider({Name="Cam Lock Range", Range={20,300}, Increment=5, Suffix="studs", CurrentValue=120, Flag="CamLockRange", Callback=function(v) S.CamLockRange=v end})
CombatTab:CreateToggle({Name="Ability Aim Assist", CurrentValue=false, Flag="AimAssist", Callback=function(v) S.AimAssist=v end})
CombatTab:CreateToggle({Name="Strong Aim", CurrentValue=false, Flag="AimStrong", Callback=function(v) S.AimStrong=v end})
CombatTab:CreateToggle({Name="Aim on M1", CurrentValue=true, Flag="AimOnM1", Callback=function(v) S.AimOnM1=v end})
CombatTab:CreateSlider({Name="Aim Smoothness (lower = smoother)", Range={5,100}, Increment=5, Suffix="%", CurrentValue=35, Flag="AimSmooth100", Callback=function(v) S.AimSmooth=v/100 end})
CombatTab:CreateSlider({Name="Aim Assist Range", Range={20,400}, Increment=10, Suffix="studs", CurrentValue=140, Flag="AimAssistRange", Callback=function(v) S.AimAssistRange=v end})
CombatTab:CreateSlider({Name="Aim Assist Lead (prediction)", Range={0,50}, Increment=1, Suffix="x0.01s", CurrentValue=12, Flag="AimAssistLead100", Callback=function(v) S.AimAssistLead=v/100 end})

AbilitiesTab:CreateSection("Ability Grabber")
AbilitiesTab:CreateParagraph({Title="Ability Grabber", Content="Pick any ability from the list to equip it instantly. Raise Grab Delay if an ability needs a moment longer to register."})
AbilitiesTab:CreateSlider({Name="Grab Delay (sec)", Range={1,8}, Increment=1, Suffix="sec", CurrentValue=3, Flag="GrabDelay", Callback=function(v) S.GrabDelay=v end})
AbilitiesTab:CreateToggle({Name="Return to map spawn after grab", CurrentValue=true, Flag="GrabReturn", Callback=function(v) S.GrabReturn=v end})
local selectedAbility = nil
local abilityDrop = AbilitiesTab:CreateDropdown({Name="Ability", Options=abilityNames(), CurrentOption={}, Flag="AbilityPick", Callback=function(o)
    selectedAbility = (type(o)=="table" and o[1]) or o
    grabAbility(selectedAbility)
end})
AbilitiesTab:CreateButton({Name="Get Ability Again", Callback=function() grabAbility(selectedAbility) end})
AbilitiesTab:CreateButton({Name="Refresh Ability List", Callback=function()
    elementFolder = nil
    pcall(function() abilityDrop:Refresh(abilityNames()) end)
end})

TeleportsTab:CreateSection("Players")
local tpDrop = TeleportsTab:CreateDropdown({Name="Teleport Target", Options=playerNames(), CurrentOption={}, Flag="TPTarget", Callback=function(o)
    S.TPTarget = (type(o)=="table" and o[1]) or o
end})
TeleportsTab:CreateButton({Name="TP To Target (in front)", Callback=function() tpToPlayer(S.TPTarget, false) end})
TeleportsTab:CreateButton({Name="TP Behind Target", Callback=function() tpToPlayer(S.TPTarget, true) end})
TeleportsTab:CreateButton({Name="TP Behind Nearest Player", Callback=function()
    local p = nearestPlayer()
    if p then tpToPlayer(p.Name, true)
    else Rayfield:Notify({Title="Dream Hub", Content="No players nearby.", Duration=3}) end
end})
TeleportsTab:CreateButton({Name="Refresh Player List", Callback=function()
    pcall(function() tpDrop:Refresh(playerNames()) end)
end})

TeleportsTab:CreateSection("Places")
TeleportsTab:CreateButton({Name="TP To Ability Pads (lobby)", Callback=function()
    local f = findElementFolder()
    local root = getRoot()
    if f and root then
        local pos = f:GetChildren()[1]
        if pos and (pos:IsA("BasePart") or pos:IsA("Model")) then
            local pp = pos:IsA("BasePart") and pos.Position or pos:GetPivot().Position
            tpTo(CFrame.new(pp + Vector3.new(0, 5, 0)))
        end
    else
        Rayfield:Notify({Title="Dream Hub", Content="Ability pads not found - are you in the lobby?", Duration=3})
    end
end})
TeleportsTab:CreateToggle({Name="Click Teleport  [V]", CurrentValue=false, Flag="ClickTP", Callback=function(v) S.ClickTP=v end})

TeleportsTab:CreateSection("Safe Spawn")
TeleportsTab:CreateButton({Name="Set Safe Spawn (save position)", Callback=function()
    local root = getRoot()
    if root then
        savedSpawnCF = root.CFrame
        Rayfield:Notify({Title="Dream Hub", Content="Safe spawn saved!", Duration=4})
    end
end})
TeleportsTab:CreateButton({Name="TP to Safe Spawn", Callback=function()
    local tpCF = savedSpawnCF or lastSafeCF
    if tpCF then
        healPanic = false                     -- cancel any Save Health sky-anchor first
        local r = getRoot(); if r then pcall(function() r.Anchored = false end) end
        tpTo(tpCF + Vector3.new(0, 3, 0))
    else
        Rayfield:Notify({Title="Dream Hub", Content="No safe spawn set yet.", Duration=4})
    end
end})
TeleportsTab:CreateButton({Name="Clear Safe Spawn", Callback=function()
    savedSpawnCF = nil
    Rayfield:Notify({Title="Dream Hub", Content="Safe spawn cleared.", Duration=3})
end})

MovementTab:CreateToggle({Name="Fly (WASD + Space/Ctrl)", CurrentValue=false, Flag="Fly", Callback=function(v) S.Fly=v end})
MovementTab:CreateSlider({Name="Fly Speed", Range={10,250}, Increment=5, Suffix="spd", CurrentValue=60, Flag="FlySpeed", Callback=function(v) S.FlySpeed=v end})
MovementTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v)
    S.Noclip=v
    if not v then
        local c=getChar()
        if c then for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then pcall(function() p.CanCollide=true end) end
        end end
    end
end})
MovementTab:CreateToggle({Name="Speed Hack", CurrentValue=false, Flag="SpeedHack", Callback=function(v)
    S.SpeedHack=v
    if not v then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end
end})
MovementTab:CreateSlider({Name="Walk Speed", Range={16,300}, Increment=1, Suffix="spd", CurrentValue=16, Flag="Speed", Callback=function(v) S.Speed=v end})
MovementTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Flag="InfiniteJump", Callback=function(v) S.InfiniteJump=v end})
MovementTab:CreateToggle({Name="Spin Bot", CurrentValue=false, Flag="SpinBot", Callback=function(v) S.SpinBot=v end})
MovementTab:CreateToggle({Name="Anti-Fling", CurrentValue=false, Flag="AntiFling", Callback=function(v) S.AntiFling=v end})

VisualsTab:CreateToggle({Name="Player ESP", CurrentValue=false, Flag="ESP", Callback=function(v) S.ESP=v end})
VisualsTab:CreateToggle({Name="Color By HP", CurrentValue=true, Flag="ESPColor", Callback=function(v) S.ESPColor=v end})
VisualsTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="Tracers", Callback=function(v) S.Tracers=v end})
VisualsTab:CreateToggle({Name="ESP Boxes (2D)", CurrentValue=false, Flag="ESPBox", Callback=function(v) S.ESPBox=v end})
VisualsTab:CreateToggle({Name="Show Ability on ESP", CurrentValue=true, Flag="ESPAbility", Callback=function(v) S.ESPAbility=v end})
VisualsTab:CreateSlider({Name="ESP Max Distance (0 = unlimited)", Range={0,2000}, Increment=10, Suffix="studs", CurrentValue=0, Flag="ESPMaxDist", Callback=function(v) S.ESPMaxDist=v end})
VisualsTab:CreateToggle({Name="Enemy Highlight", CurrentValue=false, Flag="EnemyHighlight", Callback=function(v) S.EnemyHighlight=v end})
VisualsTab:CreateDropdown({Name="Highlight Color", Options={"Bright blue","Bright red","Lime green","New Yeller","White","Magenta"}, CurrentOption={"Bright blue"}, Flag="HighlightColor", Callback=function(o)
    S.HighlightColor = (type(o)=="table" and o[1]) or o
    clearHighlights()
end})
VisualsTab:CreateToggle({Name="Full Bright", CurrentValue=false, Flag="FullBright", Callback=function(v) S.FullBright=v; setFullBright(v) end})

VisualsTab:CreateSection("View Player")
local viewDrop = VisualsTab:CreateDropdown({Name="Spectate Target", Options=playerNames(), CurrentOption={}, Flag="ViewTarget", Callback=function(o)
    S.ViewTarget = (type(o)=="table" and o[1]) or o
end})
VisualsTab:CreateButton({Name="View Player", Callback=function() viewPlayer(S.ViewTarget) end})
VisualsTab:CreateButton({Name="Stop Viewing", Callback=stopView})

VisualsTab:CreateSection("Auras")
VisualsTab:CreateParagraph({Title="Add Aura", Content="Pick any aura and click Add Aura to wear its effect. Use Remove Aura to take it off."})
local selAura = nil
local auraDrop = VisualsTab:CreateDropdown({Name="Aura", Options=auraNames(), CurrentOption={}, Flag="AuraPick", Callback=function(o)
    selAura = (type(o)=="table" and o[1]) or o
end})
VisualsTab:CreateButton({Name="Add Aura", Callback=function() addAura(selAura) end})
VisualsTab:CreateButton({Name="Remove Aura", Callback=clearAura})
VisualsTab:CreateButton({Name="Refresh Aura List", Callback=function() pcall(function() auraDrop:Refresh(auraNames()) end) end})

VisualsTab:CreateSection("AURA / VFX MAKER")
VisualsTab:CreateParagraph({Title="Aura Maker", Content="Build your own aura like the Aura games - presets, dual colour / rainbow, particles, light, spinning rings, beams, trail. Client-side (only you see it)."})
local function reVFX() if S.VFXOn then applyCustomVFX() end end
VisualsTab:CreateToggle({Name="Apply My Aura", CurrentValue=false, Flag="VFXOn", Callback=function(v) S.VFXOn=v; if v then applyCustomVFX() else clearCustomVFX() end end})
VisualsTab:CreateDropdown({Name="Preset", Options={"Fire","Ice","Lightning","Galaxy","Shadow","Holy","Toxic","Rainbow","Void","Sakura","Nuke","Inferno","Frostbite","Blood","Cursed","Storm","Emerald","Phoenix","Nebula","Divine","Cyber"}, CurrentOption={}, Flag="VFXPreset", Callback=function(o)
    local nm; if type(o)=="table" then nm=o[1] else nm=o end   -- empty table -> nm=nil (Fluriore fires this on creation)
    if not nm or nm=="" then return end                        -- so no red aura applies on spawn
    applyVFXPreset(nm); S.VFXOn=true; applyCustomVFX()
end})

VisualsTab:CreateSection("Aura - Core")
VisualsTab:CreateToggle({Name="Core Shape", CurrentValue=true, Flag="VFXShapeOn", Callback=function(v) S.VFXShapeOn=v; reVFX() end})
VisualsTab:CreateDropdown({Name="Shape", Options={"Ball","Block","Cylinder"}, CurrentOption={"Ball"}, Flag="VFXShape", Callback=function(o) S.VFXShape=(type(o)=="table" and o[1]) or o; reVFX() end})
VisualsTab:CreateColorPicker({Name="Color 1", Color=Color3.fromRGB(255,40,40), Flag="VFXColor", Callback=function(c) S.VFXColor=c; reVFX() end})
VisualsTab:CreateColorPicker({Name="Color 2 (gradient)", Color=Color3.fromRGB(255,180,40), Flag="VFXColor2", Callback=function(c) S.VFXColor2=c; reVFX() end})
VisualsTab:CreateToggle({Name="Rainbow (animated)", CurrentValue=false, Flag="VFXRainbow", Callback=function(v) S.VFXRainbow=v; reVFX() end})
VisualsTab:CreateSlider({Name="Size", Range={1,30}, Increment=1, Suffix="studs", CurrentValue=6, Flag="VFXSize", Callback=function(v) S.VFXSize=v; reVFX() end})
VisualsTab:CreateSlider({Name="Transparency", Range={0,100}, Increment=5, Suffix="%", CurrentValue=40, Flag="VFXTransp", Callback=function(v) S.VFXTransparency=v/100; reVFX() end})

VisualsTab:CreateSection("Aura - Particles")
VisualsTab:CreateToggle({Name="Particles", CurrentValue=true, Flag="VFXParticles", Callback=function(v) S.VFXParticles=v; reVFX() end})
VisualsTab:CreateDropdown({Name="Particle Texture", Options={"Sparkles","Fire","Smoke","Square"}, CurrentOption={"Sparkles"}, Flag="VFXTexture", Callback=function(o) S.VFXTexture=(type(o)=="table" and o[1]) or o; reVFX() end})
VisualsTab:CreateSlider({Name="Particle Rate", Range={0,300}, Increment=5, Suffix="/s", CurrentValue=80, Flag="VFXRate", Callback=function(v) S.VFXRate=v; reVFX() end})
VisualsTab:CreateSlider({Name="Particle Speed", Range={0,30}, Increment=1, Suffix="spd", CurrentValue=6, Flag="VFXSpeed", Callback=function(v) S.VFXSpeed=v; reVFX() end})
VisualsTab:CreateSlider({Name="Particle Spread", Range={0,360}, Increment=10, Suffix="deg", CurrentValue=180, Flag="VFXSpread", Callback=function(v) S.VFXSpread=v; reVFX() end})
VisualsTab:CreateSlider({Name="Particle Size", Range={1,20}, Increment=1, Suffix="x0.1", CurrentValue=12, Flag="VFXPSize", Callback=function(v) S.VFXPSize=v/10; reVFX() end})

VisualsTab:CreateSection("Aura - Extras")
VisualsTab:CreateToggle({Name="Light Glow", CurrentValue=true, Flag="VFXLight", Callback=function(v) S.VFXLight=v; reVFX() end})
VisualsTab:CreateSlider({Name="Light Brightness", Range={0,15}, Increment=1, Suffix="", CurrentValue=5, Flag="VFXBrightness", Callback=function(v) S.VFXBrightness=v; reVFX() end})
VisualsTab:CreateToggle({Name="Spinning Rings", CurrentValue=false, Flag="VFXRings", Callback=function(v) S.VFXRings=v; reVFX() end})
VisualsTab:CreateSlider({Name="Ring Count", Range={1,5}, Increment=1, Suffix="", CurrentValue=2, Flag="VFXRingCount", Callback=function(v) S.VFXRingCount=v; reVFX() end})
VisualsTab:CreateSlider({Name="Spin Speed", Range={0,10}, Increment=1, Suffix="", CurrentValue=2, Flag="VFXSpin", Callback=function(v) S.VFXSpin=v end})
VisualsTab:CreateToggle({Name="Beams / Pillars", CurrentValue=false, Flag="VFXBeams", Callback=function(v) S.VFXBeams=v; reVFX() end})
VisualsTab:CreateToggle({Name="Trail", CurrentValue=true, Flag="VFXTrail", Callback=function(v) S.VFXTrail=v; reVFX() end})
VisualsTab:CreateButton({Name="Save / Copy Preset", Callback=function()
    local function rgb(c) return math.floor(c.R*255)..","..math.floor(c.G*255)..","..math.floor(c.B*255) end
    local preset = string.format("shape=%s|c1=%s|c2=%s|size=%d|transp=%d|tex=%s|rate=%d|speed=%d|spread=%d|rainbow=%s|light=%s|bright=%d|rings=%s|ringc=%d|beams=%s|trail=%s",
        S.VFXShape, rgb(S.VFXColor), rgb(S.VFXColor2), S.VFXSize, math.floor(S.VFXTransparency*100), S.VFXTexture, S.VFXRate, S.VFXSpeed, S.VFXSpread,
        tostring(S.VFXRainbow), tostring(S.VFXLight), S.VFXBrightness, tostring(S.VFXRings), S.VFXRingCount, tostring(S.VFXBeams), tostring(S.VFXTrail))
    pcall(function() if writefile then writefile("DreamAura.txt", preset) end end)
    pcall(function() if setclipboard then setclipboard(preset) end end)
    Rayfield:Notify({Title="Aura Maker", Content="Preset saved + copied. Share the text to let others rebuild your aura.", Duration=5})
end})

FarmTab:CreateSection("Auto Play")
FarmTab:CreateToggle({Name="Auto Play (fight nearest enemy automatically)", CurrentValue=false, Flag="AutoPlay", Callback=function(v) S.AutoPlay=v end})
FarmTab:CreateSlider({Name="Auto Play Search Range", Range={10,300}, Increment=5, Suffix="studs", CurrentValue=100, Flag="AutoPlayRange", Callback=function(v) S.AutoPlayRange=v end})

FarmTab:CreateSection("Auto Farm")
FarmTab:CreateToggle({Name="Auto Farm Target", CurrentValue=false, Flag="AutoFarm", Callback=function(v)
    if v and not S.FarmTarget then
        Rayfield:Notify({Title="Dream Hub", Content="Pick a target first.", Duration=3})
        v=false
    end
    S.AutoFarm=v
end})
local farmDrop = FarmTab:CreateDropdown({Name="Target Player", Options=playerNames(), CurrentOption={}, Flag="FarmTarget", Callback=function(o)
    S.FarmTarget = (type(o)=="table" and o[1]) or o
end})
FarmTab:CreateButton({Name="Refresh Player List", Callback=function()
    pcall(function() farmDrop:Refresh(playerNames()) end)
end})

-- Keep the Teleport + Farm target lists current as players join/leave.
local function refreshPlayerDrops()
    pcall(function() tpDrop:Refresh(playerNames()) end)
    pcall(function() farmDrop:Refresh(playerNames()) end)
    pcall(function() viewDrop:Refresh(playerNames()) end)
end
hook(Players.PlayerAdded,    function() task.delay(0.3, refreshPlayerDrops) end)
hook(Players.PlayerRemoving, function() task.delay(0.3, refreshPlayerDrops) end)

UtilityTab:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AntiAFK", Callback=function(v) S.AntiAFK=v end})
UtilityTab:CreateToggle({Name="Instant Respawn", CurrentValue=false, Flag="InstantRespawn", Callback=function(v) S.InstantRespawn=v end})
UtilityTab:CreateButton({Name="Rejoin Server", Callback=rejoin})
UtilityTab:CreateButton({Name="Server Hop", Callback=serverHop})

UtilityTab:CreateSection("Debug")
UtilityTab:CreateParagraph({Title="Dump Player Data", Content="Prints every player's character attributes + value-objects to the executor console (F9 / your console). Paste it back so the ESP ability + god-mode flag can be wired exactly."})
UtilityTab:CreateButton({Name="Dump Player Data (to console)", Callback=function()
    local function dump(char, tag)
        if not char then return end
        print("=====", tag, char.Name, "=====")
        local attrs = char:GetAttributes()
        for k,v in pairs(attrs) do print("  Attr:", k, "=", tostring(v), "("..typeof(v)..")") end
        for _,d in ipairs(char:GetDescendants()) do
            if d:IsA("StringValue") or d:IsA("ObjectValue") or d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("BoolValue") then
                local val = d:IsA("ObjectValue") and (d.Value and d.Value.Name or "nil") or tostring(d.Value)
                print("  Value:", d:GetFullName(), "=", val)
            end
        end
    end
    dump(LP.Character, "SELF")
    for _,pl in ipairs(Players:GetPlayers()) do if pl ~= LP then dump(pl.Character, "PLAYER") end end
    Rayfield:Notify({Title="Dream Hub", Content="Dumped to console (open F9 / executor console).", Duration=5})
end})

UtilityTab:CreateToggle({Name="Spy M1 Packets  [removed - anti-cheat safe]", CurrentValue=false, Flag="M1Spy", Callback=function(v)
    -- Hard-disabled: the packet spy required a __namecall hook, which Ability Arena's anti-cheat
    -- detects ("namecallInstance detector" -> 267 kick). The toggle is kept as a no-op so old saved
    -- configs with M1Spy=true don't error; it never installs a hook now.
    S.M1Spy = false
    if v then Rayfield:Notify({Title="Dream Hub", Content="M1 Packet Spy is disabled — it used a namecall hook that got you kicked (Error 267). The hub no longer hooks anything.", Duration=8}) end
end})

UtilityTab:CreateSection("Admin")
UtilityTab:CreateButton({Name="Unload Dream Hub", Callback=function()
    for _,c in pairs(Conns) do pcall(function() c:Disconnect() end) end
    for _,c in ipairs(Listeners) do pcall(function() c:Disconnect() end) end
    pcall(function() setFullBright(false) end)   -- restore lighting if Full Bright was on
    pcall(function() stopView() end)             -- restore camera if spectating
    clearESP(); clearHighlights(); restoreHitboxes(); destroyAbilityHb(); clearAura()
    if floatPart then pcall(function() floatPart:Destroy() end) end
    local h=getHum(); if h then setRagdollStates(h, true) end
    for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
    pcall(function() Rayfield:Destroy() end)
end})


-- session integrity watcher
do
    local Plrs = game:GetService("Players"); local me = Plrs.LocalPlayer
    -- add YOUR OWN account name(s) here (lowercase) so you can run spy/dev tools on your own copy without it unloading
    local WL = { }   -- e.g. { ["unskibidyy"]=true }
    -- known remote-spy / explorer / decompiler / save-instance tool signatures (globals + GUI names)
    local G  = {"SimpleSpy","RemoteSpy","Dex","DarkDex","DarkDexV3","Hydroxide","SaveInstance","RemoteLogger","SimpleSpyExecutionList","Hydroxgen","Decompiler","IY_LOADED","Serpent","BytecodeInspector"}
    local NS = {"simplespy","remotespy","remote spy","darkdex","dex explorer","dex v","hydroxide","saveinstance","script spy","server spy","spy v","remote logger","decompile","bytecode","dumper"}
    local function bail(sig)
        pcall(function() for _,c in pairs(Conns) do pcall(function() c:Disconnect() end) end end)
        pcall(function() for _,c in ipairs(Listeners) do pcall(function() c:Disconnect() end) end end)
        pcall(function() for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end end)
        pcall(function() restoreHitboxes(); restoreArms() end)
        pcall(function() Rayfield:Destroy() end)
        pcall(function() me:Kick("\226\154\160") end)   -- best-effort hard kick so the tool can't keep logging
    end
    local function scan()
        if WL[tostring(me.Name):lower()] then return end
        local ok,genv = pcall(getgenv); if ok and type(genv)=="table" then for _,s in ipairs(G) do if rawget(genv,s)~=nil then return bail(s) end end end
        if type(shared)=="table" then for _,s in ipairs({"Hydroxide","SimpleSpy"}) do local o=pcall(function() return shared[s] end); if o and shared[s]~=nil then return bail(s) end end end
        local roots={}
        pcall(function() if gethui then roots[#roots+1]=gethui() end end)
        pcall(function() roots[#roots+1]=game:GetService("CoreGui") end)
        pcall(function() local pg=me:FindFirstChildOfClass("PlayerGui"); if pg then roots[#roots+1]=pg end end)
        for _,r in ipairs(roots) do
            local ok2,kids=pcall(function() return r:GetChildren() end)
            if ok2 then for _,g in ipairs(kids) do local n=tostring(g.Name):lower()
                for _,s in ipairs(NS) do if n:find(s,1,true) then return bail(g.Name) end end
            end end
        end
    end
    task.spawn(function() task.wait(4); while true do pcall(scan); task.wait(3) end end)   -- settle, then poll
end

-- INSURANCE: Fluriore fires element callbacks on creation, which can flip the aura on during build.
-- After the GUI settles, force the aura OFF so you always spawn clean (no red sphere).
task.delay(1.2, function() S.VFXOn=false; pcall(clearCustomVFX) end)

Rayfield:Notify({Title="Dream Hub", Content="Loaded.", Duration=5})

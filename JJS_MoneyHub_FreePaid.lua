--[=[
    MoneyHub - Fixed Version
    - Inline character and tier data now properly stored.
    - Rayfield loading improved with fallback and user feedback.
    - External file dependency removed for stability.
]=]

-- ========== INLINE CHARACTER REGISTRY ==========
local CharacterRegistry = (function()
    local defaultMoves = {
        dash = Enum.KeyCode.Q,
        s1 = Enum.KeyCode.One,
        s2 = Enum.KeyCode.Two,
        s3 = Enum.KeyCode.Three,
        s4 = Enum.KeyCode.Four,
        ult = Enum.KeyCode.G,
        counter = Enum.KeyCode.R,
        block = Enum.KeyCode.F,
    }

    local function copyMoves(overrides)
        local result = {}
        for key, value in pairs(defaultMoves) do
            result[key] = value
        end

        if overrides then
            for key, value in pairs(overrides) do
                result[key] = value
            end
        end

        return result
    end

    local function tech(name, preset, seq, options)
        options = options or {}
        return {
            name = name,
            preset = preset or "Balanced",
            seq = seq,
            cooldown = options.cooldown or 1.6,
            maxDistance = options.maxDistance or 13,
            weight = options.weight or 1,
        }
    end

    return {
        vessel = {
            displayName = "Vessel",
            free = true,
            moves = copyMoves(),
            techs = {
                tech("Dash CS", "Balanced", {{Enum.KeyCode.Q, 0.06}, {Enum.KeyCode.One, 0.18}}, {maxDistance = 14}),
                tech("Groundslam", "Burst", {{Enum.KeyCode.Two, 0.18}}, {maxDistance = 11}),
                tech("Divergent BF", "Pressure", {{Enum.KeyCode.Three, 0.08}, {Enum.KeyCode.Three, 0.15}}, {maxDistance = 9, cooldown = 2.2}),
                tech("M1 Crush", "Balanced", {{"m1", 0.04}, {"m1", 0.04}, {Enum.KeyCode.Two, 0.18}}, {maxDistance = 9}),
                tech("Aerial Dash", "Burst", {{Enum.KeyCode.Space, 0.05}, {Enum.KeyCode.Q, 0.06}, {Enum.KeyCode.One, 0.18}}, {maxDistance = 15, cooldown = 2.4}),
            },
        },
        honored_one = {
            displayName = "Honored One",
            aliases = {"Honored"},
            free = true,
            moves = copyMoves(),
            techs = {
                tech("Blue Red", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.16}}),
                tech("Rapid Red", "Pressure", {{Enum.KeyCode.Two, 0.12}, {Enum.KeyCode.Three, 0.16}}, {maxDistance = 12}),
                tech("Purple Burst", "Burst", {{Enum.KeyCode.One, 0.08}, {Enum.KeyCode.Two, 0.08}, {Enum.KeyCode.Three, 0.18}}, {cooldown = 2.8, maxDistance = 15}),
            },
        },
        restless_gambler = {
            displayName = "Restless Gambler",
            aliases = {"Gambler"},
            free = true,
            moves = copyMoves(),
            techs = {
                tech("Reserve Doors", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.16}}),
                tech("Doors Rough", "Pressure", {{Enum.KeyCode.Two, 0.12}, {Enum.KeyCode.Three, 0.18}}, {maxDistance = 11}),
                tech("Fever", "Burst", {{Enum.KeyCode.Four, 0.16}}, {cooldown = 2.5, maxDistance = 9}),
            },
        },
        ten_shadows = {
            displayName = "Ten Shadows",
            free = true,
            moves = copyMoves(),
            techs = {
                tech("Nue Dog", "Balanced", {{Enum.KeyCode.Two, 0.12}, {Enum.KeyCode.Four, 0.18}}, {maxDistance = 14}),
                tech("Toad Slam", "Pressure", {{Enum.KeyCode.Three, 0.18}}, {maxDistance = 11}),
                tech("Shadow Dog", "Burst", {{Enum.KeyCode.R, 0.08}, {Enum.KeyCode.Four, 0.15}}, {cooldown = 2.4, maxDistance = 12}),
            },
        },
        perfection = {
            displayName = "Perfection",
            free = true,
            moves = copyMoves(),
            techs = {
                tech("Stockpile Fire", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Body Repel", "Pressure", {{Enum.KeyCode.Four, 0.15}}, {maxDistance = 10}),
                tech("Focus Repel", "Burst", {{Enum.KeyCode.Three, 0.12}, {Enum.KeyCode.Four, 0.15}}, {cooldown = 2.3, maxDistance = 11}),
            },
        },
        blood_manipulator = {
            displayName = "Blood Manipulator",
            moves = copyMoves(),
            techs = {
                tech("Pierce Scale", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.16}}),
                tech("Supernova", "Burst", {{Enum.KeyCode.Three, 0.18}}, {cooldown = 2.7, maxDistance = 13}),
                tech("Edge Convergence", "Pressure", {{Enum.KeyCode.Four, 0.1}, {Enum.KeyCode.R, 0.12}}, {maxDistance = 11}),
            },
        },
        switcher = {
            displayName = "Switcher",
            moves = copyMoves(),
            techs = {
                tech("Swap Kick", "Balanced", {{Enum.KeyCode.R, 0.08}, {Enum.KeyCode.One, 0.15}}),
                tech("Brute Elbow", "Pressure", {{Enum.KeyCode.Two, 0.12}, {Enum.KeyCode.Four, 0.18}}, {maxDistance = 10}),
                tech("Pebble Kick", "Burst", {{Enum.KeyCode.Three, 0.08}, {Enum.KeyCode.One, 0.15}}, {maxDistance = 12}),
            },
        },
        defense_attorney = {
            displayName = "Defense Attorney",
            moves = copyMoves(),
            techs = {
                tech("Swings Justice", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Reach Charges", "Pressure", {{Enum.KeyCode.Three, 0.12}, {Enum.KeyCode.Four, 0.18}}, {maxDistance = 11}),
            },
        },
        cursed_partners = {
            displayName = "Cursed Partners",
            moves = copyMoves(),
            techs = {
                tech("Sever Slash", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Veilstep Revolve", "Pressure", {{Enum.KeyCode.Three, 0.1}, {Enum.KeyCode.Four, 0.15}}, {maxDistance = 12}),
                tech("Rika Slam", "Burst", {{Enum.KeyCode.R, 0.08}, {Enum.KeyCode.One, 0.15}}, {cooldown = 2.5, maxDistance = 10}),
            },
        },
        puppet_master = {
            displayName = "Puppet Master",
            moves = copyMoves(),
            techs = {
                tech("Spin Boost", "Balanced", {{Enum.KeyCode.One, 0.1}, {Enum.KeyCode.Two, 0.15}}),
                tech("Cannon Heat", "Burst", {{Enum.KeyCode.Three, 0.12}, {Enum.KeyCode.Four, 0.18}}, {cooldown = 2.4, maxDistance = 13}),
            },
        },
        head_of_the_hei = {
            displayName = "Head of the Hei",
            moves = copyMoves(),
            techs = {
                tech("Break Bleed", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Decisive Impact", "Pressure", {{Enum.KeyCode.Three, 0.1}, {Enum.KeyCode.Four, 0.15}}, {maxDistance = 10}),
            },
        },
        salaryman = {
            displayName = "Salaryman",
            moves = copyMoves(),
            techs = {
                tech("Whirlwind Sever", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Blunt Stab", "Pressure", {{Enum.KeyCode.Three, 0.12}, {Enum.KeyCode.Four, 0.15}}, {maxDistance = 11}),
            },
        },
        disaster_plants = {
            displayName = "Disaster Plants",
            moves = copyMoves(),
            techs = {
                tech("Root Thorns", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Bud Defense", "Pressure", {{Enum.KeyCode.Three, 0.12}, {Enum.KeyCode.Four, 0.15}}, {maxDistance = 12}),
            },
        },
        true_cannon = {
            displayName = "True Cannon",
            moves = copyMoves(),
            techs = {
                tech("Granite Unsat", "Burst", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}, {cooldown = 2.4, maxDistance = 15}),
            },
        },
        locust_guy = {
            displayName = "Locust Guy",
            moves = copyMoves(),
            techs = {
                tech("Clever Mucus", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
            },
        },
        star_rage = {
            displayName = "Star Rage",
            moves = copyMoves(),
            techs = {
                tech("Garuda Rising", "Burst", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}, {cooldown = 2.3, maxDistance = 13}),
            },
        },
        aspiring_mangaka = {
            displayName = "Aspiring Mangaka",
            moves = copyMoves(),
            techs = {
                tech("Despair Shut", "Burst", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}, {cooldown = 2.6, maxDistance = 12}),
            },
        },
        lucky_coward = {
            displayName = "Lucky Coward",
            moves = copyMoves(),
            techs = {
                tech("Ambush Stab", "Balanced", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}),
                tech("Ankle Help", "Pressure", {{Enum.KeyCode.R, 0.06}, {Enum.KeyCode.One, 0.15}}, {maxDistance = 9}),
            },
        },
        crow_charmer = {
            displayName = "Crow Charmer",
            moves = copyMoves(),
            techs = {
                tech("Updraft Circle", "Burst", {{Enum.KeyCode.One, 0.12}, {Enum.KeyCode.Two, 0.18}}, {cooldown = 2.4, maxDistance = 13}),
            },
        },
    }
end)()

-- ========== INLINE TIER CONFIGS ==========
local TierConfigs = (function()
    return {
        FREE = {
            Name = "Money/Free Hub",
            LoadingTitle = "Money/Free Hub",
            LoadingSubtitle = "Mega Free",
            Version = "Free v15.3",
            Theme = "Ocean",
            CharacterIds = {
                "vessel", "honored_one", "restless_gambler", "ten_shadows", "perfection",
                "blood_manipulator", "switcher", "defense_attorney", "cursed_partners",
                "puppet_master", "head_of_the_hei", "salaryman", "disaster_plants",
                "true_cannon", "locust_guy", "star_rage", "aspiring_mangaka",
                "lucky_coward", "crow_charmer",
            },
            Flags = {
                advancedDefense = false, techPicker = false, techPreview = false,
                comboPresets = false, crosshairLock = true, manualPlayerLock = false,
                autoLockOnDamage = true, ignoreOthers = true, lockCamera = true,
                autoUlt = false, externalLoaders = false, viewPlayer = false,
                statsPanel = true, analytics = false, configSaving = false,
                loaderStatus = false, changeLog = false, targetHud = true,
                liveTargetPanel = false, helpPanel = true, presets = true,
                fly = true, infiniteJump = true, noclip = false,
                antiRagdoll = false, serverTools = false,
            },
            DefaultSettings = {
                Speed = 24, AttackDelay = 0.11, AttackRange = 9,
                PreferredDistance = 6, AutoTechs = true, TechInterval = 0.09,
                EnableDash = true, DashDistanceThreshold = 16, MovementMode = "Pro",
                JumpyIntensity = 0.6, MovePredict = 0.12, AutoJump = true,
                JumpCooldown = 0.85, JumpPower = 30, ESP = false,
                RainbowESP = false, LockOnIcon = true, TargetHud = true,
                EnableNativeBlock = true, BlockDistance = 12, BlockConfirmWindow = 0.2,
                AutoCounter = true, CounterKey = Enum.KeyCode.R,
                UseTBOBlockCounter = true, EnableBlackFlash = true,
                BFCooldownTime = 4, BlackFlashDelay = 0.12, FlySpeed = 65,
                InfiniteJump = false, LockMode = "Nearest", LockCamera = false,
                LockSmoothness = 0.28, IgnoreOthers = true, AutoLockOnDamage = true,
                LockKey = Enum.KeyCode.L, PanicKey = Enum.KeyCode.RightBracket,
                HideKey = Enum.KeyCode.RightShift,
            },
            MovementModes = {"Straight", "Jumpy", "Pro"},
        },
        PAID = {
            Name = "Money/Paid Hub",
            LoadingTitle = "Money/Paid Hub",
            LoadingSubtitle = "Depth + Coverage",
            Version = "Paid v15.2",
            Theme = "Amethyst",
            CharacterIds = {
                "vessel", "honored_one", "restless_gambler", "ten_shadows", "perfection",
                "blood_manipulator", "switcher", "defense_attorney", "cursed_partners",
                "puppet_master", "head_of_the_hei", "salaryman", "disaster_plants",
                "true_cannon", "locust_guy", "star_rage", "aspiring_mangaka",
                "lucky_coward", "crow_charmer",
            },
            Flags = {
                advancedDefense = true, techPicker = true, techPreview = true,
                comboPresets = true, crosshairLock = true, manualPlayerLock = true,
                autoLockOnDamage = true, ignoreOthers = true, lockCamera = true,
                autoUlt = true, externalLoaders = true, viewPlayer = true,
                statsPanel = true, analytics = true, configSaving = true,
                loaderStatus = true, changeLog = true, targetHud = true,
                liveTargetPanel = true, helpPanel = true, presets = true,
                fly = true, infiniteJump = true, noclip = true,
                antiRagdoll = true, serverTools = true,
            },
            DefaultSettings = {
                Speed = 24, AttackDelay = 0.06, AttackRange = 11,
                PreferredDistance = 4, AutoTechs = true, TechInterval = 0.05,
                EnableDash = true, DashDistanceThreshold = 14, DashAggro = 1.3,
                MovementMode = "Kimbaap", JumpyIntensity = 0.45, MovePredict = 0.18,
                AutoJump = true, JumpCooldown = 0.65, JumpPower = 32,
                StrafeAmplitude = 4, StrafeFrequency = 5.5, ESP = false,
                RainbowESP = false, ShowLockedTarget = true, ShowTargetHealth = true,
                LockOnIcon = true, TargetHud = true, EnableNativeBlock = true,
                BlockDistance = 13, BlockConfirmWindow = 0.18, AutoCounter = true,
                CounterKey = Enum.KeyCode.R, AutoDodgeHeavy = false, AutoFeint = true,
                ParryMode = true, EnableBlackFlash = true, BFCooldownTime = 4,
                BFChainReps = 4, BlackFlashDelay = 0.1, UseExternalBF = false,
                UseTBOBlockCounter = false, LockMode = "Nearest", LockCamera = true,
                LockSmoothness = 0.35, LockKey = Enum.KeyCode.L, IgnoreOthers = true,
                AutoLockOnDamage = true, AutoUlt = false, UltEnemyThreshold = 0.55,
                UltSelfThreshold = 0.35, UltCooldown = 2.5, FlySpeed = 75,
                InfiniteJump = false, NoClip = false, AntiRagdoll = false,
                PanicKey = Enum.KeyCode.RightBracket, HideKey = Enum.KeyCode.RightShift,
            },
            MovementModes = {"Kimbaap", "Circle", "Orbital", "Pro", "Aggro", "Straight", "Jumpy"},
        },
    }
end)()

-- ========== STORE IN SHARED STATE ==========
local sharedState = (getgenv and getgenv()) or _G
sharedState.__MoneyHubCharacters = CharacterRegistry
sharedState.__MoneyHubTiers = TierConfigs

-- ========== MONEYHUB SHARED CORE ==========
local MoneyHubShared = (function()
    local sharedState = (getgenv and getgenv()) or _G

    local MoneyHubShared = sharedState.__MoneyHubShared or {}
    local CharacterRegistry = sharedState.__MoneyHubCharacters
    local TierConfig = sharedState.__MoneyHubTiers

    -- Ensure registry data exists
    if type(CharacterRegistry) ~= "table" or type(TierConfig) ~= "table" then
        error("MoneyHub: Character registry or tier config missing.")
    end

    MoneyHubShared.CharacterRegistry = CharacterRegistry
    MoneyHubShared.TierConfig = TierConfig
    MoneyHubShared.FeatureFlags = {
        advancedDefense = true, techPicker = true, techPreview = true,
        comboPresets = true, crosshairLock = true, manualPlayerLock = true,
        autoLockOnDamage = true, ignoreOthers = true, lockCamera = true,
        autoUlt = true, externalLoaders = true, viewPlayer = true,
        statsPanel = true, analytics = true, configSaving = true,
        loaderStatus = true, changeLog = true, targetHud = true,
        liveTargetPanel = true, helpPanel = true, presets = true,
        fly = true, infiniteJump = true, noclip = true,
        antiRagdoll = true, serverTools = true,
    }

    local DIFFICULTY_PROFILES = {
        Noob = {attack = 0.4, tech = 4.8, dash = 2.4, techChance = 0.35, blockChance = 0.35, feintChance = 0.05, dodgeChance = 0.05, m1count = 2},
        Pro = {attack = 0.22, tech = 3.0, dash = 1.9, techChance = 0.55, blockChance = 0.55, feintChance = 0.15, dodgeChance = 0.12, m1count = 3},
        Good = {attack = 0.14, tech = 2.2, dash = 1.5, techChance = 0.78, blockChance = 0.75, feintChance = 0.28, dodgeChance = 0.22, m1count = 3},
        Expert = {attack = 0.08, tech = 1.4, dash = 1.2, techChance = 0.94, blockChance = 0.92, feintChance = 0.42, dodgeChance = 0.35, m1count = 3},
    }

    local FREE_PRESETS = {
        Aggressive = {
            MovementMode = "Straight", PreferredDistance = 4, DashDistanceThreshold = 10,
            AttackDelay = 0.08, Speed = 28,
        },
        Balanced = {
            MovementMode = "Pro", PreferredDistance = 6, DashDistanceThreshold = 16,
            AttackDelay = 0.11, Speed = 24,
        },
        Safe = {
            MovementMode = "Jumpy", PreferredDistance = 7.5, DashDistanceThreshold = 18,
            AttackDelay = 0.13, Speed = 22, JumpyIntensity = 0.82,
        },
    }

    local PAID_CONFIG_PRESETS = {
        ["1v1"] = {
            MovementMode = "Kimbaap", PreferredDistance = 3.8, AttackDelay = 0.05,
            DashDistanceThreshold = 12, AutoUlt = false, IgnoreOthers = true,
        },
        Public = {
            MovementMode = "Pro", PreferredDistance = 5.2, AttackDelay = 0.07,
            DashDistanceThreshold = 14, AutoUlt = false, IgnoreOthers = false,
        },
        Safe = {
            MovementMode = "Orbital", PreferredDistance = 6.5, AttackDelay = 0.1,
            DashDistanceThreshold = 16, AutoUlt = true, IgnoreOthers = true,
        },
        Rage = {
            MovementMode = "Aggro", PreferredDistance = 2.8, AttackDelay = 0.04,
            DashDistanceThreshold = 10, AutoUlt = true, IgnoreOthers = true,
        },
    }

    local ATTACK_KEYWORDS = {
        "attack", "punch", "hit", "swing", "strike", "slam", "kick",
        "upper", "combo", "m1", "slash", "crush", "purple", "red",
        "blue", "divergent", "flash", "rough", "stab",
    }

    local HEAVY_KEYWORDS = {
        "supernova", "purple", "hollow", "domain", "ultimate", "world", "granite",
    }

    local function deepCopy(value, seen)
        if type(value) ~= "table" then return value end
        seen = seen or {}
        if seen[value] then return seen[value] end
        local copy = {}
        seen[value] = copy
        for key, child in pairs(value) do
            copy[deepCopy(key, seen)] = deepCopy(child, seen)
        end
        return copy
    end

    local function mergeInto(target, source)
        for key, value in pairs(source) do
            if type(value) == "table" and type(target[key]) == "table" then
                mergeInto(target[key], value)
            else
                target[key] = deepCopy(value)
            end
        end
        return target
    end

    local function normalizeString(value)
        return type(value) == "string" and string.lower(value) or ""
    end

    local function loadRayfield()
        local urls = {
            "https://sirius.menu/rayfield",
            "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
            "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
        }

        for _, url in ipairs(urls) do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(url))()
            end)
            if success and result then
                return result
            end
        end

        return nil
    end

    local function buildCharacterDisplayLists(characterIds)
        local options, lookup = {}, {}
        for _, id in ipairs(characterIds) do
            local entry = CharacterRegistry[id]
            if entry then
                table.insert(options, entry.displayName)
                lookup[entry.displayName] = id
            end
        end
        return options, lookup
    end

    local function getTechNames(characterId)
        local character = CharacterRegistry[characterId]
        local names = {"Random"}
        if character and character.techs then
            for _, tech in ipairs(character.techs) do
                table.insert(names, tech.name)
            end
        end
        return names
    end

    local function findTechByName(characterId, techName)
        local character = CharacterRegistry[characterId]
        if not character or not character.techs then return nil end
        for _, tech in ipairs(character.techs) do
            if tech.name == techName then return tech end
        end
        return nil
    end

    function MoneyHubShared.launch(tierName)
        if type(sharedState.__MoneyHubCleanup) == "function" then
            pcall(sharedState.__MoneyHubCleanup)
        end

        local tier = TierConfig[tierName]
        if not tier then
            error("Unknown MoneyHub tier: " .. tostring(tierName))
        end

        -- Load Rayfield with better feedback
        local Rayfield = loadRayfield()
        if not Rayfield then
            warn("MoneyHub: Failed to load Rayfield UI library.")
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "MoneyHub",
                    Text = "UI library failed to load. Check your internet or executor.",
                    Duration = 5,
                })
            end)
            return nil
        end

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local StarterGui = game:GetService("StarterGui")
        local CoreGui = game:GetService("CoreGui")
        local Workspace = game:GetService("Workspace")
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local Lighting = game:GetService("Lighting")
        local LocalPlayer = Players.LocalPlayer
        local Camera = Workspace.CurrentCamera

        local connections = {}
        local playerConnections = {}
        local espObjects = {}
        local overlayGui
        local targetHudLabel
        local statusHudLabel
        local lockBillboard
        local flyVelocity, flyGyro, flyLoop
        local noclipConnection
        local viewDropdown, techDropdown, characterDropdown
        local rayfieldWindow
        local externalBFFunctions = {}
        local namedProfiles
        local currentLockQuery = ""
        local currentViewQuery = ""

        local loaderState = {
            Rayfield = "Loaded",
            TBO = "Idle",
            ExternalBF = "Idle",
        }

        local state = {
            TierName = tierName,
            Version = tier.Version,
            Enabled = false,
            Destroyed = false,
            Hidden = false,
            ChainActive = false,
            FlyEnabled = false,
            FlyMovement = {W = false, A = false, S = false, D = false, Up = false, Down = false},
            SelectedCharId = tier.CharacterIds[1],
            SelectedTech = "Random",
            SelectedPreset = "Balanced",
            Difficulty = "Expert",
            Target = nil,
            LockedTarget = nil,
            LockHard = false,
            LastLockSource = "Nearest",
            LastAttack = 0,
            LastDash = 0,
            LastJump = 0,
            LastTechAt = 0,
            LastBF = 0,
            LastUlt = 0,
            LastBlockAt = 0,
            LastCounterAt = 0,
            LastDodge = 0,
            LastFeint = 0,
            LastDamageHealth = 0,
            LastDamageTarget = nil,
            LastMovePos = Vector3.zero,
            StuckSince = 0,
            M1ComboCount = 0,
            ComboStep = 0,
            LastTargetUpdate = 0,
            Viewing = nil,
            TargetDistance = 0,
            LastTechName = "None",
            TechUsageCounts = {},
            Kills = 0,
            Deaths = 0,
            KillStreak = 0,
            BestStreak = 0,
            TotalDamageDealt = 0,
            TotalDamageTaken = 0,
            HitCount = 0,
            MissCount = 0,
            SessionStart = tick(),
            HasSpawned = false,
            AutoBlockHeld = false,
            StatusText = "",
        }

        state.Settings = deepCopy(tier.DefaultSettings)

        local function track(connection)
            table.insert(connections, connection)
            return connection
        end

        local function disconnectList(list)
            for _, conn in ipairs(list) do
                if conn and conn.Connected then conn:Disconnect() end
            end
        end

        local function safeDestroy(instance)
            if instance then pcall(function() instance:Destroy() end) end
        end

        local function notify(title, text, duration)
            pcall(function()
                Rayfield:Notify({
                    Title = title,
                    Content = text,
                    Duration = duration or 3,
                })
            end)
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = title,
                    Text = text,
                    Duration = duration or 3,
                })
            end)
        end

        local function getGuiParent()
            local parent = LocalPlayer:WaitForChild("PlayerGui")
            pcall(function()
                parent = gethui and gethui() or CoreGui
            end)
            return parent
        end

        local function removeExistingGui(name)
            for _, container in ipairs({CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}) do
                if container then
                    local existing = container:FindFirstChild(name)
                    if existing then existing:Destroy() end
                end
            end
            pcall(function()
                if gethui then
                    local existing = gethui():FindFirstChild(name)
                    if existing then existing:Destroy() end
                end
            end)
        end

        local function getChar(player)
            player = player or LocalPlayer
            return player and player.Character
        end

        local function getHumanoid(subject)
            local char = subject
            if typeof(subject) == "Instance" and subject:IsA("Player") then
                char = subject.Character
            end
            return char and char:FindFirstChildOfClass("Humanoid")
        end

        local function getRoot(subject)
            local char = subject
            if typeof(subject) == "Instance" and subject:IsA("Player") then
                char = subject.Character
            end
            return char and char:FindFirstChild("HumanoidRootPart")
        end

        local function getHead(subject)
            local char = subject
            if typeof(subject) == "Instance" and subject:IsA("Player") then
                char = subject.Character
            end
            return char and char:FindFirstChild("Head")
        end

        local function currentCharacter()
            return CharacterRegistry[state.SelectedCharId]
        end

        local function currentMoves()
            local char = currentCharacter()
            return char and char.moves
        end

        local function getProfile()
            return DIFFICULTY_PROFILES[state.Difficulty] or DIFFICULTY_PROFILES.Expert
        end

        local function applyDifficulty(name)
            state.Difficulty = name
            local profile = getProfile()
            state.Settings.AttackDelay = profile.attack
            state.Settings.TechInterval = profile.tech
        end

        local function tapKey(keyCode, holdLength)
            if not keyCode then return end
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(holdLength or 0.05)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end

        local function clickMouse()
            local pos = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end

        local function setBlockHeld(shouldHold)
            if state.AutoBlockHeld == shouldHold then return end
            state.AutoBlockHeld = shouldHold
            state.LastBlockAt = tick()
            VirtualInputManager:SendKeyEvent(shouldHold, Enum.KeyCode.F, false, game)
        end

        local function getPing()
            local ping = 80
            pcall(function()
                ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            return ping
        end

        local function isEnemy(player)
            if not player or player == LocalPlayer then return false end
            local hum = getHumanoid(player)
            local root = getRoot(player)
            return hum and root and hum.Health > 0
        end

        local function getNearest(range)
            local myRoot = getRoot(LocalPlayer)
            if not myRoot then return nil end
            local bestPlayer, bestDist = nil, range or math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if isEnemy(player) then
                    local root = getRoot(player)
                    if root then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            bestPlayer = player
                        end
                    end
                end
            end
            return bestPlayer, bestDist
        end

        local function getCrosshairTarget(range)
            local myRoot = getRoot(LocalPlayer)
            Camera = Workspace.CurrentCamera or Camera
            if not myRoot or not Camera then return nil end
            local center = Camera.ViewportSize / 2
            local bestPlayer, bestScore = nil, math.huge
            local maxRange = range or 300
            for _, player in ipairs(Players:GetPlayers()) do
                if isEnemy(player) then
                    local root = getRoot(player)
                    if root then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        if dist <= maxRange then
                            local screen, onScreen = Camera:WorldToViewportPoint(root.Position)
                            if onScreen then
                                local offset = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                                local score = offset + (dist * 0.5)
                                if score < bestScore then
                                    bestScore = score
                                    bestPlayer = player
                                end
                            end
                        end
                    end
                end
            end
            return bestPlayer
        end

        local function findPlayerByQuery(query)
            query = normalizeString(query):gsub("^@", "")
            if query == "" then return nil end
            local asNumber = tonumber(query)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    if asNumber and player.UserId == asNumber then return player end
                    if normalizeString(player.Name) == query or normalizeString(player.DisplayName) == query then return player end
                    if string.find(normalizeString(player.Name), query, 1, true) then return player end
                    if string.find(normalizeString(player.DisplayName), query, 1, true) then return player end
                end
            end
            return nil
        end

        local function clearLockBillboard()
            if lockBillboard then lockBillboard.Enabled = false end
        end

        local function updateLockBillboard(target)
            if not state.Settings.LockOnIcon then clearLockBillboard(); return end
            if not target or not isEnemy(target) then clearLockBillboard(); return end
            local root = getRoot(target)
            if not root then clearLockBillboard(); return end

            if not lockBillboard then
                lockBillboard = Instance.new("BillboardGui")
                lockBillboard.Name = "MoneyHubLockBillboard"
                lockBillboard.Size = UDim2.fromOffset(88, 88)
                lockBillboard.AlwaysOnTop = true
                lockBillboard.StudsOffset = Vector3.new(0, 3.8, 0)

                local accent = Color3.fromRGB(255, 220, 84)

                local function addSegment(name, size, pos)
                    local seg = Instance.new("Frame")
                    seg.Name = name
                    seg.BorderSizePixel = 0
                    seg.BackgroundColor3 = accent
                    seg.Size = size
                    seg.Position = pos
                    seg.Parent = lockBillboard
                end

                addSegment("TLH", UDim2.fromOffset(22, 4), UDim2.new(0, 0, 0, 0))
                addSegment("TLV", UDim2.fromOffset(4, 22), UDim2.new(0, 0, 0, 0))
                addSegment("TRH", UDim2.fromOffset(22, 4), UDim2.new(1, -22, 0, 0))
                addSegment("TRV", UDim2.fromOffset(4, 22), UDim2.new(1, -4, 0, 0))
                addSegment("BLH", UDim2.fromOffset(22, 4), UDim2.new(0, 0, 1, -4))
                addSegment("BLV", UDim2.fromOffset(4, 22), UDim2.new(0, 0, 1, -22))
                addSegment("BRH", UDim2.fromOffset(22, 4), UDim2.new(1, -22, 1, -4))
                addSegment("BRV", UDim2.fromOffset(4, 22), UDim2.new(1, -4, 1, -22))

                local dot = Instance.new("Frame")
                dot.Name = "CenterDot"
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                dot.Position = UDim2.new(0.5, 0, 0.5, -6)
                dot.Size = UDim2.fromOffset(10, 10)
                dot.Rotation = 45
                dot.BorderSizePixel = 0
                dot.BackgroundColor3 = accent
                dot.Parent = lockBillboard
                Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 2)

                local text = Instance.new("TextLabel")
                text.Name = "Text"
                text.AnchorPoint = Vector2.new(0.5, 1)
                text.Position = UDim2.new(0.5, 0, 1, 0)
                text.Size = UDim2.fromOffset(88, 22)
                text.BackgroundTransparency = 1
                text.TextScaled = true
                text.TextStrokeTransparency = 0
                text.Font = Enum.Font.GothamBold
                text.TextColor3 = accent
                text.Text = "LOCK"
                text.Parent = lockBillboard

                lockBillboard.Parent = overlayGui or getGuiParent()
            end

            lockBillboard.Parent = root
            lockBillboard.Enabled = true
        end

        local function ensureOverlay()
            if overlayGui then return end
            removeExistingGui("MoneyHubOverlay")

            overlayGui = Instance.new("ScreenGui")
            overlayGui.Name = "MoneyHubOverlay"
            overlayGui.ResetOnSpawn = false
            overlayGui.IgnoreGuiInset = true
            overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            pcall(function() if syn and syn.protect_gui then syn.protect_gui(overlayGui) end end)
            overlayGui.Parent = getGuiParent()

            local hudFrame = Instance.new("Frame")
            hudFrame.Name = "TargetHud"
            hudFrame.AnchorPoint = Vector2.new(0, 1)
            hudFrame.Position = UDim2.new(0, 16, 1, -16)
            hudFrame.Size = UDim2.fromOffset(tier.Flags.liveTargetPanel and 340 or 280, tier.Flags.liveTargetPanel and 112 or 72)
            hudFrame.BackgroundColor3 = Color3.fromRGB(19, 27, 39)
            hudFrame.BackgroundTransparency = 0.12
            hudFrame.BorderSizePixel = 0
            hudFrame.Parent = overlayGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 16)
            corner.Parent = hudFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(73, 98, 129)
            stroke.Thickness = 1
            stroke.Parent = hudFrame

            targetHudLabel = Instance.new("TextLabel")
            targetHudLabel.BackgroundTransparency = 1
            targetHudLabel.Position = UDim2.fromOffset(12, 10)
            targetHudLabel.Size = UDim2.new(1, -24, 1, -20)
            targetHudLabel.Font = Enum.Font.GothamSemibold
            targetHudLabel.TextSize = 14
            targetHudLabel.TextWrapped = true
            targetHudLabel.TextXAlignment = Enum.TextXAlignment.Left
            targetHudLabel.TextYAlignment = Enum.TextYAlignment.Top
            targetHudLabel.TextColor3 = Color3.fromRGB(243, 247, 255)
            targetHudLabel.Text = tier.Name .. "\nWaiting for target..."
            targetHudLabel.Parent = hudFrame

            if tier.Flags.liveTargetPanel then
                local statusFrame = Instance.new("Frame")
                statusFrame.Name = "StatusHud"
                statusFrame.AnchorPoint = Vector2.new(1, 0)
                statusFrame.Position = UDim2.new(1, -16, 0, 16)
                statusFrame.Size = UDim2.fromOffset(350, 150)
                statusFrame.BackgroundColor3 = Color3.fromRGB(19, 27, 39)
                statusFrame.BackgroundTransparency = 0.12
                statusFrame.BorderSizePixel = 0
                statusFrame.Parent = overlayGui

                local sc = Instance.new("UICorner")
                sc.CornerRadius = UDim.new(0, 16)
                sc.Parent = statusFrame

                local ss = Instance.new("UIStroke")
                ss.Color = Color3.fromRGB(111, 92, 156)
                ss.Thickness = 1
                ss.Parent = statusFrame

                statusHudLabel = Instance.new("TextLabel")
                statusHudLabel.BackgroundTransparency = 1
                statusHudLabel.Position = UDim2.fromOffset(12, 10)
                statusHudLabel.Size = UDim2.new(1, -24, 1, -20)
                statusHudLabel.Font = Enum.Font.Code
                statusHudLabel.TextSize = 13
                statusHudLabel.TextWrapped = true
                statusHudLabel.TextXAlignment = Enum.TextXAlignment.Left
                statusHudLabel.TextYAlignment = Enum.TextYAlignment.Top
                statusHudLabel.TextColor3 = Color3.fromRGB(243, 247, 255)
                statusHudLabel.Text = "Status panel ready."
                statusHudLabel.Parent = statusFrame
            end
        end

        local function clearESP(player)
            local bucket = espObjects[player]
            if bucket then
                for _, obj in ipairs(bucket) do safeDestroy(obj) end
                espObjects[player] = nil
            end
        end

        local function updateESPEntry(player)
            if not player or player == LocalPlayer then return end
            local shouldShow = state.Settings.ESP and isEnemy(player)
            local isLocked = player == state.LockedTarget
            if not shouldShow and not (tier.Flags.lockCamera and state.Settings.ShowLockedTarget and isLocked) then
                clearESP(player)
                return
            end

            local char = getChar(player)
            local root = getRoot(char)
            local head = getHead(char) or root
            if not char or not root or not head then clearESP(player); return end

            local bucket = espObjects[player]
            if not bucket then
                local highlight = Instance.new("Highlight")
                highlight.Name = "MoneyHubESP"
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = char

                local tag = Instance.new("BillboardGui")
                tag.Name = "MoneyHubESPTag"
                tag.Adornee = head
                tag.AlwaysOnTop = true
                tag.LightInfluence = 0
                tag.MaxDistance = 1200
                tag.Size = UDim2.fromOffset(200, tier.Flags.liveTargetPanel and 44 or 34)
                tag.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
                tag.Parent = char

                local label = Instance.new("TextLabel")
                label.Name = "Text"
                label.BackgroundTransparency = 1
                label.Size = UDim2.fromScale(1, 1)
                label.Font = Enum.Font.GothamSemibold
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextStrokeTransparency = 0.18
                label.TextWrapped = true
                label.TextSize = 14
                label.Parent = tag

                bucket = {highlight, tag}
                espObjects[player] = bucket
            end

            local highlight, tag = bucket[1], bucket[2]
            if highlight.Parent ~= char then highlight.Parent = char end
            if tag.Parent ~= char then tag.Parent = char; tag.Adornee = head end

            local fillColor = isLocked and state.Settings.ShowLockedTarget and Color3.fromRGB(255, 214, 74)
                or state.Settings.RainbowESP and Color3.fromHSV((tick() % 5) / 5, 1, 1)
                or Color3.fromRGB(255, 78, 78)

            highlight.FillColor = fillColor
            highlight.FillTransparency = isLocked and 0.28 or 0.55
            highlight.OutlineColor = isLocked and Color3.fromRGB(255, 241, 164) or Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0

            local label = tag:FindFirstChild("Text")
            if label then
                local text = string.format("%s (@%s)", player.DisplayName, player.Name)
                if tier.Flags.liveTargetPanel and state.Settings.ShowTargetHealth then
                    local hum = getHumanoid(player)
                    local myRoot = getRoot(LocalPlayer)
                    if hum and myRoot and root then
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        text = string.format("%s\nHP %d/%d | %dm", text, hum.Health, hum.MaxHealth, dist)
                    end
                end
                if isLocked then text = text .. "\n[LOCKED]" end
                label.Text = text
            end
        end

        local function refreshESP()
            for _, player in ipairs(Players:GetPlayers()) do
                updateESPEntry(player)
            end
        end

        local function getFavoriteTech()
            local bestName, bestCount = "None", 0
            for name, count in pairs(state.TechUsageCounts) do
                if count > bestCount then bestName, bestCount = name, count end
            end
            return bestName, bestCount
        end

        local function updateTargetHud()
            ensureOverlay()
            if not targetHudLabel then return end
            local target = state.Target
            if not state.Settings.TargetHud then
                targetHudLabel.Text = tier.Name .. "\nHUD hidden."
                return
            end

            local lockText = state.LockHard and "Hard" or "Soft"
            if target and isEnemy(target) then
                local hum = getHumanoid(target)
                local root = getRoot(target)
                local myRoot = getRoot(LocalPlayer)
                local hpText = hum and string.format(" | HP %d/%d", hum.Health, hum.MaxHealth) or ""
                if root and myRoot then state.TargetDistance = (myRoot.Position - root.Position).Magnitude end
                targetHudLabel.Text = string.format(
                    "%s  |  %s\nTarget: %s  |  %.1fm%s\nLock: %s (%s)  |  Tech: %s",
                    tier.Version,
                    state.Enabled and "AI ON" or "AI OFF",
                    target.DisplayName,
                    state.TargetDistance,
                    hpText,
                    lockText,
                    state.LastLockSource,
                    state.LastTechName
                )
            elseif state.LockHard and state.LockedTarget and state.LockedTarget.Parent then
                targetHudLabel.Text = string.format(
                    "%s  |  %s\nLocked: %s\nStatus: Waiting for respawn / reacquire\nMode: %s  |  Preset: %s",
                    tier.Version,
                    state.Enabled and "AI ON" or "AI OFF",
                    state.LockedTarget.DisplayName,
                    state.Settings.MovementMode or "Pro",
                    state.SelectedPreset
                )
            else
                targetHudLabel.Text = string.format(
                    "%s  |  %s\nNo target locked.\nMode: %s  |  Preset: %s",
                    tier.Version,
                    state.Enabled and "AI ON" or "AI OFF",
                    state.Settings.MovementMode or "Pro",
                    state.SelectedPreset
                )
            end
        end

        local function updateStatusHud()
            if not statusHudLabel then return end
            local favTech = getFavoriteTech()
            local uptime = math.floor(tick() - state.SessionStart)
            local target = state.Target
            local targetInfo = "No target"
            if target and isEnemy(target) then
                local hum = getHumanoid(target)
                if hum then
                    targetInfo = string.format("%s | HP %d/%d | %.1fm", target.DisplayName, hum.Health, hum.MaxHealth, state.TargetDistance)
                end
            end
            statusHudLabel.Text = table.concat({
                string.format("[%s] %s", tier.Version, state.Enabled and "ACTIVE" or "IDLE"),
                string.format("Target   : %s", targetInfo),
                string.format("Combo    : %s | %s", state.SelectedPreset, state.LastTechName),
                string.format("Cooldown : Dash %.1fs | BF %.1fs | Ult %.1fs | Block %.1fs",
                    math.max(0, 1.5 - (tick() - state.LastDash)),
                    math.max(0, state.Settings.BFCooldownTime - (tick() - state.LastBF)),
                    math.max(0, (state.Settings.UltCooldown or 2.5) - (tick() - state.LastUlt)),
                    math.max(0, state.Settings.BlockConfirmWindow - (tick() - state.LastBlockAt))
                ),
                string.format("Loaders  : Rayfield=%s | TBO=%s | BF=%s", loaderState.Rayfield, loaderState.TBO, loaderState.ExternalBF),
                string.format("Session  : K %d D %d Streak %d Best %d", state.Kills, state.Deaths, state.KillStreak, state.BestStreak),
                string.format("Damage   : Out %d | In %d | Fav %s", math.floor(state.TotalDamageDealt), math.floor(state.TotalDamageTaken), favTech),
                string.format("Accuracy : Hits %d | Miss %d | Uptime %ss", state.HitCount, state.MissCount, uptime),
            }, "\n")
        end

        local function setLockTarget(player, source, hardLock)
            if player and isEnemy(player) then
                state.LockedTarget = player
                state.Target = player
                state.LockHard = hardLock ~= false
                state.LastLockSource = source or "Nearest"
                updateLockBillboard(player)
                updateTargetHud()
                updateStatusHud()
                return true
            end
            state.LockedTarget = nil
            state.Target = nil
            state.LockHard = false
            state.LastLockSource = "Nearest"
            clearLockBillboard()
            updateTargetHud()
            updateStatusHud()
            return false
        end

        local function acquireTarget()
            local myRoot = getRoot(LocalPlayer)
            if state.LockHard and state.LockedTarget then
                if isEnemy(state.LockedTarget) then return state.LockedTarget end
                if state.LockedTarget.Parent then return nil end
                setLockTarget(nil, "Nearest", false)
                return nil
            end

            local target = tier.Flags.crosshairLock and state.Settings.LockMode == "Crosshair"
                and getCrosshairTarget(300) or getNearest(300)

            if state.Target and isEnemy(state.Target) and myRoot then
                local curRoot = getRoot(state.Target)
                if curRoot then
                    local curDist = (myRoot.Position - curRoot.Position).Magnitude
                    local nearDist = math.huge
                    if target and isEnemy(target) then
                        local tRoot = getRoot(target)
                        if tRoot then nearDist = (myRoot.Position - tRoot.Position).Magnitude end
                    end
                    if state.Target == target or curDist <= math.min(300, nearDist + 4.5) then
                        target = state.Target
                    end
                end
            end

            if state.LockHard and not target then
                setLockTarget(nil, "Nearest", false)
            end
            return target
        end

        local function viewPlayer(player)
            if not player or not isEnemy(player) then return false end
            local hum = getHumanoid(player)
            if not hum then return false end
            state.Viewing = player
            Workspace.CurrentCamera.CameraSubject = hum
            return true
        end

        local function unviewPlayer()
            state.Viewing = nil
            local hum = getHumanoid(LocalPlayer)
            if hum then Workspace.CurrentCamera.CameraSubject = hum end
        end

        local function getPlayerList()
            local list = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    table.insert(list, string.format("%s (@%s)", p.DisplayName, p.Name))
                end
            end
            table.sort(list)
            if #list == 0 then table.insert(list, "No players") end
            return list
        end

        local function detectAttackFromPlayer(player)
            local tRoot = getRoot(player)
            local tHum = getHumanoid(player)
            local myRoot = getRoot(LocalPlayer)
            if not tRoot or not tHum or not myRoot then return false, false end

            local dist = (myRoot.Position - tRoot.Position).Magnitude
            if dist > state.Settings.BlockDistance then return false, false end

            local offset = myRoot.Position - tRoot.Position
            local facing = offset.Magnitude > 0 and tRoot.CFrame.LookVector:Dot(offset.Unit) or 0
            local vel = tRoot.AssemblyLinearVelocity.Magnitude

            local heavy = false
            local actionThreat = false
            local animator = tHum:FindFirstChildOfClass("Animator")
            if animator then
                local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
                if ok and tracks then
                    for _, track in ipairs(tracks) do
                        if track and track.IsPlaying then
                            local haystack = normalizeString(track.Name)
                            if track.Animation then
                                haystack = haystack .. " " .. normalizeString(track.Animation.Name)
                                haystack = haystack .. " " .. normalizeString(track.Animation.AnimationId)
                            end
                            for _, kw in ipairs(ATTACK_KEYWORDS) do
                                if string.find(haystack, kw, 1, true) then
                                    actionThreat = true
                                    break
                                end
                            end
                            for _, kw in ipairs(HEAVY_KEYWORDS) do
                                if string.find(haystack, kw, 1, true) then
                                    heavy = true
                                    break
                                end
                            end
                        end
                    end
                end
            end

            local closeThreat = dist <= math.max(4.2, (state.Settings.BlockDistance or 12) * 0.42)
            local chargeThreat = vel >= 10 and facing >= 0.18
            local pointBlankRush = closeThreat and vel >= 5.5 and facing >= 0.25
            local shouldThreaten = (actionThreat and facing >= 0.02) or chargeThreat or pointBlankRush
            return shouldThreaten, heavy
        end

        local function findThreateningPlayer()
            local bestPlayer, bestDist = nil, math.huge
            local myRoot = getRoot(LocalPlayer)
            if not myRoot then return nil end
            for _, player in ipairs(Players:GetPlayers()) do
                if isEnemy(player) then
                    local threat = detectAttackFromPlayer(player)
                    if threat then
                        local root = getRoot(player)
                        if root then
                            local dist = (myRoot.Position - root.Position).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                bestPlayer = player
                            end
                        end
                    end
                end
            end
            return bestPlayer
        end

        local function attemptDodge()
            if tick() - state.LastDodge < 1.2 then return false end
            local moves = currentMoves()
            if not moves then return false end
            state.LastDodge = tick()
            task.spawn(function()
                tapKey(moves.dash, 0.05)
                task.wait(0.08)
                tapKey(Enum.KeyCode.Space, 0.03)
            end)
            return true
        end

        local function attemptCounter(threatPlayer, heavy)
            if not state.Settings.AutoCounter then return false end
            if tick() - state.LastCounterAt < 1.15 then return false end
            if not threatPlayer or not isEnemy(threatPlayer) then return false end
            local myRoot = getRoot(LocalPlayer)
            local threatRoot = getRoot(threatPlayer)
            if not myRoot or not threatRoot then return false end
            local dist = (myRoot.Position - threatRoot.Position).Magnitude
            local triggerDist = math.max(4.8, (state.Settings.BlockDistance or 12) * 0.5)
            if not heavy and dist > triggerDist then return false end
            local moves = currentMoves()
            local counterKey = state.Settings.CounterKey or (moves and moves.counter) or Enum.KeyCode.R
            state.LastCounterAt = tick()
            task.spawn(function() tapKey(counterKey, 0.05) end)
            return true
        end

        local function attemptFeint()
            if tick() - state.LastFeint < 0.8 then return false end
            local moves = currentMoves()
            if not moves then return false end
            state.LastFeint = tick()
            task.spawn(function() tapKey(moves.counter, 0.04) end)
            return true
        end

        local function handleAutoBlock(target)
            if not state.Settings.EnableNativeBlock then
                setBlockHeld(false)
                return false
            end
            -- TBO loading omitted for brevity, can be added back if needed
            local threatPlayer = target or findThreateningPlayer()
            if not threatPlayer then
                if state.AutoBlockHeld and tick() - state.LastBlockAt > state.Settings.BlockConfirmWindow then
                    setBlockHeld(false)
                end
                return false
            end
            local threatening, heavy = detectAttackFromPlayer(threatPlayer)
            if threatening then
                local profile = getProfile()
                attemptCounter(threatPlayer, heavy)
                if tier.Flags.advancedDefense and heavy and state.Settings.AutoDodgeHeavy and math.random() < profile.dodgeChance then
                    attemptDodge()
                    return true
                end
                if tier.Flags.advancedDefense and state.Settings.AutoFeint and math.random() < profile.feintChance then
                    attemptFeint()
                end
                if math.random() <= profile.blockChance then
                    setBlockHeld(true)
                    task.delay(state.Settings.BlockConfirmWindow, function()
                        if not state.Destroyed and tick() - state.LastBlockAt >= state.Settings.BlockConfirmWindow - 0.03 then
                            setBlockHeld(false)
                        end
                    end)
                end
                return true
            end
            if state.AutoBlockHeld and tick() - state.LastBlockAt > state.Settings.BlockConfirmWindow then
                setBlockHeld(false)
            end
            return false
        end

        local function recordTechUse(techName)
            state.LastTechName = techName
            state.TechUsageCounts[techName] = (state.TechUsageCounts[techName] or 0) + 1
        end

        local function executeSequence(seq)
            for _, action in ipairs(seq) do
                local code, delay = action[1], action[2] or 0.05
                if code == "m1" then clickMouse()
                elseif code == "space" then tapKey(Enum.KeyCode.Space, 0.03)
                else tapKey(code, 0.05) end
                task.wait(delay)
            end
        end

        local function selectTech(dist)
            local char = currentCharacter()
            if not char or not char.techs or #char.techs == 0 then return nil end
            if tick() - state.LastTechAt < state.Settings.TechInterval then return nil end
            local profile = getProfile()
            if math.random() > profile.techChance then return nil end
            if tier.Flags.techPicker and state.SelectedTech ~= "Random" then
                local chosen = findTechByName(state.SelectedCharId, state.SelectedTech)
                if chosen and dist <= (chosen.maxDistance or 13) then return chosen end
            end
            local preset = tier.Flags.comboPresets and state.SelectedPreset or nil
            local pool = {}
            for _, tech in ipairs(char.techs) do
                local inRange = dist <= (tech.maxDistance or 13)
                local presetMatch = (not preset) or tech.preset == preset
                if inRange and presetMatch then table.insert(pool, tech) end
            end
            if #pool == 0 then pool = char.techs end
            if #pool == 0 then return nil end
            return pool[math.random(1, #pool)]
        end

        local function runTechs(dist)
            if not state.Settings.AutoTechs or state.ChainActive then return false end
            local tech = selectTech(dist)
            if not tech then return false end
            state.LastTechAt = tick()
            recordTechUse(tech.name)
            task.spawn(function() executeSequence(tech.seq) end)
            return true
        end

        local function doBasicBlackFlash(dist)
            if state.SelectedCharId ~= "vessel" or dist > 8 then return false end
            if tick() - state.LastBF < state.Settings.BFCooldownTime then return false end
            local moves = currentMoves()
            state.LastBF = tick()
            task.spawn(function()
                tapKey(moves.dash, 0.05)
                task.wait(0.08)
                tapKey(moves.s3, 0.06)
                task.wait(state.Settings.BlackFlashDelay)
                tapKey(moves.s3, 0.06)
            end)
            return true
        end

        local function attemptBlackFlash(target, dist)
            if not state.Settings.EnableBlackFlash then return false end
            return doBasicBlackFlash(dist)
        end

        local function tryAutoUlt(target, dist)
            if not tier.Flags.autoUlt or not state.Settings.AutoUlt then return false end
            if tick() - state.LastUlt < (state.Settings.UltCooldown or 2.5) then return false end
            local moves = currentMoves()
            local myHum = getHumanoid(LocalPlayer)
            local tHum = getHumanoid(target)
            if not moves or not myHum or not tHum then return false end
            local myRatio = myHum.Health / math.max(1, myHum.MaxHealth)
            local tRatio = tHum.Health / math.max(1, tHum.MaxHealth)
            local shouldUlt = (tRatio <= (state.Settings.UltEnemyThreshold or 0.55) and dist <= 20)
                or (myRatio <= (state.Settings.UltSelfThreshold or 0.35) and dist <= 18)
            if not shouldUlt then return false end
            state.LastUlt = tick()
            task.spawn(function()
                tapKey(moves.ult, 0.08)
                task.wait(0.06)
                tapKey(moves.ult, 0.12)
            end)
            return true
        end

        local function updateDamageTaken()
            local hum = getHumanoid(LocalPlayer)
            if not hum or hum.Health <= 0 then state.LastDamageHealth = 0; return end
            if state.LastDamageHealth > 0 and hum.Health < state.LastDamageHealth then
                state.TotalDamageTaken = state.TotalDamageTaken + (state.LastDamageHealth - hum.Health)
                if tier.Flags.autoLockOnDamage and state.Settings.AutoLockOnDamage then
                    local attacker = findThreateningPlayer() or select(1, getNearest(30))
                    if attacker then setLockTarget(attacker, "Damage", true) end
                end
            end
            state.LastDamageHealth = hum.Health
        end

        local function updateDamageDealt(target)
            if not target or not isEnemy(target) then return end
            local hum = getHumanoid(target)
            if not hum then return end
            local prev = state.LastDamageTarget == target and sharedState.__MoneyHubLastTargetHealth or hum.Health
            if prev and hum.Health < prev then
                state.TotalDamageDealt = state.TotalDamageDealt + (prev - hum.Health)
            end
            if prev and prev > 0 and hum.Health <= 0 then
                state.Kills = state.Kills + 1
                state.KillStreak = state.KillStreak + 1
                if state.KillStreak > state.BestStreak then state.BestStreak = state.KillStreak end
            end
            sharedState.__MoneyHubLastTargetHealth = hum.Health
            state.LastDamageTarget = target
        end

        local function panicReset()
            state.Enabled = false
            state.LockHard = false
            state.LockedTarget = nil
            state.Target = nil
            state.ChainActive = false
            state.M1ComboCount = 0
            state.ComboStep = 0
            setBlockHeld(false)
            clearLockBillboard()
            notify(tier.Name, "Panic reset fired.", 2)
            updateTargetHud()
            updateStatusHud()
        end

        local function applySettingPatch(patch)
            mergeInto(state.Settings, patch)
            updateTargetHud()
            updateStatusHud()
        end

        local function applyFreePreset(name)
            local preset = FREE_PRESETS[name]
            if not preset then return end
            state.SelectedPreset = name
            applySettingPatch(preset)
            notify("Preset", name .. " applied.", 2)
        end

        local function loadNamedProfile(name)
            local store = namedProfiles or {}
            local snapshot = store[name]
            if snapshot then
                state.SelectedCharId = snapshot.SelectedCharId or state.SelectedCharId
                state.SelectedTech = snapshot.SelectedTech or state.SelectedTech
                state.SelectedPreset = snapshot.SelectedPreset or state.SelectedPreset
                applyDifficulty(snapshot.Difficulty or state.Difficulty)
                mergeInto(state.Settings, snapshot.Settings or {})
                if techDropdown then
                    pcall(function() techDropdown:Refresh(getTechNames(state.SelectedCharId), false) end)
                end
                updateTargetHud()
                updateStatusHud()
                refreshESP()
                notify("Config", "Profile loaded.", 2)
            end
        end

        local function getAttackAlignment(myRoot, targetRoot)
            local flatOff = Vector3.new(targetRoot.Position.X - myRoot.Position.X, 0, targetRoot.Position.Z - myRoot.Position.Z)
            if flatOff.Magnitude <= 0.01 then return 1 end
            local flatLook = Vector3.new(myRoot.CFrame.LookVector.X, 0, myRoot.CFrame.LookVector.Z)
            if flatLook.Magnitude <= 0.01 then return 0 end
            return flatLook.Unit:Dot(flatOff.Unit)
        end

        local function getMeleeCommitRange()
            local pref = state.Settings.PreferredDistance or 5
            local attRange = state.Settings.AttackRange or 9
            return math.min(attRange, math.max(5.6, pref + 2.15))
        end

        local function canCommitMelee(myRoot, targetRoot, dist, targetThreatening)
            if not myRoot or not targetRoot then return false end
            if math.abs(targetRoot.Position.Y - myRoot.Position.Y) > 5.25 then return false end
            local commitRange = getMeleeCommitRange()
            if dist > commitRange then return false end
            local facing = getAttackAlignment(myRoot, targetRoot)
            local required = dist > math.max(6, commitRange - 0.75) and 0.52 or 0.28
            if facing < required then return false end
            local predicted = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * 0.06)
            local predictedFlat = Vector3.new(predicted.X - myRoot.Position.X, 0, predicted.Z - myRoot.Position.Z)
            if predictedFlat.Magnitude > commitRange + 0.9 then return false end
            if targetThreatening and dist > math.max(5.6, (state.Settings.PreferredDistance or 5) + 0.75) then return false end
            return true
        end

        local function shouldTriggerAutoJump(myRoot, myHum, targetRoot, dist)
            if not state.Settings.AutoJump then return false end
            if tick() - state.LastJump < (state.Settings.JumpCooldown or 0.9) then return false end
            if myHum.FloorMaterial == Enum.Material.Air then return false end
            local heightDelta = targetRoot.Position.Y - myRoot.Position.Y
            if heightDelta > 3 and dist < 13 then return true end
            local flat = Vector3.new(targetRoot.Position.X - myRoot.Position.X, 0, targetRoot.Position.Z - myRoot.Position.Z)
            if flat.Magnitude > 1 then
                local rayParams = RaycastParams.new()
                local filter = {}
                if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
                if targetRoot.Parent then table.insert(filter, targetRoot.Parent) end
                rayParams.FilterDescendantsInstances = filter
                pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end)
                local wallRay = Workspace:Raycast(myRoot.Position + Vector3.new(0,2,0), flat.Unit * math.min(4.5, flat.Magnitude), rayParams)
                if wallRay and wallRay.Instance and math.abs(wallRay.Normal.Y) < 0.8 then return true end
            end
            if state.StuckSince > 0 and dist > 4 then return true end
            return false
        end

        local strafeState = {lastFlip = 0, direction = 1}

        local function moveToTarget(myRoot, myHum, targetRoot, dist, targetThreatening)
            local strictLock = state.LockHard and state.Target == state.LockedTarget
            local predicted = strictLock and targetRoot.Position or (targetRoot.Position + targetRoot.AssemblyLinearVelocity * (state.Settings.MovePredict or 0.12))
            local offset = predicted - myRoot.Position
            local flat = Vector3.new(offset.X, 0, offset.Z)
            local dir = flat.Magnitude > 0 and flat.Unit or myRoot.CFrame.LookVector
            local right = Vector3.new(dir.Z, 0, -dir.X)
            local desired = state.Settings.PreferredDistance
            local movement = Vector3.zero
            local mode = state.Settings.MovementMode or "Straight"
            local now = tick()
            local attackAlign = getAttackAlignment(myRoot, targetRoot)
            local commitRange = getMeleeCommitRange()

            myHum.AutoRotate = false
            if strictLock then
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z))
            else
                myRoot.CFrame = myRoot.CFrame:Lerp(CFrame.lookAt(myRoot.Position, Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)), 0.25)
            end

            -- Stuck detection
            if state.LastMovePos == Vector3.zero then
                state.LastMovePos = myRoot.Position
            else
                local moved = (myRoot.Position - state.LastMovePos).Magnitude
                state.LastMovePos = myRoot.Position
                if dist > 3 then
                    if moved < 0.45 then
                        if state.StuckSince == 0 then state.StuckSince = tick() end
                    else
                        state.StuckSince = 0
                    end
                    if state.StuckSince > 0 and tick() - state.StuckSince > 1.35 then
                        state.StuckSince = 0
                        local moves = currentMoves()
                        if state.Settings.EnableDash and moves then
                            tapKey(moves.dash, 0.05)
                            state.LastDash = tick()
                        else
                            myHum.Jump = true
                            state.LastJump = tick()
                        end
                    end
                else
                    state.StuckSince = 0
                end
            end

            if mode == "Straight" then
                movement = dir
            elseif mode == "Jumpy" then
                movement = dir
                if dist < 9 and math.random() < ((state.Settings.JumpyIntensity or 0.6) * 0.04) and tick() - state.LastJump > math.max(0.45, (state.Settings.JumpCooldown or 0.9) * 0.75) then
                    myHum.JumpPower = state.Settings.JumpPower or myHum.JumpPower
                    myHum.Jump = true
                    state.LastJump = tick()
                end
            elseif mode == "Pro" then
                if now - strafeState.lastFlip > 0.4 then
                    strafeState.lastFlip = now
                    strafeState.direction = -strafeState.direction
                end
                movement = dir + (right * strafeState.direction * 0.85)
            elseif mode == "Kimbaap" then
                desired = 3.5
                movement = (dir * 0.65) + (right * math.sin(now * 7) * 0.85)
            elseif mode == "Circle" then
                movement = (dir * 0.35) + (right * math.cos(now * 2.2))
            elseif mode == "Orbital" then
                movement = (dir * 0.25) + (right * math.cos(now * 1.8) * 1.2)
            elseif mode == "Aggro" then
                desired = 2.8
                movement = (dir * 0.95) + (right * math.sin(now * 6) * 0.25)
            end

            if strictLock then
                if now - strafeState.lastFlip > 0.55 then
                    strafeState.lastFlip = now
                    strafeState.direction = -strafeState.direction
                end
                desired = math.max(3.2, math.min(desired, 4.4))
                if attackAlign < 0.55 and dist <= commitRange + 1 then
                    movement = dir
                elseif dist > desired + 1.1 then
                    movement = dir + (right * strafeState.direction * 0.2)
                elseif dist > commitRange then
                    movement = (dir * 0.8) + (right * strafeState.direction * 0.22)
                elseif dist < math.max(2.3, desired - 1.05) then
                    movement = (dir * 0.14) + (right * strafeState.direction * 0.28)
                else
                    movement = (dir * 0.3) + (right * strafeState.direction * 0.2)
                end
            elseif dist <= commitRange and attackAlign < 0.38 then
                movement = dir
            elseif dist < desired then
                movement = right * strafeState.direction
            elseif dist < desired + 1.5 then
                movement = movement + (dir * 0.18)
            end

            if targetThreatening and dist > desired + 1 then
                movement = dir * 0.65
            end

            myHum.WalkSpeed = state.Settings.Speed
            if movement.Magnitude > 0 then
                local moveUnit = movement.Unit
                myHum:Move(moveUnit, false)
                if strictLock or dist > desired + 1.5 then
                    myHum:MoveTo(myRoot.Position + (moveUnit * math.max(5, desired + 1.5)))
                end
            else
                myHum:Move(Vector3.zero, false)
            end

            if state.Settings.EnableDash and tick() - state.LastDash > math.max(0.8, getProfile().dash) and dist > state.Settings.DashDistanceThreshold then
                local moves = currentMoves()
                if moves then
                    tapKey(moves.dash, 0.05)
                    state.LastDash = tick()
                end
            end

            if shouldTriggerAutoJump(myRoot, myHum, targetRoot, dist) then
                myHum.JumpPower = state.Settings.JumpPower or myHum.JumpPower
                myHum.Jump = true
                state.LastJump = tick()
            end
        end

        local function attackCombo(targetHum, dist)
            local clicks = dist <= 6.2 and getProfile().m1count or math.min(2, getProfile().m1count)
            local hpBefore = targetHum.Health
            local landed = 0
            local swingDelay = math.max(0.025, math.min(0.055, (state.Settings.AttackDelay or 0.08) * 0.5))
            for _ = 1, clicks do
                local myRoot = getRoot(LocalPlayer)
                local tRoot = getRoot(state.Target)
                if not myRoot or not tRoot or not targetHum or targetHum.Health <= 0 then break end
                local liveDist = (myRoot.Position - tRoot.Position).Magnitude
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                if not canCommitMelee(myRoot, tRoot, liveDist, false) then break end
                clickMouse()
                landed = landed + 1
                task.wait(swingDelay)
            end
            if landed == 0 then
                state.MissCount = state.MissCount + 1
                return 0
            end
            state.M1ComboCount = state.M1ComboCount + landed
            state.ComboStep = (state.ComboStep % 4) + 1
            local moves = currentMoves()
            if moves and landed >= 2 and state.ComboStep == 3 then
                task.spawn(function() tapKey(moves.s1, 0.05) end)
            elseif moves and landed >= 2 and state.ComboStep == 4 then
                task.spawn(function() tapKey(moves.s2, 0.05) end)
            end
            task.delay(0.16, function()
                if targetHum and targetHum.Parent then
                    if targetHum.Health < hpBefore then
                        state.HitCount = state.HitCount + landed
                    else
                        state.MissCount = state.MissCount + 1
                    end
                end
            end)
            return landed
        end

        local function stopFly()
            if flyLoop and flyLoop.Connected then flyLoop:Disconnect() end
            flyLoop = nil
            safeDestroy(flyVelocity); flyVelocity = nil
            safeDestroy(flyGyro); flyGyro = nil
            for k in pairs(state.FlyMovement) do state.FlyMovement[k] = false end
            local hum = getHumanoid(LocalPlayer)
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
            end
        end

        local function startFly()
            if not tier.Flags.fly then return end
            local char = getChar(LocalPlayer)
            local hum = getHumanoid(char)
            local root = getRoot(char)
            if not hum or not root then return false end
            stopFly()
            flyVelocity = Instance.new("BodyVelocity")
            flyVelocity.Name = "MoneyHubFlyVelocity"
            flyVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
            flyVelocity.P = 15000
            flyVelocity.Parent = root
            flyGyro = Instance.new("BodyGyro")
            flyGyro.Name = "MoneyHubFlyGyro"
            flyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
            flyGyro.P = 30000
            flyGyro.CFrame = root.CFrame
            flyGyro.Parent = root
            hum.PlatformStand = true
            hum.AutoRotate = false
            flyLoop = RunService.RenderStepped:Connect(function()
                if not state.FlyEnabled or state.Destroyed then return end
                Camera = Workspace.CurrentCamera or Camera
                local liveChar = getChar(LocalPlayer)
                local liveHum = getHumanoid(liveChar)
                local liveRoot = getRoot(liveChar)
                if not Camera or not liveHum or not liveRoot or not flyVelocity or not flyGyro then return end
                local look = Camera.CFrame.LookVector
                local right = Camera.CFrame.RightVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                local flatRight = Vector3.new(right.X, 0, right.Z)
                if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
                local moveVec = Vector3.zero
                if state.FlyMovement.W then moveVec += flatLook end
                if state.FlyMovement.S then moveVec -= flatLook end
                if state.FlyMovement.A then moveVec -= flatRight end
                if state.FlyMovement.D then moveVec += flatRight end
                if state.FlyMovement.Up then moveVec += Vector3.new(0,1,0) end
                if state.FlyMovement.Down then moveVec -= Vector3.new(0,1,0) end
                flyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * state.Settings.FlySpeed or Vector3.zero
                flyGyro.CFrame = CFrame.new(liveRoot.Position, liveRoot.Position + Camera.CFrame.LookVector)
                liveHum:ChangeState(Enum.HumanoidStateType.Physics)
            end)
            return true
        end

        local function setFly(enabled)
            if not tier.Flags.fly then return end
            state.FlyEnabled = enabled
            if enabled then startFly() else stopFly() end
        end

        local function setNoClip(enabled)
            if noclipConnection and noclipConnection.Connected then noclipConnection:Disconnect() end
            noclipConnection = nil
            if not enabled or not tier.Flags.noclip then return end
            noclipConnection = RunService.Stepped:Connect(function()
                local char = getChar(LocalPlayer)
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end

        local function printControls()
            print("========================================")
            print(tier.Name .. " Controls")
            print("========================================")
            print("Lock key: " .. tostring(state.Settings.LockKey))
            print("Panic key: " .. tostring(state.Settings.PanicKey))
            print("Hide key: " .. tostring(state.Settings.HideKey))
            if tier.Flags.fly then print("Fly: WASD steer, Space up, Ctrl down") end
            print("========================================")
        end

        local function printStatusSnapshot()
            local favTech = getFavoriteTech()
            print("========================================")
            print(tier.Name .. " Status")
            print("========================================")
            print("Tier: " .. tierName)
            print("Version: " .. tier.Version)
            print("Character: " .. currentCharacter().displayName)
            print("Difficulty: " .. state.Difficulty)
            print("Preset: " .. state.SelectedPreset)
            print("Tech: " .. state.LastTechName)
            print("Target: " .. (state.Target and state.Target.DisplayName or "None"))
            print("Loader Status: Rayfield=" .. loaderState.Rayfield .. " TBO=" .. loaderState.TBO .. " BF=" .. loaderState.ExternalBF)
            print("Favorite Tech: " .. favTech)
            print("========================================")
        end

        local function buildWindow()
            local configSaving = {
                Enabled = tier.Flags.configSaving,
                FolderName = "MoneyHub",
                FileName = tierName == "PAID" and "MoneyHubPaid" or "MoneyHubFree",
            }

            rayfieldWindow = Rayfield:CreateWindow({
                Name = tier.Name,
                LoadingTitle = tier.LoadingTitle,
                LoadingSubtitle = tier.LoadingSubtitle,
                Theme = tier.Theme,
                ConfigurationSaving = configSaving,
            })

            local charOptions, charLookup = buildCharacterDisplayLists(tier.CharacterIds)

            local mainTab = rayfieldWindow:CreateTab(tierName == "PAID" and "Combat AI" or "Main")
            local movementTab = rayfieldWindow:CreateTab("Movement")
            local visualsTab = rayfieldWindow:CreateTab("Visuals")
            local miscTab = rayfieldWindow:CreateTab("Misc")
            local helpTab, defenseTab, lockTab, bfTab, ultTab, viewTab, statsTab, configTab, statusTab, changelogTab

            if tier.Flags.helpPanel then helpTab = rayfieldWindow:CreateTab("Help") end
            if tier.Flags.advancedDefense or tierName == "FREE" then defenseTab = rayfieldWindow:CreateTab("Defense") end
            if tier.Flags.crosshairLock or tier.Flags.manualPlayerLock or tier.Flags.lockCamera or tierName == "FREE" then lockTab = rayfieldWindow:CreateTab("Lock-On") end
            if tier.Flags.externalLoaders then bfTab = rayfieldWindow:CreateTab("BF Chain") end
            if tier.Flags.autoUlt then ultTab = rayfieldWindow:CreateTab("Ultimate") end
            if tier.Flags.viewPlayer then viewTab = rayfieldWindow:CreateTab("View Player") end
            if tier.Flags.statsPanel then statsTab = rayfieldWindow:CreateTab("Stats") end
            if tier.Flags.configSaving then configTab = rayfieldWindow:CreateTab("Configs") end
            if tier.Flags.loaderStatus or tier.Flags.liveTargetPanel then statusTab = rayfieldWindow:CreateTab("Status") end
            if tier.Flags.changeLog then changelogTab = rayfieldWindow:CreateTab("Changelog") end

            mainTab:CreateToggle({
                Name = "Master AI",
                CurrentValue = false,
                Callback = function(val)
                    state.Enabled = val
                    if not val then setBlockHeld(false) end
                    updateTargetHud()
                    updateStatusHud()
                    notify(tier.Name, val and "AI enabled." or "AI disabled.", 2)
                end,
            })

            mainTab:CreateButton({
                Name = "Instant Lock On",
                Callback = function()
                    local t = acquireTarget()
                    if t then setLockTarget(t, "Manual", true); notify("Lock", "Locked: " .. t.DisplayName, 2)
                    else notify("Lock", "No valid target.", 2) end
                end,
            })

            characterDropdown = mainTab:CreateDropdown({
                Name = "Character",
                Options = charOptions,
                CurrentOption = {currentCharacter().displayName},
                Callback = function(val)
                    if type(val) == "table" then val = val[1] end
                    state.SelectedCharId = charLookup[val] or state.SelectedCharId
                    state.SelectedTech = "Random"
                    state.SelectedPreset = "Balanced"
                    if techDropdown then pcall(function() techDropdown:Refresh(getTechNames(state.SelectedCharId), false) end) end
                    updateTargetHud()
                    updateStatusHud()
                    notify("Character", currentCharacter().displayName, 2)
                end,
            })

            if tier.Flags.comboPresets then
                mainTab:CreateDropdown({
                    Name = "Combo Preset",
                    Options = {"Balanced", "Pressure", "Burst"},
                    CurrentOption = {"Balanced"},
                    Callback = function(val)
                        if type(val) == "table" then val = val[1] end
                        state.SelectedPreset = val
                        updateTargetHud()
                        updateStatusHud()
                    end,
                })
            end

            if tier.Flags.techPicker then
                techDropdown = mainTab:CreateDropdown({
                    Name = "Tech to Use",
                    Options = getTechNames(state.SelectedCharId),
                    CurrentOption = {"Random"},
                    Callback = function(val)
                        if type(val) == "table" then val = val[1] end
                        state.SelectedTech = val
                        updateTargetHud()
                        updateStatusHud()
                    end,
                })

                mainTab:CreateButton({
                    Name = "Preview Selected Tech",
                    Callback = function()
                        local tech = state.SelectedTech == "Random" and selectTech(10) or findTechByName(state.SelectedCharId, state.SelectedTech)
                        if tech then
                            recordTechUse(tech.name)
                            task.spawn(function() executeSequence(tech.seq) end)
                            notify("Preview", tech.name, 2)
                        else
                            notify("Preview", "No tech available.", 2)
                        end
                    end,
                })
            end

            mainTab:CreateDropdown({
                Name = "Difficulty",
                Options = {"Noob", "Pro", "Good", "Expert"},
                CurrentOption = {"Expert"},
                Callback = function(val)
                    if type(val) == "table" then val = val[1] end
                    applyDifficulty(val)
                    notify("Difficulty", val, 2)
                end,
            })

            mainTab:CreateSlider({
                Name = "Attack Delay",
                Range = {0.04, 0.5},
                Increment = 0.01,
                CurrentValue = state.Settings.AttackDelay,
                Callback = function(val) state.Settings.AttackDelay = val end,
            })

            mainTab:CreateSlider({
                Name = "Attack Range",
                Range = {5, 18},
                Increment = 0.5,
                CurrentValue = state.Settings.AttackRange,
                Callback = function(val) state.Settings.AttackRange = val end,
            })

            mainTab:CreateToggle({
                Name = "Auto Techs",
                CurrentValue = state.Settings.AutoTechs,
                Callback = function(val) state.Settings.AutoTechs = val end,
            })

            mainTab:CreateToggle({
                Name = "Enable Dash",
                CurrentValue = state.Settings.EnableDash,
                Callback = function(val) state.Settings.EnableDash = val end,
            })

            mainTab:CreateToggle({
                Name = "Enable Black Flash",
                CurrentValue = state.Settings.EnableBlackFlash,
                Callback = function(val) state.Settings.EnableBlackFlash = val end,
            })

            movementTab:CreateDropdown({
                Name = "Move Type",
                Options = tier.MovementModes,
                CurrentOption = {state.Settings.MovementMode},
                Callback = function(val)
                    if type(val) == "table" then val = val[1] end
                    state.Settings.MovementMode = val
                    updateTargetHud()
                end,
            })

            if tier.Flags.presets then
                movementTab:CreateButton({ Name = "Aggressive Preset", Callback = function() if tierName=="FREE" then applyFreePreset("Aggressive") else loadNamedProfile("Rage") end end })
                movementTab:CreateButton({ Name = "Balanced Preset", Callback = function() if tierName=="FREE" then applyFreePreset("Balanced") else loadNamedProfile("Public") end end })
                movementTab:CreateButton({ Name = "Safe Preset", Callback = function() if tierName=="FREE" then applyFreePreset("Safe") else loadNamedProfile("Safe") end end })
            end

            movementTab:CreateSlider({ Name = "WalkSpeed", Range = {16,60}, Increment = 1, CurrentValue = state.Settings.Speed, Callback = function(v) state.Settings.Speed = v end })
            movementTab:CreateSlider({ Name = "Preferred Distance", Range = {2,12}, Increment = 0.5, CurrentValue = state.Settings.PreferredDistance, Callback = function(v) state.Settings.PreferredDistance = v end })
            movementTab:CreateSlider({ Name = "Dash Distance", Range = {8,30}, Increment = 1, CurrentValue = state.Settings.DashDistanceThreshold, Callback = function(v) state.Settings.DashDistanceThreshold = v end })

            if tier.Flags.advancedDefense then
                movementTab:CreateSlider({ Name = "Strafe Amplitude", Range = {1,10}, Increment = 0.5, CurrentValue = state.Settings.StrafeAmplitude or 4, Callback = function(v) state.Settings.StrafeAmplitude = v end })
                movementTab:CreateSlider({ Name = "Strafe Frequency", Range = {1,12}, Increment = 0.5, CurrentValue = state.Settings.StrafeFrequency or 5.5, Callback = function(v) state.Settings.StrafeFrequency = v end })
            else
                movementTab:CreateSlider({ Name = "Jumpy Intensity", Range = {0,1}, Increment = 0.05, CurrentValue = state.Settings.JumpyIntensity, Callback = function(v) state.Settings.JumpyIntensity = v end })
            end

            movementTab:CreateToggle({ Name = "Auto Jump", CurrentValue = state.Settings.AutoJump, Callback = function(v) state.Settings.AutoJump = v end })
            movementTab:CreateSlider({ Name = "Jump Cooldown", Range = {0.25,2.5}, Increment = 0.05, CurrentValue = state.Settings.JumpCooldown, Callback = function(v) state.Settings.JumpCooldown = v end })
            movementTab:CreateSlider({ Name = "Jump Power", Range = {20,60}, Increment = 1, CurrentValue = state.Settings.JumpPower, Callback = function(v) state.Settings.JumpPower = v end })

            if tier.Flags.fly then
                movementTab:CreateToggle({ Name = "Fly", CurrentValue = false, Callback = setFly })
                movementTab:CreateSlider({ Name = "Fly Speed", Range = {20,140}, Increment = 1, CurrentValue = state.Settings.FlySpeed, Callback = function(v) state.Settings.FlySpeed = v end })
            end

            if tier.Flags.infiniteJump then
                movementTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = state.Settings.InfiniteJump, Callback = function(v) state.Settings.InfiniteJump = v end })
            end

            visualsTab:CreateToggle({ Name = "ESP", CurrentValue = state.Settings.ESP, Callback = function(v) state.Settings.ESP = v; refreshESP() end })
            visualsTab:CreateToggle({ Name = "Rainbow ESP", CurrentValue = state.Settings.RainbowESP, Callback = function(v) state.Settings.RainbowESP = v end })
            visualsTab:CreateToggle({ Name = "Lock Icon (Target)", CurrentValue = state.Settings.LockOnIcon, Callback = function(v) state.Settings.LockOnIcon = v; updateLockBillboard(state.Target) end })

            if state.Settings.TargetHud ~= nil then
                visualsTab:CreateToggle({ Name = "Target HUD", CurrentValue = state.Settings.TargetHud, Callback = function(v) state.Settings.TargetHud = v; updateTargetHud() end })
            end

            if tier.Flags.liveTargetPanel then
                visualsTab:CreateToggle({ Name = "Show Health + Distance", CurrentValue = state.Settings.ShowTargetHealth, Callback = function(v) state.Settings.ShowTargetHealth = v end })
            end

            if helpTab then
                helpTab:CreateSection("Controls")
                helpTab:CreateLabel("Lock key: " .. tostring(state.Settings.LockKey))
                helpTab:CreateLabel("Panic key: " .. tostring(state.Settings.PanicKey))
                helpTab:CreateLabel("Hide key: " .. tostring(state.Settings.HideKey))
                if tier.Flags.fly then helpTab:CreateLabel("Fly: WASD steer, Space up, Ctrl down") end
                helpTab:CreateButton({ Name = "Print Controls to F9", Callback = printControls })
            end

            if defenseTab then
                defenseTab:CreateToggle({ Name = "Auto Block", CurrentValue = state.Settings.EnableNativeBlock, Callback = function(v) state.Settings.EnableNativeBlock = v; if not v then setBlockHeld(false) end end })
                defenseTab:CreateToggle({ Name = "Auto Counter", CurrentValue = state.Settings.AutoCounter, Callback = function(v) state.Settings.AutoCounter = v end })
                defenseTab:CreateDropdown({
                    Name = "Counter Key",
                    Options = {"R","F","G","T","Y"},
                    CurrentOption = {tostring((state.Settings.CounterKey or Enum.KeyCode.R).Name)},
                    Callback = function(v)
                        if type(v) == "table" then v = v[1] end
                        local map = {R=Enum.KeyCode.R, F=Enum.KeyCode.F, G=Enum.KeyCode.G, T=Enum.KeyCode.T, Y=Enum.KeyCode.Y}
                        state.Settings.CounterKey = map[v] or Enum.KeyCode.R
                    end,
                })
                defenseTab:CreateSlider({ Name = "Block Distance", Range = {8,20}, Increment = 1, CurrentValue = state.Settings.BlockDistance, Callback = function(v) state.Settings.BlockDistance = v end })
                defenseTab:CreateSlider({ Name = "Block Confirm", Range = {0.05,0.5}, Increment = 0.01, CurrentValue = state.Settings.BlockConfirmWindow, Callback = function(v) state.Settings.BlockConfirmWindow = v end })

                if tier.Flags.advancedDefense then
                    defenseTab:CreateToggle({ Name = "Auto Feint", CurrentValue = state.Settings.AutoFeint, Callback = function(v) state.Settings.AutoFeint = v end })
                    defenseTab:CreateToggle({ Name = "Auto Dodge Heavy", CurrentValue = state.Settings.AutoDodgeHeavy, Callback = function(v) state.Settings.AutoDodgeHeavy = v end })
                    defenseTab:CreateToggle({ Name = "Parry Mode", CurrentValue = state.Settings.ParryMode, Callback = function(v) state.Settings.ParryMode = v end })
                end
            end

            if lockTab then
                lockTab:CreateToggle({ Name = "Lock Camera", CurrentValue = state.Settings.LockCamera, Callback = function(v) state.Settings.LockCamera = v end })
                lockTab:CreateToggle({ Name = "Ignore Others", CurrentValue = state.Settings.IgnoreOthers, Callback = function(v) state.Settings.IgnoreOthers = v end })
                lockTab:CreateToggle({ Name = "Auto Lock On Damage", CurrentValue = state.Settings.AutoLockOnDamage, Callback = function(v) state.Settings.AutoLockOnDamage = v end })
                lockTab:CreateSlider({ Name = "Camera Smoothness", Range = {5,100}, Increment = 5, CurrentValue = math.floor((state.Settings.LockSmoothness or 0.35)*100), Suffix = "%", Callback = function(v) state.Settings.LockSmoothness = v/100 end })
                lockTab:CreateDropdown({
                    Name = "Target Mode",
                    Options = {"Nearest","Crosshair"},
                    CurrentOption = {state.Settings.LockMode or "Nearest"},
                    Callback = function(v)
                        if type(v) == "table" then v = v[1] end
                        state.Settings.LockMode = v
                        updateTargetHud()
                    end,
                })
                if tier.Flags.manualPlayerLock then
                    lockTab:CreateInput({ Name = "Player Name", PlaceholderText = "Username or display", RemoveTextAfterFocusLost = false, Callback = function(t) currentLockQuery = t end })
                    lockTab:CreateButton({ Name = "Lock This Player", Callback = function()
                        local t = findPlayerByQuery(currentLockQuery)
                        if t then setLockTarget(t, "Manual", true); notify("Lock", "Locked: "..t.DisplayName, 2) else notify("Lock", "Player not found.", 2) end
                    end })
                end
                lockTab:CreateButton({ Name = "Lock Nearest", Callback = function()
                    local t = select(1, getNearest(300))
                    if t then setLockTarget(t, "Nearest", true); notify("Lock", "Locked: "..t.DisplayName, 2) end
                end })
                lockTab:CreateButton({ Name = "Release Lock", Callback = function() setLockTarget(nil, "Nearest", false) end })
            end

            if viewTab then
                viewDropdown = viewTab:CreateDropdown({ Name = "Player List", Options = getPlayerList(), CurrentOption = {}, Callback = function(v) if type(v)=="table" then currentViewSelection = v[1] else currentViewSelection = v end end })
                viewTab:CreateButton({ Name = "Refresh Players", Callback = function() pcall(function() viewDropdown:Refresh(getPlayerList(), false) end) end })
                viewTab:CreateInput({ Name = "Search", PlaceholderText = "Username or display", RemoveTextAfterFocusLost = false, Callback = function(t) currentViewQuery = t end })
                viewTab:CreateButton({ Name = "View Selected", Callback = function()
                    if currentViewSelection and currentViewSelection ~= "No players" then
                        local user = string.match(currentViewSelection, "@(.+)%)$")
                        if user then
                            local t = findPlayerByQuery(user)
                            if t and viewPlayer(t) then notify("View", "Viewing "..t.DisplayName, 2) end
                        end
                    end
                end })
                viewTab:CreateButton({ Name = "View by Search", Callback = function()
                    local t = findPlayerByQuery(currentViewQuery)
                    if t and viewPlayer(t) then notify("View", "Viewing "..t.DisplayName, 2) else notify("View", "Player not found.", 2) end
                end })
                viewTab:CreateButton({ Name = "Go Back to Me", Callback = unviewPlayer })
            end

            if statsTab then
                statsTab:CreateButton({ Name = "Print Session Stats to F9", Callback = function()
                    local fav = getFavoriteTech()
                    local uptime = math.floor(tick()-state.SessionStart)
                    print("========================================")
                    print(tier.Name .. " Stats")
                    print("========================================")
                    print("Uptime: "..uptime.."s")
                    print("Kills: "..state.Kills.." | Deaths: "..state.Deaths)
                    print("Kill Streak: "..state.KillStreak.." | Best: "..state.BestStreak)
                    print("Damage Out: "..math.floor(state.TotalDamageDealt))
                    print("Damage In: "..math.floor(state.TotalDamageTaken))
                    print("Hits: "..state.HitCount.." | Misses: "..state.MissCount)
                    print("Favorite Tech: "..fav)
                    print("========================================")
                end })
                statsTab:CreateButton({ Name = "Reset Session Stats", Callback = function()
                    state.Kills = 0; state.Deaths = 0; state.KillStreak = 0; state.BestStreak = 0
                    state.TotalDamageDealt = 0; state.TotalDamageTaken = 0; state.HitCount = 0; state.MissCount = 0
                    state.TechUsageCounts = {}; state.SessionStart = tick()
                    updateStatusHud()
                end })
            end

            if configTab then
                namedProfiles = PAID_CONFIG_PRESETS
                configTab:CreateSection("Preset Profiles")
                for _, name in ipairs({"1v1","Public","Safe","Rage"}) do
                    configTab:CreateButton({ Name = "Load "..name, Callback = function() loadNamedProfile(name) end })
                    configTab:CreateButton({ Name = "Save Current to "..name, Callback = function()
                        local store = namedProfiles or {}
                        store[name] = { SelectedCharId = state.SelectedCharId, SelectedTech = state.SelectedTech, SelectedPreset = state.SelectedPreset, Difficulty = state.Difficulty, Settings = deepCopy(state.Settings) }
                        namedProfiles = store
                        notify("Config", "Saved to "..name, 2)
                    end })
                end
            end

            if statusTab then
                statusTab:CreateLabel("Use the live overlay for cooldowns, target data, and loader health.")
                statusTab:CreateButton({ Name = "Print Live Status to F9", Callback = printStatusSnapshot })
                statusTab:CreateButton({ Name = "Refresh Loader Status", Callback = function() updateStatusHud(); notify("Status", "Overlay refreshed.", 2) end })
            end

            if changelogTab then
                changelogTab:CreateLabel(tier.Version .. " - Tiered architecture")
                changelogTab:CreateLabel("Shared core + tier config + character registry")
                changelogTab:CreateLabel("FREE gets starter core, paid gets depth and tooling")
                changelogTab:CreateLabel("Target HUD, panic reset, presets, status overlays")
            end

            miscTab:CreateButton({ Name = "Panic Reset", Callback = panicReset })
            miscTab:CreateButton({ Name = "Stop All + Unlock", Callback = function() panicReset(); setFly(false); unviewPlayer() end })

            if tier.Flags.noclip then
                miscTab:CreateToggle({ Name = "NoClip", CurrentValue = state.Settings.NoClip, Callback = function(v) state.Settings.NoClip = v; setNoClip(v) end })
            end

            if tier.Flags.antiRagdoll then
                miscTab:CreateToggle({ Name = "Anti-Ragdoll", CurrentValue = state.Settings.AntiRagdoll, Callback = function(v) state.Settings.AntiRagdoll = v end })
            end

            miscTab:CreateButton({ Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end })

            if tier.Flags.serverTools then
                miscTab:CreateButton({ Name = "Server Hop", Callback = function()
                    local ok, servers = pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=25")) end)
                    if ok and servers and servers.data then
                        for _, srv in ipairs(servers.data) do
                            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                                return
                            end
                        end
                    end
                    notify("Server Hop", "No open server found.", 2)
                end })
                miscTab:CreateButton({ Name = "Fullbright", Callback = function()
                    Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.FogEnd = 999999; Lighting.GlobalShadows = false
                    for _, v in ipairs(Lighting:GetDescendants()) do
                        if v:IsA("Atmosphere") then v.Density = 0
                        elseif v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then v.Enabled = false
                        end
                    end
                end })
            end
        end

        local function cleanupPlayer(player)
            clearESP(player)
            local bucket = playerConnections[player]
            if bucket then disconnectList(bucket); playerConnections[player] = nil end
        end

        local function bindPlayer(player)
            if player == LocalPlayer or playerConnections[player] then return end
            playerConnections[player] = {
                player.CharacterAdded:Connect(function()
                    task.wait(0.15)
                    if state.Settings.ESP and not state.Destroyed then updateESPEntry(player) end
                    if viewDropdown then pcall(function() viewDropdown:Refresh(getPlayerList(), false) end) end
                end),
                player.CharacterRemoving:Connect(function()
                    clearESP(player)
                    if state.LockedTarget == player then setLockTarget(nil, "Nearest", false) end
                end),
            }
            if state.Settings.ESP then task.defer(function() updateESPEntry(player) end) end
        end

        local function cleanup()
            if state.Destroyed then return end
            state.Destroyed = true
            state.Enabled = false
            setBlockHeld(false)
            setFly(false)
            setNoClip(false)
            unviewPlayer()

            for player in pairs(playerConnections) do cleanupPlayer(player) end
            disconnectList(connections)
            table.clear(connections)

            clearLockBillboard()
            safeDestroy(lockBillboard)
            lockBillboard = nil

            for player in pairs(espObjects) do clearESP(player) end

            safeDestroy(overlayGui)
            overlayGui = nil
            targetHudLabel = nil
            statusHudLabel = nil

            sharedState.__MoneyHubCleanup = nil
        end

        sharedState.__MoneyHubCleanup = cleanup

        removeExistingGui("MoneyHubOverlay")
        ensureOverlay()
        buildWindow()
        applyDifficulty(state.Difficulty)
        updateTargetHud()
        updateStatusHud()
        printControls()

        track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == state.Settings.HideKey then
                pcall(function() Rayfield:Toggle() end)
                return
            end
            if input.KeyCode == state.Settings.PanicKey then panicReset(); return end
            if input.KeyCode == state.Settings.LockKey then
                if state.LockHard then setLockTarget(nil, "Nearest", false); notify("Lock", "Unlocked", 2)
                else
                    local t = acquireTarget()
                    if t then setLockTarget(t, "Hotkey", true); notify("Lock", "Locked: "..t.DisplayName, 2)
                    else notify("Lock", "No target.", 2) end
                end
                return
            end
            if gameProcessed then return end
            if state.FlyEnabled then
                if input.KeyCode == Enum.KeyCode.W then state.FlyMovement.W = true
                elseif input.KeyCode == Enum.KeyCode.A then state.FlyMovement.A = true
                elseif input.KeyCode == Enum.KeyCode.S then state.FlyMovement.S = true
                elseif input.KeyCode == Enum.KeyCode.D then state.FlyMovement.D = true
                elseif input.KeyCode == Enum.KeyCode.Space then state.FlyMovement.Up = true
                elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then state.FlyMovement.Down = true
                end
            end
        end))

        track(UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W then state.FlyMovement.W = false
            elseif input.KeyCode == Enum.KeyCode.A then state.FlyMovement.A = false
            elseif input.KeyCode == Enum.KeyCode.S then state.FlyMovement.S = false
            elseif input.KeyCode == Enum.KeyCode.D then state.FlyMovement.D = false
            elseif input.KeyCode == Enum.KeyCode.Space then state.FlyMovement.Up = false
            elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then state.FlyMovement.Down = false
            end
        end))

        track(UserInputService.JumpRequest:Connect(function()
            if state.Settings.InfiniteJump then
                local hum = getHumanoid(LocalPlayer)
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end))

        track(LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.25)
            if state.HasSpawned then state.Deaths = state.Deaths + 1; state.KillStreak = 0 end
            state.HasSpawned = true
            state.LastDamageHealth = 0
            state.M1ComboCount = 0
            state.ComboStep = 0
            state.ChainActive = false
            setBlockHeld(false)
            if state.FlyEnabled then startFly() end
            if state.Settings.NoClip then setNoClip(true) end
        end))

        track(Players.PlayerAdded:Connect(function(player)
            bindPlayer(player)
            if viewDropdown then task.wait(0.3); pcall(function() viewDropdown:Refresh(getPlayerList(), false) end) end
        end))

        track(Players.PlayerRemoving:Connect(function(player)
            if state.Viewing == player then unviewPlayer() end
            cleanupPlayer(player)
            if viewDropdown then task.wait(0.2); pcall(function() viewDropdown:Refresh(getPlayerList(), false) end) end
        end))

        track(RunService.RenderStepped:Connect(function()
            if tier.Flags.lockCamera and state.Settings.LockCamera and state.LockHard and isEnemy(state.LockedTarget) then
                Camera = Workspace.CurrentCamera or Camera
                local root = getRoot(state.LockedTarget)
                local head = getHead(state.LockedTarget) or root
                if Camera and root and head then
                    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, state.Settings.LockSmoothness or 0.35)
                end
            end
            if tier.Flags.antiRagdoll and state.Settings.AntiRagdoll then
                local hum = getHumanoid(LocalPlayer)
                if hum then
                    hum.PlatformStand = false
                    local st = hum:GetState()
                    if st == Enum.HumanoidStateType.PlatformStanding or st == Enum.HumanoidStateType.Physics then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end
            if state.Viewing then
                local hum = getHumanoid(state.Viewing)
                if hum and Workspace.CurrentCamera.CameraSubject ~= hum then
                    Workspace.CurrentCamera.CameraSubject = hum
                end
            end
        end))

        track(RunService.Heartbeat:Connect(function()
            if state.Destroyed then return end
            updateDamageTaken()
            if state.Settings.ESP or state.Settings.ShowLockedTarget then refreshESP() end
            if not state.Enabled then
                local hum = getHumanoid(LocalPlayer)
                if hum then
                    hum.AutoRotate = true
                    hum:Move(Vector3.zero, false)
                end
                if state.AutoBlockHeld then setBlockHeld(false) end
                updateTargetHud()
                updateStatusHud()
                return
            end

            local myChar = getChar(LocalPlayer)
            local myHum = getHumanoid(myChar)
            local myRoot = getRoot(myChar)
            if not myHum or not myRoot or myHum.Health <= 0 then
                updateTargetHud()
                updateStatusHud()
                return
            end

            local target = acquireTarget()
            state.Target = target
            updateLockBillboard(target)

            if not target or not isEnemy(target) then
                myHum.AutoRotate = true
                myHum:Move(Vector3.zero, false)
                updateTargetHud()
                updateStatusHud()
                return
            end

            local tRoot = getRoot(target)
            local tHum = getHumanoid(target)
            if not tRoot or not tHum then
                updateTargetHud()
                updateStatusHud()
                return
            end

            state.TargetDistance = (myRoot.Position - tRoot.Position).Magnitude
            if state.LockHard and state.Target == state.LockedTarget then
                myHum.AutoRotate = false
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
            end
            updateDamageDealt(target)

            local targetThreatening = handleAutoBlock(target)

            if not state.AutoBlockHeld and not state.ChainActive then
                moveToTarget(myRoot, myHum, tRoot, state.TargetDistance, targetThreatening)
            end

            tryAutoUlt(target, state.TargetDistance)

            local dynamicDelay = math.max(0.04, state.Settings.AttackDelay - (state.TargetDistance < 5 and 0.02 or 0))
            if not state.AutoBlockHeld and not state.ChainActive and canCommitMelee(myRoot, tRoot, state.TargetDistance, targetThreatening) and tick() - state.LastAttack > dynamicDelay then
                local landed = attackCombo(tHum, state.TargetDistance)
                state.LastAttack = tick()
                if landed > 0 then
                    runTechs(state.TargetDistance)
                    if state.M1ComboCount >= 3 then
                        attemptBlackFlash(target, state.TargetDistance)
                        state.M1ComboCount = 0
                    end
                end
            end

            updateTargetHud()
            updateStatusHud()
        end))

        for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end

        notify(tier.Name, tier.Version .. " loaded.", 4)
        return { cleanup = cleanup, state = state, tier = tier }
    end

    sharedState.__MoneyHubShared = MoneyHubShared
    return MoneyHubShared
end)()

-- ========== LAUNCH ==========
MoneyHubShared.launch("FREE")

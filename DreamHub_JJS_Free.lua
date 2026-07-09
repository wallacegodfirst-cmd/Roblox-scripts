--[[  Dream Hub · Jujutsu Shenanigans — FREE build
      Red & black theme. Trimmed feature set (auto BF chain modes, auto Rika sword, side/back dash,
      auto evasive, auto adapt, emote/jump counter, feint BF, Crow Ult + Lock On are Premium-only).
      Everything else — including Auto Uppercut/Down Slam and Auto Air — is included.
      Load: loadstring(game:HttpGet("<this url>"))()  ]]
_G.JJS_FREE = true   -- switches the shared hub to the FREE tier (red/black + trimmed features + FREE badge)
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Dream Hub", Text = "JJS FREE loading...", Duration = 4,
    })
end)
loadstring(game:HttpGet("https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/DreamHub_JJS.lua"))()

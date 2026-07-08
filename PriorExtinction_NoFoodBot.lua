--[[  Prior Extinction — Money / Free Hub  (No-Food build)
      Full hub with INF Food / Carnivore Meat TP / Teleport Back / Danger Alert / Auto Play Bot hidden.

      ── BUG / UPDATE LOG ──────────────────────────────────────────────
      v1.7
        • Auto Farm: now reliably finds and teleports to fossils/gems every server
          (was only working about 1 in 20 tries).
        • Menu always loads now, even on weaker executors (Real / Medium / Xeno) —
          falls back to the built-in UI if the fancy menu can't render.
        • Mobile (touch) support: on-screen menu button + fly controls.
      v1.6
        • INF Stam: no more snapback, and runs at normal sprint speed.
        • Anti Head: now actually reduces the damage you take (works on the slow/tanky dinos too).
        • Bone Protection: now works — protects the bone you pick while you keep moving.
        • Always Damage: aims the body part you select on every dino.
        • Hitbox: works on every dino now.
        • Fixed dying on spawn (fall damage / getting sent off the map).
        • Removed the Auto Clicker.
        • Cleaned up the menu.
      ──────────────────────────────────────────────────────────────────
      Load with: loadstring(game:HttpGet("<this url>"))()  ]]
_G.PE_HIDE_LITE = true   -- hide the food/alert/bot sections in the shared hub
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Money / Free Hub", Text = "No-Food build v1.7 loaded — see the update log.", Duration = 5,
	})
end)
loadstring(game:HttpGet("https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/PriorExtinction_MoneyFreeHub.lua"))()

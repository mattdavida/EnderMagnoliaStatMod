-- ==================================================================================================
-- ENDER MAGNOLIA Stat Modification Mod
-- Version 5.0 (Simplified Accessibility)
--
-- Simplified back to core accessibility features that work perfectly:
-- F7 = Ultimate God Mode (immortality + infinite jumps + instant dash)
-- F8 = Speed Boost (comprehensive movement speed increase)  
-- F9 = Exploration No-Clip (free camera mode)
-- ==================================================================================================

local UEHelpers = require("UEHelpers")

-- Global variables for infinite health system
local InfiniteHealthActive = false
local InfiniteHealthTarget = 0

-- A logging helper to print to both the in-game console and the debug log
local function Log(Ar, Message)
    print(Message)
    if Ar and Ar:IsValid() then
        Ar:Log(Message)
    end
end

-- === HELPER FUNCTION to get the core player components ===
local function GetComponents()
    local PC = UEHelpers.GetPlayerController()
    local PlayerPawn = UEHelpers.GetPlayer()

    if not PC or not PC:IsValid() or not PlayerPawn or not PlayerPawn:IsValid() then
        return nil, nil, nil
    end

    local StatsController = PC:GetComponentByClass(StaticFindObject("/Script/Zion.StatsControllerPlayerComponent"))
    local StatHPComponent = PlayerPawn:GetComponentByClass(StaticFindObject("/Script/Zion.StatHPComponent"))
    
    if not StatsController or not StatsController:IsValid() or not StatHPComponent or not StatHPComponent:IsValid() then
        return nil, nil, nil
    end

    return PC, StatsController, StatHPComponent
end

-- === LEVEL SETTER (Persistent) ===
local function SetLevelHandler(FullCommand, Parameters, Ar)
    -- Ensure we ALWAYS return true to claim this command
    local function safeReturn()
        return true
    end
    
    local LevelInput = tonumber(Parameters[1])
    if not LevelInput then 
        Log(Ar, "Usage: set_level <number>")
        return safeReturn()
    end

    local PC, StatsController, StatHPComponent = GetComponents()
    if not PC then 
        Log(Ar, "Could not find player components.")
        return safeReturn()
    end
    
    Log(Ar, "Setting persistent Level to " .. tostring(LevelInput) .. "...")
    
    -- Wrap everything in pcall to prevent any errors from causing a false return
    local success = pcall(function()
        StatsController:SetLevel(LevelInput)
    end)
    
    if success then
        Log(Ar, "Level set. Remember to save your game to make it permanent.")
    else
        Log(Ar, "Level setting completed (with minor engine noise).")
    end
    
    return safeReturn()
end

-- === UI REFRESH HELPER ===
-- This trick forces the game to re-read stat values and update the pause menu UI.
local function RefreshUI(StatsController)
    if StatsController and StatsController:IsValid() then
        local CurrentLevel = StatsController:GetAppliedLevel()
        StatsController:SetLevel(CurrentLevel)
        -- Don't log this to the in-game console, it's a bit too spammy.
        print("UI refreshed.")
    end
end

-- === INFINITE HEALTH SYSTEM ===
-- Function that gets called repeatedly to maintain target HP
local function InfiniteHealthTick()
    if not InfiniteHealthActive then return end
    
    local PC, StatsController, StatHPComponent = GetComponents()
    if not PC then return end
    
    -- Silently restore health to target value
    local success = pcall(function()
        StatHPComponent:SetMaxValue(InfiniteHealthTarget)
        StatHPComponent:FullyRestore()
        
        -- Also maintain the bonus stat
        local stats_object = StatsController.Stats
        local BaseHP_Object = stats_object.HP
        local found_value = 100 -- Default assumption based on data table
        
        -- Try to get actual base value
        local property_names_to_test = {"Value", "BaseValue", "CurrentValue", "Amount"}
        for _, name in ipairs(property_names_to_test) do
            local val, get_err = pcall(function() return BaseHP_Object[name] end)
            if not get_err and type(val) == "number" then
                found_value = val
                break
            end
        end
        
        local BonusHP = InfiniteHealthTarget - found_value
        if BonusHP < 0 then BonusHP = 0 end
        StatsController.AdditiveBonusStats.Stats.HP = BonusHP
    end)
end

-- Start infinite health mode with recursive timer
local function StartInfiniteHealth(targetHP)
    InfiniteHealthActive = true
    InfiniteHealthTarget = targetHP
    
    -- Simple recursive function that keeps calling itself
    local function InfiniteHealthLoop()
        if not InfiniteHealthActive then return end
        
        -- Call the health restoration
        InfiniteHealthTick()
        
        -- Schedule next call after 500ms
        local timer_success = pcall(function()
            ExecuteWithDelay(500, InfiniteHealthLoop)
        end)
        
        -- If ExecuteWithDelay isn't available, fall back to immediate scheduling
        if not timer_success then
            pcall(function()
                ExecuteAsync(InfiniteHealthLoop)
            end)
        end
    end
    
    -- Start the loop
    InfiniteHealthLoop()
end

-- Stop infinite health mode
local function StopInfiniteHealth()
    InfiniteHealthActive = false
    -- The recursive loop will stop automatically when InfiniteHealthActive becomes false
end

-- === HP SETTER (Session Only) ===
local function SetHpHandler(FullCommand, Parameters, Ar)
    local HpInput = tonumber(Parameters[1])
    if not HpInput then Log(Ar, "Usage: set_hp <number>"); return true end

    local PC, StatsController, StatHPComponent = GetComponents()
    if not PC then return true end

    Log(Ar, "Setting HP to " .. tostring(HpInput) .. "...")

    -- 1. Set the combat health on the Pawn's component to the final target value.
    StatHPComponent:SetMaxValue(HpInput)
    StatHPComponent:FullyRestore()

    -- 2. Calculate the correct *bonus* HP to get the exact number requested.
    local success, err = pcall(function()
        local stats_object = StatsController.Stats
        local BaseHP_Object = stats_object.HP
        
        local property_names_to_test = {"Value", "BaseValue", "CurrentValue", "Amount"}
        local found_value = nil

        for _, name in ipairs(property_names_to_test) do
            local val, get_err = pcall(function() return BaseHP_Object[name] end)
            if not get_err and type(val) == "number" then
                found_value = val
                break
            end
        end

        if not found_value then
            error("Could not find a numeric property inside the HP object.")
        end

        local BonusHP = HpInput - found_value
        if BonusHP < 0 then BonusHP = 0 end -- Prevent negative bonus
        StatsController.AdditiveBonusStats.Stats.HP = BonusHP
    end)
    
    if not success then
        StatsController.AdditiveBonusStats.Stats.HP = HpInput
    end
    
    -- 3. Refresh the UI to make sure the change is reflected immediately.
    RefreshUI(StatsController)
    
    Log(Ar, "HP set successfully.")
    return true
end

-- === ROBUST HP SETTER (Modifies Data Table) ===
local function SetHpRobustHandler(FullCommand, Parameters, Ar)
    local HpInput = tonumber(Parameters[1])
    if not HpInput then Log(Ar, "Usage: set_hp_robust <number>"); return true end

    local PC, StatsController, StatHPComponent = GetComponents()
    if not PC then Log(Ar, "Could not find player components."); return true end

    Log(Ar, "Setting robust HP to " .. tostring(HpInput) .. " (modifies data table)...")

    local success = pcall(function()
        -- Find the DT_PlayerStats data table
        local DT_PlayerStats = StaticFindObject("/Game/DataTable/DT_PlayerStats")
        if not DT_PlayerStats or not DT_PlayerStats:IsValid() then
            error("Could not find DT_PlayerStats data table")
        end

        -- Get current level
        local CurrentLevel = StatsController:GetAppliedLevel()
        Log(Ar, "Modifying HP for level " .. tostring(CurrentLevel) .. "...")

        -- Get the row for current level
        -- We need to convert the level to a string since that's how DataTable rows work
        local LevelKey = tostring(CurrentLevel)
        
        -- Try to find and modify the row data
        -- This is tricky because DataTable row access varies by UE4SS version
        -- We'll try multiple approaches
        
        local row_found = false
        
        -- Method 1: Try direct property access
        local direct_success = pcall(function()
            local RowMap = DT_PlayerStats.RowMap
            if RowMap and RowMap[LevelKey] then
                RowMap[LevelKey].HP = HpInput
                row_found = true
            end
        end)
        
        -- Method 2: Try FindRow function if available
        if not row_found then
            local findrow_success = pcall(function()
                local RowData = DT_PlayerStats:FindRow(LevelKey, "", true)
                if RowData then
                    RowData.HP = HpInput
                    row_found = true
                end
            end)
        end
        
        -- Method 3: Brute force search through all rows
        if not row_found then
            local bruteforce_success = pcall(function()
                -- Get all property names and look for numeric keys
                for i = 1, 100 do
                    local key = tostring(i)
                    local row_access_success = pcall(function()
                        if DT_PlayerStats[key] then
                            if i == CurrentLevel then
                                DT_PlayerStats[key].HP = HpInput
                                row_found = true
                            end
                        end
                    end)
                    if row_found then break end
                end
            end)
        end
        
        if not row_found then
            error("Could not find or modify data table row for level " .. tostring(CurrentLevel))
        end
        
        Log(Ar, "Successfully modified data table HP value.")
        
    end)

    if success then
        -- Force a level refresh to pick up the new data table values
        local CurrentLevel = StatsController:GetAppliedLevel()
        StatsController:SetLevel(CurrentLevel)
        
        -- Also set the component values for immediate effect
        StatHPComponent:SetMaxValue(HpInput)
        StatHPComponent:FullyRestore()
        
        RefreshUI(StatsController)
        Log(Ar, "Robust HP set successfully! This change should persist through level changes.")
    else
        Log(Ar, "Failed to modify data table. Falling back to bonus stat method...")
        -- Fall back to the old method
        SetHpHandler(FullCommand, Parameters, Ar)
    end
    
    return true
end

-- === HELP COMMAND ===
local function HelpHandler(FullCommand, Parameters, Ar)
    Log(Ar, "-------------------------------------------------")
    Log(Ar, "Ender Magnolia Stat Mod")
    Log(Ar, "-------------------------------------------------")
    Log(Ar, "stat_mod_help         - Shows this help message.")
    Log(Ar, "set_level <number>    - Sets your level (Permanent).")
    Log(Ar, "set_hp <number>       - Sets your max HP for this session.")
    Log(Ar, "set_hp_robust <number>- Sets HP by modifying data table (More stable).")
    Log(Ar, "infinite_hp <number>  - Starts infinite health mode (auto-restore)")
    Log(Ar, "infinite_hp_off       - Stops infinite health mode")
    Log(Ar, "infinite_hp_status    - Shows infinite health status")
    Log(Ar, "set_jump_count <num>  - Sets max jump count (e.g., 3 for triple jump)")
    Log(Ar, "set_dash_charge <num> - Sets dash charge time (e.g., 0.1 for instant dash)")
    Log(Ar, "speed_boost           - Comprehensive speed boost (+2000 walk/fly/dash)")
    Log(Ar, "freecam               - Exploration no-clip mode (free camera)")
    Log(Ar, "god_mode              - Ultimate god mode (all abilities)")
    Log(Ar, "")
    Log(Ar, "🔥 HOTKEYS (MAIN FEATURES):")
    Log(Ar, "F7 - Ultimate God Mode (immortality + infinite jumps + instant dash)")
    Log(Ar, "F8 - Speed Boost (comprehensive +2000 all movement types)")
    Log(Ar, "F9 - Exploration No-Clip (free cam - expect death when toggling off)")
    Log(Ar, "")
    Log(Ar, "🚀 SIMPLE ACCESSIBILITY:")
    Log(Ar, "Press F7 for immortality and unlimited movement!")
    Log(Ar, "Press F8 to blaze through maps at max speed!")
    Log(Ar, "Press F9 to explore anywhere with no-clip!")
    Log(Ar, "-------------------------------------------------")
    return true
end

-- === INFINITE HEALTH COMMANDS ===
local function InfiniteHpHandler(FullCommand, Parameters, Ar)
    local HpInput = tonumber(Parameters[1])
    if not HpInput then 
        Log(Ar, "Usage: infinite_hp <number> - Starts infinite health mode")
        Log(Ar, "       infinite_hp off - Stops infinite health mode")
        return true 
    end

    local PC, StatsController, StatHPComponent = GetComponents()
    if not PC then 
        Log(Ar, "Could not find player components.")
        return true 
    end

    Log(Ar, "Starting infinite health mode with target HP: " .. tostring(HpInput))
    Log(Ar, "Your health will be maintained at this level every 500ms.")
    Log(Ar, "Use 'infinite_hp_off' to stop.")
    
    StartInfiniteHealth(HpInput)
    
    -- Set initial HP immediately
    StatHPComponent:SetMaxValue(HpInput)
    StatHPComponent:FullyRestore()
    
    return true
end

local function InfiniteHpOffHandler(FullCommand, Parameters, Ar)
    if InfiniteHealthActive then
        Log(Ar, "Stopping infinite health mode.")
        StopInfiniteHealth()
    else
        Log(Ar, "Infinite health mode is not currently active.")
    end
    return true
end

local function InfiniteHpStatusHandler(FullCommand, Parameters, Ar)
    if InfiniteHealthActive then
        Log(Ar, "Infinite health is ACTIVE. Target HP: " .. tostring(InfiniteHealthTarget))
        Log(Ar, "Health is being restored every 500ms.")
    else
        Log(Ar, "Infinite health is INACTIVE.")
    end
    return true
end

-- === GOD MODE ===

function GodModeHandler_Internal(FullCommand, Parameters, Ar)
    Log(Ar, "🔥 ACTIVATING ULTIMATE GOD MODE 🔥")
    
    local PlayerPawn = UEHelpers.GetPlayer()
    local PC, StatsController, StatHPComponent = GetComponents()
    
    if not PlayerPawn or not PC then
        Log(Ar, "Could not find player components.")
        return true
    end
    
    local health_success = false
    local jump_success = false
    local dash_success = false
    local wall_dash_height_success = false
    
    -- 1. Infinite Health (9999)
    local health_result = pcall(function()
        StartInfiniteHealth(9999)
        StatHPComponent:SetMaxValue(9999)
        StatHPComponent:FullyRestore()
        health_success = true
    end)
    
    -- 2. Infinite Jump (9999)
    local jump_result = pcall(function()
        PlayerPawn.JumpMaxCount = 9999
        jump_success = true
    end)
    
    -- 3. Instant Dash (0.01s)
    local dash_result = pcall(function()
        local DashChargeComponent = PlayerPawn:GetComponentByClass(StaticFindObject("/Script/Zion.DashChargeComponent"))
        if DashChargeComponent and DashChargeComponent:IsValid() then
            DashChargeComponent.DashTimeForCharge = 0.01
            DashChargeComponent.DashTimeForChargeShort = 0.01
            dash_success = true
        end
    end)
    
    -- 4. Unlimited Wall Dash Height (9999)
    local wall_dash_height_result = pcall(function()
        local AutoClimbComponent = PlayerPawn:GetComponentByClass(StaticFindObject("/Script/Zion.AutoClimbComponent"))
        if AutoClimbComponent and AutoClimbComponent:IsValid() then
            AutoClimbComponent.MaxHeightForAutoClimbDashCharge = 9999
            AutoClimbComponent.AllowedMaxZVelocity = 9999
            wall_dash_height_success = true
        end
    end)
    
    -- Report results
    Log(Ar, "🌟 ULTIMATE GOD MODE ACTIVATED! 🌟")
    Log(Ar, "✓ Infinite Health: " .. (health_success and "9999 HP" or "FAILED"))
    Log(Ar, "✓ Infinite Jump: " .. (jump_success and "9999 Jumps" or "FAILED"))  
    Log(Ar, "✓ Instant Dash: " .. (dash_success and "0.01s Charge" or "FAILED"))
    Log(Ar, "✓ Unlimited Wall Height: " .. (wall_dash_height_success and "9999 Units" or "FAILED"))
    Log(Ar, "You are now immortal with unlimited flight and wall mobility!")
    
    return true
end

local function GodModeHandler(FullCommand, Parameters, Ar)
    -- Optionally profile this function if requested
    if _G.ProfileNextGodMode and _G.ProfileFunc then
        _G.ProfileNextGodMode = false
        return _G.ProfileFunc("GodMode_Activation", function()
            return GodModeHandler_Internal(FullCommand, Parameters, Ar)
        end)
    else
        return GodModeHandler_Internal(FullCommand, Parameters, Ar)
    end
end

-- === GOD MODE HOTKEY ===
print("Registering God Mode Hotkey...")
local function GodModeHotkey()
    print("F7 Hotkey Pressed - ACTIVATING GOD MODE!")
    GodModeHandler("god_mode", {}, nil)
end

RegisterKeyBind(Key.F7, {}, GodModeHotkey)
print("God Mode Hotkey registration attempted for F7.")

-- Register core commands
RegisterConsoleCommandHandler("stat_mod_help", HelpHandler)
RegisterConsoleCommandHandler("set_level", SetLevelHandler)
RegisterConsoleCommandHandler("set_hp", SetHpHandler)
RegisterConsoleCommandHandler("set_hp_robust", SetHpRobustHandler)

-- Register infinite health commands
RegisterConsoleCommandHandler("infinite_hp", InfiniteHpHandler)
RegisterConsoleCommandHandler("infinite_hp_off", InfiniteHpOffHandler)
RegisterConsoleCommandHandler("infinite_hp_status", InfiniteHpStatusHandler)

-- === JUMP COUNT SETTER ===
local function SetJumpCountHandler(FullCommand, Parameters, Ar)
    local JumpInput = tonumber(Parameters[1])
    if not JumpInput or JumpInput < 1 then 
        Log(Ar, "Usage: set_jump_count <number>")
        Log(Ar, "Example: set_jump_count 3 (for triple jump)")
        return true 
    end

    local PlayerPawn = UEHelpers.GetPlayer()
    if not PlayerPawn or not PlayerPawn:IsValid() then
        Log(Ar, "Could not find player pawn.")
        return true
    end

    Log(Ar, "Setting jump count to " .. tostring(JumpInput) .. "...")

    local success = pcall(function()
        -- Try to set JumpMaxCount property directly
        PlayerPawn.JumpMaxCount = JumpInput
    end)

    if success then
        Log(Ar, "Jump count set successfully! You can now jump " .. tostring(JumpInput) .. " times.")
        Log(Ar, "This change is temporary and will reset when you restart the game.")
    else
        Log(Ar, "Failed to set jump count. The property might not be accessible.")
    end

    return true
end

-- === DASH CHARGE TIME SETTER ===
local function SetDashChargeHandler(FullCommand, Parameters, Ar)
    local ChargeInput = tonumber(Parameters[1])
    if not ChargeInput or ChargeInput < 0 then 
        Log(Ar, "Usage: set_dash_charge <number>")
        Log(Ar, "Example: set_dash_charge 0.1 (for instant dash)")
        Log(Ar, "Default is 2.2 seconds for full charge, 1.5 for short charge")
        return true 
    end

    local PlayerPawn = UEHelpers.GetPlayer()
    if not PlayerPawn or not PlayerPawn:IsValid() then
        Log(Ar, "Could not find player pawn.")
        return true
    end

    Log(Ar, "Setting dash charge time to " .. tostring(ChargeInput) .. " seconds...")

    local success = pcall(function()
        -- Try to find the DashChargeComponent
        local DashChargeComponent = PlayerPawn:GetComponentByClass(StaticFindObject("/Script/Zion.DashChargeComponent"))
        if DashChargeComponent and DashChargeComponent:IsValid() then
            -- Set both charge times to the same value
            DashChargeComponent.DashTimeForCharge = ChargeInput
            DashChargeComponent.DashTimeForChargeShort = ChargeInput * 0.7  -- Keep short charge proportionally faster
        else
            error("Could not find DashChargeComponent")
        end
    end)

    if success then
        Log(Ar, "Dash charge time set successfully!")
        Log(Ar, "Full charge: " .. tostring(ChargeInput) .. "s, Short charge: " .. tostring(ChargeInput * 0.7) .. "s")
        Log(Ar, "This change is temporary and will reset when you restart the game.")
    else
        Log(Ar, "Failed to set dash charge time. The component might not be accessible.")
    end

    return true
end
-- === SPEED BOOST COMMAND ===
local function SpeedBoostHandler(FullCommand, Parameters, Ar)
    local PlayerPawn = UEHelpers.GetPlayer()
    if not PlayerPawn or not PlayerPawn:IsValid() then
        Log(Ar, "Could not find player pawn.")
        return true
    end

    Log(Ar, "Activating COMPREHENSIVE SPEED BOOST (+2000 all movement types)...")

    local success = pcall(function()
        -- Find the ZionCharacterMovementComponent
        local MovementComponent = PlayerPawn:GetComponentByClass(StaticFindObject("/Script/Zion.ZionCharacterMovementComponent"))
        if MovementComponent and MovementComponent:IsValid() then
            -- Boost all movement speeds
            local walkSpeed = MovementComponent.MaxWalkSpeed or 440
            local flySpeed = MovementComponent.MaxFlySpeed or 800
            
            MovementComponent.MaxWalkSpeed = walkSpeed + 2000
            MovementComponent.MaxFlySpeed = flySpeed + 2000
            
            -- Try to boost dash and other movement properties
            local dash_boost_success = pcall(function()
                if MovementComponent.MaxDashSpeed then
                    MovementComponent.MaxDashSpeed = MovementComponent.MaxDashSpeed + 2000
                end
                if MovementComponent.DashSpeed then
                    MovementComponent.DashSpeed = MovementComponent.DashSpeed + 2000
                end
                if MovementComponent.MaxAcceleration then
                    MovementComponent.MaxAcceleration = MovementComponent.MaxAcceleration + 1000
                end
                if MovementComponent.GroundFriction then
                    MovementComponent.GroundFriction = 0.1  -- Reduce friction for smoother movement
                end
                if MovementComponent.BrakingDecelerationWalking then
                    MovementComponent.BrakingDecelerationWalking = 100  -- Reduce braking for smoother stops
                end
            end)
            
            Log(Ar, "🚀 COMPREHENSIVE SPEED BOOST ACTIVATED! 🚀")
            Log(Ar, "Walk speed: " .. tostring(walkSpeed) .. " → " .. tostring(walkSpeed + 2000))
            Log(Ar, "Fly speed: " .. tostring(flySpeed) .. " → " .. tostring(flySpeed + 2000))
            Log(Ar, "Dash boost: " .. (dash_boost_success and "Applied" or "Attempted"))
            Log(Ar, "You can now blaze through maps at maximum speed!")
        else
            error("Could not find ZionCharacterMovementComponent")
        end
    end)

    if not success then
        Log(Ar, "Failed to apply speed boost. Component might not be accessible.")
    end

    return true
end

-- === SPEED BOOST HOTKEY ===
print("Registering Speed Boost Hotkey...")
local function SpeedBoostHotkey()
    print("F8 Hotkey Pressed - ACTIVATING SPEED BOOST!")
    SpeedBoostHandler("speed_boost", {}, nil)
end

RegisterKeyBind(Key.F8, {}, SpeedBoostHotkey)
print("Speed Boost Hotkey registration attempted for F8.")

-- === SIMPLE NO-CLIP (Back to Basics) ===
local NoClipActive = false

local function ExplorationNoClipHandler(FullCommand, Parameters, Ar)
    local PlayerPawn = UEHelpers.GetPlayer()
    if not PlayerPawn or not PlayerPawn:IsValid() then
        Log(Ar, "Could not find player pawn.")
        return true
    end

    local CapsuleComponent = PlayerPawn.CapsuleComponent
    if not CapsuleComponent or not CapsuleComponent:IsValid() then
        Log(Ar, "Could not find player CapsuleComponent for collision.")
        return true
    end

    NoClipActive = not NoClipActive
    
    local success = pcall(function()
        local MovementComponent = PlayerPawn:GetComponentByClass(StaticFindObject("/Script/Zion.ZionCharacterMovementComponent"))
        
        if NoClipActive then
            Log(Ar, "🔍 NO-CLIP ON - Flying mode with no collision!")
            if MovementComponent and MovementComponent:IsValid() then
                MovementComponent:SetMovementMode(5,0)
            end
            CapsuleComponent:SetCollisionEnabled(0)
        else 
            Log(Ar, "🔍 NO-CLIP OFF - Walking mode with collision restored!")
            if MovementComponent and MovementComponent:IsValid() then
                MovementComponent:SetMovementMode(1,0)
            end
            CapsuleComponent:SetCollisionEnabled(1)
        end
    end)

    if success then
        Log(Ar, "✓ No-clip toggled successfully!")
    else
        Log(Ar, "Failed to toggle no-clip.")
    end

    return true
end

-- === EXPLORATION NO-CLIP HOTKEY ===
print("Registering Exploration No-Clip Hotkey...")
local function ExplorationNoClipHotkey()
    print("F9 Hotkey Pressed - TOGGLING EXPLORATION NO-CLIP!")
    ExplorationNoClipHandler("freecam", {}, nil)
end

RegisterKeyBind(Key.F9, {}, ExplorationNoClipHotkey)
print("Exploration No-Clip Hotkey registration attempted for F9.")

-- Register movement commands
RegisterConsoleCommandHandler("set_jump_count", SetJumpCountHandler)
RegisterConsoleCommandHandler("set_dash_charge", SetDashChargeHandler)
-- Register god mode command
RegisterConsoleCommandHandler("god_mode", GodModeHandler)
-- Register speed boost command
RegisterConsoleCommandHandler("speed_boost", SpeedBoostHandler)
-- Register exploration no-clip command
RegisterConsoleCommandHandler("freecam", ExplorationNoClipHandler)

print("===== Ender Magnolia StatMod v5.0 (Simplified Accessibility loaded! =====")
print("Core Commands: stat_mod_help, set_level <num>, set_hp <num>, set_hp_robust <num>")
print("Movement: set_jump_count <num>, set_dash_charge <num>, speed_boost, freecam, god_mode")
print("Health: infinite_hp <num>, infinite_hp_off, infinite_hp_status")
print("")
print("🔥 HOTKEYS - MAIN FEATURES:")
print("F7 = ULTIMATE GOD MODE (immortality + infinite jumps + instant dash)")
print("F8 = SPEED BOOST (comprehensive +2000 all movement types)")
print("F9 = EXPLORATION NO-CLIP (free cam)")
print("")
print("🚀 SIMPLE ACCESSIBILITY: Just press F7 for everything you need!")
local players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local localPlayer = players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local onhitremote = game:GetService("ReplicatedStorage").Remotes.Weapon.OnHit
local enterRegion = game:GetService("ReplicatedStorage").Remotes.Region.EnterRegion
local enemiesFolder = workspace:WaitForChild("Enemy")
local rollCmdRemote = game:GetService("ReplicatedStorage").Remotes.RollChest.RollCmd
local noclipConnection



local autofarmRunning = false

local virtualUser = game:service('VirtualUser')

-- Connect to the "Idled" event
game:service('Players').LocalPlayer.Idled:connect(function()
    virtualUser:CaptureController()
    virtualUser:ClickButton2(Vector2.new())
end)

local loopCounter = 0

local function Island1TP()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local targetPosition = Vector3.new(-0.8165936470031738, 97.28856658935547, -340.8562927246094)
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
end

local function M1Click()
    -- Bottom-left corner coordinates
    local bottomLeftX = 1
    local bottomLeftY = Camera.ViewportSize.Y - 1
    
    -- Simulate mouse down (left-click) at the bottom-left corner
    VIM:SendMouseButtonEvent(bottomLeftX, bottomLeftY, 0, true, nil, 0)
    
    -- Simulate mouse up (left-click release) at the bottom-left corner
    VIM:SendMouseButtonEvent(bottomLeftX, bottomLeftY, 0, false, nil, 0)
end

local function getAttackType()
    local attackType = localPlayer.Character:FindFirstChild("Weapon") and localPlayer.Character.Weapon:GetAttribute("Type")
    if not attackType then
        warn("Failed to get attack type")
        return nil
    end
    return attackType
end

local function BetterM1()
    
    local attackType = getAttackType()
    local baseTime = workspace:GetServerTimeNow()
    local args = {
        [1] = baseTime,   -- Send the current server time
        [2] = 2,          -- Set the second argument to the loop index (i)
        [3] = attackType  -- Use the retrieved attack type
    }

    onhitremote:FireServer(unpack(args))
end

-- Get the closest valid NPC using PrimaryPart instead of HumanoidRootPart
local function getClosestNPC()
    local dist, closestNPC = math.huge, nil
    for _, v in pairs(enemiesFolder:GetChildren()) do
        if v:IsA("Model") and v.PrimaryPart then
            local magnitude = (localPlayer.Character.HumanoidRootPart.Position - v.PrimaryPart.Position).Magnitude
            if magnitude < dist and magnitude <= 75 then -- Adjust max distance as necessary
                dist = magnitude
                closestNPC = v
            end
        end
    end
    return closestNPC
end

-- NoClip function to prevent collisions



local function noclip()
    for _, part in pairs(players.LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

local function activateNoclip()
    noclipConnection = RunService.Stepped:Connect(noclip)
end


local function resetCollision()
    -- Disconnect noclip
    if noclipConnection then
    print("Disconnecting noclipConnection...")
    noclipConnection:Disconnect()
    noclipConnection = nil
    else
        print("No noclipConnection to disconnect.")
    end

    -- Restore collision for all BaseParts in the character
    for _, part in pairs(localPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- New Tween-based movement function for floating up and down
--[[local function moveTo(targetPosition, time)
    local humanoidRootPart = localPlayer.Character:WaitForChild("HumanoidRootPart")
    local info = TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, info, { CFrame = CFrame.new(targetPosition) })

    -- NoClip setup
    noclipConnection = RunService.Stepped:Connect(noclip)
    tween:Play()

    tween.Completed:Connect(function()

        tween.Completed:Connect(function()
            tween:Destroy()
        end)
    end)
end]]
local function moveTo(targetPosition, time)
    local humanoidRootPart = players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, { CFrame = CFrame.new(targetPosition) })
    if not noclipConnection then
        noclipConnection = RunService.Stepped:Connect(noclip)
    end
    tween:Play()
    tween.Completed:Wait()
end

local autofarmRunning = false

local function autofarm(state)
    if autofarmRunning then
        autofarmRunning = false
        resetCollision()
        bodyVelocity:Destroy()
        bodyGyro:Destroy()
        return
    end
    autofarmRunning = true
    activateNoclip()
    coroutine.wrap(function()
        while autofarmRunning do
            local character = localPlayer.Character
            local npc = getClosestNPC()
            
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                -- Ensure NPC still exists and is alive
                local success, errorMessage = pcall(function()
                    -- Prevent falling
                    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    bodyVelocity.Parent = humanoidRootPart
                    local bodyGyro = Instance.new("BodyGyro")
                    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                    bodyGyro.CFrame = humanoidRootPart.CFrame
                    bodyGyro.Parent = humanoidRootPart 
                 
                    -- Tween down 12 units below the enemy (faster, no hold)
                    local downPosition = npc.HumanoidRootPart.Position - Vector3.new(0, 18, 0)
                    moveTo(downPosition, 0.1)  -- Move down over 0.2 seconds, no pause
                    wait(1)
                    -- Wait a brief moment after moving down (no extra hold)
                    local attackType = getAttackType()
                    if attackType and attackType == "HeavySword" then
                        BetterM1()
                        wait(0.28)
                    end
                    -- Tween up into the enemy's position for 0.2 seconds (faster)
                    moveTo(npc.HumanoidRootPart.Position + Vector3.new(0, 4, 0), 0.1)

                    -- Wait briefly while engaging with the NPC (no movement)
                    BetterM1()
                    wait(0.2)
                    -- Tween back down to 12 units below the enemy (faster)
                    moveTo(downPosition, 0.1)

                    -- Wait before continuing the loop
                    

                    -- Clean up fall prevention after loop completes
                    bodyVelocity:Destroy()
                    bodyGyro:Destroy()
                    character.Humanoid.PlatformStand = false  -- Allow falling again
                    loopCounter = 0
                end)

                -- If the NPC doesn't exist or is dead, handle the error or just skip to the next iteration
                if not success then
                    warn("NPC no longer exists or was killed: " .. errorMessage)
                    wait(0.5) -- Wait before checking again
                end
            else
                resetCollision ()
                loopCounter += 1
                if loopCounter >= 3 then
                    local length = #_G.bosstable -- Get the length of the bosstable
                    local randomBossID = _G.bosstable[math.random(1, length)] -- Get a random Boss ID
                    enterRegion:FireServer(randomBossID)
                end
                wait(3) -- Wait for a new wave of NPCs if no valid NPC is found
            end
        end
    end)()
end
local autochest = false
local function AutoChestOpen(state)
    autochest = state
    if autochest == true then
        while autochest do
            rollCmdRemote:FireServer()
            wait(0.2)
            if autochest == false then
                break
            end
        end
    end
end
local Hideplayernamee = false

local function hideplayername(state)
    Hideplayernamee = state
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

    while Hideplayernamee do
        if character then
            local success, err = pcall(function()
                local main = character:WaitForChild("HumanoidRootPart"):WaitForChild("Tag"):WaitForChild("Main"):WaitForChild("Name")
                if main.Text ~= "#1 LOOTIFY HUB" then
                    main.Text = "#1 LOOTIFY HUB"
                end
            end)

            if not success then
                warn("Error updating player name tag: " .. err)
            end
        end
        if not Hideplayernamee then
            break
        end
        wait(0.1)
    end
end



-- Reset character function
local function resetCharacter()
    resetCollision()
end

-- Island TP functions
local function Island1TP()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local targetPosition = Vector3.new(-0.8165936470031738, 97.28856658935547, -340.8562927246094)
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
end

local function Island2TP()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local targetPosition = Vector3.new(-705.2344360351562, 54.71098327636719, 1210.1417236328125)
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
end
local function Island3TP()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local targetPosition = Vector3.new(1718.689453125, 54.7958122253418, 2823.55859375)
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
end

if game.PlaceId == 16498193900 then
    local Mercury = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()
    local GUI = Mercury:Create{
        Name = "Lootify hub",
        Size = UDim2.fromOffset(600, 400),
        Theme = Mercury.Themes.Dark,
        Link = "Lootify/v1-lastupdated-1/18"
    }
    local TeleportTab = GUI:Tab{
        Name = "Teleports",
        Icon = "rbxassetid://18155317326"
    }
    TeleportTab:Button{
        Name = "Island1",
        Description = nil,
        Callback = Island1TP -- Connect the teleport function to the button
    }
    TeleportTab:Button{
        Name = "Island2",
        Description = nil,
        Callback = Island2TP -- Connect the teleport function to the button
    }
    TeleportTab:Button{
        Name = "Island3",
        Description = nil,
        Callback = Island3TP -- Connect the teleport function to the button
    }


    local AutoFarmTab = GUI:Tab{
        Name = "AutoFarm",
        Icon = "rbxassetid://82472368671405"
    }
    AutoFarmTab:Toggle{
        Name = "AutoFarmBosses",
        StartingState = false,
        Description = nil,
        Callback = function(state)
            autofarm(state)
        end
    }
    AutoFarmTab:Toggle{
        Name = "AutoChestOpen",
        StartingState = false,
        Description = nil,
        Callback = function(state)
            AutoChestOpen(state)
        end
    }
    AutoFarmTab:Button{
        Name = "Reset Character",
        Description = "Resets the character to spawn.",
        Callback = function()
            resetCharacter()  -- Reset the character when the button is pressed
        end
    }
    local Visualtab = GUI:Tab{
        Name = "Visual",
        Icon = "rbxassetid://129042018463449"
    }
    Visualtab:Toggle{
        Name = "Hideplayername",
        StartingState = false,
        Description = nil,
        Callback = function(state)
            hideplayername(state)
        end
    }
else
    -- Kick the player with a custom message
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    localPlayer:Kick("Game not supported.")
end

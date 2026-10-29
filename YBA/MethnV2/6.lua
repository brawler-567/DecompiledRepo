return function(Window, player, QuestTab, config)
	local enableNoclip = config.enableNoclip
	local disableNoclip = config.disableNoclip
	local function isSelling()
		if type(config.isSelling) ~= "function" then return false end
		local ok, value = pcall(config.isSelling)
		return ok and value == true
	end

	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")
	local Stats = game:GetService("Stats")
	local UserInputService = game:GetService("UserInputService")
	local PhysicsService = game:GetService("PhysicsService")
	local MarketplaceService = game:GetService("MarketplaceService")
	local TeleportService = game:GetService("TeleportService")

	local PlayerStats = player:WaitForChild("PlayerStats")
	local PlayerLevel = PlayerStats:WaitForChild("Level")
	local PlayerPity = PlayerStats:WaitForChild("PityCount")
	local PlayerStand = PlayerStats:WaitForChild("Stand")
	local PlayerPrestige = PlayerStats:WaitForChild("Prestige")
	local PlayerSpec = PlayerStats:WaitForChild("Spec")
	local PlayerMoney = PlayerStats:WaitForChild("Money")
	local ClientFX = ReplicatedStorage:WaitForChild("ClientFX")
	local Dialogues = workspace:WaitForChild("Dialogues")

	local function GetPlayer()
		return game.Players.LocalPlayer
	end

	local function GetCharacter()
		return GetPlayer().Character or GetPlayer().CharacterAdded:Wait()
	end

	local function GetHRP()
		local Character = GetCharacter()
		return Character and Character:FindFirstChild("HumanoidRootPart")
	end

	local function EldiabloIsMobile()
		if rawget(_G, "mobile_ui") then return true end
		if type(shared) == "table" and rawget(shared, "mobile_ui") then return true end
		if getgenv then
			local ok, g = pcall(getgenv)
			if ok and type(g) == "table" and (rawget(g, "mobile_ui") or rawget(g, "Eldiablo_Mobile")) then
				return true
			end
		end
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end

	local farmNoclipConnections = setmetatable({}, {__mode = "k"})
	local function farmEnsureNoclip(char)
		if not char then return end
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
		if not farmNoclipConnections[char] then
			farmNoclipConnections[char] = char.DescendantAdded:Connect(function(v)
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end)
		end
	end

	local function farmReleaseNoclip(char)
		if not char then return end
		local connection = farmNoclipConnections[char]
		if connection then
			pcall(function() connection:Disconnect() end)
			farmNoclipConnections[char] = nil
		end
	end

	local function farmThrottledHeartbeat(fn, fpsMobile, fpsDesktop)
		fpsMobile = fpsMobile or 20
		fpsDesktop = fpsDesktop or 45
		local interval = 1 / (EldiabloIsMobile() and fpsMobile or fpsDesktop)
		local accum = 0
		return RunService.Heartbeat:Connect(function(dt)
			accum = accum + dt
			if accum < interval then return end
			accum = accum - interval
			fn(dt)
		end)
	end

	local function farmStepWait(default)
		default = default or 0
		return EldiabloIsMobile() and math.max(default, 0.06) or default
	end

	local function getRootPart()
		local char = GetCharacter()
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function teleportUp()
		local hrp = getRootPart()
		if not hrp then return end
		local fallY = workspace.FallenPartsDestroyHeight
		local p = hrp.Position
		if p.Y < fallY + 100 then
			hrp.Position = Vector3.new(p.X, fallY + 180, p.Z)
		end
		hrp.Anchored = true
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		local pad = Instance.new("Part")
		pad.Name = tostring(math.random(1, 6764))
		pad.Anchored = true
		pad.Size = Vector3.new(150, 1, 150)
		pad.Transparency = 1
		pad.CFrame = hrp.CFrame * CFrame.new(0, 200, 0)
		pad.Parent = workspace
		hrp.CFrame = pad.CFrame * CFrame.new(0, 6, 0)
		hrp.Anchored = false
		task.delay(15, function()
			if pad and pad.Parent then
				pad:Destroy()
			end
		end)
	end

	local function notify(title, msg, duration, kind)
		pcall(function()
			if Window and Window.Notify then
				Window:Notify(title, msg, type(duration) == "number" and duration or 4)
			end
		end)
	end

	local function clearFocusCam(char)
		if not char then return end
		pcall(function()
			local fc = char:FindFirstChild("FocusCam")
			if fc then
				fc:Destroy()
			end
		end)
	end

	local function fireproximityprompt(prompt)
		if not prompt then return end
		pcall(function()
			if type(getconnections) == "function" and prompt.Triggered then
				for _, conn in pairs(getconnections(prompt.Triggered)) do
					conn:Fire(prompt)
				end
				return
			end
			if type(prompt.InputHoldBegin) == "function" then
				prompt:InputHoldBegin()
				task.wait(0.1)
				if type(prompt.InputHoldEnd) == "function" then
					prompt:InputHoldEnd()
				end
			end
		end)
	end

	local STAND_KEEPALIVE_EXCLUDED = {
		["Beach Boy"] = true,
		["Hermit Purple"] = true,
		["Mr. President"] = true,
		["Sex Pistols"] = true,
		["Anubis"] = true,
		["None"] = true,
	}

	local FarmConfig = {
		KillLoopDelay = 0,
		QuestCheckDelay = 0.35,
		FarmingMethod = "Auto (Detect)",
		Distance = -28,
	}

	local FarmState = {
		Active = false,
		CurrentQuest = nil,
		CompletedQuest = false,
		OriginalCFrame = nil,
	}

	local QuestRuntime = {
		ManualQuest = nil,
		Phase = "Idle",
		Message = "Quest Farm is ready.",
		LastAcceptAttempt = 0,
		LastAcceptQuest = nil,
		LastTurnInAttempt = 0,
		ActiveQuest = nil,
		DialogueTarget = nil,
		OverrideRequested = false,
	}
	local QuestStatusLabel = nil
	local QuestProgressLabel = nil

	local function setQuestStatus(phase, message)
		local nextPhase = tostring(phase or "Ready")
		local nextMessage = tostring(message or "")
		local changed = QuestRuntime.Phase ~= nextPhase or QuestRuntime.Message ~= nextMessage
		if changed then
			QuestRuntime.Phase = nextPhase
			QuestRuntime.Message = nextMessage
			pcall(function()
				if QuestStatusLabel and QuestStatusLabel.SetDesc then
					QuestStatusLabel:SetDesc(QuestRuntime.Message)
				end
			end)
		end

		if nextPhase == "Farming selected target" then
			pcall(function()
				if QuestProgressLabel and QuestProgressLabel.SetDesc then
					QuestProgressLabel:SetDesc(nextMessage)
				end
			end)
		end
	end

	local QuestNPCView = {
		Active = false,
		Target = nil,
		Camera = nil,
		CameraType = nil,
		CameraSubject = nil,
		CameraCFrame = nil,
		CameraFocus = nil,
	}
	local QUEST_VIEW_BEFORE = "Phantom_QuestFarm_NPCView_BeforeCamera"
	local QUEST_VIEW_AFTER = "Phantom_QuestFarm_NPCView_AfterCamera"

	local function keepQuestNPCInView()
		if not QuestNPCView.Active then return end
		local camera = workspace.CurrentCamera
		if camera then QuestNPCView.Camera = camera end
		camera = QuestNPCView.Camera
		local target = QuestNPCView.Target
		if not camera or not target or not target.Parent then return end
		local subject = target:FindFirstChildOfClass("Humanoid") or target:FindFirstChild("HumanoidRootPart")
		if not subject or not subject.Parent then return end
		if camera.CameraType ~= Enum.CameraType.Custom then
			camera.CameraType = Enum.CameraType.Custom
		end
		if camera.CameraSubject ~= subject then
			camera.CameraSubject = subject
		end
	end

	local function startQuestNPCView(npc)
		if not npc then return end
		if QuestNPCView.Active then
			QuestNPCView.Target = npc
			keepQuestNPCInView()
			return
		end
		local camera = workspace.CurrentCamera
		QuestNPCView.Camera = camera
		QuestNPCView.CameraType = camera and camera.CameraType or nil
		QuestNPCView.CameraSubject = camera and camera.CameraSubject or nil
		QuestNPCView.CameraCFrame = camera and camera.CFrame or nil
		QuestNPCView.CameraFocus = camera and camera.Focus or nil
		QuestNPCView.Target = npc
		QuestNPCView.Active = true
		pcall(function() RunService:UnbindFromRenderStep(QUEST_VIEW_BEFORE) end)
		pcall(function() RunService:UnbindFromRenderStep(QUEST_VIEW_AFTER) end)
		RunService:BindToRenderStep(QUEST_VIEW_BEFORE, Enum.RenderPriority.Camera.Value - 1, keepQuestNPCInView)
		RunService:BindToRenderStep(QUEST_VIEW_AFTER, Enum.RenderPriority.Camera.Value + 1, keepQuestNPCInView)
		keepQuestNPCInView()
	end

	local function stopQuestNPCView()
		if not QuestNPCView.Active then return end
		pcall(function() RunService:UnbindFromRenderStep(QUEST_VIEW_BEFORE) end)
		pcall(function() RunService:UnbindFromRenderStep(QUEST_VIEW_AFTER) end)
		local camera = workspace.CurrentCamera or QuestNPCView.Camera
		if camera then
			pcall(function()
				camera.CameraType = QuestNPCView.CameraType or Enum.CameraType.Custom
				if QuestNPCView.CameraSubject and QuestNPCView.CameraSubject.Parent then
					camera.CameraSubject = QuestNPCView.CameraSubject
				end
				if QuestNPCView.CameraCFrame then camera.CFrame = QuestNPCView.CameraCFrame end
				if QuestNPCView.CameraFocus then camera.Focus = QuestNPCView.CameraFocus end
			end)
		end
		QuestNPCView.Active = false
		QuestNPCView.Target = nil
		QuestNPCView.Camera = nil
		QuestNPCView.CameraType = nil
		QuestNPCView.CameraSubject = nil
		QuestNPCView.CameraCFrame = nil
		QuestNPCView.CameraFocus = nil
	end

	local function zeroFarmVelocity(part)
		if not part then return end
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end

	local QuestStickState = _G.__MethionQuestStickState or {
		Target = nil,
		LastMoveAt = 0,
		LastGoal = nil,
	}
	QuestStickState.LastGoal = nil
	_G.__MethionQuestStickState = QuestStickState

	local function stickFarmPartsToNPC(char, npc, handheld)
		if not char or not npc or not npc.Parent then return end
		local playerRoot = char:FindFirstChild("HumanoidRootPart")
		local npcRoot = npc:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		if not playerRoot or not npcRoot or not humanoid or humanoid.Health <= 0 then return end

		local verticalOffset = handheld and 1.5 or (tonumber(FarmConfig.Distance) or -28)
		local backOffset = handheld and 2.5 or 1.8
		local follow = npcRoot.CFrame - npcRoot.CFrame.LookVector * backOffset
		follow = follow + Vector3.new(0, verticalOffset, 0)
		local targetCFrame = CFrame.lookAt(follow.Position, npcRoot.Position)

		local stand = char:FindFirstChild("StandMorph")
		local standRoot = stand and (stand.PrimaryPart or stand:FindFirstChild("HumanoidRootPart"))
		if not handheld and standRoot then
			local standFollow = npcRoot.CFrame - npcRoot.CFrame.LookVector * 2.5
			standFollow = standFollow + Vector3.new(0, 1.5, 0)
			standRoot.CFrame = CFrame.lookAt(standFollow.Position, npcRoot.Position)
			zeroFarmVelocity(standRoot)
		end

		playerRoot.CFrame = targetCFrame
		zeroFarmVelocity(playerRoot)
	end

	local FarmUtil = {}
	FarmUtil.CurrentEnemy = nil

	function FarmUtil.GetCharacter()
		return Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	end

	function FarmUtil.GetHRP()
		local char = FarmUtil.GetCharacter()
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function isHandheldMethod()
		local m = FarmConfig.FarmingMethod
		if type(m) == "table" then m = m[1] end
		if m == "Handheld/Fist" then
			return true
		end
		if m == "Auto" or m == "Auto (Detect)" then
			return STAND_KEEPALIVE_EXCLUDED[Players.LocalPlayer.PlayerStats.Stand.Value] == true
		end
		return false
	end

	function FarmUtil.EquipStand()
		local char = FarmUtil.GetCharacter()
		if not char then return false end
		if isHandheldMethod() then
			if char:FindFirstChildWhichIsA("Tool") then
				return true
			end
			local rf = char:FindFirstChild("RemoteFunction")
			if rf then
				pcall(function()
					rf:InvokeServer("ToggleStand", "Toggle")
				end)
				task.wait(0.25)
				return char:FindFirstChildWhichIsA("Tool") ~= nil
			end
			return true
		end
		local ss = char:FindFirstChild("SummonedStand")
		if ss and ss.Value then
			return true
		end
		local rf = char:FindFirstChild("RemoteFunction")
		if rf then
			pcall(function()
				rf:InvokeServer("ToggleStand", "Toggle")
			end)
			task.wait(0.25)
			ss = char:FindFirstChild("SummonedStand")
			return ss and ss.Value
		end
		return false
	end

	function FarmUtil.UseMove(move)
		local char = FarmUtil.GetCharacter()
		if char and char:FindFirstChild("RemoteEvent") then
			pcall(function()
				char.RemoteEvent:FireServer("Attack", move)
			end)
		end
	end

	function FarmUtil.CountItem(itemName)
		local count = 0
		for _, v in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
			if v.Name == itemName then
				count = count + 1
			end
		end
		local char = FarmUtil.GetCharacter()
		if char then
			local tool = char:FindFirstChildWhichIsA("Tool")
			if tool and tool.Name == itemName then
				count = count + 1
			end
		end
		return count
	end

	local function clickThroughDialogue()
		local plr = game:GetService("Players").LocalPlayer
		local dialogueGui = plr.PlayerGui:FindFirstChild("DialogueGui")
		local startTime = tick()
		while dialogueGui and dialogueGui.Parent and tick() - startTime < 5 do
			pcall(function()
				local frame = dialogueGui:FindFirstChild("Frame")
				if not frame then return end
				local clickContinue = frame:FindFirstChild("ClickContinue")
				if clickContinue then
					for _, conn in pairs(getconnections(clickContinue.MouseButton1Click)) do
						conn:Fire()
					end
				end
				local options = frame:FindFirstChild("Options")
				if options then
					local option1 = options:FindFirstChild("Option1")
					if option1 then
						local textButton = option1:FindFirstChild("TextButton")
						if textButton then
							for _, conn in pairs(getconnections(textButton.MouseButton1Click)) do
								conn:Fire()
							end
						end
					end
				end
			end)
			task.wait(0.1)
			dialogueGui = plr.PlayerGui:FindFirstChild("DialogueGui")
		end
	end

	local QuestDialogueBridge = config and config.dialogue or {}

	local function normalizeDialogueText(value)
		local text = string.lower(tostring(value or ""))
		text = text:gsub("[^%w%s]", " ")
		text = text:gsub("%s+", " ")
		return text:match("^%s*(.-)%s*$") or ""
	end

	local function containsDialoguePhrase(text, phrase)
		local haystack = " " .. normalizeDialogueText(text) .. " "
		local needle = " " .. normalizeDialogueText(phrase) .. " "
		return needle ~= "  " and haystack:find(needle, 1, true) ~= nil
	end

	local function questOptionText(button)
		if not button then return "" end
		local pieces = {}
		if button:IsA("TextButton") and button.Text ~= "" then table.insert(pieces, button.Text) end
		for _, child in ipairs(button:GetDescendants()) do
			if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox")) and child.Text and child.Text ~= "" then
				table.insert(pieces, child.Text)
			end
		end
		return normalizeDialogueText(table.concat(pieces, " "))
	end

	local function questDialogueMatchesNPC(gui, npc, dialogueName)
		if not gui or not npc then return false end
		local pieces = {}
		for _, child in ipairs(gui:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
				if child.Text and child.Text ~= "" then table.insert(pieces, child.Text) end
			end
		end
		local joined = normalizeDialogueText(table.concat(pieces, " "))
		local npcName = normalizeDialogueText(npc.Name)
		npcName = npcName:gsub(" lvl %d+.*$", "")
		local dialog = normalizeDialogueText(dialogueName)
		return (npcName ~= "" and containsDialoguePhrase(joined, npcName))
			or (dialog ~= "" and #dialog >= 4 and containsDialoguePhrase(joined, dialog))
	end

	local function chooseQuestOption(gui, mode)
		local positive = mode == "turnin"
			and {"turn in", "complete", "finished", "reward", "claim", "deliver", "hand over", "here", "done", "yes", "continue", "next", "okay", "ok"}
			or {"accept", "take quest", "help", "start", "begin", "yes", "quest", "sure", "okay", "ok", "ready", "do it"}

		local negative = {"no thanks", "not now", "don't", "do not", "decline", "cancel", "leave", "later", "never mind", "no, "}
		local firstSafeName, firstSafeButton = nil, nil
		local bestName, bestButton, bestScore = nil, nil, 0

		for optionIndex = 1, 8 do
			local optionName = "Option" .. tostring(optionIndex)
			local button = QuestDialogueBridge.option and QuestDialogueBridge.option(gui, optionName)
			if button and button.Parent and QuestDialogueBridge.isVisible and QuestDialogueBridge.isVisible(button) then
				local text = questOptionText(button)
				local score = 0
				for _, word in ipairs(positive) do
					if containsDialoguePhrase(text, word) then score = score + 2 end
				end
				for _, word in ipairs(negative) do
					if containsDialoguePhrase(text, word) then score = score - 5 end
				end

				if score >= 0 then
					if not firstSafeButton then
						firstSafeName, firstSafeButton = optionName, button
					end
					if score > bestScore then
						bestName, bestButton, bestScore = optionName, button, score
					end
				end
			end
		end

		return bestName or firstSafeName, bestButton or firstSafeButton
	end

	local function questDialogueSignature(gui)
		if not gui then return "" end
		local pieces = {}
		for _, child in ipairs(gui:GetDescendants()) do
			if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox"))
				and child.Text and child.Text ~= ""
				and (not QuestDialogueBridge.isVisible or QuestDialogueBridge.isVisible(child)) then
				table.insert(pieces, child.Name .. "=" .. tostring(child.Text))
			end
		end
		table.sort(pieces)
		return table.concat(pieces, "\30")
	end

	local function driveQuestDialogue(NPC, mode)
		if isSelling() or not NPC then return false end
		local dialogueNameObject = NPC:FindFirstChild("Dialogue")
		local dialogueName = dialogueNameObject and tostring(dialogueNameObject.Value or "") or ""
		if dialogueName == "" then return false end

		local character = GetCharacter()
		local remote = character and character:FindFirstChild("RemoteEvent")
		if not remote then return false end

		local dialogueFolder = ReplicatedStorage:FindFirstChild("Dialogue")
		local templateName = NPC.Name == "DIO [Lvl. 35+]" and "DIO" or dialogueName
		local dialogueTemplate = dialogueFolder and dialogueFolder:FindFirstChild(templateName)
		local gui = QuestDialogueBridge.currentDialogue and QuestDialogueBridge.currentDialogue()
		local opened = false

		local function dismissPreviousDialogueOnce()
			if QuestDialogueBridge.skipClick then pcall(QuestDialogueBridge.skipClick) end
			task.wait(0.12)
			return not (QuestDialogueBridge.currentDialogue and QuestDialogueBridge.currentDialogue())
		end

		if gui then
			local trackedTarget = QuestRuntime.DialogueTarget
			if trackedTarget == NPC.Name or questDialogueMatchesNPC(gui, NPC, dialogueName) then
				QuestRuntime.DialogueTarget = NPC.Name
				opened = true
			elseif dismissPreviousDialogueOnce() then
				QuestRuntime.DialogueTarget = nil
				gui = nil
			else
				setQuestStatus("Waiting for dialogue", "Close the previous NPC dialogue, then Quest Farm can use " .. tostring(NPC.Name) .. ".")
				return false
			end
		else
			QuestRuntime.DialogueTarget = nil
		end

		if isSelling() then return false end
		if not opened and dialogueTemplate then
			QuestRuntime.DialogueTarget = NPC.Name
			pcall(function() remote:FireServer("PromptTriggered", dialogueTemplate) end)
			if QuestDialogueBridge.waitDialogue then
				gui = QuestDialogueBridge.waitDialogue(3)
				opened = gui ~= nil
			end
			if not opened then QuestRuntime.DialogueTarget = nil end
		end

		if not opened then
			if isSelling() then return false end
			QuestRuntime.DialogueTarget = NPC.Name
			pcall(function()
				remote:FireServer("DialogueInteracted", {DialogueName = dialogueName, Speaker = NPC.Name})
			end)
			if QuestDialogueBridge.waitDialogue then
				gui = QuestDialogueBridge.waitDialogue(4)
				opened = gui ~= nil
			end
			if not opened then QuestRuntime.DialogueTarget = nil end
		end

		if not opened then return false end

		local deadline = tick() + 12
		local actionCount = 0
		local clickedAny = false
		local sawGui = false
		local lastActionSignature = nil
		local lastActionTarget = nil
		local lastActionAt = 0

		while tick() < deadline and actionCount < 12 and FarmState.Active do
			if isSelling() then return false end
			gui = QuestDialogueBridge.currentDialogue and QuestDialogueBridge.currentDialogue()
			if gui then
				sawGui = true
				local signature = questDialogueSignature(gui)
				local optionName, target = chooseQuestOption(gui, mode)
				if signature == lastActionSignature and target == lastActionTarget then
					if tick() - lastActionAt >= 2 then
						if QuestRuntime.DialogueTarget == NPC.Name then QuestRuntime.DialogueTarget = nil end
						return clickedAny
					end
					task.wait(0.08)
				else
					local clicked = false
					if target and optionName then
						if QuestDialogueBridge.click then clicked = QuestDialogueBridge.click(target) == true end
						if not clicked and QuestDialogueBridge.waitAndClickOption then
							clicked = QuestDialogueBridge.waitAndClickOption(optionName, 0.8) == true
						end
					else
						if QuestDialogueBridge.skipClick then
							pcall(QuestDialogueBridge.skipClick)
							clicked = true
						elseif QuestDialogueBridge.waitAndClickOption then
							clicked = QuestDialogueBridge.waitAndClickOption("Option1", 0.5) == true
						end
					end

					if clicked then
						if target and optionName then clickedAny = true end
						lastActionSignature = signature
						lastActionTarget = target
						lastActionAt = tick()
						actionCount = actionCount + 1
						task.wait(0.16)
					else
						task.wait(0.08)
					end
				end
			elseif sawGui then
				task.wait(0.2)
				if not (QuestDialogueBridge.currentDialogue and QuestDialogueBridge.currentDialogue()) then
					if QuestRuntime.DialogueTarget == NPC.Name then QuestRuntime.DialogueTarget = nil end
					return clickedAny
				end
			else
				task.wait(0.1)
			end
		end

		if not (QuestDialogueBridge.currentDialogue and QuestDialogueBridge.currentDialogue()) and QuestRuntime.DialogueTarget == NPC.Name then
			QuestRuntime.DialogueTarget = nil
		end
		return clickedAny
	end

	local function closeQuestDialogueIfOpen()
		local bridge = QuestDialogueBridge
		if bridge and bridge.currentDialogue and bridge.currentDialogue() and bridge.skipClick then
			pcall(bridge.skipClick)
			task.wait(0.08)
		end
	end

	local function GetQuest(NPC)
		if not NPC or isSelling() then return false end
		local ok, interacted = pcall(driveQuestDialogue, NPC, "accept")
		if not ok then
			warn("[Quest Farm] Quest dialogue failed: " .. tostring(interacted))
			return false
		end
		closeQuestDialogueIfOpen()
		return interacted == true
	end

	local function TurnInQuest(NPC)
		if not NPC or isSelling() then return false end
		local ok, interacted = pcall(driveQuestDialogue, NPC, "turnin")
		if not ok then
			warn("[Quest Farm] Turn-in dialogue failed: " .. tostring(interacted))
			return false
		end
		closeQuestDialogueIfOpen()
		return interacted == true
	end

	FarmUtil.GetQuest = GetQuest

	local function questEnemyNameMatches(instName, questEnemy)
		if instName == questEnemy then
			return true
		end
		if questEnemy == "Heaven Ascension Dio" then
			local n = string.lower(instName or "")
			if n:find("heaven", 1, true) and n:find("dio", 1, true) then
				if n:find("ascension", 1, true) or n:find("ascended", 1, true) then
					return true
				end
			end
		end
		return false
	end

	local NPC_KILL_POST_BUFFER_SEC = 1

	local function findAliveQuestEnemy(enemyName)
		if not enemyName or enemyName == "" then return nil end
		local function consider(inst)
			if not inst or not inst.Parent then return nil end
			if not questEnemyNameMatches(inst.Name, enemyName) then return nil end
			local h = inst:FindFirstChild("Health")
			local hrp = inst:FindFirstChild("HumanoidRootPart")
			if h and hrp and h.Value > 0 then
				return inst
			end
			return nil
		end
		local living = workspace:FindFirstChild("Living")
		if living then
			for _, child in ipairs(living:GetChildren()) do
				local e = consider(child)
				if e then return e end
			end
			for _, child in ipairs(living:GetDescendants()) do
				if child ~= living and child.Parent ~= living then
					local e = consider(child)
					if e then return e end
				end
			end
		end
		local mob2 = workspace:FindFirstChild("Mob_Spawns2")
		if mob2 then
			for _, child in ipairs(mob2:GetDescendants()) do
				local e = consider(child)
				if e then return e end
			end
		end
		return nil
	end

	function FarmUtil.Kill(enemy)
		if not enemy or not enemy.Parent then return end
		local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
		local enemyHealth = enemy:FindFirstChild("Health")
		if not (enemyHRP and enemyHealth and enemyHealth.Value > 0) then return end
		local hrp = FarmUtil.GetHRP()
		if not hrp then return end

		FarmUtil.CurrentEnemy = enemy
		local progressConn
		local questProgressAdvanced = false

		local okKill = pcall(function()
			local handheld = isHandheldMethod()
			local lp = Players.LocalPlayer
			local stats = lp:FindFirstChild("PlayerStats")
			local questProgress = stats and stats:FindFirstChild("QuestProgress")
			local questProgressStart = tonumber(questProgress and questProgress.Value) or 0
			if questProgress then
				progressConn = questProgress:GetPropertyChangedSignal("Value"):Connect(function()
					local currentProgress = tonumber(questProgress.Value) or 0
					if currentProgress ~= questProgressStart then
						questProgressAdvanced = true
					end
				end)
			end

			if not handheld then
				FarmUtil.EquipStand()
				local standWaitTimeout = tick() + 4
				repeat task.wait(0.05) until (FarmUtil.GetCharacter():FindFirstChild("SummonedStand") and FarmUtil.GetCharacter():FindFirstChild("SummonedStand").Value) or tick() > standWaitTimeout
				task.wait(0.1)
			end

			while FarmState.Active and not FarmState.CompletedQuest and not QuestRuntime.OverrideRequested do
				if enemy.Parent == nil or not enemy:FindFirstChild("HumanoidRootPart") then
					break
				end
				local currentEnemyHRP = enemy:FindFirstChild("HumanoidRootPart")
				local h = enemy:FindFirstChild("Health")
				if h and h.Value <= 0 then
					task.wait(0.25)
					break
				end
				if questProgressAdvanced then
					break
				end
				local char = Players.LocalPlayer.Character
				local hum = char and char:FindFirstChildWhichIsA("Humanoid")
				if hum and hum.Health > 0 then
					if handheld or char:FindFirstChild("StandMorph") then
						FarmUtil.UseMove("m1")
						local remote = char:FindFirstChild("RemoteEvent")
						if remote then
							if game:GetService("CollectionService"):HasTag(enemy, "Blocking") then
								remote:FireServer("InputBegan", { Input = Enum.KeyCode.R })
							end
							local keys = getgenv().AutoUseStandSkillKeys or {"E"}
							for _, keyName in ipairs(keys) do
								local skillKey = keyName and Enum.KeyCode[keyName] or nil
								if skillKey then
									remote:FireServer("InputBegan", { Input = skillKey })
								end
							end
						end
					else
						task.wait(0.3)
					end
				else
					Players.LocalPlayer.CharacterAdded:Wait()
					if not handheld then
						FarmUtil.EquipStand()
					end
					task.wait(0.3)
				end
				local kd = FarmConfig.KillLoopDelay
				if type(kd) == "number" and kd > 0 then
					task.wait(math.min(kd, 2))
				else
					task.wait()
				end
			end
		end)

		local bufUntil = tick() + (QuestRuntime.OverrideRequested and 0 or NPC_KILL_POST_BUFFER_SEC)
		while FarmState.Active and not FarmState.CompletedQuest and not questProgressAdvanced
			and not QuestRuntime.OverrideRequested and tick() < bufUntil do
			local currentHealth = enemy and enemy:FindFirstChild("Health")
			if not enemy or not enemy.Parent or not currentHealth or currentHealth.Value <= 0 then break end
			local char = Players.LocalPlayer.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			if hum and hum.Health > 0 then
				if isHandheldMethod() or (char and char:FindFirstChild("StandMorph")) then
					FarmUtil.UseMove("m1")
					local remote = char:FindFirstChild("RemoteEvent")
					if remote then
						local keys = getgenv().AutoUseStandSkillKeys or {"E"}
						for _, keyName in ipairs(keys) do
							local skillKey = keyName and Enum.KeyCode[keyName] or nil
							if skillKey then
								remote:FireServer("InputBegan", { Input = skillKey })
							end
						end
					end
				else
					task.wait(0.3)
				end
			end
			local kd = FarmConfig.KillLoopDelay
			if type(kd) == "number" and kd > 0 then
				task.wait(math.min(kd, 2))
			else
				task.wait()
			end
		end

		if progressConn then pcall(function() progressConn:Disconnect() end) end
		stopQuestNPCView()
		clearFocusCam(Players.LocalPlayer.Character)

		local safeHRP = FarmUtil.GetHRP()
		if safeHRP then
			safeHRP.AssemblyLinearVelocity = Vector3.zero
			safeHRP.AssemblyAngularVelocity = Vector3.zero
		end

		FarmUtil.CurrentEnemy = nil
	end

	function FarmUtil.Collect(item)
		if not item or not item.Parent then return false end
		local char = FarmUtil.GetCharacter()
		local hrp = FarmUtil.GetHRP()
		if not char or not hrp then return false end
		local function getItemPart()
			if not item or not item.Parent then return nil end
			if item:IsA("BasePart") then return item end
			return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
		end
		local part = getItemPart()
		if not part then return false end
		local started = tick()
		local lastPromptAt = 0
		farmEnsureNoclip(char)
		while FarmState.Active and item.Parent and tick() - started < 3.5 do
			part = getItemPart()
			if not part then break end
			local targetPosition = part.Position + Vector3.new(0, 2.25, 0)
			if (hrp.Position - targetPosition).Magnitude > 2.5 then
				hrp.CFrame = CFrame.new(targetPosition, part.Position)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
			local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt and prompt.Enabled and (tick() - lastPromptAt >= 0.16) then
				lastPromptAt = tick()
				fireproximityprompt(prompt)
			end
			task.wait(0.1)
		end
		return not item.Parent
	end

	local QuestInfo = {
		["Officer Sam [Lvl. 1+]"] = { Enemy = "Thug" },
		["Deputy Bertrude [Lvl. 10+]"] = { Enemy = "Corrupt Police" },
		["Abbacchio's Partner [Lvl 15+]"] = { Enemy = "Alpha Thug" },
		["Dracula [Lvl. 20+]"] = { Enemy = "Zombie Henchman" },
		["William Zeppeli [Lvl. 25+]"] = { Enemy = "Vampire" },
		["Doppio [Lvl. 30+]"] = { Enemy = "DIO" },
		["DIO [Lvl. 35+]"] = { Enemy = "Jotaro" },
	}

	local QUEST_LEVEL_REQUIREMENTS = {
		["Officer Sam [Lvl. 1+]"] = 1,
		["Deputy Bertrude [Lvl. 10+]"] = 10,
		["Abbacchio's Partner [Lvl 15+]"] = 15,
		["Dracula [Lvl. 20+]"] = 20,
		["William Zeppeli [Lvl. 25+]"] = 25,
		["Doppio [Lvl. 30+]"] = 30,
		["DIO [Lvl. 35+]"] = 35,
	}

	local QUEST_SELECTION_ORDER = {
		"Officer Sam [Lvl. 1+]",
		"Deputy Bertrude [Lvl. 10+]",
		"Abbacchio's Partner [Lvl 15+]",
		"Dracula [Lvl. 20+]",
		"William Zeppeli [Lvl. 25+]",
		"Doppio [Lvl. 30+]",
		"DIO [Lvl. 35+]",
	}

	local function ParseQuests()
		local parsed = {}
		for questName in pairs(QuestInfo) do
			table.insert(parsed, questName)
		end
		table.sort(parsed, function(a, b)
			local levelA = QUEST_LEVEL_REQUIREMENTS[a] or tonumber(tostring(a):match("(%d+)")) or math.huge
			local levelB = QUEST_LEVEL_REQUIREMENTS[b] or tonumber(tostring(b):match("(%d+)")) or math.huge
			if levelA == levelB then return a < b end
			return levelA < levelB
		end)
		return parsed
	end

	local ParsedQuests = ParseQuests()
	if workspace:FindFirstChild("Dialogues") then
		workspace.Dialogues.ChildAdded:Connect(function(child)
			if not child or not QuestInfo[child.Name] then return end
			for _, existing in ipairs(ParsedQuests) do
				if existing == child.Name then return end
			end
			table.insert(ParsedQuests, child.Name)
			table.sort(ParsedQuests)
			pcall(function()
				if QuestDropdown and QuestDropdown.Refresh then
					QuestDropdown:Refresh(ParsedQuests, true)
				end
			end)
		end)
	end

	local function GetBestQuest()
		local playerLevel = Players.LocalPlayer.PlayerStats.Level.Value
		local bestQuest, highestReq = nil, 0
		for _, questName in pairs(ParsedQuests) do
			if QuestInfo[questName] and questName ~= "Auto (Best for Level)" and questName ~= "No quests available" then
				local levelReq = tonumber(questName:match("%d+"))
				if levelReq and levelReq <= playerLevel and levelReq >= highestReq then
					highestReq = levelReq
					bestQuest = questName
				end
			end
		end
		if not bestQuest then
			for questName, _ in pairs(QuestInfo) do
				local levelReq = tonumber(questName:match("%d+"))
				if levelReq and levelReq <= playerLevel and levelReq >= highestReq then
					highestReq = levelReq
					bestQuest = questName
				end
			end
		end
		return bestQuest
	end

	local function GetBestQuestForLevel(currentLevel)
		local level = tonumber(currentLevel) or 0
		local bestQuest, highestReq = nil, -1

		for _, questName in ipairs(QUEST_SELECTION_ORDER) do
			if QuestInfo[questName] then
				local requirement = QUEST_LEVEL_REQUIREMENTS[questName]
					or tonumber(tostring(questName):match("(%d+)"))
				if requirement and requirement <= level and requirement > highestReq then
					bestQuest, highestReq = questName, requirement
				end
			end
		end

		if not bestQuest then
			for questName in pairs(QuestInfo) do
				local requirement = QUEST_LEVEL_REQUIREMENTS[questName]
					or tonumber(tostring(questName):match("(%d+)"))
				if requirement and requirement <= level and requirement > highestReq then
					bestQuest, highestReq = questName, requirement
				end
			end
		end
		return bestQuest
	end

	local function GetLowestLevelQuest()
		local lowestQuest, lowestReq = nil, math.huge
		for _, questName in ipairs(ParsedQuests) do
			if QuestInfo[questName] then
				local requirement = tonumber(tostring(questName):match("(%d+)"))
				if requirement and requirement < lowestReq then
					lowestQuest, lowestReq = questName, requirement
				end
			end
		end
		if not lowestQuest then
			for questName in pairs(QuestInfo) do
				local requirement = tonumber(tostring(questName):match("(%d+)"))
				if requirement and requirement < lowestReq then
					lowestQuest, lowestReq = questName, requirement
				end
			end
		end
		return lowestQuest
	end

	local function GetQuestLevelRequirement(questName)
		if not questName then return 0 end
		return QUEST_LEVEL_REQUIREMENTS[questName] or tonumber(tostring(questName):match("(%d+)")) or 0
	end

	local function GetPlayerLevel()
		local player = GetPlayer()
		if player and player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("Level") then
			return player.PlayerStats.Level.Value
		end
		return 0
	end

	local function UpdateQuestStatusLabel()
		local target = FarmState.CurrentQuest or QuestRuntime.ManualQuest or getgenv().SelectedQuest
		local stats = player and player:FindFirstChild("PlayerStats")
		local progressObject = stats and stats:FindFirstChild("QuestProgress")
		local maximumObject = stats and stats:FindFirstChild("QuestMaxProgress")
		local progress = tonumber(progressObject and progressObject.Value) or 0
		local maximum = tonumber(maximumObject and maximumObject.Value) or 0
		local labelText = target and ("Target: " .. tostring(target)) or "No target selected"
		if target and maximum > 0 then
			local remaining = math.max(0, maximum - progress)
			labelText ..= " | " .. tostring(progress) .. "/" .. tostring(maximum)
			if remaining == 0 then
				labelText ..= " | Finished"
			else
				labelText ..= " (" .. tostring(remaining) .. " left)"
			end
		end
		pcall(function()
			if _G.QuestCurrentQuestLabelObj then
				if _G.QuestCurrentQuestLabelObj.Set then
					_G.QuestCurrentQuestLabelObj:Set(labelText)
				elseif _G.QuestCurrentQuestLabelObj.Text then
					_G.QuestCurrentQuestLabelObj.Text = labelText
				end
			end
		end)
	end

	local function IsPlayerReady()
		local player = GetPlayer()
		if not player then return false end
		local character = player.Character
		if not character then return false end
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then return false end
		if humanoid.Health <= 0 then return false end
		if not character:FindFirstChild("HumanoidRootPart") then return false end
		if not character.PrimaryPart then return false end
		return true
	end

	local function WaitForCharacter(timeout)
		timeout = timeout or 10
		local player = GetPlayer()
		if not player then return false end
		local start = tick()
		while tick() - start < timeout do
			if player.Character then
				local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return true
				end
			end
			task.wait(0.1)
		end
		return false
	end

	local function getRemoteFunction()
		return GetCharacter():WaitForChild("RemoteFunction")
	end

	local function learnSkill(skill, treeType)
		pcall(function()
			getRemoteFunction():InvokeServer("LearnSkill", {
				Skill = skill,
				SkillTreeType = treeType,
			})
		end)
	end

	local SPEC_SKILLS = {
		"Hamon Breathing","Lung Capacity I","Lung Capacity II","Lung Capacity III",
		"Lung Capacity IV","Lung Capacity V","Breathing Technique I","Breathing Technique II",
		"Breathing Technique III","Breathing Technique IV","Breathing Technique V",
	}

	local function learnAllSkills()
		pcall(function()
			local sst = player:FindFirstChild("StandSkillTree")
			if sst then
				for _, v in pairs(sst:GetChildren()) do
					if not v.Value then
						learnSkill(v.Name, "Stand")
					end
				end
			end
			local info = getRemoteFunction():InvokeServer("ReturnSkillInfoInTree", {
				Type   = "Stand",
				Skills = { [19] = "Inhale" },
			})
			if info and info.Inhale and info.Inhale.AssignedKey ~= "L" then
				getRemoteFunction():InvokeServer("AssignSkillKey", {
					Type  = "Stand",
					Key   = "Enum.KeyCode.L",
					Skill = "Inhale",
				})
			end
			for _, name in ipairs(SPEC_SKILLS) do
				learnSkill(name, "Spec")
			end
		end)
	end

	local function getQuests()
		local t = {}
		local ok, questFrame = pcall(function()
			return player.PlayerGui:WaitForChild("HUD")
				:WaitForChild("Main")
				:WaitForChild("Frames")
				:WaitForChild("Quest")
				:WaitForChild("Quests")
		end)
		if not ok then return t end
		for _, v in pairs(questFrame:GetChildren()) do
			if v.Name ~= "Sample" then t[v.Name] = true end
		end
		return t
	end

	local function getPity()
		return PlayerPity.Value <= 0 and 1
			or math.clamp(1 + PlayerPity.Value / 25, 0, 10)
	end

	local function roundTwo(n)
		return math.floor(n * 100) / 100
	end

	local function FarmLoop()
		local lp = Players.LocalPlayer
		local playerGui = lp:WaitForChild("PlayerGui")
		local hud = playerGui:FindFirstChild("HUD")
		local completionConnection
		local activeTarget = nil
		local acceptAttempted = false
		local turnInRetryAt = 0
		local turnInStartedAt = nil
		local turnInAttempted = false
		local turnInInteracted = false
		local turnInStartProgress = 0
		local turnInStartMaximum = 0
		local trackedQuestMaximum = 0
		local ignoreProgressCompletionUntil = 0

		local function questProgressValues()
			local stats = lp:FindFirstChild("PlayerStats")
			local progress = stats and stats:FindFirstChild("QuestProgress")
			local maximum = stats and stats:FindFirstChild("QuestMaxProgress")
			return tonumber(progress and progress.Value) or 0, tonumber(maximum and maximum.Value) or 0
		end

		local function displayQuestProgressValues()
			local progress, maximum = questProgressValues()
			if tick() < ignoreProgressCompletionUntil and not FarmState.CompletedQuest then
				return 0, math.max(maximum, trackedQuestMaximum, 0)
			end
			if acceptAttempted and maximum > 0 then
				trackedQuestMaximum = math.max(trackedQuestMaximum, maximum)
			end
			local displayMaximum = math.max(maximum, trackedQuestMaximum, progress, 0)
			local displayProgress = math.max(0, progress)
			if displayMaximum > 0 then
				displayProgress = math.min(displayProgress, displayMaximum)
			end
			return displayProgress, displayMaximum
		end

		local function isValidQuest(name)
			return type(name) == "string" and QuestInfo[name] ~= nil and name ~= "No quests available"
		end

		local function chooseNextQuest()
			local chosen
			if getgenv().AutoSelectBestQuest == true then
				chosen = GetBestQuestForLevel(GetPlayerLevel())
			else
				chosen = QuestRuntime.ManualQuest or getgenv().SelectedQuest
			end
			if not isValidQuest(chosen) then chosen = GetLowestLevelQuest() end
			return isValidQuest(chosen) and chosen or nil
		end

		local function updateProgressLabel()
			local progress, maximum = displayQuestProgressValues()
			local detail = tostring(activeTarget or "No quest selected")
			local questData = activeTarget and QuestInfo[activeTarget]

			if questData and questData.Enemy then
				detail ..= "  •  target: " .. tostring(questData.Enemy)
				if maximum > 0 then
					detail ..= "  •  " .. tostring(progress) .. "/" .. tostring(maximum)
				end
			elseif questData and questData.Item then
				local count = FarmUtil.CountItem(questData.Item)
				detail ..= "  •  " .. tostring(count) .. "/" .. tostring(questData.Amount) .. " " .. tostring(questData.Item)
			elseif maximum > 0 then
				detail ..= "  •  " .. tostring(progress) .. "/" .. tostring(maximum)
			end

			setQuestStatus("Farming selected target", detail)
		end

		local function assignNextTarget()
			local nextQuest = chooseNextQuest()
			if not nextQuest then
				setQuestStatus("No quest available", "Choose a quest or wait for the quest catalog to become available.")
				return false
			end
			activeTarget = nextQuest
			FarmState.CurrentQuest = nextQuest
			QuestRuntime.ActiveQuest = nextQuest
			FarmState.CompletedQuest = false
			getgenv().CompletedQuest = false
			acceptAttempted = false
			turnInRetryAt = 0
			turnInStartedAt = nil
			turnInAttempted = false
			turnInInteracted = false
			turnInStartProgress = 0
			turnInStartMaximum = 0
			trackedQuestMaximum = 0
			ignoreProgressCompletionUntil = tick() + 1.25
			setQuestStatus("Quest target selected", "Target: " .. tostring(nextQuest) .. ". Quest Farm will open this giver once, then farm its configured objective.")
			return true
		end

		local function attemptAcceptOnce(questName)
			if acceptAttempted or not isValidQuest(questName) or isSelling() then return acceptAttempted end
			local dialogues = workspace:FindFirstChild("Dialogues")
			local npc = dialogues and dialogues:FindFirstChild(questName)
			if not npc then
				setQuestStatus("Waiting for quest giver", "Waiting for " .. tostring(questName) .. " to load before making the single quest request.")
				return false
			end

			acceptAttempted = true
			QuestRuntime.LastAcceptAttempt = tick()
			QuestRuntime.LastAcceptQuest = questName
			setQuestStatus("Requesting quest once", "Opening " .. tostring(questName) .. " and selecting its quest option once, without checking which quest is already active.")
			local ok, interacted = pcall(GetQuest, npc)
			if not ok then
				warn("[Quest Farm] Quest request failed: " .. tostring(interacted))
				setQuestStatus("Quest request attempted", "The NPC dialogue was attempted once. The farm will still work the selected target.")
			elseif interacted then
				setQuestStatus("Quest requested", "NPC dialogue interaction finished. Farming " .. tostring(questName) .. " regardless of any existing quest state.")
			else
				setQuestStatus("Quest request attempted", "The NPC dialogue was attempted once. Farming will continue using the selected target and progress counter only.")
			end
			task.wait(0.25)
			return true
		end

		local function clearFinishedTarget(questName)
			setQuestStatus("Quest cycle handled", "Finished the " .. tostring(questName) .. " cycle. Preparing the next quest request.")
			activeTarget = nil
			FarmState.CurrentQuest = nil
			QuestRuntime.ActiveQuest = nil
			FarmState.CompletedQuest = false
			getgenv().CompletedQuest = false
			acceptAttempted = false
			turnInRetryAt = 0
			turnInStartedAt = nil
			turnInAttempted = false
			turnInInteracted = false
			turnInStartProgress = 0
			turnInStartMaximum = 0
			trackedQuestMaximum = 0
			ignoreProgressCompletionUntil = tick() + 1.25
		end

		local function attemptTurnIn(questName)
			if isSelling() then return false end

			local currentProgress, currentMaximum = questProgressValues()
			if turnInAttempted then
				local progressReset = turnInStartMaximum > 0
					and (currentMaximum < turnInStartMaximum or currentProgress < turnInStartProgress)
				if progressReset then
					clearFinishedTarget(questName)
					return true
				end
				if turnInStartedAt and turnInInteracted and tick() - turnInStartedAt >= 3.5 then
					clearFinishedTarget(questName)
					return true
				end
				if turnInStartedAt and not turnInInteracted and tick() - turnInStartedAt >= 5 then
					setQuestStatus("Turn-in needs attention", "The completion dialogue was attempted once but did not confirm. It will not reopen repeatedly. Toggle Quest Farm off and on to retry.")
				end
				return false
			end

			if tick() < turnInRetryAt then return false end
			local dialogues = workspace:FindFirstChild("Dialogues")
			local npc = dialogues and dialogues:FindFirstChild(questName)
			if not npc then
				setQuestStatus("Waiting to turn in", "The objective is complete. Waiting for " .. tostring(questName) .. " to load for the reward interaction.")
				turnInRetryAt = tick() + 1.25
				return false
			end

			turnInStartedAt = tick()
			turnInStartProgress = currentProgress
			turnInStartMaximum = currentMaximum
			turnInAttempted = true
			turnInInteracted = false
			QuestRuntime.LastTurnInAttempt = turnInStartedAt
			setQuestStatus("Turning in quest", "The objective is complete. Opening " .. tostring(questName) .. " once to claim the reward.")
			local ok, interacted = pcall(TurnInQuest, npc)
			if not ok then
				warn("[Quest Farm] Turn-in attempt failed: " .. tostring(interacted))
				interacted = false
			end
			turnInInteracted = interacted == true
			task.wait(0.65)
			local afterProgress, afterMaximum = questProgressValues()
			local progressReset = turnInStartMaximum > 0
				and (afterMaximum < turnInStartMaximum or afterProgress < turnInStartProgress)

			if progressReset or (turnInStartMaximum <= 0 and turnInInteracted) then
				clearFinishedTarget(questName)
				return true
			end

			if turnInInteracted then
				setQuestStatus("Waiting for turn-in", "The turn-in option was selected once. Waiting for the counter to reset without reopening the dialogue.")
			else
				setQuestStatus("Turn-in attempted once", "The completion dialogue did not confirm a selection. Waiting without reopening the giver repeatedly.")
			end
			return false
		end

		if hud then
			completionConnection = hud.DescendantAdded:Connect(function(child)
				if child and child.Name == "QuestCompleted" and FarmState.Active then
					FarmState.CompletedQuest = true
					getgenv().CompletedQuest = true
				end
			end)
		end

		task.spawn(function()
			while FarmState.Active do
				task.wait(2.5)
				if not FarmState.Active then break end
				local stats = lp:FindFirstChild("PlayerStats")
				local standValue = stats and stats:FindFirstChild("Stand")
				if isHandheldMethod() and not STAND_KEEPALIVE_EXCLUDED[standValue and standValue.Value or ""] then continue end
				local char = lp.Character
				if char then
					local ss = char:FindFirstChild("SummonedStand")
					if not (ss and ss.Value) then pcall(FarmUtil.EquipStand) end
				end
			end
		end)

		local masterConn = RunService.Heartbeat:Connect(function()
			if not FarmState.Active then return end
			local char = lp.Character
			if not char then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local enemy = FarmUtil.CurrentEnemy
			if enemy and enemy.Parent and enemy:FindFirstChild("HumanoidRootPart") then
				startQuestNPCView(enemy)
				stickFarmPartsToNPC(char, enemy, isHandheldMethod())
			else
				stopQuestNPCView()
				zeroFarmVelocity(root)
			end
		end, 22, 45)

		while FarmState.Active do
			if not IsPlayerReady() then
				setQuestStatus("Waiting for character", "Waiting for your character to finish spawning before continuing Quest Farm.")
				task.wait(0.3)
				continue
			end

			if not activeTarget and not assignNextTarget() then
				task.wait(0.5)
				continue
			end

			if not attemptAcceptOnce(activeTarget) then
				task.wait(0.2)
				continue
			end

			local questData = QuestInfo[activeTarget]
			if not questData then
				setQuestStatus("Unknown target", "No objective handler exists for " .. tostring(activeTarget) .. ".")
				task.wait(0.3)
				continue
			end

			local progress, maximum = questProgressValues()
			if acceptAttempted and maximum > 0 and tick() >= ignoreProgressCompletionUntil then
				trackedQuestMaximum = math.max(trackedQuestMaximum, maximum)
			end
			local complete = FarmState.CompletedQuest == true
			if maximum > 0 and progress >= maximum and tick() >= ignoreProgressCompletionUntil then
				complete = true
			end

			if questData.Item then
				local count = FarmUtil.CountItem(questData.Item)
				if count >= questData.Amount then complete = true end
			end

			if complete then
				FarmState.CompletedQuest = true
				getgenv().CompletedQuest = true
				if not turnInAttempted then updateProgressLabel() end
				attemptTurnIn(activeTarget)
				task.wait(0.12)
				continue
			end

			FarmState.CompletedQuest = false
			getgenv().CompletedQuest = false
			if questData.Enemy then
				updateProgressLabel()
				local enemy = findAliveQuestEnemy(questData.Enemy)
				if enemy then
					local ok, err = pcall(FarmUtil.Kill, enemy)
					if not ok then
						warn("[Quest Farm] Combat iteration failed: " .. tostring(err))
						setQuestStatus("Recovering combat", "The target action failed. Reacquiring the configured enemy and continuing.")
						task.wait(0.25)
					end
				else
					task.wait(0.2)
				end
			elseif questData.Item then
				local count = FarmUtil.CountItem(questData.Item)
				setQuestStatus("Collecting selected objective", tostring(activeTarget) .. "  •  " .. tostring(count) .. "/" .. tostring(questData.Amount) .. " " .. tostring(questData.Item))
				local spawns = workspace:FindFirstChild("Item_Spawns")
				local spawnParent = spawns and spawns:FindFirstChild("Items")
				local targetItem
				if spawnParent then
					for _, item in ipairs(spawnParent:GetChildren()) do
						if item.Name == questData.Item then targetItem = item break end
					end
				end
				if targetItem then
					local ok, err = pcall(FarmUtil.Collect, targetItem)
					if not ok then warn("[Quest Farm] Item collection failed: " .. tostring(err)) end
				else
					task.wait(0.25)
				end
			end

			updateProgressLabel()
			task.wait(math.max(0.1, tonumber(FarmConfig.QuestCheckDelay) or 0.35))
		end

		FarmUtil.CurrentEnemy = nil
		stopQuestNPCView()
		pcall(function() if masterConn then masterConn:Disconnect() end end)
		pcall(function() if completionConnection then completionConnection:Disconnect() end end)
	end

	local noQuestKillEnabled = false
	local noQuestKillTarget = "Vampire"

	local function killNPCNoQuest(npcName)
		local enemy = nil
		local containers = { workspace:FindFirstChild("Living") or workspace }
		if workspace:FindFirstChild("Mob_Spawns2") then
			table.insert(containers, workspace.Mob_Spawns2)
		end
		for _, container in pairs(containers) do
			for _, child in pairs(container:GetDescendants()) do
				if child.Name == npcName or questEnemyNameMatches(child.Name, npcName) then
					local h = child:FindFirstChild("Health")
					local hrp = child:FindFirstChild("HumanoidRootPart")
					if h and h.Value > 0 and hrp then
						enemy = child
						break
					end
				end
			end
			if enemy then break end
		end
		if not enemy then return end

		local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
		if not enemyHRP then return end

		local handheld = isHandheldMethod()
		if not handheld then
			FarmUtil.EquipStand()
			task.wait(0.3)
		end

		local running = true
		local moneyConn
		local dropMoney = Players.LocalPlayer.PlayerGui:FindFirstChild("HUD")
			and Players.LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
			and Players.LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("DropMoney")
			and Players.LocalPlayer.PlayerGui.HUD.Main.DropMoney:FindFirstChild("Money")
		if dropMoney then
			moneyConn = dropMoney.ChildAdded:Connect(function(child)
				if tonumber(string.match(child.Name, "%d+")) then
					running = false
					if moneyConn then moneyConn:Disconnect() moneyConn = nil end
				end
			end)
		end

		local heartbeat = RunService.Heartbeat:Connect(function()
			if not running or not noQuestKillEnabled then return end
			if enemy.Parent == nil then return end
			local currentHRP = enemy:FindFirstChild("HumanoidRootPart")
			if not currentHRP then return end
			local char = Players.LocalPlayer.Character
			if not char then return end
			local hHRP = char:FindFirstChild("HumanoidRootPart")
			if not hHRP then return end

			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if not (hum and hum.Health > 0) then return end
			stickFarmPartsToNPC(char, enemy, handheld)
		end, 22, 45)

		while running and noQuestKillEnabled do
			if enemy.Parent == nil or not enemy:FindFirstChild("HumanoidRootPart") then
				running = false
				break
			end
			local currentEnemyHRP = enemy:FindFirstChild("HumanoidRootPart")
			local h = enemy:FindFirstChild("Health")
			if h and h.Value <= 0 then
				running = false
				break
			end
			local char = Players.LocalPlayer.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			if hum and hum.Health > 0 then
				if handheld or char:FindFirstChild("StandMorph") then
					FarmUtil.UseMove("m1")
					local remote = char:FindFirstChild("RemoteEvent")
					if remote then
						if game:GetService("CollectionService"):HasTag(enemy, "Blocking") then
							remote:FireServer("InputBegan", { Input = Enum.KeyCode.R })
						end
						local keys = getgenv().AutoUseStandSkillKeys or {"E"}
						for _, keyName in ipairs(keys) do
							local skillKey = keyName and Enum.KeyCode[keyName] or nil
							if skillKey then
								remote:FireServer("InputBegan", { Input = skillKey })
							end
						end
					end
				else
					task.wait(0.3)
				end
			else
				Players.LocalPlayer.CharacterAdded:Wait()
				if not handheld then FarmUtil.EquipStand() end
				task.wait(0.3)
			end
			task.wait(farmStepWait())
		end
		if moneyConn then
			moneyConn:Disconnect()
			moneyConn = nil
		end

		local bufUntil = tick() + NPC_KILL_POST_BUFFER_SEC
		while noQuestKillEnabled and tick() < bufUntil do
			local char = Players.LocalPlayer.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			if hum and hum.Health > 0 then
				if char:FindFirstChild("StandMorph") then
					FarmUtil.UseMove("m1")
					local remote = char:FindFirstChild("RemoteEvent")
					if remote then
						local keys = getgenv().AutoUseStandSkillKeys or {"E"}
						for _, keyName in ipairs(keys) do
							local skillKey = keyName and Enum.KeyCode[keyName] or nil
							if skillKey then
								remote:FireServer("InputBegan", { Input = skillKey })
							end
						end
					end
				else
					task.wait(0.3)
				end
			end
			task.wait(farmStepWait())
		end

		if heartbeat then heartbeat:Disconnect() end
		stopQuestNPCView()
		local char = Players.LocalPlayer.Character
		if char then
			clearFocusCam(char)
			for _, v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = true end
			end
		end
	end

	QuestLeft = QuestTab:Section("Quest Controller", "Left", "target")
	QuestRight = QuestTab:Section("NPC Farm & Tools", "Right", "swords")

	getgenv().QuestDelay = tonumber(getgenv().QuestDelay) or 0.6
	getgenv().QuestMethod = getgenv().QuestMethod or "With Stand"
	getgenv().CompletedQuest = false
	getgenv().QuestFarmEnabled = false
	getgenv().NPCFarmEnabled = false
	getgenv().NoStandNotified = false
	getgenv().TargetNPC = getgenv().TargetNPC or ""
	getgenv().AutoUseStandSkillKey = "E"
	getgenv().LastQuestNotifyTime = 0
	getgenv().QuestNotifyCooldown = 5
	getgenv().PreviousQuest = nil
	if getgenv().AutoSelectBestQuest == nil then getgenv().AutoSelectBestQuest = true end

	if #ParsedQuests == 0 then
		for questName in pairs(QuestInfo) do table.insert(ParsedQuests, questName) end
		table.sort(ParsedQuests)
	end
	if #ParsedQuests == 0 then table.insert(ParsedQuests, "No quests available") end

	local initialManualQuest = getgenv().SelectedQuest
	if not (type(initialManualQuest) == "string" and QuestInfo[initialManualQuest]) then
		initialManualQuest = GetLowestLevelQuest() or ParsedQuests[1]
	end
	QuestRuntime.ManualQuest = initialManualQuest
	getgenv().SelectedQuest = initialManualQuest
	QuestStatusLabel = QuestLeft:Paragraph("Automation Status", "Ready. Choose a quest, then enable Quest Farm.")
	QuestProgressLabel = QuestLeft:Paragraph("Selected Target", "No target selected")
	_G.QuestCurrentQuestLabelObj = QuestProgressLabel
	QuestLeft:Divider()

	local AutoSelectBestQuestToggle = nil
	QuestDropdown = QuestLeft:Dropdown("Manual Quest Selection", ParsedQuests, initialManualQuest or "No quests available", function(selected)
		if type(selected) == "table" then selected = selected[1] end
		if not (type(selected) == "string" and QuestInfo[selected]) then return end

		if getgenv().AutoSelectBestQuest then
			getgenv().AutoSelectBestQuest = false
			if AutoSelectBestQuestToggle then
				for _, methodName in ipairs({"SetValue", "Set", "SetState"}) do
					local ok, method = pcall(function()
						return AutoSelectBestQuestToggle[methodName]
					end)
					if ok and type(method) == "function" then
						local applied = pcall(function()
							method(AutoSelectBestQuestToggle, false)
						end)
						if applied then break end
					end
				end
			end
		end

		QuestRuntime.ManualQuest = selected
		getgenv().SelectedQuest = selected
		if not FarmState.Active then FarmState.CurrentQuest = nil end
		if FarmState.Active then QuestRuntime.OverrideRequested = false end
		setQuestStatus("Manual target selected", "Selected: " .. selected .. ". Quest Farm will request this target once when the next quest cycle begins.")
		Window:Notify("Quest Farm", "Manual quest selected: " .. selected, 3)
	end)

	AutoSelectBestQuestToggle = QuestLeft:Toggle("Auto Select Best Quest", getgenv().AutoSelectBestQuest == true, function(state)
		getgenv().AutoSelectBestQuest = state == true
		if state then
			QuestRuntime.OverrideRequested = false
			local currentLevel = GetPlayerLevel()
			local best = GetBestQuestForLevel(currentLevel)
			setQuestStatus("Automatic selection", "Auto Farm Ready.")
			Window:Notify("Quest Farm", "Auto selection enabled at level " .. tostring(currentLevel) .. ". Target: " .. tostring(best or "none available") .. ". The next target is recalculated after completion.", 4)
		else
			local manual = QuestRuntime.ManualQuest or GetLowestLevelQuest()
			if manual then
				QuestRuntime.ManualQuest = manual
				getgenv().SelectedQuest = manual
			end
			setQuestStatus("Manual selection", "Auto mode is OFF. Quest Farm will use your selected quest: " .. tostring(manual or "choose a quest") .. ". It won't replace it with the best-for-level quest.")
			Window:Notify("Quest Farm", "Auto Select Best Quest disabled. Your manual selection will be respected.", 3)
		end
	end, "When enabled, recalculates the highest quest available for your level after each completed quest cycle. When disabled, keeps using your chosen quest.", "list-check")

	QuestMethodDropdown = QuestLeft:Dropdown("Combat Method", {"With Stand", "Without Stand"}, getgenv().QuestMethod, function(selected)
		if selected ~= "With Stand" and selected ~= "Without Stand" then return end
		getgenv().QuestMethod = selected
		FarmConfig.FarmingMethod = selected == "With Stand" and "Auto (Detect)" or "Handheld/Fist"
		setQuestStatus("Combat method updated", "Quest combat will use " .. selected .. ". The setting applies to the next combat action.")
	end, "Choose whether the farm uses your stand or handheld attacks.")

	getgenv().AutoUseStandSkillKeys = getgenv().AutoUseStandSkillKeys or {"E"}
	QuestLeft:MultiDropdown("Auto Use Stand Skills", {"B","C","E","F","G","H","I","J","K","L","M","N","O","P","T","U","V","X","Y","Z"}, getgenv().AutoUseStandSkillKeys, function(selectedList)
		selectedList = selectedList or {}
		getgenv().AutoUseStandSkillKeys = selectedList
		setQuestStatus("Skill keys updated", "Automatic skill keys: " .. (#selectedList > 0 and table.concat(selectedList, ", ") or "none") .. ".")
		if #selectedList > 2 then
			local skillTree = player:FindFirstChild("StandSkillTree")
			local hasUnlearned = false
			if skillTree then
				for _, skill in ipairs(skillTree:GetChildren()) do
					if skill:IsA("ValueBase") and skill.Value ~= true then hasUnlearned = true break end
				end
			end
			if hasUnlearned then
				Window:Notify("Quest Farm", "Multiple skills selected. Learning available stand skills in the background.", 4)
				task.spawn(function() pcall(learnAllSkills) end)
			end
		end
	end, "Select the stand skill keys to repeat during each combat encounter.")

	QuestLeft:Slider("Combat Loop Delay", 0, 0.25, 0, 0.01, function(value)
		FarmConfig.KillLoopDelay = math.clamp(tonumber(value) or 0, 0, 0.25)
	end, "Increase this slightly if attacks are being sent too quickly.")
	QuestLeft:Slider("Quest Check Delay", 0.1, 1, 0.35, 0.05, function(value)
		FarmConfig.QuestCheckDelay = math.clamp(tonumber(value) or 0.35, 0.1, 1)
	end, "How often the farm rechecks progress when not fighting.")

	QuestLeft:Divider()
	local QuestFarmToggle
	local function resetQuestFarmToggle()
		if QuestFarmToggle and type(QuestFarmToggle.Set) == "function" then
			pcall(function() QuestFarmToggle:Set(false, true) end)
		end
	end
	QuestFarmToggle = QuestLeft:Toggle("Enable Quest Farm", getgenv().QuestFarmEnabled == true, function(value)
		if value then
			if config.canStart and not config.canStart() then
				setQuestStatus("Blocked by another farm", "Stop Auto Farm, Auto Prestige, and selling before starting Quest Farm.")
				Window:Notify("Quest Farm", "Stop Auto Farm, Auto Prestige, and selling before starting Quest Farm.", 4)
				resetQuestFarmToggle()
				return
			end
			if getgenv().normalFarmOn or getgenv().afkFarmOn or getgenv().afkUnderneathFarmOn or getgenv().safePlaceFarmOn then
				setQuestStatus("Blocked by item farm", "Turn off Item Farm before starting Quest Farm.")
				Window:Notify("Quest Farm", "Item Farm is running. Disable it first.", 4)
				resetQuestFarmToggle()
				return
			end
			if getgenv().NPCFarmEnabled then
				setQuestStatus("Blocked by NPC Farm", "Turn off the standalone NPC Farm before starting Quest Farm.")
				Window:Notify("Quest Farm", "NPC Farm is running. Disable it first.", 4)
				resetQuestFarmToggle()
				return
			end
			if not getgenv().AutoSelectBestQuest and not (QuestRuntime.ManualQuest and QuestInfo[QuestRuntime.ManualQuest]) then
				setQuestStatus("Choose a quest", "Select a manual quest before starting with Auto Select Best Quest disabled.")
				Window:Notify("Quest Farm", "Choose a quest first, or enable Auto Select Best Quest.", 4)
				resetQuestFarmToggle()
				return
			end
			local root = FarmUtil.GetHRP()
			FarmState.OriginalCFrame = root and root.CFrame or nil
			FarmState.CurrentQuest = nil
			FarmState.CompletedQuest = false
			QuestRuntime.ActiveQuest = nil
			QuestRuntime.LastAcceptAttempt = 0
			QuestRuntime.LastAcceptQuest = nil
			QuestRuntime.LastTurnInAttempt = 0
			QuestRuntime.DialogueTarget = nil
			QuestRuntime.OverrideRequested = false
			FarmState.Active = true
			getgenv().QuestFarmEnabled = true
			getgenv().CompletedQuest = false
			if enableNoclip then pcall(enableNoclip) end
			local startLevel = GetPlayerLevel()
			local chosen = getgenv().AutoSelectBestQuest and GetBestQuestForLevel(startLevel) or QuestRuntime.ManualQuest
			setQuestStatus("Quest Farm starting", "Player level: " .. tostring(startLevel) .. ". Target: " .. tostring(chosen or "the selected target") .. ". The selected quest giver will be opened once, then its configured objective will be farmed.")
			Window:Notify("Quest Farm", "Started. The selected quest giver will be contacted once per quest cycle; objective farming follows the selected target, not detected quest names.", 3)
			task.spawn(function()
				local ok, err = pcall(FarmLoop)
				if not ok then
					warn("[Quest Farm] Main loop stopped: " .. tostring(err))
					FarmState.Active = false
					FarmState.CurrentQuest = nil
					FarmState.CompletedQuest = false
					getgenv().QuestFarmEnabled = false
					getgenv().CompletedQuest = false
					resetQuestFarmToggle()
					stopQuestNPCView()
					clearFocusCam(FarmUtil.GetCharacter())
					if disableNoclip then pcall(disableNoclip) end
					if not noQuestKillEnabled and farmReleaseNoclip then pcall(farmReleaseNoclip, FarmUtil.GetCharacter()) end
					setQuestStatus("Stopped after error", "The farm recovered from a runtime error: " .. tostring(err))
					Window:Notify("Quest Farm", "Stopped after an error. Details were written to the executor console.", 6)
					if FarmState.OriginalCFrame then
						local currentRoot = FarmUtil.GetHRP()
						if currentRoot then pcall(function() currentRoot.CFrame = FarmState.OriginalCFrame end) end
						FarmState.OriginalCFrame = nil
					end
				end
			end)
		else
			FarmState.Active = false
			FarmState.CurrentQuest = nil
			FarmState.CompletedQuest = false
			QuestRuntime.ActiveQuest = nil
			getgenv().QuestFarmEnabled = false
			getgenv().CompletedQuest = false
			stopQuestNPCView()
			if not noQuestKillEnabled and farmReleaseNoclip then pcall(farmReleaseNoclip, FarmUtil.GetCharacter()) end
			clearFocusCam(FarmUtil.GetCharacter())
			if FarmState.OriginalCFrame then
				local root = FarmUtil.GetHRP()
				if root then pcall(function() root.CFrame = FarmState.OriginalCFrame end) end
				FarmState.OriginalCFrame = nil
			end
			if disableNoclip then pcall(disableNoclip) end
			setQuestStatus("Stopped", "Quest Farm is stopped. Your manual quest selection has been kept.")
			Window:Notify("Quest Farm", "Stopped. Your selected quest was saved.", 3)
		end
	end, "Request the selected quest once, farm its configured objective, turn it in, and recalculate the next target from your level.", "play")

	QuestRight:Divider()
	local function GetAllNPCs()
		local NPCs, seen = {}, {}
		local living = workspace:FindFirstChild("Living")
		if living then
			for _, npc in ipairs(living:GetChildren()) do
				if npc:FindFirstChild("Spawn") and not seen[npc.Name] then
					seen[npc.Name] = true
					table.insert(NPCs, npc.Name)
				end
			end
		end
		table.sort(NPCs)
		return NPCs
	end

	local NPCList = GetAllNPCs()
	if #NPCList == 0 then NPCList = {"Vampire"} end
	local NPCDropdown = QuestRight:Dropdown("NPC Target", NPCList, getgenv().TargetNPC ~= "" and getgenv().TargetNPC or NPCList[1], function(selected)
		if type(selected) ~= "string" or selected == "" then return end
		getgenv().TargetNPC = selected
		noQuestKillTarget = selected
		Window:Notify("NPC Farm", "Target saved: " .. selected, 3)
	end, "Choose a target for the separate no-quest NPC farm.")

	if getgenv().TargetNPC == "" then getgenv().TargetNPC = NPCList[1] or "Vampire" end
	noQuestKillTarget = getgenv().TargetNPC
	local livingFolder = workspace:FindFirstChild("Living")
	if livingFolder then
		livingFolder.ChildAdded:Connect(function(child)
			if not child or not child:FindFirstChild("Spawn") then return end
			if NPCDropdown and NPCDropdown.Add then NPCDropdown:Add(child.Name) end
		end)
	end

	QuestRight:Toggle("Enable NPC Farm", false, function(state)
		if state then
			if getgenv().normalFarmOn or getgenv().afkFarmOn or getgenv().afkUnderneathFarmOn or getgenv().safePlaceFarmOn then
				Window:Notify("NPC Farm", "Item Farm is running. Disable it first.", 4)
				return
			end
			if getgenv().QuestFarmEnabled then
				Window:Notify("NPC Farm", "Quest Farm is running. Disable it first.", 4)
				return
			end
		end
		getgenv().NPCFarmEnabled = state == true
		noQuestKillEnabled = state == true
		if state then
			if getgenv().TargetNPC == "" then
				Window:Notify("NPC Farm", "Choose an NPC first.", 4)
				getgenv().NPCFarmEnabled = false
				noQuestKillEnabled = false
				return
			end
			Window:Notify("NPC Farm", "Started farming: " .. getgenv().TargetNPC, 3)
			if enableNoclip then pcall(enableNoclip) end
			task.spawn(function()
				while noQuestKillEnabled do
					pcall(killNPCNoQuest, noQuestKillTarget)
					task.wait(0.2)
				end
				if disableNoclip then pcall(disableNoclip) end
				Window:Notify("NPC Farm", "Stopped farming.", 3)
			end)
			task.spawn(function()
				while noQuestKillEnabled do
					task.wait(2.5)
					if not noQuestKillEnabled then break end
					if isHandheldMethod() then continue end
					local char = Players.LocalPlayer.Character
					if char then
						local ss = char:FindFirstChild("SummonedStand")
						if not (ss and ss.Value) then pcall(FarmUtil.EquipStand) end
					end
				end
			end)
		else
			noQuestKillEnabled = false
			if disableNoclip then pcall(disableNoclip) end
			if not FarmState.Active and farmReleaseNoclip then pcall(farmReleaseNoclip, Players.LocalPlayer.Character) end
			Window:Notify("NPC Farm", "Stopped farming.", 3)
		end
	end, "Farm a selected NPC without requiring a quest.", "swords")

	QuestRight:Button("Show Stats", function()
		local statsText = "Stand: " .. tostring(PlayerStand.Value) .. " | Level: " .. tostring(PlayerLevel.Value) .. " | Pity: " .. tostring(roundTwo(getPity())) .. " | Money: $" .. tostring(PlayerMoney.Value) .. " | Spec: " .. tostring(PlayerSpec.Value)
		Window:Notify("Player Stats", statsText, 10)
	end, "Display your current character stats.", "chart-no-axes-column")

	QuestRight:Button("Show Active Quests", function()
		local quests = getQuests()
		local names = {}
		for name in pairs(quests) do table.insert(names, tostring(name)) end
		table.sort(names)
		Window:Notify("Active Quests", #names > 0 and table.concat(names, "\n") or "No active quests.", 6)
	end, "List the quest cards currently visible in your HUD.", "list")

	QuestRight:Button("Learn All Stand Skills", function()
		if getgenv().autoPrestigeEnabled or getgenv().autoPrestigeBusy then
			Window:Notify("Skills", "Auto Prestige is running. Stop it first.", 5)
			return
		end
		task.spawn(function()
			local ok, err = pcall(learnAllSkills)
			if ok then Window:Notify("Skills", "Skill learning requests sent.", 4)
			else Window:Notify("Skills", "Skill learning failed: " .. tostring(err), 5) end
		end)
	end, "Send learning requests for the known stand and spec skills.", "graduation-cap")

	farmThrottledHeartbeat(function()
		if not (FarmState.Active or noQuestKillEnabled or getgenv().__EldiabloAutoStwActive) then return end
		local char = Players.LocalPlayer.Character
		if not char then return end
		farmEnsureNoclip(char)
	end, 12, 30)

	notify("", "Mob Farm ready.", 4)
end

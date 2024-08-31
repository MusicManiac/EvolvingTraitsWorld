require "ETWModData";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

---Function responsible for processing Bloodlust trait execution logic
---@param zombie IsoZombie
local function OnZombieDeadETW(zombie)
	local player = getPlayer();
	if player:HasTrait("Bloodlust") and player:DistTo(zombie) <= 4 then
		local bodyDamage = player:getBodyDamage();
		local stats = player:getStats();
		local stressFromCigarettes = stats:getStressFromCigarettes(); -- 0-1
		local unhappiness = bodyDamage:getUnhappynessLevel(); -- 0-100
		local stress = math.max(0, stats:getStress() - stressFromCigarettes); -- 0-1, may be higher with stress from cigarettes
		local panic = stats:getPanic(); -- 0-100
		bodyDamage:setUnhappynessLevel(math.max(0, unhappiness - 4 * SBvars.BloodlustMultiplier));
		stats:setStress(math.max(0, stress - 0.04 * SBvars.BloodlustMultiplier));
		stats:setPanic(math.max(0, panic - 4 * SBvars.BloodlustMultiplier));
		if detailedDebug() then print("ETW Logger | OnZombieDeadETW(): Bloodlust kill. Unhappiness:"..unhappiness.."->"..bodyDamage:getUnhappynessLevel()..", stress: "..math.min(1, stress + stressFromCigarettes).."->"..stats:getStress()..", panic: "..panic.."->"..stats:getPanic()) end
	end
end

---Function responsible for processing carry weight traits execution logic
---@param player IsoPlayer
local function checkWeightLimit(player)
	local maxWeightBase = 8;
	local strength = player:getPerkLevel(Perks.Strength);

	if getActivatedMods():contains("ToadTraits") then
		if player:HasTrait("packmule") then maxWeightBase = math.floor(SandboxVars.MoreTraits.WeightPackMule + strength / 5) end
		if player:HasTrait("packmouse") then maxWeightBase = SandboxVars.MoreTraits.WeightPackMouse end
		if not player:HasTrait("packmule") and not player:HasTrait("packmouse") then maxWeightBase = SandboxVars.MoreTraits.WeightDefault end
		maxWeightBase = maxWeightBase + SandboxVars.MoreTraits.WeightGlobalMod;
		if detailedDebug() then print("ETW Logger | checkWeightLimit(): [ToadTraits present] Set maxWeightBase to "..maxWeightBase) end
	end

	if getActivatedMods():contains("SimpleOverhaulTraitsAndOccupations") or getActivatedMods():contains("AliceSPack") then
		if player:HasTrait("StrongBack") or player:HasTrait("Strongback2") or player:HasTrait("Strongback") then
			maxWeightBase = maxWeightBase + 1;
		elseif player:HasTrait("WeakBack") then
			maxWeightBase = maxWeightBase - 1;
		end
		if player:HasTrait("Metalstrongback") or player:HasTrait("Metalstrongback2") then
			maxWeightBase = maxWeightBase + 4;
		end
		if detailedDebug() then print("ETW Logger | checkWeightLimit(): [SOTO/AlicePack compatibility] Set maxWeightBase to "..tostring(maxWeightBase)) end
	end

	if player:HasTrait("Hoarder") then
		maxWeightBase = maxWeightBase + strength * SBvars.HoarderWeight;
		if detailedDebug() then print("ETW Logger | checkWeightLimit(): Set Hoarder maxWeightBase to "..maxWeightBase) end
	end

	if getActivatedMods():contains("zReArmorPackBYKK") and player:getWornItem("zReExoskeleton") then
		maxWeightBase = math.floor(maxWeightBase * 1.5)
		if detailedDebug() then print("ETW Logger | checkWeightLimit(): [zReArmorPackBYKK compatibility] Set maxWeightBase to "..maxWeightBase) end
	end

	player:setMaxWeightBase(maxWeightBase);
end

---Function responsible for processing Rain traits execution logic
---@param player IsoPlayer
---@param rainIntensity number
local function rainTraits(player, rainIntensity)
	local Pluviophobia = player:HasTrait("Pluviophobia");
	local Pluviophile = player:HasTrait("Pluviophile");
	if rainIntensity > 0 and (Pluviophobia or Pluviophile) and player:isOutside() and player:getVehicle() == nil then
		local primaryItem = player:getPrimaryHandItem();
		local secondaryItem = player:getSecondaryHandItem();
		local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped()) or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped());
		local bodyDamage = player:getBodyDamage();
		local stats = player:getStats();
		local stressFromCigarettes = stats:getStressFromCigarettes(); -- 0-1
		if Pluviophobia then
			local unhappinessIncrease = 0.1 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier;
			bodyDamage:setUnhappynessLevel(math.min(100, bodyDamage:getUnhappynessLevel() + unhappinessIncrease));
			if detailedDebug() then print("ETW Logger | rainTraits(): unhappinessIncrease:"..unhappinessIncrease) end
			local boredomIncrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier;
			stats:setBoredom(math.min(100, stats:getBoredom() + boredomIncrease));
			if detailedDebug() then print("ETW Logger | rainTraits(): boredomIncrease:"..boredomIncrease) end
			local stressIncrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier;
			stats:setStress(math.min(1, stats:getStress() - stressFromCigarettes + stressIncrease));
			if detailedDebug() then print("ETW Logger | rainTraits(): stressIncrease:"..stressIncrease) end
		elseif Pluviophile then
			local unhappinessDecrease = 0.1 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier;
			bodyDamage:setUnhappynessLevel(math.max(0, bodyDamage:getUnhappynessLevel() - unhappinessDecrease));
			if detailedDebug() then print("ETW Logger | rainTraits(): unhappinessDecrease:"..unhappinessDecrease) end
			local boredomDecrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier;
			stats:setBoredom(math.max(0, stats:getBoredom() - boredomDecrease));
			if detailedDebug() then print("ETW Logger | rainTraits(): boredomDecrease:"..boredomDecrease) end
			local stressDecrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier;
			stats:setStress(math.max(0, stats:getStress() - stressFromCigarettes - stressDecrease));
			if detailedDebug() then print("ETW Logger | rainTraits(): stressDecrease:"..stressDecrease) end
		end
	end
end

---Function responsible for processing Rain traits execution logic
---@param player IsoPlayer
---@param fogIntensity number
local function fogTraits(player, fogIntensity)
	local Homichlophobia = player:HasTrait("Homichlophobia");
	local Homichlophile = player:HasTrait("Homichlophile");
	if fogIntensity > 0 and (Homichlophobia or Homichlophile) and player:isOutside() and player:getVehicle() == nil then
		local stats = player:getStats();
		local stressFromCigarettes = stats:getStressFromCigarettes();
		if Homichlophobia then
			local panicIncrease = 4 * fogIntensity * SBvars.HomichlophobiaMultiplier;
			local resultingPanic = stats:getPanic() + panicIncrease;
			if resultingPanic <= 50 then
				stats:setPanic(math.max(0, resultingPanic));
				if detailedDebug() then print("ETW Logger | fogTraits(): panicIncrease:"..panicIncrease) end
			end
			local stressIncrease = 0.04 * fogIntensity * SBvars.HomichlophobiaMultiplier;
			local resultingStress = math.min(1, stats:getStress() + stressIncrease);
			if resultingStress <= 0.5 then
				stats:setStress(math.min(1, resultingStress - stressFromCigarettes));
				if detailedDebug() then print("ETW Logger | fogTraits(): stressIncrease:"..stressIncrease) end
			end
		elseif Homichlophile then
			local panicDecrease = 4 * fogIntensity * SBvars.HomichlophileMultiplier;
			stats:setPanic(math.max(0, stats:getPanic() - panicDecrease));
			local stressDecrease = 0.04 * fogIntensity * SBvars.HomichlophileMultiplier;
			stats:setStress(math.max(0, stats:getStress() - stressFromCigarettes - stressDecrease));
			if detailedDebug() then print("ETW Logger | fogTraits(): panicDecrease:"..panicDecrease.."stressDecrease: "..stressDecrease) end
		end
	end
end

---unction responsible for processing Pain Tolerance execution logic
local function painTolerance()
	local player = getPlayer();
	local PainTolerance = player:HasTrait("PainTolerance");
	local stats = player:getStats();
	local pain = stats:getPain();
	if PainTolerance and pain >= SBvars.PainToleranceThreshold then
		stats:setPain(SBvars.PainToleranceThreshold);
	end
end

---Function responsible for setting up every minute updates
local function oneMinuteUpdate()
	local player = getPlayer();
	local climateManager = getClimateManager();
	if not getActivatedMods():contains("EvolvingTraitsWorldDisableHoarder") then checkWeightLimit(player) end
	if not getActivatedMods():contains("EvolvingTraitsWorldDisableRainTraits") then rainTraits(player, climateManager:getRainIntensity()) end
	if not getActivatedMods():contains("EvolvingTraitsWorldDisableFogTraits") then fogTraits(player, climateManager:getFogIntensity()) end
end

---Function responsible for activating Pain Tolerance trait. It's global so it can be called from another file
---@param player IsoPlayer
function ETW_InitiatePainToleranceTrait(player)
	Events.OnTick.Remove(painTolerance);
	if not getActivatedMods():contains("EvolvingTraitsWorldDisablePainTolerance") and player:HasTrait("PainTolerance") then Events.OnTick.Add(painTolerance) end
end

---Function responsible for initializing all traits logic
---@param playerIndex number
---@param player IsoPlayer
local function initializeTraitsLogic(playerIndex, player)
	Events.OnZombieDead.Remove(OnZombieDeadETW);
	Events.OnZombieDead.Add(OnZombieDeadETW);
	Events.EveryOneMinute.Remove(oneMinuteUpdate);
	Events.EveryOneMinute.Add(oneMinuteUpdate);
	Events.OnTick.Remove(painTolerance);
	if not getActivatedMods():contains("EvolvingTraitsWorldDisablePainTolerance") and getPlayer():HasTrait("PainTolerance") then Events.OnTick.Add(painTolerance) end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(OnZombieDeadETW);
	Events.EveryOneMinute.Remove(oneMinuteUpdate);
	Events.OnTick.Remove(painTolerance);
	if detailedDebug() then print("ETW Logger | System: clearEventsETW in ETWTraitsLogic.lua") end
end

---@diagnostic disable-next-line: undefined-global
Events.EveryHours.Remove(SOcheckWeight);

Events.OnCreatePlayer.Remove(initializeTraitsLogic);
Events.OnCreatePlayer.Add(initializeTraitsLogic);
Events.OnPlayerDeath.Remove(clearEventsETW);
Events.OnPlayerDeath.Add(clearEventsETW);
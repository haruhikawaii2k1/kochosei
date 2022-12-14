local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/kochosei_voice.fsb")
}

-- Your character's stats

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.KOCHOSEI = {
    "flint",
    "flint",
    "twigs",
    "twigs",
    "cutgrass",
    "cutgrass",
    "kochosei_hat2",
    "kochosei_lantern"
}

TUNING.STARTING_ITEM_IMAGE_OVERRIDE.kochosei_lantern = {
    atlas = "images/inventoryimages/kochosei_lantern.xml",
    image = "kochosei_lantern.tex"
}

TUNING.STARTING_ITEM_IMAGE_OVERRIDE.kochosei_hat2 = {
    atlas = "images/inventoryimages/kochosei_hat2.xml",
    image = "kochosei_hat2.tex"
}
local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.KOCHOSEI
end
local prefabs = FlattenTree(start_inv, true)

local function DoEffects(pet)
    local x, y, z = pet.Transform:GetWorldPosition()
    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
end

local function KillPet(pet)
    pet.components.health:Kill()
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("kochosei_enemy") then
        --Delayed in case we need to relocate for migration spawning
        pet:DoTaskInTime(0, DoEffects)

        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
            if not inst.components.builder.freebuildmode then
                inst.components.sanity:AddSanityPenalty(
                    pet,
                    TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)]
                )
            end
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    elseif inst._OnSpawnPet ~= nil then
        inst:_OnSpawnPet(pet)
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("kochosei_enemy") then
        DoEffects(pet)
        pet:Remove()
    elseif inst._OnDespawnPet ~= nil then
        inst:_OnDespawnPet(pet)
    end
end

-- When the character is revived from human
local function onbecamehuman(inst)
    -- Set speed when not a ghost (optional)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "kochosei_speed_mod", 1.25)
end

local function onbecameghost(inst)
    -- Remove speed modifier when becoming a ghost
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "kochosei_speed_mod", 1.25)
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end

local function onpick(inst, data)
    if data.object.prefab == "flower" or data.object:HasTag("flower") then
        inst.components.sanity:DoDelta(-20)
    end
end

local function emoteplants(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 15, nil, nil, {"farm_plant"})
    for k, v in pairs(ents) do
        if v.components.farmplanttendable ~= nil then
            v.components.farmplanttendable:TendTo(inst)
        end
    end
end

local wlist = require "util/weighted_list"

local talklist =
    wlist(
    {
        talk1 = 1,
        talk2 = 2,
        talk3 = 3,
        talk4 = 4,
        talk5 = 5,
        talk6 = 6,
        talk7 = 7,
        talk8 = 8,
        talk9 = 9,
        talk10 = 10,
        talk11 = 11,
        talk12 = 12,
        talk13 = 13,
        talk14 = 14,
        talk15 = 15
    }
)
local emotesoundlist = {
    emote = "emote",
    emoteXL_waving1 = "wave", -- wave
    emoteXL_facepalm = "facepalm", -- facepalm
    research = "joy", -- joy
    emoteXL_sad = "cry", -- cry
    emoteXL_annoyed = "no", -- nosay
    emoteXL_waving4 = "rude", -- rude
    emote_pre_sit1 = "squat", -- squat
    emote_pre_sit2 = "sit", -- sit
    emoteXL_angry = "angry", -- angry
    emoteXL_happycheer = "happy", -- happy
    emoteXL_bonesaw = "bonesaw", -- bonesaw
    emoteXL_kiss = "kiss", -- kiss
    pose = wlist({pose1 = 1, pose2 = 1, pose3 = 1}), -- pose
    emote_fistshake = "fistshake", -- fistshake
    emote_flex = "flex", -- flex
    emoteXL_pre_dance7 = "step", -- MY GODFATHER --
    emoteXL_pre_dance0 = "dance", -- dance
    emoteXL_pre_dance8 = "robot", -- robot
    emoteXL_pre_dance6 = "chicken", -- chicken
    emote_swoon = "swoon", -- swoon
    carol = wlist({carol1 = 1, carol2 = 2, carol3 = 3, carol4 = 4, carol5 = 5}), -- carol
    emote_slowclap = "slowclap", -- slowclap
    emote_shrug = "shrug", -- shrug
    emote_laugh = "laugh", -- laugh
    emote_jumpcheer = "cheer", -- cheer
    emote_impatient = "impatient", -- impatient
    eye_rub_vo = "sleepy", -- sleepy
    emote_yawn = "yawn" -- yawn
}

local function OnTaskTick(inst)
    if inst.components.health:IsDead() or inst:HasTag("playerghost") then
        return
    end
    if inst.components.sanity:GetPercent() < 1 then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 8, {"player"}, {"playerghost"})
    for i, v in ipairs(ents) do
        if v.components.health ~= nil and v.components.health:GetPercent() < 1 and not v.components.health:IsDead() then
            v.components.health:DoDelta(1, true, "kochosei")
        end
    end
end

---------------------------K??n ??n------------------
local kochoseikhongan = {
    "butterflywings",
    "butterflymuffin",
    "poop",
    "moonbutterflywings"
}

local function anvaochetnguoiay(inst, food)
    if food ~= nil then
        for k, v in ipairs(kochoseikhongan) do
            if food.prefab == v then
                return false
            end
        end
    end
    return true
end
---------------------------K??n ??n------------------

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
    -- Minimap icon
    inst:AddTag("kochosei")
    inst:AddTag("summonerally")
    inst:AddTag("puppeteer")
    inst.MiniMapEntity:SetIcon("kochosei.tex")
    inst.AnimState:AddOverrideBuild("wendy_channel")
    inst.AnimState:AddOverrideBuild("player_idles_wendy")
end

-- This initializes for the server only. Components are added here.

local kochoseidancingsanity = 20

local function CalcSanityAura(inst)
    return inst.kochoseiindancing * kochoseidancingsanity / 60
end

local function KochoseiSound(inst, talk, time, tag)
    if inst._kochoseitalk ~= nil then
        inst._kochoseitalk:Cancel()
        inst._kochoseitalk = nil
    end
    inst.SoundEmitter:KillSound("kochoseitalk")
    if tag then
        inst.SoundEmitter:KillSound(tag)
    end
    local name = ""
    if type(talk) == "table" then
        name = talk:getChoice(math.random() * talk:getTotalWeight())
    elseif type(talk) == "string" then
        name = talk
    end
    if name ~= nil then
        inst.SoundEmitter:PlaySound("kochosei_voice/sound/" .. name, tag or "kochoseitalk")
    end

    if time ~= nil then
        inst._kochoseitalk =
            inst:DoTaskInTime(
            time,
            function()
                inst.SoundEmitter:KillSound(tag or "kochoseitalk")
                inst._kochoseitalk:Cancel()
                inst._kochoseitalk = nil
            end
        )
    end
end

------------------------------------------------chicken--------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
local function onnewstate(inst, data)
    if inst.sg.currentstate.name ~= "emote" then
        if inst._kochoseitalk ~= nil then
            inst._kochoseitalk:Cancel()
            inst._kochoseitalk = nil
        end
        if inst.emotefn then
            inst.emotefn:Cancel()
            inst.emotefn = nil
        end

        inst.SoundEmitter:KillSound("kochoseibgm")
        inst.components.sanity.dapperness =
            inst.components.sanity.dapperness - inst.kochoseiindancing * kochoseidancingsanity / 60
        inst.kochoseiindancing = 0
        inst:RemoveEventCallback("newstate", onnewstate)
    end
end
local function onemote(inst, data)
    --    GetExp(inst, 5, "emote", 20)
    local soundname =
        data.soundoverride or
        (type(data.anim) == "table" and (type(data.anim[1]) == "table" and data.anim[1][1] or data.anim[1])) or
        (type(data.anim) == "string" and data.anim) or
        "emote"
    local loop = data.loop
    local sound = "emote"
    sound = emotesoundlist[soundname] or "emote"
    if soundname == "carol" or sound == "dance" or sound == "step" or sound == "robot" or sound == "chicken" then
        inst.components.sanity.dapperness =
            inst.components.sanity.dapperness - inst.kochoseiindancing * kochoseidancingsanity / 60
        inst.kochoseiindancing = (sound == "dance") and 1 or 1.5
        -- print(inst.components.sanity.dapperness)
        inst.components.sanity.dapperness =
            inst.components.sanity.dapperness + inst.kochoseiindancing * kochoseidancingsanity / 60
        if not inst.components.sanityaura then
            inst:AddComponent("sanityaura") -- ???SAN??????
        end
        inst.components.sanityaura.aurafn = CalcSanityAura
        inst:ListenForEvent("newstate", onnewstate)
        if inst.emotefn then
            inst.emotefn:Cancel()
            inst.emotefn = nil
        end

        inst.emotefn = inst:DoTaskInTime(1, emoteplants) --happytime
        KochoseiSound(inst, sound, nil, "kochoseibgm")
    else
        KochoseiSound(inst, sound, nil)
    end
end

---------------------------------------------------------------------------------------------------------------
local lootlist = {
    dragonfly = {
        {
            name = "moonglass",
            probability = 1
        }
    }
}

-------------B?????m ch???t ??? g???n b??? tr??? sanity----------------------

-- Credit to Ultroman  https://forums.kleientertainment.com/forums/topic/110716-coding-killing-mobs-penalty/
local WATCH_WORLD_HOUNDS_DIST_SQ = 15 * 15

function contains(list, x)
    for _, v in pairs(list) do
        if v == x then
            return true
        end
    end
    return false
end

local trungphatgietbuom = {
    "butterfly"
}
local function apdungtrungphat(inst, data)
    if data and data.inst and contains(trungphatgietbuom, data.inst.prefab) then
        if inst:IsNear(data.inst, WATCH_WORLD_HOUNDS_DIST_SQ) then
            inst.components.sanity:DoDelta(-20)
        end
    end
end
-------------B?????m ch???t ??? g???n b??? tr??? sanity----------------------

local function onkilled(inst, data)
    --    local victim = data.victim
    if data ~= nil and data.victim ~= nil and data.victim:HasTag("butterfly") then
        print("test butterfly")
        inst.components.sanity:DoDelta(-200)
        --        inst.components.hunger:DoDelta(-100)
        inst.components.health:DoDelta(-100, true, "Gi???t ?????ng lo???i")
        inst.components.talker:Say("What are you doingggggg!!!")
        TheWorld:PushEvent("ms_sendlightningstrike", inst:GetPosition())
        TheNet:Announce("T???i ????? " .. inst:GetDisplayName() .. " ???? gi???t ?????ng lo???i c???a m??nh v?? ???? ph???i tr??? gi??!!!")
    end

    if data ~= nil and data.victim ~= nil and data.victim:HasTag("frog") then
        data.victim.components.lootdropper:AddRandomLoot("krampus", 0.1)
        data.victim.components.lootdropper:AddRandomLoot("leif", 0.01)
        data.victim.components.lootdropper:AddRandomLoot("frogleg", 1)
        data.victim.components.lootdropper.numrandomloot = 1

        local math = math.random(1, 100)
        if math == 1 then
            TheWorld:PushEvent("ms_sendlightningstrike", inst:GetPosition())
            TheNet:Announce(
                "Truy???n thuy???t k??? r???ng c?? m???t onii-chan " .. inst:GetDisplayName() .. " ???? t??n s??t r???t nhi???u ???ch"
            )
        end
    end

    if data ~= nil and data.victim ~= nil and data.victim:HasTag("dragonfly") then
        SetSharedLootTable(
            "dragonfly",
            {
                {"dragon_scales", 1.00},
                {"dragonflyfurnace_blueprint", 1.00},
                {"chesspiece_dragonfly_sketch", 1.00},
                {"chesspiece_dragonfly_sketch", 1.00},
                {"lavae_egg", 0.33},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"meat", 1.00},
                {"goldnugget", 1.00},
                {"goldnugget", 1.00},
                {"goldnugget", 1.00},
                {"goldnugget", 1.00},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"goldnugget", 0.50},
                {"redgem", 1.00},
                {"bluegem", 1.00},
                {"purplegem", 1.00},
                {"orangegem", 1.00},
                {"yellowgem", 1.00},
                {"greengem", 1.00},
                {"redgem", 0.40},
                {"bluegem", 0.40},
                {"purplegem", 0.40},
                {"orangegem", 0.40},
                {"yellowgem", 0.40},
                {"greengem", 0.40},
                {"redgem", 1.00},
                {"bluegem", 1.00},
                {"purplegem", 0.50},
                {"orangegem", 0.50},
                {"yellowgem", 0.50},
                {"greengem", 0.50}
            }
        )
    end
end

---------------------------------Level Miomhm---------------------
local function IsValidVictim(victim)
    return victim ~= nil and
        not (victim:HasTag("prey") or victim:HasTag("veggie") or victim:HasTag("structure") or victim:HasTag("wall") or
            victim:HasTag("companion")) and
        victim.components.health ~= nil and
        victim.components.combat ~= nil
end
local function onkilledmiohm(inst, data)
    local victim = data.victim
    if IsValidVictim(victim) then
        local weapon = inst.components.combat:GetWeapon()
        if weapon and weapon:HasTag("miohm") then
            weapon.levelmiohm = weapon.levelmiohm + TUNING.KOCHOSEI_PER_KILL
            weapon:applyupgrades()
        end
    end
end
---------------------------------Level Miomhm---------------------

local ghosttalklist = wlist({ghosttalk1 = 1, ghosttalk2 = 1, ghosttalk3 = 1})
local function ontalk(inst, data)
    if not inst:HasTag("playerghost") then
        KochoseiSound(inst, talklist)
    else
        KochoseiSound(inst, ghosttalklist)
    end
end
-----------------------------------------------------------------------------
local function OnEquipCustom(inst, data)
    if data.item.prefab == "kochosei_hat1" or "kochosei_hat2" then
        if inst:HasTag("scarytoprey") then
            inst:RemoveTag("scarytoprey")
        end
    end
end
--------------- B??? tag scarytoprey (o?????????)o???(o?????????)o???(o?????????)o???----------------
local function OnUnequipCustom(inst, data)
    if data.item ~= nil then
        if data.item.prefab == "kochosei_hat1" or "kochosei_hat2" then
            if not inst:HasTag("scarytoprey") then
                inst:AddTag("scarytoprey")
            end
        end
    end
end
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
local function in_fire(inst)
    if inst.sg:HasStateTag("knockout") then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 10, {"fire"})
        for i, v in ipairs(ents) do
            if v.components.burnable ~= nil and v.components.burnable:IsBurning() then
                if TheWorld.state.isnight then
                    inst.components.sanity:DoDelta(2)
                end
            end
        end
    end
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
local function haru(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local spell = SpawnPrefab("crab_king_icefx")
    spell.Transform:SetPosition(x, y, z)
end

stop = 0

local function harulevel(inst)
  if inst.components.health:IsDead() or inst:HasTag("playerghost") then
        return
    end
    if not inst.components.locomotor.wantstomoveforward then
        stop = stop + 1
    
	else 
		stop = 0
	end
    if stop >= 60 then
        haru(inst)
    end
end

local master_postinit = function(inst)
    -- Set starting inventory
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default



    -- choose which sounds this character will play
    inst.soundsname = "kochosei"
    inst.kochoseiindancing = 0
    inst.components.talker.ontalkfn = ontalk

    -- Stats
    inst:AddComponent("reader")
    inst.components.health:SetMaxHealth(TUNING.KOCHOSEI_HEALTH)
    inst.components.hunger:SetMax(TUNING.KOCHOSEI_HUNGER)
    inst.components.sanity:SetMax(TUNING.KOCHOSEI_SANITY)
    inst.components.health.absorb = TUNING.KOCHOSEI_ARMOR
    inst.components.combat.damagemultiplier = TUNING.KOCHOSEI_DAMAGE
    inst.components.sanity.dapperness = -5 / 60

    inst:AddComponent("petleash")
    inst.components.petleash:SetMaxPets(TUNING.KOCHOSEI_SLAVE_MAX)

    inst:DoPeriodicTask(1, OnTaskTick, 1)
    inst:DoPeriodicTask(5, in_fire, 1)
	inst:DoPeriodicTask(1, harulevel, 1)
	 
  

    -- Damage multiplier (optional)

    -- Hunger rate (optional)
    inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
    inst.components.eater.PrefersToEat = anvaochetnguoiay
    inst.customidleanim = "idle_wendy"
    inst.OnLoad = onload
    inst.OnNewSpawn = onload
    inst:ListenForEvent("emote", onemote)
    ------------
    inst:ListenForEvent("equip", OnEquipCustom)
    inst:ListenForEvent("unequip", OnUnequipCustom)
    ------------

    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("death", onbecameghost)
    inst:ListenForEvent(
        "death",
        function(inst, data)
            if
                data and data.afflicter and data.afflicter:IsValid() and data.afflicter.components.health and
                    not data.afflicter.components.health:IsDead()
             then
                local killer =
                    data.afflicter.components.follower and data.afflicter.components.follower:GetLeader() or
                    data.afflicter:HasTag("player") and data.afflicter or
                    nil
                if killer and killer:HasTag("player") and killer ~= inst then
                    killer.components.health:Kill() -- ???????????????
                end
            end
        end
    )
    inst:ListenForEvent(
        "healthdelta",
        function(inst, data)
            if
                data and data.afflicter and data.afflicter:IsValid() and data.afflicter.components.health and
                    not data.afflicter.components.health:IsDead()
             then
                local killer =
                    data.afflicter.components.follower and data.afflicter.components.follower:GetLeader() or
                    data.afflicter:HasTag("player") and data.afflicter or
                    nil
                if killer and killer:HasTag("player") and killer ~= inst then
                    killer.components.health:DoDelta(3 * data.amount, nil, nil, true, killer, true) -- 3?????????
                end
            end
        end
    )

    inst.wlist = wlist
    inst:ListenForEvent("killed", onkilled)
    inst:ListenForEvent("killed", onkilledmiohm)
    inst:ListenForEvent("picksomething", onpick)
    ---------------------------K??n ??n------------------
    local inedibles = {}
    local old_CanEat = inst.components.eater.CanEat
    inst.components.eater.CanEat = function(self, food_inst)
        for i, v in ipairs(inedibles) do
            if food_inst.prefab == v then
                return false
            end
        end
        return old_CanEat(self, food_inst)
    end
    ---------------------------K??n ??n------------------
    -------------B?????m ch???t ??? g???n b??? tr??? sanity----------------------
    inst._onentitydeathfn = function(src, data)
        apdungtrungphat(inst, data)
    end
    inst:ListenForEvent("entity_death", inst._onentitydeathfn, TheWorld)
    -------------B?????m ch???t ??? g???n b??? tr??? sanity----------------------
end

return MakePlayerCharacter("kochosei", prefabs, assets, common_postinit, master_postinit, prefabs)

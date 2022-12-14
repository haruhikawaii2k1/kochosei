local assets = {
    Asset("ANIM", "anim/kochotambourin.zip"),
    Asset("ANIM", "anim/swap_kochotambourin.zip"),
    Asset("ANIM", "anim/lavaarena_heal_flowers_fx.zip"),
    Asset("ATLAS", "images/inventoryimages/kochotambourin.xml"),
    Asset("IMAGE", "images/inventoryimages/kochotambourin.tex")
}
local prefabs_healblooms = {
    "lavaarena_bloom_kocho",
    "lavaarena_bloomhealbuff_kocho",
    "lavaarena_bloomsleepdebuff_kocho"
}

local function TurnOn(inst, owner)
    for i = 0, 12 do
        local fx = SpawnPrefab("kochotambourin_light")
        fx.Light:SetRadius(1.1)
        owner:AddChild(fx)
        table.insert(inst.lights, fx)
        fx.Transform:SetPosition(0, 0, 0)
    end
end

local function TurnOff(inst, owner)
    for k, v in ipairs(inst.lights) do
        v:Remove()
    end
    inst.lights = {}
end

--Bloomson credit to Abigail  https://steamcommunity.com/sharedfiles/filedetails/?id=2535962194&searchtext=fantasy
local Rn = 6 --这是范围
local Zn = 5 --这是持续时间

local hua = {}
table.insert(hua, Point())
for i = 2, Rn, 2 do
    local z = 2 * PI * i
    local jg = 2 + (z % 2) / (z / 2)
    for j = jg, z, jg do
        local hu = j / i
        local po = Vector3(math.cos(hu) * i, 0, math.sin(hu) * i)
        table.insert(hua, po)
    end
end

local function SanityCheck(inst, level)
    level = level or inst.components.sanity.current
    if level > 50 then
        inst.components.sanity:DoDelta(-40)

        return true
    end
    return false
end

local function HealFunc2(inst, target, pos) -- 范围回血 + 催眠 + 催熟
    print(inst, target)
    local hstrongtay = STRINGS.NAMES.LYDOHOISINH
    local caster = inst.components.inventoryitem.owner
    if not caster then
        caster = target or caster
    end
    inst.components.finiteuses:Use(20)
    if SanityCheck(caster) then
        local xu = CreateEntity()
        xu.entity:AddTransform()
        xu.Transform:SetPosition(pos.x, 0, pos.z)
		   for k, v in pairs(hua) do
            xu:DoTaskInTime(
                math.random() * 0.2,
                function()
                    local fx = SpawnPrefab("lavaarena_bloom_kocho" .. math.random(6))
                    fx.Transform:SetPosition((pos + v):Get())
                    fx:chixu(Zn + math.random())
                end
            )
        end
        local players = TheSim:FindEntities(pos.x, pos.y, pos.z, Rn, {"playerghost"})
        local playercount = #players
        for k, v in ipairs(players) do
            v:PushEvent("respawnfromghost")
            v.rezsource = hstrongtay
        end
        if playercount >= 1 then
            caster.components.health:DoDelta(-100, true, "lydochet")
            inst.components.finiteuses:SetUses(0)
        end

        local playersheal = TheSim:FindEntities(pos.x, pos.y, pos.z, Rn, {"player"})
        xu:DoPeriodicTask(
            0.5,
            function()
                for k, v in pairs(playersheal) do
                    v.components.health:DoDelta(TUNING.KOCHO_TAMBOURIN_HEAL)
                end
            end
        )
        xu:DoTaskInTime(Zn, xu.Remove)
    else
        inst.components.talker:Say("I need more sanity!")
    end
end


--Bloomson credit to Abigail  https://steamcommunity.com/sharedfiles/filedetails/?id=2535962194&searchtext=fantasy

local function onattack(inst, attacker, target)
    if not target:IsValid() then
        return
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end
end

local function OnEquip(inst, owner)
    if owner:HasTag("kochosei") then
        owner.AnimState:OverrideSymbol("swap_object", "swap_kochotambourin", "swap_kochotambourin")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
        TurnOn(inst, owner)
    else
        inst:DoTaskInTime(
            0,
            function()
                if owner and owner.components and owner.components.inventory then
                    owner.components.inventory:DropItem(inst, true)
                    if owner.components.talker then
                        owner.components.talker:Say("This is Kochosei's item!!")
                    end
                end
            end
        )
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    TurnOff(inst, owner)
end

local function light_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
    inst.Light:Enable(true)
    inst.Light:SetFalloff(.5)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetColour(200 / 255, 100 / 255, 200 / 255)
    inst.persists = false
    inst:AddTag("FX")
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function fn()
   local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeHauntableLaunch(inst)

    inst.AnimState:SetBank("kochotambourin")
    inst.AnimState:SetBuild("kochotambourin")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    -- Glow in the Dark!
    inst.entity:AddLight()
    inst.Light:Enable(true) -- originally was false.
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(.5)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetColour(200 / 255, 100 / 255, 200 / 255)
	
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.fxcolour = {0 / 255, 255 / 255, 0 / 255}
    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canpoint = false
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster:SetSpellFn(HealFunc2)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("weapon")
    inst.components.weapon:SetOnAttack(onattack)
    inst.components.weapon:SetDamage(20)

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable.walkspeedmult = 1.25
    inst.components.equippable.dapperness = (0.033)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "kochotambourin"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/kochotambourin.xml"

    inst.lights = {}

    MakeHauntableLaunch(inst)

    return inst
end

STRINGS.NAMES.KOCHOTAMBOURIN = "Kochotambourin"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.KOCHOTAMBOURIN = "I want this!! :D"
STRINGS.RECIPE_DESC.KOCHOTAMBOURIN = "Healing teammate"

return Prefab("common/inventory/kochotambourin", fn, assets, prefabs), Prefab("kochotambourin_light", light_fn)

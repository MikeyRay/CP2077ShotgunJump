-- Credit goes to psiberx for Cron!
local Cron = require("Cron/Cron")
registerForEvent('onUpdate', function(delta)
	Cron.Update(delta)
end)

ShotgunJump = {
    minPitch = 55, -- How far you need to look down for it to activate
    isReloading = false,
    weapons = {
        -- Specific weapons
        Carnage_Edgerunners = 15,
        -- Weapon types
        Carnage = 12,
        Satara = 9,
        Crusher = 7,
        Zhuo = 6,
        Tactician = 9,
        Pozhar = 5
    }   
}

registerForEvent("onInit", function()
    Observe('WeaponObject', 'StartReload', function(float)
        -- Need a longer wait here than stop, so that start gets called *after* stop for per-shell weapon support (looking at you, Carnage)
        Cron.After(0.1, function()
            ShotgunJump.isReloading = true
        end)
    end)

    Observe('WeaponObject', 'StopReload', function(status)
        -- A little hacky, but this is mandatory because otherwise StopReload fires before SendAmmoUpdateEvent meaning you can get launched for just reloading
        Cron.After(0.05, function()
            ShotgunJump.isReloading = false
        end)
    end)

    ObserveAfter('WeaponObject', 'SendAmmoUpdateEvent;GameObjectWeaponObject', function(self, weapon) -- This is not ideal for guns that are potentially infinite ammo
        local cameraForward = Game.GetCameraSystem():GetActiveCameraForward()
        local vector = Vector4.new(cameraForward.x, cameraForward.y, cameraForward.z, cameraForward.w)
        local angles = vector:ToRotation()

        if angles.pitch > ShotgunJump.minPitch then -- Only boost if they're looking down! (could also do looking up so you can shoot yourself down?)
            if ShotgunJump.isReloading then
                return
            end

            local weapon = Game.GetActiveWeapon(self)
            local weaponName = TweakDBID.new(weapon:GetItemID().id).value
            local weaponClass = tostring(Game.GetWeaponType(weapon:GetItemID()))
            
            -- If it's not classified as a Shotgun we have no reason to continue
            if not string.find(weaponClass, "Wea_Shotgun") then
                return
            end

            local charge = weapon:GetWeaponChargeNormalized() / 2 -- 50% increase at max charge
            local vectorUp = 0

            for weapon, force in pairs(ShotgunJump.weapons) do
                if string.find(weaponName, weapon) then
                    if force > vectorUp then
                        vectorUp = force * (1 + charge)
                    end
                end
            end

            local impulseEvent = PSMImpulse.new()
            impulseEvent.id = "impulse"
            impulseEvent.impulse = Vector4.new(0, 0, vectorUp, 1)
            self:QueueEvent(impulseEvent)
        end
    end)

    print("Shotgun Jump v1.0 loaded")
end)

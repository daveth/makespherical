
--[[
Copyright (C) 2013 David 'Falcqn' Hepworth

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF 
OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

AddCSLuaFile( "makesphericalcore.lua" )

MakeSpherical = MakeSpherical or {}
local MakeSpherical = MakeSpherical

function MakeSpherical.CanTool( TargetEnt )

	if 	not IsValid( TargetEnt )
		or string.find( TargetEnt:GetClass(), "npc_" ) or ( TargetEnt:GetClass() == "player" )
		or string.find( TargetEnt:GetClass(), "prop_vehicle_" ) 
		or ( TargetEnt:GetClass() == "prop_ragdoll" )
		or ( TargetEnt:GetMoveType() ~= MOVETYPE_VPHYSICS )
		or ( SERVER and not TargetEnt:GetPhysicsObject():IsValid() )

	then 

		return false 

	end

	return true

end

function MakeSpherical.ApplySimpleSphere( TargetEnt, Data )

	if not MakeSpherical.CanTool( TargetEnt ) then return end
	if CLIENT then return end
	local OBB = Vector()
	local Radius = 0
	local PhysObj = TargetEnt:GetPhysicsObject()
	local Mass = PhysObj:GetMass()
	local Sleep = PhysObj:IsAsleep()
	local Moveable = PhysObj:IsMoveable()

	-- We need to store these because applying the spherical collisions overrides the original bounding box
	if not TargetEnt.MSData then
		TargetEnt.MSData = 
		{
			OBBMaxs 		= TargetEnt:OBBMaxs(),
			OBBMins			= TargetEnt:OBBMins(),
			OBBCenter		= TargetEnt:OBBCenter(),
			BoundingRadius 	= TargetEnt:BoundingRadius(),
		}
	end

	OBB = TargetEnt.MSData.OBBMaxs - TargetEnt.MSData.OBBMins

	if Data.Mode == "max" then
		Radius = math.Max( OBB.x, OBB.y, OBB.z ) / 2
	elseif Data.Mode == "x" then
		Radius = OBB.x / 2
	elseif Data.Mode == "y" then
		Radius = OBB.y / 2
	elseif Data.Mode == "z" then
		Radius = OBB.z / 2
	elseif Data.Mode == "obb_radius" then
		Radius = TargetEnt.MSData.BoundingRadius
	elseif Data.Mode == "custom_val" then
		Radius = Data.Radius
	end

	Radius = math.Clamp( Radius, 1, 200 )
	TargetEnt:PhysicsInitSphere( Radius, PhysObj:GetMaterial() )
	TargetEnt:SetCollisionBounds( Vector( -Radius, -Radius, -Radius ), Vector( Radius, Radius, Radius ) )

	-- Applying spherical collisions creates a new physics object for the entity
	PhysObj = TargetEnt:GetPhysicsObject()
	-- Re-apply certain effects so that the entity remains frozen if it was before, etc
	PhysObj:SetMass( Mass )
	PhysObj:EnableMotion( Moveable )
	if not Sleep then PhysObj:Wake() end

	--duplicator.StoreEntityModifier( TargetEnt, "MakeSphericalSimple", Data )

end

function MakeSpherical.Remove( TargetEnt )

	TargetEnt:SetSolid( SOLID_VPHYSICS )
	TargetEnt:PhysicsInit( SOLID_VPHYSICS )
	TargetEnt:SetMoveType( MOVETYPE_VPHYSICS )

end
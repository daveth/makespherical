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

AddCSLuaFile( "MakeSphericalCore.lua" )

MakeSpherical = MakeSpherical or {}
local MakeSpherical = MakeSpherical

function MakeSpherical.CanTool( ent )

	if (
		not ent:IsValid()
		or string.find( ent:GetClass(), "npc_" ) or ( ent:GetClass() == "player" )
		or string.find( ent:GetClass(), "prop_vehicle_" )
		or ( ent:GetClass() == "prop_ragdoll" )
		or ( ent:GetMoveType() ~= MOVETYPE_VPHYSICS )
		or ( SERVER and not ent:GetPhysicsObject():IsValid() ) )

		then return false

	end

	return true

end

if SERVER then

	util.AddNetworkString( "MakeSpherical_AddRenderOffset" )
	util.AddNetworkString( "MakeSpherical_RemoveRenderOffset" )

	MakeSpherical.RenderOffsetEnts = {}

	function MakeSpherical.ApplyLegacySphere( ply, ent, data )

		if hook.Run( "MakeSpherical_PreMakeSphericalLegacy", ply, ent, data ) == false then return end

		local obb = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = ent.noradius or math.max( obb.x, obb.y, obb.z ) / 2
		-- This is the default radius used when left-clicked with the tool, not set by the slider.
		-- It needs to be stored on the entity because it cannot be calculated after the radius has been set manually
		-- The ent's OBB size changes when made spherical

		-- In case the legacy dupe is old enough to not include these
		data.mass = ent:GetPhysicsObject():GetMass() or data.mass
		data.noradius = data.noradius or ent.noradius
		data.isrenderoffset = 0
		data.renderoffset = nil
		data.obbcenter = ent:OBBCenter()

		local phys = ent:GetPhysicsObject()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()

		local radius = math.Clamp( data.radius, 1, 200 )
		if data.enabled then

			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ), Vector( radius, radius, radius ) )

		else

			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )

		end

		-- New physobject after applying spherical collisions
		phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end

		ent.noradius = data.noradius
		ent.obbcenter = data.obbcenter
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )
		duplicator.ClearEntityModifier( ent, "sphere" )

		hook.Run( "MakeSpherical_PostMakeSphericalLegacy", ply, ent, data )

	end

	function MakeSpherical.ApplySphericalCollisions( ply, ent, data )

		if hook.Run( "MakeSpherical_PreMakeSpherical", ply, ent, data ) == false then return end

		local phys = ent:GetPhysicsObject()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		local radius = math.Clamp( data.radius, 1, 200 )

		if data.enabled then

			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ) , Vector( radius, radius, radius ) )

		else

			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )

		end

		if data.isrenderoffset ~= 0 then

			net.Start( "MakeSpherical_AddRenderOffset" )

				net.WriteUInt( ent:EntIndex(), 13 )
				net.WriteVector( data.renderoffset )

			net.Broadcast()

			MakeSpherical.RenderOffsetEnts[ ent:EntIndex() ] = data.renderoffset

		elseif data.isrenderoffset == 0 and MakeSpherical.RenderOffsetEnts[ ent:EntIndex() ] then

			net.Start( "MakeSpherical_RemoveRenderOffset" )

				net.WriteUInt( ent:EntIndex(), 13 )

			net.Broadcast()

		end

		-- New physobject after applying spherical collisions
		phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end

		data.radius = radius
		ent.noradius = data.noradius
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )

		hook.Run( "MakeSpherical_PostMakeSpherical", ply, ent, data )

	end

	function MakeSpherical.ApplySphericalCollisionsE2( ent, enabled, radius )

		if hook.Run( "MakeSpherical_PreMakeSphericalE2", ent, enabled, radius ) == false then return end

		local phys = ent:GetPhysicsObject()
		local mass = phys:GetMass()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		radius = math.Clamp( radius, 1, 200 )

		if enabled then

			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ) , Vector( radius, radius, radius ) )

		else

			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )

		end

		-- New physobject after applying spherical collisions
		phys = ent:GetPhysicsObject()
		phys:SetMass( mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end

			local data = {}
			data.enabled = true
			data.isrenderoffset = 0
			data.mass = mass
			data.obbcenter = ent:OBBCenter()
			data.radius = radius
			data.renderoffset = Vector(0,0,0)
			ent.noradius = data.noradius

		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )

		hook.Run( "MakeSpherical_PostMakeSphericalE2", ent, enabled, radius )

	end

	function MakeSpherical.CopyConstraintData( ent, removeconstraints )

		local constraintdata = {}
		for _, v in pairs( constraint.GetTable( ent ) ) do

			table.insert( constraintdata, v )

		end
		if removeconstraints then constraint.RemoveAll( ent ) end
		return constraintdata

	end

	function MakeSpherical.ApplyConstraintData( ent, constraintdata )

		if not ( table.Count( constraintdata ) > 0 and ent:IsValid() and ent:GetPhysicsObject():IsValid() ) then return end

		for _, constr in pairs( constraintdata ) do

			local factory = duplicator.ConstraintType[ constr.Type ]
			if not factory then

				Msg( "MakeSpherical: Unknown constraint type '" .. constr.Type .. "', skipping\n" )
				break

			end

			-- Set up a table with "ent1 = Entity( n )" etc etc for use with the factory function
			local args = {}
			for i = 1, #factory.Args do

				args[ i ] = constr[ factory.Args[ i ] ]

			end

			-- GG Wire team, spelling "Ctrl" wrong
			-- This section is just to fix stuff like wire hydraulics that need "crontollers"
			if constr.MyCrtl then

				-- Apply the constraint & set all the crap wire hydraulics/winches need etc
				local controller = Entity( constr.MyCrtl )
				controller.constraint:Remove()

				if constr.Type == "WireHydraulic" then

					WireHydraulicTracking[ constr.MyCrtl ] = controller

				elseif constr.Type == "WireWinch" then

					WireWinchTracking[ constr.MyCrtl ] = controller

				end

			end

			-- Apply the constraint
			constr, _ = factory.Func( unpack( args ) )

			-- Wheels need their ent.Motor value set to their motor constraint
			if ent:GetClass() == "gmod_wheel" or ent:GetClass() == "gmod_wire_wheel" then

				ent.Motor = constr

			end

		end

	end

	hook.Add( "PlayerConnected", "MakeSphericalSyncOffsetTable", function( ply )

		for k, v in pairs( MakeSpherical.ApplySphericalCollisions ) do

			net.Start( "MakeSpherical_AddRenderOffset" )

				net.WriteUInt( k, 13 )
				net.WriteVector( v )

			net.Send( ply )

		end

	end )

	duplicator.RegisterEntityModifier( "sphere", MakeSpherical.ApplyLegacySphere )
	duplicator.RegisterEntityModifier( "MakeSphericalCollisions", MakeSpherical.ApplySphericalCollisions )

end

if CLIENT then

	local temp = {}

	net.Receive( "MakeSpherical_AddRenderOffset", function()

		local id = net.ReadUInt( 13 )
		local offset = net.ReadVector()
		local ent = Entity( id )

		if not ent:IsValid() then

			temp[ id ] = offset
			return

		end

		ent.RenderOverride = function()

			ent:SetRenderOrigin( ent:LocalToWorld( offset ) )
			ent:SetupBones()
			if ent.Draw then ent:Draw() else ent:DrawModel() end
			ent:SetRenderOrigin( nil )

		end

	end )

	net.Receive( "MakeSpherical_RemoveRenderOffset", function()

		local id = net.ReadUInt( 13 )
		local ent = Entity( id )
		if not IsValid( ent ) then return end
		ent.RenderOverride = nil

	end )

	hook.Add( "OnEntityCreated", "MakeSphericalEntityAddedDelay", function( ent )

		local id = ent:EntIndex()
		if not temp[ id ] then return end

		ent.RenderOverride = function()

			ent:SetRenderOrigin( offset )
			ent:SetupBones()
			if ent.Draw then ent:Draw() else ent:DrawModel() end
			ent:SetRenderOrigin( nil )

		end

		temp[ id ] = nil

	end )

end
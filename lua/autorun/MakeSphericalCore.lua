
/*

Copyright (C) 2012 David 'Falcqn' Hepworth
All rights not explicitly granted are reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and assosciated files 
(the "software") to use the software without restriction in any and all compatible environments, regardless of whether 
the use is part of a for-profit organisation or not. The software itself may UNDER NO CIRCUMSTANCES be sold, traded or 
monetised in any fashion whatsoever.

The software may NOT be reuploaded to any distributor or redistributed at all unless given express written consent by all 
authors and copyright holders. The software is free to modify for personal use, including but not limited to use on servers 
whether they be "for-profit" organisations or not, provided that this license is left unaltered in any way. 
Again, the software itself may UNDER NO CIRCUMSTANCES be sold, traded or monetised in any fashion whatsoever. 
Any modifications of the software may not be distributed unless either express written consent is given by the authors and
copyright holders, or the modifications are part of a "FORK" on the website "GitHub".

The software and all of its assets included are property of their respective author(s).
The software is provided "As-Is" without warranty of any kind, express or implied, including but not limited to
the warranties of fitness for a particular purpose and noninfringement. In no event shall the authors or copyright
holders be held liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise
arising from, out of, or in connection with the software or the use of other dealings in the software.
Under no circumstances may this license be removed from any of the Software's files, documentation or code.

*/



AddCSLuaFile( "MakeSphericalCore.lua" )

MakeSpherical = MakeSpherical or {}
local MakeSpherical = MakeSpherical

function MakeSpherical.CanTool( ent )

	if (
		not ent:IsValid()
		or string.find( ent:GetClass(), "npc_" ) or ( ent:GetClass() == "player" )
		or ( ent:GetClass() == "prop_ragdoll" )
		or ( ent:GetMoveType() ~= MOVETYPE_VPHYSICS )
		or ( SERVER && not ent:GetPhysicsObject():IsValid() ) )
		
		then return false 
	
	end

	return true

end

if SERVER then
	
	MakeSpherical.RenderOffsetEnts = {}
	
	function MakeSpherical.ApplyLegacySphere( ply, ent, data )
		
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
		local phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end
		
		ent.noradius = data.noradius
		ent.obbcenter = data.obbcenter
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )
		duplicator.ClearEntityModifier( ent, "sphere" )
	
	end
	
	function MakeSpherical.ApplySphericalCollisions( ply, ent, data )
	
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
		
			umsg.Start( "MakeSphericalAddRenderOffset" )
			
				umsg.Short( ent:EntIndex() )
				umsg.Vector( data.renderoffset )
				
			umsg.End()
			
			MakeSpherical.RenderOffsetEnts[ ent:EntIndex() ] = data.renderoffset
			
		elseif data.isrenderoffset == 0 and MakeSpherical.RenderOffsetEnts[ ent:EntIndex() ] then
		
			umsg.Start( "MakeSphericalRemoveRenderOffset" )
			
				umsg.Short( ent:EntIndex() )
				
			umsg.End()
			
		end
		
		-- New physobject after applying spherical collisions
		local phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end
		
		data.radius = radius
		ent.noradius = data.noradius
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )
		
	end
	
	function MakeSpherical.ApplySphericalCollisionsE2( ent, enabled, radius )
		
		local phys = ent:GetPhysicsObject()
		local mass = phys:GetMass()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		local radius = math.Clamp( radius, 1, 200 )
		
		if enabled then
		
			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ) , Vector( radius, radius, radius ) )
		
		else
		
			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )
		
		end
		
		-- New physobject after applying spherical collisions
		local phys = ent:GetPhysicsObject()
		phys:SetMass( mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end
		
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
		
		for k, constr in pairs( constraintdata ) do
			
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
			local constr, misc = factory.Func( unpack( args ) )
			
			-- Wheels need their ent.Motor value set to their motor constraint
			if ent:GetClass() == "gmod_wheel" or ent:GetClass() == "gmod_wire_wheel" then
						
				ent.Motor = constr 
				
			end
			
		end
	
	end
	
	hook.Add( "PlayerConnected", "MakeSphericalSyncOffsetTable", function( ply )
	
		for k, v in pairs( MakeSpherical.ApplySphericalCollisions ) do
		
			umsg.Start( "MakeSphericalAddRenderOffset" )
			
				umsg.Short( k )
				umsg.Vector( v )
			
			umsg.End()
			
		end
		
	end )
	
	duplicator.RegisterEntityModifier( "sphere", MakeSpherical.ApplyLegacySphere )
	duplicator.RegisterEntityModifier( "MakeSphericalCollisions", MakeSpherical.ApplySphericalCollisions )
	
end

if CLIENT then
	
	local temp = {}
	
	usermessage.Hook( "MakeSphericalAddRenderOffset", function( um )
		
		--[[
		local id = um:ReadShort()
		local offset = um:ReadVector()
		
		if not Entity( id ) then 
				
			tempents[ id ] = offset  
				
		else
		
			local ent = Entity( id )
			local csprop
			
			if not IsValid( MakeSpherical.RenderOffsetEnts[ id ] ) then
			
				csprop = ClientsideModel( ent:GetModel() )
				
			else
			
				csprop = MakeSpherical.RenderOffsetEnts[ id ]
				
			end
			
			csprop:SetPos( ent:LocalToWorld( offset ) )
			csprop:SetAngles( ent:GetAngles() )
			csprop:SetParent( ent )
			csprop:SetColor( ent:GetColor() )
			csprop:SetMaterial( ent:GetMaterial() )
			csprop:SetSkin( ent:GetSkin() )
			
			ent:SetModelScale( Vector( 0 ) )
			
			MakeSpherical.RenderOffsetEnts[ id ] = csprop
			
		end
		]]--
		
		local id = um:ReadShort()
		local offset = um:ReadVector()
		local ent = Entity( id )
		
		if not ent:IsValid() then
		
			temp[ id ] = offset
			return
			
		end
		
		ent.RenderOverride = function( self )
			
			ent:SetRenderOrigin( ent:LocalToWorld( offset ) )
			ent:SetupBones()
			if ent.Draw then ent:Draw() else ent:DrawModel() end
			ent:SetRenderOrigin( nil )
		
		end
		
	end )
	
	usermessage.Hook( "MakeSphericalRemoveRenderOffset", function( um )
	
		--[[
		local id = um:ReadShort()
		local ent = Entity( id )
		print( "removing" )
		if MakeSpherical.RenderOffsetEnts[ id ] then 
			
			ent:SetModelScale( Vector( 1, 1, 1 ) )
			MakeSpherical.RenderOffsetEnts[ id ]:Remove()
			MakeSpherical.RenderOffsetEnt[ id ] = nil
			
		end
		]]--
		
		local ent = Entity( um:ReadShort() )
		ent.RenderOverride = nil
		
	end )
	
	hook.Add( "OnEntityCreated", "MakeSphericalEntityAddedDelay", function( ent )
	
		--[[
		if not ent:IsValid() then return end
		local id = ent:EntIndex()
		if tempents[ id ] then
			
			if not IsValid( MakeSpherical.RenderOffsetEnts[ id ] ) then
			
				local csprop = ClientsideModel( ent:GetModel() )
				
			else
			
				local csprop = MakeSpherical.RenderOffsetEnts[ id ]
				
			end
			
			csprop:SetPos( ent:LocalToWorld( offset ) )
			csprop:SetAngles( ent:GetAngles() )
			csprop:SetParent( ent )
			csprop:SetColor( ent:GetColor() )
			csprop:SetMaterial( ent:GetMaterial() )
			csprop:SetSkin( ent:GetSkin() )
			
			ent:SetModelScale( Vector( 0 ) )
		
			MakeSpherical.RenderOffsetEnts[ id ] = csprop
			tempents[ id ] = nil
			
		end
		]]--
		
		local id = ent:EntIndex()
		if not temp[ id ] then return end
		
		ent.RenderOverride = function( self )
		
			ent:SetRenderOrigin( offset )
			ent:SetupBones()
			if ent.Draw() then ent:Draw() else ent:DrawModel() end
			ent:SetRenderOrigin( nil )
			
		end
		
		temp[ id ] = nil
		
	end )
	
end
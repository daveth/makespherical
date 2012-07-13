
/* 
	MakeSpherical tool made by Dave ( Falcqn )
*/

if CLIENT then
	
	language.Add( "Tool_MakeSpherical_name", "Spherical Collisions" )
	language.Add( "Tool_MakeSpherical_desc", "Gives entities a spherical collisions with a defined radius" )
	language.Add( "Tool_MakeSpherical_0", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	language.Add( "Tool_MakeSpherical_1", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	language.Add( "MakeSpherical_radius", "Set radius: " )
	
	function TOOL.BuildCPanel( panel )
		
		panel:AddControl( "Header", { Text = "#Tool_MakeSpherical_name", Description = "Tool_MakeSpherical_desc" } )
		
		panel:AddControl( "Slider", 
		{
			Label = "#MakeSpherical_radius",
			Type = "Float",
			Min = "1",
			Max = "200",
			Command = "makespherical_radius"
		})
	
end
	
end

TOOL.Category		= "Construction"
TOOL.Name			= "#MakeSpherical"
TOOL.ClientConVar[ "radius" ] = "20"

local function IsItOkToFuckWith( This )
	
	if !This || !This:IsValid() then return false end
	if string.find( This:GetClass(), "npc_" ) || This:GetClass() == "player" then return false end
	if This:GetMoveType() ~= MOVETYPE_VPHYSICS then return end
	if SERVER and not This:GetPhysicsObject():IsValid() then return false end

	return true
	
end

local LegacyProcessQue = {}

local function MakeSphere( Ply, Ent, Data )
	
	if not SERVER then return end
	
	-- Check if legacy dupe
	
	if not Data.mass then
		
		--print( "Legacy Dupe" )
		local OBB = Ent:OBBMaxs() - Ent:OBBMins()
		if not Ent.noradius then Ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 end
		
		local Args = 
		{
			Ply, 
			Ent,  
			{
				noradius = Ent.noradius,
				mass = Ent:GetPhysicsObject():GetMass(),
				radius = Ent.noradius,
				enabled = true
			}
		}
		
		-- Add it to a que of ents to process later
		table.insert( LegacyProcessQue, Args )
		
		return
		
	end
	
	local PhysObj = Ent:GetPhysicsObject()
	local MakeConstraints = false
	local ConstraintsTable = {}
	local IsMoveable = PhysObj:IsMoveable()
	local IsSleep = PhysObj:IsAsleep()
	
	local Radius = math.Clamp( Data.radius, 1, 200 )
		
	-- need to remove re-apply constraints afterward
	if Ent:IsConstrained() then
		
		MakeConstraints = true
		for _, Const in pairs( constraint.GetTable( Ent ) ) do
		
			table.insert( ConstraintsTable, Const )
			
		end
		constraint.RemoveAll( Ent )
		
	end
	
	if Data.enabled then

		Ent:PhysicsInitSphere( Radius , PhysObj:GetMaterial() )
		Ent:SetCollisionBounds( Vector( -Radius, -Radius, -Radius ), Vector( Radius, Radius, Radius ) )
		
	else
	
		Ent:PhysicsInit( SOLID_VPHYSICS )
		Ent:SetMoveType( MOVETYPE_VPHYSICS )
		Ent:SetSolid( SOLID_VPHYSICS )
	
	end
	
	if MakeConstraints then
		
		-- re-apply constraints
		for k, Constr in pairs( ConstraintsTable ) do
		
			local Factory = duplicator.ConstraintType[ Constr.Type ]
			if !( Factory ) then break end
			
			-- set up args to be passed to factory function
			local Args = {}
			for i = 1, #Factory.Args do
				
				table.insert( Args, Constr[ Factory.Args[ i ] ] )
				
			end
			
			-- wheels need the ent.motor value set to their motor constraint
			if Ent:GetClass() == "gmod_wheel" or Ent:GetClass() == "gmod_wire_wheel" and Constr.Type == "motor" then
			
				timer.Simple( 0.01, function( Ent, Args )
				
					Ent.Motor = Factory.Func( unpack( Args ) )
				
				end, Ent, Args )
			
			else
			
				timer.Simple( 0.01, Factory.Func, unpack( Args ) )
			
			end
			
		end
	
	end
	
	local PhysObj = Ent:GetPhysicsObject()
	PhysObj:SetMass( Data.mass )
	PhysObj:EnableMotion( IsMoveable )
	if !IsSleep then PhysObj:Wake() end
	
	--Ent.CanPGBM = Data.enabled and false or true
	Ent.noradius = Data.noradius
	duplicator.StoreEntityModifier( Ent, "sphere", Data )
	
end

hook.Add( "AdvDupe_FinishPasting", "MakeSphericalFixLegacyDupes", function()
	
	for k, v in pairs( LegacyProcessQue ) do
		
		MakeSphere( unpack( v ) )
		LegacyProcessQue[ k ] = nil
		
	end

end )

duplicator.RegisterEntityModifier( "sphere", MakeSphere )

function TOOL:LeftClick( trace )

	local Ent = trace.Entity
	if !IsItOkToFuckWith( Ent ) then return false end
	
	local OBB = Ent:OBBMaxs() - Ent:OBBMins()
	if not Ent.noradius then Ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 end
	
	if SERVER then
	
		local Data = 
		{
			noradius = Ent.noradius,
			mass = Ent:GetPhysicsObject():GetMass(),
			radius = Ent.noradius,
			enabled = true
		}
		
		MakeSphere( self:GetOwner(), Ent, Data )
		
	end
	
	return true
	
end

function TOOL:RightClick( trace )

	local Ent = trace.Entity
	if !IsItOkToFuckWith( Ent ) then return false end
	
	local OBB = Ent:OBBMaxs() - Ent:OBBMins()
	if not Ent.noradius then Ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 end
	
	if SERVER then

	
		local Data = 
		{
			noradius = Ent.noradius,
			mass = Ent:GetPhysicsObject():GetMass(),
			radius = self:GetClientNumber( "radius" ),
			enabled = true
		}
	
		MakeSphere( self:GetOwner(), Ent, Data )
		
	end
	
	return true
		
end

function TOOL:Reload( trace )

	local Ent = trace.Entity
	if !IsItOkToFuckWith( Ent ) then return false end
	
	if SERVER then

		local Data = 
		{
			noradius = Ent.noradius,
			mass = Ent:GetPhysicsObject():GetMass(),
			radius = 0,
			enabled = false
		}
		
		Ent:GetPhysicsObject():EnableMotion( false )
		MakeSphere( self:GetOwner(), Ent, Data )
		
	end
	
	return true
	
end

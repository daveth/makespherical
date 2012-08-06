AddCSLuaFile( "makespherical.lua" )

/*
	MakeSpherical tool made by Dave ( Falcqn )
	Thanks to:
		Divran
		OmicroN
*/

if CLIENT then
	
	language.Add( "Tool_MakeSpherical_name", "Spherical Collisions" )
	language.Add( "Tool_MakeSpherical_desc", "Gives entities a spherical collisions with a defined radius" )
	language.Add( "Tool_MakeSpherical_0", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	language.Add( "Tool_MakeSpherical_1", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	
	function TOOL.BuildCPanel( panel )
		
		panel:AddControl( "Header", { Text = "#Tool_MakeSpherical_name", Description = "Tool_MakeSpherical_desc" } )
		
		panel:AddControl( "Slider", 
		{
			Label = "Set radius: ",
			Type = "Float",
			Min = "1",
			Max = "200",
			Command = "makespherical_radius"
		})
		
		panel:AddControl( "CheckBox",
		{
			Label = "Offset render origin?",
			Command = "makespherical_offset"
		})
		
		panel:AddControl( "Label",
		{
			Text = "Note: This only changes the position the prop's model is drawn at, getting the position or bounding box center in Lua or in "
					.. "E2 will give the exact same coordinates.\nThe prop's position will still be the center of the sphere."
		})
		
		panel:AddControl( "Slider",
		{
			Label = "X Offset",
			Type = "Float",
			Min = "-100",
			Max = "100",
			Command = "makespherical_offset_x"
		})
		
		panel:AddControl( "Slider",
		{
			Label = "Y Offset",
			Type = "Float",
			Min = "-100",
			Max = "100",
			Command = "makespherical_offset_y"
		})
		
		panel:AddControl( "Slider",
		{
			Label = "Z Offset",
			Type = "Float",
			Min = "-100",
			Max = "100",
			Command = "makespherical_offset_z"
		})
		
		panel:AddControl( "CheckBox",
		{
			Label = "Offset position by bounding box center instead",
			Command = "makespherical_useobbcenter"
		})
	
	end

end

TOOL.Category = "Construction"
TOOL.Name = "#MakeSpherical"
TOOL.ClientConVar[ "radius" ] = "20"
TOOL.ClientConVar[ "offset" ] = "0"
TOOL.ClientConVar[ "offset_x" ] = "0"
TOOL.ClientConVar[ "offset_y" ] = "0"
TOOL.ClientConVar[ "offset_z" ] = "0"
TOOL.ClientConVar[ "useobbcenter" ] = "0"

MakeSpherical = MakeSpherical or {}
local MakeSpherical = MakeSpherical

function TOOL:LeftClick( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	local renderoffset
	if self:GetClientNumber( "useobbcenter" ) == 1 then
		
		renderoffset = -ent:OBBCenter()
			
	else
	
		renderoffset = Vector( self:GetClientNumber( "offset_x" ), self:GetClientNumber( "offset_y" ), self:GetClientNumber( "offset_z" ) )
		
	end
	
	if SERVER then
		
		local data = 
		{
			noradius = ent.noradius,
			radius = ent.noradius,
			mass = ent:GetPhysicsObject():GetMass(),
			enabled = true,
			isrenderoffset = self:GetClientNumber( "offset" ),
			renderoffset = renderoffset
		}
		
		local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
		MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
		timer.Simple( 0.01, MakeSpherical.ApplyConstraintData, ent, constraintdata )
		
	end
	
	return true

end

function TOOL:RightClick( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	local renderoffset
	if self:GetClientNumber( "useobbcenter" ) == 1 then
		
		renderoffset = -ent:OBBCenter()
			
	else
	
		renderoffset = Vector( self:GetClientNumber( "offset_x" ), self:GetClientNumber( "offset_y" ), self:GetClientNumber( "offset_z" ) )
		
	end
	
	if SERVER then
	
		local data = 
		{
			noradius = ent.noradius,
			radius = self:GetClientNumber( "radius" ),
			mass = ent:GetPhysicsObject():GetMass(),
			enabled = true,
			isrenderoffset = self:GetClientNumber( "offset" ),
			renderoffset = renderoffset
		}
		
		local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
		MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
		timer.Simple( 0.01, MakeSpherical.ApplyConstraintData, ent, constraintdata )
		
	end
	
	return true

end

function TOOL:Reload( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	if SERVER then
	
		local data = 
		{
			noradius = ent.noradius,
			radius = ent.noradius,
			mass = ent:GetPhysicsObject():GetMass(),
			enabled = false,
			isrenderoffset = 0,
			renderoffset = nil
		}
		
		local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
		MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
		timer.Simple( 0.01, MakeSpherical.ApplyConstraintData, ent, constraintdata )
		
	end
	
	return true
	
end
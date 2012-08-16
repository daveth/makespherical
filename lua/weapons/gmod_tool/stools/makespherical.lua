
/*

Copyright (C) 2012 David 'Falcqn' Hepworth [davidhepp2@gmail.com]
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

AddCSLuaFile( "makespherical.lua" )

TOOL.Category 		= "Construction"
TOOL.Name 			= "#MakeSpherical"
TOOL.Command 		= nil
TOOL.ConfigName 	= nil

TOOL.ClientConVar[ "radius" ] 		= "20"
TOOL.ClientConVar[ "offset" ] 		= "0"
TOOL.ClientConVar[ "offset_x" ] 	= "0"
TOOL.ClientConVar[ "offset_y" ] 	= "0"
TOOL.ClientConVar[ "offset_z" ] 	= "0"
TOOL.ClientConVar[ "useobbcenter" ] = "0"

if CLIENT then
	
	language.Add( "tool.makespherical.name", "Spherical Collisions" )
	language.Add( "tool.makespherical.desc", "Gives entities a spherical collisions with a defined radius" )
	language.Add( "tool.makespherical.0", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	language.Add( "tool.makespherical.1", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	
	--gm12
	language.Add( "tool_makespherical_name", "Spherical Collisions" )
	language.Add( "tool_makespherical_desc", "Gives entities a spherical collisions with a defined radius" )
	language.Add( "tool_makespherical_0", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	language.Add( "tool_makespherical_1", "Left click to make an Ent have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	
	function TOOL.BuildCPanel( panel )
		
		panel:AddControl( "Header", { Text = "#tool.makespherical.name", Description = "#tool.makespherical.desc" } )
		
		panel:AddControl( "Slider", 
		{
			Label 	= "Set radius: ",
			Type 	= "Float",
			Min 	= "1",
			Max 	= "200",
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
			Label 	= "X Offset",
			Type 	= "Float",
			Min 	= "-100",
			Max 	= "100",
			Command = "makespherical_offset_x"
		})
		
		panel:AddControl( "Slider",
		{
			Label 	= "Y Offset",
			Type 	= "Float",
			Min 	= "-100",
			Max 	= "100",
			Command = "makespherical_offset_y"
		})
		
		panel:AddControl( "Slider",
		{
			Label 	= "Z Offset",
			Type 	= "Float",
			Min		= "-100",
			Max 	= "100",
			Command = "makespherical_offset_z"
		})
		
		panel:AddControl( "CheckBox",
		{
			Label = "Offset position by bounding box center instead",
			Command = "makespherical_useobbcenter"
		})
	
	end

end

function TOOL:LeftClick( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if CLIENT then return true end

	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	ent.obbcenter = ent.obbcenter or ent:OBBCenter()
	local offsetvec = Vector( self:GetClientNumber( "offset_x" ), self:GetClientNumber( "offset_y" ), self:GetClientNumber( "offset_z" ) )
	
	local data = 
	{
		// I store the obbcenter and "obb radius" because they are altered when SetCollisionBounds is used
		// This allows the spherical collisions to be reset even after duping
		obbcenter 		= ent.obbcenter,
		noradius 		= ent.noradius,
		radius 			= ent.noradius,
		mass 			= ent:GetPhysicsObject():GetMass(),
		enabled 		= true,
		isrenderoffset 	= self:GetClientNumber( "offset" ),
		renderoffset 	= ( self:GetClientNumber( "useobbcenter" ) == 1 ) and -ent.obbcenter or offsetvec
	}
	
	local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
	MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
	timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
		
	return true

end

function TOOL:RightClick( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if CLIENT then return true end

	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	ent.obbcenter = ent.obbcenter or ent:OBBCenter()
	local offsetvec = Vector( self:GetClientNumber( "offset_x" ), self:GetClientNumber( "offset_y" ), self:GetClientNumber( "offset_z" ) )

	local data = 
	{
		obbcenter		= ent.obbcenter,							
		noradius 		= ent.noradius,
		radius 			= self:GetClientNumber( "radius" ),
		mass			= ent:GetPhysicsObject():GetMass(),
		enabled 		= true,
		isrenderoffset 	= self:GetClientNumber( "offset" ),
		renderoffset 	= ( self:GetClientNumber( "useobbcenter" ) == 1 ) and -ent.obbcenter or offsetvec
	}
	
	local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
	MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
	timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
	
	return true

end

function TOOL:Reload( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if CLIENT then return true end
	
	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	ent.obbcenter = ent.obbcenter or ent:OBBCenter()
	
	local data = 
	{
		obbcenter 		= ent.obbcenter,
		noradius 		= ent.noradius,
		radius 			= ent.noradius,
		mass 			= ent:GetPhysicsObject():GetMass(),
		enabled 		= false,
		isrenderoffset 	= 0,
		renderoffset 	= nil
	}
	
	local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
	MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
	timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
	
	return true
	
end
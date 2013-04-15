
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

AddCSLuaFile( "makespherical.lua" )
include( "makesphericalcore.lua" )

TOOL.Category 		= "Construction"
TOOL.Name 			= "#tool.makespherical.name"
TOOL.Command 		= nil
TOOL.ConfigName 	= nil

TOOL.ClientConVar[ "setvalue" ] = "max"
TOOL.ClientConVar[ "radius" ] 	= 25

function TOOL.BuildCPanel( CPanel )
		
	CPanel:AddControl( "Header", 
	{ 
		Text = "#tool.makespherical.name",
		Description	= "#tool.makespherical.desc"
	} )

	local Options = 
	{ 
		Default =
		{
			makespherical_setvalue 	= "max",
			makespherical_radius	= 25
		}
	}
								
	local CVars = 
	{
		"makespherical_setvalue",
		"makespherical_radius"
	}

	CPanel:AddControl( "ComboBox", 
	{ 
		Label 		= "#tool.presets",
		MenuButton 	= 1,
		Folder 		= "makespherical",
		Options 	= Options,
		CVars 		= CVars
	} )

	CPanel:AddControl( "ComboBox",
	{
		Label 	= "Radius Value",
		Command = "makespherical_setvalue",
		Options = MakeSphericalValueOptions
	} )

	CPanel:AddControl( "Slider",
	{
		Label 	= "Custom Radius",
		Type 	= "Float",
		Min		= 1,
		Max 	= 200,
		Command = "makespherical_radius"
	} )

end

function TOOL:LeftClick( Trace )

	if not MakeSpherical.CanTool( Trace.Entity ) then return false end
	local TargetEnt = Trace.Entity
	local Data = 
	{
		Mode = self:GetClientInfo( "setvalue" ),
		Radius = self:GetClientNumber( "radius" )
	}
	MakeSpherical.ApplySimpleSphere( TargetEnt, Data )

	return true

end

function TOOL:RightClick( Trace )

end

function TOOL:Reload( Trace )

	if not MakeSpherical.CanTool( Trace.Entity ) then return false end
	if not SERVER then return true end
	MakeSpherical.Remove( Trace.Entity )

	return true

end

if CLIENT then

	language.Add( "tool.makespherical.name", "Make Spherical" )
	language.Add( "tool.makespherical.desc", "Left click to give an object spherical collisions. Right click on an object for a more advanced menu." )

end

MakeSphericalValueOptions = 
{
	[ "#Bounding Radius" ] 	= { 1, makespherical_setvalue = "obb_radius" },
	[ "#Maximum Width" ] 	= { 2, makespherical_setvalue = "max" },
	[ "#X Width" ] 			= { 3, makespherical_setvalue = "x" },
	[ "#Y Width" ] 			= { 4, makespherical_setvalue = "y" },
	[ "#Z Width" ] 			= { 5, makespherical_setvalue = "z" },
	[ "#Custom Value" ] 	= { 6, makespherical_setvalue = "custom_val" },
}
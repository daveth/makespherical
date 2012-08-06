
/*
	MakeSpherical tool made by Dave ( Falcqn )
	Thanks to:
		Divran
		OmicroN
*/

MakeSpherical = MakeSpherical or {}
local MakeSpherical = MakeSpherical

e2function void entity:makeSpherical( number radius )

	if not MakeSpherical.CanTool( this ) then return false end

	local constraintdata = MakeSpherical.CopyConstraintData( this, true )
	MakeSpherical.ApplySphericalCollisionsE2( this, true, radius, nil )
	timer.Simple( 0.01, MakeSpherical.ApplyConstraintData, this, constraintdata )

end

e2function void entity:removeSpherical()

	if not MakeSpherical.CanTool( this ) then return false end

	local constraintdata = MakeSpherical.CopyConstraintData( this, true )
	MakeSpherical.ApplySphericalCollisionsE2( this, false, 0, nil )
	timer.Simple( 0.01, MakeSpherical.ApplyConstraintData, this, constraintdata )
	
end
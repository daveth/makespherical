
/* 
	MakeSpherical E2 Extension
	Made by Dave ( Falcqn )
*/

local function MakeSphere( Ply, this, Data )
	
	local PhysObj = this:GetPhysicsObject()
	local MakeConstraints = false
	local ConstraintsTable = {}
	local IsMoveable = PhysObj:IsMoveable()
	local IsSleep = PhysObj:IsAsleep()
		
	local Radius = math.Clamp( Data.radius, 1, 200 )
	
	-- need to remove re-apply constraints afterward
	if this:IsConstrained() then
		
		MakeConstraints = true
		for _, Const in pairs( constraint.GetTable( this ) ) do
		
			table.insert( ConstraintsTable, Const )
			
		end
		constraint.RemoveAll( this )
		
	end
	
	if Data.enabled then
	
		this:PhysicsInitSphere( Radius , PhysObj:GetMaterial() )
		this:SetCollisionBounds( Vector( -Radius, -Radius, -Radius ), Vector( Radius, Radius, Radius ) )
		
	else
	
		this:PhysicsInit( SOLID_VPHYSICS )
		this:SetMoveType( MOVETYPE_VPHYSICS )
		this:SetSolid( SOLID_VPHYSICS )
	
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
			
			-- wheels need the this.motor value set to their motor constraint
			if this:GetClass() == "gmod_wheel" or this:GetClass() == "gmod_wire_wheel" and Constr.Type == "motor" then
			
				timer.Simple( 0.01, function( this, Args )
				
					this.Motor = Factory.Func( unpack( Args ) )
				
				end, this, Args )
			
			else
			
				timer.Simple( 0.01, Factory.Func, unpack( Args ) )
			
			end
			
		end
	
	end

	local PhysObj = this:GetPhysicsObject()
	PhysObj:SetMass( Data.mass )
	PhysObj:EnableMotion( IsMoveable )
	if !IsSleep then PhysObj:Wake() end
	
	--this.CanPGBM = Data.enabled and false or true
	this.noradius = Data.noradius
	
end

e2function void entity:makeSpherical( number radius )

	local OBB = this:OBBMaxs() - this:OBBMins()
	if not this.noradius then this.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 end
	
	if SERVER then
	
		local Data = 
		{
			noradius = this.noradius,
			mass = this:GetPhysicsObject():GetMass(),
			radius = radius,
			enabled = true
		}
		
		MakeSphere( self.player, this, Data )
		
	end

end

e2function void entity:removeSpherical()

	local Data = 
	{
		noradius = this.noradius,
		mass = this:GetPhysicsObject():GetMass(),
		radius = 0,
		enabled = false
	}

	this:GetPhysicsObject():EnableMotion( false )
	MakeSphere( self.player, this, Data )

end
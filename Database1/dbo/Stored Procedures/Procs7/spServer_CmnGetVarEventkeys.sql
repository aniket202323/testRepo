CREATE PROCEDURE dbo.spServer_CmnGetVarEventkeys
@VarId int
AS
Declare
  @EventType int,
  @MatDefId uniqueidentifier,
  @MatClassName nVarChar(100),
  @PUId int
Select @PUId = NULL
Select @EventType = NULL
Select @EventType = Event_Type, @PUId = PU_Id From Variables_Base Where Var_Id = @VarId
If (@EventType Is NULL)
 	 Return
 	 
If (@EventType = 31) Or (@EventType = 32)
 	 Begin
 	  	 If (@PUId = -100)
 	  	  	 Begin
 	  	  	  	 Select @MatDefId = NULL
 	  	  	  	 Select @MatDefId = Origin1MaterialDefinitionId From Variables_Aspect_MaterialDefinitionProperty Where (Var_Id = @VarId)
 	  	  	  	 If (@MatDefId Is Not Null)
 	  	  	  	  	 Select Prod_Id From Products_Aspect_MaterialDefinition Where Origin1MaterialDefinitionId = @MatDefId
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @MatClassName = NULL
 	  	  	  	  	  	 Select @MatClassName = Origin2MaterialClassName From Variables_Aspect_MaterialDefinitionProperty Where (Var_Id = @VarId)
 	  	  	  	  	  	 If (@MatClassName Is Not NULL)
 	  	  	  	  	  	  	 Select Prod_Id From Products_Aspect_MaterialDefinition Where Origin1MaterialDefinitionId in
 	  	  	  	  	  	  	  	 (Select MaterialDefinitionId From MaterialClass_MaterialDefinition Where (MaterialClassName = @MatClassName)) 
 	  	  	  	  	 End
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 Select -1
 	  	  	 End
 	 End

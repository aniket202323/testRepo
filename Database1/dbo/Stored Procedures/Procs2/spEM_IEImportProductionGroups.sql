CREATE PROCEDURE dbo.spEM_IEImportProductionGroups
 	 @PL_Desc 	  	 nvarchar(50),
 	 @PU_Desc 	  	 nvarchar(50),
 	 @PUG_Desc 	  	 nvarchar(50),
 	 @External_Link 	 nvarchar(255),
 	 @Group_Desc 	  	 nvarchar(50),
 	 @User_Id 	  	 Int
As
Declare 	 @PL_Id 	  	 int,
 	  	 @PU_Id 	  	 int,
 	  	 @Group_Id 	 int,
 	  	 @PUG_Order 	 int,
 	  	 @PUG_Id  	 int
/* Initialization */
Select 	 @PL_Id 	  	 = Null,
 	  	 @PU_Id 	 = Null,
 	  	 @PUG_Id 	 = Null,
 	  	 @Group_Id 	 = Null
/* Clean and verify arguments */
Select 	 @PL_Desc  	 = ltrim(rtrim(@PL_Desc)),
 	 @PU_Desc  	 = ltrim(rtrim(@PU_Desc)),
 	 @PUG_Desc  	 = ltrim(rtrim(@PUG_Desc)),
 	 @Group_Desc 	 = ltrim(rtrim(@Group_Desc)),
 	 @External_Link 	 = ltrim(rtrim(@External_Link))
If @PL_Desc = '' Or @PL_Desc Is Null
  Begin
 	 Select 'Failed - Missing Production Line'
 	 Return (-100)
  End
If @PU_Desc = '' Or @PU_Desc Is Null
  Begin
 	 Select 'Failed - Missing Production Unit'
 	 Return (-100)
  End
If @PUG_Desc = '' Or @PUG_Desc Is Null
  Begin
 	 Select 'Failed - Missing Production Group'
 	 Return (-100)
  End
/* Get configuration data */
If @Group_Desc Is Not Null And @Group_Desc <> ''
   Begin
     Select @Group_Id = Group_Id From Security_Groups
       Where Group_Desc = @Group_Desc
     If @Group_Id Is Null
 	   Begin
 	  	 Select 'Failed - Security Group Not Found'
 	  	 Return (-100)
 	   End
   End
/* Get PL_Id  */
Select @PL_Id = PL_Id From Prod_Lines
 Where PL_Desc = @PL_Desc
If @PL_Id Is Null
  Begin
 	 Select 'Failed - Production Line not found.'
 	 Return (-100)
  End
Select @PU_Id = PU_Id From Prod_Units
   Where PU_Desc = @PU_Desc And PL_Id = @PL_Id
If @PU_Id Is Null
  Begin
 	 Select 'Failed - Production Unit not found.'
 	 Return (-100)
  End
Select @PUG_Id = PUG_Id  From PU_Groups
    Where PUG_Desc = @PUG_Desc And PU_Id = @PU_Id
If @PUG_Id Is Null
  Begin
    Select @PUG_Order = Max(PUG_Order) + 1
     From PU_Groups
     Where PU_Id = @PU_Id
 	 Select @PUG_Order = Coalesce(@PUG_Order,1)
 	 Execute spEM_CreatePUG  @PUG_Desc,@PU_Id,@PUG_Order,@User_Id,@PUG_Id OUTPUT
    If @PUG_Id Is Null
   	   Begin
 	  	 Select 'Failed - could not create group.'
 	  	 Return (-100)
   	   End
  End
  Execute spEM_PutSecurityGroup @PUG_Id,@Group_Id,@User_Id
  Execute spEM_PutExtLink  @PUG_Id,'af',@External_Link,'', 0,@User_Id
Return (0)

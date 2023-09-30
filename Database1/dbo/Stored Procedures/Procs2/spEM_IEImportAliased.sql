CREATE PROCEDURE dbo.spEM_IEImportAliased
@Result_PL_Desc 	  nvarchar(50),
@Result_PU_Desc 	  nvarchar(50),
@Result_Var_Desc nvarchar(50),
@Alias_PL_Desc 	  nvarchar(50),
@Alias_PU_Desc 	  nvarchar(50),
@Alias_Var_Desc 	  nvarchar(50),
@User_Id 	  	 int
AS
Declare 	 @Result_PL_Id 	 int,
 	  	 @Result_PU_Id 	 int,
 	  	 @Result_PUG_Id 	 int,
 	  	 @Alias_PL_Id 	 int,
 	  	 @Alias_PU_Id 	 int,
 	  	 @Alias_PUG_Id 	 int,
 	  	 @Count 	  	  	 int,
 	  	 @Result_Var_Id 	 int,
 	  	 @Alias_Var_Id  	 int
/* Initialization */
Select 	 @Result_PL_Id 	  	 = Null,
 	 @Result_PU_Id 	  	 = Null,
 	 @Result_PUG_Id 	 = Null,
 	 @Result_Var_Id 	  	 = Null,
 	 @Alias_PL_Id 	  	 = Null,
 	 @Alias_PU_Id 	  	 = Null,
 	 @Alias_PUG_Id 	  	 = Null,
 	 @Alias_Var_Id 	  	 = Null,
 	 @Count 	  	  	 = 0
/* Clean and verify arguments */
Select 	 @Result_PL_Desc  	 = LTrim(RTrim(@Result_PL_Desc)),
 	  	 @Result_PU_Desc  	 = LTrim(RTrim(@Result_PU_Desc)),
 	  	 @Result_Var_Desc  	 = LTrim(RTrim(@Result_Var_Desc)),
 	  	 @Alias_PL_Desc  	  	 = LTrim(RTrim(@Alias_PL_Desc)),
 	  	 @Alias_PU_Desc  	  	 = LTrim(RTrim(@Alias_PU_Desc)),
 	  	 @Alias_Var_Desc  	 = LTrim(RTrim(@Alias_Var_Desc))
If @Result_PL_Desc = '' Or @Result_PL_Desc Is Null Or @Alias_PL_Desc = '' Or @Alias_PL_Desc Is Null
  Begin
 	 Select 'Failed - Production Line Missing'
     Return (-100)
  End
If @Result_PU_Desc = '' Or @Result_PU_Desc Is Null Or @Alias_PU_Desc = '' Or @Alias_PU_Desc Is Null
  Begin
 	 Select 'Failed - Production Unit Missing'
     Return (-100)
  End
If @Result_Var_Desc = '' Or @Result_Var_Desc Is Null Or @Alias_Var_Desc = '' Or @Alias_Var_Desc Is Null
  Begin
 	 Select 'Failed - Variable Missing'
     Return (-100)
  End
Select @Result_PL_Id = PL_Id
  From Prod_Lines
  Where PL_Desc = @Result_PL_Desc
If @Result_PL_Id is NUll
  Begin
 	 Select 'Failed - Production Line not found'
     Return (-100)
  End
Select @Result_PU_Id = PU_Id
  From Prod_Units
  Where PU_Desc = @Result_PU_Desc And PL_Id = @Result_PL_Id
If @Result_PU_Id is NUll
  Begin
 	 Select 'Failed - Production Unit not found'
     Return (-100)
  End
Select @Result_Var_Id = Var_Id
  From Variables
  Where Var_Desc = @Result_Var_Desc And PU_Id = @Result_PU_Id
If @Result_Var_Id Is Null
  Begin
 	 Select 'Failed - Variable not found'
     Return (-100)
  End
Select @Alias_PL_Id = PL_Id
  From Prod_Lines
  Where PL_Desc = @Alias_PL_Desc
If @Alias_PL_Id Is Null
  Begin
 	 Select 'Failed - Production Line not found'
     Return (-100)
  End
Select @Alias_PU_Id = PU_Id
  From Prod_Units
  Where PU_Desc = @Alias_PU_Desc And PL_Id = @Alias_PL_Id
If @Alias_PU_Id Is Null
  Begin
 	 Select 'Failed - Production Unit not found'
     Return (-100)
  End
Select @Alias_Var_Id = Var_Id
  From Variables
  Where Var_Desc = @Alias_Var_Desc And PU_Id = @Alias_PU_Id
If @Alias_Var_Id Is Null
  Begin
 	 Select 'Failed - Variable not found'
     Return (-100)
  End
If (Select count(*) From Variable_Alias Where Src_Var_Id = @Alias_Var_Id And Dst_Var_Id = @Result_Var_Id) = 0 
 Execute spEM_PutAliasedVar  @Result_Var_Id,@Alias_Var_Id,1,@User_Id
Else
  Begin
 	 Select 'Failed - Alias already exists'
     Return (-100)
  End
Return (0)

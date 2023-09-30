CREATE PROCEDURE dbo.spEM_IEImportProductProperties
 	 @Prop_Desc 	  	 nvarchar(50),
 	 @External_Link 	 nvarchar(255),
 	 @Group_Desc 	  	 nvarchar(50),
 	 @User_Id 	  	 Int
AS
Declare @Group_Id 	 int,
 	  	 @Prop_Id 	 int
/* Initialize */
Select  	 @Prop_Id = Null
/* Clean and verify arguments */
Select  	 @Prop_Desc 	  	 = ltrim(rtrim(@Prop_Desc)),
 	  	 @Group_Desc 	  	 = ltrim(rtrim(@Group_Desc)),
 	  	 @External_Link 	 = ltrim(rtrim(@External_Link))
If @Prop_Desc Is Null Or @Prop_Desc = ''
  Begin
 	 Select 'Failed - Product Property missing'
 	 Return (-100)
  End
/* Get Configuration ids */
If @Group_Desc Is Not Null And @Group_Desc <> ''
 Begin
   Select @Group_Id = Group_Id From Security_Groups
     Where Group_Desc = @Group_Desc
     If @Group_Id Is Null
 	   Begin
 	  	 Select 'Failed - Security Group not found'
 	  	 Return (-100)
 	   End
 End
/* Create property */
Select @Prop_Id = Prop_Id
  From Product_Properties
  Where Prop_Desc = @Prop_Desc
If @Prop_Id Is Null
  Begin
 	 Execute spEM_CreateProp @Prop_Desc,1,@User_Id,@Prop_Id OUTPUT
    If @Prop_Id Is Null
 	   Begin
 	  	 Select 'Failed - could not create property'
 	  	 Return (-100)
 	   End
  End
Execute spEM_PutSecurityProp @Prop_Id,@Group_Id,@User_Id
Execute spEM_PutExtLink @Prop_Id,'ao',@External_Link,'',0,@User_Id

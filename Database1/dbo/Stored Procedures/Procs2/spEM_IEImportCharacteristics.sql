CREATE PROCEDURE dbo.spEM_IEImportCharacteristics
@Prop_Desc  	  	 nvarchar(50),
@Char_Desc 	  	 nvarchar(50),
@Parent_Char_Desc 	 nvarchar(50),
@ExtInfo 	  	  	 nvarchar(255),
@ExtLink 	  	  	 nvarchar(255),
@User_Id  	  	 int,
@Trans_Id 	  	 Int
AS
Declare @Parent_Char_Id 	 int,
 	  	 @AS_Id 	  	  	 int,
 	  	 @Spec_Id 	  	 int,
 	  	 @Child_AS_Id 	 int,
 	  	 @Prop_Id  	  	 int,
 	  	 @Char_Id  	  	 int,
 	  	 @Approved_Date 	 DateTime,
 	  	 @Trans_Desc 	  	 nvarchar(50)
 	 
/* Initialization */
Select  	 @Prop_Id 	  	 = Null,
 	 @Char_Id 	  	 = Null,
 	 @Parent_Char_Id 	 = Null
/* Prepare Arguments */
Select  	 @Prop_Desc 	  	 = LTrim(RTrim(@Prop_Desc)),
 	  	 @Char_Desc 	  	 = LTrim(RTrim(@Char_Desc)),
 	  	 @Parent_Char_Desc 	 = LTrim(RTrim(@Parent_Char_Desc)),
 	  	 @ExtInfo 	 = ltrim(rtrim(@ExtInfo)),
 	  	 @ExtLink 	 = ltrim(rtrim(@ExtLink))
/* Validate Arguments */
If @Prop_Desc = '' or @Prop_Desc IS NULL
  BEGIN
     Select 'Failed - Must have a Product Property'
     RETURN (-100)
  END
If @Char_Desc = '' or @Char_Desc IS NULL
  BEGIN
     Select 'Failed - Must have a Characteristic Description'
     RETURN (-100)
  END
/*******************************************************************************************************************************************
* 	  	  	  	  	  	 Properties 	  	  	  	  	  	  	 *
********************************************************************************************************************************************/
/* Check to see if Property exists and if not then create it */
Select @Prop_Id = Prop_Id 
From Product_Properties
Where Prop_Desc = @Prop_Desc 
If @Prop_Id IS NULL 
  Begin
     Execute spEM_CreateProp  @Prop_Desc,1,@User_Id,@Prop_Id OUTPUT
  End
/* If non-existent and failed to create then rollback */
If @Prop_Id IS NULL 
  BEGIN
     Select 'Failed - Unable to create product property'
     RETURN(-100)
  END
/*******************************************************************************************************************************************
* 	  	  	  	  	  	 Parent Characteristics 	  	  	  	  	  	 *
********************************************************************************************************************************************/
If @Parent_Char_Desc <> '' And @Parent_Char_Desc Is Not Null
     Begin
     /* Check to see if Parent Characteristic exists and if not then create it */
     Select @Parent_Char_Id = Char_Id 
     From Characteristics
     Where Char_Desc = @Parent_Char_Desc and Prop_Id =  @Prop_Id
     If @Parent_Char_Id Is NULL 
 	  	   Execute spEM_CreateChar @Parent_Char_Desc,@Prop_Id,@User_Id,@Parent_Char_Id OUTPUT
     /* If non-existent and failed to create then rollback */
     If @Parent_Char_Id Is NULL 
       BEGIN
          Select 'Failed - Unable to create Parent Characteristic'
          RETURN(-100)
       END
     End
/*******************************************************************************************************************************************
* 	  	  	  	  	  	     Characteristics 	  	  	  	  	  	 *
********************************************************************************************************************************************/
/* Check to see if Characteristic exists and if not then create it */
Select @Char_Id = Char_Id 
From Characteristics
Where Char_Desc = @Char_Desc and Prop_Id =  @Prop_Id
If @Char_Id IS NULL 
 	 Execute spEM_CreateChar @Char_Desc,@Prop_Id,@User_Id,@Char_Id OUTPUT
If @Char_Id Is NULL 
  BEGIN
     Select 'Failed - Unable to create Characteristic'
     RETURN(-100)
  END
Else If @Parent_Char_Id Is Not Null 	 /* Update the characteristic with the parent characteristic */
     Begin
 	  	 Execute spEM_PutTransCharLinks @Trans_Id,@Char_Id,@Parent_Char_Id,@User_Id
     End
Execute spEM_PutExtLink @Char_Id,'aq',@ExtLink,@ExtInfo,Null,@User_Id
RETURN(0)

CREATE PROCEDURE dbo.spEM_IEImportProductGroups
@Product_Grp_Desc 	 nVarChar(100),
@Prod_Code 	  	 nVarChar(100),
@Comment 	  	 nvarchar(255),
@User_Id 	  	 int
As
Declare @Product_Grp_Id int,
 	  	 @Prod_Id  	  	 int,
 	  	 @PGD_Id 	  	  	 int,
 	  	 @Comment_Id 	  	 Int
/* Initialization */
Select 	 @Product_Grp_Id 	 = Null,
 	 @Prod_Id  	  	 = Null,
 	 @PGD_Id  	  	 = Null
Select @Product_Grp_Desc =  LTrim(RTrim(@Product_Grp_Desc))
Select @Prod_Code =  LTrim(RTrim(@Prod_Code))
Select @Comment = Ltrim(Rtrim(@Comment))
If @Product_Grp_Desc = '' or @Product_Grp_Desc IS NULL 
    BEGIN
      Select 'Failed - missing product group description' 
      Return(-100)
    END
If @Prod_Code = '' or @Prod_Code IS NULL 
    BEGIN
      Select 'Failed - missing product code description' 
      Return(-100)
    END
/* Get Prod_Id */
Select @Prod_Id = Prod_Id
From Products
Where Prod_Code = @Prod_Code
If @Prod_Id Is Null
    BEGIN
      Select 'Failed - invalid product code description'
      Return(-100)
    END
/* Get PL_Id  */
Select @Product_Grp_Id = Product_Grp_Id
From Product_Groups
Where Product_Grp_Desc = @Product_Grp_Desc
If @Product_Grp_Id Is Null
 	 Execute spEM_CreateProdGroup  @Product_Grp_Desc,@User_Id,@Product_Grp_Id OUTPUT
If @Product_Grp_Id Is Not Null
   Begin
     Select @PGD_Id = PGD_Id
     From Product_Group_Data
     Where Prod_Id = @Prod_Id And Product_Grp_Id = @Product_Grp_Id
     If @PGD_Id Is Null
     Begin
 	  	 Execute spEM_CreateProdGroupData @Product_Grp_Id,@Prod_Id,@User_Id,@PGD_Id   OUTPUT
 	  	 If @PGD_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - could not create group data'
       	  	 Return(-100)
 	  	   End
     End
   End
Else
   Begin
     Select 'Failed - could not create group'
     Return(-100)
   End
-- Product Comments
If @Comment <> '' and @Comment IS NOT NULL 
  Begin
    -- If the product already has a comment, update it. 
    Select @Comment_Id from Product_Groups
 	 Where Product_Grp_Id = @Product_Grp_Id
    If @Comment_Id IS NULL 
      BEGIN
  	  	 Execute spEM_CreateComment @Product_Grp_Id,'al',@User_Id,3,@Comment_Id OUTPUT
 	   End
 	 If @Comment_Id is not Null
 	  Begin
        Update Comments Set Comment = @Comment Where Comment_Id = @Comment_Id
        Update Comments Set Comment_Text = @Comment Where Comment_Id = @Comment_Id
      End
    Else
 	   Begin
        Select 'Failed - Could not create Comment for product group'
        RETURN (-100)
      End
  End
Return(0)
select * from comments

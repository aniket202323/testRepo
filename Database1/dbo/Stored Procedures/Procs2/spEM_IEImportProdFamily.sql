CREATE PROCEDURE dbo.spEM_IEImportProdFamily
@Prod_Code  	  	 nVarChar(100),
@Prod_Desc  	  	 nVarChar(100),
@Comment1  	  	 nvarchar(1000),
@Product_Family_Desc  	 nVarChar(100),
@Comment2  	  	 nvarchar(1000), 	 
@EventEsigLevel 	  	 nvarchar(50),
@ProductEsigLevel 	 nvarchar(50),
@IsSerialized BIT,
@User_Id int
AS
Declare 
  @PU_Id int,
  @Product_Family_Id int,
  @Prod_Id int,
  @Comment_Id 	 Int,
  @iESigLevel 	 Int,
  @iPSigLevel 	 Int
Select @Product_Family_Desc = LTrim(RTrim(@Product_Family_Desc))
Select @Comment1 = LTrim(RTrim(@Comment1))
Select @Comment2 = LTrim(RTrim(@Comment2))
Select @EventEsigLevel = LTrim(RTrim(@EventEsigLevel))
Select @ProductEsigLevel = LTrim(RTrim(@ProductEsigLevel))
Select @Prod_Id = Null
Select @Product_Family_Id = Null
Select @Comment_Id = Null
If @EventEsigLevel = '' 	  	 Select @EventEsigLevel = Null
If @ProductEsigLevel = '' 	 Select @ProductEsigLevel = Null
IF ISNULL(@Product_Family_Desc,'') =''
Begin
 	 Select 'Failed - Product family is not provided'
 	 RETURN (-100)
END
If  @EventEsigLevel Is null
 	 Select @iESigLevel = 0
ELSE
BEGIN
 	 Select @iESigLevel = Case @EventEsigLevel When 'User Level' Then 1
 	  	  	  	  	  	  	 When 'Approver Level' Then 2
 	  	  	  	  	  	  	 When 'Undefined' 	 Then 0
 	  	  	  	  	  	  	 Else -2
 	  	  	  	  	  	  End
 	 If @iESigLevel = -2 
 	 BEGIN
 	  	 Select 'Failed - Event ESignature is not correct'
 	  	 RETURN (-100)
 	 END
END
If  @ProductEsigLevel Is null
 	 Select @iPSigLevel = Null
ELSE
BEGIN
 	 Select @iPSigLevel = Case @ProductEsigLevel When 'User Level' Then 1
 	  	  	  	  	  	  	 When 'Approver Level' Then 2
 	  	  	  	  	  	  	 When 'Undefined' 	 Then 0
 	  	  	  	  	  	  	 Else -2
 	  	  	  	  	  	  End
 	 If @iPSigLevel = -2 
 	 BEGIN
 	  	 Select 'Failed - Event ESignature is not correct'
 	  	 RETURN (-100)
 	 END
END
Select @Prod_Id = Prod_Id from Products 
 	 where Prod_Code = @Prod_Code
If @Prod_Id IS NOT NULL
    BEGIN
      Select 'Failed - Product code already exists'
      RETURN (-100)
    END
Select @Prod_Id = Prod_Id from Products 
 	 where Prod_Desc = @Prod_Desc
If @Prod_Id IS NOT NULL and 1=0
    BEGIN
      Select 'Failed - Product description already exists'
      RETURN (-100)
    END
If @Product_Family_Desc <> '' and @Product_Family_Desc IS NOT NULL
  BEGIN
    -- Add the product family if it doesn't exist
    Select @Product_Family_Id = NULL
    Select @Product_Family_Id = Product_Family_Id 
      From Product_Family
      Where Product_Family_Desc = @Product_Family_Desc
    If @Product_Family_Id IS NULL 
      BEGIN
 	  	 Execute spEM_CreateProductFamily @Product_Family_Desc,@User_Id,@Product_Family_Id OUTPUT
        If @Product_Family_Id IS NULL
          BEGIN
       	  	 Select 'Failed - Could not create product family'
       	  	 RETURN (-100)
          END
      END
   End
   Execute spEM_CreateProd  @Prod_Desc = @Prod_Desc,@Prod_Code = @Prod_Code,@Prod_Family_Id = @Product_Family_Id,@User_Id=@User_Id,@Serialized = @IsSerialized,@Prod_Id = @Prod_Id OUTPUT
   If @Prod_Id IS NULL
    BEGIN
      Select 'Failed - Could not create product'
      RETURN (-100)
    END
Execute spEM_PutProductProperties  @Prod_Id=@Prod_Id,@EventLevel = @iESigLevel,@ProductLevel = @iPSigLevel,@User_Id = @User_Id,@Serialized = @IsSerialized
-- Product Comments
If @Comment1 <> '' and @Comment1 IS NOT NULL 
  Begin
    -- If the product already has a comment, update it. 
    Select @Comment_Id = Comment_id from Products 
 	 Where Prod_Id = @Prod_Id
    If @Comment_Id IS NULL 
      BEGIN
  	  	 Execute spEM_CreateComment @Prod_Id,'aj',@User_Id,3,@Comment_Id OUTPUT
 	   End
 	 If @Comment_Id is not Null
 	  Begin
        Update Comments Set Comment = @Comment1 Where Comment_Id = @Comment_Id
        Update Comments Set Comment_Text = @Comment1 Where Comment_Id = @Comment_Id
      End
    Else
 	   Begin
        Select 'Failed - Could not create Comment for product'
        RETURN (-100)
      End
  End
If @Comment2 <> '' and @Comment2 IS NOT NULL 
  Begin
 	 Select @Comment_Id = Null
    -- If the product Family  already has a comment, update it. 
    Select @Comment_Id = Comment_id from Product_Family
 	  	 Where Product_Family_Id = @Product_Family_Id
    If @Comment_Id IS NULL 
      BEGIN
  	  	 Execute spEM_CreateComment @Product_Family_Id,'cn',@User_Id,3,@Comment_Id OUTPUT
 	   End
 	 If @Comment_Id is not Null
 	  Begin
        Update Comments Set Comment = @Comment2 Where Comment_Id = @Comment_Id
        Update Comments Set Comment_Text = @Comment2 Where Comment_Id = @Comment_Id
      End
    Else
 	   Begin
        Select 'Failed - Could not create Comment for product family'
        RETURN (-100)
     END
  END
RETURN(0)

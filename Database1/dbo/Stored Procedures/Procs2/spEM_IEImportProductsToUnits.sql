CREATE PROCEDURE dbo.spEM_IEImportProductsToUnits
@PL_Desc  	  	 nvarchar(50),
@PU_Desc  	  	 nvarchar(50),
@Prod_Code  	  	 nvarchar(25),
@Prod_Code_Xref nvarchar(255),
@User_Id  	  	 int,
@Trans_Id 	  	 Int
AS
Declare @Count  	  	  	 int,
 	  	 @Master_Unit 	 int,
 	  	 @PU_Id  	  	  	 int,
 	  	 @Prod_Id  	  	 int,
 	  	 @PLId 	  	  	 Int
-- Initialization
Select @PL_Desc = LTrim(RTrim(@PL_Desc))
Select @PU_Desc = LTrim(RTrim(@PU_Desc))
Select @Prod_Code = LTrim(RTrim(@Prod_Code))
Select @Prod_Code_Xref = LTrim(RTrim(@Prod_Code_Xref))
If @Prod_Code_Xref = '' or @Prod_Code_Xref IS NULL 
 	 Select @Prod_Code_Xref = Null
Select @Master_Unit = Null,@PU_Id = Null,@PLId = Null
Select @PLId = PL_Id from Prod_Lines where PL_Desc = @PL_Desc
If @PLId Is NUll
 Begin 
    Select 'Failed - Production Line Not Found'
    RETURN (-100)
 End
Select @PU_Id = PU_Id, @Master_Unit = Master_Unit
  From Prod_Units 
  Where PU_Desc = @PU_Desc and PL_Id = @PLId
If @PU_Id Is NULL
  BEGIN
    Select 'Failed - Production Unit Not Found'
    RETURN (-100)
  END
If @Master_Unit Is Not Null
  BEGIN
    Select 'Failed - Production Unit must be a master unit'
    RETURN (-100)
  END
Select @Prod_Id = Null
Select @Prod_Id = Prod_Id 
  From Products
  Where Prod_Code = @Prod_Code 
If @Prod_Id IS Null 
  BEGIN
    Select 'Failed - Product Code not found'
    RETURN (-100)
  END
If @Prod_Id = 1
  BEGIN
    Select 'Failed - <None> is not a valid Product Code for import'
    RETURN (-100)  
  END
Select @Count = Count(*) from PU_Products 
 	 Where PU_Id = @PU_Id and Prod_Id = @Prod_Id
---------------------------------------------------------------
-- Changed following so that Prod_Code_Xref always updated.
---------------------------------------------------------------
If @Count = 0 
  BEGIN
    Execute spEM_PutTransProduct  @Trans_Id,@Prod_Id, @PU_Id,0, @User_Id 
  END
-- Insert Prod_Code_Xref
If @Prod_Code_Xref Is Not Null
 	 Execute spEM_PutProductXRef  @Prod_Id, @PU_Id, @Prod_Code_Xref, @User_Id
RETURN(0)

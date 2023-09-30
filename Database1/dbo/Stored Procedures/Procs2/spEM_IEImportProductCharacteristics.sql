CREATE PROCEDURE dbo.spEM_IEImportProductCharacteristics
@PL_Desc nvarchar(50),
@PU_Desc nvarchar(50),
@Prod_Code nvarchar(25),
@Prop_Desc nvarchar(50),
@Char_Desc nvarchar(50),
@User_Id int,
@Trans_Id int 
AS
Declare 	 @Old_Char_Id 	 int,
 	  	 @RetCode  	  	 int,
 	  	 @Master_Unit  	 int,
 	  	 @Return_Code 	 int,
 	  	 @Var_Id 	  	  	 int,
 	  	 @Spec_Id 	  	 int,
 	  	 @Effective_Date 	 datetime,
 	  	 @PU_Id  	  	  	 int,
 	  	 @PL_Id  	  	  	 int,
 	  	 @Prod_Id  	  	 int,
 	  	 @Prop_Id  	  	 int,
 	  	 @Char_Id  	  	 int
Select 	 @PL_Desc = Ltrim(Rtrim(@PL_Desc)),
 	  	 @PU_Desc = Ltrim(Rtrim(@PU_Desc)),
 	  	 @Prod_Code = Ltrim(Rtrim(@Prod_Code)),
 	  	 @Prop_Desc = Ltrim(Rtrim(@Prop_Desc)),
 	  	 @Char_Desc = Ltrim(Rtrim(@Char_Desc))
Select @PL_Id = PL_Id
 	 From Prod_Lines where PL_Desc = @PL_Desc
If @PL_Id is null
  Begin
 	 select 'Failed - Production Line not found'
 	 return (-100)
  End
Select @PU_Id = Null
Select @PU_Id = PU_Id, @Master_Unit = Master_Unit
  From Prod_Units 
  Where PU_Desc = @PU_Desc and PL_Id = @PL_Id
If @PU_Id IS NULL
  BEGIN
 	 select 'Failed - Production Unit not found'
 	 return (-100)
  END
If @Master_Unit Is Not Null
  BEGIN
 	 select 'Failed - Production Unit must be a Master Unit'
 	 return (-100)
  END
Select @Prod_Id = Null
Select @Prod_Id = Prod_Id 
  From Products
  Where Prod_Code = @Prod_Code 
If @Prod_Id IS NULL
  BEGIN
  	 select 'Failed - Product Code not found'
 	 return (-100)
  END
If (Select Count(*) from PU_Products Where PU_Id = @PU_Id and Prod_Id = @Prod_Id) = 0
  BEGIN
  	 select 'Failed - Product Code not active on unit'
 	 return (-100)
  END
Select @Prop_Id = Null 
Select @Prop_Id = Prop_Id 
 	 from Product_Properties
 	 where Prop_Desc = @Prop_Desc 
If @Prop_Id IS NULL
  BEGIN
  	 select 'Failed - Product Property not found'
 	 return (-100)
  END
Select @Char_Id = Null 
Select @Char_Id = Char_Id 
 	 from Characteristics
 	 where Char_Desc = @Char_Desc And Prop_Id = @Prop_Id
If @Char_Id IS NULL
  BEGIN
  	 select 'Failed - Characteristic not found'
 	 return (-100)
  END
SELECT @Old_Char_Id = Char_Id FROM PU_Characteristics
    WHERE (Prod_Id = @Prod_Id) AND (PU_Id = @PU_Id) AND (Prop_Id = @Prop_Id)
--
-- Check if the record already exists in the same state.
--
If @Old_Char_Id = @Char_Id
  BEGIN
  	 select 'Failed - Characteristic association already exists'
 	 return (-100)
  END
Execute spEM_PutTransCharacteristics @Trans_Id,@PU_Id,@Prod_Id,@Prop_Id,@Char_Id,@User_Id
RETURN(0)

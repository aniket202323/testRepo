Create Procedure dbo.spRC_LookupSpecification 
@PU_Id int,
@SpecificationId int,
@ProductId int,
@SpecificationValue real OUTPUT
AS
/*
Declare @Char_Id int
Declare @Property_Id int
Select @SpecificationValue = NULL
Select @Property_Id = Prop_Id
  From Specifications
  Where Spec_Id = @SpecificationId
Select @Char_Id = Char_Id
  From PU_Characteristics
  Where PU_Id = @PU_Id and
        Prod_id = @ProductId and 
        Prop_Id = @Property_Id
If @Char_Id Is Not Null
  Select @SpecificationValue = convert(real, target)
    From Active_Specs
    Where Spec_Id = @SpecificationId and
          Char_Id = @Char_Id and
          Expiration_Date Is Null
*/
--EU (Legacy) For Those Still Using Variable Ids, Find Spec By Variable Id
--If @SpecificationValue Is Null
  Select @SpecificationValue = convert(real, target)
    From Var_Specs
    Where Var_Id = @SpecificationId and
          Prod_Id = @ProductId and
          Expiration_Date Is Null

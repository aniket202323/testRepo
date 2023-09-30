CREATE PROCEDURE dbo.spEM_GetUnitCharacteristics
  @PU_Id int,
  @Prop_Id Int,
  @Trans_Id int
  AS
  --
  -- Get valid product ids for this production unit.
  --
-- SELECT Prod_Id FROM PU_Products WHERE PU_Id = @PU_Id
  --
  -- Get valid characteristic ids for this production unit.
  --
Create Table #Products(Prod_Id int)
Insert into #Products
  SELECT p.Prod_Id 
 	  From PU_Products p
 	  Where p.PU_Id = @PU_Id and p.prod_Id not in(Select Prod_Id From  PU_Characteristics Where PU_Id = @PU_Id and  Prop_Id = @Prop_Id)
 	      And p.PU_Id  = @PU_Id and p.prod_Id not in(Select Prod_Id From  Trans_Characteristics Where PU_Id = @PU_Id and  Prop_Id = @Prop_Id and Trans_Id = @Trans_Id)
Insert into #Products
  SELECT t.Prod_Id 
 	  From Trans_Products t
 	  Where t.PU_Id = @PU_Id and t.Trans_Id = @Trans_Id and t.prod_Id not in(Select Prod_Id From  PU_Characteristics Where PU_Id = @PU_Id and  Prop_Id = @Prop_Id)
 	      And t.PU_Id  = @PU_Id and t.Trans_Id = @Trans_Id and t.prod_Id not in(Select Prod_Id From  Trans_Characteristics Where PU_Id = @PU_Id and  Prop_Id = @Prop_Id and Trans_Id = @Trans_Id)
select  * from #Products

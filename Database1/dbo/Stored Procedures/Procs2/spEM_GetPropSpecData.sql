CREATE PROCEDURE dbo.spEM_GetPropSpecData
  @Prop_Id int
  AS
  SELECT distinct Product_Family_Id 
 	 FROM pu_Characteristics  pu
 	 Join Products p On p.Prod_Id = pu.Prod_Id 
 	 WHERE Prop_Id = @Prop_Id
  SELECT Char_Id,Exception_Type 
 	 FROM Characteristics 
 	 WHERE Prop_Id = @Prop_Id and Characteristic_Type IS NULL
  --
  -- Get the specifications.
  --
  SELECT Spec_Id,Parent_Id FROM Specifications WHERE  Prop_Id = @Prop_Id ORDER BY Spec_Order
  --
  --
  -- Get The variables
  --
  Select Var_Id,Spec_Id,PUG_Id,PU_Id,IsChild = Case When  PVar_Id is NUll Then 0 Else 1 End
 	  from Variables where Spec_Id in (  SELECT Spec_Id FROM Specifications WHERE  Prop_Id = @Prop_Id )

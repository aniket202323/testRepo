CREATE PROCEDURE dbo.spEM_GetGroupSpecData
  @PUG_Id int,
  @TransId int
  AS
  --
  DECLARE @Master_PU_Id  int,
 	       @PU_Id         int  
  --
  -- Find the master unit for this Group
  --
  SELECT @PU_Id = PU_ID FROM PU_Groups WHERE PUG_Id = @PUG_Id
  SELECT @Master_PU_Id = Master_Unit FROM Prod_Units WHERE PU_Id = @PU_Id
  IF @Master_PU_Id IS NULL SELECT @Master_PU_Id = PU_ID FROM Prod_Units WHERE PU_Id = @PU_Id
  --
  -- Get the valid products for this production unit.
  --
   Create Table #Prods(Prod_Id int,Product_Family_Id int)
   Insert  InTo #Prods
     Select  pu.Prod_Id,Product_Family_Id
      From PU_Products pu
      Join Products p on p.Prod_Id = pu.Prod_Id
      Where PU_Id = @Master_PU_Id 
   Insert  InTo #Prods
     Select  t.Prod_Id,Product_Family_Id  
     From  Trans_Products t
     Join Products p on p.Prod_Id = t.Prod_Id
      Where PU_Id = @Master_PU_Id  and Trans_Id = @TransId and Is_Delete = 0
   Delete From  #Prods
 	 Where Prod_Id in (Select  Prod_Id  From  Trans_Products
      Where PU_Id = @Master_PU_Id  and Trans_Id = @TransId and Is_Delete = 1)
  Select Distinct Prod_Id,Product_Family_Id From #Prods
  Drop Table #Prods
  --
  -- Get the variables for this production unit
  --
    Create Table #Variables(Var_Id Int,Spec_Id Int,PVar_Id Int,PUG_Order Int)
 	 Insert Into #Variables(Var_Id,Spec_Id,PVar_Id,PUG_Order) 
 	  	 Select  Var_Id,Spec_Id,PVar_Id,PUG_Order
 	  	 From Variables
 	  	 Where PUG_Id = @PUG_Id AND ((PVar_Id is null) or (SPC_Group_Variable_Type_Id is not Null)) and sa_Id <> 0
     Delete From #Variables
 	  	 From  #Variables v
 	  	   Join Specifications s on s.Spec_Id = v.Spec_Id
 	  	   Join Product_Properties pp on pp.prop_Id = s.prop_Id and Property_Type_Id <> 1
 	 
  SELECT *
 	 FROM #Variables order by PUG_Order
-- change for all units
  SELECT Distinct s.Prop_Id
 	 From Specifications s
 	 Join Variables v on v.spec_Id  = s.spec_Id
 	 Join Prod_units p on p.Pu_Id = v.pu_Id
 	 Join Product_Properties pp On pp.Prop_Id = s.Prop_Id and pp.Property_Type_Id = 1
 	 Where v.pU_Id = @Master_PU_Id or p.Master_Unit = @Master_PU_Id
--  SELECT Distinct Prop_Id From Specifications Where spec_id IN    (Select DISTINCT Spec_Id FROM Variables WHERE  PUG_Id = @PUG_Id)

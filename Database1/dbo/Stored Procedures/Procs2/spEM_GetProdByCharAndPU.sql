CREATE PROCEDURE dbo.spEM_GetProdByCharAndPU
  @PU_Id int,
  @Char_Id int
  AS
  --
  DECLARE @Master_PU_Id  int,
 	       @Prop_Id     int
select @Prop_Id = Prop_Id from characteristics where Char_Id = @Char_Id
  --
  -- Find the master unit
  --
  SELECT @Master_PU_Id = Master_Unit FROM Prod_Units WHERE PU_Id = @PU_Id
  IF @Master_PU_Id IS NULL SELECT @Master_PU_Id = PU_ID FROM Prod_Units WHERE PU_Id = @PU_Id
  --
  -- Get the valid products for this production unit.
  --
     Create Table  #Prods(Prod_Id Int)
     Insert into #Prods
 	 SELECT   Prod_Id
 	  	 FROM  Pu_Characteristics pc
 	  	 WHERE PU_Id = @Master_PU_Id And Char_Id = @Char_Id and Prop_Id = @Prop_Id
     Insert into #Prods
 	 SELECT   Prod_Id
 	  	 FROM  Trans_Characteristics pc
 	  	 WHERE PU_Id = @Master_PU_Id And Char_Id = @Char_Id and Prop_Id = @Prop_Id
Select Distinct Prod_Id From #Prods
Drop Table #Prods

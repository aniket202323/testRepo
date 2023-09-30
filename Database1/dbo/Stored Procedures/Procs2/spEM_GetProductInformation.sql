CREATE PROCEDURE dbo.spEM_GetProductInformation 
   @ProdId int,
   @TransId Int
AS
DECLARE @UseSOAClient Int
SELECT @UseSOAClient = value
 	 From Site_Parameters 
 	 Where Parm_Id = 87
 	 
SET @UseSOAClient = coalesce(@UseSOAClient,1)
 	 
/* Default Product Properties */
  SELECT pp.Prop_Id,pc.Char_Id,pp.Prop_Desc,c.Char_Desc
 	 From Product_Properties pp
 	 Left Join Product_Characteristic_Defaults pc on pc.Prop_Id = pp.Prop_Id and pc.Prod_Id = @ProdId
 	 Left Join Characteristics c on pc.Char_Id = c.Char_Id
 	 Order By pp.Prop_Desc
/* Current PU_Characteristics */
Declare @PUId Int,@PropId Int,@CharId Int
  Create Table #PU (PU_Id Int)
  Insert INto #PU
  SELECT p.PU_Id
  	 From PU_Products p
 	 Join prod_Units pu on pu.pu_Id = p.pu_Id and pu.Master_Unit Is Null
 	 Where Prod_Id = @ProdId 
 	 and p.PU_Id <> 0
    Insert InTo #PU Select PU_Id 
 	  	     From Trans_Products 
 	  	     Where Trans_Id = @TransId And Prod_Id = @ProdId and Is_Delete = 0
    Delete From #PU 
     Where PU_Id in (Select PU_Id 
 	  	     From Trans_Products 
 	  	     Where Trans_Id = @TransId And Prod_Id = @ProdId and Is_Delete = 1)
   Create Table #Results (PU_Id INT,Prop_Id Int,Char_Id int)
   Insert into #Results
    Select Distinct pu.PU_Id, pc.Prop_Id,pc.Char_Id
     From #PU  pu
     left Join PU_Characteristics pc on pc.PU_Id = pu.PU_Id And pc.prod_Id = @ProdId
Declare Tc Cursor For
  Select PU_Id, Prop_Id,Char_Id
    From Trans_Characteristics 
    Where Trans_Id = @TransId And Prod_Id = @ProdId
Open Tc
FetchNextTc:
Fetch Next From Tc Into @PUId,@PropId,@CharId  
If @@Fetch_Status = 0
  Begin
   IF (Select Count(*) From #Results Where PU_Id = @PUId and Prop_Id = @PropId) > 0
     Begin
 	 Update #Results set Char_Id = @CharId
 	   Where Prop_Id = @PropId and PU_Id = @PUId
     End
   Else
     Begin
       Insert Into #Results (PU_Id,Prop_Id,Char_Id) Values (@PUId,@PropId,@CharId)
     End
    GoTo FetchNextTc
   End
Close Tc
Deallocate Tc
IF @UseSOAClient = 1
BEGIN
 	 Select r.PU_Id,r.Prop_Id,r.Char_Id,c.Char_Desc
 	  	  	  From #Results r
 	  	  	  Left Join Characteristics c on r.Char_Id = c.Char_Id
 	  	  	  Order By r.PU_Id,r.Prop_Id
  SELECT PU_Id
     From Prod_Units
 	 Where PU_Id Not In (SELECT PU_Id From #PU) and PU_Id <> 0 and Master_Unit is Null
END
ELSE
BEGIN
 	 Select r.PU_Id,r.Prop_Id,r.Char_Id,c.Char_Desc
 	  	  	  From #Results r
 	  	  	  Left Join Characteristics c on r.Char_Id = c.Char_Id
 	  	  	  WHERE r.PU_Id > 0
 	  	  	  Order By r.PU_Id,r.Prop_Id
  SELECT PU_Id
     From Prod_Units
 	 Where PU_Id Not In (SELECT PU_Id From #PU) and PU_Id > 0 and Master_Unit is Null
END
Select (Select isSerialized from Product_Serialized  where product_id = A.Prod_Id) isSerialized,Case when exists(Select 1 from Production_Starts Where Prod_Id = A.Prod_Id) OR Exists(Select 1 from Events where Applied_Product = A.Prod_Id) Then 1 Else 0 End IsProduced 
from Products A where Prod_id = @ProdId
Drop Table #Results
Drop Table #PU

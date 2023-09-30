Create Procedure dbo.spSS_ProductsGetInitial
@ProductFamilies int
AS
 Declare @Any nVarChar(25)
 Select @Any = '<Any>'
-------------------------------------------------------
-- Product Families
-------------------------------------------------------
Create Table #Temp (Key_Id Int Null, Key_Desc nVarChar(50) Null)
If @ProductFamilies = 0
  Begin
    Insert Into #Temp
      Select Product_Grp_Id, Product_Grp_Desc
        From Product_Groups
         Where Product_Grp_Id<>0
  End
Else
  Insert Into #Temp
    Select Product_Family_Id, Product_Family_Desc
      From Product_Family
       Where Product_Family_Id <> 0
 Insert Into #Temp (Key_Id, Key_Desc) 
  Values (0, @Any)
 Select Key_Id, Key_Desc 
  From #Temp
   Order by Key_Desc
 Drop Table #Temp

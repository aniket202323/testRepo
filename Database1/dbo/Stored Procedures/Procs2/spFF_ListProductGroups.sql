Create Procedure dbo.spFF_ListProductGroups      
@PU_Id int = NULL
AS
If @PU_Id Is Null
  Begin
    SELECT Product_Grp_Id, Product_Grp_Desc FROM Product_Groups
    ORDER By Product_Grp_Desc
  End
Else
  Begin
    SELECT Distinct pg.Product_Grp_Id, pg.Product_Grp_Desc 
      FROM PU_Products pu
      Join Product_Group_Data pgd on pgd.Prod_Id = pu.Prod_Id 
      Join Product_Groups pg on pg.Product_Grp_Id = pgd.Product_Grp_Id
      Where pu.PU_Id = @PU_Id
      ORDER By pg.Product_Grp_Desc
  End

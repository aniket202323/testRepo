CREATE Procedure dbo.spGE_GetValidProductGroups
@PU_Id int
AS
set nocount on
Create Table #PG ([Key] Int,[Description] nvarchar(50))
Insert Into #PG ([Key],[Description]) Values (-1,'All')
Insert Into #PG ([Key],[Description])
Select pgd.Product_Grp_Id,pg.Product_Grp_Desc
  From Product_Group_Data pgd
   Join PU_Products pu on pgd.Prod_Id = pu.Prod_Id
   Join Products p On p.Prod_Id = pu.Prod_Id
   Join Product_Groups pg on pg.Product_Grp_Id = pgd.Product_Grp_Id
   Where pu.PU_Id = @PU_Id
Select distinct [Key],[Description] from #PG
Drop table #PG
set nocount off

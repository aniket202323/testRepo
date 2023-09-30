Create Procedure dbo.spSPC_ListChildUnits
@Unit int
AS
select Id = PU_Id, Description = PU_Desc
  From Prod_Units
  Where PU_Id = @Unit or Master_Unit = @Unit
  Order By PU_Desc

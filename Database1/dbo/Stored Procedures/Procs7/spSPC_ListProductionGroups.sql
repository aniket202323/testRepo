Create Procedure dbo.spSPC_ListProductionGroups
@Unit int
AS
select Id = PUG_Id, Description = PUG_Desc
  From PU_Groups
  Where PU_Id = @Unit
  Order By PUG_Desc

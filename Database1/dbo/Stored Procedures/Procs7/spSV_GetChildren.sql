CREATE Procedure dbo.spSV_GetChildren
@PP_Id int
AS
Select PP_Id
From Production_Plan
Where Parent_PP_Id = @PP_Id
Order By PP_Id

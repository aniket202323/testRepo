CREATE Procedure dbo.spSV_GetSheetName
@Path_Id int,
@Sheet_Desc nvarchar(50) OUTPUT
AS
Select @Sheet_Desc = NULL
Select @Sheet_Desc = s.Sheet_Desc
  From Sheets s
  Join Sheet_Paths sp on sp.Sheet_Id = s.Sheet_Id
  Where sp.Path_Id = @Path_Id
  And s.Sheet_Type = 17
  And (Select Count(*) From Sheet_Paths Where Sheet_Id = s.Sheet_Id) = 1

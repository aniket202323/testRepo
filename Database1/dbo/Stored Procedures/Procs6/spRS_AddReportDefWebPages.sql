CREATE PROCEDURE dbo.spRS_AddReportDefWebPages
@Report_Id int,
@RWP_Id int,
@PageOrder int
 AS
Declare @Exists int
Select @Exists = RDW_Id
  From Report_Def_WebPages
  Where Report_Def_Id = @Report_Id
  and RWP_Id = @RWP_Id
If @Exists Is Null  -- Add a new row
  Begin
    Insert Into Report_Def_WebPages(Report_def_Id, RWP_Id, Page_Order)
    Values(@Report_Id, @RWP_Id, @PageOrder)
    Return (1)
  End
Else -- update an existing row
  Begin
    Update Report_Def_WebPages
    Set Page_Order = @PageOrder
    Where RDW_Id = @Exists
    Return (2)
  End

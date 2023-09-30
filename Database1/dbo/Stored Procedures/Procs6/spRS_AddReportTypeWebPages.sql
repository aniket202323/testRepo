/* This Stored Procedure used by Report Server V2 */
CREATE PROCEDURE dbo.spRS_AddReportTypeWebPages
@ReportTypeId int, 
@ReportWebPageID int,
@PageOrder int
 AS
Declare @PageExists int
Select @PageExists = RTW_Id
From report_type_webpages
Where Report_Type_Id = @ReportTypeId
and RWP_Id = @ReportWebPageId
If @PageExists Is Null
  Begin
    Insert Into Report_Type_WebPages(Report_Type_Id, RWP_Id, Page_Order)
    Values(@ReportTypeId, @ReportWebPageId, @PageOrder)
    Return (1)  -- New Item Entry
  End
Else
  Begin
    Update Report_Type_WebPages
    Set Page_Order = @PageOrder
    Where RTW_Id = @PageExists
    Return (2)  -- Update
  End

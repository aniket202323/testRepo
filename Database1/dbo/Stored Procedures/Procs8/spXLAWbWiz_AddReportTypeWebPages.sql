/* This Stored Procedure used by Report Server V2 */
CREATE PROCEDURE dbo.spXLAWbWiz_AddReportTypeWebPages
 	   @Report_Type_Id    Int
 	 , @RWP_Id            Int
 	 , @Page_Order        Int
AS
DECLARE @Existing_RTW_Id    Int
DECLARE @ReturnStatus       Int
DECLARE @ReturnStatusInsert TinyInt
DECLARE @ReturnStatusUpdate TinyInt
--Define Return Status
SELECT @ReturnStatusInsert = 1
SELECT @ReturnStatusUpdate = 2
SELECT @ReturnStatus = -1 --Initialize
--Check if this webpage already exists
SELECT @Existing_RTW_Id = RTW_Id FROM Report_Type_Webpages WHERE Report_Type_Id = @Report_Type_Id AND RWP_Id = @RWP_Id
If @Existing_RTW_Id Is NULL
  BEGIN
    INSERT INTO Report_Type_WebPages(Report_Type_Id, RWP_Id, Page_Order) VALUES(@Report_Type_Id, @RWP_Id, @Page_Order)
    SELECT @ReturnStatus = @ReturnStatusInsert
  END
Else
  BEGIN
    UPDATE Report_Type_WebPages SET Page_Order = @Page_Order WHERE RTW_Id = @Existing_RTW_Id
    SELECT @ReturnStatus = @ReturnStatusUpdate
  END
--EndIf
SELECT [ReturnStatus] = @ReturnStatus

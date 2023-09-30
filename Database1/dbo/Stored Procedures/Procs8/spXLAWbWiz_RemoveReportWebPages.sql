/* This Stored Procedure used by Report Server V2 */
CREATE PROCEDURE dbo.spXLAWbWiz_RemoveReportWebPages
 	   @Report_Type_Id    Int
 	 , @ReturnStatus      Int OUTPUT
AS
SELECT @ReturnStatus = 0 --Initialize
DELETE FROM Report_Type_WebPages WHERE Report_Type_Id = @Report_Type_Id
SELECT @ReturnStatus = @@Error

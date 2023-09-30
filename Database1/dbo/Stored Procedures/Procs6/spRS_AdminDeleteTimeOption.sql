CREATE   PROCEDURE [dbo].[spRS_AdminDeleteTimeOption] 
@RRD_Id int
AS
Delete From Report_Relative_dates Where RRD_ID = @RRD_Id

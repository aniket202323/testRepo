CREATE PROCEDURE [dbo].[spRS_GetSiteParameters]
 AS
-----------------------
-- DECLARE LOCAL VARS
-----------------------
Declare @FTPUid varchar(50) --52
Declare @FTPPW  varchar(50) --53
Declare @FTPSiteName varchar(50) --55
Declare @RSName varchar(50) --56
Declare @AvailableReportingDays varchar(50)--57
Declare @PDFEngineRestartMinutes int
-----------------------------------------
-- INIT VARS FROM SITE_PARAMETERS TABLE
-- REPORT SERVER USES PARM_ID's 50 - 59
-----------------------------------------
Select @FTPUID = Value From Site_Parameters where Parm_Id = 52
Select @FTPPW = Value From Site_Parameters where Parm_Id = 53
Select @FTPSiteName = Value From Site_Parameters where Parm_Id = 55
Select @RSName = Value From Site_Parameters where Parm_Id = 56
Select @AvailableReportingDays = Value From Site_Parameters where Parm_Id = 57
Select @PDFEngineRestartMinutes = value from Site_Parameters where Parm_Id = 319
if @PDFEngineRestartMinutes is null 
 	 select @PDFEngineRestartMinutes = 60
Select @FTPUID 'FtpUID', @FTPPW 'FtpPW', @FTPSiteName 'FTPSiteName', @RSName 'RSName', @AvailableReportingDays 'AvailableReportingDays', @PDFEngineRestartMinutes 'PDFEngineRestartMinutes'

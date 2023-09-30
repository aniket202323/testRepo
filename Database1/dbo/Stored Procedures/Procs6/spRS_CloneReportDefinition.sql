CREATE PROCEDURE [dbo].[spRS_CloneReportDefinition] 
@Report_Id int,
@Report_Name varchar(255),
@File_Name varchar(255)
AS
Declare @NewReportId int
Insert Into Report_Definitions(Class, Priority, Report_Type_Id, Report_Name, File_Name, Security_Group_Id, AutoRefresh, TimeStamp, Image_Ext, Native_Ext, OwnerId)
 	 Select Class, Priority, Report_Type_Id, @Report_Name, @File_Name, Security_Group_Id, AutoRefresh, TimeStamp, Image_Ext, Native_Ext, OwnerId
 	 From report_definitions
 	 Where Report_Id = @Report_Id
Select @NewReportId = Scope_Identity()
-- Copy Parameters
Insert Into Report_Definition_Parameters(RTP_Id, Report_Id, Value)
  Select RTP_Id, @NewReportId, Value
  From Report_Definition_Parameters
  Where Report_Id = @Report_Id
-- Update ReportName and FileName parameters
Exec spRS_AddReportDefParam @NewReportId, 'FileName', @File_Name
Exec spRS_AddReportDefParam @NewReportId, 'ReportName', @Report_Name
-- Update Report Definition Webpages
Insert Into Report_Def_Webpages(RWP_Id, Page_Order, Report_Def_Id)
  Select RWP_Id, Page_Order, @NewReportId
  From Report_Def_Webpages
  Where Report_Def_Id = @Report_Id

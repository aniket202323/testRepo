CREATE PROCEDURE dbo.spRS_GetReportDefProperties
@ReportDefId int
 AS
Declare @Native_Ext varchar(20)
Declare @Image_Ext varchar(20)
Declare @Report_Type_Id Int
Select @Report_Type_Id = Report_Type_Id, @Native_Ext = Native_Ext, @Image_Ext = Image_Ext From Report_Definitions Where Report_Id = @ReportDefId
If @Native_Ext Is Null
  Begin
    Select @Native_Ext = Native_Ext, @Image_Ext = Image_Ext From Report_Types Where Report_Type_Id = @Report_Type_Id
  End
Select 
RD.Report_Id, 
RD.Class, 
RD.Priority, 
RD.Report_Name,
RD.File_Name,
RD.Security_Group_Id,
RD.AutoRefresh,
RD.TimeStamp,
RD.OwnerId,
@Native_Ext 'Native_Ext',
@Image_Ext 'Image_Ext',
RT.Report_Type_Id,
RT.Version,
RT.Description,
RT.Template_Path,
RT.Class_Name,
RT.Detail_Desc,
RT.SPName,
RT.MinVersion,
RT.Template_File_Name,
RT.Date_Saved,
RT.Date_Tested_Locally,
RT.Date_Tested_Remotely,
RT.Is_Addin,
RT.Send_Parameters,
REC.Code_Desc 'sClass'
From Report_Definitions RD
Left Join Report_Types RT on RD.Report_Type_Id = RT.Report_Type_Id
Left Join Return_Error_Codes REC on REC.Code_Value = RD.Class
Where Report_Id = @ReportDefId
and REC.App_Id = 11
and REC.Group_Id = 2

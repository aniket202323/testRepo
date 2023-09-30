CREATE PROCEDURE dbo.spRS_GetReportName
@Node_Id int = Null,
@ReportDefId int = Null
AS
Declare @File_Name varchar(255) 
Declare @Report_Id int
Declare @Date_Time_Run datetime
Declare @ClassName varchar(50)
Declare @ReportType int
Declare @Native_Ext varchar(20)
Declare @Image_Ext varchar(20)
Declare @FileLocation varchar(255)
Declare @WebLocation varchar(255)
Declare @ServerFileLocation varchar(255)
Declare @Report_Name varchar(255)
----------------------------------------------------
-- Get All Information Based On Report Tree Node Id
----------------------------------------------------
If @Node_Id Is Not Null
  Begin
    Select @Report_Id = null
    --------------------------------
    -- Get the Report Definition Id
    --------------------------------
    Select @Report_Id = Report_Def_Id
    From Report_Tree_Nodes
    Where Node_Id = @Node_Id
    If (@Report_Id is Null)
      Begin
        Select @File_Name = ''
      End
    Else
      Begin
        Select @File_Name = File_Name  , @ReportType = Report_Type_Id, @Report_Name = Report_Name
        From Report_Definitions
        Where Report_Id = @Report_Id 
        Select @ClassName = Class_Name, @Native_Ext = Native_Ext, @Image_Ext = Image_Ext
        From Report_Types
        Where Report_Type_Id = @ReportType
        Exec spRS_GetReportParamValue 'WebLocation', @Report_Id, @WebLocation output
        Exec spRS_GetReportParamValue 'FileLocation', @Report_Id, @FileLocation output
        Exec spRS_GetReportParamValue 'ServerFileLocation', @Report_Id, @ServerFileLocation output
      End
    Select @Report_Id 'Report_Id', @Report_Name 'Report_Name', @File_Name 'File_Name', @ReportType 'Report_Type', @ClassName 'Class_Name', @Native_Ext 'Native_Ext', @Image_Ext 'Image_Ext', @FileLocation 'File_Location', @WebLocation 'Web_Location', @ServerFileLocation 'Server_File_Location'
  End
----------------------------------------------------
-- Get All Information Based On ReportId Passed In
----------------------------------------------------  
Else
  Begin
    Select @Report_Id = @ReportDefId
    Select @File_Name = File_Name  , @ReportType = Report_Type_Id, @Report_Name = Report_Name
    From Report_Definitions
    Where Report_Id = @Report_Id 
    Select @ClassName = Class_Name, @Native_Ext = Native_Ext, @Image_Ext = Image_Ext
    From Report_Types
    Where Report_Type_Id = @ReportType
    Exec spRS_GetReportParamValue 'WebLocation', @Report_Id, @WebLocation output
    Exec spRS_GetReportParamValue 'FileLocation', @Report_Id, @FileLocation output
    Exec spRS_GetReportParamValue 'ServerFileLocation', @Report_Id, @ServerFileLocation output
    Select @Report_Id 'Report_Id', @Report_Name 'Report_Name', @File_Name 'File_Name', @ReportType 'Report_Type', @ClassName 'Class_Name', @Native_Ext 'Native_Ext', @Image_Ext 'Image_Ext', @FileLocation 'File_Location', @WebLocation 'Web_Location', @ServerFileLocation 'Server_File_Location'
  End

CREATE PROCEDURE dbo.spRS_AddReportDefParam  
@ReportDefId int,
@ParamName varchar(50),
@ParamValue varchar(7000)
AS
Declare @RTP_Id int
Declare @New_Row int
Declare @ReportTypeId int
Declare @RowExists int
-- find the param name in the report_parameters table
-- What Parameter are we saving?
-- Get the Report type for this definition
Select @ReportTypeId = Report_Type_Id
From Report_Definitions
Where Report_Id = @ReportDefId
-- Get the Report_Type_Parameter_Id for this type of report
Select @RTP_Id = RTP.RTP_Id  --, RP.RP_Name
From Report_type_Parameters RTP
Left Join Report_Parameters RP on RTP.RP_Id = RP.RP_Id
Where RP.RP_Name = @ParamName
And RTP.Report_Type_id = @ReportTypeId
-- If No Such Parameter Then Exit
If @RTP_Id Is Null
 	 Return 1
-- If this entry already exists then update it instead of adding a new entry
Select @RowExists = RDP_Id
From Report_Definition_Parameters
Where RTP_Id = @RTP_Id
And Report_Id = @ReportDefId
If @RowExists is null
  Begin
    Insert Into Report_Definition_Parameters(
      RTP_Id,
      Report_Id,
      Value
    )
    Values(
      @RTP_Id,
      @ReportDefId,
      @ParamValue
    )
    Select @New_Row = Scope_Identity()
    If @New_Row is Null
      Return (1)  -- Error
    Else
      Return (0)  -- New Row was added
  End
Else
  Begin
    Update Report_Definition_Parameters
      Set Value = @ParamValue
    Where  RDP_Id = @RowExists
    Select @New_Row = @RowExists
    Return (2)  -- An update was performed
  End

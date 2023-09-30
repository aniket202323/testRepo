CREATE PROCEDURE dbo.spRS_GetReportParamValue
@ParamName VarChar(50),
@ReportId int,
@ReturnVal varchar(7000) output
AS
Declare @ReportTypeId int
Declare @RTP_Id int
Declare @RP_Id int
Select @ReturnVal = Null
-- Get This Definitions Report Type
Select @ReportTypeId = Report_Type_Id 
From Report_Definitions
Where Report_Id = @ReportId
-- Get the Parameters ID
Select @RP_Id = RP_Id
From Report_Parameters
Where RP_Name = @ParamName
-- Get the Report Type's Parameter Id
Select @RTP_Id = RTP_Id
From Report_Type_Parameters
Where Report_Type_Id = @ReportTypeId
and RP_Id = @RP_Id
-- Get the Report Definition's Value for the Parameter Id
Select @ReturnVal = Value
From Report_Definition_Parameters
Where RTP_Id = @RTP_Id
And Report_Id = @ReportId
If LTrim(RTrim(@ReturnVal)) = '' 
 	 Select @ReturnVal = Null

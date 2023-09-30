CREATE PROCEDURE dbo.spRS_GetTypeParamValue
@ParamName VarChar(20),
@ReportTypeId int
 AS
Declare @RP_Id int
Select @RP_Id = RP_Id
From Report_Parameters
Where RP_Name = @ParamName
Select * 
From report_Type_parameters
Where Report_Type_Id = @ReportTypeId
and RP_Id = @RP_Id

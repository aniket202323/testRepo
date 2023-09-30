CREATE PROCEDURE dbo.spRS_AddReportDefinition
@ReportTypeId INT,
@ReportName   VarChar(255) = Null,
@FileName 	   VarChar(255) = Null,
@Class        INT = Null,
@RDOwnerId 	   INT,
@ReportDefId  INT output
 AS
-------------------------------------------------- 
-- Local Variables
--------------------------------------------------
DECLARE @Security_Group_Id INT
DECLARE @RTOwnerId INT
--------------------------------------------------
-- Get Report Type  Security Group and Owner Info
--------------------------------------------------
SELECT 	 @Security_Group_Id = Security_Group_Id,
 	  	 @RTOwnerId = OwnerId
FROM 	 Report_Types
WHERE 	 Report_Type_Id = @ReportTypeId
If @RTOwnerId Is Null
  Select @RTOwnerId = @RDOwnerId
Insert Into Report_Definitions(
  Report_Type_Id,
  Report_Name,
  File_Name,
  Class,
  Security_Group_Id,
  OwnerId)
Values(
  @ReportTypeId,
  @ReportName,
  @FileName,
  @Class,
  @Security_Group_Id,
  @RTOwnerId)
Select @ReportDefId = Scope_Identity()

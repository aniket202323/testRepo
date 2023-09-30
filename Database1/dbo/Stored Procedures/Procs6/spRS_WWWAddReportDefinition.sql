CREATE PROCEDURE [dbo].[spRS_WWWAddReportDefinition]
@ReportTypeId 	 INT,
@ReportName 	  	 VARCHAR(255) = Null,
@FileName 	  	 VARCHAR(255) = Null,
@Class 	  	  	 INT = Null,
@RDUserId 	  	 INT
 AS
Declare @ReportDefId int
Exec spRS_AddReportDefinition @ReportTypeId, @ReportName, @FileName, @Class, @RDUserId, @ReportDefId output
Select @ReportDefId

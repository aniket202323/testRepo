CREATE PROCEDURE [dbo].[spRS_EngineUpdateFileName]
@ReportTypeId int,
@FileName varchar(255)
 AS
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
Update report_types Set 
 	 template_file_name = @FileName,
 	 Date_Saved = @Now
Where Report_Type_Id = @ReportTypeId

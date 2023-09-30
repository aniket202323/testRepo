Create Procedure dbo.spDBR_Get_Default_Report_Name
@ReportID int
AS
declare @ReportName varchar(100)
declare @Count int
select @ReportName = dashboard_report_name from dashboard_reports where dashboard_report_id = @reportid 
 	  	 
select @count = count(dashboard_report_Name) from dashboard_reports where dashboard_report_name like @ReportName + '%'
select @ReportName = @ReportName + convert(varchar(50),  @count)  	 
select @ReportName as ReportName

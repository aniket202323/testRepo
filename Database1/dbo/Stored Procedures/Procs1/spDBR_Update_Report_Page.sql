Create Procedure dbo.spDBR_Update_Report_Page
@ReportID int,
@Page int,
@XML   text
AS
DECLARE @ptrval binary(16)
 	 delete from dashboard_report_data_pages where report_id = @reportID and report_page = @page
 	 insert into dashboard_report_Data_pages (report_id, report_page, page_xml) values(@ReportID, @Page, @XML)
 	 SELECT @ptrval = TEXTPTR(page_xml) FROM dashboard_report_data_pages WHERE report_id = @reportid and report_page= @page
 	 WRITETEXT dashboard_report_Data_Pages.page_xml @ptrval @xml

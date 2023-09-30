CREATE PROCEDURE dbo.spRS_IEgetReportTypeWebPages
 	 @Report_Type_Id 	 int
AS
/*  For use with IMPORT/EXPORT of report packages
    MSI-MT 8-10-2000
*/
  SELECT  RTWP.* 
    FROM  Report_Type_WebPages RTWP
   WHERE  RTWP.Report_Type_Id = @Report_Type_Id
ORDER BY  RTWP.Page_Order

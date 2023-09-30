CREATE PROCEDURE dbo.spRS_IEgetReportTypeDependencies
 	 @ReportTypeId 	  	 int,
 	 @RptDependTypeId 	 int
AS
/*  For use in Import/Export of report packages
    MSI/MT 8-10-2000
*/
SELECT 	   *
FROM 	   Report_Type_Dependencies
WHERE 	   Report_Type_Id = @ReportTypeId
AND 	   RDT_Id = @RptDependTypeId
--ORDER BY  DFD

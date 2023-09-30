CREATE PROCEDURE dbo.spRS_IEgetWebPageDependencies
 	   @RptWebPageId 	  	 Int
 	 , @RptDependTypeId 	 Int
AS
/*  For use with Import/Export of report packages
    MSI/MT 8-10-2000
*/
SELECT 	   RWD.*
FROM 	   Report_WebPage_Dependencies RWD
WHERE 	   RWD.RWP_Id = @RptWebPageId
AND 	   RWD.RDT_Id = @RptDependTypeId

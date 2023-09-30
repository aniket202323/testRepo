CREATE PROCEDURE dbo.spRS_IEgetWebPageRptParamIDs
 	 @RWP_Id 	 int
AS
/*  For use in Import/Export of report packages
    MSI/MT 8-9-2000
*/
  SELECT  RWPP.RP_Id
    FROM  Report_WebPage_Parameters RWPP
   WHERE  RWPP.RWP_Id = @RWP_Id
ORDER BY  RWPP.RP_Id

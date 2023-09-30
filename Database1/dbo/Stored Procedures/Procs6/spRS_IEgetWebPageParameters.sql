CREATE PROCEDURE dbo.spRS_IEgetWebPageParameters
 	 @RWP_Id 	 int
AS
/*  For use in Import/Export of report packages
    MSI/MT 8-14-2000
*/
  SELECT  RWPP.*
    FROM  Report_WebPage_Parameters RWPP
   WHERE  RWPP.RWP_Id = @RWP_Id
ORDER BY  RWPP.RP_Id

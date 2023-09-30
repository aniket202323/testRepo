CREATE PROCEDURE dbo.spRS_IEgetWebPageInfo
 	 @RWP_Id 	 int 	 
/* Get Web Pages Info based on given RWP_Id
   Intended for use with Export/Import
   MSI/MT 8-9-2000
*/
AS
SELECT 	  WPAGE.*  	  	 
FROM  	  Report_WebPages WPAGE
WHERE 	  WPAGE.RWP_Id = @RWP_Id

CREATE PROCEDURE dbo.spRS_IEgetReportTypes
 	 @Report_Type_Id int = Null
AS
/*  For use with IMPORT/EXPORT of report packages
    MSI/MT 8-10-2000
*/
If @Report_Type_Id Is NULL
    BEGIN
 	 SELECT 	 RT.* 
 	 FROM 	 Report_Types RT
    END
Else
    BEGIN
 	 SELECT  	 RT.*
        FROM  	 Report_Types RT
 	 WHERE 	 RT.Report_Type_Id = @Report_Type_Id
    END

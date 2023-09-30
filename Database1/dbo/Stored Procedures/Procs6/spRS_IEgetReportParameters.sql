CREATE PROCEDURE dbo.spRS_IEgetReportParameters 
 	 @RP_Id 	 int = NULL
AS
/*  For use in Import/Export of report packages
    MSI/MT 8-10-2000
*/
If @RP_Id Is NUll
    BEGIN
 	 SELECT 	 RP.*
 	 FROM 	 Report_Parameters RP
    END
Else
    BEGIN
 	 SELECT 	 RP.*
 	 FROM 	 Report_Parameters RP
 	 WHERE 	 RP.RP_Id = @RP_Id
    END

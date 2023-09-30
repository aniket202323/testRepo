CREATE PROCEDURE dbo.spRS_IEgetReportTypeParameters
 	 @Report_Type_Id 	 int = NULL 	 
/*  For use with IMPORT/EXPORT for report packages
    MSI-MT 8-11-2000
*/
AS
If @Report_Type_Id Is NULL
    BEGIN
 	 SELECT 	 RTP.* 
 	 FROM 	 Report_Type_Parameters RTP
    END
Else
    BEGIN
 	 SELECT 	 RTP.* 
 	 FROM 	 Report_Type_Parameters RTP
 	 WHERE 	 RTP.Report_Type_Id = @Report_Type_Id
    END

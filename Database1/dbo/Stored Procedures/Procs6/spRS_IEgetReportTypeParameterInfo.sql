CREATE PROCEDURE dbo.spRS_IEgetReportTypeParameterInfo
 	 @Report_Type_Id 	 int 	 
AS
/*  For use with IMPORT/EXPORT of report packages  
    MSI-MT 8-10-2000  
*/
SELECT   RTP.* 
FROM     Report_Type_Parameters RTP
WHERE    RTP.Report_Type_Id = @Report_Type_Id

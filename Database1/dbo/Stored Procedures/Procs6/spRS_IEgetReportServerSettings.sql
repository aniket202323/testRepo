CREATE PROCEDURE dbo.spRS_IEgetReportServerSettings
 	 @Name 	 varchar(20) = NULL
AS
/*  For Import/Export use
    MSI/MT 8-10-2000
*/
If @Name Is Null
    BEGIN
 	 SELECT 	 RSS.* 
 	 FROM 	 Report_Server_Settings RSS
    END
Else
    BEGIN
 	 SELECT 	 RSS.Value
 	 FROM 	 Report_Server_Settings RSS
 	 WHERE 	 RSS.Name = @Name
    END

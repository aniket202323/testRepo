
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetSiteParameter] 

AS 
BEGIN

	DECLARE @SiteName nVARCHAR(255), @ProcessOrderOrBatch nVARCHAR(255)

	SELECT @SiteName = (SELECT Value FROM Site_Parameters WHERE Parm_Id =12)
	,@ProcessOrderOrBatch = (SELECT Value FROM Site_Parameters WHERE Parm_Id = 609)

	SELECT @SiteName SiteName, ProcessOrderOrBatch = CASE @ProcessOrderOrBatch
													 WHEN 'ProcessOrder' THEN 'ProcessOrder' 
													 WHEN 'Batch' THEN 'Batch' 
													 ELSE 'Batch'
	END
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetSiteParameter] TO [ComXClient]
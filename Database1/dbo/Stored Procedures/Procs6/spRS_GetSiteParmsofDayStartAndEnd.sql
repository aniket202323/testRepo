CREATE   PROCEDURE [dbo].[spRS_GetSiteParmsofDayStartAndEnd] 
AS
SELECT Value 
FROM Site_Parameters Where Parm_Id in (14,15)

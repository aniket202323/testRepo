CREATE PROCEDURE [dbo].[spBF_GetSiteName] 
AS 
BEGIN
  SELECT Value FROM Site_Parameters WHERE Parm_Id =12
END

CREATE PROCEDURE dbo.spRS_EngineGetSiteParameters
 AS
SELECT p.Parm_Id, p.Parm_name, sp.Hostname, sp.value
FROM Site_Parameters sp
JOIN Parameters p ON p.Parm_Id = sp.Parm_Id
WHERE p.Parm_Id BETWEEN 50 AND 59
OR p.Parm_Id BETWEEN 301 AND 350
OR p.Parm_Id = 10
ORDER BY Hostname ASC

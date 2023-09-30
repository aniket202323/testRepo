CREATE PROCEDURE dbo.spSDK_QuerySiteParameterValues
 	 @HostName 	  	  	 nvarchar(50),
 	 @ParmId 	  	  	  	 INT,
 	 @ParmName 	  	  	 nvarchar(50)
AS
SET 	 @ParmName = REPLACE(REPLACE(REPLACE(COALESCE(@ParmName, '%'), '*', '%'), '?', '_'), '[', '[[]')
CREATE 	 TABLE 	 #Parameters (
 	 ParameterId 	  	 INT,
 	 ParameterName 	 nvarchar(50),
 	 Value 	  	  	  	 nVarChar(4000),
 	 DefaultValue 	 nVarChar(4000),
 	 MinValue 	  	  	 INT,
 	 MaxValue 	  	  	 INT
)
INSERT 	 #Parameters
SELECT 	 ParameterId 	  	  	 = 	 p.Parm_Id,
 	  	  	 ParameterName 	  	 = 	 p.Parm_Name,
 	  	  	 Value 	  	  	  	  	 = 	 sp.Value,
 	  	  	 DefaultValue 	  	 = 	 Null,  --not used
 	  	  	 MinValue 	  	  	  	 = 	 p.Parm_Min,
 	  	  	 MaxValue 	  	  	  	 = 	 p.Parm_Max
 	 FROM 	  	  	 Parameters p
 	 INNER 	 JOIN 	 Site_Parameters sp 	  	 ON 	  	 sp.Parm_Id = p.Parm_Id
 	 WHERE 	  	  	 sp.HostName = @HostName
 	 AND 	  	  	 p.System = 0
INSERT 	 #Parameters
SELECT 	 ParameterId 	  	  	 = 	 p.Parm_Id,
 	  	  	 ParameterName 	  	 = 	 p.Parm_Name,
 	  	  	 Value 	  	  	  	  	 = 	 sp.Value,
 	  	  	 DefaultValue 	  	 = 	 Null,
 	  	  	 MinValue 	  	  	  	 = 	 p.Parm_Min,
 	  	  	 MaxValue 	  	  	  	 = 	 p.Parm_Max
 	 FROM 	  	  	 Parameters p
 	 INNER 	 JOIN 	 Site_Parameters sp 	  	 ON 	  	 sp.Parm_Id = p.Parm_Id
 	 WHERE 	  	  	 (sp.HostName = '' 	 OR sp.HostName IS NULL)
 	 AND 	  	  	 sp.Parm_Id NOT IN (SELECT ParameterId FROM #Parameters)
 	 AND 	  	  	 p.System = 0
SELECT 	 *
 	 FROM 	 #Parameters
 	 WHERE 	 ParameterName LIKE @ParmName
 	 AND 	 (ParameterId = @ParmId OR @ParmId IS NULL)
 	 ORDER BY ParameterName

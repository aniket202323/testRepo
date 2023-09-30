CREATE VIEW dbo.ProceduresAndParameters
AS
SELECT     TOP 100 PERCENT sys.sysobjects.name AS ProcName, sys.sysobjects.id AS ProcId, sys.syscolumns.name AS ParamName, 
                      sys.syscolumns.colid AS ParamId, sys.syscolumns.isoutparam AS IsOutput
FROM         sys.syscolumns INNER JOIN
                      sys.sysobjects ON sys.syscolumns.id = sys.sysobjects.id
WHERE     (OBJECTPROPERTY(dbo.sysobjects.id, N'IsProcedure') = 1)
ORDER BY sys.sysobjects.name, sys.sysobjects.id DESC

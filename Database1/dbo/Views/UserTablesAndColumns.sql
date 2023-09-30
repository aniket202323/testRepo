CREATE VIEW dbo.UserTablesAndColumns
AS
SELECT TOP 100 PERCENT sys.sysobjects.name AS TableName, sys.sysobjects.id AS TableId, sys.syscolumns.name AS ColumnName, 
               sys.syscolumns.colid AS ColumnId
FROM  sys.syscolumns INNER JOIN
               sys.sysobjects ON sys.syscolumns.id = sys.sysobjects.id
WHERE (OBJECTPROPERTY(sysobjects.id, N'IsUserTable') = 1)
ORDER BY TableName, ColumnName

CREATE PROCEDURE dbo.spSupport_CheckIndexes
-- checks the entire database for tables that don't have indexes
AS
Select o.name as TableName, (Select Rows from sys.sysindexes where ID = o.id and indid = 0) ROWS
FROM 
  sys.sysobjects o
Where 
  Type = 'U' 
  AND OBJECTPROPERTY(o.id, 'TableHasIndex') = 0 

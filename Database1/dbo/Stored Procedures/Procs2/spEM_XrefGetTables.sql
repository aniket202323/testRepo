CREATE PROCEDURE dbo.spEM_XrefGetTables 
AS
 	 Select TableId,TableName from Tables where allow_X_Ref = 1 order by TableName

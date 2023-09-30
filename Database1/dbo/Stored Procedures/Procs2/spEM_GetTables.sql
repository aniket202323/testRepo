CREATE PROCEDURE dbo.spEM_GetTables 
  AS
 	 SELECT TableId,TableName
 	 FROM Tables 
 	 WHERE Allow_User_Defined_Property = 1
 	 ORDER BY TableName

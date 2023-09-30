--  execute spEM_XrefGetEmailTables 51
CREATE PROCEDURE dbo.spEM_XrefGetEmailTables 
@EmailGroupid Int
AS
DECLARE @Tables Table (TableId Int,TableName nVarChar(100),HasRows Int)
INSERT INTO @Tables(TableId,TableName) VALUES (17,'Department')
INSERT INTO @Tables(TableId,TableName) VALUES (18,'Production Line')
INSERT INTO @Tables(TableId,TableName) VALUES (19,'Production Group')
INSERT INTO @Tables(TableId,TableName) VALUES (21,'Product Family')
INSERT INTO @Tables(TableId,TableName) VALUES (22,'Product Group')
INSERT INTO @Tables(TableId,TableName) VALUES (23,'Product')
INSERT INTO @Tables(TableId,TableName) VALUES (43,'Production Unit')
Update @Tables SET TableName = '* ' + TableName 
 	 FROM @Tables a
 	 JOIN Email_Group_Xref b on a.TableId = b.Table_Id and b.EG_Id = @EmailGroupid
Select TableId,TableName from @Tables  order by TableName

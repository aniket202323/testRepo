
CREATE PROCEDURE dbo.spMES_GetReportTimeSelection
		@DisplayType Int = Null
AS

DECLARE @AllOptions TABLE (SelectionId int,SelectionDesc nvarchar(100))
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (1,'Current Day')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (2,'Previous Day')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (3,'Current Week')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (4,'Previous Week')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (5,'Next Week')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (6,'Next Day')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (7,'User Defined')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (8,'Current Shift')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (9,'Previous Shift')
INSERT INTO @AllOptions (SelectionId,SelectionDesc) VALUES (10,'Next Shift')

IF @DisplayType = 1
BEGIN
	SELECT SelectionId,SelectionDesc 
	FROM @AllOptions 
	WHERE SelectionId IN (1,2,7,8,9)
	ORDER BY SelectionDesc
END
ELSE
BEGIN
	SELECT SelectionId,SelectionDesc 
	FROM @AllOptions
	ORDER BY SelectionDesc
END


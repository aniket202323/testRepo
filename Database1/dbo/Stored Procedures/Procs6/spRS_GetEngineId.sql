CREATE PROCEDURE dbo.spRS_GetEngineId
@ComputerName varchar(50),
@ServiceName varchar(20)
 AS
SELECT * FROM REPORT_ENGINES
WHERE ENGINE_NAME = @ComputerName
and Service_Name = @ServiceName

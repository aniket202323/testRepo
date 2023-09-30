CREATE FUNCTION [dbo].[fnLocal_eCIL_GetDowntimeRecordsForLines]
(@LineIds VARCHAR (7000) NULL, @AfterDate DATETIME NULL, @BeforeDate DATETIME NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [LineId]    INT        NULL,
        [PU_Id]     INT        NULL,
        [StartTime] DATETIME   NULL,
        [EndTime]   DATETIME   NULL,
        [DownTime]  FLOAT (53) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


CREATE FUNCTION [dbo].[fnLocal_SSI_GetProductionDay]
(@p_vchStartTime VARCHAR (25) NULL, @p_vchEndTime VARCHAR (25) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]             INT           IDENTITY (1, 1) NOT NULL,
        [ProductionDay]      VARCHAR (25)  NULL,
        [ProductionDayStart] VARCHAR (25)  NULL,
        [ProductionDayEnd]   VARCHAR (25)  NULL,
        [Error]              VARCHAR (250) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


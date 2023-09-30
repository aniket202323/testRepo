CREATE FUNCTION [dbo].[fnLocal_PG_Batch_GetTestConformanceConfigData]
( )
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]          INT          IDENTITY (1, 1) NOT NULL,
        [PUId]            INT          NULL,
        [ParmTestVarDesc] VARCHAR (50) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


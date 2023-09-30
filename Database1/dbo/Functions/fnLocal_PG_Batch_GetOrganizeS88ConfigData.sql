CREATE FUNCTION [dbo].[fnLocal_PG_Batch_GetOrganizeS88ConfigData]
( )
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]           INT          IDENTITY (1, 1) NOT NULL,
        [PUId]             INT          NULL,
        [ResultVarId]      INT          NULL,
        [CalcId]           INT          NULL,
        [ParmProcessOrder] VARCHAR (25) NULL,
        [ParmBatchSize]    VARCHAR (25) NULL,
        [ParmBatchEnd]     VARCHAR (25) NULL,
        [ParmBatchReport]  VARCHAR (25) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


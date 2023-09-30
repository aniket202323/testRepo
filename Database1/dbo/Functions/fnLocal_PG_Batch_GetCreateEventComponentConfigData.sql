CREATE FUNCTION [dbo].[fnLocal_PG_Batch_GetCreateEventComponentConfigData]
( )
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]             INT          IDENTITY (1, 1) NOT NULL,
        [PUId]               INT          NULL,
        [ResultVarId]        INT          NULL,
        [CalcId]             INT          NULL,
        [ParmProdCode]       VARCHAR (25) NULL,
        [ParmQuantityValue]  VARCHAR (25) NULL,
        [ParmSourceLocation] VARCHAR (25) NULL,
        [ParmSourceLotId]    VARCHAR (25) NULL,
        [ParmBatchUoM]       VARCHAR (25) NULL,
        [ParmSAPReportValue] VARCHAR (25) NULL,
        [ParmFilterValue]    VARCHAR (25) NULL,
        [ParmStartHeelPhase] VARCHAR (25) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


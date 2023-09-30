CREATE FUNCTION [dbo].[fnLocal_LEDS_Formulas]
(@intLanguageId INT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]               INT            IDENTITY (1, 1) NOT NULL,
        [MeasurePromptNumber]  INT            NULL,
        [Measure]              VARCHAR (1000) NULL,
        [EngUnitsPromptNumber] INT            NULL,
        [EngUnits]             VARCHAR (50)   NULL,
        [MultiLineRollUp]      VARCHAR (1000) NULL,
        [Line]                 VARCHAR (1000) NULL,
        [Constraint1]          VARCHAR (1000) NULL,
        [Constraintx]          VARCHAR (1000) NULL,
        [Machine]              VARCHAR (1000) NULL,
        [IntRowCount]          INT            NULL,
        [ErrorCode]            INT            NULL,
        [ErrorMsg]             VARCHAR (1000) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


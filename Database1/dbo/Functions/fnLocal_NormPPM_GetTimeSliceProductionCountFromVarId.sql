CREATE FUNCTION [dbo].[fnLocal_NormPPM_GetTimeSliceProductionCountFromVarId]
(@p_intProductionVarId INT NULL, @p_dtmTimeSliceStart DATETIME NULL, @p_dtmTimeSliceEnd DATETIME NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [ProductionVarId] INT        NULL,
        [TimeSliceStart]  DATETIME   NULL,
        [TimeSliceEnd]    DATETIME   NULL,
        [ProductionCount] FLOAT (53) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


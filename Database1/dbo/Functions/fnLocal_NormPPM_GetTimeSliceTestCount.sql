CREATE FUNCTION [dbo].[fnLocal_NormPPM_GetTimeSliceTestCount]
(@p_intVarId INT NULL, @p_intSamplePUId INT NULL, @p_intIsOfflineQuality INT NULL, @p_dtmTimeSliceStart DATETIME NULL, @p_dtmTimeSliceEnd DATETIME NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [VarId]                  INT      NULL,
        [TimeSliceStart]         DATETIME NULL,
        [TimeSliceEnd]           DATETIME NULL,
        [TestCountResultNOTNULL] INT      NULL,
        [TestCountResultNULL]    INT      NULL,
        [TestCountTotal]         INT      NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


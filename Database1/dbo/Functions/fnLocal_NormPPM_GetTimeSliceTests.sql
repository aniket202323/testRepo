CREATE FUNCTION [dbo].[fnLocal_NormPPM_GetTimeSliceTests]
(@p_intVarId INT NULL, @p_intSamplePUId INT NULL, @p_intIsOfflineQuality INT NULL, @p_dtmTimeSliceStart DATETIME NULL, @p_dtmTimeSliceEnd DATETIME NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [TimeSliceStart] DATETIME     NULL,
        [TimeSliceEnd]   DATETIME     NULL,
        [VarId]          INT          NULL,
        [Result]         VARCHAR (50) NULL,
        [ResultOn]       DATETIME     NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


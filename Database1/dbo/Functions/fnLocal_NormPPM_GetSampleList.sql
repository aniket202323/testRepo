CREATE FUNCTION [dbo].[fnLocal_NormPPM_GetSampleList]
(@p_intSamplePUId INT NULL, @p_intEventSubTypeId INT NULL, @p_dtmTimeSliceStart DATETIME NULL, @p_dtmTimeSliceEnd DATETIME NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [SampleId]        INT      NULL,
        [SamplePUId]      INT      NULL,
        [EventSubTypeId]  INT      NULL,
        [SampleTimeStamp] DATETIME NULL,
        [TimeSliceStart]  DATETIME NULL,
        [TimeSliceEnd]    DATETIME NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


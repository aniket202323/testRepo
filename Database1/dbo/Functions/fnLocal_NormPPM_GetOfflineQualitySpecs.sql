CREATE FUNCTION [dbo].[fnLocal_NormPPM_GetOfflineQualitySpecs]
(@p_intSamplePUId INT NULL, @p_intVarId INT NULL, @p_dtmTimeSliceStart DATETIME NULL, @p_dtmTimeSliceEnd DATETIME NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [VarId]          INT            NULL,
        [TimeSliceStart] DATETIME       NULL,
        [TimeSliceEnd]   DATETIME       NULL,
        [ProdId]         INT            NULL,
        [LEL]            VARCHAR (50)   NULL,
        [LSL]            VARCHAR (50)   NULL,
        [Target]         VARCHAR (50)   NULL,
        [USL]            VARCHAR (50)   NULL,
        [UEL]            VARCHAR (50)   NULL,
        [LTL]            VARCHAR (50)   NULL,
        [UTL]            VARCHAR (50)   NULL,
        [SpecVersion]    VARCHAR (35)   NULL,
        [SpecTestFreq]   INT            NULL,
        [TestFreq]       INT            NULL,
        [ErrorCode]      INT            NULL,
        [ErrorMsg]       VARCHAR (1000) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


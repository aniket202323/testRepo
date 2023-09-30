CREATE FUNCTION [dbo].[fnLocal_PG_Cmn_StringSplitSingleDelimiter]
(@p_vchDelimitedString VARCHAR (MAX) NULL, @p_vchDelimiter VARCHAR (1) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [RcdIdx]       INT            IDENTITY (1, 1) NOT NULL,
        [ErrorCode]    INT            NULL,
        [ErrorMessage] VARCHAR (2000) NULL,
        [StringValue]  VARCHAR (255)  NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


CREATE FUNCTION [dbo].[fnLocal_STI_Cmn_SplitString]
(@String VARCHAR (8000) NULL, @Delimiter CHAR (1) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Id]     INT            IDENTITY (1, 1) NOT NULL,
        [String] VARCHAR (8000) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


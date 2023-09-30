CREATE FUNCTION [dbo].[fnLocal_eCIL_GetPlantModelItemByUDP]
(@FL1 VARCHAR (50) NULL, @FL2 VARCHAR (50) NULL, @FL3 VARCHAR (50) NULL, @FL4 VARCHAR (50) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Id]          INT            NULL,
        [Description] VARCHAR (8000) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


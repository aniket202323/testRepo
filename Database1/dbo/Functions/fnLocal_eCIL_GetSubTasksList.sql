CREATE FUNCTION [dbo].[fnLocal_eCIL_GetSubTasksList]
(@Granularity INT NULL, @TopLevelID INT NULL, @SubLevel INT NULL, @UserId INT NULL, @RouteIds VARCHAR (7000) NULL, @TeamIDs VARCHAR (7000) NULL, @TeamDetail INT NULL, @QFactorOnly BIT NULL, @HSEOnly BIT NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Var_Id]       INT           NULL,
        [Var_Desc]     VARCHAR (50)  NULL,
        [PU_Id]        INT           NULL,
        [Master_Unit]  INT           NULL,
        [TopLevelId]   INT           NULL,
        [TopLevelDesc] VARCHAR (150) NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


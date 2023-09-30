CREATE PROCEDURE [dbo].[spLocal_CTS_CreateUpdate_Location_Cleaning]
@PUId INT NULL, @UDEId INT NULL, @CleaningType VARCHAR (30) NULL, @CleaningProcedure VARCHAR (30) NULL, @LocationCleared INT NULL, @CleaningStatus VARCHAR (30) NULL, @SanitizerBatch VARCHAR (100) NULL, @SanitizerConc FLOAT (53) NULL, @DetergentBatch VARCHAR (100) NULL, @DetergentConc FLOAT (53) NULL, @StartTime DATETIME NULL, @EndTime DATETIME NULL, @UserId INT NULL, @RoleId INT NULL, @ApprovalTime DATETIME NULL, @Comment VARCHAR (5000) NULL, @OutPutStatus INT NULL OUTPUT, @OutPutMessage VARCHAR (255) NULL OUTPUT
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



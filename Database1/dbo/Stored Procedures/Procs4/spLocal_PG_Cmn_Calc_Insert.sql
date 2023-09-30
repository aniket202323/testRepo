CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_Calc_Insert]
@Status INT NULL OUTPUT, @ErrMsg VARCHAR (300) NULL OUTPUT, @CalculationId INT NULL OUTPUT, @UserId INT NULL, @Name NVARCHAR (255) NULL, @Desc NVARCHAR (255) NULL, @Type NVARCHAR (50) NULL, @Action NVARCHAR (MAX) NULL, @Trigger NVARCHAR (50) NULL, @IAlias NVARCHAR (MAX) NULL, @IName NVARCHAR (MAX) NULL, @IEntity NVARCHAR (MAX) NULL, @IAttribute NVARCHAR (MAX) NULL, @DefValue NVARCHAR (MAX) NULL, @NonTrigger NVARCHAR (MAX) NULL, @Optional NVARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



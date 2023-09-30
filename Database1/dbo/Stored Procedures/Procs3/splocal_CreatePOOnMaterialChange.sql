CREATE PROCEDURE [dbo].[splocal_CreatePOOnMaterialChange]
@Success INT NULL OUTPUT, @ErrMsg VARCHAR (255) NULL OUTPUT, @JumptoTime DATETIME NULL OUTPUT, @ECID INT NULL, @Reserved1 VARCHAR (30) NULL, @Reserved2 VARCHAR (30) NULL, @Reserved3 VARCHAR (30) NULL, @ChangedTagNum INT NULL, @ChangedPrevValue VARCHAR (10) NULL, @ChangedNewValue VARCHAR (10) NULL, @ChangedPrevTime DATETIME NULL, @ChangedNewTime DATETIME NULL, @Trigger_PrevValue VARCHAR (30) NULL, @MaterialCode VARCHAR (10) NULL, @Trigger_PrevTime DATETIME NULL, @Trigger_NewTime DATETIME NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



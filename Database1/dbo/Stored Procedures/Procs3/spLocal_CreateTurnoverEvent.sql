CREATE PROCEDURE [dbo].[spLocal_CreateTurnoverEvent]
@Success INT NULL OUTPUT, @ErrorMsg VARCHAR (255) NULL OUTPUT, @JumpToTime DATETIME NULL OUTPUT, @ECId INT NULL, @Reserved1 VARCHAR (30) NULL, @Reserved2 VARCHAR (30) NULL, @Reserved3 VARCHAR (30) NULL, @ChangedTagNum INT NULL, @ChangedPrevValue VARCHAR (30) NULL, @ChangedNewValue VARCHAR (30) NULL, @ChangedPrevTime DATETIME NULL, @ChangedNewTime DATETIME NULL, @TurnoverPrevValue VARCHAR (30) NULL, @TurnoverNewValue VARCHAR (30) NULL, @TurnoverPrevTime DATETIME NULL, @TurnoverNewTime DATETIME NULL, @DiameterPrevValue VARCHAR (30) NULL, @DiameterNewValue VARCHAR (30) NULL, @DiameterPrevTime DATETIME NULL, @DiameterNewTime DATETIME NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



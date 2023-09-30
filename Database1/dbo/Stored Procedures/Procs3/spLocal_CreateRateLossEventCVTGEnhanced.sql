CREATE PROCEDURE [dbo].[spLocal_CreateRateLossEventCVTGEnhanced]
@Success INT NULL OUTPUT, @ErrorMsg VARCHAR (255) NULL OUTPUT, @JumpToTime DATETIME NULL OUTPUT, @ECId INT NULL, @Reserved1 VARCHAR (30) NULL, @Reserved2 VARCHAR (30) NULL, @Reserved3 VARCHAR (30) NULL, @ChangedTagNum INT NULL, @ChangedTagPrevValue VARCHAR (30) NULL, @ChangedTagNewValue VARCHAR (30) NULL, @ChangedTagPrevTime DATETIME NULL, @ChangedTagNewTime DATETIME NULL, @SpeedPrevValue VARCHAR (30) NULL, @SpeedNewValue VARCHAR (30) NULL, @SpeedPrevTime DATETIME NULL, @SpeedNewTime DATETIME NULL, @ReliabilityPrevValue VARCHAR (30) NULL, @ReliabilityNewValue VARCHAR (30) NULL, @ReliabilityPrevTime DATETIME NULL, @ReliabilityNewTime DATETIME NULL, @UnitOpFaultPrevValue VARCHAR (30) NULL, @UnitOpFaultNewValue VARCHAR (30) NULL, @UnitOpFaultPrevTime DATETIME NULL, @UnitOpFaultNewTime DATETIME NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



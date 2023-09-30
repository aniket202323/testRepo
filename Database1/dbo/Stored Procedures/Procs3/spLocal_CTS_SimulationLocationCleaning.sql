CREATE PROCEDURE [dbo].[spLocal_CTS_SimulationLocationCleaning]
@OutputValue VARCHAR (25) NULL OUTPUT, @ExecStartedVarId INT NULL, @ExecCompletedVarId INT NULL, @ExecApprovedVarId INT NULL, @PuDesc VARCHAR (50) NULL, @UDEIdVarId INT NULL, @CleaningType VARCHAR (30) NULL, @SanitizerBatch VARCHAR (100) NULL, @SanitizerConc FLOAT (53) NULL, @DetergentBatch VARCHAR (100) NULL, @DetergentConc FLOAT (53) NULL, @Comment VARCHAR (5000) NULL, @CompleteStatus VARCHAR (25) NULL, @ApproveStatus VARCHAR (25) NULL, @TriggervarId INT NULL, @Timestamp DATETIME NULL, @Role VARCHAR (50) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



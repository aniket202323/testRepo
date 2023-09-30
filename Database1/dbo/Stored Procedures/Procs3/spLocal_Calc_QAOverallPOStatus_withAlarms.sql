CREATE PROCEDURE [dbo].[spLocal_Calc_QAOverallPOStatus_withAlarms]
@Result NVARCHAR (10) NULL OUTPUT, @TriggerValue NVARCHAR (25) NULL, @SampleCount INT NULL, @ThisVarId INT NULL, @Timestamp DATETIME NULL, @LineType NVARCHAR (25) NULL, @CountUnacceptable FLOAT (53) NULL, @CountMarginal FLOAT (53) NULL, @CountOOSLRL FLOAT (53) NULL, @CountOOSLWL FLOAT (53) NULL, @CountAlarms FLOAT (53) NULL, @NbVarColumns INT NULL, @NbPercMarginals FLOAT (53) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



CREATE PROCEDURE [dbo].[spLocal_QIC_ProductionRun]
@ProductionRunId INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



GO
EXECUTE sp_addextendedproperty @name = N'QIC.Version', @value = '3.0.4', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = N'spLocal_QIC_ProductionRun';


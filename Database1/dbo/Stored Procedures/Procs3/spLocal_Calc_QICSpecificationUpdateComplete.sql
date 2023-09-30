CREATE PROCEDURE [dbo].[spLocal_Calc_QICSpecificationUpdateComplete]
@Outputvalue VARCHAR (25) NULL OUTPUT, @EventID INT NULL, @WeightVarID INT NULL, @ProductID INT NULL, @UpperEntry NUMERIC (18, 4) NULL, @UpperReject NUMERIC (18, 4) NULL, @UpperWarning NUMERIC (18, 4) NULL, @UpperUser NUMERIC (18, 4) NULL, @LowerEntry NUMERIC (18, 4) NULL, @LowerReject NUMERIC (18, 4) NULL, @LowerWarning NUMERIC (18, 4) NULL, @LowerUser NUMERIC (18, 4) NULL, @TargetWeight NUMERIC (18, 4) NULL, @SpecificGravity NUMERIC (18, 4) NULL, @StandardDeviation NUMERIC (18, 4) NULL, @SpecGravUpperLimit NUMERIC (18, 4) NULL, @SpecGravLowerLimit NUMERIC (18, 4) NULL, @StdDevUpperLimit NUMERIC (18, 4) NULL, @StdDevLowerLimit NUMERIC (18, 4) NULL, @TargetUpperLimit NUMERIC (18, 4) NULL, @TargetLowerLimit NUMERIC (18, 4) NULL, @ThisVarId INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



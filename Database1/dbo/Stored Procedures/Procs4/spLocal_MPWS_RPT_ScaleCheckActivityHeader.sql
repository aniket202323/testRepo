 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ScaleCheckActivityHeader
	
	Date			Version		Build	Author  
	27-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development
	08-Nov-2017		001			002		Susan Lee (GE Digital)	Filter negative weights
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ScaleCheckActivityHeader @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 3373, '20150101', '20160731'
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ScaleCheckActivityHeader]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ScaleId		INT,
	@StartTime		DATETIME,
	@EndTime		DATETIME
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @MinWeight FLOAT = 0.000
 
;WITH d AS
(
	SELECT
		Result_On,
		(SELECT PU_Desc FROM dbo.Prod_Units_Base WHERE PU_Id = @ScaleId) ScaleDesc,
		ScaleCheckTarget TargetWeight,
		ScaleCheckTarget * (100.0 - ScaleCheckTolerance) / 100.0 LowerTolWeight,
		ScaleCheckTarget * (100.0 + ScaleCheckTolerance) / 100.0 UpperTolWeight,
		MIN(Result_On) OVER (PARTITION BY ScaleCheckTarget, ScaleCheckTolerance) StartTimestamp,
		MAX(Result_On) OVER (PARTITION BY ScaleCheckTarget, ScaleCheckTolerance) EndTimestamp
	FROM (
			SELECT
				t.Result_On,
				v.Var_Desc,
				t.Result
			FROM dbo.Tests t
				JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
			WHERE t.Result_On BETWEEN @StartTime AND @EndTime
				AND v.PU_Id = @ScaleId
				AND v.Var_Desc IN ('ScaleCheckTarget', 'ScaleCheckTolerance', 'ScaleCheckWeight', 'ScaleCheckZeroWeight', 'ScaleCalibratePassed', 'ScaleCheckPassed')
		)a
		PIVOT (MAX(Result) FOR Var_Desc IN ([ScaleCheckTarget], [ScaleCheckTolerance], [ScaleCheckWeight], [ScaleCheckZeroWeight], [ScaleCalibratePassed], [ScaleCheckPassed])) pvt
	WHERE ScaleCheckTarget IS NOT NULL
)
SELECT DISTINCT
	StartTimestamp,
	EndTimestamp,
	ScaleDesc,
	TargetWeight,
	UpperTolWeight,
	LowerTolWeight
FROM d
WHERE TargetWeight >= @MinWeight
	
SET @ErrorCode = 1;
SET @ErrorMessage = 'Success';
	

 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ScaleCalibrateActivityHeader
	
	Date			Version		Build	Author  
	27-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development
	28-Jul-2016		001			002		Susan Lee				Added RowNum to output
 	08-Nov-2017		001			003		Susan Lee (GE Digital)	Filter negative weight rows
	30-Nov-2017     001         004		Susan Lee (GE Digital)	output null for non-required targets
test
 select pu_id from prod_units_base where pu_desc='PW01DS02-Scale01'

DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ScaleCalibrateActivityHeader @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 6083, '2017-10-01', '2017-12-30'
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ScaleCalibrateActivityHeader]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ScaleId		INT,
	@StartTime		DATETIME,
	@EndTime		DATETIME
--WITH ENCRYPTION 
AS


SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @MinWeight float = 0.000 

DECLARE @tOutput TABLE
(
	StartTimestamp	datetime,
	EndTimestamp	datetime,
	ScaleDesc		varchar(50),
	Target1			varchar(255),
	Target2			varchar(255),
	Target3			varchar(255),
	Target4			varchar(255),
	Target5			varchar(255)
	--TargetWeight1	float,
	--LowerTolWeight1	float,
	--UpperTolWeight1	float,
	--TargetWeight2	float,
	--LowerTolWeight2	float,
	--UpperTolWeight2	float,
	--TargetWeight3	float,
	--LowerTolWeight3	float,
	--UpperTolWeight3	float,
	--TargetWeight4	float,
	--LowerTolWeight4	float,
	--UpperTolWeight4	float,
	--TargetWeight5	float,
	--LowerTolWeight5	float,
	--UpperTolWeight5	float
)
 
;WITH d AS
(
	SELECT
		Result_On,
		(SELECT PU_Desc FROM dbo.Prod_Units_Base WHERE PU_Id = @ScaleId) ScaleDesc,
		ScaleCalibrateTarget1 TargetWeight1,
		ScaleCalibrateTarget1 * (100.0 - ScaleCalibrateTolerance) / 100.0 LowerTolWeight1,
		ScaleCalibrateTarget1 * (100.0 + ScaleCalibrateTolerance) / 100.0 UpperTolWeight1,
		ScaleCalibrateTarget2 TargetWeight2,
		ScaleCalibrateTarget2 * (100.0 - ScaleCalibrateTolerance) / 100.0 LowerTolWeight2,
		ScaleCalibrateTarget2 * (100.0 + ScaleCalibrateTolerance) / 100.0 UpperTolWeight2,
		ScaleCalibrateTarget3 TargetWeight3,
		ScaleCalibrateTarget3 * (100.0 - ScaleCalibrateTolerance) / 100.0 LowerTolWeight3,
		ScaleCalibrateTarget3 * (100.0 + ScaleCalibrateTolerance) / 100.0 UpperTolWeight3,
		ScaleCalibrateTarget4 TargetWeight4,
		ScaleCalibrateTarget4 * (100.0 - ScaleCalibrateTolerance) / 100.0 LowerTolWeight4,
		ScaleCalibrateTarget4 * (100.0 + ScaleCalibrateTolerance) / 100.0 UpperTolWeight4,
		ScaleCalibrateTarget5 TargetWeight5,
		ScaleCalibrateTarget5 * (100.0 - ScaleCalibrateTolerance) / 100.0 LowerTolWeight5,
		ScaleCalibrateTarget5 * (100.0 + ScaleCalibrateTolerance) / 100.0 UpperTolWeight5,
		MIN(Result_On) OVER (PARTITION BY ScaleCalibrateTarget1, ScaleCalibrateTarget2, ScaleCalibrateTarget3, ScaleCalibrateTarget4, ScaleCalibrateTarget5, ScaleCalibrateTolerance) StartTimestamp,
		MAX(Result_On) OVER (PARTITION BY ScaleCalibrateTarget1, ScaleCalibrateTarget2, ScaleCalibrateTarget3, ScaleCalibrateTarget4, ScaleCalibrateTarget5, ScaleCalibrateTolerance) EndTimestamp
	FROM (
			SELECT
				t.Result_On,
				v.Var_Desc,
				t.Result
			FROM dbo.Tests t
				JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
			WHERE t.Result_On BETWEEN @StartTime AND @EndTime
				AND v.PU_Id = @ScaleId
				AND v.Var_Desc IN ('ScaleCalibrateTarget1', 'ScaleCalibrateTarget2', 'ScaleCalibrateTarget3', 'ScaleCalibrateTarget4', 'ScaleCalibrateTarget5', 'ScaleCalibrateTolerance')
		)a
		PIVOT (MAX(Result) FOR Var_Desc IN ([ScaleCalibrateTarget1], [ScaleCalibrateTarget2], [ScaleCalibrateTarget3], [ScaleCalibrateTarget4], [ScaleCalibrateTarget5], [ScaleCalibrateTolerance])) pvt
	WHERE ScaleCalibrateTarget1 IS NOT NULL 
)
 
INSERT INTO @tOutput
SELECT DISTINCT
	StartTimestamp,
	EndTimestamp,
	ScaleDesc,
	convert(varchar(20),convert(decimal(10,3),TargetWeight1)) + ' (' + convert(varchar(20),convert(decimal(10,3),LowerTolWeight1))+'-'+ convert(varchar(20),convert(decimal(10,3),UpperTolWeight1)) + ')' as Target1,
	case when TargetWeight2 = '-1' then 'N/A' else convert(varchar(20),convert(decimal(10,3),TargetWeight2)) + ' (' + convert(varchar(20),convert(decimal(10,3),LowerTolWeight2))+'-'+ convert(varchar(20),convert(decimal(10,3),UpperTolWeight2)) + ')' end as Target2,
	case when TargetWeight3 = '-1' then 'N/A' else convert(varchar(20),convert(decimal(10,3),TargetWeight3)) + ' (' + convert(varchar(20),convert(decimal(10,3),LowerTolWeight3))+'-'+ convert(varchar(20),convert(decimal(10,3),UpperTolWeight3)) + ')' end as Target3,
	case when TargetWeight4 = '-1' then 'N/A' else convert(varchar(20),convert(decimal(10,3),TargetWeight4)) + ' (' + convert(varchar(20),convert(decimal(10,3),LowerTolWeight4))+'-'+ convert(varchar(20),convert(decimal(10,3),UpperTolWeight4)) + ')' end as Target4,
	case when TargetWeight5 = '-1' then 'N/A' else convert(varchar(20),convert(decimal(10,3),TargetWeight5)) + ' (' + convert(varchar(20),convert(decimal(10,3),LowerTolWeight5))+'-'+ convert(varchar(20),convert(decimal(10,3),UpperTolWeight5)) + ')' end as Target5
	--TargetWeight1,
	--LowerTolWeight1,
	--UpperTolWeight1,
	--case when TargetWeight2 = '-1' then null else TargetWeight2 end as TargetWeight2,
	--case when TargetWeight2 = '-1' then null else LowerTolWeight2 end as LowerTolWeight2,
	--case when TargetWeight2 = '-1' then null else UpperTolWeight2 end as UpperTolWeight2,
	--case when TargetWeight3 = '-1' then null else TargetWeight3 end as TargetWeight3,
	--case when TargetWeight3 = '-1' then null else LowerTolWeight3 end as LowerTolWeight3,
	--case when TargetWeight3 = '-1' then null else UpperTolWeight3 end as UpperTolWeight3,
	--case when TargetWeight4 = '-1' then null else TargetWeight4 end as TargetWeight4,
	--case when TargetWeight4 = '-1' then null else LowerTolWeight4 end as LowerTolWeight4,
	--case when TargetWeight4 = '-1' then null else UpperTolWeight4 end as UpperTolWeight4,
	--case when TargetWeight5 = '-1' then null else TargetWeight5 end as TargetWeight5,
	--case when TargetWeight5 = '-1' then null else LowerTolWeight5 end as LowerTolWeight5,
	--case when TargetWeight5 = '-1' then null else UpperTolWeight5 end as UpperTolWeight5
FROM d
WHERE TargetWeight1 >= @MinWeight -- filter out negative target weight
 
SELECT 	ROW_NUMBER() OVER (ORDER BY StartTimestamp) RowNum,
		*
FROM	@tOutput
ORDER BY 	StartTimestamp
 
SET @ErrorCode = 1;
SET @ErrorMessage = 'Success';
 
 
 

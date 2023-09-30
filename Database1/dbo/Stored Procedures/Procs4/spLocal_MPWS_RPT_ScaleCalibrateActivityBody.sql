 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ScaleCalibrateActivityBody
	
	Date			Version		Build	Author  
	27-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development
	28-Jul-2016		001			002		Susan Lee				Added RowNum to input and output.  
 	26-Sep-2017		001			003		Susan Lee (GE Digital)	Updated UOM, User & Verifier
	08-Nov-2017		001			004		Susan Lee (GE Digital)	Filter negative weight rows
	30-Nov-2017		001			005		Susan Lee (GE Digital)	Replace -1 with blank (means weighment was not required)
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ScaleCalibrateActivityBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 1, 6079, '20170101', '20171201'
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ScaleCalibrateActivityBody]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@RowNum			INT,
	@ScaleId		INT,
	@StartTime		DATETIME,
	@EndTime		DATETIME
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @UOM VARCHAR(10),
		@MinWeight float = 0.000 

-- Get scale UOM
SELECT @UOM = CAST(peec.Value AS VARCHAR) 
FROM dbo.EquipmentClass_EquipmentObject eeo
	JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
	JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
	JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
	AND peec.Name = 'WeightUOM'
	AND pu.PU_Id = @ScaleId 
 
;WITH d AS
(
	SELECT
 
		Result_On [Timestamp],
		ScaleCalibrateZeroWeight ZeroWeight,
		ScaleCalibrateWeight1 Weight1,
		ScaleCalibrateWeight2 Weight2,
		ScaleCalibrateWeight3 Weight3,
		ScaleCalibrateWeight4 Weight4,
		ScaleCalibrateWeight5 Weight5,
		@UOM UOM,
		ScaleCalibratePassed PassFail,
		EntryUser				UserName,
		SignatureUser			VerifierName
	FROM (
			SELECT
				t.Result_On,
				v.Var_Desc,
				t.Result,
				u.Username	EntryUser,
				vu.Username SignatureUser
			FROM dbo.Tests t
				JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
				JOIN dbo.Users_Base		u	ON u.User_Id = t.Entry_By
				LEFT JOIN dbo.Users_Base		vu	ON vu.User_Id	= t.Second_User_Id
			WHERE t.Result_On BETWEEN @StartTime AND @EndTime
				AND v.PU_Id = @ScaleId
				AND v.Var_Desc IN ('ScaleCalibrateZeroWeight', 'ScaleCalibrateWeight1', 'ScaleCalibrateWeight2', 'ScaleCalibrateWeight3', 
									'ScaleCalibrateWeight4', 'ScaleCalibrateWeight5', 'ScaleCalibratePassed')
		)a
		PIVOT (MAX(Result) FOR Var_Desc IN ([ScaleCalibrateZeroWeight], [ScaleCalibrateWeight1], [ScaleCalibrateWeight2], [ScaleCalibrateWeight3], 
											[ScaleCalibrateWeight4], [ScaleCalibrateWeight5], [ScaleCalibratePassed])) pvt
	WHERE ScaleCalibrateWeight1 IS NOT NULL 
)
SELECT
	--@RowNum  RowNum,
	[Timestamp],
	ZeroWeight,
	Weight1,
	case Weight2 when '-1' then 'N/A' else Weight2 end as Weight2,
	case Weight3 when '-1' then 'N/A' else Weight3 end as Weight3,
	case Weight4 when '-1' then 'N/A' else Weight4 end as Weight4,
	case Weight5 when '-1' then 'N/A' else Weight5 end as Weight5,
	UOM,
	PassFail,
	UserName,
	VerifierName
FROM d
WHERE Weight1 >= @MinWeight -- filter out negative target weight

SET @ErrorCode = 1;
SET @ErrorMessage = 'Success';


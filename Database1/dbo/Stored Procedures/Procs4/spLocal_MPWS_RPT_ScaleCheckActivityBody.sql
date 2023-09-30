 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ScaleCheckActivityBody
	
	Date			Version		Build	Author  
	27-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development
	26-Sep-2017		001			002		Susan Lee (GE Digital)	Updated UOM, User & Verifier
	08-Nov-2017		001			002		Susan Lee (GE Digital)	Filter negative weights
	 
test
 select pu_id, pu_desc from prod_units where pu_desc like 'PW01DS%' --5632,5633,5641,5639

DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ScaleCheckActivityBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 5632, '20170801', '20170930'
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ScaleCheckActivityBody]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ScaleId		INT,
	@StartTime		DATETIME,
	@EndTime		DATETIME
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @UOM VARCHAR(10),
		@MinWeight FLOAT = 0.000

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
		Result_On				[Timestamp],
		ScaleCheckZeroWeight	ZeroWeight,
		ScaleCheckWeight		CheckWeight,
		@UOM					UOM,
		ScaleCheckPassed		PassFail,
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
				JOIN dbo.Variables_Base v	ON t.Var_Id = v.Var_Id
				JOIN dbo.Users_Base		u	ON u.User_Id = t.Entry_By
				LEFT JOIN dbo.Users_Base		vu	ON vu.User_Id	= t.Second_User_Id
			WHERE t.Result_On BETWEEN @StartTime AND @EndTime
				AND v.PU_Id = @ScaleId
				AND v.Var_Desc IN ('ScaleCheckWeight', 'ScaleCheckZeroWeight', 'ScaleCheckPassed')
		)a
		PIVOT (MAX(Result) FOR Var_Desc IN ([ScaleCheckWeight], [ScaleCheckZeroWeight], [ScaleCheckPassed])) pvt
	WHERE ScaleCheckWeight IS NOT NULL
)
SELECT
	[Timestamp],
	CAST(ZeroWeight AS DECIMAL(10,3)) as ZeroWeight,
	CAST(CheckWeight AS DECIMAL(10,3)) as CheckWeight,
	UOM,
	PassFail,
	UserName,
	VerifierName
FROM d
WHERE ZeroWeight >= @MinWeight
	
SET @ErrorCode = 1;
SET @ErrorMessage = 'Success';


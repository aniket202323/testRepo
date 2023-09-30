 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_PerformCheckCalibrateScale
	
	Date			Version		Build	Author  
	26-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development	
	19-May-2017		001			002     Susan Lee (GE Digital)	Changed select PassFail to select MIN(PassFail) to determine scale check status
	27-Sep-2017		001			003		Susan Lee (GE Digital)	Added second user Id
	08-Nov-2017		001			004		Susan Lee (GE Digital)	Change second user to name.
	28-Nov-2017		001			005		Susan Lee (GE Digital)	Update values to -1 if not performed and update either scale check OR scale calibrate

test
 
DECLARE @ReturnStatus INT, @ReturnMessage VARCHAR(255)
EXEC dbo.spLocal_MPWS_DISP_PerformCheckCalibrateScale @ReturnStatus OUTPUT, @ReturnMessage OUTPUT, 'PW01DS01-Scale01', 1, 'lee.s.3',	null,null,0,20,40,60,80,100,			null,20,40,60,80,100,			null,2
EXEC dbo.spLocal_MPWS_DISP_PerformCheckCalibrateScale @ReturnStatus OUTPUT, @ReturnMessage OUTPUT, 'PW01DS01-Scale01', 1, 1,	0,50,null,null,null,null,null,null, 	50,null,null,null,null,null,	4,null
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_DISP_PerformCheckCalibrateScale]
	@ErrorCode					INT				OUTPUT,
	@ErrorMessage				VARCHAR(500)	OUTPUT,

	@ScaleDesc					VARCHAR(50),
 
	@UserId						INT,
	@ESigId						INT,
	@VerifierName				VARCHAR(50),
	@ScaleCheckZeroWeight		FLOAT,
	@CheckWeight				FLOAT,	-- Measured check weight - null/blank/notNumeric if not check
	@ScaleCalibrateZeroWeight	FLOAT,
	@CalibrateWeight1			FLOAT,	-- Measured calibration weights 1-5 - null/blank/notNumeric if not calibration
	@CalibrateWeight2			FLOAT,
	@CalibrateWeight3			FLOAT,
	@CalibrateWeight4			FLOAT,
	@CalibrateWeight5			FLOAT,
 
	@CheckTarget				FLOAT,	-- sending back targets used on the screens in case they change in the database during the check/calib
	@CalibrateTarget1			FLOAT,	-- do not look these up
	@CalibrateTarget2			FLOAT,
	@CalibrateTarget3			FLOAT,
	@CalibrateTarget4			FLOAT,
	@CalibrateTarget5			FLOAT,
 
	@CheckTolerance				FLOAT ,	-- same reason as for targets
	@CalibrateTolerance			FLOAT ,
	@WeightCount				INT 

--WITH ENCRYPTION
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

 
DECLARE
	@VerifierId			INT,
	@Timestamp				DATETIME = GETDATE(),
	@CheckCalibrateClass	VARCHAR(50),
	@Row					INT,
	@MaxRow					INT,
	@VarId					INT,
	@VarResult				VARCHAR(25), 
	@VarDesc				VARCHAR(50),
	@PUId					INT,
	@TestId					INT,
	@PassFail				VARCHAR(5),
	@VarType				VARCHAR(15),
	@RC						INT;
 
DECLARE @ScaleData TABLE
(
	Id			INT IDENTITY,	-- used for looping
	WeightNum	INT,	
	VarId		INT,
	VarDesc		VARCHAR(50),
	VarValue	VARCHAR(25),	-- varchar(25) for numbers and pass/fail for writing to dbo.Tests
	LimitLow	FLOAT,
	LimitHigh	FLOAT,
	PassFail	VARCHAR(5)
)
 
-- get the verifier ID
IF @VerifierName IS NOT NULL AND @VerifierName <> ''
BEGIN
	SELECT	@VerifierId =	User_Id
	FROM	dbo.Users_Base	WITH (NOLOCK)
	WHERE	Username = @VerifierName
END

-- use a table for the var/results so we can loop instead of like 20 exec's
INSERT @ScaleData (WeightNum, VarDesc, VarValue, LimitLow, LimitHigh)
	VALUES
	(0,'ScaleCheckZeroWeight',		@ScaleCheckZeroWeight,		0.0, 0.0),
	(1,'ScaleCheckWeight',			@CheckWeight,				@CheckTarget * (100.0 - @CheckTolerance) / 100.0, @CheckTarget * (100.0 + @CheckTolerance) / 100.0),
	
	(0,'ScaleCalibrateZeroWeight',	@ScaleCalibrateZeroWeight,	0.0, 0.0),
	(1,'ScaleCalibrateWeight1',		@CalibrateWeight1,			@CalibrateTarget1 * (100.0 - @CalibrateTolerance) / 100.0, @CalibrateTarget1 * (100.0 + @CalibrateTolerance) / 100.0),
	(2,'ScaleCalibrateWeight2',		@CalibrateWeight2,			@CalibrateTarget2 * (100.0 - @CalibrateTolerance) / 100.0, @CalibrateTarget2 * (100.0 + @CalibrateTolerance) / 100.0),
	(3,'ScaleCalibrateWeight3',		@CalibrateWeight3,			@CalibrateTarget3 * (100.0 - @CalibrateTolerance) / 100.0, @CalibrateTarget3 * (100.0 + @CalibrateTolerance) / 100.0),
	(4,'ScaleCalibrateWeight4',		@CalibrateWeight4,			@CalibrateTarget4 * (100.0 - @CalibrateTolerance) / 100.0, @CalibrateTarget4 * (100.0 + @CalibrateTolerance) / 100.0),
	(5,'ScaleCalibrateWeight5',		@CalibrateWeight5,			@CalibrateTarget5 * (100.0 - @CalibrateTolerance) / 100.0, @CalibrateTarget5 * (100.0 + @CalibrateTolerance) / 100.0),
	
	(0,'ScaleCheckTarget',			@CheckTarget,		NULL, NULL),
	(1,'ScaleCalibrateTarget1',		@CalibrateTarget1,	NULL, NULL),
	(2,'ScaleCalibrateTarget2',		@CalibrateTarget2,	NULL, NULL),
	(3,'ScaleCalibrateTarget3',		@CalibrateTarget3,	NULL, NULL),
	(4,'ScaleCalibrateTarget4',		@CalibrateTarget4,	NULL, NULL),
	(5,'ScaleCalibrateTarget5',		@CalibrateTarget5,	NULL, NULL),
	
	(-1,'ScaleCheckTolerance',			@CheckTolerance,		NULL, NULL),
	(-1,'ScaleCalibrateTolerance',		@CalibrateTolerance,	NULL, NULL),
	
	(-1,'ScaleCalibratePassed',		NULL, NULL,	NULL),
	(-1,'ScaleCheckPassed',			NULL, NULL,	NULL);


-- update unperformed weights to -1, for example if doing 3 calibrations, target and weights ofr 4 and 5 will be -1
UPDATE  @ScaleData
SET		VarValue = -1,
		LimitLow = NULL,
		LimitHigh = NULL
WHERE	WeightNum > @WeightCount

-- get the var_id's
UPDATE sd
	SET VarId = v.Var_Id
FROM @ScaleData sd
	JOIN dbo.Variables_Base v ON v.Var_Desc = sd.VarDesc
	JOIN dbo.PU_Groups pug ON pug.PUG_Id = v.PUG_Id
	JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = v.PU_Id
WHERE pug.PUG_Desc = 'ScaleCalibrate'
	AND pu.PU_Desc = @ScaleDesc;
 
-- determine pass/fail for relevant rows
UPDATE @ScaleData
	SET PassFail = CASE WHEN VarValue BETWEEN LimitLow AND LimitHigh THEN 'Pass' ELSE 'Fail' END
	WHERE LimitLow IS NOT NULL;

IF @CheckWeight IS NOT NULL AND @CheckWeight >= 0.000
BEGIN
	SET @VarType = 'ScaleCheck'
	SET @PassFail = (SELECT MIN(PassFail) FROM @ScaleData WHERE VarDesc LIKE 'ScaleCheck%Weight');
		
	UPDATE @ScaleData
		SET VarValue = @PassFail
		WHERE VarDesc = 'ScaleCheckPassed';
 
	UPDATE peec
		SET peec.Value = CASE WHEN @PassFail = 'Pass' THEN 'True' ELSE 'False' END
		FROM dbo.EquipmentClass_EquipmentObject eeo
			JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
			JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
			JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
		WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
			AND pu.PU_Desc = @ScaleDesc
			AND peec.Name ='LastCheckPassed'
 
	UPDATE peec
		SET peec.Value = @Timestamp
		FROM dbo.EquipmentClass_EquipmentObject eeo
			JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
			JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
			JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
		WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
			AND pu.PU_Desc = @ScaleDesc
			AND peec.Name = 'LastCheckTime'
	
END
ELSE
BEGIN
 
	SET @VarType = 'ScaleCalibrate'
	SET @PassFail = (SELECT MIN(PassFail) FROM @ScaleData WHERE VarDesc LIKE 'ScaleCalibrate%Weight%' AND PassFail IS NOT NULL);

	UPDATE @ScaleData
		SET VarValue = @PassFail
		WHERE VarDesc = 'ScaleCalibratePassed';
		
	UPDATE peec
		SET peec.Value = CASE WHEN @PassFail = 'Pass' THEN 'True' ELSE 'False' END
		FROM dbo.EquipmentClass_EquipmentObject eeo
			JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
			JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
			JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
		WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
			AND pu.PU_Desc = @ScaleDesc
			AND peec.Name ='LastCalibratePassed'
 
	UPDATE peec
		SET peec.Value = @Timestamp
		FROM dbo.EquipmentClass_EquipmentObject eeo
			JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
			JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
			JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
		WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
			AND pu.PU_Desc = @ScaleDesc
			AND peec.Name = 'LastCalibrateTime'
		
END;
 
-- write out var results
SELECT
	@Row = 1,
	@MaxRow = (SELECT MAX(Id) FROM @ScaleData),
	@PUId = (SELECT pu.PU_Id FROM dbo.Prod_Units_Base pu WHERE pu.PU_Desc = @ScaleDesc);
 
WHILE @Row <= @MaxRow
BEGIN
 
	SELECT 
		@VarId		= VarId,
		@VarResult	= VarValue,
		@VarDesc	= VarDesc
	FROM @ScaleData
	WHERE Id = @Row
	
	IF (@VarDesc LIKE @VarType + '%')
	BEGIN
		
		EXEC	@RC	=	dbo.spServer_DBMgrUpdTest2

				@VarId		,			-- @var_Id			INT,
				@UserId,				-- @User_Id			INT,
				0,						-- @Canceled		INT
				@VarResult,				-- @New_Result		VARCHAR(25)
				@Timestamp,				-- @Result_On		DATETIME
				0,						-- @TransNum		INT
				NULL,					-- @CommentId		INT
				NULL,					-- @ArrayId			INT
				NULL,					-- @EventId			INT			-- time based
				@PUId,					-- @PUId			INT
				@TestId		OUTPUT,		-- @Test_Id			INT
				NULL,					-- @Entry_ON		DATETIME
				@VerifierId					-- @SecondUserId	INT
	END

	SET @Row += 1;
	
END;
 
SELECT
	@ErrorCode = 1,
	@ErrorMessage = 'Success';
	

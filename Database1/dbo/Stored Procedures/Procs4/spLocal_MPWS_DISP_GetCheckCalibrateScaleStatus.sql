 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_GetCheckCalibrateScaleStatus
	
	Date			Version		Build	Author  
	27-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development	
	
test
 
DECLARE @ReturnStatus INT, @ReturnMessage VARCHAR(255)
exec spLocal_MPWS_DISP_GetCheckCalibrateScaleStatus  @ReturnStatus OUTPUT, @ReturnMessage OUTPUT, 'PW01DS01-Scale01'
exec spLocal_MPWS_DISP_GetCheckCalibrateScaleStatus  @ReturnStatus OUTPUT, @ReturnMessage OUTPUT, 'PW01DS01-Scale02'
SELECT @ReturnStatus, @ReturnMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_DISP_GetCheckCalibrateScaleStatus]
	@ErrorCode				INT				OUTPUT,
	@ErrorMessage			VARCHAR(500)	OUTPUT,
 
	@ScaleDesc				VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
 
DECLARE
	@CheckCalibrateClass	VARCHAR(50),
	@LastCalibratePassed	VARCHAR(5),
	@LastCalibrateTime		DATETIME,
	@LastCheckPassed		VARCHAR(5),
	@LastCheckTime			DATETIME;
	
SELECT
	@CheckCalibrateClass	= CheckCalibrateClass,
	@LastCalibratePassed	= LastCalibratePassed,
	@LastCalibrateTime		= LastCalibrateTime,
	@LastCheckPassed		= LastCheckPassed,
	@LastCheckTime			= LastCheckTime
FROM (
		SELECT
			peec.Name,
			CAST(peec.Value AS VARCHAR(50)) Value
		FROM dbo.EquipmentClass_EquipmentObject eeo
			JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
			JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
			JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
		WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
			AND peec.Name IN ('CheckCalibrateClass', 'LastCalibratePassed', 'LastCalibrateTime', 'LastCheckPassed', 'LastCheckTime')
			AND pu.PU_Desc = @ScaleDesc
	) a
	PIVOT (MAX(Value) FOR Name IN ([CheckCalibrateClass], [LastCalibratePassed], [LastCalibrateTime], [LastCheckPassed], [LastCheckTime])) pvt
 
SELECT
	CASE WHEN @LastCheckPassed = 'True' THEN 'Pass' ELSE 'Fail' END LastCheckPassed,
	@LastCheckTime LastCheckTime,
	CheckFrequency,
	CASE WHEN @LastCalibratePassed = 'True' THEN 'Pass' ELSE 'Fail' END LastCalibratePassed,
	@LastCalibrateTime LastCalibrateTime,
	CalibrateFrequency
FROM (
		SELECT ec.EquipmentClassName, pec.PropertyName, pec.Value
		FROM dbo.EquipmentClass ec
			LEFT JOIN dbo.Property_EquipmentClass pec ON ec.EquipmentClassName = pec.EquipmentClassName
		WHERE ec.EquipmentClassName = @CheckCalibrateClass
	) a
	PIVOT (MAX(Value) FOR PropertyName IN ([CalibrateFrequency], [CheckFrequency])) pvt
 
IF @@ROWCOUNT > 0
BEGIN
	SELECT
		@ErrorCode = 1,
		@ErrorMessage = 'Success';
END
ELSE
BEGIN
	IF @CheckCalibrateClass IS NULL
	BEGIN
		SELECT
			@ErrorCode = -2,
			@ErrorMessage = 'CheckCalibrateClass not found for scale ' + @ScaleDesc;
	END
	ELSE
	BEGIN
		SELECT
			@ErrorCode = -1,
			@ErrorMessage = 'No data found';
	END;
END;

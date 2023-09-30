 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DISP_GetCheckCalibrateScaleProperties
	
	Date			Version		Build	Author  
	26-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development	
	
test
 
DECLARE @ReturnStatus INT, @ReturnMessage VARCHAR(255)
exec spLocal_MPWS_DISP_GetCheckCalibrateScaleProperties  @ReturnStatus OUTPUT, @ReturnMessage OUTPUT, 'PW01DS01-Scale01'
exec spLocal_MPWS_DISP_GetCheckCalibrateScaleProperties  @ReturnStatus OUTPUT, @ReturnMessage OUTPUT, 'PW01DS01-Scale02'
SELECT @ReturnStatus, @ReturnMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_DISP_GetCheckCalibrateScaleProperties]
	@ErrorCode				INT				OUTPUT,
	@ErrorMessage			VARCHAR(500)	OUTPUT,
 
	@ScaleDesc				VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
 
DECLARE
	@CheckCalibrateClass	VARCHAR(50);
	
SELECT
	@CheckCalibrateClass = SUBSTRING(CAST(peec.Value AS VARCHAR(MAX)), 1, 50)
FROM dbo.EquipmentClass_EquipmentObject eeo
	JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
	JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
	JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
	AND peec.Name = 'CheckCalibrateClass'
	AND pu.PU_Desc = @ScaleDesc
 
SELECT
	CalibrateFrequency, CalibrateInstructions, CalibrateSOPFile, 
	CalibrateTolerance, CalibrateWeightCount,
	CalibrateWeightTarget1, CalibrateWeightTarget2, CalibrateWeightTarget3, CalibrateWeightTarget4, CalibrateWeightTarget5,
	CheckCalibrateUOM, CheckFrequency, CheckInstructions, CheckSOPFile, CheckTolerance1, CheckWeightTarget
FROM (
		SELECT ec.EquipmentClassName, pec.PropertyName, SUBSTRING(CAST(pec.Value AS VARCHAR(MAX)), 1, 255) Value
		FROM dbo.EquipmentClass ec
			LEFT JOIN dbo.Property_EquipmentClass pec ON ec.EquipmentClassName = pec.EquipmentClassName
		WHERE ec.EquipmentClassName = @CheckCalibrateClass
	) a
	PIVOT (MAX(Value) FOR PropertyName IN (	[CalibrateFrequency], [CalibrateInstructions], [CalibrateSOPFile], 
											[CalibrateTolerance], [CalibrateWeightCount],
											[CalibrateWeightTarget1], [CalibrateWeightTarget2], [CalibrateWeightTarget3], [CalibrateWeightTarget4], [CalibrateWeightTarget5],
											[CheckCalibrateUOM], [CheckFrequency], [CheckInstructions], [CheckSOPFile], [CheckTolerance1], [CheckWeightTarget])) pvt
 
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

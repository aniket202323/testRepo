 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DASH_GetPreweighAreas
	
	Get a list of preweigh areas
	
	Date			Version		Build	Author  
	08-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DASH_GetPreweighAreas @ErrorCode OUTPUT, @ErrorMessage OUTPUT
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_DASH_GetPreweighAreas]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT	
 
AS
 
SET NOCOUNT ON;
 
DECLARE @TABLE TABLE
(
	ExecutionPath INT,
	PreweighAreaName VARCHAR(100)
)
 
BEGIN TRY
 
	INSERT INTO @TABLE
	SELECT
		pep.Path_Id ExecutionPath,
		CONVERT(VARCHAR(100),peec.Value)AS PreweighAreaName
	FROM dbo.Property_Equipment_EquipmentClass peec
		JOIN dbo.EquipmentClass_EquipmentObject eeo ON eeo.EquipmentId = peec.EquipmentId
		LEFT JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
		LEFT JOIN dbo.Prod_Lines_Base pl ON pas.PL_Id = pl.PL_Id
		LEFT JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pl.PL_Id
	WHERE peec.Name	= 'Security Group'
		AND eeo.EquipmentClassName =  'Pre-Weigh - Area'
	
	SELECT
		ExecutionPath,
		PreweighAreaName
	FROM @TABLE
	
	IF @@ROWCOUNT > 0
	BEGIN
		SELECT 
			@ErrorCode = 1,
			@ErrorMessage = 'Success';
	END
	ELSE
	BEGIN
		SELECT 
			@ErrorCode = -1,
			@ErrorMessage = 'No Preweigh Areas Found';
	END;
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 

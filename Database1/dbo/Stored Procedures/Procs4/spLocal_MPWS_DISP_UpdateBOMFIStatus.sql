 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_UpdateBOMFIStatus]
		@BOMFIId			INT,
		@NewStatus			VARCHAR(255),
		@ValidStatusIdMask	VARCHAR(2000)		-- (14, 16)
AS	
 
-- test params
--declare
--		@BOMFIId			INT = 6466,
--		@NewStatus			VARCHAR(255) = '17',-- 'Dispensing',
--		@ValidStatusIdMask	VARCHAR(2000) = '15,17'--'Dispensing,Released'	
 
-------------------------------------------------------------------------------
-- Update BOMFormulationStatusId UDP for BOMFI
/*
exec [dbo].[spLocal_MPWS_DISP_UpdateBOMFIStatus] 6466, 'Dispensing', 'Dispensing,Released'
 
*/
-- Date         Version Build Author  
-- 23-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development
-- 29-Aug-2017  001     002   Susan Lee (GE Digital) Allow the NewStatus and ValidStatusIdMask
--													 to be Status_Id or Status_Desc		
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
SET NOCOUNT ON;
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
 
DECLARE	@tValidBOMFIStatus	TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT									NULL,
	StatusDesc				VARCHAR(255)						NULL
)
 
DECLARE	@BOMFIStatusId		INT,
		@NewStatusId		INT
-------------------------------------------------------------------------------
--  Parse Status Mask
-------------------------------------------------------------------------------
-- Both @NewStatus & @ValidStatusIdMask must be Status_Id or both must be Status_Desc
IF (ISNUMERIC(@NewStatus) = 1)
BEGIN
	INSERT	@tValidBOMFIStatus (StatusId)
			SELECT	*
			FROM	dbo.fnLocal_CmnParseListLong(@ValidStatusIdMask,',')
 
	-- was passed in Id as the new status		
	SET @NewStatusId = @NewStatus		
END
ELSE
BEGIN
	INSERT	@tValidBOMFIStatus (StatusDesc)
			SELECT	*
			FROM	dbo.fnLocal_CmnParseListLong(@ValidStatusIdMask,',')		
 
	--get status id of passed in status desc
	UPDATE t
	SET StatusId = pps.PP_Status_Id
	FROM @tValidBOMFIStatus t
	JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Desc = t.StatusDesc
 
	-- get status id of @NewStatus
	SELECT @NewStatusId = PP_Status_Id
	FROM	dbo.Production_Plan_Statuses
	WHERE	PP_Status_Desc = @NewStatus
END
 
-------------------------------------------------------------------------------
--  Get the BOM Formulation Id status value
-------------------------------------------------------------------------------
SELECT	@BOMFIStatusId				= TFV.Value
		FROM	dbo.Table_Fields_Values TFV					WITH (NOLOCK)
		JOIN	dbo.Table_Fields TF							WITH (NOLOCK)
		ON		TFV.KeyId			= @BOMFIId
		AND		TFV.TableId			= 28
		AND		TFV.Table_Field_Id	= TF.Table_Field_Id
		AND		TF.Table_Field_Desc	= 'BOMItemStatus'			
	
IF		NOT EXISTS (SELECT	StatusId
							FROM	@tValidBOMFIStatus 
							WHERE	StatusId = @BOMFIStatusId)
 
BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'Bill Of Material Formulation Status cannot be updated')
END
ELSE
BEGIN
									
		-------------------------------------------------------------------------------
		-- Update the BOMItemStatus UDP for the BOMFI to dispensing
		-------------------------------------------------------------------------------
		UPDATE	TFV
				SET	TFV.Value = @NewStatusId
				FROM	dbo.Table_Fields_Values TFV					WITH (NOLOCK)
				JOIN	dbo.Table_Fields TF							WITH (NOLOCK)
				ON		TFV.KeyId			= @BOMFIId
				AND		TFV.TableId			= 28
				AND		TFV.Table_Field_Id	= TF.Table_Field_Id
				AND		TF.Table_Field_Desc	= 'BOMItemStatus'		
				
		IF		@@ROWCOUNT = 0
				INSERT	@tFeedback (ErrorCode, ErrorMessage)
						VALUES (-2, 'Bill Of Material Formulation Status cannot be updated')
		ELSE
		
				INSERT	@tFeedback (ErrorCode, ErrorMessage)
						VALUES (1, 'Success')
						
END						
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
 
 
 
 
 
 

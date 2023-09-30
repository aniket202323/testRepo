 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetStatusByProductionUnit]
		@PUId			INT	,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT,
		@AllFlag		INT  =0 
		
AS	
-------------------------------------------------------------------------------
-- Get status associated with the passed in production unit
/*
exec  spLocal_MPWS_GENL_GetStatusByProductionUnit 3379,'','',1
*/
-- Date         Version Build Author  
-- 14-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ProdStatusId			INT									NULL,
	ProdStatusDesc			VARCHAR(255)						NULL,
	DefaultStatus			BIT
)
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Find products associated with the passed PU
-------------------------------------------------------------------------------		
INSERT	@tOutput	(ProdStatusId, ProdStatusDesc, DefaultStatus)
		SELECT	PS.ProdStatus_Id, PS.ProdStatus_Desc, COALESCE(PR.Is_Default_Status, 0)
				FROM	dbo.Production_Status PS		WITH (NOLOCK)
				JOIN	dbo.PrdExec_Status PR			WITH (NOLOCK)
				ON		PS.ProdStatus_Id	= PR.Valid_Status
				AND		PR.PU_Id			= @PUId
				ORDER
				BY		PS.ProdStatus_Desc
 
IF		@@ROWCOUNT	> 0
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (1, 'Success')
ELSE
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'No status was found for production unit: ' + CONVERT(VARCHAR(25), @PUId)
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'No status was found for production unit: ' + CONVERT(VARCHAR(25), @PUId))
				
-------------------------------------------------------------------------------
		-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
	IF (@AllFlag =1)
		BEGIN						
			INSERT	@tOutput (ProdStatusId,ProdStatusDesc)
			VALUES (0,'ALL')	
		END				
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	Id						Id,
		ProdStatusId			ProdStatusId,
		ProdStatusDesc			ProdStatusDesc,
		DefaultStatus			DefaultStatus
		FROM	@tOutput
		ORDER
		BY		Id DESC
 
 
 
 
 
 

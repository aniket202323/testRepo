 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetPOStatusList]
		@PathId			INT,
		@AllFlag		INT=0
AS	
-------------------------------------------------------------------------------
-- Get valid PO status for passed in execution path
/*
exec  spLocal_MPWS_PLAN_GetPOStatusList 29
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
				
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PPStatusId				INT									NULL,
	PPStatusDesc			VARCHAR(255)						NULL,
	IsDefault				BIT									NOT NULL DEFAULT 0
)	
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Get the configured status transitions for the passed in path and get their
-- distinct 'FROM' status 
-------------------------------------------------------------------------------	
INSERT	@tOutput (PPStatusId, PPStatusDesc, IsDefault)
		SELECT	DISTINCT PPS.From_PPStatus_Id, NULL, 0
				FROM	dbo.Production_Plan_Status PPS		WITH (NOLOCK)
				WHERE	PPS.Path_Id			= @PathId
-------------------------------------------------------------------------------
-- Get the configured status transitions for the passed in path and get their
-- distinct 'TO' status 
-------------------------------------------------------------------------------					
INSERT	@tOutput (PPStatusId, PPStatusDesc, IsDefault)
		SELECT	DISTINCT PPS.To_PPStatus_Id, NULL, 0
				FROM	dbo.Production_Plan_Status PPS		WITH (NOLOCK)
				LEFT
				JOIN	@tOutput T
				ON		PPS.To_PPStatus_Id = T.PPStatusId
				WHERE	T.PPStatusId		IS NULL	
				AND		PPS.Path_Id			= @PathId
 
IF		EXISTS (SELECT Id
				FROM	@tOutput)
BEGIN
		-------------------------------------------------------------------------------
		-- Get description for status
		-------------------------------------------------------------------------------					
		UPDATE	T
				SET		T.PPStatusDesc  = PPS.PP_Status_Desc
						FROM	@tOutput T
						JOIN	dbo.Production_Plan_Statuses PPS	WITH (NOLOCK)
						ON		PPS.PP_Status_Id	= T.PPStatusId
						
  
END
ELSE
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'Status not configured for execution path: ' 
						+ CONVERT(VARCHAR(10), COALESCE(@PathId, -1)))
						
-------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
		IF (@AllFlag =1)
		BEGIN				
		INSERT	@tOutput (PPStatusId,PPStatusDesc)
				VALUES (0,'ALL')						
		END
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
--SELECT	Id						Id,
--		PPStatusId				PPStatusId,
--		PPStatusDesc			PPStatusDesc,
--		IsDefault				IsDefault
--		FROM	@tOutput t
--			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(PPStatusId, 'PreWeigh Order', 'Production_Plan_Statuses') pOrder
--		WHERE pOrder.Value > 0
--		ORDER
--		BY		pOrder.Value
 
--SELECT	
--	ROW_NUMBER() OVER (ORDER BY pOrder.Value) Id,
--	PP_Status_Id	PPStatusId,
--	PP_Status_Desc	PPStatusDesc,
--	0				IsDefault
--FROM dbo.Production_Plan_Statuses
--	OUTER APPLY dbo.fnLocal_MPWS_GetUDP(PP_Status_Id, 'PreWeigh Order', 'Production_Plan_Statuses') pOrder
--WHERE ISNULL(pOrder.Value, -1) > 0
--ORDER BY pOrder.Value
 
 
SELECT	
	ROW_NUMBER() OVER (ORDER BY pOrder.Value) Id,
	PP_Status_Id	PPStatusId,
	PP_Status_Desc	PPStatusDesc,
	0				IsDefault
FROM dbo.Production_Plan_Statuses
	OUTER APPLY dbo.fnLocal_MPWS_GetUDP(PP_Status_Id, 'PreWeigh Order', 'Production_Plan_Statuses') pOrder
WHERE ISNULL(pOrder.Value, -1) > 0
AND PP_Status_Desc not in ('Complete','Cancelled')
ORDER BY pOrder.Value
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_PLAN_GetPOStatusList] TO [public]
 
 
 

 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetProductionPlanStatusId]
		@StatusDesc			VARCHAR(25)
AS	
-------------------------------------------------------------------------------
-- Get statusId for Passed StatusDescription
/*
exec  spLocal_MPWS_GENL_GetProductionPlanStatusId 'Released'
*/
-- Date         Version Build Author  
-- 29-July-2016	001     001   Chris Donnelly (GE Digital)  Initial development	
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
	StatusId				INT									NULL,
	StatusDesc				VARCHAR(255)						NULL
)	
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Get the Status ID frm the Description
-------------------------------------------------------------------------------	
INSERT	@tOutput (StatusId, StatusDesc)
	SELECT 
			pps.PP_Status_Id,
			pps.PP_Status_Desc 
		FROM [Production_Plan_Statuses] pps 
		WHERE pps.PP_Status_Desc = @StatusDesc
						
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	--Id					Id,
		StatusId			StatusId,
		StatusDesc			StatusDesc
		FROM	@tOutput
		ORDER
		BY		StatusDesc
 
 
 
 
 
 
 

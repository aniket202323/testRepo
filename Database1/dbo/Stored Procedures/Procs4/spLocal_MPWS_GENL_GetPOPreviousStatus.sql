 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetPOPreviousStatus]
		@PP_Id			INT
AS	
-------------------------------------------------------------------------------
-- Get Previous Prod Order Status for the passed PP_Id
/*
exec  spLocal_MPWS_GENL_GetPOPreviousStatus 390806
*/
-- Date         Version Build Author  
-- 20-Jun-2016	001     001   Chris Donnelly (GE Digital)  Initial development	
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
-- Get the configured status transitions for the passed in path and get their
-- distinct 'FROM' status 
-------------------------------------------------------------------------------	
INSERT	@tOutput (StatusId, StatusDesc)
select Top 1
		pph.pp_status_id ,
		ps.PP_Status_Desc
	from 
		Production_Plan_History pph
		JOIN dbo.Production_Plan_Statuses ps on ps.PP_Status_Id = pph.PP_Status_Id
	where 
		pph.pp_id = @PP_Id 
			and ps.PP_Status_Desc <> 'PreWeigh Hold'
	order by 
		pph.Entry_On desc
						
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	Id					Id,
		StatusId			StatusId,
		StatusDesc			StatusDesc
		FROM	@tOutput
 
 
 
 

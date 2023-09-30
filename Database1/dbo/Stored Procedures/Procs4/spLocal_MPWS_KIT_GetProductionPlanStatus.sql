 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetProductionPlanStatus]
		@ProdStatus_Id			INT	
		
AS	
-------------------------------------------------------------------------------
-- Get Production Status of passed in ProdStatus_Id
/*
spLocal_MPWS_KIT_GetProductionPlanStatus 14
*/
-- Date         Version Build Author  
-- 17-JUN-2016  001     001   Chris Donnelly (GE Digital)  Initial development	
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE @ProductionStatus VarChar(50)
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
-------------------------------------------------------------------------------
--  Get Status Description for code passed
-------------------------------------------------------------------------------
SELECT @ProductionStatus = ProdStatus_Desc 
	FROM 
		Production_Status ps
	WHERE 
		ps.ProdStatus_Id = @ProdStatus_Id
		
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
IF LEN(@ProductionStatus) > 1
	BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (1, 'Success')
	END
ELSE
	BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'Status ID Not Found for this Event')
	END
 
--Return Status
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
--Return Data
SELECT 1 as Id, @ProductionStatus as ProductionStatus 
		
 
 
 

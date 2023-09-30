 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetProductionStatus]
		@CarrierEventId			INT	,
		@CarrierStatusId		INT
		
AS	
-------------------------------------------------------------------------------
-- Set Production Status of Event from passed in Status Id
/*
spLocal_MPWS_KIT_GetProductionStatus 5739014, 24
*/
-- Date         Version Build Author  
-- 06-JUN-2016  001     001   Chris Donnelly (GE Digital)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE @ProductionStatus varchar(255)
 
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
	FROM dbo.[Events] e
		Join Prod_Units pu on pu.PU_ID = e.PU_Id
		JOIN dbo.PrdExec_Status px	WITH (NOLOCK) on pu.PU_Id = px.PU_Id
		JOIN Production_Status ps on ps.ProdStatus_Id = px.Valid_Status
	WHERE e.Event_Id = @CarrierEventId
		AND ps.ProdStatus_Id = @CarrierStatusId
		
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
SELECT 1 as Id, @ProductionStatus as ProductionStatus , @CarrierStatusId as CarrierStatusId
		
 
 
 

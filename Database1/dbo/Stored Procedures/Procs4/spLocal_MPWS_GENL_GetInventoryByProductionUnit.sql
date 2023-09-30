 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetInventoryByProductionUnit]
		@PUId			INT,
		@ProdId			INT		= NULL,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT	
AS	
-------------------------------------------------------------------------------
-- Get production events for a passed in production unit that counts for
-- inventory
/*
exec  spLocal_MPWS_GENL_GetInventoryByProductionUnit 3379
go
exec  spLocal_MPWS_GENL_GetInventoryByProductionUnit 3379, 6511
*/
-- Date         Version Build Author  
-- 12-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
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
	EventId					INT									NULL,
	EventNum				VARCHAR(255)						NULL,
	EventStatusId			INT									NULL,
	EventStatusDesc			VARCHAR(255)						NULL,
	TimeStamp				DATETIME							NULL,
	InitialDimX				FLOAT								NULL,
	FinalDimX				FLOAT								NULL,
	ProdId					INT									NULL,
	ProdCode				VARCHAR(255)						NULL	
)
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
IF	@ProdId		IS NOT NULL
		------------------------------------------------------------------------------
		-- Find production events for the passed in PU with status that count for
		-- inventory for the passed in product id
		-------------------------------------------------------------------------------		
		INSERT	@tOutput	(EventId, EventNum, EventStatusId, EventStatusDesc, TimeStamp,
				InitialDimX, FinalDimX, ProdId, ProdCode)
				SELECT	EV.Event_Id, EV.Event_Num, EV.Event_Status, PS.ProdStatus_Desc, 
						EV.TimeStamp, ED.Initial_Dimension_X, ED.Final_Dimension_X, EV.Applied_Product,
						P.Prod_Code
						FROM	dbo.Events EV					WITH (NOLOCK)
						JOIN	dbo.Event_Details ED			WITH (NOLOCK)
						ON		EV.Event_Id				= ED.Event_Id
						AND		EV.PU_Id				= @PUId	
						AND		EV.Applied_Product		= @ProdId
						JOIN	dbo.Production_Status PS		WITH (NOLOCK)
						ON		PS.ProdStatus_Id		= EV.Event_Status
						AND		PS.Count_For_Inventory	= 1
						JOIN	dbo.Products_Base P					WITH (NOLOCK)
						ON		P.Prod_Id				= EV.Applied_Product
						ORDER
						BY		EV.TimeStamp
ELSE						
		------------------------------------------------------------------------------
		-- Find production events for the passed in PU with status that count for
		-- inventory
		-------------------------------------------------------------------------------		
		INSERT	@tOutput	(EventId, EventNum, EventStatusId, EventStatusDesc, TimeStamp,
				InitialDimX, FinalDimX, ProdId, ProdCode)
				SELECT	EV.Event_Id, EV.Event_Num, EV.Event_Status, PS.ProdStatus_Desc, 
						EV.TimeStamp, ED.Initial_Dimension_X, ED.Final_Dimension_X, EV.Applied_Product,
						P.Prod_Code
						FROM	dbo.Events EV					WITH (NOLOCK)
						JOIN	dbo.Event_Details ED			WITH (NOLOCK)
						ON		EV.Event_Id = ED.Event_Id
						AND		EV.PU_Id				= @PUId	
						JOIN	dbo.Production_Status PS		WITH (NOLOCK)
						ON		PS.ProdStatus_Id		= EV.Event_Status
						AND		PS.Count_For_Inventory	= 1
						LEFT
						JOIN	dbo.Products_Base P					WITH (NOLOCK)
						ON		P.Prod_Id				= EV.Applied_Product
						ORDER
						BY		EV.TimeStamp
 
 
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'
--INSERT	@tFeedback (ErrorCode, ErrorMessage)
--		VALUES (1, 'Success')
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	Id						Id,
		EventId					EventId,
		EventNum				EventNum,
		EventStatusId			EventStatusId,
		EventStatusDesc			EventStatusDesc,
		TimeStamp				TimeStamp,
		InitialDimX				InitialDimX,
		FinalDimX				FinalDimX,
		ProdId					ProdId,
		ProdCode				ProdCode
		FROM	@tOutput
		ORDER
		BY		Id
 
 
-- GRANT EXECUTE ON [dbo].[spLocal_MPWS_GENL_GetInventoryByProductionUnit] TO [public]
 
 
 
 
 

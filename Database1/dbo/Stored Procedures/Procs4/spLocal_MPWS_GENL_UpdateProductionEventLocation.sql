 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_UpdateProductionEventLocation]
		@EventId		INT,
		@LocationId		INT,
		@LocationCode	VARCHAR(50) = NULL
AS	
-------------------------------------------------------------------------------
-- Update location for a production event. a SPROC needs to be used because
-- the current MESCore Service provider does not expose the location update
/*
exec  spLocal_MPWS_GENL_UpdateProductionEventLocation  5738336, 1
*/
-- Date         Version Build Author  
-- 20-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development
-- 31-Oct-2017  001     002	  Susan Lee (GE Digital) Add update by location code 
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

DECLARE @Location INT

-------------------------------------------------------------------------------
--  Updates the location for the production event if this location exists for 
-- the production unit the production event belongs to
--
-- This SPROC does not use a Spserver to update because the spserver does not
-- support the location update so I have to use a hot update
-------------------------------------------------------------------------------

SELECT	@Location = UL.Location_Id
					FROM	dbo.Unit_Locations	UL		WITH (NOLOCK)
					JOIN	dbo.[Events] EV				WITH (NOLOCK)
					ON		UL.PU_Id = EV.PU_Id
					AND		EV.Event_Id		= @EventId
					AND
					(		( @LocationId <> -1  AND UL.Location_Id	= @LocationId )
					OR
							( @LocationId = -1 AND UL.Location_Code = @LocationCode AND UL.PU_Id = EV.PU_Id)
					)		
				
IF @Location IS NOT NULL
BEGIN					
		UPDATE	dbo.Event_Details
				SET		Location_Id = @Location
				WHERE	Event_Id	= @EventId
				
		IF		@@ROWCOUNT	> 0
				INSERT	@tFeedback (ErrorCode, ErrorMessage)
					VALUES (1, 'Success')
		ELSE
				INSERT	@tFeedback (ErrorCode, ErrorMessage)
					VALUES (-2, 'Production Event could not be updated')			
END
ELSE
	INSERT	@tFeedback (ErrorCode, ErrorMessage)
			VALUES (-1, 'Location not found for production unit')
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
 
 
 
 
 

 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_AssignCarrierLocationId]
		@EventNum	VARCHAR(255),
		@LocationId			INT
AS	
-------------------------------------------------------------------------------
-- Assigns the passed LocationID to the Event_Details for the Passed Production Event
/*
spLocal_MPWS_KIT_AssignCarrierLocationId '20160601_001',2
*/
-- Date         Version Build Author  
-- 02-JUN-2016  001     001   Chris Donnelly (GE Digital) Initial development	
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
 
 
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Update Event Detail with Location Id
-------------------------------------------------------------------------------
DECLARE @Event_ID INT
 
SELECT @Event_ID = Event_ID FROM dbo.[Events]
		WHERE Event_Num = @EventNum
 
BEGIN TRY
	UPDATE dbo.Event_Details SET Location_Id =  @LocationId 
		WHERE Event_Id = @Event_ID
		
	INSERT	@tFeedback (ErrorCode, ErrorMessage)
			VALUES (1, 'Success')
END TRY
BEGIN CATCH
	INSERT	@tFeedback (ErrorCode, ErrorMessage)
			VALUES (-1, 'Failed to Update Location Id')
END CATCH
 
-------------------------------------------------------------------------------					
---- Return data tables
---------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
		
 
 
 
 

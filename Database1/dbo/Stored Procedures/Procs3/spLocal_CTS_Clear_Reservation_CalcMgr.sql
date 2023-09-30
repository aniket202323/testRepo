
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Clear_Reservation_CalcMgr
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-11-09-- Version: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Clears reservation when the appliance reaches destination
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-09		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE spLocal_CTS_Clear_Reservation_CalcMgr
	@Output output,
	995373

	SELECT @Output

*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Clear_Reservation_CalcMgr]
	@output						VARCHAR(25) OUTPUT,
	@ThisEventId				INTEGER


AS
BEGIN
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================
	DECLARE 
	@Username					VARCHAR(100),
	@ApplianceId				INTEGER,
	@OutPutStatus				INTEGER,
	@OutPutMessage				VARCHAR(50),
	@LocationPUId				INTEGER
	------------------------------------------------------------------------------------------------------------------------
	--GET APPLIANCE_ID FROM @thisEventId
	------------------------------------------------------------------------------------------------------------------------
	SET @ApplianceId = (SELECT TOP 1 source_event_id FROM dbo.event_components WITH(NOLOCK) WHERE event_id = @thisEventId ORDER BY Timestamp DESC)
	SET @Username = (
					SELECT	UB.username 
					FROM	dbo.users_Base UB WITH(NOLOCK) 
							JOIN dbo.events E WITH(NOLOCK)
								ON E.user_id = UB.user_id
					WHERE	E.event_id = @ThisEventId
					)
	
	------------------------------------------------------------------------------------------------------------------------
	--CALL THE SP TO CLEAR THE RESEREVATION
	------------------------------------------------------------------------------------------------------------------------
	SET @LocationPUId =	(
						SELECT	PU_ID 
						FROM	dbo.events WITH(NOLOCK) 
						WHERE	event_id = @ThisEventId
						)

	EXECUTE [dbo].[spLocal_CTS_CancelReservation] @ApplianceId, @LocationPUId, @Username, @OutPutStatus OUTPUT, @OutPutMessage OUTPUT
	IF @OutPutStatus = 1
		SET @output = 'Reservation cleared'
	ELSE
		SET @output = 'Error'




--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================
END

GRANT EXECUTE ON [dbo].[spLocal_CTS_Clear_Reservation_CalcMgr] TO ctsWebService
GRANT EXECUTE ON [dbo].[spLocal_CTS_Clear_Reservation_CalcMgr] TO comxclient
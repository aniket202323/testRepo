--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Serial_CalcMgr
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-10-27-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Extract the serial from the appliance transition PE
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-04		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE [spLocal_CTS_Get_Serial_CalcMgr]
	@Output output,
	995678
	SELECT @Output

	SELECT * FROM EVENTS WHERE PU_ID = 8459
	Select * from event_details where pu_id = 8455
	Select * from event_details where event_id  = 986440

*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Get_Serial_CalcMgr]
	@Output						VARCHAR(25) OUTPUT,
	@ThisEventId				INTEGER



AS
BEGIN
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================
	-----------------------------------------------------------------------------------------------------------------------
	-- DECLARE VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@ApplianceEventId	INTEGER

	SET @Output = 'Serial Not found'
		
	
	SET @ApplianceEventId =	(
							SELECT	source_event_id 
							FROM	dbo.event_components WITH(NOLOCK) 
							WHERE	event_id = @ThisEventId
							)
	SET @Output =			(
							SELECT	alternate_event_num 
							FROM	dbo.event_details WITH(NOLOCK) 
							WHERE event_id = @ApplianceEventId
							)
--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================


END -- BODY

GRANT EXECUTE ON [dbo].[spLocal_CTS_Get_Serial_CalcMgr] TO ctsWebService
GRANT EXECUTE ON [dbo].[spLocal_CTS_Get_Serial_CalcMgr] TO comxclient






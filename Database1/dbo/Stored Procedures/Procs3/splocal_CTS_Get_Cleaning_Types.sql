
--------------------------------------------------------------------------------------------------
-- Stored Procedure: splocal_CTS_Get_Cleaning_Types
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-08-12
-- Version 				: Version 1.0
-- SP Type				: WEB
-- Caller				: WEB SERVICE
-- Description			: Get the cleaning types from SQL table
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-08-12		F. Bergeron				Initial Release 
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE [splocal_CTS_Get_Cleaning_Types] NULL, NULL, 1
*/

CREATE   PROCEDURE [dbo].[splocal_CTS_Get_Cleaning_Types]




AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables


	SELECT	CCM_id, --'Cleaning type id',
			Description, --'Cleaning type desc',
			Code --'Cleaning type code'
	FROM 	dbo.Local_CTS_Cleaning_Methods
	
	SET NOCOUNT OFF;

END


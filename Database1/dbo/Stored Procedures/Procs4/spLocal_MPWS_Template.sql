 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_Template]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@InputVar1		FLOAT,
		@InputVar2		VARCHAR(255) = NULL
AS	
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- < Description >
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_Template 5.01, 'value1', @ErrorCode, @ErrorMessage
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 06-Oct-2015  001     001    (GE Digital)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
		
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------
-- <Actions>
-------------------------------------------------------------------------------
 
 
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_Template] TO [comxclient]
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_Template] TO [MPWSHMI]
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_Template] TO [ThingWorx]
 
 
 
 

 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetESigUserValidation]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PWFunction		VARCHAR(50),
	@PWAction		VARCHAR(50),
	@UserId			INT = NULL,
	@UserName		VARCHAR(50) = NULL
--WITH ENCRYPTION	
AS	
 
SET NOCOUNT ON
 
/* -------------------------------------------------------------------------------
 
	dbo.spLocal_MPWS_GENL_GetESigUserValidation
 
	Get Preweigh ESig Configuration Info for a UserId based on Function and Action. Returns @ErrorCode = -1 if the UserId has no allowed Actions.
	
	Date			Version	Build	Author  
	01-Jul-2016		001		001		Jim Cameron (GEIP)		Initial development	
	23-Aug-2017		002		001		Susan Lee (GE Digital)	Updated to use UDP mapping for Preweigh to PPA
	10-Nov-2017     002		001		Susan Lee (GE Digital)	use spLocal_MPWS_GENL_GetUserValidation for validation
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_GetESigUserValidation @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Inventory', 'AdjustRMC', null, 'mpwoperator.im'
--exec dbo.spLocal_MPWS_GENL_GetESigUserValidation @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'Dispense', 'All', null, 'lee.s.3'
select @ErrorCode, @ErrorMessage
 
------------------------------------------------------------------------------- */

Declare @Type			VARCHAR(50) = 'ESig'

DECLARE @tOutput TABLE
(
	Usr_Id				INT,
	UserName			VARCHAR(50),
	PWAction			VARCHAR(50),
	ButtonGroup			VARCHAR(50),
	ESigGroup			VARCHAR(50),
	VerifierEsigGroup	VARCHAR(50),
	ErrCode				INT,
	ErrMessage			VARCHAR(500)
)

INSERT @tOutput 
		(Usr_Id, UserName, PWAction, ButtonGroup, ESigGroup, VerifierEsigGroup, ErrCode, ErrMessage)
		EXEC dbo.spLocal_MPWS_GENL_GetUserValidation @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 
		@PWFunction, @PWAction, @Type,@UserId, @UserName

SELECT	*
FROM	@tOutput 


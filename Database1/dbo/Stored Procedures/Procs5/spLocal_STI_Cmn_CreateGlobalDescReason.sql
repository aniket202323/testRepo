
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescReason]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescReason
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a reason

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescReason '', ''
--------------------------------------------------------------------------------------------------------
*/

@ReasonDescGlobal	varchar(100),
@ReasonDescLocal	varchar(100)

AS

SET NOCOUNT ON

-- verify if reason tree exists
IF NOT EXISTS (SELECT Event_Reason_Id FROM dbo.Event_Reasons WHERE Event_Reason_Name_Local = @ReasonDescLocal)
	BEGIN
		SELECT 'Reason ' + @ReasonDescLocal + ' not found.'
		RETURN
	END

-- set reason's Global description
UPDATE	dbo.Event_Reasons
SET		Event_Reason_Name_Global = @ReasonDescGlobal
WHERE		Event_Reason_Name_Local = @ReasonDescLocal

SET NOCOUNT OFF


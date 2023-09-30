
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescReason]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescReason
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a reason

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescReason '', ''
--------------------------------------------------------------------------------------------------------
*/

@ReasonDescLocal	varchar(50),
@ReasonDescGlobal	varchar(50)

AS

SET NOCOUNT ON

-- verify if reason tree exists
IF NOT EXISTS (SELECT Event_Reason_Id FROM dbo.Event_Reasons WHERE Event_Reason_Name_Global = @ReasonDescGlobal)
	BEGIN
		SELECT 'Reason ' + @ReasonDescGlobal + ' not found.'
		RETURN
	END

-- set reason's local description
UPDATE	dbo.Event_Reasons
SET		Event_Reason_Name_Local = @ReasonDescLocal
WHERE		Event_Reason_Name_Global = @ReasonDescGlobal

SET NOCOUNT OFF


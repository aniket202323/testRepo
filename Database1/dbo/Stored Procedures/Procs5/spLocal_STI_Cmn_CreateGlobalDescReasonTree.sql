
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescReasonTree]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescReasonTree
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a reason tree

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescReasonTree '', ''
--------------------------------------------------------------------------------------------------------
*/
@RTDescGlobal	varchar(50),
@RTDescLocal	varchar(50)

AS

SET NOCOUNT ON

-- verify if reason tree exists
IF NOT EXISTS (SELECT Tree_Name_Id FROM dbo.Event_Reason_Tree WHERE Tree_Name_Local = @RTDescLocal)
	BEGIN
		SELECT 'Reason tree ' + @RTDescLocal + ' not found.'
		RETURN
	END

-- set reason tree's Global description
UPDATE	dbo.Event_Reason_Tree
SET		Tree_Name_Global = @RTDescGlobal
WHERE		Tree_Name_Local = @RTDescLocal


SET NOCOUNT OFF


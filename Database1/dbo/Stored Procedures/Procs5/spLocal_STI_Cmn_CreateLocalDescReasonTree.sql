
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescReasonTree]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescReasonTree
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a reason tree

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescReasonTree '', ''
--------------------------------------------------------------------------------------------------------
*/
@RTDescLocal	varchar(50),
@RTDescGlobal	varchar(50)

AS

SET NOCOUNT ON

-- verify if reason tree exists
IF NOT EXISTS (SELECT Tree_Name_Id FROM dbo.Event_Reason_Tree WHERE Tree_Name_Global = @RTDescGlobal)
	BEGIN
		SELECT 'Reason tree ' + @RTDescGlobal + ' not found.'
		RETURN
	END

-- set reason tree's local description
UPDATE	dbo.Event_Reason_Tree
SET		Tree_Name_Local = @RTDescLocal
WHERE		Tree_Name_Global = @RTDescGlobal


SET NOCOUNT OFF


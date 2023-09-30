
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescLine]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescLine
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a production line

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescLine '', ''
--------------------------------------------------------------------------------------------------------
*/
@PLDescLocal	varchar(50),
@PLDescGlobal	varchar(50)

AS

SET NOCOUNT ON

-- verify if production line exists
IF NOT EXISTS (SELECT Pl_Id FROM dbo.Prod_Lines WHERE Pl_Desc_Global = @PLDescGlobal)
	BEGIN
		SELECT 'Production line ' + @PLDescGlobal + ' not found.'
		RETURN
	END

-- set production line's local description
UPDATE	dbo.Prod_Lines
SET		Pl_Desc_Local = @PLDescLocal
WHERE		Pl_Desc_Global = @PLDescGlobal

SET NOCOUNT OFF


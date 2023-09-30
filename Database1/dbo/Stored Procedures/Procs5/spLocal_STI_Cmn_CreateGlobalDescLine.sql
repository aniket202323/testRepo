
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescLine]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescLine
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a production line

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescLine '', ''
--------------------------------------------------------------------------------------------------------
*/
@PLDescGlobal	varchar(50),
@PLDescLocal	varchar(50)

AS

SET NOCOUNT ON

-- verify if production line exists
IF NOT EXISTS (SELECT Pl_Id FROM dbo.Prod_Lines WHERE Pl_Desc_Local = @PLDescLocal)
	BEGIN
		SELECT 'Production line ' + @PLDescLocal + ' not found.'
		RETURN
	END

-- set production line's Global description
UPDATE	dbo.Prod_Lines
SET		Pl_Desc_Global = @PLDescGlobal
WHERE		Pl_Desc_Local = @PLDescLocal

SET NOCOUNT OFF


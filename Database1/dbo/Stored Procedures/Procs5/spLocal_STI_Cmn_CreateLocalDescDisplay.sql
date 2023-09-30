
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescDisplay]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescDisplay
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a display

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescDisplay '', ''
--------------------------------------------------------------------------------------------------------
*/
@DisplayDescLocal		varchar(50),
@DisplayDescGlobal	varchar(50)

AS

SET NOCOUNT ON

-- verify if display exists
IF NOT EXISTS (SELECT Sheet_Id FROM dbo.Sheets WHERE Sheet_Desc_Global = @DisplayDescGlobal)
	BEGIN
		SELECT 'Display ' + @DisplayDescGlobal + ' not found.'
		RETURN
	END

-- set display's local description
UPDATE	dbo.Sheets
SET		Sheet_Desc_Local = @DisplayDescLocal
WHERE		Sheet_Desc_Global = @DisplayDescGlobal

SET NOCOUNT OFF


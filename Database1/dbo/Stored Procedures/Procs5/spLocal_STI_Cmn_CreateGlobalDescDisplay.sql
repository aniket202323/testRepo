
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescDisplay]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescDisplay
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a display

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescDisplay '', ''
--------------------------------------------------------------------------------------------------------
*/
@DisplayDescGlobal		varchar(50),
@DisplayDescLocal	varchar(50)

AS

SET NOCOUNT ON

-- verify if display exists
IF NOT EXISTS (SELECT Sheet_Id FROM dbo.Sheets WHERE Sheet_Desc_Local = @DisplayDescLocal)
	BEGIN
		SELECT 'Display ' + @DisplayDescLocal + ' not found.'
		RETURN
	END

-- set display's Global description
UPDATE	dbo.Sheets
SET		Sheet_Desc_Global = @DisplayDescGlobal
WHERE		Sheet_Desc_Local = @DisplayDescLocal

SET NOCOUNT OFF


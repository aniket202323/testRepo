
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescDisplayGroup]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescDisplayGroup
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a display group

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescDisplayGroup '', ''
--------------------------------------------------------------------------------------------------------
*/
@DisplayGroupDescGlobal		varchar(50),
@DisplayGroupDescLocal		varchar(50)

AS

SET NOCOUNT ON

-- verify if display exists
IF NOT EXISTS (SELECT Sheet_Group_Id FROM dbo.Sheet_Groups WHERE Sheet_Group_Desc_Local = @DisplayGroupDescLocal)
	BEGIN
		SELECT 'Display Group ' + @DisplayGroupDescLocal + ' not found.'
		RETURN
	END

-- set display group's Global description
UPDATE	dbo.Sheet_Groups
SET		Sheet_Group_Desc_Global = @DisplayGroupDescGlobal
WHERE		Sheet_Group_Desc_Local = @DisplayGroupDescLocal

SET NOCOUNT OFF



----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescDisplayGroup]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescDisplayGroup
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a display group

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescDisplayGroup '', ''
--------------------------------------------------------------------------------------------------------
*/
@DisplayGroupDescLocal		varchar(50),
@DisplayGroupDescGlobal		varchar(50)

AS

SET NOCOUNT ON

-- verify if display exists
IF NOT EXISTS (SELECT Sheet_Group_Id FROM dbo.Sheet_Groups WHERE Sheet_Group_Desc_Global = @DisplayGroupDescGlobal)
	BEGIN
		SELECT 'Display Group ' + @DisplayGroupDescGlobal + ' not found.'
		RETURN
	END

-- set display group's local description
UPDATE	dbo.Sheet_Groups
SET		Sheet_Group_Desc_Local = @DisplayGroupDescLocal
WHERE		Sheet_Group_Desc_Global = @DisplayGroupDescGlobal

SET NOCOUNT OFF


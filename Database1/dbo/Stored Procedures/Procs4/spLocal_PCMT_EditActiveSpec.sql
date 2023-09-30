
CREATE PROCEDURE [dbo].[spLocal_PCMT_EditActiveSpec]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_EditActiveSpec
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtSpecId			INTEGER,
@txtCharId			INTEGER,
@txtEffDate			DATETIME,
@txtSampleNumber	INTEGER,
@txtPriority		INTEGER,
@txtOldEffDate		DATETIME

AS

SET NOCOUNT ON


IF EXISTS (SELECT Spec_UDP_ID FROM dbo.Local_PG_Spec_UDP 
			  WHERE Spec_Id = @txtSpecId AND char_id = @txtCharId AND effective_date = @txtEffDate) BEGIN

	EXECUTE spLocal_PCMT_DropActiveSpec @txtSpecId, @txtCharId, @txtEffDate
	EXECUTE spLocal_PCMT_DropActiveSpec @txtSpecId, @txtCharId, @txtOldEffDate
	EXECUTE spLocal_PCMT_AddActiveSpec @txtSpecId, @txtCharId, @txtEffDate, @txtSampleNumber, @txtPriority END

ELSE BEGIN

	EXECUTE spLocal_PCMT_DropActiveSpec @txtSpecId, @txtCharId, @txtOldEffDate
	EXECUTE spLocal_PCMT_AddActiveSpec @txtSpecId, @txtCharId, @txtEffDate, @txtSampleNumber, @txtPriority

END

SELECT 0, 'Active specification successfully edited!'


SET NOCOUNT OFF











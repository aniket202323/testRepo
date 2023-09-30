










CREATE PROCEDURE [dbo].[spLocal_PCMT_DropActiveSpec]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_DropActiveSpec
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
@txtOldEffDate		DATETIME

AS

SET NOCOUNT ON

DECLARE
@intItemID				INTEGER,
@dtmExpirationDate	DATETIME

IF EXISTS	(SELECT Spec_UDP_ID FROM dbo.Local_PG_Spec_UDP 
				 WHERE Spec_Id = @txtSpecId AND char_id = @txtCharId AND effective_date = @txtOldEffDate) BEGIN

	--Get current record expiration date
	SET @dtmExpirationDate =  (SELECT expiration_date FROM dbo.Local_PG_Spec_UDP
										WHERE
											Spec_Id = @txtSpecId 
											AND char_id = @txtCharId 
											AND effective_date = @txtOldEffDate)

	DELETE FROM dbo.Local_PG_Spec_UDP
	WHERE
		Spec_Id = @txtSpecId 
		AND char_id = @txtCharId 
		AND effective_date = @txtOldEffDate

	--Updating previous record (if any) (replacing previous record expiration date 
	--with current record expiration date)
	SET @intItemID = (SELECT TOP 1 Spec_UDP_ID FROM dbo.Local_PG_Spec_UDP 
				  			WHERE Spec_Id = @txtSpecId AND char_id = @txtCharId AND effective_date < @txtOldEffDate
							ORDER BY effective_date DESC)
	IF @intItemID IS NOT NULL BEGIN
		UPDATE dbo.Local_PG_Spec_UDP
		SET	
			Expiration_Date = @dtmExpirationDate
		WHERE
			Spec_UDP_ID = @intItemID
	END

	SELECT 0, 'Active specification successfully deleted!' END

ELSE BEGIN

	SELECT 1, 'No active specification found!'

END

SET NOCOUNT OFF









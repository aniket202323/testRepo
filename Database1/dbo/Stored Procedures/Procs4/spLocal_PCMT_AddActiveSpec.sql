

CREATE PROCEDURE [dbo].[spLocal_PCMT_AddActiveSpec]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_AddActiveSpec
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
@txtPriority		INTEGER

AS

SET NOCOUNT ON

DECLARE
@intItemID			INTEGER,
@dtmNextEffDate	DATETIME

IF NOT EXISTS (SELECT Spec_UDP_ID FROM dbo.Local_PG_Spec_UDP 
					WHERE Spec_Id = @txtSpecId AND char_id = @txtCharId AND effective_date = @txtEffDate) BEGIN

	INSERT dbo.Local_PG_Spec_UDP 
		(Spec_Id, Char_Id, Effective_Date, Expiration_Date, Sample_Number, Priority)
	VALUES
		(@txtSpecId, @txtCharId, @txtEffDate, NULL, @txtSampleNumber, @txtPriority)

	--Updating previous record (if any) (replacing previous record expiration date 
	--with current record effective date)
	SET @intItemID = (SELECT TOP 1 Spec_UDP_ID FROM dbo.Local_PG_Spec_UDP 
				  			WHERE Spec_Id = @txtSpecId AND char_id = @txtCharId AND effective_date < @txtEffDate
							ORDER BY effective_date DESC)
	IF @intItemID IS NOT NULL BEGIN
		UPDATE dbo.Local_PG_Spec_UDP
		SET	
			Expiration_Date = @txtEffDate
		WHERE
			Spec_UDP_ID = @intItemID
	END

	--Updating current record with next record (if any) (replacing current record expiration date 
	--with next record effective date)
	SET @dtmNextEffDate = (SELECT TOP 1 effective_date FROM dbo.Local_PG_Spec_UDP 
				  				  WHERE Spec_Id = @txtSpecId AND char_id = @txtCharId AND effective_date > @txtEffDate
								  ORDER BY effective_date ASC)
	IF @dtmNextEffDate IS NOT NULL BEGIN
		UPDATE dbo.Local_PG_Spec_UDP
		SET	
			Expiration_Date = @dtmNextEffDate
		WHERE
			Spec_Id = @txtSpecId 
			AND char_id = @txtCharId 
			AND effective_date = @txtEffDate
	END

	SELECT 0, 'Active specification successfully added!' END

ELSE BEGIN

	SELECT 1, 'Effective date already exists for the given product and specification!'

END

SET NOCOUNT OFF









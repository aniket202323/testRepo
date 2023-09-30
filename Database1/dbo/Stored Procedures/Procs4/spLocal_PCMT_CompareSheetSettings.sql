













CREATE PROCEDURE [dbo].[spLocal_PCMT_CompareSheetSettings]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_CompareSheetSettings
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates a new user.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@cboTempDisp				INTEGER,
@txtVarInterval			INTEGER,
@txtVarOffset				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intSheetInterval		INTEGER,
@intSheetOffset		INTEGER

--Get sheet setings
SELECT 
	@intSheetInterval = ISNULL(interval, 0), 
	@intSheetOffset = ISNULL(offset, 0) 
FROM 
	dbo.sheets 
WHERE 
	sheet_id = @cboTempDisp

--Compare sheet and variable settings
IF @intSheetInterval <> @txtVarInterval OR @intSheetOffset <> @txtVarOffset BEGIN
	SELECT @txtVarInterval, @intSheetInterval, @txtVarOffset, @intSheetOffset END
ELSE BEGIN
	SELECT -1
END

SET NOCOUNT OFF













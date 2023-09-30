
-------------------------------------------------------------------------------------------------
CREATE  	PROCEDURE [dbo].[spLocal_PCMT_CreateUDP]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_CreateUDP
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:				ADO or SDK Call
Editor Tab Spacing:		4	
*****************************************************************************************************************
Author:					Juan Pablo Galanzini (Arido)
Date Created:			2014-07-28
Version:				2.0
Uodate:					Added a new parameter for field TableId in dbo.table_fields for PPA6
*****************************************************************************************************************
*/
@txtUDPDesc		VARCHAR(255),
@cboUDPTypes	INTEGER,
@cboUDPTableId	INTEGER
AS

SET NOCOUNT ON

DECLARE @intUDPID INTEGER

--SET @intUDPID = (SELECT MIN(table_field_id) FROM dbo.table_fields WHERE Table_Field_Desc = @txtUDPDesc)
SELECT @intUDPID = table_field_id FROM dbo.table_fields WHERE Table_Field_Desc = @txtUDPDesc

IF @intUDPID IS NULL BEGIN
	INSERT dbo.table_fields 
		(ED_Field_Type_Id, Table_Field_Desc, TableId)
	VALUES (@cboUDPTypes, @txtUDPDesc, @cboUDPTableId)
	
	SET @intUDPID = (SELECT table_field_id FROM dbo.table_fields WHERE Table_Field_Desc = @txtUDPDesc)
END

SELECT @intUDPID

SET NOCOUNT OFF

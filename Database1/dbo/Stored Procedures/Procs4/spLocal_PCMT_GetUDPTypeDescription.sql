






-------------------------------------------------------------------------------------------------

CREATE  	PROCEDURE [dbo].[spLocal_PCMT_GetUDPTypeDescription]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetUDPTypeDescription
Author:					Marc Charest (STI)
Date Created:			2009-05-19
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP gets data type for the given UDP field.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================



spLocal_PCMT_GetUDPTypeDescription 175

*****************************************************************************************************************
*/
@cboOtherUDP INTEGER

AS

SET NOCOUNT ON

SELECT Field_Type_Desc
FROM 
	dbo.ED_FieldTypes ed
	JOIN Table_Fields tf ON (tf.ED_Field_Type_Id = ed.ED_Field_Type_Id)
WHERE 
	Table_Field_ID = @cboOtherUDP

SET NOCOUNT OFF








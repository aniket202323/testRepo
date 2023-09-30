












-------------------------------------------------------------------------------------------------

CREATE  	PROCEDURE [dbo].[spLocal_PCMT_GetUDPTypes]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetUDPTypes
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
1.1.0		2009-01-28	Marc Charest STI		Add code to filter the list.

*****************************************************************************************************************
*/

AS

SET NOCOUNT ON

SELECT ED_Field_Type_Id AS [cboUDPTypes], Field_Type_Desc
FROM dbo.ed_fieldtypes
WHERE Field_Type_Desc IN ('Numeric', 'TRUE/FALSE', 'Variable Id', 'Unit Id', 'Text', 'Tag')
ORDER BY 
	Field_Type_Desc

SET NOCOUNT OFF














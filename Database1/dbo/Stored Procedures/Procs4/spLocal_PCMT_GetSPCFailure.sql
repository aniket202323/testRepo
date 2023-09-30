













CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSPCFailure]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSPCFailure
Author:					Marc Charest (STI)	
Date Created:			2007-05-03
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP ...

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@cboDataType			INTEGER

AS

SET NOCOUNT ON

--IF EXISTS (SELECT data_type_id FROM dbo.data_type WHERE data_type_id = @cboDataType AND user_defined = 1) BEGIN
	SELECT phrase_id AS [cboSPCFailure], phrase_value 
	FROM dbo.phrase  
	WHERE 
		data_type_id = @cboDataType
	ORDER BY phrase_value ASC
--END

SET NOCOUNT OFF









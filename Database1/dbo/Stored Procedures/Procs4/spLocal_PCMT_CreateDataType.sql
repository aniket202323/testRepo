


















CREATE PROCEDURE [dbo].[spLocal_PCMT_CreateDataType]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_CreateDataType
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates new data type.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtNewDataType				VARCHAR(50)

AS

SET NOCOUNT ON

DECLARE
@vcrNewDataType				VARCHAR(50),
@intNewDataTypeId				INTEGER

SET @vcrNewDataType			= @txtNewDataType

--Selecting IDENTITY
SET @intNewDataTypeId = (SELECT MAX(data_type_id) FROM dbo.Data_Type) + 1

--Creating new data type
EXECUTE spEM_CreateDataType @vcrNewDataType, 1, @intNewDataTypeId
SELECT @intNewDataTypeId

SET NOCOUNT OFF






















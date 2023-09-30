














CREATE PROCEDURE [dbo].[spLocal_PCMT_CreatePhrase]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_CreatePhrase
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates a data type prhase.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtNewDataTypeId				INTEGER,
@txtPhraseValue				VARCHAR(50),
@txtPhraseOrder				INTEGER,
@txtUserId						INTEGER

AS

SET NOCOUNT ON

DECLARE
@intNewDataTypeId				INTEGER,
@vcrPhraseValue				VARCHAR(50),
@intPhraseOrder				INTEGER,
@intNewPhraseId				INTEGER

SET @intNewDataTypeId		= @txtNewDataTypeId
SET @vcrPhraseValue			= @txtPhraseValue
SET @intPhraseOrder			= @txtPhraseOrder

--Get IDENTITY
SET @intNewPhraseId = (SELECT ISNULL(MAX(phrase_id), 0) FROM dbo.phrase) + 1

--Creating phrase
EXECUTE spEM_CreatePhrase @intNewDataTypeId, @vcrPhraseValue, @intPhraseOrder, 1, @intNewPhraseId

SELECT @intNewPhraseId

INSERT Local_PG_PCMT_Log_DataTypes (Timestamp, User_id1, Type, Data_Type_Id, Data_Type_Desc, Phrase_Id, Phrase_Value, Phrase_Order)
SELECT GETDATE(), @txtUserId, 1, @txtNewDataTypeId, data_type_desc, @intNewPhraseId, @vcrPhraseValue, @intPhraseOrder
FROM dbo.data_type dt LEFT JOIN dbo.phrase p ON (p.data_type_id = dt.data_type_id)
WHERE p.phrase_id = @intNewPhraseId

SET NOCOUNT OFF























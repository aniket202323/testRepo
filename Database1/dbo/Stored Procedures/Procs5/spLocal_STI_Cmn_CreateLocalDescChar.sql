
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescChar]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescChar
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a characteristic

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescChar '', '', ''
--------------------------------------------------------------------------------------------------------
*/
@CharDescLocal		varchar(50),
@CharDescGlobal	varchar(50),
@PropDescGlobal	varchar(50)

AS

SET NOCOUNT ON

DECLARE
@PropId	int

-- retrieve product property id
SET @PropId = (SELECT Prop_Id FROM dbo.Product_Properties WHERE Prop_Desc_Global = @PropDescGlobal)

IF @PropId IS NULL
	BEGIN
		SELECT 'Product property ' + @PropDescGlobal + ' not found.'
		RETURN
	END

-- verify if characteristic exists inside property
IF NOT EXISTS (SELECT Char_Id FROM dbo.Characteristics WHERE Char_Desc_Global = @CharDescGlobal AND Prop_Id = @PropId)
	BEGIN
		SELECT 'Characteristic ' + @CharDescGlobal + ' not found in product property ' + @PropDescGlobal
		RETURN
	END

-- set characteristic's local description
UPDATE	dbo.Characteristics 
SET		Char_Desc_Local = @CharDescLocal 
WHERE		Char_Desc_Global = @CharDescGlobal
AND		Prop_Id = @PropId

SET NOCOUNT OFF


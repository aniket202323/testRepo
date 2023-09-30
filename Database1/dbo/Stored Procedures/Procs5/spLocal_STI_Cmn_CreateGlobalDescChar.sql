
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescChar]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescChar
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a characteristic

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescChar '', '', ''
--------------------------------------------------------------------------------------------------------
*/
@CharDescGlobal	varchar(50),
@CharDescLocal		varchar(50),
@PropDescLocal		varchar(50)

AS

SET NOCOUNT ON

DECLARE
@PropId	int

-- retrieve product property id
SET @PropId = (SELECT Prop_Id FROM dbo.Product_Properties WHERE Prop_Desc_Local = @PropDescLocal)

IF @PropId IS NULL
	BEGIN
		SELECT 'Product property ' + @PropDescLocal + ' not found.'
		RETURN
	END

-- verify if characteristic exists inside property
IF NOT EXISTS (SELECT Char_Id FROM dbo.Characteristics WHERE Char_Desc_Local = @CharDescLocal AND Prop_Id = @PropId)
	BEGIN
		SELECT 'Characteristic ' + @CharDescLocal + ' not found in product property ' + @PropDescLocal
		RETURN
	END

-- set characteristic's Global description
UPDATE	dbo.Characteristics 
SET		Char_Desc_Global = @CharDescGlobal 
WHERE		Char_Desc_Local = @CharDescLocal
AND		Prop_Id = @PropId

SET NOCOUNT OFF



----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescProperty]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescProperty
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a product property

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescProperty '', ''
--------------------------------------------------------------------------------------------------------
*/
@PropDescGlobal		varchar(50),
@PropDescLocal	varchar(50)

AS 

SET NOCOUNT ON

-- verify if product property exists
IF NOT EXISTS (SELECT Prop_Id FROM dbo.Product_Properties WHERE Prop_Desc_Local = @PropDescLocal)
	BEGIN
		SELECT 'Product property ' + @PropDescLocal + ' not found.'
		RETURN
	END

-- set product property's Global desccription
UPDATE	dbo.Product_Properties 
SET		Prop_Desc_Global = @PropDescGlobal
WHERE		Prop_Desc_Local = @PropDescLocal

SET NOCOUNT OFF


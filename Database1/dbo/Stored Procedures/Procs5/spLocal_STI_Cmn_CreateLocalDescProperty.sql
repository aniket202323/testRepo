
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescProperty]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescProperty
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a product property

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescProperty '', ''
--------------------------------------------------------------------------------------------------------
*/
@PropDescLocal		varchar(50),
@PropDescGlobal	varchar(50)

AS 

SET NOCOUNT ON

-- verify if product property exists
IF NOT EXISTS (SELECT Prop_Id FROM dbo.Product_Properties WHERE Prop_Desc_Global = @PropDescGlobal)
	BEGIN
		SELECT 'Product property ' + @PropDescGlobal + ' not found.'
		RETURN
	END

-- set product property's local desccription
UPDATE	dbo.Product_Properties 
SET		Prop_Desc_Local = @PropDescLocal
WHERE		Prop_Desc_Global = @PropDescGlobal

SET NOCOUNT OFF


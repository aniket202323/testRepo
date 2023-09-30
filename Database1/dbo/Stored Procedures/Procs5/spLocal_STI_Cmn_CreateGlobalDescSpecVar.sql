
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescSpecVar]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescSpecVar
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a specification variable

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescSpecVar '', ''
--------------------------------------------------------------------------------------------------------
*/
@SpecDescGlobal		varchar(50),
@SpecDescLocal	varchar(50),
@PropDescLocal	varchar(50)

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

-- verify if specification variable exists inside property
IF NOT EXISTS (SELECT Spec_Id FROM dbo.Specifications WHERE Spec_Desc_Local = @SpecDescLocal AND Prop_Id = @PropId)
	BEGIN
		SELECT 'Specification variable ' + @SpecDescLocal + ' not found in product property ' + @PropDescLocal
		RETURN
	END

-- set specification variable's Global description
UPDATE	dbo.Specifications 
SET		Spec_Desc_Global = @SpecDescGlobal 
WHERE		Spec_Desc_Local = @SpecDescLocal
AND		Prop_Id = @PropId

SET NOCOUNT OFF


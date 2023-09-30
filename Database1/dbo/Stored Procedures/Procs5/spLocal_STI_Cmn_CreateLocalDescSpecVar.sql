
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescSpecVar]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescSpecVar
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a specification variable

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescSpecVar '', ''
--------------------------------------------------------------------------------------------------------
*/
@SpecDescLocal		varchar(50),
@SpecDescGlobal	varchar(50),
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

-- verify if specification variable exists inside property
IF NOT EXISTS (SELECT Spec_Id FROM dbo.Specifications WHERE Spec_Desc_Global = @SpecDescGlobal AND Prop_Id = @PropId)
	BEGIN
		SELECT 'Specification variable ' + @SpecDescGlobal + ' not found in product property ' + @PropDescGlobal
		RETURN
	END

-- set specification variable's local description
UPDATE	dbo.Specifications 
SET		Spec_Desc_Local = @SpecDescLocal 
WHERE		Spec_Desc_Global = @SpecDescGlobal
AND		Prop_Id = @PropId

SET NOCOUNT OFF


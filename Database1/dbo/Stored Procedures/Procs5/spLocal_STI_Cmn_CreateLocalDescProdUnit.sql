
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescProdUnit]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescProdUnit
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a productino unit

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescProdUnit '', '', ''
--------------------------------------------------------------------------------------------------------
*/
@PUDescLocal		varchar(50),
@PUDescGlobal		varchar(50),
@PLDescGlobal		varchar(50)

AS

SET NOCOUNT ON

DECLARE
@Plid		int

-- retrieve production line id
SET @Plid = (SELECT Pl_Id FROM dbo.Prod_Lines WHERE Pl_Desc_Global = @PLDescGlobal)

IF @Plid IS NULL
	BEGIN
		SELECT 'Production line ' + @PLDescGlobal + ' not found.'
		RETURN
	END

-- verify if production unit exists
IF NOT EXISTS (SELECT Pu_Id FROM dbo.Prod_Units WHERE Pu_Desc_Global = @PUDescGlobal)
	BEGIN
		SELECT 'Production unit ' + @PUDescGlobal + ' not found.'
		RETURN
	END

-- set production unit's local description
UPDATE	dbo.Prod_Units
SET		Pu_Desc_Local = @PUDescLocal
WHERE		Pu_Desc_Global = @PUDescGlobal

SET NOCOUNT OFF


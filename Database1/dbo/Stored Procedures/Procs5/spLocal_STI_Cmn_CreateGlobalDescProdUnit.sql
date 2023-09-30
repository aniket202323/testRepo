
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescProdUnit]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescProdUnit
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a productino unit

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescProdUnit '', '', ''
--------------------------------------------------------------------------------------------------------
*/
@PUDescGlobal		varchar(50),
@PUDescLocal		varchar(50),
@PLDescLocal		varchar(50)

AS

SET NOCOUNT ON

DECLARE
@Plid		int

-- retrieve production line id
SET @Plid = (SELECT Pl_Id FROM dbo.Prod_Lines WHERE Pl_Desc_Local = @PLDescLocal)

IF @Plid IS NULL
	BEGIN
		SELECT 'Production line ' + @PLDescLocal + ' not found.'
		RETURN
	END

-- verify if production unit exists
IF NOT EXISTS (SELECT Pu_Id FROM dbo.Prod_Units WHERE Pu_Desc_Local = @PUDescLocal)
	BEGIN
		SELECT 'Production unit ' + @PUDescLocal + ' not found.'
		RETURN
	END

-- set production unit's Global description
UPDATE	dbo.Prod_Units
SET		Pu_Desc_Global = @PUDescGlobal
WHERE		Pu_Desc_Local = @PUDescLocal

SET NOCOUNT OFF


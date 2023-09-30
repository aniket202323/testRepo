
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescVariable]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescVariable
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a variable

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescVariable '', '', '', ''
--------------------------------------------------------------------------------------------------------
*/
@VarDescGlobal		varchar(50),
@VarDescLocal		varchar(50),
@PuDescLocal		varchar(50),
@PlDescLocal		varchar(50)

AS

SET NOCOUNT ON

DECLARE
@PlId		int,
@PuId		int

-- retrieve production line id
SET @PlId = (SELECT Pl_Id FROM dbo.Prod_Lines WHERE Pl_Desc_Local = @PlDescLocal)

IF @PlId IS NULL
	BEGIN
		SELECT 'Production line ' + @PLDescLocal + ' not found.'
		RETURN
	END

-- retrieve production unit id
SET @PuId = (SELECT Pu_Id FROM dbo.Prod_Units WHERE Pu_Desc_Local = @PuDescLocal AND Pl_Id = @PlId)

IF @PuId IS NULL
	BEGIN
		SELECT 'Production unit ' + @PuDescLocal + ' under production line ' + @PlDescLocal + ' not found.'
		RETURN
	END

-- verify if variable exists
IF NOT EXISTS (SELECT Var_Id FROM dbo.Variables WHERE Var_Desc_Local = @VarDescLocal AND Pu_Id = @PuId)
	BEGIN
		SELECT 'Variable ' + @VarDescLocal + ' under production unit ' + @PuDescLocal + ' on production line ' + @PLDescLocal + ' not found.'
		RETURN
	END

-- set variable's Global description
UPDATE	dbo.Variables
SET		Var_Desc_Global = @VarDescGlobal
WHERE		Var_Desc_Local = @VarDescLocal
AND		Pu_Id = @PuId

SET NOCOUNT OFF


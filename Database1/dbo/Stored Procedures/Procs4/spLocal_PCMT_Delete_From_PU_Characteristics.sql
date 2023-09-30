








----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Delete_From_PU_Characteristics]

/*
Stored Procedure		:		spLocal_PCMT_Delete_From_PU_Characteristics
Author					:		Marc Charest (System Technologies for Industry Inc)
Date Created			:		28-Apr-2003
SP Type					:		
Editor Tab Spacing	:		3

Description:
===========
Delete all rows from PU_Characteristics for a given product.

CALLED BY				:  QSMT


Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.0.1				09-Jul-2003		Clement Morin				Delete only the row edit and respect the multiple line edition

1.1.0				04-Aug-2003		Rick Perreault				Delete all rows from PU_Characteristics for a specific unit, product and property 
																		and set the expiration date in var_specs

1.2.0				30-Dec-2005		Normand Carbonneau		Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		QSMT Version 10.0.0

1.3.0				26-Sep-2006		Normand Carbonneau		Now takes only Master Units to avoid the following example:
																		'Cartoner' slave unit returned with 'QXHYH0 Cartoner' Master Unit
																		
																		Also refined the Unit selection to have LineDesc + any + Unit Template
																		to avoid the following example:
																		'xxxQXHTR3 EDL' returned with 'QXHYR3 EDL'

1.3.1				2008-07022		Stephane Turner, STI		Correctly looks for pu_desc



*/

@ProdDesc 	varchar(50),
@PropId		INT,
@PU_Desc		varchar(50),
@PL_Id		INT = NULL

AS
SET NOCOUNT ON

DECLARE
@Prod_Id				INT,
@PU_Id				INT,
@ExpirationDate	datetime,
@PL_Desc				varchar(50)

--Set Expiration Date
SET @ExpirationDate = getdate()

--Retreive the Prod_Id
SET @Prod_Id = (SELECT Prod_Id FROM dbo.Products WHERE Prod_Desc = @ProdDesc)

--Retreive the Pu_Id
IF @PL_Id IS NOT NULL
	BEGIN
		SET @PL_Desc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @PL_Id)

		SET @PU_Id =(	SELECT	PU_Id
							FROM		dbo.Prod_Units
							WHERE		PL_Id = @PL_Id
							AND		((CHARINDEX(@PL_Desc, PU_Desc) > 0 AND CHARINDEX(@PU_Desc, PU_Desc) > 0) OR PU_Desc = @PU_Desc)
--							AND		(PU_Desc LIKE @PL_Desc + '%' + @PU_Desc OR PU_Desc = @PU_Desc)
							AND		Master_Unit IS NULL)
	END
ELSE
	BEGIN
		SET @PU_Id = (SELECT PU_Id FROM dbo.Prod_Units WHERE PU_Desc = @PU_Desc)
	END

DELETE	dbo.PU_Characteristics
FROM		dbo.PU_Characteristics
WHERE		Prod_Id = @Prod_Id
AND		Prop_Id = @PropId
AND		PU_Id = @PU_Id

UPDATE	dbo.Var_Specs 
SET		Expiration_Date = @ExpirationDate
WHERE		Expiration_Date IS NULL
AND		Prod_Id = @Prod_Id
AND		Var_Id IN	(
							SELECT	Var_Id
							FROM		dbo.Variables
							WHERE		PU_Id = @PU_Id
							)
AND		AS_Id IN		(
							SELECT	AS_Id
							FROM		dbo.Active_Specs a
							JOIN		dbo.Characteristics c ON (c.Char_Id = a.Char_Id)
							WHERE		c.Prop_Id = @PropId
							) 

--EXEC spEM_...

SELECT 1

SET NOCOUNT OFF









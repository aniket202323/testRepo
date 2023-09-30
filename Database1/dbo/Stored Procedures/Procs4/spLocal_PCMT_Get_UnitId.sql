















----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_UnitId]

/*
Stored Procedure		:		spLocal_PCMT_Get_UnitId
Author					:		Rick Perreault (System Technologies for Industry Inc)
Date Created			:		24-Feb-2003
SP Type					:		
Editor Tab Spacing	:		3

Description:
===========
Return the list of properties for a given unit name

CALLED BY				:  QSMT

Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.1.0				05-Jan-2006		Normand Carbonneau		Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		QSMT Version 10.0.0

1.2.0				26-Sep-2006		Normand Carbonneau		Now takes only Master Units to avoid the following example:
																		'Cartoner' slave unit returned with 'QXHYH0 Cartoner' Master Unit
																		
																		Also refined the Unit selection to have LineDesc + any + Unit Template
																		to avoid the following example:
																		'xxxQXHTR3 EDL' returned with 'QXHYR3 EDL'
																		



*/

@PL_Id			INT,
@PU_Desc			varchar(50),
@intMultiLine	INTEGER=0

AS
SET NOCOUNT ON

DECLARE
@PU_Id		INT,
@PL_Desc		varchar(50)

IF @intMultiLine = 0 BEGIN

	--SET @PL_Desc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @PL_Id)
	
	SET @PU_Id =	(
						SELECT	PU_Id
						FROM		dbo.Prod_Units
						WHERE		PL_Id = @PL_Id
						--AND		PU_Desc LIKE @PL_Desc + '%' + @PU_Desc
						AND		PU_Desc = @PU_Desc
						AND		Master_Unit IS NULL
						) END

ELSE BEGIN

	SET @PL_Desc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @PL_Id)
	
	SET @PU_Id =	(
						SELECT	PU_Id
						FROM		dbo.Prod_Units
						WHERE		PL_Id = @PL_Id
						AND		PU_Desc LIKE @PL_Desc + ' ' + @PU_Desc
						--AND		PU_Desc = @PU_Desc
						AND		Master_Unit IS NULL
						)

END

SELECT ISNULL(@PU_Id, 0)

SET NOCOUNT OFF














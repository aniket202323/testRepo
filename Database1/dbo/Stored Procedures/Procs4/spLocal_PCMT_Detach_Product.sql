











-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Detach_Product]
/*
Stored Procedure		:		spLocal_QSMT_Detach_Product
Author					:		Rick Perreault (System Technologies for Industry Inc)
Date Created			:		24-Feb-2003
SP Type					:		QSMT
Editor Tab Spacing	:		3
CALLED BY				:  	QSMT

Description:
===========
Detach the product from a given unit.

Revision 		Date				Who							What
========			===========		==================		=======================
1.2.0				2007-02-16		Vincent Rouleau (STI)	Detach the product from the path if the unit is a schedule point.

1.1.0				2005-12-30		Normand Carbonneau, STI	Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		QSMT Version 10.0.0

*/

@intProdId	INT,
@intUnitId	INT

AS
SET NOCOUNT ON

DECLARE
@intPathId		INT,
@intPEPPId		INT,
@SQLCommand		NVARCHAR(1000),
@ctr				INT,
@max				INT,
@AppVersion		varchar(10)

CREATE TABLE #Paths (
	NoPath INT identity(1, 1),
	PathId INT,
	PEPPId INT)

DELETE
FROM		dbo.PU_Characteristics
WHERE		(prod_id = @intProdId)
AND		(pu_id = @intUnitId)

DELETE
FROM		dbo.PU_Products
WHERE		(prod_id = @intProdId)
AND		(pu_id = @intUnitId)

-----------------------------------------
--Add to version 1.2.0
-----------------------------------------

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

--If Proficy 4, detach the product from the path
IF @AppVersion LIKE '4%'
BEGIN
	--Determine the paths where the unit is a schedule point
	SET @SQLCommand = 'SELECT u.path_id, p.pepp_id FROM dbo.prdexec_path_units u LEFT JOIN dbo.prdexec_path_products p ON u.path_id = p.path_id  
							AND p.prod_id = ' + CONVERT(varchar(10), @intProdId) + ' WHERE u.pu_id = ' + CONVERT(varchar(10), @intUnitId) + ' AND u.is_schedule_point = 1'

	INSERT INTO #Paths (PathId, PEPPId)
	EXEC sp_executesql @SQLCommand

	SET @ctr = 1
	SET @max = (SELECT MAX(NoPath) FROM #Paths)

	WHILE @ctr <= @max
	BEGIN
		SET @intPathId = NULL
		SET @intPEPPId = NULL

		--Get the path
		SELECT @intPathId = PathId, @intPEPPId = PEPPId FROM #Paths WHERE NoPath = @ctr

		IF @intPEPPId IS NOT NULL
		BEGIN
			--Link the products to the path
			SET @SQLCommand = 'EXEC spEMEPC_PutPathProducts ' + CONVERT(varchar(10), @intPathId) + ', ' +  CONVERT(varchar(10), @intProdId) + ', 1, ' + CONVERT(varchar(10), @intPEPPId)

			EXEC sp_executesql @SQLCommand
		END

		SET @ctr = @ctr + 1
	END
END

--Add to version 1.2.0 ends

UPDATE
	dbo.var_specs
SET
	expiration_date = GETDATE()
FROM
	dbo.variables v
	JOIN dbo.var_specs vs ON (v.var_id = vs.var_id AND v.pu_id = @intUnitId AND vs.prod_id = @intProdId)


SET NOCOUNT OFF


















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Delete_From_PU_Products]
/*
Stored Procedure		:		spLocal_PCMT_Delete_From_PU_Products
Author					:		Marc Charest (System Technologies for Industry Inc)
Date Created			:		28-Apr-2003	
SP Type					:		QSMT
Editor Tab Spacing	:		3
CALLED BY				:  	QSMT

Description:
===========
Delete all rows from PU_Products for a given product.

Revision 		Date				Who							What
========			===========		==================		=======================
-------------------------------------------------------------------------------------------------
Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2007-10-29
Version		:	1.2.1
Purpose		: 	Allow to use multiple lines
-------------------------------------------------------------------------------------------------
1.3.1				2008-06-02		Stephane Turner, STI		Make sure SP always return a value
1.3.0				2007-02-16		Vincent Rouleau, STI		Detach product from the path if unit is a schedule point.

1.2.0				2005-12-30		Normand Carbonneau, STI	Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		QSMT Version 10.0.0

1.1.0				04-Aug-2003		Rick Perreault, STI		Delete all rows from PU_Products for a specific unit and product
													               and set the expiration date in var_specs

1.0.1				09-Jul-2003		Clement Morin, STI		Delete only the row edit and respect the multiple line edition 	
*/

@vcrProdDesc 	varchar(50),
@vcrPuDesc		Varchar(50),
@intLineId		INT,
@MultiLine		INT

AS
SET NOCOUNT ON

Declare
@intProdID		INT,
@intPuId			INT,
@dtmExpiration	datetime,
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

--Set Expiration Date
SET @dtmExpiration = getdate()

--Retrieve the Prod_id
SET @intProdID = (SELECT prod_id FROM dbo.Products WHERE prod_desc = @vcrProdDesc)

--Retrieve the Pu_Id
IF @intLineId IS NOT NULL
	BEGIN
		IF @MultiLine = 1
		BEGIN
			SET @intPuId = (SELECT pu_id FROM dbo.prod_units WHERE (pu_desc like '% ' + @vcrPuDesc) AND (pl_id = @intLineId))
		END
		ELSE
		BEGIN
			SET @intPuId = (SELECT pu_id FROM dbo.prod_units WHERE pl_id = @intLineId AND pu_desc = @vcrPuDesc)
		END
	END
ELSE
	BEGIN
		SET @intPuId = (SELECT pu_id FROM dbo.prod_units WHERE pu_desc = @vcrPuDesc)
	END

IF @intPUId IS NOT NULL
BEGIN
DELETE 
FROM		dbo.PU_Characteristics
WHERE		(prod_id = @intProdId)
AND		(pu_id = @intPuId)

DELETE 
FROM		dbo.PU_Products
WHERE		(prod_id = @intProdID)
AND		(pu_id = @intPuId)

UPDATE	dbo.Var_Specs 
SET		expiration_date = @dtmExpiration
WHERE		(expiration_date IS NULL)
AND		(prod_id = @intProdId)
AND		var_id IN	(
							SELECT	var_id
							FROM		dbo.variables
							WHERE		pu_id = @intPuId
							)

-----------------------------------------------
--Add to version 1.3.0
-----------------------------------------------


-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

--If Proficy 4, detach the product from the path
IF @AppVersion LIKE '4%'
BEGIN
	--Determine the paths where the unit is a schedule point
	SET @SQLCommand = 'SELECT u.path_id, p.pepp_id FROM dbo.prdexec_path_units u LEFT JOIN dbo.prdexec_path_products p ON u.path_id = p.path_id  AND 
							p.prod_id = ' + CONVERT(varchar(10), @intProdId) + ' WHERE u.pu_id = ' + CONVERT(varchar(10), @intPUId) + ' AND u.is_schedule_point = 1'

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

--Add to version 1.3.0 ends

END

SELECT 1
							
SET NOCOUNT OFF


















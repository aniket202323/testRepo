











-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_New_Char_Link]
/*
Stored Procedure		:		spLocal_QSMT_New_Char_Link
Author					:		Rick Perrault (System Technologies for Industry Inc)
Date Created			:		24-Feb-2003
SP Type					:		QSMT
Editor Tab Spacing	:		3
CALLED BY				: 	 	QSMT

Description:
===========
Links the product to units and characteristics.

Revision 		Date				Who							What
========			===========		==================		=======================
1.7.0				2007-02-16		Vincent Rouleau, STI		Attach the product to the path if the unit is a schedule point.

1.6.0				2006-01-10		Normand Carbonneau, STI	Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		QSMT Version 10.0.0

1.5.1				04-Aug-2003		Marc Charest, STI			Remove the "AND Char_Id = @intCharId" criteria (see 2004-09-28 comment). 
																		This way one cannot try to insert duplicate key within PU_CHARACTERISTICS table

1.5.0				04-Aug-2003		Ugo Lapierre, STI			Char_desc for re_product_information is now build with prod_desc instead of prod_code

1.4.1				04-Aug-2003		Marc Charest, STI			Make some changes to go with splocal_QSMT_Set_Product version 4.1.1

1.4.0				04-Aug-2003		Rick Perreault, STI		Return 1 if the link have been update, else 0

1.3.0				07-Jul-2003		Clement Morin, STI		Transfert the name of the line to respect the Char_desc format 
																		(Char_desc<space>line)

1.2.0				25-Apr-2003		Marc Charest, STI			Back to version 1.0.0

1.1.0				16-Apr-2003		Marc Charest, STI			QSMT is now creating hierarchical characteristics. So one adds 
																		a variable to get production line description (@vcrPL_desc). Now 
																		one inserts 'Line Description' + '_' + 'Product Desciption'
																		characteristic into PU_Characteristics table.	
*/

@intUserID		INTEGER,
@intProdId		INT,
@intUnitId		INT,
@intPropId		INT = NULL,
@intCharId		INT = NULL,
@intLine			INT = NULL,				--1.3.0	
@strCharDesc	Varchar(100) = NULL  -- 1.3.0

AS
SET NOCOUNT ON

DECLARE
@vcrLine_desc		varchar(50),	--1.3.0
@AppVersion			varchar(50),
@intPathId			INT,
@SQLCommand			NVARCHAR(1000),
@ctr					INT,
@max					INT,
@intPEPPId			INT
--  @vcrPL_desc	varchar(50)	--1.1.0

CREATE TABLE #Paths (
	NoPath INT identity(1, 1),
	PathId INT,
	PEPPId INT)

IF @intPropId IS NULL
	BEGIN
--    --1.1.0
--    select @vcrPL_desc = pl_desc from prod_units pu, prod_lines pl where pu.pl_id = pl.pl_id and pu.pu_id = @intUnitId	--1.1.0

		SELECT	@intPropId = pp.prop_id, @intCharId = c.char_id
		FROM		dbo.Product_Properties pp
		JOIN		dbo.Characteristics c ON (pp.prop_id = c.prop_id)
		JOIN		dbo.Products p ON (p.prod_desc = c.char_desc)	--1.1.0  --1.5.0
--		JOIN		dbo.Products p ON (substring(@vcrPL_desc + '_' + p.prod_desc,1,50) = c.char_desc)	--1.1.0
		WHERE		pp.prop_desc = 'RE_Product Information'
		AND		p.prod_id = @intProdId

		IF NOT EXISTS	(
							SELECT	prod_id 
							FROM		dbo.PU_Products
							WHERE		Prod_Id = @intProdId
							AND		PU_Id = @intUnitId
							)
			BEGIN
				--INSERT	dbo.PU_Products (Prod_Id,PU_Id)
				--VALUES	(@intProdId,@intUnitId)
				EXECUTE spEM_CreateUnitProd @intUnitId, @intProdId, @intUserID
			END
		
		--------------------------------------------------
		--Added to version 1.7.0
		--------------------------------------------------

		-- Get the Proficy Database Version
		SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

		--If Proficy 4, attach the product to the path
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

				IF @intPEPPId IS NULL
				BEGIN
					--Link the products to the path
					SET @SQLCommand = 'EXEC spEMEPC_PutPathProducts ' + CONVERT(varchar(10), @intPathId) + ', ' +  CONVERT(varchar(10), @intProdId) + ', 1, NULL'

					EXEC sp_executesql @SQLCommand
				END

				SET @ctr = @ctr + 1
			END
		END

		--Add to Version 1.7.0 ends

		IF NOT EXISTS	(
							SELECT	prod_id 
							FROM		dbo.PU_Characteristics
							WHERE		Prod_Id = @intProdId
							AND		PU_Id = @intUnitId
							AND		Prop_Id = @intPropId) AND @intPropId IS NOT NULL
--							AND		Char_Id = @intCharId)	--2004-09-28
			BEGIN
				--INSERT	dbo.PU_Characteristics (Prod_Id,PU_Id,Prop_Id,Char_Id)
				--VALUES	(@intProdId,@intUnitId,@intPropId,@intCharId)
				EXECUTE spEM_PutUnitCharacteristic @intUnitId, @intProdId, @intPropId, @intCharId, @intUserID
			END
	END

-- 1.3.0 start
IF (@intLine IS NOT NULL) AND (@strCharDesc IS NOT NULL)
	BEGIN
		SET @vcrLine_desc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @intLine)
		SET @intCharId = NULL
		SET @intCharId = (SELECT Char_Id FROM dbo.Characteristics WHERE Char_Desc = @strCharDesc + ' ' + @vcrLine_desc)
		
		IF @intCharId IS NULL
			BEGIN
				RETURN
			END
	END
--1.3.0 end


--If the exact link does not exist
IF NOT EXISTS	(
					SELECT	prod_id 
					FROM		dbo.PU_Characteristics
					WHERE		Prod_Id = @intProdId
					AND		PU_Id = @intUnitId
					AND		Char_id = @intCharId
					AND		Prop_Id = @intPropId
					) AND @intPropId IS NOT NULL
	BEGIN
		--If the product-unit-property link already exist
		IF EXISTS	(
						SELECT	prod_id 
						FROM		dbo.PU_Characteristics
						WHERE		Prod_Id = @intProdId
						AND		PU_Id = @intUnitId
						AND		Prop_Id = @intPropId
						)
			BEGIN
				--UPDATE	dbo.PU_Characteristics
				--SET		Char_Id = @intCharId
				--WHERE		Prod_Id = @intProdId
				--AND		PU_Id = @intUnitId
				--AND		Prop_Id = @intPropId
				EXECUTE spEM_PutUnitCharacteristic @intUnitId, @intProdId, @intPropId, @intCharId, @intUserID
			END
		ELSE
			BEGIN
				--INSERT	dbo.PU_Characteristics (Prod_Id,PU_Id,Prop_Id,Char_Id)
				--VALUES	(@intProdId,@intUnitId,@intPropId,@intCharId)
				EXECUTE spEM_PutUnitCharacteristic @intUnitId, @intProdId, @intPropId, @intCharId, @intUserID
			END

		SELECT 1
  END 
ELSE     
  SELECT 0
     
DROP TABLE #Paths

SET NOCOUNT OFF













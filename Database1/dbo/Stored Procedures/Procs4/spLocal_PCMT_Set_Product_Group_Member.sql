
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Set_Product_Group_Member]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-11
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	Return the list of properties for a given unit name
-------------------------------------------------------------------------------------------------
*/

@intType		INT,
@intGroupId	INT,
@intProdId	INT = NULL

AS
SET NOCOUNT ON

IF @intType = 1
	BEGIN
		SELECT	p.prod_id, p.prod_desc
		FROM		dbo.Products p
      JOIN		dbo.Product_Group_Data pgd ON (p.prod_id = pgd.prod_id)
		WHERE		pgd.product_grp_id = @intGroupId
		ORDER BY p.prod_desc
	END
ELSE
	BEGIN
		IF @intType = 2
			BEGIN
				SELECT	prod_id, prod_desc
				FROM		dbo.Products 
				WHERE		prod_id NOT IN	(
												SELECT	prod_id
												FROM		dbo.Product_Group_Data
												WHERE		product_grp_id = @intGroupId
												)
				ORDER BY	prod_desc
			END
		ELSE
			BEGIN
				IF @intType = 3
					BEGIN
						IF @intProdId IS NOT NULL
							BEGIN
								INSERT	dbo.Product_Group_Data (Prod_Id,Product_Grp_Id)
								VALUES	(@intProdId,@intGroupId)
							END
						ELSE
							BEGIN
								INSERT	dbo.Product_Group_Data (Prod_Id,Product_Grp_Id)
									SELECT	prod_id, @intGroupId
									FROM		dbo.Products 
									WHERE		prod_id NOT IN	(
																	SELECT	prod_id
																	FROM		dbo.Product_Group_Data
																	WHERE		product_grp_id = @intGroupId
																	)
							END
					END
				ELSE
					BEGIN
						IF @intProdId IS NOT NULL
							BEGIN
								DELETE FROM	dbo.Product_Group_Data
								WHERE			Prod_Id = @intProdId
								AND			Product_Grp_Id = @intGroupId
							END
						ELSE
							BEGIN
								DELETE FROM	dbo.Product_Group_Data
								WHERE			Product_Grp_Id = @intGroupId
							END
					END
			END
	END
	
SET NOCOUNT OFF














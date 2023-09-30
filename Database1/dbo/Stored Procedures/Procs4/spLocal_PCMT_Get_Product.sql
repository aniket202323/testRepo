


-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Product]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-11-19
Version		:	3.3.0  => Compatible with PCMT version 1.7 and higher only
Purpose		: 	Change the select to fill @tblPUProductIDs

-------------------------------------------------------------------------------------------------
Updated By	:	Patrick-Daniel Dubois (System Technologies for Industry Inc)
Date			:	2008-04-22
Version		:	3.2.1  => Compatible with PCMT version 1.7 and higher only
Purpose		: 	Modified the Product comment management. 
					This has been done to be able to manage the comment in the Product Edit form.
					1- I added the variable @vcrProdComment VARCHAR(8000) that will hold the comment
					2- Added it's initialization => SET @vcrProdComment = ISNULL((SELECT CONVERT(VARCHAR(4000),Comment_Text) FROM dbo.comments WHERE comment_id = @intCommentId),' ')--> Added by PDD
					3- Return it in the result set => ISNULL(@vcrProdComment,' ') AS ProdComment --> Added by PDD
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-22
Version		:	3.0.0
Purpose		: 	Now returns the External_Link field in the Resultset for intType = 4.
					4: Product Info: Return Product Name, Product Code, Product_Family_Id and External_Link a given product.
					Use with QSMT Version 10.1.0 and higher
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-04
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced #tblLines and #tblPUProductIDs temp table by @tblLines and 
					@tblPUProductIDs TABLE variables.
					Eliminated #tblLineIDs temp table no longer necessary (included in @tblLines)
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Modified by	: 	Marc Chrest, Solutions et Technologies Industrielles inc.
On				:	23-Mar-2004
Version		: 	2.0.0
Purpose		: 	In case of @intId = 3, @intDescOrCode let us switch from prod_desc 
					to prod_code sort order.
					Still in case of @intId = 3, @vcrLineDesc let us select only
					selected lines attatched products.
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	1: Family: Return all the product families
					2: Group: Return all the product groups
               3: Product: if input is null, return the list of all products
                  else return the list of all products in the specified family.
               4: Product Info: Return product name, code, family and group od a given product.
-------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_PCMT_Get_Product 2,2,NULL,'DIMR004[REC]DIMR005[REC]DIMR007[REC]DIMR009[REC]'
-------------------------------------------------------------------------------------------------
*/
@intUserId		INTEGER,
@intType 		INT,
@intId			INT = NULL,
@intDescOrCode	INT = NULL,
@vcrLineDesc	varchar(500) = NULL

AS

SET NOCOUNT ON

DECLARE
@intBegPos			INT,
@intEndPos			INT,
@vcrLine				varchar(50),
@intCommentId		INTEGER,
@vcrProdDesc		VARCHAR(255),
@bitIsCommented	BIT,
@vcrProdComment	VARCHAR(8000) --> Added by PDD

DECLARE @Lines TABLE
(
PL_Id		INT,
PL_Desc	varchar(50),
Prod_Id	INT
)

DECLARE @tblPUProductIDs TABLE
(
Prod_Id	INT
)

--Security Utilization
CREATE TABLE #PCMTFamilyIDs(Item_Id INTEGER)
INSERT #PCMTFamilyIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'product_family', 'Product_Family_Id', @intUserId

SET @intBegPos = 1
	
WHILE @intBegPos <= LEN(@vcrLineDesc) 
	BEGIN
		SET @intEndPos = CHARINDEX('[REC]', @vcrLineDesc, @intBegPos)
		SET @vcrLine = SUBSTRING(@vcrLinedesc, @intBegPos, @intEndPos - @intBegPos)
		
		INSERT INTO @Lines (PL_Desc) VALUES (@vcrLine)
		
		SET @intBegPos = @intEndPos + 5
	END

UPDATE	@Lines
SET		PL_Id = pl.PL_Id
FROM		@Lines L
JOIN		dbo.Prod_Lines pl
ON			L.PL_Desc = pl.PL_Desc 

INSERT INTO	@tblPUProductIDs (Prod_Id)
/*
	SELECT DISTINCT	Prod_Id						-- DISTINCT added v10.0.0
	FROM					dbo.Products
*/

	SELECT DISTINCT	Prod_Id						-- DISTINCT added v10.0.0
	FROM					dbo.PU_Products
	WHERE					PU_Id IN	(
										SELECT	PU_Id
										FROM		dbo.Prod_Units
										WHERE		PL_Id IN	(
																SELECT	PL_Id
																FROM		@Lines
																)
										)


IF @intType = 1				--Family
	BEGIN
		SELECT	[ID] = Product_Family_Id, Family = Product_Family_Desc 
		FROM		dbo.Product_Family pf, #PCMTFamilyIDs pf2
		WHERE		pf.Product_Family_Id = pf2.item_id
		ORDER BY	Product_Family_Desc
	END
ELSE
	BEGIN
		IF @intType = 2		--Group
			BEGIN
				SELECT	[ID] = Product_Grp_Id, [Group] = Product_Grp_Desc
				FROM		dbo.Product_Groups
				ORDER BY	Product_Grp_Desc
			END
		ELSE
			BEGIN
				IF @intType = 3 --Product
					BEGIN
						IF @intId IS NOT NULL
							BEGIN
								IF @intDescOrCode IS NULL
									BEGIN
										SELECT	[ID] = Prod_Id, Product = Prod_Desc
										FROM		dbo.Products
										WHERE		Product_Family_Id = @intId
										AND		Prod_Id IN	(
																	SELECT	Prod_Id
																	FROM		@tblPUProductIDs
																	)
										ORDER BY	Prod_Desc ASC
									END
								ELSE
									BEGIN
										SELECT	[ID] = Prod_Id, Product = Prod_Code
										FROM		dbo.Products
										WHERE		Product_Family_Id = @intId
										AND		Prod_Id IN	(
																	SELECT	Prod_Id
																	FROM		@tblPUProductIDs
																	)
										ORDER BY	Prod_Code ASC
									END
							END
						ELSE
							BEGIN
								IF @intDescOrCode IS NULL
									BEGIN
										SELECT	[ID] = Prod_Id, Product = Prod_Desc
										FROM		dbo.Products p, dbo.Product_Family pf, #PCMTFamilyIDs pf2
										WHERE		Prod_Id IN	(
																	SELECT	Prod_Id
																	FROM		@tblPUProductIDs
																	)
													AND p.product_family_id = pf.product_family_id
													AND pf.product_family_id = pf2.item_id
										ORDER BY	Prod_Desc ASC
									END
								ELSE
									BEGIN
										SELECT	[ID] = Prod_Id, Product = Prod_Code
										FROM		dbo.Products p, dbo.Product_Family pf, #PCMTFamilyIDs pf2
										WHERE		Prod_Id IN	(
																	SELECT	Prod_Id
																	FROM		@tblPUProductIDs
																	)
													AND p.product_family_id = pf.product_family_id
													AND pf.product_family_id = pf2.item_id
										ORDER BY Prod_Code ASC
									END
							END
					END
				ELSE				-- Product Info
					BEGIN

						--Want to know if product has comment with product description in it
						SET @intCommentId = (SELECT comment_id FROM dbo.products WHERE prod_id = @intId)
						SET @vcrProdDesc = (SELECT prod_desc_local FROM dbo.products WHERE prod_id = @intId)
						SET @bitIsCommented = 0
						IF @intCommentId IS NOT NULL BEGIN
							SET @bitIsCommented = (SELECT CHARINDEX(@vcrProdDesc, comment) FROM dbo.comments WHERE comment_id = @intCommentId)
							SET @vcrProdComment = ISNULL((SELECT CONVERT(VARCHAR(4000),Comment_Text) FROM dbo.comments WHERE comment_id = @intCommentId),' ')--> Added by PDD
						END

						--Returning product info
						SELECT	Prod_Desc, Prod_Code, Product_Family_Id, External_Link, Prod_Desc_Global, Prod_Desc_Local, Prod_id, @bitIsCommented AS [Is_Commented]
							,ISNULL(REPLACE(@vcrProdComment,'\par',' '),' ') AS ProdComment --> Added by PDD
						FROM		dbo.Products p
						WHERE		p.prod_id = @intId
					END
			END
	END

DROP TABLE #PCMTFamilyIDs

SET NOCOUNT OFF



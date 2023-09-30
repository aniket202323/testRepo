--=====================================================================================================================
-- Store Procedure: 	spLocal_BETS_WebDialog_LocalSelectAllProducts
-- Author:				Jose Martinez
-- Date Created:		2007-12-14
-- Sp Type:				Store Procedure
-- Editor Tab Spacing: 	4
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION:
-- This stored procedure returns all products or products groups when the user doesn't select filters before
-- using the web dialogs Local Filter Select Products and Local Select Filter Product Groups
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2008-04-23  Jose Martinez		Initial Development
-- 1.1			2008-05-06	Paula Lafuente		Change sp name 
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-----------------------------------------------------------------------------------------------------------------------
--	EXEC spLocal_BETS_WebDialog_LocalSelectAllProducts
-- 		0,				-- 	output: @ErrorCode
-- 		'',				-- 	output: @ErrorMessage
--		1,				-- 	@p_intOption
						--  1 returns Products
						--  0 returns Product Groups
--		1,				-- 	@p_returnCount
						--  1 returns count
						--  0 returns entire results
--		1,				--  @p_searchby
						--  0 Search by Code6
						--  1 Serch by Description 
--		!NULL			--  List of product groups selected
-----------------------------------------------------------------------------------------------------------------------
--Parameters
-----------------------------------------------------------------------------------------------------------------------
-- 	output: @ErrorCode   				-- 	Return the error code
-- 	output: @ErrorMessage				-- 	Return the error message
--  @p_intOption
										--  1 returns Products
										--  0 returns Product Groups
--  @p_returnCount
										--  1 returns count
										--  0 returns entire results
--  @p_searchby
										--  0 Search by Code
										--  1 Serch by Description 
--		!NULL							--  List of product groups selected
--=====================================================================================================================
CREATE	PROCEDURE [dbo].[spLocal_BETS_WebDialog_LocalSelectAllProducts]
		@ErrorCode								INT OUTPUT,
		@ErrorMessage							VARCHAR(1000) OUTPUT,
		@p_intOption							INT = 1,
		@p_returnCount							INT = 1,
		@p_searchby								INT = 1,
		@p_vchstrRptProdGroupIdList				VARCHAR(250) 
AS
--=====================================================================================================================
SET NOCOUNT ON
--=====================================================================================================================
-- VARIABLES
--=====================================================================================================================
DECLARE @tblProdGroupsTable TABLE(
	RcdIdx		INT IDENTITY(1,1),
	ProdGroupId	INT)
-----------------------------------------------------------------------------------------------------------------------
-- TEMP TABLE used for parsing labels
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE	#TempParsingTable	(
				RcdId			INT,
				ValueINT		INT,
				ValueVARCHAR100	VARCHAR(100))
-----------------------------------------------------------------------------------------------------------------------
--Parameter @p_intOption = 1. The store procedure returns Products or the count of those
-----------------------------------------------------------------------------------------------------------------------
IF @p_intOption = 1 
BEGIN
	---------------------------------------------------------------------------------------------------------------
	-- Parse product group list
	---------------------------------------------------------------------------------------------------------------
	IF @p_vchstrRptProdGroupIdList IS NOT NULL AND UPPER(@p_vchstrRptProdGroupIdList) <> '!NULL'
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		-- SPLIT the values of the product units list
		---------------------------------------------------------------------------------------------------------------
		TRUNCATE TABLE	#TempParsingTable
		INSERT INTO	#TempParsingTable(RcdId, ValueINT)
		EXEC	spCMN_ReportCollectionParsing 
				@PRMCollectionString = 	@p_vchstrRptProdGroupIdList,
				@PRMFieldDelimiter = NULL,		
				@PRMRecordDelimiter = '|',
				@PRMDataType01 = 'INT'
		---------------------------------------------------------------------------------------------------------------
		-- INSERT the values to the @tblProdUnitsTable
		---------------------------------------------------------------------------------------------------------------
		INSERT INTO @tblProdGroupsTable(
				ProdGroupId)
		SELECT	ValueINT
		FROM	#TempParsingTable
		-------------------------------------------------------------------------------------------------------------------
		--Parameter @p_returnCount = 1. The store procedure returns count of Products
		-------------------------------------------------------------------------------------------------------------------
		IF @p_returnCount = 1 
		BEGIN
			SELECT "" as Prod_Code, COUNT(p.prod_id) as Prod_id
			FROM dbo.products 	p	WITH (NOLOCK)
			JOIN	dbo. product_Group_Data pgd		on  p.prod_id = pgd.prod_id
			JOIN	dbo. product_groups		pg		on	pgd.product_grp_id = pg.product_grp_id
			JOIN	@tblProdGroupsTable		tpg		on  tpg.ProdGroupId = pg.product_grp_id
	
		END
		-------------------------------------------------------------------------------------------------------------------
		--Parameter @p_returnCount =0. The store procedure returns Products
		-------------------------------------------------------------------------------------------------------------------
		ELSE IF @p_returnCount = 0
		BEGIN
			---------------------------------------------------------------------------------------------------------------
			--Parameter @p_searchby = 0. The store procedure returns prod_code of Products
			---------------------------------------------------------------------------------------------------------------
			IF @p_searchby = 0
			BEGIN
				 SELECT  
					p.prod_id,  
					p.prod_code 
				FROM dbo.products 	p	WITH (NOLOCK)
				JOIN	dbo. product_Group_Data pgd		on  p.prod_id = pgd.prod_id
				JOIN	dbo. product_groups		pg		on	pgd.product_grp_id = pg.product_grp_id
				JOIN	@tblProdGroupsTable		tpg		on  tpg.ProdGroupId = pg.product_grp_id
			END
			---------------------------------------------------------------------------------------------------------------
			--Parameter @p_searchby = 1. The store procedure returns prod_desc of Products
			---------------------------------------------------------------------------------------------------------------	
			ELSE IF @p_searchby = 1
			BEGIN			
				 SELECT  
					p.prod_id,  
					p.prod_desc 
				FROM dbo.products	p	WITH (NOLOCK)
				JOIN	dbo. product_Group_Data pgd		on  p.prod_id = pgd.prod_id
				JOIN	dbo. product_groups		pg		on	pgd.product_grp_id = pg.product_grp_id
				JOIN	@tblProdGroupsTable		tpg		on  tpg.ProdGroupId = pg.product_grp_id
			END
		END

	END
	ELSE
	BEGIN
		-------------------------------------------------------------------------------------------------------------------
		--Parameter @p_returnCount = 1. The store procedure returns count of Products
		-------------------------------------------------------------------------------------------------------------------
		IF @p_returnCount = 1 
		BEGIN
			SELECT "" as Prod_Code, COUNT(p.prod_id) as Prod_id
			FROM dbo.products 	p	WITH (NOLOCK)
	
		END
		-------------------------------------------------------------------------------------------------------------------
		--Parameter @p_returnCount =0. The store procedure returns Products
		-------------------------------------------------------------------------------------------------------------------
		ELSE IF @p_returnCount = 0
		BEGIN
			---------------------------------------------------------------------------------------------------------------
			--Parameter @p_searchby = 0. The store procedure returns prod_code of Products
			---------------------------------------------------------------------------------------------------------------
			IF @p_searchby = 0
			BEGIN
				 SELECT  
					p.prod_id,  
					p.prod_code 
				FROM dbo.products 	p	WITH (NOLOCK)
			END
			---------------------------------------------------------------------------------------------------------------
			--Parameter @p_searchby = 1. The store procedure returns prod_desc of Products
			---------------------------------------------------------------------------------------------------------------	
			ELSE IF @p_searchby = 1
			BEGIN			
				 SELECT  
					p.prod_id,  
					p.prod_desc 
				FROM dbo.products	p	WITH (NOLOCK)
			END
		END
	END
END
-----------------------------------------------------------------------------------------------------------------------
--Parameter @p_intOption = 0. The store procedure returns Product Groups or the count of those
-----------------------------------------------------------------------------------------------------------------------
ELSE IF @p_intOption = 0
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	--Parameter @p_returnCount = 1. The store procedure returns count of Product Groups
	-------------------------------------------------------------------------------------------------------------------
	IF @p_returnCount = 1 
	BEGIN
		 SELECT  "" as product_grp_desc, COUNT(product_grp_id) as  product_grp_id
		FROM dbo.product_groups
 
	END
	-------------------------------------------------------------------------------------------------------------------
	--Parameter @p_returnCount =0. The store procedure returns Product Groups
	-------------------------------------------------------------------------------------------------------------------
	ELSE 	IF @p_returnCount = 0 
	BEGIN
		 SELECT  
			product_grp_id,  
			product_grp_desc 
		FROM dbo.product_groups
	END
END
--=====================================================================================================================	
SET NOCOUNT ON
--=====================================================================================================================
DROP TABLE #TempParsingTable
--=====================================================================================================================
RETURN



--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Process_Orders_BOM
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-02-03
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Get process order BOM
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--



--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-02-03		F. Bergeron				Initial Release 

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_Get_Process_Orders_BOM] 15043

SELECT * FROM production_plan where Path_id = 210

SELECT * FROM prdexec_paths WHERE path_code LIKE 'CTS%'
SELECT * FROM [dbo].[Bill_Of_Material_Formulation_Item] WHERE BOM_Formulation_id = 4410
SELECT * FROM Engineering_Unit WHERE eng_unit_id = 50027
*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Process_Orders_BOM]
@PP_Id							INTEGER

		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON



--Output table
DECLARE @Output TABLE 
(	
	PP_Id						INTEGER,
	BOM_Formulation_Id			INTEGER,
	Product_Id					INTEGER,
	Product_code				VARCHAR(50),
	Product_Desc				VARCHAR(50),
	Quantity					FLOAT,
	UOM							VARCHAR(25)
)


INSERT INTO @Output
(	PP_Id,
	BOM_Formulation_Id,
	Product_Id,
	Product_code,
	Product_Desc,
	Quantity,
	UOM
)
SELECT	@PP_Id,
		PP.BOM_Formulation_Id,
		COALESCE(BOMS.Prod_Id, BOMFI.prod_id),
		COALESCE(PB2.Prod_code, PB1.prod_code),
		COALESCE(PB2.Prod_Desc, PB1.prod_Desc),
		(	
		CASE 
			WHEN	EU2.Eng_unit_code IS NOT NULL
			THEN	BOMFI.Quantity * BOMS.conversion_Factor
			ELSE	BOMFI.Quantity
		END
		),
		COALESCE(EU2.Eng_unit_code, EU1.Eng_unit_code)		
FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI WITH(NOLOCK)	
			ON PP.BOM_Formulation_Id = BOMFI.BOM_Formulation_Id
		JOIN dbo.products_base PB1 
			ON PB1.prod_id = BOMFI.prod_id
		JOIN dbo.Engineering_Unit EU1
			ON EU1.eng_unit_id = BOMFI.Eng_unit_id
		LEFT JOIN dbo.Bill_Of_Material_Substitution BOMS	WITH(NOLOCK)	
			ON BOMFI.BOM_Formulation_Item_Id = BOMS.BOM_Formulation_Item_Id
		LEFT JOIN dbo.products_base PB2 
			ON PB2.prod_id = BOMS.prod_id
		LEFT JOIN dbo.Engineering_Unit EU2
			ON EU2.eng_unit_id = BOMS.Eng_unit_id

WHERE	pp.pp_id = @PP_Id
						
SELECT	DISTINCT PP_Id,
		BOM_Formulation_Id,
		Product_Id,
		Product_code,
		Product_Desc,
		Quantity,
		UOM 
FROM	@Output

LaFin:

SET NOCOUNT OFF

RETURN

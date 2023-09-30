 
 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_CreateProcessOrder]
		@PathCode			VARCHAR(255),
		@ProdCode			VARCHAR(255),
		@ForecastQuantity	FLOAT,
		@ProcessOrder		VARCHAR(255) = NULL
AS	
-------------------------------------------------------------------------------
-- Create Pre Weigh Process Order
/*
exec spLocal_MPWS_GENL_CreateProcessOrder 'PW01', 'FG01', 100, 'PO01'
*/
-- Date         Version Build Author  
-- 06-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@BOMId		INT,
		@BOMFId		INT,
		@ProdId		INT,
		@PPId		INT,
		@PathId		INT,
		@KeyId		INT
-------------------------------------------------------------------------------
-- Check Parameters
-------------------------------------------------------------------------------
SELECT	@ProdId = NULL
SELECT	@ProdId = Prod_Id
		FROM	dbo.Products_Base		WITH (NOLOCK)
		WHERE	Prod_Code		= @ProdCode
		
IF		@ProdId	IS NULL
BEGIN
		SELECT	'Product Not Found'
		RETURN
END
 
SELECT	@PathId = NULL
SELECT	@PathId = Path_Id
		FROM	dbo.PrdExec_Paths	WITH (NOLOCK)
		WHERE	Path_Code		= @PathCode
 
IF		@PathId	IS NULL
BEGIN
		SELECT	'Path Not Found'
		RETURN
END
-------------------------------------------------------------------------------
--  Handle input parameters
-------------------------------------------------------------------------------						
IF		@ProcessOrder	IS NULL
		SELECT	@ProcessOrder = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(25), GETDATE(), 120),':',''), '-',''), ' ','')
-------------------------------------------------------------------------------
--  Handle BOM
-------------------------------------------------------------------------------	
INSERT	dbo.Bill_Of_Material	(BOM_Desc, BOM_Family_Id, Is_Active)
		VALUES (@ProcessOrder, 2, 1)
SELECT	@BOMId	= @@IDENTITY
-------------------------------------------------------------------------------
--  Handle BOMF
-------------------------------------------------------------------------------	
INSERT	dbo.Bill_Of_Material_Formulation (BOM_Formulation_Code, BOM_Formulation_Desc, 
		BOM_Id, Eng_Unit_Id, Quantity_Precision, Standard_Quantity)
		VALUES (@ProcessOrder, @ProcessOrder, @BOMId, 50002, 2, @ForecastQuantity)
SELECT	@BOMFId	= @@IDENTITY		
-------------------------------------------------------------------------------
--  Handle BOMFI
-------------------------------------------------------------------------------	
IF		@ProdCode = 'FG01'
BEGIN
		INSERT	dbo.Bill_Of_Material_Formulation_Item (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision)
				-- SELECT	@BOMFId, 1, 50002, 2, P.Prod_Id, @ForecastQuantity, 2, 0, 1, 2
				SELECT	@BOMFId, 1, 50002, 2, P.Prod_Id, @ForecastQuantity/2, 2, 0, 1, 2
						FROM	dbo.Products_Base P		WITH (NOLOCK)
						WHERE	Prod_Code = 'RM01'
		SELECT	@KeyId	= @@IDENTITY						
 
							
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, '1'
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'BOMItemStatus'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'						
						
						
						
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, NULL
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'DispenseStationId'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'				
										
		INSERT	dbo.Bill_Of_Material_Formulation_Item (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision)
				-- SELECT	@BOMFId, 2, 50002, 2, P.Prod_Id, @ForecastQuantity*2, 2, 0, 1, 2
				SELECT	@BOMFId, 2, 50002, 2, P.Prod_Id, @ForecastQuantity/4, 2, 0, 1, 2
						FROM	dbo.Products_Base P		WITH (NOLOCK)
						WHERE	Prod_Code = 'RM02'
		
		SELECT	@KeyId	= @@IDENTITY						
 
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, '1'
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'BOMItemStatus'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'
						
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, NULL
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'DispenseStationId'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'	
						
						
						
		INSERT	dbo.Bill_Of_Material_Formulation_Item (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision)
				-- SELECT	@BOMFId, 3, 50002, 2, P.Prod_Id, @ForecastQuantity*3, 2, 0, 1, 2
				SELECT	@BOMFId, 3, 50002, 2, P.Prod_Id, @ForecastQuantity/4, 2, 0, 1, 2
						FROM	dbo.Products_Base P		WITH (NOLOCK)
						WHERE	Prod_Code = 'RM03'
						
		SELECT	@KeyId	= @@IDENTITY						
 
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, '1'
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'BOMItemStatus'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'
						
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, NULL
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'DispenseStationId'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'					
						
END
ELSE
BEGIN
		INSERT	dbo.Bill_Of_Material_Formulation_Item (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision)
				--SELECT	@BOMFId, 1, 50002, 2, P.Prod_Id, @ForecastQuantity, 2, 0, 1, 2
				SELECT	@BOMFId, 1, 50002, 2, P.Prod_Id, @ForecastQuantity, 2, 0, 1, 2
						FROM	dbo.Products_Base P		WITH (NOLOCK)
						WHERE	Prod_Code = 'RM01'
						
		SELECT	@KeyId	= @@IDENTITY						
 
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, '1'
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'BOMItemStatus'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'
						
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, NULL
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'DispenseStationId'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'
 
		INSERT	dbo.Bill_Of_Material_Formulation_Item (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision)
				--SELECT	@BOMFId, 2, 50002, 2, P.Prod_Id, @ForecastQuantity*2, 2, 0, 1, 2
				SELECT	@BOMFId, 2, 50002, 2, P.Prod_Id, @ForecastQuantity/4, 2, 0, 1, 2
						FROM	dbo.Products_Base P		WITH (NOLOCK)
						WHERE	Prod_Code = 'RM02'
						
		SELECT	@KeyId	= @@IDENTITY						
 
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, '1'
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'BOMItemStatus'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'
						
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, NULL
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'DispenseStationId'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'				
						
		INSERT	dbo.Bill_Of_Material_Formulation_Item (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision)
				--SELECT	@BOMFId, 3, 50002, 2, P.Prod_Id, @ForecastQuantity*3, 2, 0, 1, 2
				SELECT	@BOMFId, 3, 50002, 2, P.Prod_Id, @ForecastQuantity/4, 2, 0, 1, 2
						FROM	dbo.Products_Base P		WITH (NOLOCK)
						WHERE	Prod_Code = 'RM04'
						
		SELECT	@KeyId	= @@IDENTITY						
 
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, '1'
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'BOMItemStatus'
						AND		T.TableId = T.TableId
						AND		T.TableName			= 'Bill_Of_Material_Formulation_Item'
						
		INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
				SELECT	@KeyId, TF.Table_Field_Id, T.TableId, NULL
						FROM	dbo.Table_Fields TF		WITH (NOLOCK)
						JOIN	dbo.Tables T			WITH (NOLOCK)
						ON		TF.Table_Field_Desc =	'DispenseStationId'
						AND		T.TableId = T.TableId
						AND		T.TableName			='Bill_Of_Material_Formulation_Item'						
END
-------------------------------------------------------------------------------
--  Handle PO
-------------------------------------------------------------------------------	
-- Production_Plan
-------------------------------------------------------------------------------	
INSERT	dbo.Production_Plan (Forecast_Start_Date, Forecast_End_Date, Entry_On, 
		Forecast_Quantity, PP_Type_Id, User_Id, Prod_Id, PP_Status_Id, Process_Order,
		BOM_Formulation_Id, Control_Type, Path_Id) 
		VALUES (GETDATE(), DATEADD(hh, 2, GETDATE()), GETDATE(), @ForecastQuantity,
				1, 1, @ProdId, 1, @ProcessOrder, @BOMFId, 2, @PathId)
			
SELECT	@PPId = PP_Id
		FROM	dbo.Production_Plan
		WHERE	Path_Id			= @PathId
		AND		Process_Order	= @ProcessOrder		
-------------------------------------------------------------------------------	
-- Priority for PO
-------------------------------------------------------------------------------					
INSERT	dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
		SELECT	@PPId, Table_Field_Id, 7, 1
				FROM	dbo.Table_Fields TF		WITH (NOLOCK)
				WHERE	TF.Table_Field_Desc = 'PreWeighProcessOrderPriority'
				AND		TF.TableId			= 7
-------------------------------------------------------------------------------	
-- Production_Setup
-------------------------------------------------------------------------------					
INSERT	dbo.Production_Setup (Forecast_Quantity, PP_Status_Id, PP_Id, 
		Pattern_Code,Entry_On, User_Id)
		VALUES (@ForecastQuantity, 1, @PPId, @ProcessOrder, GETDATE(), 1)
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_GENL_CreateProcessOrder] TO [public]
 
 
 
 
 
 

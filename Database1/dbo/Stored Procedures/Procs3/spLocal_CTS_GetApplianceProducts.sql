

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetApplianceProducts
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-19
-- Version 				: Version <1.1>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Return all possible Appliance products based on specified criteria
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--



--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-19		U.Lapierre				Initial Release 
-- 1.1		2022-01-11		F.Bergeron				Add parameter to filter location based on destination Process order
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

DECLARE 
@LocationStr							varchar(3000),
@ApplianceStatusStr							varchar(3000),
@ApplianceTypeStr						varchar(3000),
@destination_location_PP				integer = NULL

SET @LocationStr = '10415'
SET @ApplianceStatusStr ='In Use,Clean'
SET @ApplianceTypeStr = 'IBC'
SET @destination_location_PP =16268

EXEC [dbo].[spLocal_CTS_GetApplianceProducts] @LocationStr, @ApplianceStatusStr, @ApplianceTypeStr,@destination_location_PP


*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_GetApplianceProducts]
@LocationStr						varchar(3000),
@ApplianceStatusStr					varchar(3000),
@ApplianceTypeStr					varchar(3000),
@destination_location_PPId			integer = NULL
		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100),
@tfIdLocationType				int,
@TableIdProdUnits				int

DECLARE @output TABLE
(
	prod_id	Integer,
	prod_code varchar(50),
	prod_Desc varchar(50)
)

DECLARE @LocationFilter TABLE (
pu_id						int
)

CREATE TABLE #AllLocation (
LocationPUID					int,
AppliancePUID					int
)



DECLARE @ApplianceStatus TABLE (
ApplianceStatus				varchar(30)
)

DECLARE @ApplianceType TABLE (
Type						varchar(50)
)

DECLARE	@ApplianceStatusEvent TABLE
	(
		Serial											VARCHAR(25),
		Appliance_Id									INTEGER,
		Appliance_desc									VARCHAR(50),
		Appliance_Type									VARCHAR(50),
		Appliance_location_Id							INTEGER,
		Appliance_location_Desc							VARCHAR(50),
		Cleaning_status									VARCHAR(25),
		Cleaning_Type									VARCHAR(25),
		Cleaning_PU_Id									INTEGER,
		Cleaning_PU_Desc								VARCHAR(50),	
		Appliance_PP_Id									INTEGER,
		Appliance_process_order							VARCHAR(50),
		Appliance_process_order_product_Id				INTEGER,
		Appliance_process_order_product_code			VARCHAR(50),
		Appliance_process_order_status_Id				INTEGER,
		Appliance_process_order_status_Desc				VARCHAR(50),
		Reservation_type								VARCHAR(25),
		Reservation_PU_Id								INTEGER,
		Reservation_PU_Desc								VARCHAR(50),
		Reservation_PP_Id								INTEGER,
		Reservation_Process_Order						VARCHAR(50),
		Reservation_Product_Id							INTEGER,
		Reservation_Product_Code						VARCHAR(50),
		Action_Reservation_Is_Active					BIT,
		Action_Cleaning_Is_Active						BIT,
		Action_Movement_Is_Active						BIT,
		Access											VARCHAR(25),
		Err_Warn										VARCHAR(500) )





IF @LocationStr  ='Any'
	SET @LocationStr = NULL

IF @ApplianceStatusStr  ='Any'
	SET @ApplianceStatusStr = NULL

IF @ApplianceTypeStr  ='Any'
	SET @ApplianceTypeStr = NULL



--Get all location based on location type and Location status
INSERT INTO #AllLocation (LocationPUID, AppliancePUID)
SELECT DISTINCT puB.pu_id, puA.PU_Id
FROM dbo.Prod_Units_Base puA		WITH(NOLOCK)
JOIN dbo.prdExec_input_Sources peis	WITH(NOLOCK) ON puA.pu_id = peis.pu_id
JOIN dbo.prdExec_inputs	pei			WITH(NOLOCK) ON peis.pei_id = pei.pei_id
JOIN dbo.prod_units_Base puB		WITH(NOLOCK) ON pei.pu_id = puB.pu_id
WHERE puA.Equipment_Type = 'CTS Appliance'


IF @LocationStr IS NOT NULL
BEGIN
	--filter location

	INSERT @LocationFilter (pu_Id)
	SELECT CAST(value as INTEGER) FROM STRING_SPLIT(@LocationStr, ',');

	DELETE #AllLocation WHERE LocationPUID NOT IN (SELECT pu_id FROM @LocationFilter)
END


--Filter applianceType
IF @ApplianceTypeStr IS NOT NULL
BEGIN

	SET @TableIdProdUnits	= (	SELECT tableId 
								FROM dbo.tables WITH(NOLOCK) 
								WHERE TableName = 'Prod_units'
							)

	SET @tfIdLocationType	= (	SELECT table_field_id 
								FROM dbo.table_fields WITH(NOLOCK) 
								WHERE tableid = @TableIdProdUnits 
								AND Table_Field_Desc = 'CTS Appliance type'
								)

	INSERT INTO @ApplianceType(Type)
	SELECT value FROM STRING_SPLIT(@ApplianceTypeStr, ',');

	DELETE #AllLocation WHERE AppliancePUID NOT IN (
													SELECT pu.pu_id
													FROM dbo.prod_units_base pu			WITH(NOLOCK)
													JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON pu.pu_id = tfv.keyid AND tfv.Table_Field_Id = @tfIdLocationType
													WHERE tfv.value IN (SELECT type FROM @ApplianceType)
													)

END



--Filter applianceSTATUS
IF @ApplianceStatusStr IS NOT NULL
BEGIN
	INSERT @ApplianceStatusEvent(	
											Serial,
											Appliance_Id,
											Appliance_desc,
											Appliance_Type,
											Appliance_location_Id,
											Appliance_location_Desc,
											Cleaning_status,
											Cleaning_Type,
											Cleaning_PU_Id,
											Cleaning_PU_Desc,	
											Appliance_PP_Id,
											Appliance_process_order,
											Appliance_process_order_product_Id,
											Appliance_process_order_product_code,
											Appliance_process_order_status_Id,
											Appliance_process_order_status_Desc,
											Reservation_type,
											Reservation_PU_Id,
											Reservation_PU_Desc,
											Reservation_PP_Id,
											Reservation_Process_Order,
											Reservation_Product_Id,
											Reservation_Product_Code,
											Action_Reservation_Is_Active,
											Action_Cleaning_Is_Active,
											Action_Movement_Is_Active,
											Access,
											Err_Warn		
							)
	EXEC dbo.spLocal_CTS_Get_Appliances 	NULL,
											NULL,
											@ApplianceStatusStr	,
											NULL,
											NULL,
											NULL



	DELETE #AllLocation WHERE LocationPUID NOT IN (SELECT Appliance_location_Id FROM @ApplianceStatusEvent)

END


INSERT INTO @Output
(
	Prod_id,
	prod_code,
	prod_desc
)					
SELECT	DISTINCT
		p.prod_id	as 'Prod_Id',
		p.prod_code as 'Prod_Code',
		p.prod_Desc as 'Prod_Desc'
FROM	dbo.pu_products pup	WITH(NOLOCK)
JOIN	dbo.products_base p	WITH(NOLOCK)		
			ON pup.prod_id	= p.prod_id
JOIN	#AllLocation	l									
			ON l.LocationPUID = pup.pu_id

-- EXCLUDE PRODUCTS NOT PART OF THE DERIVED BOM OF THE PO
DECLARE @ValidProductId TABLE(
Prod_id INTEGER)

IF @destination_location_PPId IS NOT NULL
BEGIN
	/*
	IF (SELECT COUNT(1) FROM @LocationFilter) = 0
	BEGIN
	*/
	INSERT INTO @ValidProductId(Prod_id)
	SELECT  prod_id 
	FROM	dbo.production_plan WITH(NOLOCK) 
	WHERE	PP_id = @destination_location_PPId



	INSERT INTO			@ValidProductId(Prod_id)
	SELECT DISTINCT		BOMFI.Prod_Id 
	FROM				dbo.production_plan PP WITH(NOLOCK)
						JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI WITH(NOLOCK)
							ON PP.BOM_Formulation_Id = BOMFI.BOM_Formulation_Id
						LEFT JOIN dbo.Bill_Of_Material_Substitution BOMS	WITH(NOLOCK)
							ON BOMFI.BOM_Formulation_Item_Id = BOMS.BOM_Formulation_Item_Id
	WHERE				PP.PP_id = @destination_location_PPId


	INSERT INTO @Output
	(
		Prod_id,
		prod_code,
		prod_desc
	)					
	SELECT	DISTINCT
			p.prod_id	as 'Prod_Id',
			p.prod_code as 'Prod_Code',
			p.prod_Desc as 'Prod_Desc'
	FROM 	@ValidProductId	VPI	
	JOIN dbo.products_base p WITH(NOLOCK)		
		ON VPI.prod_id = p.prod_id

	DELETE	@Output 
	WHERE	prod_id NOT IN (
							SELECT Prod_id FROM @ValidProductId
							)
	/*	
	END
	ELSE
	BEGIN

		INSERT INTO @ValidProductId(Prod_id)
		SELECT  prod_id 
		FROM	dbo.production_plan WITH(NOLOCK) 
		WHERE	PP_id = @destination_location_PPId



		INSERT INTO			@ValidProductId(Prod_id)
		SELECT DISTINCT		COALESCE(BOMFI.Prod_Id,BOMS.prod_id)
		FROM				dbo.production_plan PP WITH(NOLOCK)
							JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI WITH(NOLOCK)
								ON PP.BOM_Formulation_Id = BOMFI.BOM_Formulation_Id
							LEFT JOIN dbo.Bill_Of_Material_Substitution BOMS	WITH(NOLOCK)
								ON BOMFI.BOM_Formulation_Item_Id = BOMS.BOM_Formulation_Item_Id
		WHERE				PP.PP_id = @destination_location_PPId


		DELETE	@Output 
		WHERE	COALESCE(prod_id,(SELECT  prod_id 
		FROM	dbo.production_plan WITH(NOLOCK) 
		WHERE	PP_id = @destination_location_PPId)) NOT IN (
								SELECT Prod_id FROM @ValidProductId
								)
	END
*/
END

SELECT	DISTINCT	Prod_id,
					prod_code,
					prod_desc 
FROM				@output

DROP TABLE #AllLocation


LaFin:

SET NOCOUNT OFF

RETURN

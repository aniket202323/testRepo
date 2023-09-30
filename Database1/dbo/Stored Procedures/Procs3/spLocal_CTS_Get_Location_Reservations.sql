

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Location_Reservations
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-11-12
-- Version 				: Version 1.0
-- SP Type				: WEB
-- Caller				: WEB SERVICE
-- Description			: The purpose of this store procedure is to list reservations at location
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-12		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
EXECUTE [spLocal_CTS_Get_Location_Reservations] '10000000005',NULL, NULL


*/

CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Location_Reservations]
	@Serial 		VARCHAR(25),
	@Start_time		DATETIME = NULL,
	@End_time		DATETIME = NULL

AS
BEGIN
DECLARE
@PUId				INTEGER

DECLARE @Output TABLE 
(
	Id								INTEGER IDENTITY(1,1),	
	Appliance_Event_Id				INTEGER,
	Appliance_Serial				VARCHAR(25),
	Appliance_Type					VARCHAR(25),
	Reservation_Status				VARCHAR(25),
	Reservation_type				VARCHAR(25),	
	Reservation_PU_Id				INTEGER,
	Reservation_PU_Desc				VARCHAR(50),
	Reservation_PP_Id				INTEGER,
	Reservation_Process_Order		VARCHAR(50),
	Reservation_Product_Id			INTEGER,
	Reservation_Product_Code		VARCHAR(50),
	Reservation_creation_User_Id	INTEGER,
	Reservation_creation_User_Desc	VARCHAR(50)
)
	SET NOCOUNT ON;


	SET @PUId =	(
				SELECT	TFV.KeyId	
				FROM	dbo.Table_Fields_Values TFV
						JOIN dbo.table_fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id
						JOIN dbo.Tables T ON t.tableid = TF.tableId
							AND T.tableName = 'Prod_Units'
						JOIN dbo.prod_units_base PUB WITH(NOLOCK)
							ON  PUB.pu_id = TFV.KeyId
				WHERE		Table_Field_Desc = 'CTS Location serial number'
							AND TFV.value = @Serial
				)
	INSERT INTO @Output
	(
		Appliance_Event_Id,
		Appliance_Serial,
		Appliance_Type,
		Reservation_Status,
		Reservation_type,
		Reservation_PU_Id,
		Reservation_PU_Desc,
		Reservation_PP_Id,
		Reservation_Process_Order,
		Reservation_Product_Id,
		Reservation_Product_Code,
		Reservation_creation_User_Id,
		Reservation_creation_User_Desc
	)
	SELECT TOP 100 Appliance_Event_Id,
			Appliance_Serial,
			Appliance_Type,
			Reservation_Status,
			Reservation_type,
			Reservation_PU_Id,
			Reservation_PU_Desc,
			Reservation_PP_Id,
			Reservation_Process_Order,
			Reservation_Product_Id,
			Reservation_Product_Code,
			Reservation_creation_User_Id,
			Reservation_creation_User_Desc 
	FROM	fnLocal_CTS_Location_Reservations(@PUId,@Start_time, @End_time)


	SET NOCOUNT OFF;

	Select 
		Appliance_Event_Id,
		Appliance_Serial,
		Appliance_Type,
		Reservation_Status,
		Reservation_type,
		Reservation_PU_Id,
		Reservation_PU_Desc,
		Reservation_PP_Id,
		Reservation_Process_Order,
		Reservation_Product_Id,
		Reservation_Product_Code,
		Reservation_creation_User_Id,
		Reservation_creation_User_Desc
		from @Output
END

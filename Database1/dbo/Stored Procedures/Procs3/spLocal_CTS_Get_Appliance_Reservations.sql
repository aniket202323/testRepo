

CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Appliance_Reservations]
	@Serial 		VARCHAR(25),
	@Start_time		DATETIME = NULL,
	@End_time		DATETIME = NULL

AS
BEGIN
	DECLARE
	@EventId				INTEGER

	DECLARE @Output TABLE 
	(
		Id											INTEGER IDENTITY(1,1),	
		Appliance_Event_id							INTEGER,
		Appliance_Serial							VARCHAR(25),
		Appliance_Type								VARCHAR(25),
		Reservation_Status							VARCHAR(25),
		Reservation_type							VARCHAR(25),	
		Reservation_PU_Id							INTEGER,
		Reservation_PU_Desc							VARCHAR(50),
		Reservation_PP_Id							INTEGER,
		Reservation_Process_Order					VARCHAR(50),
		Reservation_Product_Id						INTEGER,
		Reservation_Product_Code					VARCHAR(50),
		Reservation_creation_User_Id				INTEGER,
		Reservation_creation_User_Desc				VARCHAR(50)
	)
	SET NOCOUNT ON;


	SET @EventId =	(
					SELECT	event_id
					FROM	dbo,event_details WITH(NOLOCK)
					WHERE	Alternate_event_num = @Serial
					)
	IF @EventId IS NULL
		RETURN

	INSERT INTO @Output
	(
			Appliance_Event_id,
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
	SELECT	TOP 100 Appliance_Event_Id,
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
	FROM	fnLocal_CTS_Appliance_Reservations(@EventId,@Start_time, @End_time)


	SET NOCOUNT OFF;

	SELECT	Appliance_Event_id,
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
	FROM	@Output
END


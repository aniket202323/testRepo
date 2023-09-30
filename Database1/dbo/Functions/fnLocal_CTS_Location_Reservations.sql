

/*=====================================================================================================================
Local Function: fnLocal_CTS_Location_Reservations
=====================================================================================================================
 Author					:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-08-12
 Version 				:	1.0
 Description			:	The purpose of this function is to retreive the reservations at a location
							Reservations are user defined events.  When the ude desc (indexed) = "Reserved" the reservation is active
							If start time and end time are set all unit reservations will be reetreived, otherwise only active ones
 Editor tab spacing	: 4 


==================================================================================================
 EDIT HISTORY:

 ========		====	  		====					=====
 1.0			2021-08-12		F.Bergeron				Initial Release 
 1.1			2023-06-27		U. Lapierre				Adapt for Code review


==================================================================================================
Testing Code

 SELECT * FROM fnLocal_CTS_Location_Reservations(1060,null, null)
==================================================================================================*/


CREATE   FUNCTION [dbo].[fnLocal_CTS_Location_Reservations] 
(
	@PU_id 			INTEGER,
	@Start_time		DATETIME = NULL,
	@End_time		DATETIME = NULL
)
RETURNS @Output TABLE 
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
					
AS
BEGIN
	DECLARE
	@LocationReservationUDESubTypeId			VARCHAR(50),
	@LocationReservationPOVarId					INTEGER,
	@LocationReservationTypeVarId				INTEGER;

	DECLARE @Appliance_Units TABLE
	(
		PU_Id			INTEGER,
		Appliance_Type	VARCHAR(50)
	);

	SET @LocationReservationUDESubTypeId = 
	(
		SELECT	EST.Event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.Event_Subtype_Desc = 'CTS Reservation'
	);
	SET @LocationReservationPOVarId = 
	(
		SELECT	V.var_id 
		FROM	dbo.variables_base V WITH(NOLOCK)		
		WHERE	V.PU_Id = @PU_id
					AND V.Event_Subtype_Id = @LocationReservationUDESubTypeId
					AND V.Test_Name = 'Process Order Id'
	);
	SET @LocationReservationTypeVarId = 
	(
		SELECT	V.var_id 
		FROM	dbo.variables_base V WITH(NOLOCK)
		WHERE	V.PU_Id = @PU_id
					AND V.Event_Subtype_Id = @LocationReservationUDESubTypeId
					AND V.Test_Name = 'Type'
	);
	


	INSERT INTO @Appliance_Units
	(
		PU_Id,
		Appliance_Type
	)
	SELECT	PUB.PU_Id,TFV.Value 
			FROM dbo.Prod_units_base PUB		WITH(NOLOCK)
			JOIN dbo.Table_Fields_Values TFV	WITH(NOLOCK)	ON  TFV.KeyId = PUB.PU_Id
			JOIN dbo.Table_Fields TF			WITH(NOLOCK)	ON TF.Table_Field_Id = TFV.Table_Field_Id
																AND TF.Table_Field_Desc = 'CTS Appliance type'
																AND TF.TableId =	(
																					SELECT	TableId 
																					FROM	dbo.Tables WITH(NOLOCK) 
																					WHERE	TableName = 'Prod_units'
																					);
/*
	 GET LOCATION RESERVATIONS, WITH TYPE AND STATUS
	 TWO CASES
	 1- @Start_time and @end_time are NULL only get the active
	 2- @Start_time and @end_time are NOT NULL get all for interval
*/
	IF @Start_time IS NULL OR @End_time IS NULL
	BEGIN
		INSERT INTO		@Output
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
		SELECT	E.Event_Id					'Appliance_Event_Id',
				ED.Alternate_Event_Num		'Appliance_Serial',
				AU.Appliance_Type			'Appliance_Type',
				'Active'					'Reservation_Status',
				T.Result					'Reservation_type',
				UDE.pu_id					'Reservation_PU_Id',
				PUB.pu_id					'Reservation_PU_Desc',
				PO.PP_Id					'Reservation_PP_Id',
				PO.Process_Order			'Reservation_Process_Order',
				PRODB.Prod_Id				'Reservation_Product_Id',
				PRODB.Prod_Code				'Reservation_Product_Code',
				UB.User_Id					'Reservation_creation_User_Id',
				UB.WindowsUserInfo			'Reservation_creation_User_Desc'
		FROM	dbo.Prod_Units_Base PUB				WITH(NOLOCK)
				JOIN dbo.user_defined_events UDE	WITH(NOLOCK) 	ON UDE.PU_Id = PUB.PU_id
																	AND UDE.Event_Subtype_Id = @LocationReservationUDESubTypeId
																	AND UDE.UDE_Desc = 'Reserved'
				JOIN dbo.Users_Base UB				WITH(NOLOCK)	ON UB.User_Id = UDE.User_Id
				JOIN dbo.events E					WITH(NOLOCK) 	ON E.event_id = UDE.event_id
				JOIN dbo.event_details ED			WITH(NOLOCK)	ON ED.event_Id = E.Event_Id
				JOIN @Appliance_Units AU							ON AU.pu_id = E.PU_Id
				JOIN dbo.tests T					WITH(NOLOCK)	ON UDE.End_Time = T.Result_On 
																	AND T.var_id = @LocationReservationTypeVarId	
				JOIN dbo.tests T1					WITH(NOLOCK)	ON T1.var_id = @LocationReservationPOVarId
																	AND UDE.End_Time = T1.Result_On
				JOIN dbo.Production_Plan PO			WITH(NOLOCK) 	ON PO.PP_Id = T1.Result
				JOIN dbo.Products_Base PRODB		WITH(NOLOCK) 	ON PO.Prod_Id = PRODB.Prod_id
		WHERE	PUB.PU_Id = @PU_id	;
	END
	ELSE
	BEGIN
		INSERT INTO		@Output
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
		SELECT	E.Event_Id					'Appliance_Event_Id',
				ED.Alternate_Event_Num		'Appliance_Serial',
				AU.Appliance_Type			'Appliance_Type',
				(
				CASE UDE.UDE_Desc
				WHEN 'Reserved' THEN 'Active' 
				ELSE 'Complete'				
				END
				)							'Reservation_Status',
				T.Result					'Reservation_type',
				UDE.pu_id					'Reservation_PU_Id',
				PUB.pu_id					'Reservation_PU_Desc',
				PO.PP_Id					'Reservation_PP_Id',
				PO.Process_Order			'Reservation_Process_Order',
				PRODB.Prod_Id				'Reservation_Product_Id',
				PRODB.Prod_Code				'Reservation_Product_Code',
				UB.User_Id					'Reservation_creation_User_Id',
				UB.WindowsUserInfo			'Reservation_creation_User_Desc'
		FROM	dbo.Prod_Units_Base PUB				WITH(NOLOCK)
				JOIN dbo.user_defined_events UDE	WITH(NOLOCK) 	ON UDE.PU_Id = PUB.PU_id
																	AND UDE.Event_Subtype_Id = @LocationReservationUDESubTypeId
				JOIN dbo.Users_Base UB				WITH(NOLOCK)	ON UB.User_Id = UDE.User_Id
				JOIN dbo.events E					WITH(NOLOCK) 	ON E.event_id = UDE.event_id
				JOIN dbo.event_details ED			WITH(NOLOCK)	ON ED.event_Id = E.Event_Id
				JOIN @Appliance_Units AU							ON AU.pu_id = E.PU_Id
				JOIN dbo.tests T					WITH(NOLOCK)	ON UDE.End_Time = T.Result_On 
																	AND T.var_id = @LocationReservationTypeVarId
				JOIN dbo.tests T1					WITH(NOLOCK)	ON T1.var_id = @LocationReservationPOVarId
																	AND UDE.End_Time = T1.Result_On
				JOIN dbo.Production_Plan PO			WITH(NOLOCK) 	ON PO.PP_Id = T1.Result
				JOIN dbo.Products_Base PRODB		WITH(NOLOCK) 	ON PO.Prod_Id = PRODB.Prod_id
		WHERE	PUB.PU_Id = @PU_id	
			AND UDE.End_Time BETWEEN @Start_time AND @End_time;
	END
					
	

	RETURN;
END

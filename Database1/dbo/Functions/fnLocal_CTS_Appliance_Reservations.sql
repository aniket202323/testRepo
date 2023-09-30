
/*=====================================================================================================================
Local Function: fnLocal_CTS_Appliance_Reservations
=====================================================================================================================
 Author				:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-10-05
 Version 				:	1.0
 Description			:	Get appliance reservation
							The purpose of this function is to retrieve the reservations for an appliance
							Reservations are user defined events.  When the ude desc (indexed) = "Reserved" the reservation is active
							If start time and end time are set all unit reservations will be retrieved, otherwise only active ones
 Editor tab spacing	: 4 



 EDIT HISTORY:

 ========		====	  		====					=====
 1.0			2021-10-05		F.Bergeron				Initial Release 
 1.1			2023-06-26		U. Lapierre				Adapt for Code review
 

Testing Code

 SELECT * FROM fnLocal_CTS_Appliance_Reservations(997917,NULL, NULL)
====================================================================================================================== */

CREATE   FUNCTION [dbo].[fnLocal_CTS_Appliance_Reservations] 
(
	@Event_Id		INTEGER,
	@Start_time		DATETIME = NULL,
	@End_time		DATETIME = NULL
)
RETURNS @Output TABLE 
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
					
AS
BEGIN
	DECLARE
	@ApplianceReservationUDESubTypeId			INT;



	SET @ApplianceReservationUDESubTypeId = 
	(
		SELECT	EST.Event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.Event_Subtype_Desc = 'CTS Reservation'
	);
	

	DECLARE @Appliance_Units TABLE
	(
		PU_Id			INTEGER,
		Appliance_Type	VARCHAR(50)
	);
	INSERT INTO @Appliance_Units
	(
		PU_Id,
		Appliance_Type
	)
	SELECT	PUB.PU_Id,TFV.Value FROM dbo.Prod_units_base PUB
			JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)
				ON  TFV.KeyId = PUB.PU_Id
			JOIN dbo.Table_Fields TF WITH(NOLOCK) 
				ON TF.Table_Field_Id = TFV.Table_Field_Id
				AND TF.Table_Field_Desc = 'CTS Appliance type'
				AND TF.TableId =	(
									SELECT	TableId 
									FROM	dbo.Tables WITH(NOLOCK) 
									WHERE	TableName = 'Prod_units'
									);
/*=============================================================
	 GET Appliance RESERVATIONS, WITH TYPE AND STATUS
	 TWO CASES
	 1- @Start_time and @end_time are NULL only get the active
	 2- @Start_time and @end_time are NOT NULL get all for interval
=============================================================*/

	IF @Start_time IS NULL OR @End_time IS NULL
	BEGIN
		INSERT INTO		@Output
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
		SELECT TOP 1 
				E.Event_Id,
				ED.Alternate_Event_Num		'Appliance_Serial',
				AU.Appliance_Type			'Appliance_Type',
				'Active'					'Reservation_Status',
				T.Result					'Reservation_type',
				UDE.pu_id					'Reservation_PU_Id',
				PUB1.pu_desc				'Reservation_PU_Desc',
				PP.PP_Id					'Reservation_PP_Id',
				PP.Process_Order			'Reservation_Process_Order',
				PRODB.Prod_Id				'Reservation_Product_Id',
				PRODB.Prod_Code				'Reservation_Product_Code',
				UB.User_Id					'Reservation_creation_User_Id',
				UB.Username			'Reservation_creation_User_Desc'
		FROM	dbo.events E WITH(NOLOCK)
				JOIN dbo.event_details ED
					ON ED.Event_Id = E.event_id
				JOIN @Appliance_Units AU
					ON AU.pu_id = E.PU_Id
				JOIN dbo.user_defined_Events UDE WITH(NOLOCK) 
					ON UDE.event_id = E.event_id 
					AND UDE.Event_Subtype_Id = @ApplianceReservationUDESubTypeId 
					AND UDE.UDE_Desc = 'Reserved'
				JOIN dbo.Prod_Units_Base PUB1 WITH(NOLOCK)
					ON PUB1.PU_Id = UDE.pu_id
				JOIN dbo.Users_Base UB WITH(NOLOCK)
					ON UB.User_Id = UDE.User_Id			
				-- TYPE
				JOIN dbo.variables_Base VB WITH(NOLOCK)
					ON VB.pu_id = UDE.PU_Id 
					AND VB.test_name = 'Type' 
					AND VB.event_Subtype_id = @ApplianceReservationUDESubTypeId
				JOIN dbo.tests T WITH(NOLOCK)
					ON UDE.End_Time = T.Result_On 
					AND T.var_id = VB.Var_Id
				JOIN dbo.variables_Base VB1 WITH(NOLOCK)
					ON VB1.pu_id = UDE.PU_Id 
					AND VB1.test_name = 'Process order Id'
					AND VB.event_Subtype_id = @ApplianceReservationUDESubTypeId
				JOIN dbo.tests T1 WITH(NOLOCK)
					ON UDE.End_Time = T1.Result_On 
					AND T1.var_id = VB1.Var_Id
				JOIN dbo.production_plan PP WITH(NOLOCK)
					ON PP.pp_id = T1.result
				JOIN dbo.Products_Base PRODB WITH(NOLOCK) 
					ON PP.Prod_Id = PRODB.Prod_id
		WHERE	E.Event_Id = @Event_Id
		ORDER BY	UDE.End_Time DESC;
	END
	ELSE
	BEGIN
		INSERT INTO		@Output
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
		SELECT	E.event_id,	
				ED.Alternate_Event_Num		'Appliance_Serial',
				AU.Appliance_Type			'Appliance_Type',
				'Active'					'Reservation_Status',
				T.Result					'Reservation_type',
				UDE.pu_id					'Reservation_PU_Id',
				PUB1.pu_desc				'Reservation_PU_Desc',
				PP.PP_Id					'Reservation_PP_Id',
				PP.Process_Order			'Reservation_Process_Order',
				PRODB.Prod_Id				'Reservation_Product_Id',
				PRODB.Prod_Code				'Reservation_Product_Code',
				UB.User_Id					'Reservation_creation_User_Id',
				UB.Username					'Reservation_creation_User_Desc'
		FROM	dbo.events E WITH(NOLOCK)
				JOIN dbo.event_details ED
					ON ED.Event_Id = E.event_id
				JOIN @Appliance_Units AU
					ON AU.pu_id = E.PU_Id
				JOIN dbo.user_defined_Events UDE WITH(NOLOCK) 
					ON UDE.event_id = E.event_id 
					AND UDE.Event_Subtype_Id = @ApplianceReservationUDESubTypeId 
					AND UDE.UDE_Desc = 'Reserved'
				JOIN dbo.Prod_Units_Base PUB1 WITH(NOLOCK)
					ON PUB1.PU_Id = UDE.pu_id
				JOIN dbo.Users_Base UB WITH(NOLOCK)
					ON UB.User_Id = UDE.User_Id			
				JOIN dbo.variables_Base VB WITH(NOLOCK)
					ON VB.pu_id = UDE.PU_Id 
					AND VB.test_name = 'Type' 
					AND VB.event_Subtype_id = @ApplianceReservationUDESubTypeId
				JOIN dbo.tests T WITH(NOLOCK)
					ON UDE.End_Time = T.Result_On 
					AND T.var_id = VB.Var_Id
				JOIN dbo.variables_Base VB1 WITH(NOLOCK)
					ON VB1.pu_id = UDE.PU_Id 
					AND VB1.test_name = 'Process order Id'
					AND VB.event_Subtype_id = @ApplianceReservationUDESubTypeId
				JOIN dbo.tests T1 WITH(NOLOCK)
					ON UDE.End_Time = T1.Result_On 
					AND T1.var_id = VB1.Var_Id
				JOIN dbo.production_plan PP WITH(NOLOCK)
					ON PP.pp_id = T1.result
				JOIN dbo.Products_Base PRODB WITH(NOLOCK) 
					ON PP.Prod_Id = PRODB.Prod_id
		WHERE	E.Event_Id = @Event_Id
				AND UDE.End_Time BETWEEN @Start_time AND @End_time;
	END
				
	

RETURN
END




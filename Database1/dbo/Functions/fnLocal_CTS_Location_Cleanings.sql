

/*=====================================================================================================================
Local Function: fnLocal_CTS_Location_Cleanings
=====================================================================================================================
 Author				:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-08-12
 Version 				:	1.0
 Description			:	The purpose of this function is to retreive the Cleanings at a location
							Location cleanings are user defined events.  When the ude desc (indexed) = "Cleaning" the cleaning is ongoing
							If start time and end time are set all unit cleanings will be reetreived, otherwise only lastest one
							
 Editor tab spacing	: 4 


==================================================================================================
 EDIT HISTORY:

 ========		====	  		====					=====
 1.0			2021-08-12		F.Bergeron				Initial Release 
 1.1			2022-02-01		F.Bergeron				Get E-Sig performer and Verifier
 1.2			2022-02-07		F.Bergeron				Add possibility to fetch last cleaning from any point in time
 1.3			2023-06-26		U. Lapierre				Adapt for Code review
==================================================================================================
Testing Code

 SELECT * FROM fnLocal_CTS_Location_Cleanings(8465, NULL, GETDATE())

SELECT * FROM User_Defined_Events where ude_id = 2970027

SELECT * FROM ESignature where Signature_Id = 1729
==================================================================================================*/


CREATE   FUNCTION [dbo].[fnLocal_CTS_Location_Cleanings] 
(
	@PU_id 			INTEGER,
	@Start_time		DATETIME = NULL,
	@End_time		DATETIME = NULL
)
RETURNS @Output TABLE 
(
	Id							INTEGER IDENTITY(1,1),	
	Status						VARCHAR(25),
	type						VARCHAR(25),
	Start_time					DATETIME,
	End_time					DATETIME,
	Start_User_Id				INTEGER,
	Start_Username				VARCHAR(100),
	Start_User_AD				VARCHAR(100),
	Completion_ES_User_Id		INTEGER,
	Completion_ES_Username		VARCHAR(100),
	Completion_ES_User_AD		VARCHAR(100),
	Approver_ES_User_Id			INTEGER,
	Approver_ES_Username		VARCHAR(100),
	Approver_ES_User_AD			VARCHAR(100),
	UDE_Id						INTEGER,
	Err_Warn					VARCHAR(500)
)
					
AS
BEGIN
	DECLARE
	@LocationCleaningUDESubTypeId			VARCHAR(50),
	@LocationCleaningTypeVarId				INTEGER,
	@Err_Warn								VARCHAR(500),
	@UDE_Start_User_Id						INTEGER,
	@UDE_Completion_ES_User_Id				INTEGER,
	@UDE_Approver_ES_User_Id				INTEGER;
	
	
	DECLARE @LocationPathIds TABLE
	(
		Path_id	INTEGER
	);

	IF @End_time IS NULL 
		SET @End_time = GETDATE();
	
	
	INSERT INTO @LocationPathIds
	(
		Path_id
	)
	SELECT	Path_id 
	FROM	dbo.PrdExec_Path_Units WITH(NOLOCK) 
	WHERE	pu_id = @pu_id;

	/* A CTS UNIT CAN'T BE ON MORE THAN ONE PATH, ONE PATH PER ROOM MUST BE CREATED AN A UNIT CANNOT BE IN MULTIPLE ROOMS */
	IF (SELECT COUNT(1) FROM @LocationPathIds) > 1
	BEGIN
		SET @Err_Warn	=
		(
			SELECT 'Location ' + (SELECT pu_desc FROM dbo.prod_units_Base WITH(NOLOCK) WHERE pu_id = @pu_Id) + ' Is part of more than one execution paths, please contact your administrator'
		);

		INSERT INTO @Output
		(	Err_Warn
		)
		VALUES
		(	@Err_Warn
		);

		RETURN;
	END
	
	SET @PU_id =	(	SELECT	PU_id 
						FROM	dbo.PrdExec_Path_Units WITH(NOLOCK)
						WHERE	Path_Id =	(	SELECT	path_id 
												FROM	@LocationPathIds
												WHERE	Is_Schedule_Point = 1
											)
					);
	SET @LocationCleaningUDESubTypeId = 	(	SELECT	EST.Event_Subtype_Id
												FROM	dbo.event_subtypes EST WITH(NOLOCK)
												WHERE	EST.Event_Subtype_Desc = 'CTS Location Cleaning'
											);
	
	SET @LocationCleaningTypeVarId = 		(	SELECT	V.var_id 
												FROM	dbo.variables_base V WITH(NOLOCK)	
												WHERE	V.PU_Id = @PU_id
													AND V.Event_Subtype_Id = @LocationCleaningUDESubTypeId
													AND V.Test_Name = 'Type'
											);

	/*
	 GET LOCATION CLEANINGS, WITH TYPE AND STATUS
	 TWO CASES
	 1- @Start_time and @end_time are NULL only get the latest
	 2- @Start_time and @end_time are NOT NULL get all for interval
	*/
	IF @Start_time IS NULL
	BEGIN
		INSERT INTO	@Output
		(
		Status,
		type,
		Start_time,
		End_time,
		Start_User_Id,
		Start_Username,
		Start_User_AD,
		Completion_ES_User_Id,
		Completion_ES_Username,
		Completion_ES_User_AD,
		Approver_ES_User_Id,
		Approver_ES_Username,
		Approver_ES_User_AD,
		UDE_Id,
		Err_Warn
		)
		SELECT TOP 1
					ps.prodStatus_Desc				'Status',
					T.result						'type',
					UDE.Start_Time					'Start_time',
					UDE.End_Time					'End_time',
					UB.User_Id						'Start_User_Id',
					UB.Username						'Start_Username',
					UB.WindowsUserInfo				'Start_User_AD',
					UBPERF.User_Id					'Completion_ES_User_Id',
					UBPERF.Username					'Completion_ES_Username',
					UBPERF.WindowsUserInfo			'Completion_ES_User_AD',
					UBVER.User_Id					'Approver_ES_User_Id',
					UBVER.Username					'Approver_ES_Username',
					UBVER.WindowsUserInfo			'Approver_ES_User_AD',
					ude.UDE_Id						'UDE_Id',
					NULL							'Err_Warn'
		FROM	dbo.Prod_Units_Base PUB		WITH(NOLOCK)
		JOIN dbo.user_defined_events UDE	WITH(NOLOCK)	ON UDE.PU_Id = PUB.PU_id
															AND UDE.Event_Subtype_Id = @LocationCleaningUDESubTypeId
		JOIN dbo.Users_Base UB				WITH(NOLOCK)	ON UB.User_Id = UDE.User_Id
		LEFT JOIN dbo.ESignature ESIG		WITH(NOLOCK)	ON ESIG.Signature_Id = UDE.Signature_Id
		LEFT JOIN dbo.users_base UBPERF		WITH(NOLOCK)	ON UBPERF.user_id = ESIG.Perform_User_Id
		LEFT JOIN dbo.users_base UBVER		WITH(NOLOCK)	ON UBVER.user_id = ESIG.Verify_User_Id
		LEFT JOIN dbo.Production_Status ps	WITH(NOLOCK) 	ON ude.event_status = ps.prodSTATUS_ID
		JOIN dbo.tests T					WITH(NOLOCK)	ON UDE.End_Time = T.Result_On 
															AND T.var_id = @LocationCleaningTypeVarId	
		WHERE	PUB.PU_Id = @PU_id	
			AND UDE.Start_Time <= @end_time
		ORDER BY	UDE.Start_Time DESC;
	END
	ELSE
	BEGIN
		INSERT INTO	@Output
		(
		Status,
		type,
		Start_time,
		End_time,
		Start_User_Id,
		Start_Username,
		Start_User_AD,
		Completion_ES_User_Id,
		Completion_ES_Username,
		Completion_ES_User_AD,
		Approver_ES_User_Id,
		Approver_ES_Username,
		Approver_ES_User_AD,
		UDE_Id,
		Err_Warn
		)
		SELECT		ps.prodStatus_Desc				'Status',
					T.result						'type',
					UDE.Start_Time					'Start_time',
					UDE.End_Time					'End_time',
					UB.User_Id						'Start_User_Id',
					UB.Username						'Start_Username',
					UB.WindowsUserInfo				'Start_User_AD',
					UBPERF.User_Id					'Completion_ES_User_Id',
					UBPERF.Username					'Completion_ES_Username',
					UBPERF.WindowsUserInfo			'Completion_ES_User_AD',
					UBVER.User_Id					'Approver_ES_User_Id',
					UBVER.Username					'Approver_ES_Username',
					UBVER.WindowsUserInfo			'Approver_ES_User_AD',
					ude.UDE_Id						'UDE_Id',
					NULL							'Err_Warn'
		FROM	dbo.Prod_Units_Base PUB		WITH(NOLOCK)
		JOIN dbo.user_defined_events UDE	WITH(NOLOCK)	ON UDE.PU_Id = PUB.PU_id
															AND UDE.Event_Subtype_Id = @LocationCleaningUDESubTypeId
		JOIN dbo.Users_Base UB				WITH(NOLOCK)	ON UB.User_Id = UDE.User_Id
		LEFT JOIN dbo.ESignature ESIG		WITH(NOLOCK)	ON ESIG.Signature_Id = UDE.Signature_Id
		LEFT JOIN dbo.users_base UBPERF		WITH(NOLOCK)	ON UBPERF.user_id = ESIG.Perform_User_Id
		LEFT JOIN dbo.users_base UBVER		WITH(NOLOCK)	ON UBVER.user_id = ESIG.Verify_User_Id
		LEFT JOIN dbo.Production_Status ps	WITH(NOLOCK) 	ON ude.event_status = ps.prodSTATUS_ID
		JOIN dbo.tests T					WITH(NOLOCK)	ON UDE.End_Time = T.Result_On 
															AND T.var_id = @LocationCleaningTypeVarId	
		WHERE	PUB.PU_Id = @PU_id	
			AND UDE.Start_Time BETWEEN @Start_time  AND @End_time
		ORDER BY	UDE.Start_Time DESC;
	END


RETURN
END

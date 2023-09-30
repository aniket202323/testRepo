

/*=====================================================================================================================
Local Function: fnLocal_CTS_Appliance_Cleanings
=====================================================================================================================
 Author				:	Francois Bergeron (AutomaTech Canada)
 Date created			:	2021-08-12
 Version 				:	1.0
 Description			:	The purpose of this function is to retreive the Cleanings on an appliance
							Appliance cleanings are user defined events.  When the ude desc (indexed) = "Cleaning" the cleaning is ongoing
							If start time and end time are set all unit cleanings will be retreived, otherwise only lastest one
							
 Editor tab spacing	: 4 



 EDIT HISTORY:

 ========		====	  		====					=====
 1.0			2021-08-12		F.Bergeron				Initial Release 
 1.1			2022-02-01		F.Bergeron				Get E-Sig performer and Verifier
 1.2			2022-02-07		F.Bergeron				Include default @EndTime Value
 1.3			2023-06-26		U. Lapierre				Adapt for Code review


Testing Code

 SELECT * FROM fnLocal_CTS_Appliance_Cleanings(1018703, NULL, NULL)

====================================================================================================================== */

CREATE   FUNCTION [dbo].[fnLocal_CTS_Appliance_Cleanings] 
(
	@Event_Id 			INTEGER,
	@Start_time			DATETIME = NULL,
	@End_time			DATETIME = NULL
)
RETURNS @Output TABLE 
(
	Id							INTEGER IDENTITY(1,1),	
	Status						VARCHAR(25),
	type						VARCHAR(25),
	Location_id					INTEGER,
	Location_desc				VARCHAR(50),
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
	Err_Warn					VARCHAR(500),
	UDE_Id						INTEGER
)
			
AS
BEGIN
	DECLARE
	@ApplianceCleaningUDESubTypeId			VARCHAR(50),
	@ApplianceCleaningTypeVarId				INTEGER;

	IF @End_time IS NULL
		SET @End_time = GETDATE();


	SET @ApplianceCleaningUDESubTypeId = 
	(
		SELECT	EST.Event_Subtype_Id
		FROM	dbo.event_subtypes EST WITH(NOLOCK)
		WHERE	EST.Event_Subtype_Desc = 'CTS Appliance Cleaning'
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
			Location_id,
			Location_desc,
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
			Err_Warn,
			UDE_Id
		)
			SELECT TOP 1
					(CASE (SELECT prodstatus_desc FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_id = UDE.Event_Status)
					WHEN 'CTS_Cleaning_Started' THEN 'Cleaning started'
					WHEN 'CTS_Cleaning_Completed' THEN 'Cleaning completed'
					WHEN 'CTS_Cleaning_Approved' THEN 'Clean'
					WHEN 'CTS_Cleaning_Cancelled' THEN 'Cleaning cancelled'
					WHEN 'CTS_Cleaning_Rejected' THEN 'Cleaning  rejected'
					ELSE 'Cleaning status not found'
					END)							'Cleaning_Status',
					T.result						'Cleaning_type',
					PUB1.PU_Id						'Cleaning_Location_id',
					PUB1.PU_Desc					'Cleaning_Location_desc',
					UDE.Start_Time					'Cleaning_Start_time',
					UDE.End_Time					'Cleaning_End_time',
					UB.User_Id						'Start_User_Id',
					UB.Username						'Start_Username',
					UB.WindowsUserInfo				'Start_User_AD',
					UBPERF.User_Id					'Completion_ES_User_Id',
					UBPERF.Username					'Completion_ES_Username',
					UBPERF.WindowsUserInfo			'Completion_ES_User_AD',
					UBVER.User_Id					'Approver_ES_User_Id',
					UBVER.Username					'Approver_ES_Username',
					UBVER.WindowsUserInfo			'Approver_ES_User_AD',
					NULL							'Err_Warn',
					ude.UDE_Id						'UDE_Id'
		FROM		dbo.events E WITH(NOLOCK)
					JOIN dbo.user_defined_events UDE WITH(NOLOCK)
						ON E.event_Id = UDE.Event_Id
					JOIN dbo.Users_Base UB WITH(NOLOCK)
						ON UB.User_Id = UDE.User_Id
					LEFT JOIN dbo.ESignature ESIG WITH(NOLOCK)
						ON ESIG.Signature_Id = UDE.Signature_Id
					LEFT JOIN dbo.users_base UBPERF 
						ON UBPERF.user_id = ESIG.Perform_User_Id
					LEFT JOIN dbo.users_base UBVER 
						ON UBVER.user_id = ESIG.Verify_User_Id
					JOIN dbo.prod_units_base PUB WITH(NOLOCK)
						ON PUB.pu_id = E.pu_id
					JOIN dbo.prod_units_base PUB1 ON PUB1.pu_id = UDE.PU_Id
					JOIN dbo.variables_Base VB WITH(NOLOCK) 
						ON VB.pu_id = PUB1.pu_id
						AND VB.Test_Name = 'Type'
					JOIN dbo.tests T WITH(NOLOCK)
						ON T.var_id = VB.var_id
							AND t.result_on = ude.end_time
		WHERE		UDE.Event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
					AND E.event_id = @Event_Id
					AND UDE.Start_Time <= @End_time
		ORDER BY	UDE.modified_on DESC;
	END
	ELSE
	BEGIN
	INSERT INTO	@Output
		(
			Status,
			type,
			Location_id,
			Location_desc,
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
			Err_Warn,
			UDE_Id
		)
		SELECT
					(CASE (SELECT prodstatus_desc FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_id = UDE.Event_Status)
					WHEN 'CTS_Cleaning_Started' THEN 'Cleaning started'
					WHEN 'CTS_Cleaning_Completed' THEN 'Cleaning completed'
					WHEN 'CTS_Cleaning_Approved' THEN 'Clean'
					WHEN 'CTS_Cleaning_Cancelled' THEN 'Cleaning cancelled'
					WHEN 'CTS_Cleaning_Rejected' THEN 'Cleaning  rejected'
					ELSE 'Cleaning status not found'
					END)							'Cleaning_Status',
					T.result						'Cleaning_type',
					PUB1.PU_Id						'Cleaning_Location_id',
					PUB1.PU_Desc					'Cleaning_Location_desc',
					UDE.Start_Time					'Cleaning_Start_time',
					UDE.End_Time					'Cleaning_End_time',
					UB.User_Id						'Start_User_Id',
					UB.Username						'Start_Username',
					UB.WindowsUserInfo				'Start_User_AD',
					UBPERF.User_Id					'Completion_ES_User_Id',
					UBPERF.Username					'Completion_ES_Username',
					UBPERF.WindowsUserInfo			'Completion_ES_User_AD',
					UBVER.User_Id					'Approver_ES_User_Id',
					UBVER.Username					'Approver_ES_Username',
					UBVER.WindowsUserInfo			'Approver_ES_User_AD',
					NULL							'Err_Warn',
					ude.UDE_Id						'UDE_Id'
		FROM		dbo.events E WITH(NOLOCK)
					JOIN dbo.user_defined_events UDE WITH(NOLOCK)
						ON E.event_Id = UDE.Event_Id
					JOIN dbo.Users_Base UB WITH(NOLOCK)
						ON UB.User_Id = UDE.User_Id
					LEFT JOIN dbo.ESignature ESIG WITH(NOLOCK)
						ON ESIG.Signature_Id = UDE.Signature_Id
					LEFT JOIN dbo.users_base UBPERF 
						ON UBPERF.user_id = ESIG.Perform_User_Id
					LEFT JOIN dbo.users_base UBVER 
						ON UBVER.user_id = ESIG.Verify_User_Id
					JOIN dbo.prod_units_base PUB WITH(NOLOCK)
						ON PUB.pu_id = E.pu_id
					JOIN dbo.prod_units_base PUB1 ON PUB1.pu_id = UDE.PU_Id
					JOIN dbo.variables_Base VB WITH(NOLOCK) 
						ON VB.pu_id = PUB1.pu_id
						AND VB.Test_Name = 'Type'
					JOIN dbo.tests T WITH(NOLOCK)
						ON T.var_id = VB.var_id
							AND t.result_on = ude.end_time
		WHERE		UDE.Event_Subtype_Id = 	@ApplianceCleaningUDESubTypeId
					AND E.event_id = @Event_Id
					AND VB.Test_Name = 'Type'
					AND UDE.Start_Time BETWEEN @Start_time AND @End_time
		ORDER BY	UDE.modified_on DESC;
	END

RETURN
END


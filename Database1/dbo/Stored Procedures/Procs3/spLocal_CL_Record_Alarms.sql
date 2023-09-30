
CREATE PROCEDURE [dbo].[spLocal_CL_Record_Alarms]	
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_CL_Record_Alarms
Author				:		Mayuri Dahibhate
Date Created		:		09-Jan-2023
SP Type				:			

Description:
=========
Triggered from Centerline PQF (Primary Q-Factor) Alarm template and records PQF Alarm data and stores in inbound table (Local_PG_CL_Alarms)

CALLED BY:  Centerline Alarm Template

Revision 		Date			Who						What
========		=====			====					=====
1.0.0			09-Jan-2023		Mayuri Dahibhate		Creation of SP
1.0.1			06-Feb-2023		Mayuri Dahibhate		Added logic for checking Primary QFactor and Specification data
1.0.2			02-Mar-2023		Mayuri Dahibhate		Added logic for inserting only new alarms in Local_PG_CL_Alarms table (ignore if alarm already exists)
*/
@Timestamp datetime,

@TransType int,

@AlarmTypeId int,

@AlarmId int,

@Key int,

@PUId int,

@UserId int,

@StartTime datetime,

@EndTime datetime,

@Ack int,

@ATSRDId int,

@ATVRDId int,

@StartResult varchar(100),

@EndResult varchar(100),

@MinResult varchar(100),

@MaxResult varchar(100)


AS


/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
  --[]																	[]--
  --[]							SECTION 1 - Variables Declaration		[]--
  --[]																	[]--
  --[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]-- */



DECLARE	
@CallingSP							varchar(30)='spLocal_CL_Record_Alarms',
@DebugFlagOnLine					bit=0,
@TestId								INT	= NULL,
@Event_Subtype_Id					INT	= NULL,
@StatusTag							INT	= 0,
@UDPPrimaryQFactor					NVARCHAR(150)	= 'Primary Q-Factor?',
@PrimaryQFactor						NVARCHAR(200),
@Prod_id							INT,   
@L_Entry							VARCHAR(25), 
@L_Reject							VARCHAR(25),     
@L_User								VARCHAR(25),
@L_Warning							VARCHAR(25),     
@Target								VARCHAR(25),   
@U_Entry							VARCHAR(25), 
@U_Reject							VARCHAR(25),
@U_User								VARCHAR(25),        
@U_Warning							VARCHAR(25),
@ProductionPUId						INT

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
  --[]																	[]--
  --[]					SECTION 2 - Set parameter values				[]--
  --[]																	[]--
  --[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]-- */


SET @Event_Subtype_Id = (SELECT Event_Subtype_Id from dbo.Variables_Base where Var_Id=@Key);
SET @TestId = (SELECT test_id from dbo.Tests where Result_On=@StartTime and Var_Id=@Key);
SET @ProductionPUId =ISNULL((Select Master_Unit from Prod_Units_Base where Pu_Id=@PUId),@PUId);
SET @Prod_Id = (SELECT Prod_Id from dbo.Production_Starts where PU_ID=@ProductionPUId  and End_Time is NULL);
SET @L_Entry = (SELECT L_Entry from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @L_Reject = (SELECT L_Reject from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @L_User = (SELECT L_User from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @L_Warning = (SELECT L_Warning from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @Target = (SELECT Target from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @U_Entry = (SELECT U_Entry from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @U_Reject = (SELECT U_Reject from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @U_User = (SELECT U_User from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);
SET @U_Warning = (SELECT U_Warning from dbo.Var_Specs where Prod_Id=@Prod_Id and Var_Id=@Key);


/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
  --[]																	[]--
  --[]							SECTION 3 - Debug						[]--
  --[]																	[]--
  --[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]-- */

IF @DebugFlagOnLine = 1  
	INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message], msg ) 
	VALUES(	getdate(), 
			@CallingSP,' Var_Id=' + CONVERT(varchar(50), @Key), @AlarmId) ;

/*--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
  --[]																	  []--
  --[]SECTION 4 - Inserting Alarm Information in Local_PG_CL_Alarms table
	[]--		  for open PQF Variable Alarms
  --[]																	  []--
  --[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]-- */

IF @EndTime IS NULL
BEGIN 

	SET @PrimaryQFactor = (SELECT TOP 1 Value 
						   FROM dbo.Table_Fields_Values tfv
						   JOIN dbo.Table_Fields tf
						   ON tfv.Table_Field_Id = tf.Table_Field_Id
						   WHERE KeyId=@Key and tf.Table_Field_Desc = @UDPPrimaryQFactor) ;

	IF @PrimaryQFactor = 'Yes'
	BEGIN
		IF NOT EXISTS (SELECT Alarm_Id FROM dbo.Local_PG_CL_Alarms where Alarm_Id=@AlarmId)
			INSERT  [dbo].[Local_PG_CL_Alarms] (Var_Id, Alarm_Id, Test_Id, Event_Subtype_Id, PU_Id, Status_Tag, Last_ModifiedTimeStamp,L_Entry,L_Reject,L_User,L_Warning,Prod_Id,Target,U_Entry,U_Reject,U_User,U_Warning)
				VALUES (@Key, @AlarmId, @TestId, @Event_Subtype_Id, @PUId, @StatusTag, @Timestamp,@L_Entry,@L_Reject,@L_User,@L_Warning,@Prod_id,@Target,@U_Entry,@U_Reject,@U_User,@U_Warning) ;

		IF @DebugFlagOnLine = 1  
			INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message], msg ) 
				VALUES(	getdate(), @CallingSP,'PQF VARIABLE', @AlarmId) ;
	END
	ELSE /* Variable is not a Primary Q Factor */
	BEGIN
		IF @DebugFlagOnLine = 1  
			INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message], msg ) 
				VALUES(	getdate(), @CallingSP,'NOT A PQF VARIABLE', @AlarmId) ;
		RETURN
	END
END
ELSE /* @EndTime is NOT NULL (alarm is already closed) */
BEGIN
	IF @DebugFlagOnLine = 1  
		INSERT INTO dbo.Local_Debug([Timestamp], CallingSP, [Message], msg ) 
			VALUES(	getdate(), @CallingSP,'END TIME IS NOT NULL', @AlarmId) ;
	RETURN
END


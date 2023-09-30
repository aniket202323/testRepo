
CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CL_ResetIsVarMandatory]

	/*
	--------------------------------------------------------------------------------------------------------
	Stored procedure  :	spLocal_PG_Cmn_CL_ResetIsVarMandatory
	Author            :	Steven Stier (Stier Automation LLC)
	Description			  :	Resets IsVarMandatory in for Canceled Variables For Centerline Application
	Date created		  :	02-22-2023
	Called by			    :	Called by other SPs as needed
	Version				    :	0.0.2
	Editor tab spacing:	2
	
	--------------------------------------------------------------------------------------------------------
	Revision 	  Date				  Who						          What
	========		==========		=====================		=========================================
	1.0			02/22/2023		Steven Stier						SP Creation
	1.1			03/01/2023		Steven Stier						Refactoring for Performance - FO-05271 and FO-05443

	--------------------------------------------------------------------------------------------------------
	Test calls:
		DECLARE @Output nVARCHAR(1000),
		@PUid int = 612,
		@EventSubtypeID int = 45
		EXEC spLocal_PG_Cmn_CL_ResetIsVarMandatory @PUid,@EventSubtypeID,@Output OUTPUT;
		Select @Output

		Select * from dbo.Local_SA_Debug where DebugSP = 'spLocal_PG_Cmn_CL_ResetIsVarMandatory' 
		and DebugInputs = '@PUId=612 ,@EventSubtypeID=45'  order by DebugId desc
	*/

	@PUId				INT,
	@EventSubtypeID		INT,
	@OutputMsg nVARCHAR(1000)  = '' OUTPUT

	
	AS
	SET NOCOUNT ON

	BEGIN TRY 
 
		DECLARE
			@RSUserId			int,
			@Now			DATETIME,
			@Section VARCHAR(100) = 'Initializing',
			@NumTestsToSetIsVarMandatory int,
			@NumVariables int,
			@Exectime int

		/*--------------------------------------------------------------------------------------------------------------
		-- Debugging variables - requires Local_SA_DEBUG table in DB 
		-------------------------------------------------------------------------------------------------------------*/
		DECLARE @DebugFlag int,
			@DebugSP [varchar](300),
			@DebugInputs [varchar](300),
			@DebugText [varchar](2000),
			@DebugTimestamp datetime
		/* Enable Debug here by setting = 1 - Dont leave this set. Local_SA_Debug gets too big */
		SELECT @DebugFlag = 0
		SELECT @DebugTimestamp = GETDATE() 
		SELECT @DebugSP = 'spLocal_PG_Cmn_CL_ResetIsVarMandatory'
		SELECT @DebugInputs = '@PUId=' + Isnull(convert(nvarchar(10),@PUId),'Null') +
			' ,@EventSubtypeID=' + Isnull(convert(nvarchar(10),@EventSubtypeID),'Null') 
		If @DebugFlag = 1 
		BEGIN 
			Select @DebugText = 'Starting :)'
			Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
		END

		/* @Variables Table holds all the variables to inspect*/
		DECLARE @Variables Table
		(
			PKey					int IDENTITY(1,1) PRIMARY KEY NOT NULL,
			VarId					int
		)
		/* @Tests Table holds those tests ids we need to reset isVarMandatory on. */
		DECLARE @Tests Table
		(
			TestId					int
		)


		SET @RSUserId = (SELECT ISNULL([User_Id], 6) FROM dbo.Users WITH (NOLOCK) WHERE UserName = 'RTTSystem')
			/*----------------------------------------------------------------------------------------------------------
		-- Get the variables for this PUID and Event Subtype
		----------------------------------------------------------------------------------------------------------*/
		SET @Section = 'Getting Variables'
		INSERT INTO @Variables 
			SELECT v.var_id 
			FROM dbo.Variables_base v	WITH (NOLOCK)
			JOIN dbo.Prod_Units_base pu	WITH (NOLOCK) ON pu.PU_Id = v.PU_Id
			WHERE		(v.Event_Subtype_Id = @EventSubtypeID)
				AND ((v.PU_Id = @PUId) OR (pu.Master_Unit = @PUId))
	

		Set @NumVariables = (SELECT COUNT(Varid) FROM @Variables );
		/* If there are no variables, we exit  */
		IF @NumVariables = 0  
			BEGIN  
				If @DebugFlag = 1 
					BEGIN 
						SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
						Select @DebugText = 'Nothing to do. No Variables: ' + convert(nVarChar(10),@Exectime) + ' msec'
						Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
					END
			
				SET @OutputMsg = 'Nothing to do. No Variables. Inputs:'+  @DebugInputs
				SET NOCOUNT OFF 
				RETURN  
			END  
  
		/*----------------------------------------------------------------------------------------------------------
		-- Get the test ids that we will need to reset (set to zero) the isVarMandatory field. It must be canceled
		--  (t.Canceled = 1) and the IsVarMandatory is set  (t.IsVarMandatory = 1)
		----------------------------------------------------------------------------------------------------------*/
		SET @Section = '  Getting Test ids'
		If @DebugFlag = 1 
			BEGIN 
				SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
				Select @DebugText = @Section + ': @NumVariables= ' + convert(nvarchar(10),@NumVariables) + ': ' + convert(nVarChar(10),@Exectime) + ' msec'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END
		/* Populate the @Tests table with all the tests for the variables which need to be set.*/
		INSERT INTO @Tests 
			SELECT t.test_id FROM tests t WITH (NOLOCK) 
			INNER JOIN @Variables v ON t.Var_Id = v.VarId 
			WHERE t.Canceled = 1 AND t.IsVarMandatory = 1

		SET @Section = 'Counting testIDs'
		Set @NumTestsToSetIsVarMandatory = (SELECT COUNT(TestId) FROM @Tests );
		/*----------------------------------------------------------------------------------------------------------
		-- If there is are no tests that need IsVarmandatory Reset then exit
		----------------------------------------------------------------------------------------------------------*/
		IF (@NumTestsToSetIsVarMandatory) = 0  
			BEGIN  	
				If @DebugFlag = 1 
					BEGIN 
						SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
						Select @DebugText = 'Nothing to do. No tests need IsVarMandatory reset:'+ convert(nVarChar(10),@Exectime) + ' msec'
						Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
					END
					SET @OutputMsg = 'Nothing to do. No tests need IsVarMandatory reset. Input: ' + @DebugInputs
					SET NOCOUNT OFF  
				RETURN  
			END
		/*----------------------------------------------------------------------------------------------------------
		-- Using the tests Ids we found above, update the tests table isVarMandatory Field.
		----------------------------------------------------------------------------------------------------------*/
		SET @Section = '  Resetting isVarMandatory for ' + convert(nvarchar(10),@NumTestsToSetIsVarMandatory) + ' tests: '
	
		If @DebugFlag = 1 
			BEGIN 
				SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
				Select @DebugText = @Section  + convert(nVarChar(10),@Exectime) + ' msec'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END

		UPDATE tests SET isVarMandatory = 0  FROM tests t INNER JOIN @Tests t1 ON t.Test_Id = t1.TestID

		SET @OutputMsg = 'Reset Complete: ' + convert(nvarchar(10),@NumTestsToSetIsVarMandatory) + ' tests: '
		If @DebugFlag = 1 
			BEGIN 
				SET @Exectime = DATEDIFF(ms,@DebugTimestamp,GETDATE())
				Select @DebugText = @OutputMsg + convert(nVarChar(10),@Exectime) + ' msec'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END

		RETURN  @OutputMsg

	END TRY

	BEGIN CATCH

		SET @OutputMsg = 'Inputs: '+ @DebugInputs + ' Section: ' +   @Section + ' ErrorMsg: '+ ERROR_MESSAGE () + ' LineError: '+Convert(varchar,ERROR_LINE())  

	END CATCH

SET NOCOUNT ,QUOTED_IDENTIFIER OFF 

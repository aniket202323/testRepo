﻿
CREATE PROCEDURE [dbo].[spRIS_CreateUpdateSamples]
	@UDE_Id		INT,
	@Event_Id	INT,
	@UDE_Desc	NVARCHAR(1000),
	@UserId		INT,
	@TransNum	INT  --Trans Num 1 for insert sample 2 For update sample

AS

/*---------------------------------------------------------------------------------------------------------------------
    This procedure creates/updates a lot sample
  
    Date         Ver/Build   Author              Story/Defect        Remarks
    27-Mar-2020  001         Nagaraju								 Initial Development
    13-Aug-2020  002         Evgeniy Kim         US435753            Added Receiver_Event_Id to output
	11-Sep-2020  003			 Evgeniy & Suman     Defect              Changed PUId to PU_Id in output
	11-Sep-2020  004         Evgeniy Kim			 Enhancement			 AutoGenerated test is now created 
																	 along with sample creation
	01-Nov-2020  005			 Evgeniy Kim			 Enhancement			 New sample variables are now created based on
																	 variables that exist on current lots, not as defined
																	 on specification.
---------------------------------------------------------------------------------------------------------------------
    NOTES: 
    1. 
    
    QUESTIONS:
    1. 


---------------------------------------------------------------------------------------------------------------------*/
DECLARE	 @PUId					INT,
		 @EventSubTypeId		INT,
		 @StartTime				DATETIME,
		 @EndTime  	 			DATETIME,
		 @EventStatus			INT,
		 @MaxEndTime			DATETIME,
		 @AutoGeneratedVarId	INT,
		 @Result_On				DATETIME,
		 @TestId				BIGINT;

 --Check User Id is valid or not
IF(@UserId IS NULL) 
BEGIN
	RAISERROR ('Invalid username.', 16, 1);
	RETURN;
END
	
--Check UDE_Id is valid or not for update sample
IF(@UDE_Id <> 0 OR @TransNum = 2)
BEGIN
	IF NOT EXISTS(SELECT * FROM DBO.User_Defined_Events WITH(NOLOCK) WHERE UDE_Id = @UDE_Id) 
	BEGIN
		RAISERROR ('@UDE_Id does not exist.', 16, 1);
		RETURN;
	END
	ELSE --Set starttime and endtime while update sample with given UDE_Id
		SELECT @StartTime = Start_Time, @EndTime = End_Time FROM DBO.User_Defined_Events WITH(NOLOCK) WHERE UDE_Id = @UDE_Id;
END

--Check if UDE_Desc already exists
IF (@UDE_Id = 0 OR @TransNum = 1)
BEGIN
	IF EXISTS (SELECT * FROM DBO.User_Defined_Events WITH(NOLOCK) WHERE UDE_Desc = @UDE_Desc)
	BEGIN
		SELECT Error = 'UDE_Desc:<' + @UDE_Desc + '> already exists.';
		RETURN @@ERROR;
	END

	IF EXISTS(SELECT * FROM DBO.Events WITH(NOLOCK) WHERE Event_Id = @Event_Id) 
	BEGIN
		SELECT	@PUId = NULL, @EventStatus = NULL;
		SELECT	@PUId = PU_Id, @EventStatus = Event_Status FROM DBO.Events WITH(NOLOCK) WHERE Event_Id = @Event_Id;

		--SET Event_SubType_Id 
		SELECT @EventSubTypeId = Event_SubType_Id FROM DBO.Event_Subtypes WITH(NOLOCK)    
		WHERE ET_Id = 14 AND Event_Subtype_Desc = N'Inspection Sample';    -- should we hardcode ET_Id to 14?
  
		IF(@EventSubTypeId IS NULL) 
		BEGIN
			SELECT Error = '@EventSubTypeId cannot be NULL.';
			RETURN @@ERROR;
		END 

		--SET startTime and endTime -- Has to be Current Record
		SET @EndTime = NULL
 		SELECT @StartTime = MAX(End_Time) FROM DBO.User_Defined_Events WITH(NOLOCK) WHERE PU_Id = @PUId AND Event_SubType_Id = @EventSubTypeId;
		--CONVERT(DATETIME, CONVERT(VARCHAR(25), End_Time, 120)) -- keep this for now
		SET @EndTime = DATEADD(SECOND, + 1, @StartTime);
    END
	ELSE 
	BEGIN
		SELECT Error = 'Event_Id:<' + @Event_Id + '> is not found.';
		RETURN @@ERROR;
	END
END

IF (@TransNum = 1)
BEGIN
	EXECUTE [DBO].[spServer_DBMgrUpdUserEvent]
     0,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 0,
 	 NULL,
 	 @EventSubTypeId,
 	 @PUId,
 	 @UDE_Desc,
 	 @UDE_Id  OUTPUT, 	  	  	  	  	  	
 	 @UserId,
 	 NULL,
 	 @StartTime,
 	 @EndTime,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL, 
 	 @TransNum,
 	 NULL,
 	 NULL, 	  	  
 	 NULL,
 	 @Event_Id,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL, 
     NULL;
END
ELSE
BEGIN
	EXECUTE [DBO].[spServer_DBMgrUpdUserEvent]
     0,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 0,
 	 NULL,
 	 @EventSubTypeId,
 	 @PUId,
 	 @UDE_Desc,
 	 @UDE_Id  OUTPUT, 	  	  	  	  	  	
 	 @UserId,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL, 
 	 @TransNum,
 	 NULL,
 	 NULL, 	  	  
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL, 
     NULL;
END

IF (@UDE_Id IS NOT NULL)
BEGIN

	SELECT @AutoGeneratedVarId = Var_Id FROM Variables_Base WITH(NOLOCK) WHERE PU_Id = @PUId AND Var_Desc = N'AutoGeneratedSample';
	SELECT @Result_On = End_Time FROM User_Defined_Events WITH(NOLOCK) WHERE UDE_Id = @UDE_Id;

	-- For manual samples, AutoGeneratedSample variable must be added
	IF (@AutoGeneratedVarId IS NOT NULL)
	BEGIN
		IF (@Result_On IS NOT NULL)
		BEGIN
			EXECUTE [DBO].spServer_DBMgrUpdTest2     
			 @AutoGeneratedVarId,     
			 @UserId,     
			 0,     
			 '0', -- means this is not an auto generated sample  
			 @Result_On,     
			 0,    
			 NULL,    
			 NULL,     
			 NULL,    
			 NULL,     
			 @TestId OUTPUT,     
			 NULL,     
			 NULL,     
			 NULL,     
			 NULL,     
			 NULL; 
		 END
	END

	-- Table to hold unique variables that sample engine used initially
	DECLARE @tTests TABLE (
		Id					INT   NOT NULL IDENTITY(1,1), 
		Var_Id				INT NOT NULL,
		Product_Id			INT NOT NULL,
		Char_Id				INT NULL,
		Spec_Id				INT NULL,
		Spec_Desc			NVARCHAR(50) DEFAULT '',
		TestValue			NVARCHAR(25) NULL,
		PU_Groups_PUG_Desc	NVARCHAR(50) NULL,
		VB_PUG_Id			INT NULL
	);

	DECLARE @tVariables TABLE (
		Id			INT   NOT NULL IDENTITY(1,1), 
		Var_Id		INT NOT NULL,
		Spec_Desc	NVARCHAR(50) DEFAULT '',
		TestValue	NVARCHAR(25) NULL
	);
	
	-- Find out what the Receiver Id is in order to find other lots
	DECLARE @ReceiverId INT;
	SELECT	@ReceiverId = EC.Source_Event_Id
	FROM		User_Defined_Events UDE WITH(NOLOCK)
	JOIN		Event_Components EC WITH(NOLOCK)
	ON		UDE.Event_Id = EC.Event_Id
	AND		UDE.UDE_Id = @UDE_Id;
	
	IF (@ReceiverId IS NOT NULL)
	BEGIN
		DECLARE @RowId			INT,
				@RowCount		INT,
				@Current_Var_Id INT,
				@CommonTestValue NVARCHAR(25),
				@Current_Spec_Desc NVARCHAR(50);

		INSERT INTO @tTests(Var_Id, Product_Id, TestValue)
		SELECT	tests.Var_Id, eve.Applied_Product, tests.Result
		FROM		Tests tests WITH(NOLOCK)
		JOIN		User_Defined_Events ude WITH(NOLOCK)
		ON		tests.Event_Id = ude.UDE_Id
		JOIN		Event_Components ec WITH(NOLOCK)
		ON		ec.Event_Id = ude.Event_Id
		JOIN		Events eve WITH(NOLOCK)
		ON		eve.Event_Id = ec.Event_Id
		AND		ec.Source_Event_Id = @ReceiverId;
		
		-- Get variable precision and sort order
		UPDATE  T SET T.VB_PUG_Id = VB.PUG_Id
		FROM		@tTests T
		JOIN		Variables_Base VB WITH(NOLOCK)
		ON		T.Var_Id = VB.Var_Id;
		
		-- Get variable group name and sort order
		UPDATE	T SET T.PU_Groups_PUG_Desc = PG.PUG_Desc
		FROM		@tTests T
		JOIN		PU_Groups PG WITH(NOLOCK)
		ON		T.VB_PUG_Id = PG.PUG_Id;

		-- Get characteristic found on product
		UPDATE	T SET T.Char_Id = PCD.Char_Id
		FROM		@tTests T
		JOIN		Product_Characteristic_Defaults PCD WITH(NOLOCK)
		ON		PCD.Prod_Id = T.Product_Id
		JOIN		Product_Properties PP WITH(NOLOCK)
		ON		PP.Prop_Id = PCD.Prop_Id
		AND		PP.Prop_Desc = N'Receiving and Inspection';
		
		-- Get current active specifications
		UPDATE	T SET T.Spec_Id = active_specs.Spec_Id
		FROM		@tTests T
		JOIN		Active_Specs active_specs WITH(NOLOCK)
		ON		T.PU_Groups_PUG_Desc = active_specs.[Target]
		AND		T.Char_Id = active_specs.Char_Id
		AND		active_specs.Expiration_Date IS NULL;
		
		-- Get specification names
		UPDATE	T SET T.Spec_Desc = specs.Spec_Desc
		FROM		@tTests T
		JOIN		Specifications specs WITH(NOLOCK)
		ON		T.Spec_Id = specs.Spec_Id;

		-- Populate @tVariables with unique var ids
		INSERT INTO @tVariables (Var_Id)
		SELECT DISTINCT Var_Id FROM @tTests;

		UPDATE T SET T.Spec_Desc = tests.Spec_Desc,
				T.TestValue = tests.TestValue
		FROM		@tVariables T
		JOIN		@tTests tests
		ON		T.Var_Id = tests.Var_Id;

		SELECT	@RowCount = @@ROWCOUNT, @RowId = 1; 

		IF (@RowCount > 0)
		BEGIN
			WHILE @RowId <= @RowCount  
			BEGIN
				SELECT @Current_Var_Id = Var_Id, @CommonTestValue = TestValue, @Current_Spec_Desc = Spec_Desc FROM @tVariables WHERE Id = @RowId;
				IF (LOWER(@Current_Spec_Desc) = 'tcr-common criteria')
				BEGIN
					IF (@Current_Var_Id IS NOT NULL AND @Result_On IS NOT NULL)
					BEGIN
						EXECUTE spServer_DBMgrUpdTest2     
							@Current_Var_Id,     
							@UserId,     
							0,     
							@CommonTestValue, --@Test_Value,     
							@Result_On,     
							0,    
							NULL,    
							NULL,     
							NULL,    
							NULL,     
							@TestId OUTPUT,     
							NULL,     
							NULL,     
							NULL,     
							NULL,     
							NULL; 
					END
				END
				ELSE
				BEGIN
					IF (@Current_Var_Id IS NOT NULL AND @Result_On IS NOT NULL)
					BEGIN
						EXECUTE spServer_DBMgrUpdTest2     
							@Current_Var_Id,     
							@UserId,     
							0,     
							NULL,	--@Test_Value,     
							@Result_On,     
							0,    
							NULL,    
							NULL,     
							NULL,    
							NULL,     
							@TestId OUTPUT,     
							NULL,     
							NULL,     
							NULL,     
							NULL,     
							NULL; 
					END
				END
				SELECT @RowId = @RowId + 1; 
			END
		END
	END
END

SELECT	u.UDE_Id,
		u.Event_Id,
		u.Start_Time,
		u.End_Time,
		u.UDE_Desc,
		u.PU_Id,
		u.Event_Subtype_Id,
		eve.Event_Id AS Receiver_Event_Id
		
FROM		User_Defined_Events u WITH(NOLOCK) 
JOIN		Event_Components ec WITH(NOLOCK) 
ON		ec.Event_Id = u.Event_Id
JOIN		Events eve WITH(NOLOCK) 
ON		eve.Event_Id = ec.Source_Event_Id
AND		u.UDE_Id = @UDE_Id;
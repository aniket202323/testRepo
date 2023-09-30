
CREATE PROCEDURE [dbo].[spRIS_CreateUpdateTests]    
	@Test_Id		BIGINT,    
	@Test_Value NVARCHAR(25),    
	@Var_Id		NVARCHAR(200),    
	@UserID		INT,    
	@Event_Id	BIGINT,    
	@TransNum	INT = NULL -- 0 to create test, NULL to update tests          
AS 

/*---------------------------------------------------------------------------------------------------------------------
    This procedure will either create a new test (UDE) or update an existing one with the value provided
  
    Date         Ver/Build   Author              Story/Defect		Remarks
    07-Jan-2020  001         Bhavani				 US390388			Initial Development (Retrieve test results for a sample.)
	27-Mar-2020  002			 Nagaraju			 US390388			Create Update test results
	28-Jul-2020	 003			 Evgeniy Kim			 <N/A>              Cleaned up and added change history
																	Added convert statements to error messages
	17-Sep-2020	 004			 Evgeniy Kim			 DE141380			Users can now update tests with blank values
	09-Nov-2020	 005			 Evgeniy Kim			 DE142311			Performance improvements
---------------------------------------------------------------------------------------------------------------------
    NOTES: 
	1. If @Test_Id = 0, that means a new test is being created
	2. Event_Type of 1: Production Event
	3. Event_Type of 14: User-defined Event
	4. For reasons unknown, the EndTime of the sample UDE must equal to ResultOn value of each test for that sample. /shrug
	
	QUESTIONS:
	1. 


---------------------------------------------------------------------------------------------------------------------*/
DECLARE @TestId				BIGINT,    
		@varID				INT,    
		@Result_On			DATETIME, 
		@PU_Id				INT,    
		@Variable_Count		INT,    
		@DataTypeId			INT,    
		@EventType			INT,    
		@EventId				INT;    
    
SET NOCOUNT ON;    

-- Validate @UserId   
IF NOT EXISTS(SELECT 1 FROM Users WITH(NOLOCK) WHERE User_id = @UserId)    
BEGIN    
	SELECT Auth_Error = N'User [' + CONVERT(NVARCHAR(255), @UserId) + '] not found.';
	RETURN @@ERROR;
END            

-- Validate @Var_Id  select Var_Id, Event_Type from Variables_Base where Var_Id = 107
SELECT @varID = Var_Id, @EventType = Event_Type FROM Variables_Base WITH(NOLOCK) WHERE Var_Id = @Var_Id;
IF(@varID IS NULL)  
BEGIN    
	SELECT Error = N'Variable [' + CONVERT(NVARCHAR(255), @Var_Id) + '] not found.';
	RETURN @@ERROR;
END     
            
IF(@Test_Id = 0) -- Create Test Validations
BEGIN   
	IF (@EventType NOT IN (1, 14))
	BEGIN
		SELECT Error = 'Cannot create test for Event_Type [' + CONVERT(NVARCHAR(255), @EventType) + '].';  
		RETURN @@ERROR; 
	END

	IF(@EventType = 14)  
    BEGIN     
		SELECT @PU_Id = PU_Id, @EventId = UDE_id, @Result_On = End_Time FROM User_Defined_Events WITH(NOLOCK) WHERE UDE_Id = @Event_Id;
        IF(@EventId IS NULL)   
        BEGIN    
			SELECT Error = 'User Defined Event [' + CONVERT(NVARCHAR(255), @Event_Id) + '] not found.'; 
			RETURN @@ERROR;
		END     
    END
	
	IF(@EventType = 1)  
	BEGIN    
		SELECT @PU_Id = PU_Id, @EventId = Event_Id, @Result_On = TimeStamp FROM Events WITH(NOLOCK) WHERE Event_Id = @Event_Id;
		IF(@EventId IS NULL)   
		BEGIN    
			SELECT Error = 'Production Event [' + CONVERT(NVARCHAR(255), @Event_Id) + '] not found.';
			RETURN @@ERROR; 
		END  
	END    
      
    IF(@PU_Id IS NOT NULL AND @EventType IS NOT NULL)    
    BEGIN    
		SELECT @Variable_Count = COUNT(*) FROM Variables_Base WITH(NOLOCK) WHERE PU_Id = @PU_Id AND Event_type = @EventType AND Var_Id = @Var_Id;    
        IF(@Variable_Count = 0)    
		BEGIN    
			SELECT Error = 'No variables found for PU_Id [' + CONVERT(NVARCHAR(255), @PU_id) + '], Event_Type [' + CONVERT(NVARCHAR(255), @EventType) + '], Var_Id [' + CONVERT(NVARCHAR(255), @Var_Id) + '].';    
			RETURN @@ERROR;    
        END    
    END    
      
	IF(EXISTS(SELECT 1 FROM Tests WITH(NOLOCK) WHERE Result_On = @Result_On AND Var_Id = @Var_Id))   
	BEGIN    
		SELECT Error = 'Test already exists with Var_Id [' + CONVERT(NVARCHAR(255), @Var_Id) + '], Result_On [' + CONVERT(NVARCHAR(255), @Result_On) + '].';    
		RETURN @@ERROR;    
	END      
END    
ELSE  -- Update Test Validations  
BEGIN    
	IF(NOT EXISTS(SELECT Test_Id FROM Tests WITH(NOLOCK) WHERE Test_Id = @Test_Id))    
	BEGIN    
		SELECT Error = 'Test [' + CONVERT(NVARCHAR(255), @Test_Id) + '] not found.';    
		RETURN @@ERROR;    
	END    
     
	IF(NOT EXISTS(SELECT Test_Id FROM Tests WITH(NOLOCK) WHERE Test_Id = @Test_Id and Event_Id = @Event_Id))   
	BEGIN    
		SELECT Error = 'Test [' + CONVERT(NVARCHAR(255), @Test_Id) + '] not found on sample [' + CONVERT(NVARCHAR(255), @Event_Id) + '].';    
		RETURN @@ERROR;    
	END    
   
	IF(NOT EXISTS(SELECT Test_Id FROM Tests WITH(NOLOCK) WHERE Test_Id = @Test_Id and Var_Id = @Var_Id and Event_Id = @Event_Id))    
	BEGIN    
		SELECT Error = 'Test [' + CONVERT(NVARCHAR(255), @Test_Id) + '] not found on sample [' + CONVERT(NVARCHAR(255), @Event_Id) + '] and variable [' + CONVERT(NVARCHAR(255), @Var_Id) + '].';  
		--'Variable Id is not matched with given Test Id';    
		RETURN @@ERROR;    
	END 
  
    SET @Result_On = NULL;    
    SELECT @Result_On = Result_On FROM Tests WITH(NOLOCK) WHERE Test_Id = @Test_Id;

	IF(@Result_On IS NULL)  
	BEGIN    
		SELECT Error = 'Result_On value is empty for test [' + CONVERT(NVARCHAR(255), @Test_Id) + '].';    
		RETURN @@ERROR;    
	END
END    
        
SELECT	@DataTypeId = v.Data_Type_Id 
FROM		Variables AS v  WITH(NOLOCK)   
JOIN		Data_Type AS d  WITH(NOLOCK)
ON		d.Data_Type_Id = v.Data_Type_Id    
WHERE	Var_Id = @Var_Id    
   
IF(@DataTypeId = 1) -- Integer    
BEGIN    
	IF (@Test_Value <> '' AND @Test_Value IS NOT NULL AND ISNUMERIC(Replace(Replace(@Test_Value,'+','A'),'-','A') + '.0e0') = 0)  
    BEGIN    
		SELECT Error = 'Test value [' + CONVERT(NVARCHAR(255), @Test_Value) + '] is invalid for variable [' + CONVERT(NVARCHAR(255), @Var_Id) + '] of data type [Integer].';    
		RETURN @@ERROR;    
	END    
END    

IF(@DataTypeId = 2) -- Float    
BEGIN    
	IF (@Test_Value <> '' AND @Test_Value IS NOT NULL AND ISNUMERIC(@Test_Value) = 0)    
    BEGIN    
		SELECT Error = 'Test value [' + CONVERT(NVARCHAR(255), @Test_Value) + '] is invalid for variable [' + CONVERT(NVARCHAR(255), @Var_Id) + '] of data type [Float].';  
		RETURN @@ERROR;    
	END    
END    
    
IF(@DataTypeId = 4) --Logical    
BEGIN    
	IF(@Test_Value = 'true' COLLATE Latin1_General_CS_AI)   
	BEGIN    
		SET @Test_Value = '1';    
	END    
	
	IF(@Test_Value = 'false' COLLATE Latin1_General_CS_AI)    
	BEGIN    
	    SET @Test_Value = '0';    
	END    
	            
	--IF(@Test_Value IS NOT NULL AND @Test_Value NOT IN('0', '1'))    
	--BEGIN    
	--	SELECT Error = 'Test value [' + CONVERT(NVARCHAR(255), @Test_Value) + '] is invalid for variable [' + CONVERT(NVARCHAR(255), @Var_Id) + '] of data type [Boolean].';     
	--	RETURN @@ERROR;    
	--END    
END    
    
IF(@Test_Value IS NULL)
BEGIN
	SET @Test_Value = '';
END
      
--Create an entry in tests table Test results    
IF(@TransNum = 0)    
BEGIN     
	EXECUTE spServer_DBMgrUpdTest2     
	@Var_Id,     
	@UserId,     
	0,     
	@Test_Value,     
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
--else udpate test result for the given Result_On and variable id    
ELSE IF (@TransNum IS NULL)   
BEGIN
	DECLARE @ReceiverStatus NVARCHAR(50),
			@LotStatus		NVARCHAR(50),
			@SpecDesc		NVARCHAR(50),
			@Receiver_Id		INT;

	DECLARE @testResults TABLE (
		SampleId				INT NOT NULL,
		Test_Id				BIGINT NOT NULL,
		Result				NVARCHAR(25) NULL,
		Var_Id				INT NOT NULL,
		Result_On			DATETIME NOT NULL,
		Receiver_Id			INT NULL,
		Lot_Id				INT NULL,
		ReceiverStatus		NVARCHAR(255) NULL,
		LotStatus			NVARCHAR(255) NULL,
		Spec_Desc			NVARCHAR(50) DEFAULT '',
		Applied_Product		INT NULL
	);

	INSERT INTO @testResults (SampleId, Test_Id, Result, Var_Id, Result_On, Receiver_Id, Lot_Id)
	SELECT	t.Event_Id, t.Test_Id, t.Result, t.Var_Id, t.Result_On, ec.Source_Event_Id, ec.Event_Id
	FROM		Tests t WITH(NOLOCK)
	JOIN		User_Defined_Events ude WITH(NOLOCK)
	ON		t.Event_Id = ude.UDE_Id
	JOIN		Event_Components ec WITH(NOLOCK)
	ON		ec.Event_Id = ude.Event_Id
	AND		t.Test_Id = @Test_Id;

	UPDATE T SET	 ReceiverStatus = PS.ProdStatus_Desc
	FROM		@testResults T
	JOIN		[Events] E WITH(NOLOCK)
	ON		T.Receiver_Id = E.Event_Id
	JOIN		Production_Status PS WITH(NOLOCK)
	ON		E.Event_Status = PS.ProdStatus_Id
	
	UPDATE T SET LotStatus = PS.ProdStatus_Desc,
			 Applied_Product = E.Applied_Product
	FROM		@testResults T
	JOIN		[Events] E WITH(NOLOCK)
	ON		T.Lot_Id = E.Event_Id
	JOIN		Production_Status PS WITH(NOLOCK)
	ON		E.Event_Status = PS.ProdStatus_Id

	SELECT @ReceiverStatus = ReceiverStatus, @LotStatus = LotStatus, @Receiver_Id = Receiver_Id FROM @testResults;

	IF(LOWER(@ReceiverStatus) <> 'waiting inspection' AND LOWER(@ReceiverStatus) <> 'inspection in progress')  
	BEGIN    
		SELECT Error = N'Receiver Status must be Waiting Inspection or Inspection In Progress.';
		RETURN @@ERROR;
	END  
	
	IF(LOWER(@LotStatus) = 'accept' AND LOWER(@LotStatus) = 'mrb/ncr')  
	BEGIN    
		SELECT Error = N'Material lot status cannot be Accept or MRB/NCR.';
		RETURN @@ERROR;
	END

	-- Determine specification for this test
	UPDATE  T SET T.Spec_Desc = specs.Spec_Desc
	FROM		@testResults T
	JOIN		Variables_Base VB WITH(NOLOCK)
	ON		T.Var_Id = VB.Var_Id
	JOIN		PU_Groups PG WITH(NOLOCK)
	ON		VB.PUG_Id = PG.PUG_Id
	JOIN		Product_Characteristic_Defaults PCD WITH(NOLOCK)
	ON		PCD.Prod_Id = T.Applied_Product
	JOIN		Product_Properties PP WITH(NOLOCK)
	ON		PP.Prop_Id = PCD.Prop_Id
	AND		PP.Prop_Desc = N'Receiving and Inspection'
	JOIN		Active_Specs active_specs WITH(NOLOCK)
	ON		PG.PUG_Desc = active_specs.[Target]
	AND		PCD.Char_Id = active_specs.Char_Id
	AND		active_specs.Expiration_Date IS NULL
	JOIN		Specifications specs WITH(NOLOCK)
	ON		active_specs.Spec_Id = specs.Spec_Id;

	SELECT @SpecDesc = Spec_Desc FROM @testResults;

	IF (LOWER(@SpecDesc) = 'tcr-common criteria')
	BEGIN
		DECLARE @RowId			INT,
				@RowCount		INT,
				@NextResultOn	DATETIME;

		-- Find all other material lot tests for this variable 
		DECLARE @commonTests TABLE (
			Id			INT   NOT NULL IDENTITY(1,1),
			Result_On			DATETIME NOT NULL
		);

		INSERT INTO @commonTests(Result_On)
		SELECT	T.Result_On
		FROM		Tests t WITH(NOLOCK)
		JOIN		User_Defined_Events ude WITH(NOLOCK)
		ON		t.Event_Id = ude.UDE_Id
		JOIN		Event_Components ec WITH(NOLOCK)
		ON		ec.Event_Id = ude.Event_Id
		JOIN		@testResults temp
		ON		temp.Receiver_id = ec.Source_Event_Id
		AND		T.Var_Id = temp.Var_Id

		SELECT	@RowCount = @@ROWCOUNT, @RowId = 1; 

		-- Update each test found
		IF (@RowCount > 0)
		BEGIN
			WHILE @RowId <= @RowCount  
			BEGIN
				SELECT @NextResultOn = Result_On FROM @commonTests WHERE Id = @RowId;
				EXECUTE spServer_DBMgrUpdTest2     
					@Var_Id,     
					@UserId,     
					0,     
					@Test_Value,     
					@NextResultOn,     
					NULL,     
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

				IF(@TestId IS NOT NULL)
				BEGIN 
					EXEC dbo.spServer_DBMgrUpdPendingResultSet      
						300,  --Topic ID       
						1,  -- Test data     
						@TestId,       
						1 ,  -- @TransType      
						1 ,  --@TransNum      
						2,  --@ResultSetType      
						@UserID; 
				END

				SELECT @RowId = @RowId + 1; 
			END
		END

		-- Any lots that have been accepted or marked with NC need to be reset back to "open" status
		IF (@Receiver_Id IS NOT NULL)
		BEGIN
			DECLARE @OpenStatusId INT;
			SELECT @OpenStatusId = ProdStatus_Id FROM Production_Status WITH(NOLOCK) WHERE LOWER(ProdStatus_Desc) = N'open';

			IF (@OpenStatusId IS NOT NULL)
			BEGIN
				UPDATE	lots SET lots.Event_Status = @OpenStatusId
				FROM		[Events] lots
				JOIN		Event_Components EC
				ON		EC.Event_Id = lots.Event_Id
				AND		EC.Source_Event_Id = @Receiver_Id
				JOIN		Production_Status PS
				ON		PS.ProdStatus_Id = lots.Event_Status
				AND		LOWER(PS.ProdStatus_Desc) IN (N'accept', N'mrb/ncr');
			END
		END
	END

	IF (@SpecDesc = '' OR LOWER(@SpecDesc) <> 'tcr-common criteria')
	BEGIN
		EXECUTE spServer_DBMgrUpdTest2     
			@Var_Id,     
			@UserId,     
			0,     
			@Test_Value,     
			@Result_On,     
			NULL,     
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

		IF(@TestId IS NOT NULL)
		BEGIN 
			EXEC dbo.spServer_DBMgrUpdPendingResultSet      
				300,  --Topic ID       
				1,  -- Test data     
				@TestId,       
				1 ,  -- @TransType      
				1 ,  --@TransNum      
				2,  --@ResultSetType      
				@UserID; 
		END
	END

	-- Set receiver status to 'Inspection in Progress' for first time tests
	IF (LOWER(@ReceiverStatus) = 'waiting inspection')
	BEGIN
		DECLARE @StatusId INT;
		SELECT @StatusId = ProdStatus_Id FROM Production_Status WITH(NOLOCK) WHERE LOWER(ProdStatus_Desc) = N'inspection in progress';

		IF (@Receiver_Id IS NOT NULL AND @StatusId IS NOT NULL)
		BEGIN
			UPDATE [Events] SET Event_Status = @StatusId WHERE Event_Id = @Receiver_Id;
		END
	END
END     
    
SELECT  t.Event_Id,      
		t.Test_Id,      
		t.Result,      
		t.canceled,      
		t.Var_Id,    
		t.Result_On    
FROM		Tests t WITH(NOLOCK)       
WHERE	t.Result_On = @Result_On 
AND		Test_Id = @Test_Id;    
    
SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
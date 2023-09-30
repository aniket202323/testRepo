
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Calc_SYSSetInitialStartupValues
--------------------------------------------------------------------------------------------------
-- Author			: PRASHANTH BAKSHI & PRADEEP SUVARNA, TCS Ltd.        
-- Date created			: 2010-05-10              
-- Version			: 1.0        
-- SP Type			: Calculation        
-- Called by			: Calculation
-- Description			: Initalize StartUp Display Variables based on PO STATUS 
--						sets all the values to a defined state (i.e. NO) and puts other data like bulk batch...      
-- Editor tab spacing		: 3
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2010-05-10		P. BAKSHI				Initial Release
--================================================================================================

CREATE  PROCEDURE dbo.spLocal_Calc_SYSSetInitialStartupValues
-- DECLARE	
	@Outputvalue  		VARCHAR(25) OUTPUT,
	@dtmTime    		DATETIME,
	@intthisvar_id   	INT,
	@intUDEId		INT,
	@intConfirmPOvar_id   	INT,
	@intSUDCompletevar_id  	INT,
	@intFBNvar_id		INT,
	@OkayValue 		VARCHAR(30),
	@PhrasesInculded 	VARCHAR(255)

--WITH ENCRYPTION  
AS  



-- SELECT
-- 	@dtmTime='2010-06-21 23:17:20',
-- 	@intthisvar_id=138173,
-- 	@intUDEId=310,
-- 	@intConfirmPOvar_id=138055,
-- 	@intSUDCompletevar_id =138115,
-- 	@intFBNvar_id	=138081,
-- 	@OkayValue='Yes',
-- 	@PhrasesInculded ='Na|No'
             

DECLARE
	@strThisValue 		VARCHAR(30),                    
	@intSheetid   		INT,                    
	@Sheet_Desc  		VARCHAR(50),                    
	@strType    		VARCHAR(25),                    
	@VarIDPO    		INT,                    
	@PONumberVar  		VARCHAR(30),                    
	@StatusID   		INT,                    
	@PU_ID    		INT,                    
	@intUserId   		INT,                    
	@VarIDAlarm   		INT,                    
	@Alarm_Timestamp 	DATETIME,                    
	@PP_ID    		INT,                    
	@TransType   		INT,                    
	@AppVersion   		VARCHAR(30),                    
	@RowNum    		INT,                    
	@RowCount   		INT,                    
	@SUDComplete  		VARCHAR(30),              
	@Locked 		INT,          
	@i 			INT,          
	@j 			INT,          
	@Phrasetext 		VARCHAR(30),      
	@intCount 		INT,
	@intEventSubTypeId      INT,
	@intPPId		INT,
	@strFBNProdSetup        VARCHAR(25),
	@strPONumber		VARCHAR(25)
             
              
                    
DECLARE @ResultSetVariables TABLE 
(                    
	intVarId   		INT,
	intPUId   		INT,
	intUserId  		INT,
	intCanceled  		INT DEFAULT 0,
	strResult  		VARCHAR(25),
	dtmResultOn  		DATETIME,
	intTransType  		INT DEFAULT 1,
	intPost   		INT DEFAULT 0,
	intDataType  		INT
)

DECLARE @DataTypes TABLE
(
	RowNum  		INT identity(1, 1),
	DT_ID  			INT,   
	phrase_value 		VARCHAR(30)
)

DECLARE  @Phrasevalue TABLE                                                      
(                                                                      
	pKey         		INT ,                                                                      
	PhraseDesc  		VARCHAR(25)                                                                      
)          
                    
SET NOCOUNT ON

SET @intEventSubTypeId=0  

--GET UDE TYPE AND UDE DESC [ PO NUMBER ] 
SELECT  @intEventSubTypeId = Event_SubType_Id,@strPONumber=UDE_DESC            
FROM  dbo.User_Defined_Events   WITH(NOLOCK)            
WHERE UDE_Id = @intUDEId  


IF @intEventSubTypeId <> (SELECT Event_Subtype_ID FROM VARIABLES WITH(NOLOCK) WHERE VAR_ID=@intConfirmPOvar_id)        
BEGIN     
	SET @Outputvalue = 'DONOTHING'--'START UP TYPE EVENT IS NOT FIRED'
	SET NOCOUNT OFF
	RETURN
END

SET @intUserId = 
(
	SELECT user_id 
	FROM dbo.Users_Base WITH(NOLOCK)
	WHERE username = 'CalculationMgr'
)

SET @PU_ID=
(
	SELECT PU_ID 
	FROM 	variables WITH(NOLOCK) 
	WHERE 	var_id=@intConfirmPOvar_id
)

IF @strPONumber IS NULL
BEGIN     
	SET @Outputvalue = 'DONOTHING'--'PO NUMBER CANNOT BE NULL'
	SET NOCOUNT OFF
	RETURN
END

-- IF @intCount=0
IF NOT EXISTS (	SELECT result FROM dbo.tests WITH(NOLOCK)
	WHERE var_id = @intthisvar_id AND result_on = @dtmTime )
BEGIN
	-- GET PP_ID
	SELECT @intPPId=pp_Id
	FROM dbo.Production_Plan WITH(NOLOCK)               
	WHERE Process_Order=@strPONumber

	SELECT @intCount=COUNT(*)
	FROM PRODUCTION_PLAN_STARTS WITH(NOLOCK) 
	WHERE PP_ID=@intPPId
	AND PU_ID=@PU_ID
	AND End_Time IS NULL

	SET @strFBNProdSetup =(SELECT User_General_1 FROM dbo.Production_Plan WITH(NOLOCK) WHERE PP_Id = @intPPId)        
	IF  @strFBNProdSetup IS NULL        
	SET @strFBNProdSetup='NOT DEFINED'

	--POPULATE THE FINISH BATCH NUMBER
	INSERT @ResultSetVariables 
	(intVarId,intPUId,intUserId,dtmResultOn,strResult)
	SELECT @intFBNvar_id,@PU_ID,@intUserId,@dtmTime,@strFBNProdSetup
			
     
	--IF PO IS ACTIVE THEN POPULATE THE CONFIRM PROCESS ORDER \ START UP AND EXIT
	IF @intCount=1
	BEGIN
	
		-- SET START UP TO YES	
		INSERT @ResultSetVariables 
		(intVarId,intPUId,intUserId,dtmResultOn,strResult)
		SELECT @intSUDCompletevar_id,@PU_ID,@intUserId,@dtmTime,@OkayValue
	
		-- SET Confirm Process Order 
		INSERT @ResultSetVariables 
		(intVarId,intPUId,intUserId,dtmResultOn,strResult)
		SELECT @intConfirmPOvar_id,@PU_ID,@intUserId,@dtmTime,@strPONumber
	
			SELECT                    
				2,               -- Resultset Number                    
				intVarId,        -- Var_Id                    
				intPUId,         -- PU_Id                    
				intUserId,       -- User_Id                    
				intCanceled,     -- Canceled                    
				strResult,       -- Result                    
				dtmResultOn,     -- TimeStamp                    
				intTransType,    -- TransactionType (1=Add 2=Update 3=Delete)                    
				0,               -- UpdateType (0=PreUpdate 1=PostUpdate)                    
				NULL,            -- SecondUserId                    
				NULL,            -- TransNum                    
				NULL,            -- EventId                    
				NULL,            -- ArrayId                    
				NULL             -- CommentId                    
			FROM @ResultSetVariables              
	
		SET @outputvalue = 'TriggeredActive'
		SET NOCOUNT OFF
		RETURN
	END
	
	IF @intCount=0
	BEGIN              
	
		INSERT @ResultSetVariables 
		(intVarId,intPUId,intUserId,dtmResultOn,strResult)
		SELECT @intConfirmPOvar_id,@PU_ID,@intUserId,@dtmTime,NULL
	            
		
			CREATE TABLE #Phrasevalue
			(
				pKey         INT ,
				PhraseDesc  VARCHAR(25)
			)
	
			INSERT INTO #Phrasevalue(pKey, PhraseDesc)
			EXEC SPCMN_ReportCollectionParsing
				@PRMCollectionString = @PhrasesInculded,
				@PRMFieldDelimiter = NULL,
				@PRMRecordDelimiter = '|',
				@PRMDataType01 = 'VARCHAR(30)'
	
			INSERT INTO @Phrasevalue(pKey, PhraseDesc)
			SELECT pKey, PhraseDesc  FROM #Phrasevalue
			DROP TABLE #Phrasevalue
	
			SET @i = 1
	
			SET @j = (SELECT COUNT(*) FROM @Phrasevalue)                    
	
			WHILE @i<=@j          
			BEGIN          
				SET @Phrasetext=(SELECT PhraseDesc FROM @Phrasevalue WHERE Pkey=@i)          
			
				INSERT 	@DataTypes (DT_ID,phrase_value)
				SELECT 	DISTINCT dt.data_type_id,phrase_value
				FROM 	dbo.data_type dt WITH(NOLOCK)
				JOIN 	dbo.phrase p WITH(NOLOCK) 
					ON dt.data_type_id = p.data_type_id AND phrase_value = @Phrasetext
				WHERE 	dt.data_type_id not in ( SELECT DT_ID FROM @DataTypes)
	
				SET @i=@i+1
			END          
	
			SET @RowNum = 1
			SET @RowCount = (SELECT COUNT(*) FROM @DataTypes)
		
			WHILE @RowNum <= @RowCount                    
			BEGIN                    
				-- Retrieve the variables used (ds_id = 2 : Autolog data source)                    
				INSERT @ResultSetVariables 
				(
					intVarId, 
					intDataType, 
					intPUId, 
					intUserId, 
					dtmResultOn, 
					strResult
				)
				SELECT 	v.var_id, 
					v.data_type_id, 
					@PU_ID, 
					@intUserId, 
					@dtmTime, 
					dt.phrase_value
				FROM 	dbo.Variables_Base v  WITH(NOLOCK) 
				JOIN 	@DataTypes dt  ON dt.DT_ID = v.data_type_id
				WHERE 	v.PU_Id   = @PU_ID
					AND v.Event_SubType_Id =  @intEventSubTypeId
					AND v.ds_id = 2  
					AND (dt.RowNum = @RowNum) 
					AND (v.repeating IS NULL OR v.repeating = 0)
		
				SET @RowNum = @RowNum + 1
			END
		
			SELECT                    
				2,               -- Resultset Number                    
				intVarId,        -- Var_Id                    
				intPUId,         -- PU_Id                    
				intUserId,       -- User_Id                    
				intCanceled,     -- Canceled                    
				strResult,       -- Result                    
				dtmResultOn,     -- TimeStamp                    
				intTransType,    -- TransactionType (1=Add 2=Update 3=Delete)                    
				0,               -- UpdateType (0=PreUpdate 1=PostUpdate)                    
				NULL,            -- SecondUserId                    
				NULL,            -- TransNum                    
				NULL,            -- EventId                    
				NULL,            -- ArrayId                    
				NULL             -- CommentId                    
			FROM @ResultSetVariables                    
	
			SET @outputvalue = 'TriggeredInitiated'     
			SET NOCOUNT OFF       
			RETURN          
	END


END

IF EXISTS ( SELECT result FROM dbo.tests WITH(NOLOCK)
	WHERE var_id = @intthisvar_id AND result_on = @dtmTime )
BEGIN
	SET @Outputvalue = 'DONOTHING'--'ALREADY FIRED'

END


SET NOCOUNT OFF


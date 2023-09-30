






--=================================================================================================
--	Tab Value = 4.
--
-- Unsupported Events
--   Step Activity
--   Event File Name
--
--	Updated:	2008/06/01
--	By:			Dan Hinchey SlimSoft
--	Comment:	Modified SP from Iowa City so that 2 layer recipes would not be processed.
---------------------------------------------------------------------------------------------------

--Declare
--		@ReturnStatus					INT				,
--		@ReturnMessage					VARCHAR(255)	,
--		@EConfig_Id						INT
		
--Select
--@EConfig_Id = 425

CREATE PROCEDURE [dbo].[spS88_RSBatch6Reader_HCMRTR06]

		@ReturnStatus					INT		OUTPUT		,
		@ReturnMessage					VARCHAR(255)	OUTPUT ,
		@EConfig_Id						INT

--WITH ENCRYPTION AS 

AS

DECLARE	@DatabaseName					VARCHAR(255),
		@TableName						VARCHAR(255),
		@UserName						VARCHAR(255),
		@IdFieldName					VARCHAR(255),
		@ProductCodeParameter			VARCHAR(255),
		@PurgeDaysToKeep				INT,
		@MaxBatches						INT,
		@IsRecipeValueParameterReport	INT,
		@FilterRecordString				VARCHAR(3000),
		@EndOfBatchPValue				VARCHAR(255),

		@SQL							VARCHAR(3000),
		@BatchId						INT,
		@UnitId							INT,
		@DateId							INT,

		@BatchName						VARCHAR(255),
		@BatchInstance					INT,
		@RecipeDelimiterCount			INT,

		@UnitProcedureName				VARCHAR(255), 
		@UnitProcedureInstance			VARCHAR(255), 
		@OperationName					VARCHAR(255), 
		@OperationInstance				VARCHAR(255), 
		@PhaseName						VARCHAR(255), 
		@PhaseInstance					VARCHAR(255),
		@AreaName						VARCHAR(255),
		@CellName						VARCHAR(255),
		@UnitName						VARCHAR(255),
		@MaxTimeStamp					DATETIME,
		@MinTimeStamp					DATETIME,

		@PurgeStartTime					VARCHAR(25),
		@PurgeEndTime					VARCHAR(25),
		@Now							DATETIME,
		@LotID							Varchar(10),
		@NetWeight						Varchar(20),
		@Max							Int,
		@Min							Int,
	    @Recipe1						Varchar(1000),
		@Lcltime						DateTime,
		@Time1							Datetime,
		@Time2							Datetime,
		@RunningRecordno				int,
		@maxPhaselimit					int,
		@minPhaselimit					int,
		@recipe2						Varchar(1000),
		@recipe3						Varchar(1000),
		@currentrecipeinstance			Int
--=================================================================================================
-- Set Default Values
---------------------------------------------------------------------------------------------------
-- @IsRecipeValueParameterReport	= 1 for 'Recipe Value' = 'ParameterReport'
--									= 0 for 'Recipe Value' = 'RecipeSetup'
-- @PurgeDaysToKeep (Between 1 and 364 days) 0 = No Purge
---------------------------------------------------------------------------------------------------
SELECT	@IdFieldName = 'RecordNo',
		@ProductCodeParameter = 'Product Code',
		@PurgeDaysToKeep = 30,
		@MaxBatches = 1,
		@IsRecipeValueParameterReport = 1,
		@FilterRecordString = '(PValue = ''-9999''
								OR	Recipe LIKE ''%$NULL%''
								OR	((PValue IS NULL OR PValue = '''')
									AND Event IN (''Recipe Header'', ''Report'', ''Scale Factor'', ''Param Download Verified'', 
													''Recipe Value'')))',
		@EndOfBatchPValue = 'End of Batch'


--=================================================================================================
-- Get Source Database and Table Name From Model Configuration
---------------------------------------------------------------------------------------------------
-- TODO: Assign the Model Field Ids
---------------------------------------------------------------------------------------------------
Declare 
@ParamPropertyName Varchar(100),
 @ParamDefaultValue Varchar(100),
 @BatchDatabaseOwner Varchar(10)

SET @ParamPropertyName = 'Batch table Name'     

SET @ParamDefaultValue = 'Not Found'    

EXEC spCMN_ModelParameterLookup     

 @Tablename OUTPUT,    

 @EConfig_Id,    

 @ParamPropertyName,    

 @ParamDefaultValue    



SET @ParamPropertyName = 'Batch Database Name'     

SET @ParamDefaultValue = 'Not Found'    

EXEC spCMN_ModelParameterLookup     

 @DatabaseName OUTPUT,    

 @EConfig_Id,    

 @ParamPropertyName,    

 @ParamDefaultValue  

 SET @ParamPropertyName = 'Batch Database Owner'     

SET @ParamDefaultValue = 'Not Found'    

EXEC spCMN_ModelParameterLookup     

 @UserName OUTPUT,    

 @EConfig_Id,    

 @ParamPropertyName,    

 @ParamDefaultValue  





--=================================================================================================
-- Set Initial Values
---------------------------------------------------------------------------------------------------
SELECT	@ReturnStatus = 1,
		@ReturnMessage = '',
		@TableName = @DatabaseName + '.' + @UserName + '.' + @TableName


--=================================================================================================
-- Create Temporary Table For Event Transactions
---------------------------------------------------------------------------------------------------
CREATE	TABLE	#tEventTransactions (
		ID							INT PRIMARY KEY IDENTITY,
		EventTimeStamp		 		DATETIME			NULL,
		EventType		 			VARCHAR(255)		NULL,
		AreaName		 			VARCHAR(255)		NULL,
		CellName		 			VARCHAR(255)		NULL,
		UnitName		 			VARCHAR(255)		NULL,
		BatchName		 			VARCHAR(255)		NULL,
		BatchInstance				INT					NULL,
		BatchProductCode	 		VARCHAR(255)		NULL,
		UnitProcedureName			VARCHAR(255)		NULL,
		UnitProcedureInstance		VARCHAR(255)		NULL,
		OperationName				VARCHAR(255)		NULL,
		OperationInstance			VARCHAR(255)		NULL,
		PhaseName					VARCHAR(255)		NULL,
		PhaseInstance				VARCHAR(255)		NULL,
		ProcedureStartTime			DATETIME			NULL,
		ProcedureEndTime			DATETIME			NULL,
		ParameterName				VARCHAR(255)		NULL,
		ParameterAttributeName		VARCHAR(255)		NULL,
		ParameterAttributeUOM		VARCHAR(255)		NULL,
		ParameterAttributeValue		VARCHAR(255)		NULL,
		RawMaterialAreaName			VARCHAR(255)		NULL,
		RawMaterialCellName			VARCHAR(255)		NULL,
		RawMaterialUnitName			VARCHAR(255)		NULL,
		RawMaterialProductCode		VARCHAR(255)		NULL,
		RawMaterialBatchName		VARCHAR(255)		NULL,
		RawMaterialContainerId		VARCHAR(255)		NULL,
		RawMaterialDimensionA		FLOAT				NULL,
		RawMaterialDimensionX		FLOAT				NULL,
		RawMaterialDimensionY		FLOAT				NULL,
		RawMaterialDimensionZ		FLOAT				NULL,
		StateValue					VARCHAR(255)		NULL,
		EventName					VARCHAR(255)		NULL,
		UserName					VARCHAR(255)		NULL,
		UserSignature				VARCHAR(255)		NULL,
		RecipeString				VARCHAR(255)		NULL,
		RecordNumber 				INT					NULL )

CREATE TABLE #TimeDifference (
		ID							INT Identity(1,1),
		Batchid						Varchar(25),
		StartTime					DateTime,
		EndTime						DateTime,
		TimeDifferenceinSec			Int )

CREATE	TABLE	#tBatches (
		ID							INT PRIMARY KEY IDENTITY,
		BatchName					VARCHAR(255)		NULL,
		BatchInstance				INT					NULL,
		RecipeDelimiterCount		INT )
DECLARE	@tUnits			TABLE (
		ID							INT PRIMARY KEY IDENTITY,
		AreaName					VARCHAR(255)		NULL )
DECLARE	@tDates			TABLE (
		ID							INT PRIMARY KEY IDENTITY,
		UnitProcedureName			VARCHAR(255)		NULL,
		UnitProcedureInstance		VARCHAR(255)		NULL,
		OperationName				VARCHAR(255)		NULL,
		OperationInstance			VARCHAR(255)		NULL,
		PhaseName					VARCHAR(255)		NULL,
		PhaseInstance				VARCHAR(255)		NULL )


DECLARE @Recipe			 TABLE (
		ID							INT Identity(1,1),
		Batchid						Varchar(25)			NULL,
		Recipe						Varchar(500)		NULL)


DECLARE @Lcltimetable	TABLE (
		ID							INT Identity(1,1),
		Batchid						VARCHAR(25)			NULL,
		Lcltime						DATETIME,
		Recipe						VARCHAR(1000))


CREATE TABLE #Temp (	
		[GMT]						 [datetime]			NULL,
		[lclTime]					 [datetime]			NULL,
		[UniqueID]					 [varchar](12)		NULL,
		[BatchID]					 [varchar](50)		NULL,
		[Recipe]					 [varchar](1000)	NULL,
		[Descript]					 [varchar](255)		NULL,
		[Event]						 [varchar](155)		NULL,
		[PValue]					 [varchar](255)		NULL,
		[DescriptAPI]				 [varchar](255)		NULL,
		[EventAPI]					 [varchar](155)		NULL,
		[PValueAPI]					 [varchar](255)		NULL,
		[EU]						 [varchar](255)		NULL,
		[Area]						 [varchar](155)		NULL,
		[ProcCell]					 [varchar](155)		NULL,
		[Unit]						 [varchar](155)		NULL,
		[Phase]						 [varchar](155)		NULL,
		[Printed]					 [datetime]			NULL,
		[UserID]					 [varchar](85)		NULL,
		[PhaseDesc]					 [varchar](50)		NULL,
		[MaterialName]				 [varchar](155)		NULL,
		[MaterialID]				 [varchar](50)		NULL,
		[LotName]					 [varchar](255)		NULL,
		[Label]						 [varchar](255)		NULL,
		[Container]					 [varchar](255)		NULL,
		[PromiseID]					 [varchar](50)		NULL,
		[Signature]					 [varchar](300)		NULL,
		[ERP_Flag]					 [varchar](1)		NULL,
		[RecordNo]					 [int] IDENTITY(1,1) NOT NULL,
		[ReactivationNumber]		 [int]				NULL,
		[InstructionHTML]			 [ntext]			NULL
	)
--=================================================================================================
-- Get batches to process
---------------------------------------------------------------------------------------------------

SELECT	@SQL =	'SELECT TOP ' + CONVERT(VARCHAR(25), @MaxBatches) + ' BatchId, UniqueId '
				+ ' FROM ' + @TableName + ' ' 
				+ ' WHERE PValue = ''' + @EndOfBatchPValue + '''' 
				+ ' AND LCLTime <= DATEADD(DAY, 3, GETDATE()) '
				+ ' ORDER BY LCLTime'
INSERT	#tBatches (BatchName, BatchInstance)
	EXEC	(@SQL)



--Insert   #tbatches (BatchName, BatchInstance)
--(Select '0004050473',20514)
--=================================================================================================
-- Determine recipe field delimiter count.
-- Used to determine if recipe is "4 layer" recipe.
---------------------------------------------------------------------------------------------------
SELECT	@SQL =	'UPDATE	#tBatches '
				+ 'SET	RecipeDelimiterCount = iCount '
				+ 'FROM '
 				+ '(SELECT	UniqueId, MAX((LEN(recipe) - LEN(REPLACE(recipe, ''\'', '''')))) AS iCount '
				+ 'FROM	#tBatches b '
				+ 'JOIN	' + @TableName + ' bh '
				+ '		ON b.BatchInstance = bh.UniqueId '
				+ 'GROUP	BY	UniqueId) subquery '

EXEC	(@SQL)
--=================================================================================================
-- Put filtered records 10 years in the future
---------------------------------------------------------------------------------------------------
SELECT	@SQL = 'UPDATE ' + @TableName
			 + ' SET LCLTime = CONVERT(VARCHAR(25), DATEADD(YEAR, 10, LCLTime), 120)'
			 + ' WHERE ' + @FilterRecordString
			 + ' AND LCLTime < DATEADD(DAY, 3, GETDATE())'
EXEC	(@SQL)
--=================================================================================================
-- Process batches
---------------------------------------------------------------------------------------------------
SELECT	@BatchId = MIN(ID)
		FROM	#tBatches
WHILE	@BatchId <=	(SELECT	MAX(ID)
							FROM	#tBatches)
BEGIN
	SELECT	@BatchName = BatchName,
			@BatchInstance = BatchInstance,
			@RecipeDelimiterCount = RecipeDelimiterCount
			FROM	#tBatches
			WHERE	ID = @BatchId
	-----------------------------------------------------------------------------------------------
	-- Validate recipe string delimiter count.
	-- If less than three then Batch History table does not have enough information to populate
	-- Unit Procedure, Operation, and Phase fields.
	-----------------------------------------------------------------------------------------------
	IF	@RecipeDelimiterCount < 3
	BEGIN
		-------------------------------------------------------------------------------------------
		-- Put invalid recipe records 10 years in the future.
		-- This will result in no records being retrieved in the section immediately following.
		-------------------------------------------------------------------------------------------
		SELECT	@SQL = 'UPDATE ' + @TableName
					 + ' SET LCLTime = CONVERT(VARCHAR(25), DATEADD(YEAR, 10, LCLTime), 120)'
					 + ' WHERE UniqueId = ' + CONVERT(VARCHAR(25),@BatchInstance)
					 + ' AND LCLTime < DATEADD(DAY, 3, GETDATE())'
		EXEC	(@SQL)
	END


	/*

	**************************************************************************************************************
	Code for Finch Systems start here
	**************************************************************************************************************

	*/




		SET @lotid = 'LOT_ID_%'
	SET @Netweight = 'NET_WEIGHT_%'

	SELECT @SQL = '(Select distinct Recipe,BatchID From ' + @tablename+ 
    ' where Batchid = '+''''+@BatchName+''''  +'AND '+'Descript  like ' +''''+@lotid+''''+ ' or Descript like '+''''+@Netweight +'''' +')'

		INSERT @Recipe (Recipe,Batchid)
	EXEC (@Sql)




	IF EXISTS ( SELECT Batchid FROM @Recipe )

BEGIN

		 SELECT @Sql = '(SELECT DISTINCT LCLTIME,BatchID,Recipe FROM ' + @TAblename +' WHERE Batchid = '+''''+@BatchName+''''  + ')'
 INSERT @Lcltimetable(Lcltime,Batchid,Recipe)
 EXEC ( @Sql)





 SET @Max = (SELECT COUNT(*) From @Lcltimetable)
 SET @Min = 1

 WHILE ( @Min <= @MAX)
BEGIN                                                          

SET @Time1 =  (SELECT LCLTime FROM @Lcltimetable WHERE ID = @min)
SET @Time2 =  (Select LCLTIme FROM @Lcltimetable WHERE ID = @Min + 1)



IF (DATEDIFF(ss,@time1,@time2) > 30 )
BEGIN
INSERT #TimeDifference ( Batchid,StartTime, EndTime, TimeDifferenceinSec )
(SELECT  @Batchname,@Time1,@Time2,DATEDIFF(ss,@time1,@time2))
END

SET @Min = @Min + 1
END


SET @Max = (SELECT COUNT(*) FROM @Recipe) + 1
 SET @Min = 2


 WHILE (@MIN <= @MAX)
 BEGIN


Declare @CharIndex int

IF ( (SELECT COUNT(*) FROM @Recipe) = 1)
BEGIN
SET @recipe1 = ( SELECT Recipe FROM @Recipe)
END
ELSE
BEGIN
SET @recipe1 = ( SELECT Recipe FROM @Recipe WHERE ID = @Min)
END

SET @recipe3 = Reverse(@recipe1)
SET @charindex = Charindex('\',@recipe3)
SET @recipe3 = Substring(@recipe3,0,@charindex)
SET @recipe3 = Reverse(@recipe3)



SET @maxPhaselimit =10	
SET @minPhaselimit = 1	

SET @currentrecipeinstance = (Select RIGHT(@recipe3,1))
While ( @minPhaselimit <= @maxPhaselimit)
BEGIN



SET @recipe2 = Replace (@recipe3, '-'+CONVERT(Varchar,@currentrecipeinstance),'-'+CONVERT(Varchar,(@minPhaselimit + 1 )))

IF  EXISTS ( Select * FROM @Lcltimetable WHERE Recipe like '%'+@recipe2+'%')
BEGIN
SET @minPhaselimit = @minPhaselimit + 1
END
ELSE
BEGIN
Goto IncreasePhaseInstance
END





END

IncreasePhaseInstance:


SELECT	@SQL ='SELECT Dateadd(SS,2,td.StartTime),UniqueID
      ,q.BatchID
      ,'+''''+Replace(@recipe1,@recipe3,@recipe2)+''''+'
      ,[Descript]
      ,[Event]
      ,[PValue]
      ,[EU]
      ,[Area]
      ,[ProcCell]
      ,[Unit]
      ,[Phase]
      ,[UserID]
      ,[PhaseDesc]
      ,[MaterialName]
      ,[MaterialID]
      ,[LotName]
      ,[Label]
      ,[Container]
      ,[PromiseID]
     FROM '+ @TableName +
	  ' Q 
	  JOIN #TimeDifference TD ON TD.Batchid = Q.BatchID
	  WHERE q.Recipe like'+ ''''+'%'+@recipe3+'%'+''''
	  +' AND TD.id = '+ CONVERT(Varchar,(@Min)) +
	  'ORDER BY Recordno '



	  Insert  #Temp (
      [lclTime]
      ,[UniqueID]
      ,[BatchID]
      ,[Recipe]
      ,[Descript]
      ,[Event]
      ,[PValue]
      ,[EU]
      ,[Area]
      ,[ProcCell]
      ,[Unit]
      ,[Phase]
      ,[UserID]
      ,[PhaseDesc]
      ,[MaterialName]
      ,[MaterialID]
      ,[LotName]
      ,[Label]
      ,[Container]
      ,[PromiseID]
      
)

EXEC ( @sql)




	 DELETE FROM #Temp 
	 WHERE Descript like 'LOT_ID' 
	 or Descript like 'Net_Weight'




	  Update #Temp 
	  SET DEscript = 'LOT_ID'
	  WHERE Descript like 'LOT_ID_'+Convert(Varchar,@min)

	   Update #Temp 
	   SET DEscript = 'Net_Weight'
	   WHERE Descript like 'Net_Weight_'++Convert(Varchar,@min)



	   	 SET @RunningRecordno = (SELECT RecordNo FROM #Temp 
							WHERE Descript like '%State%Change%' and Pvalue like '%DOWNLOADING%')



	  Update #Temp 
	  SET lclTime = Dateadd(ss,5,lcltime)
	  WHERE  RecordNo >= @RunningRecordno


	




  SET @Min = @Min + 1
END



 SELECT @Sql= '(SELECT LCLTime, Area, ProcCell, Unit, BatchID, UniqueID, 
						Recipe, Phase, Descript, EU, PValue, MaterialName, LotName, Container, Event, UserID, Signature, Recipe FROM   #temp '
						+ ' WHERE BatchId = ''' + @BatchName + ''' '
						+ ' AND LCLTime <= DATEADD(DAY, 3, GETDATE())) '
INSERT	#tEventTransactions (	EventTimeStamp, AreaName, CellName, UnitName, BatchName, BatchInstance,
									UnitProcedureName,
									PhaseName, ParameterName, ParameterAttributeUOM, ParameterAttributeValue,
									RawMaterialProductCode, RawMaterialBatchName, RawMaterialContainerId,
									EventName, UserName, UserSignature, RecipeString)

EXEC ( @SQL)
	


END

UPDATE #tEventTransactions
SET UnitProcedureName = 
(CASE    WHEN CHARINDEX('\', UnitProcedureName, 1) = 0     THEN NULL    ELSE SUBSTRING(UnitProcedureName, CHARINDEX('\', UnitProcedureName, 1) + 1, 1000)    END)
FROM #tEventTransactions




	/*

**************************************************************************************************************
		Code for Finch Systems ends here
**************************************************************************************************************
	*/



		-----------------------------------------------------------------------------------------------
	-- Get the transactions for the selected batch
	-----------------------------------------------------------------------------------------------
	SELECT	@SQL =	'SELECT LCLTime, Area, ProcCell, Unit, BatchID, UniqueID, '
						+ ' (CASE '
						+ '   WHEN CHARINDEX(''\'', Recipe, 1) = 0 '
						+ '    THEN NULL '
						+ '   ELSE SUBSTRING(Recipe, CHARINDEX(''\'', Recipe, 1) + 1, 1000) '
						+ '   END), '
						+ ' Phase, Descript, EU, PValue, '
						+ ' MaterialName, LotName, Container, '
						+ ' Event, UserID, Signature, Recipe, RecordNo '
						+ ' FROM ' + @TableName
						+ ' WHERE BatchId = ''' + @BatchName + ''' '
						+ ' AND LCLTime <= DATEADD(DAY, 3, GETDATE()) '
	IF	@BatchInstance IS NULL
	BEGIN
		SELECT	@SQL = @SQL + ' AND	UniqueId IS NULL '
	END
	ELSE
	BEGIN
		SELECT	@SQL = @SQL + ' AND	UniqueId = ' + CONVERT(VARCHAR(25), @BatchInstance) + ' '
	END
	SELECT	@SQL = @SQL	+ ' ORDER BY LCLTime, RecordNo'



	INSERT	#tEventTransactions (	EventTimeStamp, AreaName, CellName, UnitName, BatchName, BatchInstance,
									UnitProcedureName,
									PhaseName, ParameterName, ParameterAttributeUOM, ParameterAttributeValue,
									RawMaterialProductCode, RawMaterialBatchName, RawMaterialContainerId,
									EventName, UserName, UserSignature, RecipeString, RecordNumber)
		EXEC	(@SQL)

	

	--------------------------------------------------------------------------------------------------
	-- Parse Recipe Strings To Expose UP, OP, Phase Instance
	--------------------------------------------------------------------------------------------------
	UPDATE	#tEventTransactions
		SET	UnitProcedureName =	CASE
									WHEN	CHARINDEX(':', UnitProcedureName, 1) = 0
										THEN	UnitProcedureName
									ELSE	SUBSTRING(UnitProcedureName, 1, LEN(UnitProcedureName) - 4)
												+ REPLACE(SUBSTRING(UnitProcedureName, LEN(UnitProcedureName) - 3, 1000), '-', '00')
									END
	UPDATE	#tEventTransactions
		SET	UnitProcedureName =	CASE	
									WHEN	CHARINDEX(':', UnitProcedureName, 1) = 0
										THEN 	UnitProcedureName 
									ELSE	SUBSTRING(UnitProcedureName, 1, CHARINDEX(':', UnitProcedureName, 1) - 1) 
									END,
			UnitProcedureInstance =	CASE
										WHEN	CHARINDEX(':', UnitProcedureName, 1) = 0
											THEN	NULL
										ELSE	CASE
													WHEN	CHARINDEX('\', UnitProcedureName, 1) = 0
														THEN	CONVERT(INT, SUBSTRING(	UnitProcedureName,
																						CHARINDEX(':', UnitProcedureName, 1) + 1,
																						1000)) / 1000
													ELSE	CONVERT(INT, SUBSTRING(	UnitProcedureName,
																					CHARINDEX(':', UnitProcedureName, 1) + 1,
																					CHARINDEX('\', UnitProcedureName, 1)
																						- CHARINDEX(':', UnitProcedureName, 1) - 1))
													END
										END,
			OperationName =	CASE
								WHEN	CHARINDEX('\', UnitProcedureName, 1) = 0
									THEN	NULL
								ELSE	SUBSTRING(UnitProcedureName, CHARINDEX('\', UnitProcedureName, 1) + 1, 1000)
								END
	UPDATE	#tEventTransactions
		SET	OperationName =	CASE
								WHEN CHARINDEX(':', OperationName, 1) = 0
									THEN	OperationName 
								ELSE	SUBSTRING(OperationName, 1, CHARINDEX(':', OperationName, 1) - 1) 
								END,
			OperationInstance =	CASE
									WHEN	CHARINDEX(':', OperationName, 1) = 0
										THEN	NULL  
									ELSE	CASE
												WHEN	CHARINDEX('\', OperationName, 1) = 0
													THEN	CONVERT(INT, SUBSTRING(	OperationName,
																					CHARINDEX(':', OperationName, 1) + 1,
																					1000)) / 1000
												ELSE	CONVERT(INT, SUBSTRING(	OperationName,
																				CHARINDEX(':', OperationName, 1) + 1,
																				CHARINDEX('\', OperationName, 1)
																					- CHARINDEX(':', OperationName, 1) - 1))
												END
									END,
			PhaseName =	CASE 
							WHEN	CHARINDEX('\', OperationName, 1) = 0
								THEN	NULL
							ELSE	SUBSTRING(OperationName, CHARINDEX('\', OperationName, 1) + 1, 1000)
							END
	UPDATE	#tEventTransactions
		SET	PhaseName =	CASE
							WHEN	CHARINDEX(':', PhaseName, 1) = 0
								THEN	PhaseName 
							ELSE	SUBSTRING(PhaseName, 1, CHARINDEX(':', PhaseName, 1) - 1) 
							END,
			PhaseInstance =	CASE 
								WHEN CHARINDEX(':', PhaseName, 1) = 0
									THEN	CASE
												WHEN	PhaseName IS NOT NULL
													THEN	1
												ELSE	NULL
												END 
								ELSE	CONVERT(INT, SUBSTRING(PhaseName, CHARINDEX(':', PhaseName, 1) + 1, 1000))
								END
	--------------------------------------------------------------------------------------------------
	-- Chop off Front and Back from UP names so we can get under the 25 character limitation on Event_Num
	--------------------------------------------------------------------------------------------------
	-- TODO: Find a way to expose this logic through parameters.  This may be specific to Iowa City.
	--------------------------------------------------------------------------------------------------
	UPDATE	#tEventTransactions
		SET		UnitProcedureName = SUBSTRING(UnitProcedureName, 6, CHARINDEX('_', SUBSTRING(UnitProcedureName, 6, 100)) - 1)
		WHERE	UnitProcedureName IS NOT NULL
		AND		CHARINDEX('_', UnitProcedureName) <> 0
	--------------------------------------------------------------------------------------------------
	-- Move Batch Header Information To "First" Unit
	--------------------------------------------------------------------------------------------------
	DELETE	FROM	@tUnits
	INSERT	@tUnits (AreaName)
		SELECT DISTINCT AreaName
			FROM	#tEventTransactions
			WHERE	UnitName IS NULL
			OR		UnitName = ''
	SELECT	@UnitId = MIN(ID)
			FROM	@tUnits
	WHILE	@UnitId <=	(SELECT	MAX(ID)
								FROM	@tUnits)
	BEGIN
		SELECT	@AreaName = AreaName
				FROM	@tUnits
				WHERE	ID = @UnitId
		SELECT	@MinTimeStamp = NULL
		SELECT	@MinTimeStamp = MIN(EventTimeStamp)
				FROM	#tEventTransactions
				WHERE	AreaName = @AreaName
				AND		UnitName IS NOT NULL
				AND		UnitName <> ''
				AND		CellName IS NOT NULL
				AND		CellName <> '' 
		IF	@MinTimeStamp IS NOT NULL
		BEGIN
			SELECT	@UnitName = NULL,
					@Cellname = NULL
			SELECT	@CellName = CellName, 
					@UnitName = UnitName
					FROM	#tEventTransactions
					WHERE	EventTimeStamp = @MinTimeStamp
					AND		AreaName = @AreaName
					AND		UnitName IS NOT NULL
					AND		UnitName <> ''
					AND		CellName IS NOT NULL
					AND		CellName <> '' 
			IF	@UnitName IS NOT NULL
				AND	@CellName IS NOT NULL
			BEGIN
				UPDATE	#tEventTransactions
						SET	UnitName = @UnitName,
							CellName = @CellName,
							EventTimeStamp = DATEADD(SECOND, -1, @MinTimeStamp)
						WHERE	AreaName = @AreaName
						AND		(UnitName IS NULL
								OR	UnitName = '')
						AND		(CellName IS NULL
								OR	CellName = '')
						AND		EventTimeStamp <= @MinTimeStamp
				UPDATE	#tEventTransactions
						SET	UnitName = @UnitName,
							CellName = @CellName
						WHERE	AreaName = @AreaName
						AND		(UnitName IS NULL
								OR	UnitName = '')
						AND		(CellName IS NULL
								OR	CellName = '')
						AND		Eventtimestamp > @MinTimeStamp
			END
		END
		IF	@UnitId =	(SELECT	MAX(ID)
								FROM	@tUnits)
		BEGIN
			SELECT	@UnitId = @UnitId + 1
		END
		ELSE
		BEGIN
			SELECT	@UnitId = MIN(ID)
					FROM	@tUnits
					WHERE	ID > @UnitId
		END
	END
	--------------------------------------------------------------------------------------------------
	-- Convert "Product" Batch Header Parameter Into Procedure Report
	--------------------------------------------------------------------------------------------------
	UPDATE	#tEventTransactions
			SET	EventName = NULL,
				EventType = 'ProcedureReport',
				BatchProductCode = ParameterAttributeValue,
				StateValue = 'SETUP', 
				ParameterName = NULL,
				ParameterAttributeName = NULL,
				ParameterAttributeUOM = NULL,
				ParameterAttributeValue = NULL
			WHERE	EventName = 'Recipe Header'
			AND		(ParameterName = @ProductCodeParameter
					OR	ParameterName = 'Product Code')
	--------------------------------------------------------------------------------------------------
	-- Convert Batch Header Parameter Into Procedure Report (first batch header)
	--------------------------------------------------------------------------------------------------
	-- TODO: Need to support "null" statevalue to just advance batch end time, no status change, update product code
	-- TODO: What About Product Code On Each Unit Besides The Start Unit?
	--------------------------------------------------------------------------------------------------
	UPDATE	#tEventTransactions
			SET	EventName = NULL,
				EventType = 'ProcedureReport',
				StateValue = 'SETUP', 
				ParameterName = NULL,
				ParameterAttributeName = NULL,
				ParameterAttributeUOM = NULL,
				ParameterAttributeValue = NULL
			WHERE	EventName IN ('Event File Name')
	--------------------------------------------------------------------------------------------------
	-- Prepare Procedure Reports
	--------------------------------------------------------------------------------------------------
	-- Supported Events
	--   State Change
	--   State Command
	--------------------------------------------------------------------------------------------------
	UPDATE	#tEventTransactions
			SET	EventName = NULL,
				EventType = 'ProcedureReport',
				StateValue = ParameterAttributeValue,
				ParameterName = NULL,
				ParameterAttributeName = NULL,
				ParameterAttributeUOM = NULL,
				ParameterAttributeValue = NULL
			WHERE	EventName IN ('State Change', 'State Command')
	--------------------------------------------------------------------------------------------------
	-- Prepare Recipe Setups
	--------------------------------------------------------------------------------------------------
	-- Supported Events
	--   Recipe Value Change
	--   Recipe Value
	--------------------------------------------------------------------------------------------------
	IF	@IsRecipeValueParameterReport = 0 
	BEGIN
		UPDATE	#tEventTransactions
				SET	EventName = NULL,
					EventType = 'RecipeSetup',
					ParameterAttributeName = 'Target',
					RawMaterialProductCode = NULL,
					RawMaterialBatchName = NULL,
					RawMaterialContainerId = NULL
				WHERE	EventName IN ('Recipe Value','Recipe Value Change')
	END
	--------------------------------------------------------------------------------------------------
	-- Prepare Parameter Reports
	--------------------------------------------------------------------------------------------------
	-- Supported Events
	--    Recipe Header
	--    Report
	--    Scale Factor
	--    Param Download Verified
	--------------------------------------------------------------------------------------------------
	IF	@IsRecipeValueParameterReport = 1 
	BEGIN
		UPDATE	#tEventTransactions
				SET	EventName = NULL,
					EventType = 'ParameterReport',
					ParameterAttributeName = 'Value',
					RawMaterialProductCode = NULL,
					RawMaterialBatchName = NULL,
					RawMaterialContainerId = NULL
				WHERE	EventName IN ('Recipe Value', 'Recipe Value Change')
		UPDATE	#tEventTransactions
				SET	EventName = NULL,
					EventType = 'ParameterReport',
					ParameterAttributeName = 'Value',
					RawMaterialProductCode = NULL,
					RawMaterialBatchName = NULL,
					RawMaterialContainerId = NULL
				WHERE	EventName IN ('Recipe Header', 'Report', 'Scale Factor', 'Param Download Verified')
	END
	--------------------------------------------------------------------------------------------------
	-- Process Material Movements
	--------------------------------------------------------------------------------------------------
	INSERT	#tEventTransactions (	EventTimeStamp, EventType, AreaName, CellName, UnitName, BatchName,
									BatchInstance, BatchProductCode, UnitProcedureName, UnitProcedureInstance,
									OperationName, OperationInstance, PhaseName, PhaseInstance,
									ProcedureStartTime, ProcedureEndTime, RawMaterialProductCode,
									RawMaterialBatchName, RawMaterialContainerId, UserName, UserSignature,
									RecipeString, RecordNumber)
		SELECT	EventTimeStamp, 'MaterialMovement', AreaName, CellName, UnitName, BatchName,
				BatchInstance, BatchProductCode, UnitProcedureName, UnitProcedureInstance,
				OperationName, OperationInstance, PhaseName, PhaseInstance,
				ProcedureStartTime, ProcedureEndTime, RawMaterialProductCode,
				RawMaterialBatchName, RawMaterialContainerId, UserName, UserSignature,
				RecipeString, RecordNumber
				FROM	#tEventTransactions
				WHERE	EventType = 'ProcedureReport'
				AND		RawMaterialBatchName IS NOT NULL
				AND		RawMaterialBatchName <> ''
	UPDATE	#tEventTransactions
			SET	RawMaterialBatchName = NULL,
				RawMaterialContainerId = NULL
			WHERE	EventType = 'ProcedureReport'
			AND		RawMaterialBatchName IS NOT NULL
			AND		RawMaterialBatchName <> ''
	--------------------------------------------------------------------------------------------------
	-- Process "Other" Events
	--------------------------------------------------------------------------------------------------
	-- Supported Events
	--    Unit Verified
	--    System Message
	--    Owner Change
	--    Creation Bind
	--    Arbitration
	--    Attribute Change
	--    Batch Deletion
	--------------------------------------------------------------------------------------------------
	-- TODO: Create User Defined Events
	--------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------
	-- Move all records to new time to protect against reprocessing

	--------------------------------------------------------------------------------------------------
	SELECT	@SQL =	'UPDATE bh '
					+ ' SET LCLTime = DATEADD(YEAR, 10, bh.LCLTime) '
					+ ' FROM ' + @TableName + ' bh '
					+ ' JOIN #tEventTransactions tet ON bh.' + @IdFieldName + ' = tet.RecordNumber '

	EXEC	(@SQL)
	--------------------------------------------------------------------------------------------------
	-- Purge Unsupported Events
	--------------------------------------------------------------------------------------------------
	DELETE	FROM	#tEventTransactions 
			WHERE	Eventtype IS NULL
			OR		UnitName IS NULL
			OR		UnitName = ''
	--------------------------------------------------------------------------------------------------
	-- Populate ProcedureStartTime and ProcedureEndTime with the Min and Max for each ProcedureReport
	-- event (Batch, UP, OP, PH).  By having all records for the same event with the same starttime and
	-- endtime, it should make the spServers called by the 49000 SP run faster, since they will not have
	-- to keep moving test results to match updated timestamps.
	--------------------------------------------------------------------------------------------------
	DELETE	FROM @tDates
	INSERT	@tDates (	UnitProcedureName, UnitProcedureInstance, OperationName, OperationInstance,
						PhaseName, PhaseInstance)
		SELECT	DISTINCT	UnitProcedureName, UnitProcedureInstance, OperationName, OperationInstance,
							PhaseName, PhaseInstance
					FROM	#tEventTransactions 
					WHERE	EventType = 'ProcedureReport'
	SELECT	@DateId = MIN(ID)
			FROM	@tDates
	WHILE	@DateId <=	(SELECT	MAX(ID)
							FROM	@tDates)
	BEGIN
		SELECT	@UnitProcedureName = UnitProcedureName,
				@UnitProcedureInstance = UnitProcedureInstance,
				@OperationName = OperationName,
				@OperationInstance = OperationInstance,
				@PhaseName = PhaseName,
				@PhaseInstance = PhaseInstance
				FROM	@tDates
				WHERE	ID = @DateId
		SELECT	@MinTimeStamp = MIN(EventTimeStamp),
				@MaxTimeStamp = MAX(EventTimeStamp)
				FROM	#tEventTransactions
				WHERE	(UnitProcedureName = @UnitProcedureName
						OR	(UnitProcedureName IS NULL
							AND	@UnitProcedureName IS NULL))
				AND		(UnitProcedureInstance = @UnitProcedureInstance
						OR	(UnitProcedureInstance IS NULL
							AND	@UnitProcedureInstance IS NULL))
				AND		(OperationName = @OperationName
						OR	(OperationName IS NULL
							AND	@OperationName IS NULL))
				AND		(OperationInstance = @OperationInstance
						OR	(OperationInstance IS NULL
							AND	@OperationInstance IS NULL))
				AND		(PhaseName = @PhaseName
						OR	(PhaseName IS NULL
							AND	@PhaseName IS NULL))
				AND		(PhaseInstance = @PhaseInstance
						OR	(PhaseInstance IS NULL
							AND	@PhaseInstance IS NULL))
				AND		EventType = 'ProcedureReport'
		UPDATE	#tEventTransactions
				SET	ProcedureStartTime = @MinTimeStamp,
					ProcedureEndTime = @MaxTimeStamp
				WHERE	(UnitProcedureName = @UnitProcedureName
						OR	(UnitProcedureName IS NULL
							AND	@UnitProcedureName IS NULL))
				AND		(UnitProcedureInstance = @UnitProcedureInstance
						OR	(UnitProcedureInstance IS NULL
							AND	@UnitProcedureInstance IS NULL))
				AND		(OperationName = @OperationName
						OR	(OperationName IS NULL
							AND	@OperationName IS NULL))
				AND		(OperationInstance = @OperationInstance
						OR	(OperationInstance IS NULL
							AND	@OperationInstance IS NULL))
				AND		(PhaseName = @PhaseName
						OR	(PhaseName IS NULL
							AND	@PhaseName IS NULL))
				AND		(PhaseInstance = @PhaseInstance
						OR	(PhaseInstance IS NULL
							AND	@PhaseInstance IS NULL))
				AND		EventType = 'ProcedureReport'
		IF	@DateId =	(SELECT	MAX(ID)
								FROM	@tDates)
		BEGIN
			SELECT	@DateId = @DateId + 1
		END
		ELSE
		BEGIN
			SELECT	@DateId = MIN(ID)
					FROM	@tDates
					WHERE	ID > @DateId
		END
	END


	--------------------------------------------------------------------------------------------------
	-- Move Temporary Transactions To Event_Transactions
	--------------------------------------------------------------------------------------------------
	INSERT	Event_Transactions (EventTimeStamp, EventType, AreaName, CellName, UnitName, BatchName,
								BatchInstance, BatchProductCode, UnitProcedureName, UnitProcedureInstance,
								OperationName, OperationInstance, PhaseName, PhaseInstance, ProcedureStartTime,
								ProcedureEndTime, ParameterName, ParameterAttributeName, ParameterAttributeUOM,
								ParameterAttributeValue, RawMaterialAreaName, RawMaterialCellName, RawMaterialUnitName,
								RawMaterialProductCode, RawMaterialBatchName, RawMaterialContainerId,
								RawMaterialDimensionA, RawMaterialDimensionX, RawMaterialDimensionY,
								RawMaterialDimensionZ, StateValue, EventName, UserName, UserSignature,
								RecipeString, ProcessedFlag, OrphanedFlag)
		SELECT	EventTimeStamp, EventType, AreaName, CellName, UnitName, BatchName,
				BatchInstance, BatchProductCode, UnitProcedureName, UnitProcedureInstance,
				OperationName, OperationInstance, PhaseName, PhaseInstance, ProcedureStartTime,
				ProcedureEndTime, ParameterName, ParameterAttributeName, CONVERT(VARCHAR(15), ParameterAttributeUOM),
				CONVERT(VARCHAR(25), ParameterAttributeValue), RawMaterialAreaName, RawMaterialCellName, RawMaterialUnitName,
				RawMaterialProductCode, RawMaterialBatchName, RawMaterialContainerId,
				RawMaterialDimensionA, RawMaterialDimensionX, RawMaterialDimensionY,
				RawMaterialDimensionZ, StateValue, EventName, UserName, UserSignature,
				RecipeString, 0, 0
			FROM	#tEventTransactions
			WHERE	RecipeString NOT LIKE '%$NULL%' -- AJ:03-Oct-2005 - temporary solution when filtering on spS88_RSBatch6Reader
			ORDER BY EventTimeStamp, RecordNumber
	IF	@BatchId =	(SELECT	MAX(ID)
							FROM	#tBatches)
	BEGIN
		SELECT	@BatchId = @BatchId + 1
	END
	ELSE
	BEGIN
		SELECT	@BatchId = MIN(ID)
				FROM	#tBatches
				WHERE	ID > @BatchId
	END
END
--=================================================================================================
-- Purge old records from BatchHis table.
--------------------------------------------------------------------------------------------------
IF	@PurgeDaysToKeep > 0
	AND	@PurgeDaysToKeep < 365
BEGIN
	SELECT	@PurgeEndTime = DATEADD(DAY, -@PurgeDaysToKeep, DATEADD(YEAR, 10, GETDATE())),
			@PurgeStartTime = DATEADD(YEAR, 9, GETDATE())
	SELECT	@SQL =	'DELETE FROM ' + @TableName + ' '
					+ ' WHERE LCLTime BETWEEN ''' + @PurgeStartTime + ''' AND ''' + @PurgeEndTime + ''''
	EXEC	(@SQL)
END
--=================================================================================================
-- Finish
---------------------------------------------------------------------------------------------------


DROP	TABLE	#tEventTransactions
DROP	TABLE	#tBatches
DROP    TABLE   #Temp
DROP	TABLE	#TimeDifference











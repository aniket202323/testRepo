
 
  
CREATE  PROCEDURE [dbo].[spActivities_GetActivities] @TransactionId    TINYINT      = 0, -- 0-All the activities, 1-Single Activity
--CREATE OR ALTER PROCEDURE [dbo].[spActivities_GetActivities] @TransactionId    TINYINT      = 0, -- 0-All the activities, 1-Single Activity
                                                @StatusList       nvarchar(20), -- Activity status values seperated by a comma
                                                @ActivityId       NVARCHAR(MAX)       = NULL, -- For Single Activity
                                                @ProductList      nVARCHAR(MAX) = NULL, -- Optional Filter List of Products
                                                @EquipmentList    nVARCHAR(MAX) = NULL, -- Optional Filter List of Equipments
                                                @ProcessOrderList nVARCHAR(MAX) = NULL, -- Optional Filter List of Process Orders
                                                @EventTypeList    nvarchar(20)  = NULL, -- Optional Filter List of Event Types
                                                @CompleteType     nvarchar(20)  = NULL, -- Optional Filter List of Complete activity types
                                                @IsOverdue        TINYINT      = NULL, -- Optional is overdue indicator
                                                @DisplayType      TINYINT      = NULL, -- Optional Filter for Display Type
                                                @VariableName     nVARCHAR(100) = NULL, -- Optional Variable Description
                                                @ProcessOrderName nvarchar(200) = NULL, -- Optional Process Order name
                                                @ProductCode      nvarchar(200) = NULL, -- Optional Product Code
                                                @Event            nvarchar(200) = NULL, -- Optional Prodution Event / User Defined Event
                                                @Batch            nvarchar(200) = NULL, -- Optional Batch Prodution Event
                                                @TimeSelection    INT          = NULL, -- Optional Time Selection to fetch start and end times basing on time selection
                                                @StartTime        DATETIME     = NULL, -- Minimum start time of the activity
                                                @EndTime          DATETIME     = NULL, -- Maximum end time of the activity
                                                @TimeZone         nvarchar(200) = NULL, -- Ex: 'India Standard Time','Central Stardard Time'
                                                @SortColumn       nvarchar(20)  = 'DueIn', -- Optional sort column
                                                @SortOrder        nVARCHAR(5)   = 'ASC', -- Optional sort order
						                        @OperationNames	  nVARCHAR(MAX) = NULL, -- Optional Filter List of Operation Name
						                        @LotIdentifiers	  nVARCHAR(MAX) = NULL, -- Optional Filter List of LotIdentifier Name
                                                @PageNumber       INT          = NULL, -- Current page number
                                                @PageSize         INT          = NULL, -- Total records per page to display
                                                @ActivityCount    INT          = 0 OUTPUT, -- Returns Total activities remaining to start
                                                @OverdueCount     INT          = 0 OUTPUT, -- Returns Total overdue activities remaining to start
                                                @PageCount        INT          = 0 OUTPUT, -- Returns the total page count
                                                @CurrentPage      INT          = 0 OUTPUT, -- Returns the current page number (useful if the activity number is filled)
                                                @StartTimeOutput  DATETIME     = NULL OUTPUT, -- Returns the start time for the selected time range
                                                @EndTimeOutput    DATETIME     = NULL OUTPUT -- Returns the end time for the selected time range


AS
BEGIN
	SELECT @Event = case when @Event ='' AND @Event IS NOT NULL  THEN NULL ELSE @Event END
	SELECT @VariableName = case when @VariableName ='' AND @VariableName IS NOT NULL  THEN NULL ELSE @VariableName END
	SELECT @Batch = case when @Batch ='' AND @Batch IS NOT NULL  THEN NULL ELSE @Batch END
	SELECT @ProcessOrderName = case when @ProcessOrderName ='' AND @ProcessOrderName IS NOT NULL  THEN NULL ELSE @ProcessOrderName END
	
	SET @ProcessOrderName =NULL
	DEclare @DiscreteSearchFor1UDE INT
	DECLARE @SubSql NVARCHAR(MAX)
	DECLARE @VariableSQL nvARCHAR(MAX)
			CREATE TABLE #DiscreteEventIds (Extended_Info nvarchar(255),KeyId int, Event_Id int, UDE_Id int, Lot_Identifier nvarchar(200),Operation_Name nvarchar(200),PP_Id int, Process_Order nVarchar(100))
	SET @VariableSQL =''
	Declare @VariableNamewithNoRecord BIT
	SET @VariableNamewithNoRecord = 0
	

	Declare @productId nvarchar(max)
	IF @ProductCode <> '' AND @ProductCode IS NOT NULL
	Begin
	   	 Select @productId = coalesce(@productId+',','')+cast(prod_Id as varchar) from Products_base where Prod_code LIKE '%'+REPLACE(REPLACE(REPLACE(REPLACE(@ProductCode, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')+'%'
	End
	SET @SubSql =''
	SET @DiscreteSearchFor1UDE = 0
	IF @ActivityId IS NULL AND PATINDEX('%DISC:%',@Event) > 0 
	BEGIN
		 
		SELECT @ActivityId = cast(Activity_Id as nvarchar) from Activities  Where KeyId1 =(SELECT UDE_ID FROM User_Defined_Events  where UDE_DESC = @Event)
		IF @ActivityId IS NOT NULL
		SElecT @TransactionId = 1,@DiscreteSearchFor1UDE=1
		
		SET @ActivityId = NULL
	END

	CREATE TABLE #Equipments(PuId int)
	CREATE CLUSTERED INDEX  IX_TMPEquipments ON #Equipments(PuId)
	IF (@EquipmentList IS NOT NULL)
	BEGIN
		INSERT INTO #Equipments
		SELECT col1 FROM dbo.fn_SplitString(@EquipmentList,',') 
	END

	CREATE TABLE #Activities(ActivityId int )
	CREATE CLUSTERED INDEX  IX_TMPActivities ON #Activities(ActivityId)
	Declare @IsSingleActivity BIT
	SET @IsSingleActivity =0
	IF @ActivityId IS NOT NULL 
	BEGIN
		INSERT INTO #Activities
		Select col1 from dbo.fn_SplitString(@ActivityId,',') 
	 
		IF (@StatusList LIKE '%1%' OR @StatusList LIKE '%2%')
		BEGIN
			DELETE A from #Activities A where not exists (select 1 from Activities where Activity_Id = A.ActivityId and Activity_Status in (1,2))
		END
		IF (@StatusList LIKE '%3%' OR @StatusList LIKE '%4%')
		BEGIN
			DELETE A from #Activities A where not exists (select 1 from Activities where Activity_Id = A.ActivityId and Activity_Status in (3,4))
		END
		IF(@EquipmentList IS NOT NULL)
		BEGIN
			DELETE A from #Activities A where not exists (select 1 from Activities A1 JOIN #Equipments E ON A1.PU_Id = E.PUId where Activity_Id = A.ActivityId)
		END
		
		SELECT @IsSingleActivity =1
		
	END
    ---------------------------------------------Set default values-----------------------------------------------
    IF @TransactionId IS NULL
        BEGIN
            SET @TransactionId = 0
        END
    IF @SortColumn IS NULL
        BEGIN
            SET @SortColumn = 'DueIn'
        END
    IF @SortOrder IS NULL
        BEGIN
            SET @SortOrder = 'ASC'
        END
    DECLARE @Now DATETIME= (SELECT dbo.fnServer_CmnGetDate(GETUTCDATE()))

	
	Declare @DiscreteEventSQL nvarchar(max),@DiscreteEventIds nvarchar(max)
	SET @DiscreteEventSQL = ''
	
	SET @DiscreteEventSQL+=
	'
		;WITH S AS 
		(
			Select 
				EC.Source_Event_Id,EC.Event_Id ,ED.PP_Id,E.Extended_Info,NULL Operation_Name,E.Lot_Identifier 
			from 
				Event_Components EC 
				Join Events E  on E.Event_Id = EC.Source_Event_Id
				JOIN Event_Details ED  on Ed.Event_Id = E.Event_Id
			Where
				1=1 
				'
			IF @LotIdentifiers IS NOT NULL AND @LotIdentifiers <> ''
				SET @DiscreteEventSQL+=	' AND E.Lot_Identifier IN (N'''+Replace(@LotIdentifiers,',',''',''')+''') '
			IF @ProcessOrderList IS NOT NULL AND @ProcessOrderList <>''
				SET @DiscreteEventSQL+=	' AND Ed.Pp_Id IN  ('+@ProcessOrderList+')'
	SET @DiscreteEventSQL+='	)
		,S2 as 
		(
			Select 
				E.Event_Id Keyid,E.Event_Id,E.Extended_Info,E.Operation_Name,E.Lot_Identifier , NULL Pp_id
			from 
				Events E  
			Where 
				1=1'
				IF @OperationNames IS NOT NULL AND @OperationNames <> ''
					SET @DiscreteEventSQL+=' AND Operation_Name In (N'''+Replace(@OperationNames,',',''',''')+''') '
				SET @DiscreteEventSQL+='ANd exists (Select 1 from S where Event_Id = E.Event_id)
			UNION
			SELECT Source_Event_Id, Event_Id,Extended_Info,Operation_Name,Lot_Identifier,PP_Id  from S
		)
		Select S2.KeyId,S2.Event_id,S2.Extended_Info,S2.Operation_Name,S2.Lot_Identifier, UDE.UDE_Id, S2.PP_Id from S2 JoiN User_Defined_Events UDE  on UDE.Event_Id = S2.Event_Id
	'
	IF @Event iS NOT NULL AND @Event <> '' AND @ActivityId IS NULL AND PATINDEX('%DISC:%',@Event) > 0 
	Begin
		SET @DiscreteEventSQL='Select UDE_ID  from User_Defined_Events Where UDE_DESC = N'''+@Event+''';' 
		INSERT INTO #DiscreteEventIds(UDE_Id)
		EXEC (@DiscreteEventSQL);
		SELECT  @DiscreteEventIds = COALESCE(@DiscreteEventIds+',','')+cast(UDE_ID as nvarchar) FROM (SELECT DISTINCT UDE_ID from #DiscreteEventIds) T
		IF @DiscreteEventIds IS NULL
			SET @VariableNamewithNoRecord = 1
	End
	IF @ActivityId IS NULL AND (@OperationNames IS NOT NULL  OR @ProcessOrderList IS NOT NULL OR @LotIdentifiers IS NOT NULL)
	Begin

	
		
		INSERT INTO #DiscreteEventIds(KeyId,Event_Id,Extended_Info,Operation_Name,Lot_Identifier,UDE_Id,PP_Id)
		EXEC (@DiscreteEventSQL);
		UPDATE 
		d set d.Process_Order = pp.Process_Order from 
		#DiscreteEventIds d Join Production_Plan pp  on  pp.PP_Id = d.pp_id
		
		SELECT  @DiscreteEventIds = COALESCE(@DiscreteEventIds+',','')+cast(UDE_ID as nvarchar) FROM (SELECT DISTINCT UDE_ID from #DiscreteEventIds) T
		IF @DiscreteEventIds IS NULL
			SET @VariableNamewithNoRecord = 1
		
	End
	
	
-------------------------------------------Get activities for variable---------------------------------------------
    IF @VariableName IS NOT NULL
        BEGIN
		CREATE TABLE #VariableIdList(Id          INT,
											 ColumnIndex INT,Sheet_Id int);
		IF @EquipmentList IS NOT NULL
		Begin

				SET @VariableName = REPLACE(REPLACE(REPLACE(REPLACE(@VariableName, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
				SET @VariableName = '%'+@VariableName+'%';

				SET @VariableSQL=
				'
				SELECT Var_Id,0 ColumnIndex FROM Variables_base  WHERE PU_ID IN ('+@EquipmentList+') AND Var_Desc LIKE '''+@VariableName+''' ESCAPE ''\''
				UNION
				SELECT Var_Id,1 ColumnIndex FROM Variables_base  WHERE PU_ID IN ('+@EquipmentList+') AND User_Defined1 LIKE '''+@VariableName+''' ESCAPE ''\''
				UNION
				SELECT Var_Id,2 ColumnIndex FROM Variables_base  WHERE PU_ID IN ('+@EquipmentList+') AND User_Defined2 LIKE '''+@VariableName+''' ESCAPE ''\''
				UNION
				SELECT Var_Id,3 ColumnIndex FROM Variables_base  WHERE PU_ID IN ('+@EquipmentList+') AND User_Defined3 LIKE '''+@VariableName+''' ESCAPE ''\''
				'
				INSERT INTO #VariableIdList(Id,ColumnIndex)
				EXEC(@VariableSQL)

				UPDATE vl
				SET vl.Sheet_Id = SV.Sheet_Id
				from #VariableIdList vl join Sheet_Variables SV  on SV.Var_Id = vl.Id
				LEFT OUTER JOIN Sheet_Display_Options SDO  on SDO.Sheet_ID = SV.Sheet_Id and SDO.display_option_Id = 458
				WHERE 
					ISNULL(SDO.Value,0) = vl.ColumnIndex
					
		End
		Else
			Begin
				SET @VariableName = REPLACE(REPLACE(REPLACE(REPLACE(@VariableName, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
				SET @VariableName = '%'+@VariableName+'%';
				
				CREATE TABLE #ActivityIdList(Id          INT,
											 ColumnIndex INT);
				DECLARE @LocalVariableId INT;
				INSERT INTO #VariableIdList
				SELECT Var_Id,
					   0,0 FROM Variables_base  WHERE Var_Desc LIKE @VariableName ESCAPE '\'
				INSERT INTO #VariableIdList
				SELECT Var_Id,
					   1,0 FROM Variables_base  WHERE User_Defined1 LIKE @VariableName ESCAPE '\'
				INSERT INTO #VariableIdList
				SELECT Var_Id,
					   2,0 FROM Variables_base  WHERE User_Defined2 LIKE @VariableName ESCAPE '\'
				INSERT INTO #VariableIdList
				SELECT Var_Id,
					   3,0 FROM Variables_base  WHERE User_Defined3 LIKE @VariableName ESCAPE '\';
					   UPDATE vl
				SET vl.Sheet_Id = SV.Sheet_Id
				from #VariableIdList vl join Sheet_Variables SV  on SV.Var_Id = vl.Id
				LEFT OUTER JOIN Sheet_Display_Options SDO  on SDO.Sheet_ID = SV.Sheet_Id and SDO.display_option_Id = 458
				WHERE 
					ISNULL(SDO.Value,0) = vl.ColumnIndex

			End

			IF ((Select Count(0) from #VariableIdList) =0)
			Begin 
				SET @VariableNamewithNoRecord = 1
			END
        END
--------------------------------------------------------------------------------------------------------------------
    IF @EquipmentList IS NOT NULL
        BEGIN
            DECLARE @TopEquipmentId INT= (Select top 1 PUId from #Equipments)
            IF @TopEquipmentId IS NOT NULL
               AND @TimeSelection IS NOT NULL
               AND @TimeSelection <> 7
                BEGIN
                    DECLARE @TempEndTime DATETIME= @EndTime
                    EXECUTE dbo.spBF_CalculateOEEReportTime @TopEquipmentId, @TimeSelection, @StartTime OUTPUT, @EndTime OUTPUT, 0
                    IF @TempEndTime IS NOT NULL
                        BEGIN
                            SET @EndTime = @TempEndTime
                        END
                END
        END
    IF @StartTime IS NOT NULL
        BEGIN
            SET @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime, @TimeZone)
        END
    IF @EndTime IS NOT NULL
        BEGIN
            SET @Endtime = dbo.fnServer_CmnConvertToDBTime(@Endtime, @TimeZone)
        END

    DECLARE @Sql NVARCHAR(MAX)= '';
    SET @Sql = ' 
	S AS 
                        (SELECT 
						A.Activity_Id,
	/*AST.ActivityStatus_Desc, */
	CASE when Activity_Status = 3 Then ''Complete''
when Activity_Status = 2 Then ''In Progress''
when Activity_Status = 1 Then ''Not Started''
when Activity_Status = 6 Then ''Queued''
when Activity_Status = 5 Then ''Released''
when Activity_Status = 4 Then ''Skipped'' END  ActivityStatus_Desc,
	ATypes.Activity_Desc ActivityTypeDesc,
	pu.pu_desc,
	A.PercentComplete,
	A.UserId,
	A.End_Time,
	A.Target_Duration,
	A.Execution_Start_Time,
	case
        when a.end_time is not null then datediff(second, a.end_time, dateadd(minute, a.target_duration, a.execution_start_time))
		else
			datediff(second, @now, dateadd(minute, a.target_duration, a.execution_start_time))
    end as duein,
	DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time) AS TimeDue,
	S.Sheet_Desc_Local, 
	PS.Prod_Id,
	E.Applied_Product,
	CASE WHEN E.Applied_Product IS NULL and A.Activity_Type_Id = 2  THEN 0 ELSE 1 END HasAppliedProduct,
	P1.Prod_Desc,
	P1.Prod_Code,
	u.Username,u.User_Desc,u.[System],
	NULL Process_Order, NULL PP_id
                           FROM Activities A '+ CASE 
						   WHEN (@StatusList LIKE '%1%' OR @StatusList LIKE '%2%') and @ActivityId IS NOT NULL THEN  'WITH(INDEX(IX_ACTIVITIES_STATUS_PUID)) ' 
						   WHEN (@StatusList LIKE '%3%' OR @StatusList LIKE '%4%') and @ActivityId IS NOT NULL THEN 'WITH( INDEX(IX_ACTIVITIES_STATUS_ENDTIME_PUID)) '
						   ELSE ''
						   END;

    SET @Sql+='
	'+Case when @IsSingleActivity = 1 and 1=0 THEN ' JOIN #Activities TMPA ON TMPA.ActivityId = A.Activity_Id ' ELSE '' END+'
                INNER JOIN Activity_Types ATypes  ON ATypes.Activity_Type_Id = A.Activity_Type_Id
                INNER JOIN Sheets AS S  ON S.Sheet_Id = A.Sheet_Id
                INNER JOIN Prod_Units_Base AS PU  ON PU.PU_Id = A.PU_Id 
				LEFT OUTER JOIN Production_Starts PS  on  Ps.PU_Id = A.PU_Id AND PS.Start_Time <= A.KeyId AND (PS.End_Time > A.KeyId OR PS.End_Time IS NULL)	
				LEFT JOIN EVENTS AS E  ON E.PU_Id = A.PU_ID AND E.Event_Id = A.KeyId1 
				'+CASE WHEN @ProductCode <> '' AND @ProductCode IS NOT NULL AND @productId IS NOT NULL   THEN ' AND E.Applied_Product IN ( '+@productId+')' ELSE '' END+'
				LEFT OUTER JOIN Products_Base P1  on P1.Prod_Id = CASE WHEN A.Activity_Type_Id =2 THEN ISNULL(E.Applied_Product,PS.Prod_Id) Else PS.Prod_Id End
				'+CASE WHEN @ProductCode <> '' AND @ProductCode IS NOT NULL AND @productId IS NOT NULL   THEN ' AND P1.Prod_Id IN ( '+@productId+')' ELSE '' END+'
				LEFT OUTER JOIN User_Defined_Events UDE  on UDE.UDE_Id  = A.KeyId1
				LEFT OUTER JOIN Users_Base u  on u.User_Id = A.UserID
			   '
	SET @Sql+=' WHERE 1 = 1 '

	IF @VariableName IS NOT NULL
	
	Begin
	SET @Sql+=' AND 	
	(	
		(EXISTS (Select 1 From #SV2 where ColumnIndex = 0 AND Sheet_ID = A.Sheet_Id))
		OR 
		(EXISTS (Select 1 From #SV2 S where ColumnIndex > 0 AND S.Sheet_ID = A.Sheet_Id AND S.Title = A.Title))
	)		
	'
	End
	SET @SubSql+=  Case when @StatusList IS NOT NULL AND @StatusList <> '' THEN  ' AND Activity_Status IN('+@StatusList+') '  Else  '' End
	SET @SubSql+= Case When @StartTime IS NOT NULL AND (@StatusList LIKE '%1%' OR @StatusList LIKE '%2%') Then ' AND Execution_Start_Time >= '''+CONVERT(nvarchar,@StartTime,109) +'''' Else '' End
	SET @SubSql+= Case When @EndTime IS NOT NULL AND (@StatusList LIKE '%1%' OR @StatusList LIKE '%2%') Then ' AND Execution_Start_Time <= '''+CONVERT(nvarchar,@EndTime,109)+ '''' Else '' End
	SET @SubSql+= Case When @StartTime IS NOT NULL AND (@StatusList LIKE '%3%' OR @StatusList LIKE '%4%') Then ' AND A.End_Time >= '''+CONVERT(nvarchar,@StartTime,109) + '''' Else '' End
	SET @SubSql+= Case When @EndTime IS NOT NULL AND (@StatusList LIKE '%3%' OR @StatusList LIKE '%4%') Then ' AND A.End_Time <= '''+CONVERT(nvarchar,@EndTime,109)+ '''' Else '' End
	SET @SubSql+= Case when @CompleteType IS NOT NULL Then ' AND ((Activity_Status = 3 AND Complete_Type IN ('+@CompleteType+')) '+ Case when @StatusList <> '' then '  OR Activity_Status IN ('+@StatusList+'))' else ')' End Else '' End


	IF @ActivityId IS NOT NULL
	Begin
		--SET @PageSize = 1
		--SET @PageNumber = 
		--SET @SubSql = @SubSql + ' AND Activity_Id in ( '+@ActivityID +') '
		SET @SubSql = @SubSql + ' AND EXISTS (SELECT 1 FROM #Activities WHERE ActivityId = A.Activity_Id) '
	End
	
	SELECT @Sql=@Sql+''+@SubSql
	
    IF @TransactionId = 0
        BEGIN
            
            --Adding where conditions if required
            --IF @ProductList IS NOT NULL
            --    BEGIN
            --        SET @Sql+='AND ISNULL(P1.Prod_Id,P.Prod_Id) IN ('+@ProductList+') '
            --    END
			
			--SET @Sql+=@SubSql+' ';

            IF @EventTypeList IS NOT NULL
                BEGIN
                    SET @Sql+='AND A.Activity_Type_Id IN ('+@EventTypeList+') '
                END

		   IF @EquipmentList IS NOT NULL
                BEGIN
                    SET @Sql+='AND A.PU_Id IN ('+@EquipmentList+') '
                END
           
            IF @IsOverdue IS NOT NULL
                BEGIN
                    SET @Sql+='AND CASE
                                                WHEN A.End_Time IS NULL
                                                THEN DATEDIFF(SECOND, @Now, DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time))
                                                WHEN A.End_Time IS NOT NULL
                                                THEN DATEDIFF(SECOND, A.End_Time, DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time))
                                         END < 0 '
                END
            --IF @ProcessOrderName IS NOT NULL
            --    BEGIN
            --        SET @ProcessOrderName = REPLACE(REPLACE(REPLACE(REPLACE(@ProcessOrderName, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
            --        SET @ProcessOrderName = '%'+@ProcessOrderName+'%';
            --    END

            IF @ProductCode IS NOT NULL
                BEGIN
                    SET @ProductCode = REPLACE(REPLACE(REPLACE(REPLACE(@ProductCode, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
                    SET @ProductCode = '%'+@ProductCode+'%';
                END

            IF @Event IS NOT NULL
                BEGIN
                    SET @Event = REPLACE(REPLACE(REPLACE(REPLACE(@Event, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
                    SET @Event = '%'+@Event+'%';
                END
            IF @Batch IS NOT NULL
                BEGIN
                    SET @Batch = REPLACE(REPLACE(REPLACE(REPLACE(@Batch, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
                    SET @Batch = '%'+@Batch+'%';
                END
            IF @DisplayType IS NOT NULL
                BEGIN
                    SET @Sql+='AND A.Display_Activity_Type_Id = @DisplayType '
                END
        END
    
	
	IF @DiscreteEventIds IS NOT NULL AND @DiscreteEventIds <> ''
	Begin
		SET @Sql+=' AND A.Keyid1 In ('+@DiscreteEventIds+') '
		--SET @Sql+=' AND A.Keyid1 In (select UDE_ID from  #DiscreteEventIds) AND PPS.PP_ID in (select PP_ID from  #DiscreteEventIds)'
	End


	IF @Event IS NOT NULL AND @Event <> '' AND @DiscreteSearchFor1UDE = 0
	Begin
		SET @Sql+=' AND ((A.Activity_Type_Id = 3
                                AND A.KeyId1 IN (Select UDE_Id from UDETmp))
                                OR (A.Activity_Type_Id = 2
                                AND A.KeyId1 IN (Select Event_Id from EventsTmp))) ' 
	End
	IF @Batch IS NOT NULL AND @DiscreteSearchFor1UDE = 0 AND @Batch <> ''
	Begin
		SET @Sql+=' AND A.Activity_Type_Id = 2 AND E.Event_Num LIKE @Batch ESCAPE ''\''' 
	End
	IF @ProductCode IS NOT NULL AND @ProductCode <> ''
	Begin
		SET @Sql+= ' AND P1.Prod_Code LIKE @ProductCode ESCAPE ''\'''
	End
	IF @ProductList IS NOT NULL AND @ProductList <>''
	Begin
		SET @Sql+=' AND P1.Prod_Id IN ('+@ProductList+') '
	End

	SET @Sql+=')'
				
    IF @VariableName IS NOT NULL
        BEGIN
		DEclare @VarSql nvarchar(max)
SET @Sql = 
'			
SELECT 
	DISTINCT
	SV.Sheet_Id,
	SV.Var_Order,
	SV.Title,
	SV.Title_Var_Order_Id,
	SDO.Display_Option_Id,
	CASE WHEN SDO.Display_Option_Id = 445 THEN Value ELSE 0 END AS Value,
	ROW_NUMBER() OVER(PARTITION BY SV.Sheet_Id,SV.Var_Id ORDER BY SV.Sheet_Id,CASE WHEN SDO.Display_Option_Id = 445 THEN 1 ELSE 0 END DESC) AS RowNumber,
	v.ColumnIndex 
INTO 
	#SV1
FROM 
	Sheet_Variables AS SV 
	JOIN Sheet_Display_Options AS SDO  ON SV.Sheet_Id = SDO.Sheet_Id
	JOIN #VariableIdList AS v ON v.Id = SV.Var_Id AND v.Sheet_Id = SV.Sheet_Id
;WITH SV1 AS (
SELECT * FROM #SV1),
SV2 AS (
SELECT DISTINCT S.ColumnIndex,S.Sheet_Id,S.Title FROM #SV1 S  WHERE   S.Value = 0  AND S.Rownumber =1
UNION
SELECT DISTINCT S.ColumnIndex,S.Sheet_Id,S.Title FROM #SV1 S JOIN Sheet_Variables SV  ON SV.Sheet_Id = S.Sheet_Id AND SV.Var_Order = S.Title_Var_Order_Id 
WHERE S.Value =1 AND S.Rownumber =1
)
SELECT * INTO #SV2 FROM SV2;
				
'

+ ';WITH 
'
+Case when @Event IS NOT NULL AND @Event <> '' AND @EquipmentList <> '' and @EquipmentList IS NOT NULL THEN 
'
EventsTmp As (Select Event_Id from Events  where PU_Id in  ('+@EquipmentList+')  AND Event_Num LIKE '''+@Event+''' ESCAPE ''\'')
, UDETmp As (Select UDE_ID from User_Defined_Events  where PU_Id in  ('+@EquipmentList+')  AND UDE_DESC LIKE '''+@Event+''' ESCAPE ''\'')

,' ELSE '' END+@Sql
        END
        ELSE
        BEGIN
		
		
            SET @Sql = 
			
			CASE WHEN @ActivityId IS NULL and 1=0 THEN 
			'
			Declare @DtMax Datetime, @DtMin Datetime;
			CREATE TABLE #TmpProductionPlanStarts(PP_Start_Id	int,Start_Time	datetime,End_Time	datetime,PU_Id	int,PP_Type_Id	int,pp_setup_id	int,PP_Id	int,Comment_Id	int,User_Id	int,Is_Production	bit,Process_Order nvarchar(50),UDE_ID INT,Event_Id INT,NEW INT);
			
			Select @DtMax = MAx(KeyID),@DtMin = Min(KeyId)
			FROM Activities A  '+ CASE 
						   WHEN @StatusList LIKE '%1%' OR @StatusList LIKE '%2%' THEN  'WITH( INDEX(IX_ACTIVITIES_STATUS_PUID)) ' 
						   WHEN @StatusList LIKE '%3%' OR @StatusList LIKE '%4%' THEN 'WITH( INDEX(IX_ACTIVITIES_STATUS_ENDTIME_PUID)) '
						   ELSE ''
						   END+' WHERE 1=1 '+@SubSql+CASE WHEN  ISNULL(@EquipmentList,'') <> '' THEN ' and Pu_Id in ('+@EquipmentList+') ' ELSE '' END+
			'   
			'+Case when @ActivityId IS NOT NULL  OR (@DiscreteEventIds <> '' AND @DiscreteEventIds IS NOT NULL) or 1=1 Then '' ELSE '
			 
			'+CASE WHEN  ISNULL(@EquipmentList,'') <> '' THEN ' ' ELSE '' END+'
			 
			'+CASE WHEN  ISNULL(@EquipmentList,'') <> '' THEN '  ' ELSE '' END+'
				  '+CASE WHEN  ISNULL(@EquipmentList,'') <> '' THEN '  ' ELSE '' END+'
				
 ' END +'

			
			' ELSE '' END +'
			
			;WITH '
						+Case when @Event IS NOT NULL AND @Event <> '' AND @DiscreteSearchFor1UDE = 0 THEN 
						'
						EventsTmp As (Select Event_Id from Events  where PU_Id in  ('+@EquipmentList+')  AND Event_Num LIKE '''+@Event+''' ESCAPE ''\'')
						, UDETmp As (Select UDE_ID from User_Defined_Events  where PU_Id in  ('+@EquipmentList+')  AND UDE_DESC LIKE '''+@Event+''' ESCAPE ''\'')
						,' ELSE '' END+@Sql
        END
		  
    Declare @ActivitiesTemp Table(RowNumber              INT ,
                                 ID                     BIGINT,
                                 Activity               nVARCHAR(1000),
                                 TargetDuration         INT,
                                 TimeDue                DATETIME,
                                 DueIn                  BIGINT,
                                 Duration               BIGINT,
                                 PercentComplete        FLOAT,
                                 ActivityStatusId       INT,
                                 StartTime              DATETIME,
                                 EndTime                DATETIME,
                                 EstimatedStartTime     DATETIME,
                                 KeyTime                DATETIME,
                                 KeyId                  INT,
                                 [Key]                  nVARCHAR(1000),
                                 Title                  nVARCHAR(255),
                                 ActivityPriority       INT,
                                 ActivityStatus         nVARCHAR(100),
                                 ActivityTypeId         INT,
                                 ActivityType           nVARCHAR(100),
                                 DisplayTypeId          TINYINT,
                                 UserName               NVARCHAR(255),
                                 UserId                 INT,
                                 SystemUser             TINYINT,
                                 CommentId              INT,
                                 Comments               nVARCHAR(5),
                                 Department             NVARCHAR(255),
                                 DepartmentId           INT,
                                 ProductionLine         nvarchar(50),
                                 ProductionLineId       INT,
                                 ProductionUnit         nvarchar(50),
                                 ProductionUnitId       INT,
                                 IsLocked               TINYINT,
                                 OverdueComment         nVARCHAR(MAX),
                                 OverdueCommentId       INT,
                                 OverdueCommentSecurity TINYINT,
                                 SkipComment            nVARCHAR(MAX),
                                 SkipCommentId          INT,
                                 SheetId                INT,
                                 ProductId              INT,
                                 Product                nVARCHAR(100),
                                 ProductCode            nVARCHAR(100),
                                 HasAppliedProduct      BIT,
                                 ProcessOrderId         INT,
                                 ProcessOrder           nVARCHAR(100),
                                 HasAvailableCells      BIT,
                                 HasVariableAliasing    BIT,
                                 CompleteTypeId         INT,
                                 Total                  INT,
                                 OverDueCount           INT,
								 OperationName	  nVARCHAR(MAX), 
						         Lot_Identifier	  nVARCHAR(MAX),
								 ExtendedInfo          nVARCHAR(MAX),
								 SheetName              NVARCHAR(50),
								 ActivityDetailCommentId          INT)
								-- CREATE CLUSTERED INDEX IXTMPACTIVITIES ON @ActivitiesTemp(ID);
    SET @Sql
	+=
	'
		
        ,S1 As (SELECT Count(0) Total From S)
        ,S2 as (SELECT COUNT(0) OverDueCount FROM S WHERE DueIn < 0) 
        SELECT 1, 
			Activity_Id ID,
		NULL Activity,
		Target_Duration TargetDuration,
		TimeDue,
		DueIn,
		NULL Duration,
		PercentComplete,
		NULL ActivityStatusId,
		NULL StartTime,
		End_Time EndTime,
		Execution_Start_Time EstimatedStartTime,
		NULL KeyTime,
		NULL KeyId,
		NULL [Key],
		NULL Title,
		NULL ActivityPriority,
		ActivityStatus_Desc ActivityStatusDesc,
		NULL ActivityTypeId,
		ActivityTypeDesc ActivityTypeDesc,
		NULL DisplayTypeId,
		UserName,
		UserId,
		[System] SystemUser,
		NULL CommentId,
		NULL Comments,
		NULL Department,
		NULL DepartmentId,
		NULL ProductionLine,
		NULL ProductionLineId,
		pu_desc ProductionUnit,
		NULL ProductionUnitId,
		NULL IsLocked,
		NULL OverdueComment,
		NULL OverdueCommentId,
		NULL OverdueCommentSecurity,
		NULL SkipComment,
		NULL SkipCommentId,
		NULL SheetId,
		Prod_Id ProductId,
		Prod_Desc Product,
		Prod_Code ProductCode,
		HasAppliedProduct HasAppliedProduct,
		PP_Id ProcessOrderId,
		Process_Order ProcessOrder,
		NULL HasAvailableCells,
		0 HasVariableAliasing,
		NULL CompleteTypeId, (Select Total From S1) Total, ISNULL((Select OverDueCount From S2),0) OverDueCount,NULL,NULL,NULL,Sheet_Desc_Local,NULL FROM S ';

		
    IF @SortColumn IS NOT NULL
       AND @SortOrder IS NOT NULL
        BEGIN
		
            SET @SQL+=' Order By '+@SortColumn+' '+@SortOrder;
        END
		
    IF @PageSize IS NOT NULL
       AND @PageNumber IS NOT NULL
        BEGIN
		
            SET @SQL+=' OFFSET '+CAST(@PageSize AS nVARCHAR)+' * ('+CAST(@PageNumber AS nVARCHAR)+' - 1) ROWS
               FETCH NEXT '+CAST(@PageSize AS nVARCHAR)+' ROWS ONLY OPTION (RECOMPILE);
			   '
        END
		
	
	IF @VariableNamewithNoRecord =0
	Begin
	
		INSERT INTO @ActivitiesTemp
		EXEC sp_executesql @Sql, N'@Now DATETIME, @ActivityId Nvarchar(max), @ProcessOrderName nvarchar(200), @ProductCode nvarchar(200), @Event NVARCHAR(200), @Batch NVARCHAR(200), @StartTime DATETIME, @EndTime DATETIME, @TimeZone NVARCHAR(200), @DisplayType TINYINT', 
		@Now, @ActivityId, @ProcessOrderName, @ProductCode, @Event, @Batch, @StartTime, @EndTime, @TimeZone, @DisplayType
		  
		SELECT @ActivityCount = Total,
			   @OverdueCount = OverDueCount FROM @ActivitiesTemp
			   
		UPDATE T SET T.ActivityPriority= A.Activity_Priority ,T.StartTime = A.Start_Time,T.KeyTime=A.KeyId,T.KeyId=A.KeyId1, T.IsLocked= A.Locked,T.Title=A.Title,T.DisplayTypeId =A.Display_Activity_Type_Id,
		T.Comments = CASE WHEN A.Comment_Id = 1 THEN 'Yes' ELSE 'No' END,
	
		T.CommentId =A.Comment_Id,T.OverdueCommentId=A.Overdue_Comment_Id,T.OverdueCommentSecurity=A.Overdue_Comment_Security,T.SheetId=A.Sheet_Id,T.ProductionUnitId=A.PU_Id,T.CompleteTypeId=A.Complete_Type,T.HasAvailableCells=A.HasAvailableCells,T.ActivityStatusId = A.Activity_Status,T.ActivityTypeId = A.Activity_Type_Id,T.Activity = A.Activity_Desc, T.EndTime = A.End_Time,T.SkipCommentId= A.Skip_Comment_Id, T.ActivityDetailCommentId=A.ActivityDetail_Comment_Id from Activities A Join @ActivitiesTemp T on T.ID = A.Activity_Id	  
		UPDATE T SET T.HasVariableAliasing = Case when ISNULL(S.value,0) = 0 then 0 Else 1 End FROM @ActivitiesTemp T Join Sheet_Display_Options S  ON T.SheetId= S.Sheet_Id and Display_option_Id = 458
	

		UPDATE T SET T.ProductionLine=pl.PL_Desc, T.ProductionLineId = pl.pl_id , T.Department=d.Dept_Desc , T.DepartmentId = d.Dept_Id From @ActivitiesTemp T Join Prod_Units_Base pu on pu.pu_id = T.ProductionUnitId Join Prod_Lines_Base pl on pl.PL_Id = pu.pl_id join Departments_Base d on d.Dept_Id = pl.Dept_Id

		IF @DiscreteEventIds IS NOT NULL AND @DiscreteEventIds <>''
		Begin
			UPDATE A
			SET
				A.Lot_Identifier = (SELECT Lot_Identifier From #DiscreteEventIds where UDE_ID = A.KeyId And Lot_Identifier IS NOT NULL),	
				A.OperationName = (SELECT Operation_Name From #DiscreteEventIds where UDE_ID = A.KeyId And Operation_Name IS NOT NULL),
				A.ProcessOrder = (SELECT distinct  Process_Order From #DiscreteEventIds where UDE_ID = A.KeyId And PP_Id IS NOT NULL),
				A.ProcessOrderId = (SELECT distinct  PP_Id From #DiscreteEventIds where UDE_ID = A.KeyId And PP_Id IS NOT NULL),
				A.ExtendedInfo = (SELECT distinct  Extended_Info From #DiscreteEventIds where UDE_ID = A.KeyId And Extended_Info IS NOT NULL)
			FROM @ActivitiesTemp A 
		
		End
		SELECT @ActivityCount = ISNULL(@ActivityCount, 0),
			   @OverdueCount = ISNULL(@OverdueCount, 0)

		IF @ActivityId IS NOT NULL
			BEGIN
				

				SELECT @PageNumber = CEILING(CAST(RowNumber AS FLOAT) / @PageSize) FROM @ActivitiesTemp WHERE ID in (Select col1 from dbo.fn_SplitString (@ActivityId,','))
			END

		SET @CurrentPage = @PageNumber
		SET @PageCount = CEILING(CAST(@ActivityCount AS FLOAT) / @PageSize)

		DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);

		UPDATE A SET A.[Key] = (Select Event_Num from Events   Where Event_Id = A.KeyId)   FROM @ActivitiesTemp A Where ActivityTypeId =2
		UPDATE A SET A.[Key] = (Select UDE_Desc from User_Defined_Events   Where UDE_Id = A.KeyId)   FROM @ActivitiesTemp A Where ActivityTypeId =3

	 End
 declare @DBZone varchar(100)
 SELECT TOP 1 @DBZone = Value FROM site_parameters WHERE parm_id = 192;
	
  
         SELECT ID,
                Activity,
				OperationName,
		        ExtendedInfo,
		        Lot_Identifier AS                                                                                              LotIdentifier,
                TargetDuration AS                                                                                              TargetDuration,
                --DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE A.TimeDue >= TZ.StartTime
                --                                                 AND A.TimeDue < TZ.EndTime), A.TimeDue) AS                    
				A.TimeDue at time zone @DBZone at time zone 'UTC' TimeDue,
                DueIn,
                Duration,
                PercentComplete,
                ActivityStatusId AS                                                                                            ActivityStatus,
                --DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE A.StartTime >= TZ.StartTime
                --                                                 AND A.StartTime < TZ.EndTime), A.StartTime) AS                
				A.StartTime at time zone @DBZone at time zone 'UTC' StartTime,
                --DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE A.EndTime >= TZ.StartTime
                --                                                 AND A.EndTime < TZ.EndTime), A.EndTime) AS                    
				A.EndTime at time zone @DBZone at time zone 'UTC' EndTime,
                --DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE A.EstimatedStartTime >= StartTime
                --                                                 AND A.EstimatedStartTime < EndTime), A.EstimatedStartTime) AS 
				A.EstimatedStartTime at time zone @DBZone at time zone 'UTC' EstimatedStartTime,
                --DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE A.KeyTime >= StartTime
                --                                                 AND A.KeyTime < EndTime), A.KeyTime) AS                       
				A.KeyTime at time zone @DBZone at time zone 'UTC' KeyTime,
                KeyId,
                [Key],
                Title,
                ActivityPriority,
                ActivityStatus AS                                                                                              ActivityStatusDesc,
                ActivityTypeId,
                ActivityType AS                                                                                                ActivityTypeDesc,
                DisplayTypeId,
                UserName,
                UserId,
                SystemUser,
                CommentId,
                Comments,
                Department,
                DepartmentId,
                ProductionLine,
                ProductionLineId,
                ProductionUnit,
                ProductionUnitId,
                IsLocked,
                OverdueComment,
                OverdueCommentId,
                OverdueCommentSecurity,
                SkipComment,
                SkipCommentId,
				ActivityDetailCommentId,
                SheetId,
				SheetName,
                ProductId,
               Product,
                ProductCode,
                HasAppliedProduct,
                ProcessOrderId,
                ProcessOrder,
                HasAvailableCells,
                HasVariableAliasing,
                CompleteTypeId,
                CASE CompleteTypeId
                    WHEN 0
                    THEN 'Manual Complete'
                    WHEN 1
                    THEN 'Auto Complete'
                    WHEN 2
                    THEN 'System Complete By New Event'
                   WHEN 3
                    THEN 'System Complete By Duration'
                END AS CompleteType
                FROM @ActivitiesTemp AS A

    SELECT @ActivityCount = ISNULL(@ActivityCount, 0), @OverdueCount = ISNULL(@OverdueCount, 0), @PageCount =  ISNULL(@PageCount, 0), @CurrentPage =  ISNULL(@CurrentPage, 1)
    SET @StartTimeOutput = @StartTime at time zone @DBZone at time zone 'UTC' 
    SET @EndTimeOutput = @EndTime at time zone @DBZone at time zone 'UTC' 


END



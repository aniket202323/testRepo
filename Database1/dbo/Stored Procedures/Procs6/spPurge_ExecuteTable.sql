CREATE PROCEDURE dbo.spPurge_ExecuteTable(
@pgid int,
@timeSliceMinutes int,
@puid int,
@name varchar(30),
@StartTime DateTime,
@totalAffected int out,
@DisableServCheck Int,
@MaxPendingTasks 	 Int,
@Debug int = 0)
 AS
DECLARE @sqlfirst 	 nvarchar(Max),
 	  	 @sql 	  	  	  	  	 nvarchar(Max),
 	  	 @sql1 	  	  	  	  	 nvarchar(Max),
 	  	 @sql2 	  	  	  	  	 nvarchar(Max),
 	  	 @sqlafter 	  	  	 nvarchar(Max),
 	  	 @dt 	  	  	  	  	 datetime,
 	  	 @retention 	  	  	 int,
 	  	 @elementPerBatch 	 int,
 	  	 @top 	  	  	  	 varchar(50),
 	  	 @affected 	  	  	 int,
 	  	 @desc 	  	  	  	 varchar(255),
 	  	 @quit 	  	  	  	 int,
 	  	 @date 	  	  	  	 datetime,
 	  	 @rowcount 	  	  	 varchar(50),
 	  	 @checkaffected 	  	 varchar(100),
 	  	 @TestDeleteSql 	  	 nVarChar(Max),
 	  	 @VariableTypes 	  	 VarChar(10),
 	  	 @DoEsig 	  	  	  	 Int,
 	  	 @BatchCutoff 	  	 Int,
 	  	 @XLock 	  	  	  	 Bit
IF @Debug Is Null
 	 SELECT @Debug = 0
SET @DoEsig = 0
--If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ESignature]'))
--BEGIN
-- 	 IF EXISTS(select Top 1 * from ESignature) 	 SET @DoEsig = 1
--END
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
SET @totalAffected=0
SET @sql2=''
Set @VariableTypes = ''
--get settings
IF @puid Is Null
 	 SELECT @retention = RetentionMonths,@elementPerBatch = ElementPerBatch
  	  	 FROM PurgeConfig_Detail
 	  	 WHERE Purge_Id = @pgid and PU_Id Is NUll and Var_Id Is Null AND TableName = @name
ELSE
BEGIN
 	 SELECT @retention = MAX(RetentionMonths),@elementPerBatch = Min(ElementPerBatch)
  	  	 FROM PurgeConfig_Detail
 	  	 WHERE Purge_Id = @pgid and PU_Id = @puid and Var_Id Is Null 
END
if @retention=-1 or @retention is null return
if @elementPerBatch is null return
SET @BatchCutoff = Convert(Int,@elementPerBatch*.20)
--IF @Debug = 1 select @elementPerBatch,@retention
SET @date=dateadd(month,-@retention,@StartTime)
SET @date = DateAdd(Hour,-DatePart(Hour,@date),@date)
SET @date = DateAdd(Minute,-DatePart(Minute,@date),@date)
SET @date = DateAdd(Second,-DatePart(Second,@date),@date)
SET @date = DateAdd(millisecond,-DatePart(millisecond,@date),@date)
SET @top=' top '+cast(@elementPerBatch as varchar) + ' '
SET @rowcount='SET rowcount '+cast(@elementPerBatch as varchar)
SET @checkaffected='if @affected<'+cast(@BatchCutoff as varchar)
IF @quit=0 and (dateadd(n,@timeSliceMinutes,@StartTime)>getdate())
begin
  	  SET @sqlfirst='declare @affected int
  	    	  declare @haffected int
  	    	  DECLARE @MaxEventDate DateTime
  	    	  DECLARE @MinId  	  BigInt
  	    	  DECLARE @MinVarId2 BigInt
  	    	  SET @affected=0
  	    	  SET @haffected=0
  	    	  DECLARE @Qty TABLE(qty int)
  	    	  CREATE TABLE #IdsToDelete(id BigInt PRIMARY KEY CLUSTERED,CmtId int null,Id2 BigInt Null,Result_On Datetime)
 	  	 DECLARE @Commentids TABLE (commentId int)
 	  	 CREATE TABLE #Esigs (SignatureId int PRIMARY KEY CLUSTERED) '
  	  if @name='Tests' and @puid Is NUll   
  	  BEGIN
  	    	    	  /* Delete Via Clustered index - by id if index is not on Test_By_Variable_And_Result_On*/
  	    	    	  SET @sql='
 	  	  	  Declare  @IdsToDelete TABLE(id BigInt ,CmtId int null,Id2 BigInt Null,Result_On Datetime)
  	    	    	  DECLARE @ArrayData TABLE(Id Int)
  	    	    	  INSERT INTO @ArrayData(Id) SELECT ' + @top + ' Array_Id  FROM Array_Data WHERE ShouldDelete = 1 
  	    	    	  DELETE a From Array_Data a Join @ArrayData b On b.Id = a.Array_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  INSERT into @IdsToDelete (id, CmtId,Id2,Result_On) select'+@top+' Test_Id,Comment_Id,Array_Id,Result_On FROM Tests  a (nolock)
 	  	  	  Where   Test_Id > 0
 	  	  	  order by Test_Id
 	  	  	 
 	  	  	  INSERT into @IdsToDelete (id, CmtId,Id2,Result_On) select'+@top+' Test_Id,Comment_Id,Array_Id,Result_On FROM Tests  a (nolock)
 	  	  	  Where  Test_Id < 0
 	  	  	  order by Test_Id  
 	  	  	  Insert into #IdsToDelete (id, CmtId,Id2,Result_On)
             Select distinct id, CmtId,Id2,Result_On from @IdsToDelete
  	    	    	  DELETE a FROM #IdsToDelete a Where a.Result_On >= ''' + cast(@date as varchar)+ '''
 	  	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	    	  IF (SELECT OBJECTPROPERTY(OBJECT_ID(N''Test_By_Variable_And_Result_On''), ''CnstIsClustKey'')) = 1
  	    	    	  BEGIN
  	    	    	    	  IF (Select Count(*) From #IdsToDelete) < ' + cast(@BatchCutoff as varchar) + '
  	    	    	    	  BEGIN
  	    	    	    	    	  Declare @MinVarId Int
  	    	    	    	    	  Declare @CurrentTime DateTime
  	    	    	    	    	  Declare @MinTime DateTime
  	    	    	    	    	  DECLARE @MinTime2 DateTime
  	    	    	    	    	  Declare @Data Table(Id Int,MinTime DateTime)
  	    	    	    	    	  Declare @StartId Int,@NextId Int
  	    	    	    	    	  DECLARE @MinTestId BigInt
  	    	    	    	    	  SELECT @StartId = Min(Var_Id) From Variables_BAse
  	    	    	    	    	  While @StartId Is Not Null
  	    	    	    	    	  BEGIN
  	    	    	    	    	    	  SET @CurrentTime = Null
  	    	    	    	    	    	  SELECT @CurrentTime =  Min(Result_On) FROM Tests WHERE Var_Id = @StartId
  	    	    	    	    	    	  IF @CurrentTime Is Not Null
  	    	    	    	    	    	  BEGIN
  	    	    	    	    	    	    	  INSERT INTO @Data(Id,MinTime) Values (@StartId,@CurrentTime) 
  	    	    	    	    	    	    	  IF @MinTime Is Null
  	    	    	    	    	    	    	  BEGIN
  	    	    	    	    	    	    	    	  SET @MinTime = @CurrentTime
  	    	    	    	    	    	    	    	  SET @MinVarId = @StartId
  	    	    	    	    	    	    	  END
  	    	    	    	    	    	    	  ELSE
  	    	    	    	    	    	    	  BEGIN
  	    	    	    	    	    	    	    	  IF @MinTime > @CurrentTime 
  	    	    	    	    	    	    	    	  BEGIN
  	    	    	    	    	    	    	    	    	  SET @MinTime = @CurrentTime
  	    	    	    	    	    	    	    	    	  SET @MinVarId = @StartId
  	    	    	    	    	    	    	    	  END
  	    	    	    	    	    	    	  END
  	    	    	    	    	    	  END
  	    	    	    	    	    	  SET @NextId = Null
  	    	    	    	    	    	  SELECT @NextId = Min(Var_Id) From Variables_BAse WHERE  Var_Id > @StartId
  	    	    	    	    	    	  SET @StartId = @NextId
  	    	    	    	    	  END
  	    	    	    	    	  SELECT @MinTestId = Test_Id -1 FROM TESTS WHERE Var_Id = @MinVarId and result_On = @MinTime
  	    	    	    	    	  INSERT into #IdsToDelete (id, CmtId,Id2,Result_On) select'+@top+' Test_Id,Comment_Id,Array_Id,Result_On FROM Tests a WHERE Test_Id > @MinTestId 
 	  	  	  	  	  And not exists (select 1 from #IdsToDelete where id = a.Test_id)
 	  	  	  	  	  order by Test_Id 
  	    	    	    	    	  INSERT into #IdsToDelete (id, CmtId,Id2,Result_On) select '+@top+' Test_Id,Comment_Id,Array_Id,Result_On FROM Tests a WHERE Var_Id = @MinVarId 
 	  	  	  	  	  And not exists (select 1 from #IdsToDelete where id = a.Test_id)
 	  	  	  	  	  and result_On <  ''' + cast(@date as varchar)+ '''
  	    	    	    	    	  DELETE a FROM #IdsToDelete a where a.Result_On >= ''' + cast(@date as varchar)+ '''
  	    	    	    	    	  SET @MinVarId2 = @MinVarId -1
  	    	    	    	    	  WHILE ((SELECT COUNT(*) FROM #IdsToDelete) < ' + cast(@elementPerBatch as varchar) + ') and @MinVarId Is Not Null
  	    	    	    	    	  BEGIN
  	    	    	    	    	    	  SET @MinTime2 = Null
  	    	    	    	    	    	  SET @MinVarId = Null
  	    	    	    	    	    	  SELECT @MinTime2 = MIN(MinTime) FROM @Data WHERE MinTime >= @MinTime and Id > @MinVarId2
  	    	    	    	    	    	  IF @MinTime2 Is Not Null
  	    	    	    	    	    	  BEGIN
  	    	    	    	    	    	    	  SELECT @MinVarId = MIN(Id) FROM @Data WHERE MinTime = @MinTime2  and Id > @MinVarId2
  	    	    	    	    	    	    	  SET @MinTime = @MinTime2
  	    	    	    	    	    	    	  SET @MinVarId2 = @MinVarId
  	    	    	    	    	    	    	  INSERT into #IdsToDelete (id, CmtId,Id2,Result_On) select '+@top+' Test_Id,Comment_Id,Array_Id,Result_On FROM Tests a WHERE Var_Id = @MinVarId 
 	  	  	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Test_id)
 	  	  	  	  	  	  	  and result_On <  ''' + cast(@date as varchar)+ '''
  	    	    	    	    	    	  END
  	    	    	    	    	  END
  	    	    	    	  END
  	    	    	  END
  	    	    	  '
  	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Tests]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	  BEGIN
  	    	    	    	  SET @SQL=@SQL + '   	    	    	  
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Tests a JOIN #IdsToDelete b ON a.Test_Id = b.id  WHERE Signature_Id Is Not NULL
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Test_History a  JOIN #IdsToDelete b ON a.Test_Id = b.id WHERE Signature_Id Is Not NULL'
  	    	    	  END
  	    	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	    	  BEGIN
  	    	    	    	  SET @sql = @sql + '
  	    	    	    	    	    	 
  	    	    	    	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	    	    	  WHERE tf.TableId = 42
  	    	    	    	    	    	  SET @affected=@@rowcount
  	    	    	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	    	  '
  	    	    	  END
  	    	    	  SET @SQL1= ' 
 	  	  	  
 	  	  	  
  	    	    	  DELETE a FROM Array_Data a
  	    	    	    	  JOIN #IdsToDelete b ON a.Array_Id = b.id2
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
 	  	  	  DELETE a FROM Tests a
  	    	    	    	  JOIN #IdsToDelete b on b.id = a.Test_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  DELETE a FROM Test_History a 
  	    	    	    	  JOIN #IdsToDelete b on b.id = a.Test_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
   	    	  
  	    	    	  INSERT INTO @Commentids (CommentId)  	  SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null '
  	    	    	  SET @sql1=@sql1+@checkaffected+'
  	    	    	  begin
  	    	    	    	  SET @MinId = Null
  	    	    	    	  SELECT @MinId = Min(Test_Id) FROM Tests
  	    	    	    	  IF @MinId IS Null SELECT @MinId = Max(Test_Id) + 1 FROM Test_History
  	    	    	    	  INSERT into #IdsToDelete (id) 
 	  	  	  	  Select Distinct Test_id from (
 	  	  	  	  select'+@top+' Test_Id 
  	    	    	    	  FROM Test_History a (nolock)
  	    	    	    	  where Test_Id < @MinId 
 	  	  	  	  And Not exists (select 1 from #IdsToDelete Where id = a.Test_Id)) T
 	  	  	  	  '
  	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Test_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @SQL1=@SQL1 + '   	    	    	  
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct  Signature_Id FROM Test_History a JOIN #IdsToDelete b ON a.Test_Id = b.id WHERE Signature_Id Is Not NULL'
  	    	    	    	  END
  	    	    	    	  SET @sql1 = @sql1 + '
  	    	    	    	  DELETE a FROM Test_History a JOIN #IdsToDelete b ON a.Test_Id = b.id 
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	  end '
  	    	    	  SET @sql1=@sql1+'
 	  	  	  
 	  	  	  
 	  	  	  
 	  	  	  '
  	  END
  	  --End of script for Tests table
 	  ELSE if @name='Active_Specs'  
  	  BEGIN
  	    	  SET @sql=' 
  	    	  INSERT into #IdsToDelete (id)
  	    	  select'+@top+' AS_Id 
  	    	  FROM Active_Specs a where expiration_date<'''+cast(@date as varchar)+''' and not expiration_date is null 
 	  	  and not exists(select 1 from #IdsToDelete Where id = a.AS_ID)
 	  	  order by expiration_date
 	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  UPDATE vs SET AS_Id = NULL
  	    	    	  FROM Var_Specs vs
  	    	    	  Join #IdsToDelete a On a.id = vs.AS_Id
  	    	  DELETE s FROM Active_Specs s 
  	    	    	  Join #IdsToDelete a On a.id = s.AS_Id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	   '
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	  BEGIN
  	    	    	  SET @sql = @sql + '
  	    	    	    	   
  	    	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 39 
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	   '
  	    	  END
  	  END
  	  else if @name='Alarms'  
  	  BEGIN
  	    	  SET @sql=' 
 	  	  Truncate table #IdsToDelete;
  	    	  INSERT into #IdsToDelete (id) select'+@top+' Alarm_Id FROM Alarms a 
 	  	  where not exists (select 1 from #IdsToDelete where id = a.Alarm_id) order by Alarm_Id 
 	  	  
  	    	  DELETE i FROM  #IdsToDelete i
  	    	  JOIN Alarms a On a.Alarm_Id = i.id
  	    	  WHERE a.end_time>='''+cast(@date as varchar)+''' or a.end_time is null
 	  	  IF(select count(0) from #IdsToDelete ) =0
 	  	  Return;
  	    	  IF (SELECT COUNT(*) FROM #IdsToDelete) < ' + cast(@BatchCutoff as varchar) + '
  	    	  BEGIN
  	    	    	  INSERT into #IdsToDelete (id) select'+@top+' Alarm_Id FROM Alarms a where end_time <'''+cast(@date as varchar) + '''
 	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Alarm_Id)
 	  	  	  and end_time is not null Order By end_time
  	    	  END
  	    	  '
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Alarms]') and Name = N'Signature_Id') AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @sql = @sql + '
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct Signature_Id FROM Alarms a
  	    	    	    	    	  JOIN  #IdsToDelete b ON a.Alarm_Id = b.id 
  	    	    	    	    	  WHERE Signature_Id Is Not Null
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct  Signature_Id FROM Alarm_History ah
  	    	    	    	    	  JOIN  #IdsToDelete b ON ah.Alarm_Id = b.id 
  	    	    	    	    	  WHERE Signature_Id Is Not Null'
  	    	  END
  	    	  SET @sql = @sql + '
  	    	  DELETE ah FROM Alarm_History  ah
  	    	    	  JOIN  #IdsToDelete b ON ah.Alarm_Id = b.id 
  	    	  SET @haffected=@@rowcount
  	    	  INSERT into @Qty values (@haffected)'
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Alarms]') and Name = N'Ack_Comment_Id')
  	    	  BEGIN
  	    	    	  SET @sql = @sql + '
  	    	    	  INSERT INTO @Commentids(CommentId)
  	    	    	    	  SELECT Ack_Comment_Id FROM Alarms a
  	    	    	    	    	  JOIN  #IdsToDelete b ON a.Alarm_Id = b.id
  	    	    	    	    	  WHERE Ack_Comment_ID Is Not Null'
  	    	  END
  	    	  SET @sql = @sql + '
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Action_Comment_Id FROM Alarms a
  	    	    	    	    	  JOIN  #IdsToDelete b ON a.Alarm_Id = b.id
  	    	    	    	    	  WHERE Action_Comment_Id Is Not Null
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Cause_Comment_Id FROM Alarms a
  	    	    	    	    	  JOIN  #IdsToDelete b ON a.Alarm_Id = b.id
  	    	    	    	    	  WHERE Cause_Comment_Id Is Not Null
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Research_Comment_Id FROM Alarms a
  	    	    	    	    	  JOIN  #IdsToDelete b ON a.Alarm_Id = b.id
  	    	    	    	    	  WHERE Research_Comment_Id Is Not Null
  	    	  DELETE a FROM Alarms a  	  JOIN  #IdsToDelete b ON a.Alarm_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE FROM #IdsToDelete
  	    	  '+@checkaffected+'
  	    	  BEGIN
  	    	    	  SELECT @MinId = Min(Alarm_Id) FROM Alarms
  	    	    	  '+@rowcount+'
  	    	    	  INSERT into #IdsToDelete (id)
  	    	    	    	  SELECT distinct Alarm_Id  
  	    	    	    	    	  FROM Alarm_History  a
  	    	    	    	    	  WHERE Alarm_Id < @MinId
 	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Alarm_Id)
 	  	  	  	  	  
 	  	  	  	  	  '
  	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Alarm_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	  BEGIN
  	    	    	    	  SET @sql = @sql + '
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Alarm_History ah
  	    	    	    	    	  JOIN  #IdsToDelete b ON ah.Alarm_Id = b.id 
  	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	    	  END
  	    	    	  SET @sql = @sql + '
  	    	    	  SET rowcount 0
  	    	    	  DELETE ah FROM Alarm_History ah  	  JOIN  #IdsToDelete b ON ah.Alarm_Id = b.id 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  END
  	    	   '
  	  END
  	  else if @name='Report_Engine_Activity'  
  	  BEGIN
  	    	  SET @sql='
  	    	  INSERT into #IdsToDelete (id) select'+@top+' REA_Id  	  FROM Report_Engine_Activity a
 	  	  where not exists (select 1 from #IdsToDelete where id =a.REA_Id)
 	  	  order by REA_Id
 	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  DELETE a FROM #IdsToDelete a JOIN Report_Engine_Activity b On b.REA_Id = a.Id And b.Time >= ''' + cast(@date as varchar)+ '''
  	    	  DELETE rea FROM Report_Engine_Activity rea Join #IdsToDelete b on b.id = rea.REA_Id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  '
  	  END
  	  else if @name='Sheet_Columns'  
  	  BEGIN
  	    	  SET @sql='
  	    	  DECLARE @id2 TABLE(id int,result datetime,CmtId int)
  	    	  DECLARE @Data Table(Id Int,MinTime DateTime)
  	    	  DECLARE @StartId Int,@NextId Int
  	    	  DECLARE @SheetToDelete Int
  	    	  DECLARE @MinDate DateTime
  	    	  DECLARE @MinDate2 DateTime
  	    	  SELECT @StartId = Min(Sheet_Id) From Sheets
  	    	  While @StartId Is Not Null
  	    	  BEGIN
  	    	    	  INSERT INTO @Data(Id,MinTime)
  	    	    	    	  SELECT @StartId,Min(Result_On)
  	    	    	    	    	  FROM Sheet_Columns WHERE Sheet_Id = @StartId
  	    	    	  Select @NextId = Null
  	    	    	  SELECT @NextId = Min(Sheet_Id) From Sheets WHERE  Sheet_Id > @StartId
  	    	    	  SELECT @StartId = @NextId
  	    	  END
  	    	  DELETE FROM @Data WHERE MinTime Is Null
  	    	  SELECT @MinDate = MIN(MinTime) From @Data WHERE MinTime Is not Null
  	    	  SELECT @SheetToDelete = Min(Id) From @Data  Where MinTime = @MinDate
  	    	  INSERT into @id2 select'+@top+' Sheet_Id,Result_On,Comment_Id FROM Sheet_Columns where Result_On<'''+cast(@date as varchar)+''' and Sheet_Id = @SheetToDelete order by Result_On
  	    	  SET @StartId = @SheetToDelete
  	    	  WHILE ((SELECT COUNT(*) FROM @id2) < ' + cast(@BatchCutoff as varchar) + ') and @SheetToDelete Is Not Null
  	    	  BEGIN
  	    	    	  SET @MinDate2 = Null
  	    	    	  SET @SheetToDelete = Null
  	    	    	  SELECT @MinDate2 = MIN(MinTime) FROM @Data WHERE MinTime >=  @MinDate and Id > @StartId 
  	    	    	  IF @MinDate2 Is Not Null
  	    	    	  BEGIN
  	    	    	    	  SELECT @SheetToDelete = MIN(Id) FROM @Data WHERE MinTime = @MinDate2 and Id > @StartId 
  	    	    	    	  SET @MinDate = @MinDate2
  	    	    	    	  SET @StartId = @SheetToDelete
  	    	    	    	  INSERT into @id2 select'+@top+' Sheet_Id,Result_On,Comment_Id FROM Sheet_Columns where Result_On<'''+cast(@date as varchar)+''' and Sheet_Id = @SheetToDelete order by Result_On
  	    	    	  END
  	    	  END
'
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Sheet_Columns]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @sql = @sql + '
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct  Signature_Id FROM Sheet_Column_History sc JOIN @id2 a on sc.Sheet_Id=a.id and sc.Result_On=a.result WHERE sc.Signature_Id is not null
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct Signature_Id FROM Sheet_Columns sc JOIN @id2 a on sc.Sheet_Id=a.id and sc.Result_On=a.result  WHERE Signature_Id is not null'
  	    	  END
  	    	  SET @sql = @sql + '
  	    	  if (Select  count(0) from @id2) =0
 	  	  return;
  	    	  DELETE sc FROM Sheet_Column_History sc JOIN @id2 a on sc.Sheet_Id=a.id and sc.Result_On=a.result
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE sc FROM Sheet_Columns sc JOIN @id2 a on sc.Sheet_Id=a.id and sc.Result_On=a.result
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  INSERT INTO @Commentids(CommentId)  	  SELECT CmtId FROM @id2 WHERE CmtId Is Not Null
  	    	  '+@checkaffected+'
  	    	  begin
  	    	    	  DELETE From @id2
  	    	    	  DELETE FROM @Data
  	    	    	  SELECT @MinDate = Null
  	    	    	  SELECT @StartId = Null
  	    	    	  SELECT @SheetToDelete = NULL
  	    	    	  DECLARE @SheetIds TABLE(Sheet_Id Int)
  	    	    	  INSERT INTO @SheetIds(Sheet_Id)
  	    	    	    	  SELECT Distinct sheet_Id from Sheet_Column_History
  	    	    	  SELECT @StartId = Min(Sheet_Id) From @SheetIds
  	    	    	  While @StartId Is Not Null
  	    	    	  BEGIN
  	    	    	    	  INSERT INTO @Data(Id,MinTime)
  	    	    	    	    	  SELECT @StartId,Min(Result_On)
  	    	    	    	    	    	  FROM Sheet_Column_History WHERE Sheet_Id = @StartId
  	    	    	    	  Select @NextId = Null
  	    	    	    	  SELECT @NextId = Min(Sheet_Id) From @SheetIds WHERE  Sheet_Id > @StartId
  	    	    	    	  SELECT @StartId = @NextId
  	    	    	  END
  	    	    	  SELECT @MinDate = MIN(MinTime) From @Data WHERE MinTime Is not Null
  	    	    	  SELECT @SheetToDelete = Min(Id) From @Data  Where MinTime = @MinDate
  	    	    	  INSERT into @id2 select'+@top+' Sheet_Id,Result_On,Comment_Id FROM Sheet_Column_History where Result_On<'''+cast(@date as varchar)+''' and Sheet_Id = @SheetToDelete '
  	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Sheet_Column_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	  BEGIN
  	    	    	    	  SET @sql = @sql + '
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct  Signature_Id FROM Sheet_Column_History sc JOIN @id2 a on sc.Sheet_Id=a.id and sc.Result_On=a.result WHERE Signature_Id is Not NULL'
  	    	    	  END
  	    	    	  SET @sql = @sql + '
  	    	    	  DELETE sc FROM Sheet_Column_History sc JOIN @id2 a on sc.Sheet_Id=a.id and sc.Result_On=a.result
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  SET rowcount 0
  	    	  end
  	    	   '
  	  END
  	  else if @name='Var_Specs'  
  	    	  SET @sql='
  	    	  INSERT into #IdsToDelete (id)
  	    	  select'+@top+' VS_Id
  	    	    	  FROM Var_Specs a where effective_date<'''+cast(@date as varchar)+''' and  expiration_date<'''+cast(@date as varchar)+''' and expiration_date is Not Null 
 	  	  	 and not exists (select 1 from #IdsToDelete where id = a.VS_Id)
 	  	  	 order by effective_date
  	    	   IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  DELETE vs FROM Var_Specs vs JOIN  #IdsToDelete b ON vs.VS_Id = b.id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	    '
  	  else if @name='Deleted_Variables'  
  	  begin
  	    	  SET @sql='
  	    	  declare @var int
  	    	  SELECT @var=Min(Var_Id) FROM Variables_Base where PU_Id=0 and Var_Id > 0
  	    	  IF @var Is Not Null
  	    	  BEGIN
  	    	    	  if exists(SELECT top 1 Var_Id FROM Tests where Var_Id=@var) '
  	    	    	  if exists(select * FROM sysindexkeys where id = object_id('Test_History') and colid =(select Colid from syscolumns where id = object_id('Test_History') and Name = 'Var_Id'))
  	    	    	  BEGIN
  	    	    	    	  SET @sql=@sql+'or exists(SELECT top 1 Var_Id FROM Test_History where Var_Id=@var) '
  	    	    	  END
  	    	    	  SET @sql=@sql+'begin
  	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' Test_Id,Comment_Id FROM Tests a where Var_Id=@var
 	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Test_Id)
 	  	  	  IF (Select count(0) from #IdsToDelete) =0
 	  	  	  	  	  	  Return;
  	    	    	  INSERT INTO @Commentids(CommentId) SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null '
  	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Tests]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	  BEGIN
  	    	    	    	  SET @sql = @sql + '
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Tests t
  	    	    	    	    	  JOIN  #IdsToDelete b ON t.Test_Id = b.id 
  	    	    	    	    	  WHERE Signature_Id Is Not Null 
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Test_History th
  	    	    	    	    	  JOIN  #IdsToDelete b ON th.Test_Id = b.id 
  	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	    	  END
  	    	    	  SET @sql = @sql + '
  	    	    	    
  	    	    	  DELETE th FROM Test_History th  JOIN #IdsToDelete t on th.Test_Id=t.id ;
  	    	    	  SET @affected=@@rowcount;
  	    	    	  INSERT into @Qty values (@affected);
  	    	    	  DELETE a FROM Array_Data a
  	    	    	    	  JOIN TESTS t on t.Array_Id = a.Array_Id
  	    	    	    	  JOIN #IdsToDelete b ON t.Test_Id = b.id;
  	    	    	  SET @affected=@@rowcount;
  	    	    	  INSERT into @Qty values (@affected);
  	    	    	  DELETE ts FROM Tests ts  JOIN #IdsToDelete t on ts.Test_Id=t.id ;
  	    	    	  SET @affected=@@rowcount;
  	    	    	  INSERT into @Qty values (@affected) '
  	    	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	    	  BEGIN
  	    	    	    	  SET @sql = @sql + '
  	    	    	    	    	    	   
  	    	    	    	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	    	    	  WHERE tf.TableId = 42;
  	    	    	    	    	    	  SET @affected=@@rowcount;
  	    	    	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	    	    '
  	    	    	  END
  	    	    	  if exists(select * FROM sysindexkeys where id = object_id('Test_History') and colid =(select Colid from syscolumns where id = object_id('Test_History') and Name = 'Var_Id'))
  	    	    	  BEGIN
  	    	    	    	  SET @sql=@sql+@checkaffected+'
  	    	    	    	    	  begin
  	    	    	    	    	    	  DELETE FROM #IdsToDelete
  	    	    	    	    	    	  INSERT into #IdsToDelete (id, CmtId) 
 	  	  	  	  	  	  Select distinct Test_Id , comment_Id from (
 	  	  	  	  	  	  select'+@top+' Test_Id,Comment_Id, Row_number() Over (Partition by Test_Id order by Test_id)rownum FROM Test_History a where Var_Id=@var
 	  	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Test_Id and CmtId = a.Comment_Id ))T where rownum = 1;
 	  	  	  	  	  	  IF (Select count(0) from #IdsToDelete) =0
 	  	  	  	  	  	  Return;
 	  	  	  	  	  	  '
  	    	    	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Test_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	    	    	  BEGIN
  	    	    	    	    	    	    	  SET @sql = @sql + '
  	    	    	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Test_History  th
  	    	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON th.Test_Id = b.id 
  	    	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null ;'
  	    	    	    	    	    	  END
  	    	    	    	    	    	  SET @sql = @sql + '
  	    	    	    	    	    	  DELETE th FROM Test_History th  JOIN #IdsToDelete t on th.Test_Id=t.id ;
  	    	    	    	    	    	  SET @affected=@@rowcount;
  	    	    	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	    	  SET rowcount 0
  	    	    	    	    	  end '
  	    	    	  END
  	    	    	  SET @sql=@sql+'
  	    	    	   
  	    	    	  end
  	    	    	  else
  	    	    	  begin
  	    	    	    	  INSERT INTO @Commentids(CommentId)
  	    	    	    	    	  SELECT Comment_Id FROM Variables_Base WHERE Comment_Id Is Not Null And Var_Id=@var;
  	    	    	    	   
  	    	    	    	  DELETE FROM Calculation_Input_Data WHERE Member_Var_Id = @var;
  	    	    	    	  DELETE FROM Calculation_Input_Data WHERE Result_Var_Id = @var ;
  	    	    	    	  DELETE FROM Calculation_Dependency_Data WHERE Result_Var_Id = @var;
  	    	    	    	  DELETE FROM Calculation_Dependency_Data WHERE Var_Id = @var ;
  	    	    	    	  DELETE FROM Calculation_Instance_Dependencies WHERE Result_Var_Id = @var;
  	    	    	    	  DELETE FROM Calculation_Instance_Dependencies WHERE Var_Id = @var ;
  	    	    	    	  DELETE FROM Sheet_Variables WHERE Var_Id = @var;
  	    	    	    	  DELETE FROM GB_Rsum_Data WHERE Var_Id = @var;
  	    	    	    	  DELETE FROM Variables_Base where Var_Id=@var;
  	    	    	    	  SET @affected=@@rowcount;
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    '
  	    	    	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @sql = @sql + '
  	    	    	    	    	    	    	   
  	    	    	    	    	    	    	  DELETE FROM Table_Fields_Values where TableId = 20 and KeyId = @var
  	    	    	    	    	    	    	  SET @affected=@@rowcount
  	    	    	    	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	    	    	    '
  	    	    	    	  END
  	    	    	    	  SET @sql = @sql + '
  	    	  end
  	  END'
  	  end
  	  --per unit or time
  	  else if @name='GB_RSum'  
  	  BEGIN
  	    	  IF @puid Is Not Null
  	    	    	  SET @sql='INSERT into #IdsToDelete (id, CmtId) select'+@top+' RSum_Id,Comment_Id FROM GB_RSum a where Start_time<'''+cast(@date as varchar) + ''' 
 	  	  	  and not exists (select 1 from #IdsToDelete where id = a.RSum_Id)
 	  	  	  and PU_Id='+ Cast(@puid as varchar) +
  	    	    	    	   'order by Start_Time'
  	    	  else
  	    	  BEGIN
  	    	    	  SET @sql='
  	    	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' RSum_Id,Comment_Id FROM GB_RSum a 
 	  	  	  	  Where not exists (select 1 from #IdsToDelete where id =a.RSum_Id)
 	  	  	  	  Order By  RSum_Id 
  	    	    	    	  DELETE b FROM #IdsToDelete b Join GB_RSum  a On  a.RSum_Id = b.id  WHERE a.Start_Time >='''+cast(@date as varchar) + '''
  	    	    	    	  IF (SELECT COUNT(*) FROM #IdsToDelete) < ' + cast(@BatchCutoff as varchar) + '
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' RSum_Id,Comment_Id FROM GB_RSum a where Start_time<'''+cast(@date as varchar) + '''
 	  	  	  	  	  and not exists(select 1 from #IdsToDelete where id = a.RSum_Id)
 	  	  	  	  	  Order By Start_Time
  	    	    	    	  END
'
  	    	  END
  	    	  SET @sql=  @sql + '
 	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  INSERT INTO @Commentids(CommentId)  	  SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null
  	    	   
  	    	  DELETE rsd FROM GB_RSum_Data rsd JOIN  #IdsToDelete b ON rsd.RSum_Id = b.id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE rs FROM GB_RSum rs JOIN  #IdsToDelete b ON rs.RSum_Id = b.id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	   '
  	  END
  	  else if @name='Timed_Event_Details'  
  	  begin
  	    	  IF @puid Is Not Null
  	    	    	  SET @sql= 'INSERT into #IdsToDelete (id) select'+@top+' TEDet_Id FROM Timed_Event_Details a where end_time<'''+cast(@date as varchar) + ''' 
 	  	  	  and not exists (Select  1 from #idsToDelete where id = a.TEDet_Id)
 	  	  	  and PU_Id='+cast(@puid as varchar)
  	    	  ELSE
  	    	  BEGIN
  	    	    	    	  SET @SQL = '
  	    	    	    	  Declare @MinPUId Int
  	    	    	    	  Declare @MinTime DateTime
  	    	    	    	  Declare @MinTime2 DateTime
  	    	    	    	  Declare @Data Table(Id Int,MinTime DateTime)
  	    	    	    	  Declare @StartId Int,@NextId Int
  	    	    	    	  SELECT @StartId = Min(PU_Id) From Prod_Units_base
  	    	    	    	  While @StartId Is Not Null
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT INTO @Data(Id,MinTime)
  	    	    	    	    	    	  SELECT @StartId,Min([End_Time])
  	    	    	    	    	    	    	  FROM Timed_Event_Details WHERE PU_Id = @StartId and End_Time IS Not Null
  	    	    	    	    	  Select @NextId = Null
  	    	    	    	    	  SELECT @NextId = Min(PU_Id) From Prod_Units_base WHERE  PU_Id > @StartId
  	    	    	    	    	  SELECT @StartId = @NextId
  	    	    	    	  END
  	    	    	    	  SELECT @MinTime = MIN(MinTime) FROM @Data WHERE MinTime is not null
  	    	    	    	  SELECT @MinPUId = MIN(Id) FROM @Data WHERE MinTime = @MinTime
  	    	    	    	  INSERT into #IdsToDelete (id) select'+@top+' TEDet_Id FROM Timed_Event_Details a
  	    	    	    	  WHERE [End_Time]<'''+cast(@date as varchar)+'''and End_Time is not null and PU_Id = @MinPUId
 	  	  	  	  and not exists (select 1 from #IdsToDelete  where id = a.TEDet_Id)
 	  	  	  	  order by [End_Time]
  	    	    	    	  WHILE ((SELECT COUNT(*) FROM #IdsToDelete) < ' + cast(@BatchCutoff as varchar) + ') and @MinPUId Is Not Null
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @MinTime2 = Null
  	    	    	    	    	  SET @MinPUId = Null
  	    	    	    	    	  SELECT @MinTime2 = MIN(MinTime) FROM @Data WHERE MinTime > @MinTime
  	    	    	    	    	  IF @MinTime2 Is Not Null
  	    	    	    	    	  BEGIN
  	    	    	    	    	    	  SELECT @MinPUId = MIN(Id) FROM @Data WHERE MinTime = @MinTime2
  	    	    	    	    	    	  SET @MinTime = @MinTime2
  	    	    	    	    	    	  INSERT into #IdsToDelete (id) select'+@top+' TEDet_Id FROM Timed_Event_Details a
  	    	    	    	    	    	  WHERE [End_Time]<'''+cast(@date as varchar)+'''and End_Time is not null and PU_Id = @MinPUId 
 	  	  	  	  	  	  and not exists (select 1 from #IdsToDelete  where id = a.TEDet_Id)
 	  	  	  	  	  	  order by [End_Time]
  	    	    	    	    	  END
  	    	    	    	  END
  	    	    	    	  '
  	    	  END
  	    	  SET @sql=@sql + '
 	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Action_Comment_Id FROM Timed_Event_Details ted
  	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	  WHERE Action_Comment_Id Is Not Null
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Cause_Comment_Id FROM Timed_Event_Details  ted
  	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	  WHERE Cause_Comment_Id Is Not Null
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Research_Comment_Id FROM Timed_Event_Details  ted
  	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	  WHERE Research_Comment_Id Is Not Null '
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Timed_Event_Details]') and Name = N'Summary_Cause_Comment_Id')
  	    	  BEGIN
  	    	    	  SET @sql=@sql + '
  	    	    	    	    	    	    	  INSERT INTO @Commentids(CommentId)
  	    	    	    	    	    	    	    	  SELECT Summary_Research_Comment_Id FROM Timed_Event_Details  ted
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Summary_Research_Comment_Id Is Not Null 
  	    	    	    	    	    	    	  INSERT INTO @Commentids(CommentId)
  	    	    	    	    	    	    	    	  SELECT Summary_Cause_Comment_Id FROM Timed_Event_Details  ted
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Summary_Cause_Comment_Id Is Not Null '
  	    	  END
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Timed_Event_Details]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @sql=@sql + '
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct Signature_Id FROM Timed_Event_Details  ted
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct Signature_Id FROM Timed_Event_Detail_History  tedh
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON tedh.TEDet_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	  END
  	    	  SET @sql=@sql + '
  	    	  SELECT @MaxEventDate = Max(end_time) From Timed_Event_Details  ted
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE end_time is not null
  	    	   
  	    	  DELETE tedh FROM Timed_Event_Detail_History  tedh
  	    	    	  JOIN  #IdsToDelete b ON tedh.TEDet_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE ted FROM Timed_Event_Details ted
  	    	    	  JOIN  #IdsToDelete b ON ted.TEDet_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected) '
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	  BEGIN
  	    	    	  SET @sql = @sql + '
  	    	    	    	   
  	    	    	    	  DELETE tf FROM Table_Fields_Values  tf
  	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 3
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    '
  	    	  END
  	    	  SET @sql = @sql + @checkaffected + '
  	    	  begin '
  	    	    	    	  SET @SQL = @SQL + ' 
  	    	    	    	  DELETE FROM #IdsToDelete
  	    	    	    	  SET @MinId = NULL
  	    	    	    	  SELECT @MinId = Min(TEDet_Id) FROM Timed_Event_Details
  	    	    	    	  IF @MinId Is NUll SELECT @MinId = MAX(TEDet_Id) + 1 FROM Timed_Event_Detail_History 
  	    	    	    	  INSERT into #IdsToDelete (id) 
 	  	  	  	  Select distinct  TEDet_Id From (
 	  	  	  	  select'+@top+' TEDet_Id 
  	    	    	    	  FROM Timed_Event_Detail_History a
  	    	    	    	  where TEDet_Id < @MinId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete  where id = a.TEDet_Id))T'
  	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Timed_Event_Detail_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @SQL=@SQL + ' 
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Timed_Event_Detail_History  tedh
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON tedh.TEDet_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	    	    	  END
  	    	    	    	  SET @SQL = @SQL + '
  	    	    	  DELETE tedh FROM Timed_Event_Detail_History  tedh JOIN  #IdsToDelete b ON tedh.TEDet_Id = b.id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  end
  	    	   '
  	    	  SELECT @VariableTypes = '2'
  	  end
  	  else if @name='Waste_Event_Details'  
  	  BEGIN
  	    	  IF @puid Is Not NULL
  	    	    	  SET @SQL = ' INSERT into #IdsToDelete (id) select'+@top+' WED_Id 
  	    	    	    	    	    	    	  FROM Waste_Event_Details a where [timestamp]<'''+cast(@date as varchar)+''' and event_id is not null 
 	  	  	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.WED_Id)
 	  	  	  	  	  	  	  and PU_Id='+cast(@puid as varchar) + 'order by [timestamp] '
  	    	  ELSE
  	    	    	  BEGIN
  	    	    	    	  SET @SQL = '
  	    	    	    	  Declare @MinPUId Int
  	    	    	    	  Declare @MinTime DateTime
  	    	    	    	  Declare @Data Table(Id Int,MinTime DateTime)
  	    	    	    	  Declare @StartId Int,@NextId Int
  	    	    	    	  SELECT @StartId = Min(PU_Id) From Prod_Units_base
  	    	    	    	  While @StartId Is Not Null
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT INTO @Data(Id,MinTime)
  	    	    	    	    	    	  SELECT @StartId,Min([timestamp])
  	    	    	    	    	    	    	  FROM Waste_Event_Details WHERE PU_Id = @StartId
  	    	    	    	    	  Select @NextId = Null
  	    	    	    	    	  SELECT @NextId = Min(PU_Id) From Prod_Units_base WHERE  PU_Id > @StartId
  	    	    	    	    	  SELECT @StartId = @NextId
  	    	    	    	  END
  	    	    	    	  SELECT @MinTime = MIN(MinTime) FROM @Data WHERE MinTime is not null
  	    	    	    	  SELECT @MinPUId = MIN(Id) FROM @Data WHERE MinTime = @MinTime
  	    	    	    	  INSERT into #IdsToDelete (id) select'+@top+' WED_Id FROM Waste_Event_Details a
  	    	    	    	  WHERE [timestamp]<'''+cast(@date as varchar)+''' and PU_Id = @MinPUId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.WED_Id)
 	  	  	  	  order by [timestamp]'
  	    	    	  END
 	  	 SET @SQL = @SQL +'
 	  	 
 	  	 IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
 	  	 '
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Waste_Event_Details]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct  Signature_Id FROM Waste_Event_Details wed 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON wed.WED_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null 
  	    	    	    	  INSERT INTO #Esigs(SignatureId)  
  	    	    	    	    	    	  SELECT distinct Signature_Id FROM Waste_Event_Detail_History wedh 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON wedh.WED_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	  END
  	    	  SET @SQL=@SQL + '
  	    	  SELECT @MaxEventDate = Max(Timestamp) From Waste_Event_Details wed JOIN  #IdsToDelete b ON wed.WED_Id = b.id
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Action_Comment_Id FROM Waste_Event_Details wed JOIN  #IdsToDelete b ON wed.WED_Id = b.id WHERE Action_Comment_Id Is Not Null
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Cause_Comment_Id FROM Waste_Event_Details wed JOIN  #IdsToDelete b ON wed.WED_Id = b.id WHERE Cause_Comment_Id Is Not Null
  	    	  INSERT INTO @Commentids(CommentId)
  	    	    	  SELECT Research_Comment_Id FROM Waste_Event_Details wed JOIN  #IdsToDelete b ON wed.WED_Id = b.id WHERE Research_Comment_Id Is Not Null
  	    	  IF (select count(0) from #IdsToDelete ) = 0
 	  	  Return;
  	    	  DELETE wedh FROM Waste_Event_Detail_History wedh JOIN  #IdsToDelete b ON wedh.WED_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE wed FROM Waste_Event_Details wed JOIN #IdsToDelete b ON wed.WED_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected) '
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	  BEGIN
  	    	    	  SET @sql = @sql + '
  	    	    	    	   
  	    	    	    	  DELETE tf FROM Table_Fields_Values  tf
  	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 4
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	  '
  	    	  END
  	    	  SET @sql = @sql + @checkaffected + '
  	    	  BEGIN '
  	    	    	  IF @puid Is NULL
  	    	    	  BEGIN
  	    	    	    	  SET @SQL = @SQL + ' SELECT @MinId = Min(WED_Id) FROM Waste_Event_Details'
  	    	    	  END
  	    	    	  ELSE
  	    	    	  BEGIN
  	    	    	    	  SET @SQL = @SQL + ' SELECT @MinId = Min(WED_Id) FROM Waste_Event_Details WHERE event_id is not null and PU_Id='+cast(@puid as varchar) 
  	    	    	  END
  	    	    	  SET @SQL = @SQL + '
  	    	    	    	  DELETE FROM #IdsToDelete
  	    	    	    	  INSERT into #IdsToDelete (id) Select Distinct WED_Id from (select'+@top+' WED_Id 
  	    	    	    	  FROM Waste_Event_Detail_History a
  	    	    	    	  where WED_Id < @MinId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.WED_Id)) T'
  	    	    	    	  IF @puid Is Not NULL
  	    	    	    	    	  SET @SQL = @SQL + ' and event_id is not null and PU_Id='+cast(@puid as varchar)
  	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Waste_Event_Detail_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @SQL=@SQL + ' 
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Waste_Event_Detail_History wedh 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON wedh.WED_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	    	    	  END
  	    	    	    	  SET @SQL = @SQL + '
  	    	    	  DELETE wedh FROM Waste_Event_Detail_History wedh JOIN #IdsToDelete b ON wedh.WED_Id = b.id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  END
  	    	    '  	  
  	    	  SELECT @VariableTypes = '3'
  	  END
  	  else if @name='Events'  
  	  begin
  	    	  IF @puid Is Not NULL
  	    	    	  SET @SQL = '
  	    	    	    	  INSERT #IdsToDelete (id, CmtId) select'+@top+' Event_Id,Comment_Id FROM Events a where [timestamp]<'''+cast(@date as varchar)+''' 
  	    	    	    	    	    	  and PU_Id='+cast(@puid as varchar) + 
 	  	  	  	  	  	  ' and not exists(Select 1 from #IdsToDelete where id = a.Event_Id) order by [timestamp]'
  	    	  ELSE
  	    	  BEGIN
  	    	    	    	  SET @SQL = '
  	    	    	    	  Declare @MinPUId Int
  	    	    	    	  Declare @MinTime DateTime
  	    	    	    	  Declare @Data Table(Id Int,MinTime DateTime)
  	    	    	    	  Declare @StartId Int,@NextId Int
  	    	    	    	  DECLARE @MinEventId  	  Int
  	    	    	    	  SELECT @StartId = Min(PU_Id) From Prod_Units_base
  	    	    	    	  While @StartId Is Not Null
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT INTO @Data(Id,MinTime)
  	    	    	    	    	    	  SELECT @StartId,Min([timestamp])
  	    	    	    	    	    	    	  FROM Events WHERE PU_Id = @StartId 
  	    	    	    	    	  Select @NextId = Null
  	    	    	    	    	  SELECT @NextId = Min(PU_Id) From Prod_Units_base WHERE  PU_Id > @StartId
  	    	    	    	    	  SELECT @StartId = @NextId
  	    	    	    	  END
  	    	    	    	  SELECT @MinTime = MIN(MinTime) FROM @Data WHERE MinTime is not null
  	    	    	    	  SELECT @MinPUId = MIN(Id) FROM @Data WHERE MinTime = @MinTime
  	    	    	    	  SELECT @MinEventId = Event_Id - 1  From Events Where PU_Id = @MinPUId and Timestamp = @MinTime
  	    	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' Event_Id,Comment_Id FROM Events  a
  	    	    	    	  WHERE Event_Id >  @MinEventId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Event_Id)
 	  	  	  	  order by Event_Id
  	    	    	    	  DELETE a FROM #IdsToDelete a JOIN Events b On b.Event_Id = a.Id And b.Timestamp >= ''' + cast(@date as varchar)+ '''
  	    	    	    	  IF (Select Count(*) From #IdsToDelete) < ' + cast(@BatchCutoff as varchar) + '
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' Event_Id,Comment_Id FROM Events a
  	    	    	    	    	    	  WHERE Pu_Id =  @MinPUId 
 	  	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Event_Id)
 	  	  	  	  	  	  and Timestamp <   ''' + cast(@date as varchar)+ '''
  	    	    	    	  END
  	    	    	    	  DELETE a FROM #IdsToDelete a JOIN Events b On b.Event_Id = a.Id And b.Timestamp >= ''' + cast(@date as varchar)+ '''
'
  	    	  END
  	    	  SET @sql= @SQL + '
 	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  SELECT @MaxEventDate = Max(TimeStamp) From Events e JOIN #IdsToDelete b ON e.Event_Id = b.id 
  	    	  INSERT INTO @Commentids (CommentId)  	  SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null
  	    	  INSERT INTO @Commentids (CommentId) SELECT Comment_Id FROM Event_Details ed JOIN #IdsToDelete b ON ed.Event_Id = b.id  WHERE Comment_Id is not null
  	    	  DECLARE @CompID Table(Id Int)
  	    	  DECLARE @PIEH Table(Id Int)
  	    	  INSERT INTO @CompID (id) SELECT Component_Id FROM Event_Components a Join #IdsToDelete b on b.id = a.Event_Id
  	    	  INSERT INTO @CompID (id) SELECT Component_Id FROM Event_Components a Join #IdsToDelete b on b.id = a.Source_Event_Id
  	    	  '
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Event_Details]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Event_Detail_History edh 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON edh.Event_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null 
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Event_Details ed 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON ed.Event_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	  END
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Events]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + '   	    	  
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Event_History eh 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON eh.Event_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null 
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Events e 
  	    	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON e.Event_Id = b.id
  	    	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	  END
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Event_Components]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + '   	    	  
   	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Event_Components a JOIN @CompID b on b.id = a.Component_Id 
  	    	    	    	    	  WHERE a.Signature_Id Is Not Null
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM Event_Component_History a JOIN @CompID b on b.id = a.Component_Id  WHERE a.Signature_Id Is Not Null '
  	    	  END
  	    	  SET @SQL=@SQL + '   	  
  	    	  IF (Select count(0) from #IdsToDelete) =0
 	  	  RETURN;
  	    	  DELETE edh FROM Event_Detail_History edh JOIN #IdsToDelete b ON edh.Event_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE ed FROM Event_Details ed JOIN #IdsToDelete b ON ed.Event_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE eh FROM Event_History eh JOIN #IdsToDelete b ON eh.Event_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected) 
  	    	  DELETE a FROM Event_Component_History a JOIN @CompID b on b.id =  a.Component_Id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE a FROM Event_Components a JOIN @CompID b on b.id =  a.Component_Id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  INSERT INTO @PIEH(Id) SELECT Input_Event_History_Id FROM PrdExec_Input_Event_History  peh JOIN #IdsToDelete b ON peh.Event_Id = b.id
  	    	  DELETE peh FROM PrdExec_Input_Event_History  peh JOIN @PIEH b ON peh.Input_Event_History_Id = b.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  UPDATE p SET Event_Id = Null
  	    	    	  FROM PrdExec_Input_Event p 
  	    	    	  JOIN #IdsToDelete b ON p.Event_Id = b.id '
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[User_Defined_Events]') and Name = N'Event_Id')
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + '   	    	  
  	    	    	    	   
  	    	    	    	  UPDATE ude SET Event_Id=null 
  	    	    	    	    	  FROM User_Defined_Events ude
  	    	    	    	    	  JOIN #IdsToDelete b On b.id = ude.Event_Id 
  	    	    	    	   '
  	    	  END
  	    	  SET @SQL=@SQL + '   	    	  
  	    	    	    	  update e SET Source_Event=null FROM Events e JOIN #IdsToDelete b On b.id = e.Source_Event '
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Event_Status_Transitions]'))
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	   
  	    	    	  DELETE a FROM Event_Status_Transitions a JOIN #IdsToDelete i  on i.id = a.Event_Id 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	   '
  	    	  END
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PrdExec_Output_Event]'))
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	   
  	    	    	  UPDATE p SET Event_Id = Null FROM PrdExec_Output_Event p 
  	    	    	  JOIN #IdsToDelete b ON p.Event_Id = b.id 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	    '
  	    	  END
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PrdExec_Output_Event_Transitions]'))
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	   
  	    	    	  DELETE peh FROM PrdExec_Output_Event_Transitions  peh JOIN #IdsToDelete b ON peh.Event_Id = b.id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	    '
  	    	  END
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PrdExec_Output_Event_History]'))
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	   
  	    	    	  DELETE peh FROM PrdExec_Output_Event_History  peh JOIN #IdsToDelete b ON peh.Event_Id = b.id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	    '
  	    	  END
  	    	  SET @sql2 = ' '
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	  BEGIN
  	    	    	  SET @sql2 = '
  	    	    	   
  	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 14 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  DELETE tf FROM Table_Fields_Values  tf
  	    	    	    	    	  JOIN @CompID i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 10
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	  JOIN Waste_Event_Details w on w.WED_Id = tf.keyId
  	    	    	    	  JOIN #IdsToDelete b on b.id = w.Event_Id
  	    	    	    	  WHERE TableId = 4 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 1
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  DELETE tf FROM Table_Fields_Values  tf
  	    	    	    	    	  JOIN @PIEH i  on i.id = tf.KeyId 
  	    	    	    	    	  WHERE tf.TableId = 6
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	    '
  	     END
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PrdExec_Input_Event_Transitions]'))
  	    	  BEGIN
  	    	    	  SET @sql2=@sql2 + '  	  
  	    	    	   
  	    	    	  DELETE a FROM PrdExec_Input_Event_Transitions a  	  JOIN #IdsToDelete i  on i.id = a.Event_Id 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	    '
  	    	  END
  	    	  SET @sql2=@sql2 + '  	    	  
  	    	  DELETE wedh FROM Waste_Event_Detail_History wedh 
  	    	    	  JOIN Waste_Event_Details wed On wed.WED_Id = wedh.WED_Id
  	    	    	  JOIN #IdsToDelete b On b.id = wed.Event_Id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE wed FROM Waste_Event_Details wed JOIN #IdsToDelete b On b.id = wed.Event_Id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE ept FROM Event_PU_Transitions ept JOIN #IdsToDelete b On b.id = ept.Event_Id 
  	    	  DELETE e FROM Events e JOIN #IdsToDelete b ON b.id = e.Event_Id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected) '
  	    	  SET @SQL2=@SQL2 + @checkaffected+'
  	    	  begin '
  	    	    	  SET @SQL2 = @SQL2 + ' 
  	    	    	    	  SET @MinId = Null 
  	    	    	    	  SELECT @MinId = Min(Event_Id) FROM Events
  	    	    	    	  INSERT into #IdsToDelete (id) 
 	  	  	  	  Select distinct Event_Id from (
 	  	  	  	  select'+@top+' Event_Id 
  	    	    	    	   FROM Event_Detail_History a
  	    	    	    	  WHERE Event_Id < @MinId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Event_Id))T
  	    	    	  DELETE eh FROM Event_Detail_History eh JOIN #IdsToDelete b ON b.id = eh.Event_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  end '
  	    	  SET @SQL2=@SQL2 + @checkaffected+'
  	    	  begin '
  	    	    	  SET @SQL2 = @SQL2 + ' 
  	    	    	    	  SET @MinId = Null 
  	    	    	    	  SELECT @MinId = Min(Component_Id) FROM Event_Components
  	    	    	    	  IF @MinId Is Null SELECT @MinId = Max(Component_Id) + 1 From Event_Component_History 
  	    	    	    	  INSERT into @CompID (id) select'+@top+' Component_Id 
  	    	    	    	   FROM Event_Component_History WHERE Component_Id < @MinId 
  	    	    	  DELETE eh FROM Event_Component_History eh JOIN @CompID b ON b.id = eh.Component_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  end '
  	    	  SET @SQL2=@SQL2+@checkaffected+'
  	    	  begin'
  	    	    	  SET @SQL2 = @SQL2 + ' 
  	    	    	  SET @MinId = Null 
  	    	    	  SELECT @MinId = Min(Event_Id) FROM Events
  	    	    	  IF @MinId Is Null SELECT @MinId = Max(Event_Id) + 1 From Event_History 
  	    	    	  INSERT into #IdsToDelete (id) 
 	  	  	  Select distinct Event_Id from (
 	  	  	  select'+@top+' Event_Id 
  	    	    	    	  FROM Event_History a
  	    	    	    	  where Event_Id < @MinId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Event_Id)) T
  	    	    	  DELETE eh FROM Event_History eh JOIN #IdsToDelete b ON b.id = eh.Event_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  end '
  	    	  SET @SQL2=@SQL2+@checkaffected+'
  	    	  begin'
  	    	    	  SET @SQL2 = @SQL2 + '   	  SELECT @MinId = Min(Event_Id) FROM Events '
  	    	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Event_Status_Transitions]'))
  	    	    	  BEGIN
  	    	    	    	  SET @SQL2=@SQL2 + '   	    	    	  
  	    	    	    	  INSERT into #IdsToDelete (id) Select Distinct Event_Id from (select'+@top+' Event_Id 
  	    	    	    	    	  FROM Event_Status_Transitions a
  	    	    	    	    	  where Event_Id < @MinId 
 	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Event_Id)) T
  	    	    	    	   
  	    	    	    	  DELETE a FROM Event_Status_Transitions a JOIN #IdsToDelete i  on i.id = a.Event_Id 
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    '
  	    	    	  END
  	    	  SET @SQL2 = @SQL2 + ' end '
  	    	  SET @sql2=@sql2+'
  	    	    '
  	    	  SELECT @VariableTypes = '1,26'
  	  end
  	  else if @name='User_Defined_Events' 
  	  begin
  	    	  IF @puid Is Not NULL
  	    	    	  SET @sql='INSERT #IdsToDelete (id, CmtId) select'+@top+' UDE_Id,Comment_Id FROM User_Defined_Events a where End_Time<'''+cast(@date as varchar)+''' and not exists(select 1 from #IdsToDelete where id=a.UDE_id) and PU_Id='+cast(@puid as varchar)
  	    	  ELSE
  	    	  BEGIN
  	    	    	    	  SET @SQL = '
  	    	    	    	  Declare @MinPUId Int
  	    	    	    	  Declare @MinTime DateTime
  	    	    	    	  Declare @Data Table(Id Int,MinTime DateTime)
  	    	    	    	  Declare @StartId Int,@NextId Int
  	    	    	    	  SELECT @StartId = Min(PU_Id) From Prod_Units_base
  	    	    	    	  While @StartId Is Not Null
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT INTO @Data(Id,MinTime)
  	    	    	    	    	    	  SELECT @StartId,Min(End_Time)
  	    	    	    	    	    	    	  FROM User_Defined_Events WHERE PU_Id = @StartId and End_Time Is Not Null
  	    	    	    	    	  Select @NextId = Null
  	    	    	    	    	  SELECT @NextId = Min(PU_Id) From Prod_Units_base WHERE  PU_Id > @StartId
  	    	    	    	    	  SELECT @StartId = @NextId
  	    	    	    	  END
  	    	    	    	  SELECT @MinTime = MIN(MinTime) FROM @Data WHERE MinTime is not null
  	    	    	    	  SELECT @MinPUId = MIN(Id) FROM @Data WHERE MinTime = @MinTime
  	    	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' UDE_Id,Comment_Id FROM User_Defined_Events a
  	    	    	    	  WHERE End_Time <'''+cast(@date as varchar)+''' and PU_Id = @MinPUId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.UDE_Id)
 	  	  	  	  order by End_Time'
  	    	  END
  	    	  SET @sql= @SQL + '
 	  	  IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	  SELECT @MaxEventDate = Max(End_Time) From User_Defined_Events ude JOIN #IdsToDelete b on b.id = ude.UDE_Id
  	    	  INSERT INTO @Commentids (CommentId)  	  SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null
  	    	  INSERT INTO @Commentids (CommentId) 
  	    	    	  SELECT  Action_Comment_Id FROM User_Defined_Events ude JOIN #IdsToDelete b on b.id = ude.UDE_Id WHERE Action_Comment_Id is not null
  	    	  INSERT INTO @Commentids (CommentId) SELECT  Cause_Comment_Id FROM User_Defined_Events ude JOIN #IdsToDelete b on b.id = ude.UDE_Id WHERE Cause_Comment_Id is not null
  	    	  INSERT INTO @Commentids (CommentId) SELECT  Research_Comment_Id FROM User_Defined_Events ude JOIN #IdsToDelete b on b.id = ude.UDE_Id WHERE Research_Comment_Id is not null'
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[User_Defined_Events]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + '   	    	  
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM User_Defined_Events ude JOIN #IdsToDelete b on b.id = ude.UDE_Id WHERE Signature_Id Is Not Null
  	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	  SELECT distinct Signature_Id FROM User_Defined_Event_History a JOIN #IdsToDelete b on b.id = a.UDE_Id WHERE Signature_Id Is Not Null '
  	    	  END
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	  BEGIN
  	    	    	  SET @sql= @SQL + '
  	    	    	    	    	    	  
  	    	    	    	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	    	    	    	  JOIN #IdsToDelete i  on i.id = tf.KeyId 
  	    	    	    	    	    	    	    	  WHERE tf.TableId = 11 
  	    	    	    	    	    	  SET @affected=@@rowcount
  	    	    	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	    	   '
  	    	  END
  	    	  SET @sql= @SQL + '
  	    	   
  	    	  DELETE ude FROM User_Defined_Event_History  ude JOIN #IdsToDelete b on b.id = ude.UDE_Id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected) '
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[User_Defined_Events]') and Name = N'Parent_UDE_Id')
  	    	  BEGIN
  	    	    	  SET @SQL=@SQL + ' 
  	    	    	    	  Update ude SET Parent_UDE_Id =null 
  	    	    	    	    	  FROM User_Defined_Events ude
  	    	    	    	    	  JOIN #IdsToDelete b on b.id = ude.Parent_UDE_Id '
  	    	  END
  	    	  SET @sql= @SQL + '
  	    	  DELETE ude FROM User_Defined_Events ude JOIN #IdsToDelete b on b.id = ude.UDE_Id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected) '
  	    	  SET @SQL=@SQL + @checkaffected+'
  	    	  begin '
  	    	    	  IF @puid Is NULL
  	    	    	  BEGIN
  	    	    	    	  SET @SQL = @SQL + ' SELECT @MinId = Min(UDE_Id) FROM User_Defined_Events '
  	    	    	  END
  	    	    	  ELSE
  	    	    	  BEGIN
  	    	    	    	  SET @SQL = @SQL + ' SELECT @MinId = Min(UDE_Id) FROM User_Defined_Events WHERE  PU_Id='+cast(@puid as varchar) 
  	    	    	  END
  	    	    	  SET @SQL = @SQL + ' 
  	    	    	    	  DELETE FROM #IdsToDelete
  	    	    	    	  INSERT into #IdsToDelete (id) Select distinct UDE_Id from (select'+@top+' UDE_Id 
  	    	    	    	  FROM User_Defined_Event_History a
  	    	    	    	  where UDE_Id < @MinId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.UDE_Id))T'
  	    	    	    	  IF @puid Is Not NULL
  	    	    	    	    	  SET @SQL = @SQL + ' and PU_Id='+cast(@puid as varchar)
  	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[User_Defined_Event_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @SQL=@SQL + '  	    	    	  
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct  Signature_Id FROM User_Defined_Event_History  ude 
  	    	    	    	    	    	    	    	  JOIN #IdsToDelete b on b.id = ude.UDE_Id WHERE Signature_Id Is Not Null '
  	    	    	    	  END
  	    	    	  SET @SQL = @SQL + ' 
  	    	    	  DELETE ude FROM User_Defined_Event_History ude JOIN #IdsToDelete b on b.id = ude.UDE_Id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	  end '
  	    	  SET @SQL=@SQL+'
  	    	   '
  	    	  SELECT @VariableTypes = '14'
  	  end
  	  else if @name='Production_Starts' --unit based
  	  begin
  	    	  IF @puid Is Not NUll
  	    	  BEGIN
  	    	    	  SET @sql='
  	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' Start_Id,Comment_Id 
  	    	    	    	  FROM Production_Starts a
  	    	    	    	  where end_time<'''+cast(@date as varchar)+''' and start_time>''1/1/1970'' 
 	  	  	  	  and not exists (select 1 from #idsToDelete where id = a.Start_Id)
 	  	  	  	  and PU_Id='+cast(@puid as varchar)+' order by end_time
 	  	  	 IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  	 REturn;
  	    	    	  INSERT INTO @Commentids (CommentId)  	  SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null '
  	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Production_Starts]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	  BEGIN
  	    	    	    	  SET @SQL=@SQL + '   	    	    	  
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct  Signature_Id FROM Production_Starts a 
  	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON a.Start_Id = b.id
  	    	    	    	    	    	    	    	  WHERE  Signature_Id Is Not Null
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Production_Starts_History a 
  	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON a.Start_Id = b.id
  	    	    	    	    	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	    	  END
  	    	    	  SET @SQL=@SQL + '
  	    	    	   
  	    	    	  DELETE a FROM Production_Starts_History a JOIN  #IdsToDelete b ON a.Start_Id = b.id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  SELECT @MaxEventDate = Max(end_time) From Production_Starts a JOIN  #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	  DELETE a FROM Production_Starts a JOIN  #IdsToDelete b ON a.Start_Id = b.id
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  '+@checkaffected+'
  	    	    	  begin
  	    	    	    	  DELETE FROM #IdsToDelete
  	    	    	    	  SELECT @MinId = Min(Start_Id) FROM Production_Starts WHERE PU_Id='+cast(@puid as varchar) + '
  	    	    	    	  INSERT into #IdsToDelete (id) Select distinct Start_Id from (select'+@top+' Start_Id FROM Production_Starts_History a where PU_Id='+cast(@puid as varchar) + ' 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Start_Id)
 	  	  	  	  and Start_Id < @MinId) T '
  	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Production_Starts_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @SQL=@SQL + '   	    	    	  
  	    	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	    	  SELECT distinct  Signature_Id FROM Production_Starts_History a 
  	    	    	    	    	    	    	    	  JOIN  #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	    	    	    	    	    	  WHERE  Signature_Id Is Not Null '
  	    	    	    	  END
  	    	    	    	  SET @SQL=@SQL + '
  	    	    	    	  DELETE a FROM Production_Starts_History a JOIN #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	  end
  	    	    	   
  	    	    	  update 
  	    	    	    	  Production_Starts 
  	    	    	  SET 
  	    	    	    	  End_Time=(
  	    	    	    	    	  SELECT min(Start_Time) FROM Production_Starts where PU_Id='+cast(@puid as varchar)+' and Start_Time>''1/1/1970''
  	    	    	    	  )
  	    	    	  where 
  	    	    	    	  Start_Time=''1/1/1970''
  	    	    	    	  and PU_Id='+cast(@puid as varchar)+'
  	    	    	   '
  	    	    	  SELECT @VariableTypes = '4,5'
  	    	  END
  	    	  ELSE
  	    	  BEGIN
  	    	    	  SET @Sql = ' DECLARE @PUids TABLE(MyCount Int Identity (1,1),PUid int)'
  	    	    	  SET @Sql =@SQL + ' DECLARE @Start Int,@End Int,@CurrentPu Int'
  	    	    	  SET @sql=@SQL + '
  	    	    	  INSERT into #IdsToDelete (id, CmtId) select'+@top+' Start_Id,Comment_Id 
  	    	    	    	  FROM Production_Starts a
  	    	    	    	  where end_time<'''+cast(@date as varchar)+''' and start_time> ''1/1/1970'' 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Start_Id)
 	  	  	  	  order by end_time
 	  	  	 IF (Select count(0) from #IdsToDelete) = 0
 	  	  	  REturn;
  	    	    	  INSERT INTO @Commentids (CommentId)  	  SELECT CmtId FROM #IdsToDelete WHERE CmtId Is Not Null '
  	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Production_Starts]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	  BEGIN
  	    	    	    	  SET @SQL=@SQL + '   	    	    	  
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Production_Starts a JOIN #IdsToDelete b ON a.Start_Id = b.id WHERE Signature_Id Is Not Null
  	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Production_Starts_History a JOIN #IdsToDelete b ON a.Start_Id = b.id WHERE Signature_Id Is Not Null '
  	    	    	  END
  	    	    	  SET @SQL=@SQL + '
  	    	    	  INSERT INTO @PUids SELECT Distinct PU_Id FROM Production_Starts a JOIN #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	   
  	    	    	  DELETE a FROM Production_Starts_History a JOIN #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  DELETE a FROM Production_Starts a JOIN #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	  SET @affected=@@rowcount
  	    	    	  INSERT into @Qty values (@affected)
  	    	    	  '+@checkaffected+'
  	    	    	  begin
  	    	    	    	  DELETE FROM #IdsToDelete
  	    	    	    	  SELECT @MinId = Min(Start_Id) FROM Production_Starts
  	    	    	    	  INSERT into #IdsToDelete (id) 
 	  	  	  	  Select distinct start_Id from (
 	  	  	  	  select'+@top+' Start_Id
  	    	    	    	  FROM Production_Starts_History a
  	    	    	    	  where Start_Id < @MinId 
 	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.Start_Id)) T
 	  	  	  	  '
  	    	    	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Production_Starts_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	    	    	  BEGIN
  	    	    	    	    	  SET @SQL=@SQL + '   	    	    	  
  	    	    	    	    	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	    	    	    	    	  SELECT distinct Signature_Id FROM Production_Starts_History a JOIN #IdsToDelete b ON a.Start_Id = b.id WHERE Signature_Id Is Not Null '
  	    	    	    	  END
  	    	    	    	  SET @SQL=@SQL + '
  	    	    	    	  DELETE a FROM Production_Starts_History a JOIN #IdsToDelete b ON a.Start_Id = b.id 
  	    	    	    	  SET @affected=@@rowcount
  	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	  end
  	    	    	   
  	    	    	  Set @Start = 1
  	    	    	  SELECT @End = Max(MyCount) FROM @PUids
  	    	    	  IF @End is Null Set @End = 0
  	    	    	  WHILE @Start <= @End
  	    	    	  BEGIN
  	    	    	    	  SELECT @CurrentPu = PUid FROM @PUids Where MyCount = @Start
  	    	    	    	  update Production_Starts SET End_Time=(
  	    	    	    	    	  SELECT min(Start_Time) FROM Production_Starts where PU_Id= cast(@CurrentPu as varchar) and Start_Time>''1/1/1970'')
  	    	    	    	    	  where Start_Time=''1/1/1970''and PU_Id= cast(@CurrentPu as varchar) 
  	    	    	    	  SET @Start = @Start + 1
  	    	    	  END
  	    	    	   '
  	    	  END
  	  end
  	  ELSE IF @name='OEEAggregation'
  	  BEGIN
  	    	  IF @puid Is Not Null
  	    	    	  SET @sql='INSERT into #IdsToDelete (id) select'+@top+' OEEAggregation_Id FROM OEEAggregation a where Start_time<'''+cast(@date as varchar) + ''' 
 	  	  	  and not exists (select 1 from #IdsToDelete where id= a.OEEAggregation_Id)
 	  	  	  and PU_Id='+ Cast(@puid as varchar) +
  	    	    	    	   'order by Start_Time'
  	    	  else
  	    	  BEGIN
  	    	    	  SET @sql='
  	    	    	    	  INSERT into #IdsToDelete (id) select'+@top+' OEEAggregation_Id FROM OEEAggregation a 
 	  	  	  	  where not exists (select 1 from #IdsToDelete where id= a.OEEAggregation_Id)
 	  	  	  	  Order By  OEEAggregation_Id 
  	    	    	    	  DELETE b FROM #IdsToDelete b Join OEEAggregation  a On  a.OEEAggregation_Id = b.id  WHERE a.Start_Time >='''+cast(@date as varchar) + '''
  	    	    	    	  IF (SELECT COUNT(*) FROM #IdsToDelete) < ' + cast(@BatchCutoff as varchar) + '
  	    	    	    	  BEGIN
  	    	    	    	    	  INSERT into #IdsToDelete (id) select'+@top+' OEEAggregation_Id FROM OEEAggregation a where Start_time<'''+cast(@date as varchar) + '''
 	  	  	  	  	  and not exists (select 1 from #IdsToDelete where id = a.OEEAggregation_Id)
 	  	  	  	  	  Order By Start_Time
  	    	    	    	  END
'
  	    	  END
  	    	  SET @sql=  @sql + '
  	    	  DELETE oa FROM OEEAggregation oa JOIN  #IdsToDelete b ON oa.OEEAggregation_Id = b.id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
'
  	  END
  	  IF @PUId is Not Null AND @VariableTypes <> ''
  	  BEGIN
  	    	  SET @TestDeleteSql =  ' 
  	    	  DECLARE @TestIds TABLE(id BigInt,CmtId int null)
  	    	   
  	    	  INSERT into @TestIds (id, CmtId)
  	    	  SELECT Test_Id,t.Comment_Id FROM Tests t
  	    	  JOIN Variables_BAse  v on t.Var_Id=v.Var_Id and v.event_type IN ('+ @VariableTypes + ')
  	    	  JOIN Prod_Units_base pu on pu.PU_Id = v.PU_Id  and (pu.Master_Unit ='+cast(@puid as varchar) + ' or pu.PU_Id = '  +cast(@puid as varchar) +')
  	    	  WHERE  t.Result_On <=  cast(@MaxEventDate as varchar)'
  	    	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Tests]') and Name = N'Signature_Id')  AND @DoEsig = 1
  	    	  BEGIN
  	    	    	  SET @TestDeleteSql = @TestDeleteSql + '
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct Signature_Id FROM Tests t
  	    	    	    	  JOIN  @TestIds b ON t.Test_Id = b.id 
  	    	    	    	  WHERE Signature_Id Is Not Null 
  	    	    	  INSERT INTO #Esigs(SignatureId)
  	    	    	    	  SELECT distinct Signature_Id FROM Test_History th
  	    	    	    	  JOIN  @TestIds b ON th.Test_Id = b.id 
  	    	    	    	  WHERE Signature_Id Is Not Null '
  	    	  END
  	    	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
  	    	  BEGIN
  	    	    	  SET @TestDeleteSql = @TestDeleteSql + '
  	    	    	    	    	   
  	    	    	    	    	  DELETE tf FROM Table_Fields_Values tf
  	    	    	    	    	    	  JOIN @TestIds i  on i.id = tf.KeyId 
  	    	    	    	    	    	  WHERE tf.TableId = 42
  	    	    	    	    	  SET @affected=@@rowcount
  	    	    	    	    	  INSERT into @Qty values (@affected)
  	    	    	    	    	   '
  	    	  END
  	    	  SET @TestDeleteSql = @TestDeleteSql + '
 	  	  DELETE a FROM Tests a JOIN @TestIds b ON a.Test_Id = b.id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE a FROM Test_History a JOIN @TestIds b ON a.Test_Id = b.id 
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  DELETE a FROM Array_Data a JOIN Tests ts on a.Array_Id=ts.Array_Id JOIN @TestIds x on ts.Test_Id=x.id
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  
  	    	  INSERT INTO @Commentids (CommentId)  	  SELECT CmtId FROM @TestIds WHERE CmtId is not Null 
  	    	   
 '
  	  END
  	  ELSE
  	  BEGIN
  	    	  SELECT @TestDeleteSql = ''
  	  END
  	  SELECT @sqlafter = ' '
  	  If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Comments]') and Name = N'TopOfChain_Id')
  	    	  SET @sqlafter = @sqlafter + ' 
  	    	    	    	    	    	    	    	    	  DELETE FROM COMMENTS WHERE TopOfChain_Id in (Select CommentId FROM @Commentids)
  	    	    	    	    	    	    	    	    	  SET @affected=@@rowcount
  	    	    	    	    	    	    	    	    	  INSERT into @Qty values (@affected) '
  	  If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ESignature]'))
  	    	  SET @sqlafter = @sqlafter + ' 
  	    	    	    	  DELETE FROM ESignature WHERE Signature_Id in (Select SignatureId FROM #Esigs)'
  	  SET @sqlafter = @sqlafter + ' 
  	    	  DELETE FROM COMMENTS WHERE Comment_Id in (Select CommentId FROM @Commentids)
  	    	  SET @affected=@@rowcount
  	    	  INSERT into @Qty values (@affected)
  	    	  SELECT @RowsOutput = sum(qty) FROM @Qty'
  	    	  
exec spPurge_SetResult @desc,@affected,Null
IF @Debug = 1
BEGIN
 	 IF Len(@sqlfirst) > 6000  OR @sqlfirst IS NULL
 	 BEGIN
 	  	 SELECT '***ERROR*** @sqlfirst'
 	  	 RETURN
 	 END
 	 IF Len(@sql) > 6000  OR @sql IS NULL
 	 BEGIN
 	  	 SELECT '***ERROR*** @sql'
 	  	 RETURN
 	 END
 	 IF Len(@sql2) > 6000  OR @sql2 IS NULL
 	 BEGIN
 	  	 SELECT '***ERROR*** @sql2'
 	  	 RETURN
 	 END
 	 IF Len(@TestDeleteSql) > 6000  OR @TestDeleteSql IS NULL
 	 BEGIN
 	  	 SELECT '***ERROR*** @TestDeleteSql'
 	  	 RETURN
 	 END
 	 IF Len(@sqlafter) > 6000  OR @sqlafter IS NULL
 	 BEGIN
 	  	 SELECT '***ERROR*** @sqlafter'
 	  	 RETURN
 	 END
 	  Select @name [Tablename]
 	  SELECT @date [Date]
 	  select @StartTime [StartTime]
  	  SELECT @sqlfirst [@sqlfirst]
  	  SELECT @sql [@sql]
 	  SELECT @sql1 [@sql1]
  	  SELECT @sql2 [@sql2]
  	  SELECT @TestDeleteSql [@TestDeleteSql]
  	  SELECT @sqlafter [@sqlafter]
 	 RETURN
END
 	 begin tran
 	 IF @sql1 is Null SET @sql1 = ' '
 	 set @affected=0
 	 DECLARE @ParmDefinition nvarchar(500)
 	 DECLARE @AllSQL nvarchar(max)
 	 SET @ParmDefinition = N'@RowsOutput int Output'
 	 SELECT @AllSQL = @sqlfirst+@sql+@sql1+@sql2+@TestDeleteSql+@sqlafter
 	 EXECUTE sp_executesql  @AllSQL,@ParmDefinition,@RowsOutput = @affected OUTPUT
 	 commit tran
 	 if @affected>0 
 	 begin
 	  	 SET @totalAffected=@totalAffected+@affected
 	  	 if @puid is null
 	  	  	 SET @desc='TABLE ['+@name+'] [' + cast(@elementPerBatch as varchar) + '] '
 	  	 else
  	    	    	  SELECT @desc='UNIT ['+PU_Desc+'] TABLE ['+ @name +'] [' + cast(@elementPerBatch as varchar) + '] ' FROM Prod_Units_base pu where PU_Id=@puid
 	  	 exec spPurge_SetResult @desc,@affected,Null
 	 end
 	 IF @DisableServCheck = 0
 	  	 exec spPurge_CheckProcesses @quit out
 	 EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
end

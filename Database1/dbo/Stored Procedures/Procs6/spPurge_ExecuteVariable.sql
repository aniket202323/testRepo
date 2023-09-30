CREATE PROCEDURE dbo.spPurge_ExecuteVariable(
@pgid int,
@timeSliceMinutes int,
@puid int,
@varid int,
@StartTime DateTime,
@totalAffected int out,
@DisableServCheck Int,
@MaxPendingTasks 	 Int) 
 AS
DECLARE @affected 	 int,
 	  	 @retention 	 Int,
 	  	 @BatchSize 	 Int,
 	  	 @top 	  	 nvarchar(50),
 	  	 @sql 	  	 nvarchar(Max),
 	  	 @desc 	  	 varchar(255),
 	  	 @rc 	  	  	 int,
 	  	 @quit 	  	 int,
 	  	 @date 	  	 datetime ,
 	  	 @rowcount 	 varchar(50),
 	  	 @checkaffected varchar(100),
 	  	 @DoEsig 	  	  	  	 Int,
 	  	 @XLock 	  	  	  	 Bit
set @totalAffected=0
SELECT @retention = MAX(RetentionMonths),@BatchSize = Min(ElementPerBatch)
 	 FROM PurgeConfig_Detail
 	 WHERE Purge_Id = @pgid and PU_Id = @puid and Var_Id = @varid
IF @retention Is Null or @BatchSize Is Null
 	 RETURN
SET @DoEsig = 0
--If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ESignature]'))
--BEGIN
-- 	 IF EXISTS(select Top 1 * from ESignature) 	 SET @DoEsig = 1
--END
SET @date = dateadd(month,-@retention,@StartTime)
SET @date = DateAdd(Hour,-DatePart(Hour,@date),@date)
SET @date = DateAdd(Minute,-DatePart(Minute,@date),@date)
SET @date = DateAdd(Second,-DatePart(Second,@date),@date)
SET @date = DateAdd(millisecond,-DatePart(millisecond,@date),@date)
set @top =' top '+cast(@BatchSize as nvarchar)
set @rowcount ='set rowcount '+cast(@BatchSize as nvarchar)
set @checkaffected ='if @affected <'+cast(@BatchSize as nvarchar)
IF @DisableServCheck = 0
 	 EXEC spPurge_CheckProcesses @quit out
ELSE
 	 SET @quit = 0
EXECUTE spPurge_CheckPendingTasks @MaxPendingTasks,@quit Output
IF @quit=0 and (dateadd(n,@timeSliceMinutes,@StartTime)>getdate())
begin
 	 set @affected=0
 	 set @sql='
 	 DECLARE @affected int
 	 DECLARE @MinId 	 Int
 	 set @affected=0
 	 declare @qty table (qty int) 
 	 declare @tests table(TestId BigInt,CommId int)
 	 declare @eSigs table(esigId int)
 	 declare @Commentids table(CommentId int)
 	 INSERT into @tests (TestId, CommId) 
 	  	 select'+@top+' Test_Id,Comment_Id FROM Tests
 	  	 WHERE Var_Id= ' +cast(@varid as varchar)+
 	 ' And result_on<'''+cast(@date as varchar)+''' order by result_on 
 	 Insert Into @Commentids(CommentId) SELECT CommId From @tests WHERE CommId Is Not Null '
 	 If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Tests]') and Name = N'Signature_Id')  AND @DoEsig = 1
 	 BEGIN
 	  	 SET @sql = @sql + '
 	  	  	 INSERT INTO @eSigs(esigId)
 	  	  	  	 SELECT Signature_Id FROM Tests ts  JOIN @tests t on ts.Test_Id=t.TestId 
 	  	  	 INSERT INTO @eSigs(esigId)
 	  	  	  	 SELECT Signature_Id FROM Test_History th JOIN @tests t on th.Test_Id=t.TestId '
 	 END
 	 SET @sql = @sql + '
 	 ALTER TABLE Test_History disable trigger all 
 	 ALTER TABLE Tests disable trigger all
 	 DELETE from ad from Array_Data ad join Tests ts on ad.Array_Id=ts.Array_Id  join @tests t on ts.Test_Id=t.TestId 
 	 SET @affected=@@rowcount
 	 INSERT into @qty values (@affected)
 	 DELETE FROM th FROM Test_History th JOIN @tests t on th.Test_Id=t.TestId 
 	 SET @affected=@@rowcount
 	 INSERT into @qty values (@affected)
 	 DELETE FROM ts FROM Tests ts  JOIN @tests t on ts.Test_Id=t.TestId 
 	 SET @affected=@@rowcount
 	 INSERT into @qty values (@affected) '
 	 If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Table_Fields_Values]'))
 	 BEGIN
 	  	 SET @sql = @sql + '
 	  	  	 ALTER TABLE Table_Fields_Values Disable trigger all
 	  	  	 DELETE FROM Table_Fields_Values where TableId = 42 and KeyId in (SELECT TestId FROM @Tests)
 	  	  	 SET @affected=@@rowcount
 	  	  	 INSERT into @qty values (@affected)
 	  	  	 ALTER TABLE Table_Fields_Values enable trigger all '
 	 END
 	 if exists(select * FROM sysindexkeys where id = object_id('Test_History') and colid =(select Colid from syscolumns where id = object_id('Test_History') and Name = 'Var_Id'))
 	 BEGIN
 	  	 set @sql=@sql+@checkaffected+'
 	  	 begin
 	  	  	 DELETE FROM @tests
 	  	  	 INSERT into @tests (TestId, CommId) 
 	  	  	  	 select'+@top+' Test_Id,Comment_Id FROM Test_History
 	  	  	  	 WHERE Var_Id= ' + cast(@varid as varchar)+' And result_on<'''+cast(@date as varchar)+''''
 	  	  	 If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Test_History]') and Name = N'Signature_Id')  AND @DoEsig = 1
 	  	  	 BEGIN
 	  	  	  	 set @sql=@sql+ '
 	  	  	  	 INSERT INTO @eSigs(esigId)
 	  	  	  	  	 SELECT Signature_Id FROM Test_History th JOIN @tests t on th.Test_Id=t.TestId '
 	  	  	 END
 	  	  	 set @sql=@sql+ '
 	  	  	 DELETE FROM th FROM Test_History th JOIN @tests t on th.Test_Id=t.TestId
 	  	  	 set @affected=@@rowcount
 	  	  	 insert into @qty values (@affected)
 	  	 end '
 	 END
 	 If exists (select * from dbo.syscolumns where id = object_id(N'[dbo].[Comments]') and Name = N'TopOfChain_Id')
 	  	 SET @sql = @sql + ' DELETE FROM COMMENTS WHERE TopOfChain_Id in (Select CommentId FROM @Commentids)'
 	 If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ESignature]'))
 	  	 SET @sql = @sql + ' 
 	  	  	  	 DELETE FROM ESignature WHERE Signature_Id in (Select esigId FROM @Esigs)'
 	 SET @sql = @sql + ' 
 	  	 DELETE FROM COMMENTS WHERE Comment_Id in (Select CommentId FROM @Commentids)
 	  	 SELECT @RowsOutput = sum(qty) FROM @Qty q'
 	 SET @sql=@sql +' ALTER TABLE Tests enable trigger all 
 	  	  	 ALTER TABLE Test_History enable trigger all '
 	 begin tran
 	 set @rc=0
 	 DECLARE @ParmDefinition nvarchar(500);
 	 SET @ParmDefinition = N'@RowsOutput int Output'
 	 EXECUTE sp_executesql  @sql,@ParmDefinition,@RowsOutput = @rc OUTPUT
 	 set @totalAffected=@totalAffected+@rc
 	 if @rc>0
 	 begin
 	  	 set @affected=@rc
 	  	 select @desc='Variable ['+PU_Desc+']['+Var_Desc+'] [' + cast(@BatchSize as varchar) + ']' from Variables v  join Prod_Units pu on v.PU_Id=pu.PU_Id where Var_Id=@varid
 	  	 exec spPurge_SetResult @desc,@rc,Null
 	 end
 	 commit tran
end

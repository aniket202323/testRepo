CREATE PROCEDURE dbo.spServer_CmnLoadThreadPools
@ServiceId as int
AS
declare @Pools table(Pool_Id int not null, Pool_Desc nVarChar(100) null, Is_Default bit not null, Is_Message_Pool bit not null, Thread_Count int not null, Heartbeat_Interval int)
declare @NDef int
declare @MaxVal int
insert into @Pools (Pool_Id, Pool_Desc, Is_Default, Is_Message_Pool, Thread_Count, Heartbeat_Interval)
select Pool_Id, Pool_Desc, Is_Default, Is_Message_Pool, Thread_Count, Heartbeat_Interval
 	 from Service_ThreadPools
 	 where Service_Id = @ServiceId
select @NDef = count(*) from @Pools where Is_Default = 1
if (@NDef = 0)
Begin
 	 select @MaxVal = max(Pool_Id) from @Pools
 	 if (@MaxVal is null)
 	  	 Select @MaxVal = 0
 	 insert into @Pools (Pool_Id, Pool_Desc, Is_Default, Is_Message_Pool, Thread_Count) Values (@MaxVal + 1, 'Default Thread Pool', 1, 0, 5)
End
select @NDef = count(*) from @Pools where Is_Message_Pool = 1
if (@NDef = 0)
Begin
 	 select @MaxVal = max(Pool_Id) from @Pools
 	 if (@MaxVal is null)
 	  	 Select @MaxVal = 0
 	 insert into @Pools (Pool_Id, Pool_Desc, Is_Default, Is_Message_Pool, Thread_Count) Values (@MaxVal + 1, 'Message Thread Pool', 0, 1, 2)
End
select stp.Pool_id, stp.Thread_Count, stpd.Grouping_Number, stp.Pool_Desc, stp.Is_Default, stp.Heartbeat_Interval, stp.Is_Message_Pool
 	 from @Pools stp
 	 left join Service_ThreadPool_Data stpd on stpd.Pool_Id = stp.Pool_Id
 	 where ((stp.Is_Default = 1 or stp.Is_Message_Pool = 1) or (stpd.Grouping_Number is not null))
 	 order by stp.Pool_Id

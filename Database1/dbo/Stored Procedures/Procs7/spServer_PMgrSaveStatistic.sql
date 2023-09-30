CREATE PROCEDURE dbo.spServer_PMgrSaveStatistic
@ServiceId int,
@ObjectId int,
@CounterId int,
@InstanceName nVarChar(50),
@Value nVarChar(50),
@StartTime datetime,
@ModifiedOn datetime
AS 
declare @val nVarChar(100)
declare @mod datetime
declare @id int
declare @id2 int
Select @id = NULL
Select @id = Key_Id from Performance_Statistics_Keys WITH (index(Performance_Statistics_Keys_IDX_1))
where   	  Service_Id=@ServiceId and 
  	  Object_Id = @ObjectId And 
  	  Counter_Id = @CounterId And 
  	  Instance_Name = @InstanceName and 
  	  Start_Time=@StartTime
if @id is NULL
begin
  insert into Performance_Statistics_Keys (Service_Id, Object_Id, Counter_Id, Instance_Name, Start_Time) values(@ServiceId, @ObjectId, @CounterId, @InstanceName, @StartTime)
  Select @id = Key_Id from Performance_Statistics_Keys  WITH (index(Performance_Statistics_Keys_IDX_1)) where Service_Id=@ServiceId and Object_Id = @ObjectId And Counter_Id = @CounterId And Instance_Name = @InstanceName and Start_Time=@StartTime
end
if @id is not NULL
begin
  select @mod = null
  select @mod = max (Modified_On) from Performance_Statistics where Key_Id=@id
  if (@mod is not null)
  begin
    select @val = null
    select @val = Value, @id2=Performance_Statistics_Id from Performance_Statistics where Key_Id=@id and Modified_On=@mod
    if @val is null or @val <> @value
      insert into Performance_Statistics (Key_Id, Value, Modified_On) values (@id, @Value, @ModifiedOn)
    else
      update Performance_Statistics set Modified_On = @ModifiedOn where Performance_Statistics_Id=@id2
  end
  else
    insert into Performance_Statistics (Key_Id, Value, Modified_On) values (@id, @Value, @ModifiedOn)
end
return @id

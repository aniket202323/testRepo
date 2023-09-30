CREATE PROCEDURE dbo.spPurge_SaveConfig(
 	 @Config varchar(256),
 	 @TableName varchar(256),
 	 @PU_Id int,
 	 @Var_Id int,
 	 @Ret int,
 	 @Bat int,
 	 @Tim int
)AS
--store configuration settings for a single configuration detail
declare @Purge_Id int
--find config
select @Purge_Id=Purge_Id from PurgeConfig where Purge_Desc=@Config
if @Purge_Id is null 
begin
 	 --create a new config
 	 insert into PurgeConfig (Purge_Desc, TimeSliceMinutes) values (@Config, @Tim)
 	 set @Purge_Id=@@identity
end
else
begin
    update PurgeConfig set TimeSliceMinutes = @Tim Where Purge_Id = @Purge_Id
end    
insert into PurgeConfig_Detail (Purge_Id,TableName,PU_Id,Var_Id,RetentionMonths,ElementPerBatch)
 	 values (@Purge_Id,@TableName,@PU_Id,@Var_Id,@Ret,@Bat)

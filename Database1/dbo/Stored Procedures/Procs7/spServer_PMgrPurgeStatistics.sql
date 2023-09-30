CREATE PROCEDURE dbo.spServer_PMgrPurgeStatistics
@OldestTime datetime
AS
declare @DeleteKeys TABLE (Key_Id int)
delete from Performance_Statistics where Modified_On < @OldestTime
insert into @DeleteKeys(Key_Id) select Key_Id from Performance_Statistics_Keys 
delete from @DeleteKeys where Key_Id in (select distinct Key_Id from Performance_Statistics)
delete from Performance_Statistics_Keys where Key_Id in (select Key_Id from @DeleteKeys)

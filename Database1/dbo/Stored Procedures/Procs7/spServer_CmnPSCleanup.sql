CREATE PROCEDURE dbo.spServer_CmnPSCleanup
@PU_Id int,
@Start_Time datetime,
@End_Time datetime
 AS
Declare
  @RSumIds table (RSumId int)
insert into @RSumIds(RSumId) 
  select  RSum_Id
    From  GB_RSum
    Where (PU_Id = @PU_Id) And
          (((Start_Time >= @Start_Time) And (Start_Time < @End_Time)) Or 
          ((End_Time > @Start_Time) And (End_Time <= @End_Time)) Or
          ((Start_Time <= @Start_Time) And (End_Time >= @End_Time)))
Delete From GB_RSum_Data Where RSum_Id in (select RSumID from @RSumIds)
Delete From GB_RSum      Where RSum_Id in (select RSumID from @RSumIds)

  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
     Removed the cursor   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE procedure dbo.spLocal_DowntimeToEvent  
@OutputValue varchar(25) OUTPUT,  
@PU_Id int,   
@TimeStamp datetime,  
@Sent_PU_Id int  
  
AS  
  
  
SET NOCOUNT ON  
  
Declare @Event_Id int  
Declare @Event_Num varchar(50)  
Declare @CheckTime datetime  
Declare @PreviousEnd datetime  
Declare @PreviousStart datetime  
  
Select @OutputValue = convert(varchar(25), @TimeStamp, 109)  
  
-- declare @Msg varchar(300)  
-- select @Msg = coalesce(convert(varchar(10),@PU_Id), ' No PU ')  
-- select @Msg = @Msg + '-' + coalesce(convert(varchar(20),@TimeStamp, 109), ' No Start Time ')  
-- insert into comments (user_id, cs_id, modified_on, comment) values (1,1,getdate(), 'Downtime Update ' + @Msg)  
  
--Find The Previous Event   
Select @CheckTime = NULL  
Select @CheckTime = (Select max(Start_Time) From [dbo].Timed_Event_Details Where PU_Id = @PU_Id and Start_Time < @TimeStamp and Start_Time > dateadd(day,-5,@TimeStamp))  
Select @PreviousStart = Start_Time, @PreviousEnd = End_Time From [dbo].Timed_Event_Details Where PU_Id = @PU_id and Start_Time = @CheckTime  
  
If @CheckTime Is Null Return  
  
-- If This Is NOT The First Event In Chain, Return  
If @PreviousEnd = @TimeStamp Return  
   
--This IS The First Event In The Chain  
  
DECLARE @EventResults TABLE(  
  ResultsetType int,   
  Id int,   
  Transaction_Type int,   
  Event_Id int,   
  Event_Num varchar(50),   
  PU_Id int,   
  Timestamp datetime,  
  Applied_Product int,  
  Source_Event int,  
  Event_Status int,  
  Confirmed int,  
  User_Id int,  
  PostUpdate int  
)  
  
Declare @@Event_Id int  
Declare @@TimeStamp datetime  
Declare @@EventNum varchar(50)  
Declare @Id int,  
   @User_id   int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
Select @Id = 1  
  
INSERT INTO @eventresults (ResultsetType, Id , Transaction_Type , Event_Id , Event_Num, PU_Id,Timestamp,Applied_Product,Source_Event ,Event_Status ,Confirmed ,User_Id ,PostUpdate)  
 SELECT 1,@Id,3, Event_Id, Event_Num, @Sent_pu_id,Timestamp,0,0,5,1,@User_id,0  
 From [dbo].Events   
 Where PU_Id = @Sent_PU_Id and   
   Timestamp > @PreviousStart and   
   Timestamp < @TimeStamp  
  
  
-- --Get All Events Between Previous Start and This Start  
-- Declare MyCursor INSENSITIVE CURSOR For   
--   Select Event_Id, Event_Num, Timestamp  
--   From [dbo].Events Where PU_Id = @Sent_PU_Id and Timestamp > @PreviousStart and Timestamp < @TimeStamp  
--   For Read Only  
--   Open MyCursor    
-- MyLoop1:  
--   Fetch Next From MyCursor Into @@Event_Id, @@EventNum, @@TimeStamp  
--   
--   If (@@Fetch_Status = 0)  
--     Begin  
--   
--              insert into #eventresults  
--              Select ResultsetType = 1,   
--                  Id = @Id,   
--                 Transaction_Type = 3,   
--                  Event_Id = @@Event_Id,   
--                  Event_Num = @@EventNum,   
--                 PU_Id = @Sent_PU_Id,  
--                 Timestamp = @@Timestamp,  
--                 Applied_Product = 0,  
--                 Source_Event = 0,  
--                 Event_Status = 5,  
--                 Confirmed = 1,  
--                 User_Id = 1,  
--                 PostUpdate = 0  
--   
--  Select @Id = @Id + 1  
--       Goto MyLoop1  
--     End  
-- Close MyCursor  
-- Deallocate MyCursor  
  
Select @Event_Num = replace(replace(replace(right(convert(varchar(25),@TimeStamp, 120),14), ' ',''),'-',''),':','')  
  
insert into @eventresults(ResultsetType, Id , Transaction_Type , Event_Id , Event_Num, PU_Id,Timestamp,Applied_Product,Source_Event ,Event_Status ,Confirmed ,User_Id ,PostUpdate)  
 Select 1, @Id, 1, NULL, @Event_Num, @Sent_PU_Id,@Timestamp,0,0,5,1,@USer_id,0  
  
select ResultsetType, Id, Transaction_Type, Event_Id , Event_Num, PU_Id , Timestamp ,Applied_Product,Source_Event ,Event_Status ,Confirmed ,User_Id ,PostUpdate    
from @eventresults order by id  
  
  
SET NOCOUNT OFF  
  

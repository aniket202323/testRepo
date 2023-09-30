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
  
CREATE procedure dbo.spLocal_DowntimeToEventAll  
@OutputValue varchar(25) OUTPUT,  
@PU_Id int,   
@TimeStamp datetime,  
@Sent_PU_Id int  
AS  
  
Declare @Event_Id int  
Declare @Event_Num varchar(50)  
Declare @CheckTime datetime  
Declare @PreviousEnd datetime  
Declare @PreviousStart datetime  
  
Select @OutputValue = convert(varchar(25), @TimeStamp, 109)  
  
--Find The Previous Event   
Select @CheckTime = NULL  
Select @PreviousStart = (Select max(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time < @TimeStamp and Start_Time > dateadd(day,-5,@TimeStamp))  
   
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
 SELECT 1,NULL,3, Event_Id, Event_Num, @Sent_pu_id,Timestamp,0,0,5,1,@User_id,0  
 From [dbo].Events   
 Where PU_Id = @Sent_PU_Id and   
   Timestamp > @PreviousStart and   
   Timestamp < @TimeStamp  
  
Select @Event_Num = replace(replace(replace(right(convert(varchar(25),@TimeStamp, 120),14), ' ',''),'-',''),':','')  
  
insert into @eventresults(ResultsetType, Id , Transaction_Type , Event_Id , Event_Num, PU_Id,Timestamp,Applied_Product,Source_Event ,Event_Status ,Confirmed ,User_Id ,PostUpdate)  
 Select 1, NULL, 1, NULL, @Event_Num, @Sent_PU_Id,@Timestamp,0,0,5,1,@USer_id,0  
  
select ResultsetType, Id, Transaction_Type, Event_Id , Event_Num, PU_Id , Timestamp ,Applied_Product,Source_Event ,Event_Status ,Confirmed ,User_Id ,PostUpdate    
from @eventresults order by id  
  

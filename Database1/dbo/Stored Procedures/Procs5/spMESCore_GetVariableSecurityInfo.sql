CREATE PROCEDURE DBO.spMESCore_GetVariableSecurityInfo
(
  @UserId int,
  @SheetId int=null,
  @eventType int=null,
  @eventId int =null,
  @SheetName varchar(255)=null
)
AS
Declare @varSec table (var_id int, group_id int, accessLevel int, permission int, datasource int, maxhours int)
declare @PUId int
declare @permdenied int =0
declare @permRead int =1
declare @permWrite int =2
declare @permCreate int =4
declare @permDelete int =8
declare @permClose int =16
declare @permOpen int =32
declare @permUpdate1 int =64
declare @permUpdate2 int =128
declare @permUpdate3 int =256
declare @permAdmin int = 16384   -- select POWER(2,14)  
declare @fakeLevel int=1000
--lookup @sheetid
if @SheetId is null and @SheetName is not null 
begin
 	 select @SheetId=Sheet_id from Sheets where Sheet_Desc=@SheetName
end
if @SheetId is not null
begin
 	 insert into @varSec
 	  	 select a.var_id,  
 	  	 --coalesce(f.group_id, fg.group_id,a.group_id, b.group_id,c.group_id,d.group_id) group_id,
 	  	 coalesce(f.group_id, fg.group_id,a.group_id) group_id,
 	     accesslevel=
 	  	 (select min(isnull(v,
 	  	  	 case when u is null then @fakelevel  --no group_id is specified 
 	  	  	      when u is not null then 0       --group_id is specified but the user is not in this group
 	  	  	      end)
 	  	  	   ) from (values 
 	  	 (usa.Access_Level, a.group_id),(usf.Access_Level,f.group_id),(usfg.Access_Level, fg.group_id), (@fakeLevel, @fakeLevel)) as value(v,u)),
 	  	  @permdenied, a.DS_Id, f.max_edit_hours
 	  	 from Sheets f
 	  	 join Sheet_Groups fg on f.Sheet_Group_Id=fg.Sheet_Group_Id
 	  	 join Sheet_Variables g on f.Sheet_Id=g.Sheet_Id
 	  	 join Variables_base a on a.Var_Id=g.Var_Id
 	  	 --join PU_Groups b on b.PUG_Id=a.PUG_Id
 	  	 --join Prod_Units_base c on c.PU_Id=a.PU_Id
 	  	 --join Prod_Lines_base d on d.PL_Id=c.PL_Id
 	  	 left join User_Security usa  on a.group_id=usa.Group_Id and usa.User_Id=@UserId
 	     left join User_Security usf  on f.group_id=usf.Group_Id and usf.User_Id=@UserId
 	     left join User_Security usfg  on fg.group_id=usfg.Group_Id and usfg.User_Id=@UserId
 	  	 where f.Sheet_Id= @SheetId
 	 
end
else if(@eventId is not null and @eventType is not null)
begin
 	  	 If (@EventType = 1) -- Production Event
 	  	 Begin 
 	  	  	 Select @PUId = PU_Id from Events where Event_Id = Convert(int, @EventId)
 	  	 End
 	  	 Else If (@EventType = 2) -- Downtime Event
 	  	 Begin 
 	  	  	 Select @PUId = PU_Id from Timed_Event_Details where TEDet_Id = Convert(int, @EventId)
 	  	 End
 	  	 Else If (@EventType = 3) -- Waste Event
 	  	 Begin 
 	  	  	 Select @PUId = PU_Id from Waste_Event_Details where WED_Id = Convert(int, @EventId)
 	  	 End
 	  	 Else If (@EventType = 4) -- Product Change Event
 	  	 Begin 
 	  	  	 Select @PUId = PU_Id from Production_Starts where Start_Id = Convert(int, @EventId)
 	  	 End
 	  	 Else If (@EventType = 14) -- User Defined Event
 	  	 Begin 
 	  	  	 Select @PUId = PU_Id from User_Defined_Events where UDE_Id = Convert(int, @EventId)
 	  	 End
 	  	 Else If (@EventType = 19) -- Process Order Event
 	  	 Begin 
 	  	  	 Select @PUId = PU_Id from Production_Plan_Starts where PP_Start_Id = Convert(int, @EventId)
 	  	 End
 	  	 --Else If (@EventType = 22) -- Uptime Event
 	  	 --Begin 
 	  	 --End
 	  	 --Else If (@EventType = 31) -- Segment Response Event
 	  	 --Begin 
 	  	 --End
 	  	 --Else If (@EventType = 32) -- Work Response Event
 	  	 --Begin 
 	  	 --End
 	  	 ----------------------------------------------------------------------------
 	  	 -- Get Master Unit and ChildUnits
 	  	 ----------------------------------------------------------------------------
 	  	 declare @MasterUnit int
 	  	 declare @AllUnits table (PUId int)
 	  	 select @MasterUnit = coalesce(Master_Unit, PU_Id) from Prod_Units where PU_Id = @PUId
 	  	 insert into @AllUnits (PUId)
 	  	  	 select PU_Id from Prod_Units where PU_Id = @MasterUnit or Master_Unit = @MasterUnit
 	  	 insert into @varSec
 	  	 select a.var_id, coalesce(a.group_id, b.group_id,c.group_id,d.group_id) group_id, 0, @permdenied, a.DS_Id as datasource, 0
 	  	 from Variables_base a
 	  	 join PU_Groups b on b.PUG_Id=a.PUG_Id
 	  	 join Prod_Units_base c on c.PU_Id=a.PU_Id
 	  	 join Prod_Lines_base d on d.PL_Id=c.PL_Id
 	  	 where a.PU_Id in (select PUid from @AllUnits) and a.Event_Type=@eventType
 	  	 
 	  	 update vs set
 	  	 group_id=coalesce(a.group_id, b.group_id, c.group_id, d.group_id), 
 	  	 accesslevel=
 	  	 (select min(isnull(v,
 	  	  	 case when u is null then @fakelevel  --no group_id is specified 
 	  	  	  	  when u is not null then 0       --group_id is specified but the user is not in this group
 	  	  	 end)) from (values
 	  	  	  	 (usa.Access_Level, a.group_id), (usb.Access_Level,b.group_id), (usc.Access_Level,c.group_id), (usd.Access_Level,d.group_id), (@fakeLevel, @fakeLevel)) as value(v,u))
 	  	 from @varSec vs 
 	  	 join Variables_base a on vs.var_id=a.Var_Id
 	  	 join PU_Groups b on b.PUG_Id=a.PUG_Id
 	  	 join Prod_Units_base c on c.PU_Id=a.PU_Id
 	  	 join Prod_Lines_base d on d.PL_Id=c.PL_Id
 	     left join User_Security usa  on a.group_id=usa.Group_Id and usa.User_Id=@UserId
 	     left join User_Security usb  on b.group_id=usb.Group_Id and usb.User_Id=@UserId
 	     left join User_Security usc  on c.group_id=usc.Group_Id and usc.User_Id=@UserId
 	     left join User_Security usd  on d.group_id=usd.Group_Id and usd.User_Id=@UserId
 	  	 where  a.PU_Id in (select PUid from @AllUnits)
 	  	 and a.Event_Type=@eventType 
end
-- Revert back artifact of calculation
 	 update vs set accessLevel=0
 	 from @varSec vs
 	 where vs.accessLevel=@fakeLevel
 	 update vs set group_id=null
 	 from @varSec vs
 	 where vs.group_id=@fakeLevel
----If Group_id is null, no access_level is set,
----Set it to Manager
 	 update vs set accessLevel=3
 	 from @varSec vs
 	 where vs.group_id is null
 	 --update vs set accessLevel=us.Access_Level
 	 --from @varSec vs
 	 --join User_Security us  on vs.group_id=us.Group_Id  
 	 --where us.User_Id=@UserId
 	 
 	 
 	 --update vs set permission =
 	 --case vs.accessLevel
 	 --when 0 then @permdenied
 	 --when 1 then @permRead
 	 --when 2 then @permRead+@permWrite
 	 --when 3 then @permRead+@permWrite+ @permCreate+@permOpen+@permClose+@permDelete
 	 --when 4 then @permAdmin *2 -1  -- all rights
 	 --end
 	 --from @varSec vs 
 	 --Add read permission, if user has access
 	 update vs set permission = vs.permission |@permRead
 	 from @varSec vs 	 where vs.accessLevel > 0
 	 
 	 --Rule 1 for write
 	 --If AccessLevel < Administrator and DataSource is 2 (Autolog) then WriteAccess is True if AccessLevel >= ?Read/Write?
 	 update vs set permission = vs.permission |@permWrite |@permRead
 	 from @varSec vs 	 where vs.datasource =2 and vs.accessLevel >=2
 	 --Rule 2 for write
 	 --If AccessLevel = Administrator (to the security group) or 
 	 --the User has ?Read/Write? access to the Administrator group then WriteAccess = True regardless of DataSource
 	 --Note in this case, maxhours does not apply, so we set it to 0
 	 update vs set permission = vs.permission |@permWrite |@permRead, maxhours=0
 	 from @varSec vs 	 where vs.accessLevel =4 
 	 
 	 
 	 --finally, check if user is in Admin group and has RW access, if so, set write permission regardless group and accesslevel 
 	 declare @HasAdminRWLevel int=0
 	 select @HasAdminRWLevel=count(*) from user_security where user_id=@UserId and access_Level>=2 and group_id=1
 	 
 	 if @HasAdminRWLevel > 0 
 	 begin
 	  	 update vs set permission = vs.permission |@permWrite|@permRead , maxhours=0  from @varSec vs
 	 end 
 	 
 	 select vs.var_id , vs.group_id, vs.accessLevel , vs.permission, vs.maxhours from @varSec vs order by vs.var_id

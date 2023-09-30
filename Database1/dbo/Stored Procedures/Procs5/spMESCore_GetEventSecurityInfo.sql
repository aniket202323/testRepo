CREATE PROCEDURE DBO.spMESCore_GetEventSecurityInfo
(
  @UserId int,
  @eventType int,
  @eventIdList varchar(max)-- in the form of 1,3,4,5
 	  	  	  	  	  	    -- or 4 for single one
)
AS
Declare @eventSec table (event_id int, pl_id int, pu_id int, group_id int, accessLevel int, createLevel int, readLevel int, updateLevel int, deleteLevel int, addCommentsLevel int, updateCommentsLevel int, splitLevel int, overlapLevel int, canCreate bit, canRead bit, canUpdate bit, canDelete bit, canAddComments bit, canUpdateComments bit, canSplit bit, canOverlap bit, Sheet_Id int)
Declare @SheetOptionDefaults table (Display_Option_Desc varchar(50), Value varchar(7000))
Declare @SheetOptions table (Display_Option_Desc varchar(50), Value varchar(7000), Sheet_Id int)
declare @Sheet_Type int = 30 -- Web UI
declare @CatId int = null
declare @Denied int = 0
declare @RLevel int = 1
declare @RWLevel int = 2
declare @MgrLevel int = 3
declare @AdminLevel int = 4
declare @defaultLevel int = @Denied   --denied
declare @nullGroupIdLevel int = @AdminLevel --if group_id is null, this is the access level (customer is not controlling security, so the door is wide open)
If (@EventType = 1) -- Production Event
 	 Begin 
 	  	 set @CatId = 25 -- Production Event
 	  	 insert into @eventSec (event_id, pl_id, pu_id, group_id, accessLevel, createLevel, readLevel, updateLevel, deleteLevel, addCommentsLevel, updateCommentsLevel, splitLevel, overlapLevel)
 	  	  	 Select e.Event_Id, pu.PL_Id, e.PU_Id, null, @defaultLevel, @RWLevel, @RLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel
 	  	  	   from Events e 
 	  	  	   join dbo.fnMESCore_Split(@eventIdList,',') a on e.Event_Id = a.val
 	  	  	   join Prod_Units_base pu on pu.PU_Id = e.PU_Id
 	 End
Else If (@EventType = 2) -- Downtime Event
 	 Begin 
 	  	 set @CatId = 23 -- Downtime Event
 	  	 insert into @eventSec (event_id, pl_id, pu_id, group_id, accessLevel, createLevel, readLevel, updateLevel, deleteLevel, addCommentsLevel, updateCommentsLevel, splitLevel, overlapLevel) 
 	  	  	 Select e.TEDet_Id, pu.PL_Id, e.PU_Id, null, @defaultLevel, @RWLevel, @RLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel
 	  	  	   from Timed_Event_Details e 
 	  	  	   join dbo.fnMESCore_Split(@eventIdList,',') a on e.TEDet_Id = a.val
 	  	  	   join Prod_Units_base pu on pu.PU_Id = e.PU_Id
 	 End
Else If (@EventType = 3) -- Waste Event
 	 Begin
 	  	 set @CatId = 24 -- Waste Event
 	  	 insert into @eventSec (event_id, pl_id, pu_id, group_id, accessLevel, createLevel, readLevel, updateLevel, deleteLevel, addCommentsLevel, updateCommentsLevel, splitLevel, overlapLevel)
 	  	  	 Select e.WED_Id, pu.PL_Id, e.PU_Id, null, @defaultLevel, @RWLevel, @RLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel
 	  	  	   from Waste_Event_Details e 
 	  	  	   join dbo.fnMESCore_Split(@eventIdList,',') a on e.WED_Id = a.val 	  
 	  	  	   join Prod_Units_base pu on pu.PU_Id = e.PU_Id
 	 End
Else If (@EventType = 4) -- Product Change Event
 	 Begin 
 	  	 insert into @eventSec (event_id, pl_id, pu_id, group_id, accessLevel, createLevel, readLevel, updateLevel, deleteLevel, addCommentsLevel, updateCommentsLevel, splitLevel, overlapLevel)
 	  	  	 Select e.Start_Id, pu.PL_Id, e.PU_Id, null, @defaultLevel, @RWLevel, @RLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel
 	  	  	   from Production_Starts e 
 	  	  	   join dbo.fnMESCore_Split(@eventIdList,',') a on e.Start_Id = a.val 	  
 	  	  	   join Prod_Units_base pu on pu.PU_Id = e.PU_Id
 	 End
Else If (@EventType = 14) -- User Defined Event
 	 Begin 
 	  	 set @CatId = 26 -- User Defined Event
 	  	 insert into @eventSec (event_id, pl_id, pu_id, group_id, accessLevel, createLevel, readLevel, updateLevel, deleteLevel, addCommentsLevel, updateCommentsLevel, splitLevel, overlapLevel)
 	  	  	 Select e.UDE_Id, pu.PL_Id, e.PU_Id, null, @defaultLevel, @RWLevel, @RLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel
 	  	  	   from User_Defined_Events e 
 	  	  	   join dbo.fnMESCore_Split(@eventIdList,',') a on e.UDE_Id = a.val 	  
 	  	  	   join Prod_Units_base pu on pu.PU_Id = e.PU_Id
 	 End
Else If (@EventType = 19) -- Process Order Event
 	 Begin 
 	  	 set @CatId = 28 -- Process Order Event
 	  	 insert into @eventSec (event_id, pl_id, pu_id, group_id, accessLevel, createLevel, readLevel, updateLevel, deleteLevel, addCommentsLevel, updateCommentsLevel, splitLevel, overlapLevel)
 	  	  	 Select e.PP_Id, pps.PL_Id, null, null, @defaultLevel, @RWLevel, @RLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel, @RWLevel
 	  	  	   from Production_Plan e 
 	  	  	   join Prdexec_Paths pps on e.Path_Id = pps.Path_Id
 	  	  	   join dbo.fnMESCore_Split(@eventIdList,',') a on e.PP_Id = a.val
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
if (@CatId is not null)
 	 begin
 	  	 update es
 	  	  	 set es.Sheet_Id = coalesce(s1.Sheet_Id, s.Sheet_Id), es.group_id = coalesce(s1.Group_Id, s.Group_Id)
 	  	  	 from @eventSec es
 	  	  	 left join Sheets s on s.PL_Id = es.PL_Id and s.Sheet_Type = @Sheet_Type
 	  	  	 left join Sheet_Unit su on su.PU_Id = es.PU_Id
 	  	  	 left join Sheets s1 on s1.Sheet_Id = su.Sheet_Id and s1.Sheet_Type = @Sheet_Type
 	  	 insert into @SheetOptionDefaults (Display_Option_Desc, Value)
 	  	 select d.Display_Option_Desc, st.Display_Option_Default
 	  	   from display_options d
 	  	   join Sheet_Type_Display_Options st on st.Display_Option_Id = d.Display_Option_Id and st.Sheet_Type_Id = @Sheet_Type
 	  	   where d.Display_Option_Category_Id = @CatId
 	  	 insert into @SheetOptions (Display_Option_Desc, Value, Sheet_Id)
 	  	 select d.Display_Option_Desc, so.Value, so.Sheet_Id
 	  	   from display_options d
 	  	   join Sheet_Display_Options so on so.Display_Option_Id = d.Display_Option_Id
 	  	   join Sheets s on s.Sheet_Type = @Sheet_Type and s.Sheet_Id = so.Sheet_Id
 	  	   where d.Display_Option_Category_Id = @CatId
 	  	 update es
 	  	  	 set es.createLevel = coalesce(so.Value, sd.Value,es.createLevel)
 	  	  	 from @eventSec es
 	  	  	 left join @SheetOptions so on so.Display_Option_Desc like 'Insert Records' and so.Sheet_Id = es.Sheet_Id
 	  	  	 left join @SheetOptionDefaults sd on sd.Display_Option_Desc like 'Insert Records'
 	  	 update es
 	  	  	 set es.deleteLevel = coalesce(so.Value, sd.Value,es.deleteLevel)
 	  	  	 from @eventSec es
 	  	  	 left join @SheetOptions so on so.Display_Option_Desc like 'Delete Records' and so.Sheet_Id = es.Sheet_Id
 	  	  	 left join @SheetOptionDefaults sd on sd.Display_Option_Desc like 'Delete Records'
 	  	 update es
 	  	  	 set es.addCommentsLevel = coalesce(so.Value, sd.Value,es.addCommentsLevel)
 	  	  	 from @eventSec es
 	  	  	 left join @SheetOptions so on so.Display_Option_Desc like 'Add Comments' and so.Sheet_Id = es.Sheet_Id
 	  	  	 left join @SheetOptionDefaults sd on sd.Display_Option_Desc like 'Add Comments'
 	  	 update es
 	  	  	 set es.updateCommentsLevel = coalesce(so.Value, sd.Value,es.updateCommentsLevel)
 	  	  	 from @eventSec es
 	  	  	 left join @SheetOptions so on so.Display_Option_Desc like 'Change Comments' and so.Sheet_Id = es.Sheet_Id
 	  	  	 left join @SheetOptionDefaults sd on sd.Display_Option_Desc like 'Change Comments'
 	  	 update es
 	  	  	 set es.splitLevel = coalesce(so.Value, sd.Value,es.splitLevel)
 	  	  	 from @eventSec es
 	  	  	 left join @SheetOptions so on so.Display_Option_Desc like 'Split Records' and so.Sheet_Id = es.Sheet_Id
 	  	  	 left join @SheetOptionDefaults sd on sd.Display_Option_Desc like 'Split Records'
 	  	 update es
 	  	  	 set es.overlapLevel = coalesce(so.Value, sd.Value,es.overlapLevel)
 	  	  	 from @eventSec es
 	  	  	 left join @SheetOptions so on so.Display_Option_Desc like 'Overlap Records' and so.Sheet_Id = es.Sheet_Id
 	  	  	 left join @SheetOptionDefaults sd on sd.Display_Option_Desc like 'Overlap Records'
 	 end
update es set es.group_id = coalesce(pu.group_id, pl.group_id)
 	 from @eventSec es
 	 left join Prod_Units_base pu on pu.PU_Id = es.PU_Id
 	 left join Prod_Lines_base pl on pl.PL_Id = es.PL_Id
 	 where es.group_id is null
----If Group_id is null, no access_level is set,
----Set it to Read/Write 
update es set accessLevel = @nullGroupIdLevel
 	 from @eventSec es
 	 where es.group_id is null
update es set accessLevel = us.Access_Level
 	 from @eventSec es
 	 join User_Security us  on us.Group_Id = es.group_id
 	 where us.User_Id = @UserId
 	 
declare @UserAdminLevel int = 0
select @UserAdminLevel = Access_Level from user_security where user_id = @UserId and group_id = 1
if @UserAdminLevel = 4 
 	 begin
 	  	 update @eventSec set accessLevel = 4
 	 end 
update @eventSec
  set canCreate         = Case when accessLevel >= createLevel          then 1 else 0 end,
      canRead           = Case when accessLevel >= readLevel            then 1 else 0 end,
      canUpdate         = Case when accessLevel >= updateLevel          then 1 else 0 end,
      canDelete         = Case when accessLevel >= deleteLevel          then 1 else 0 end,
      canAddComments    = Case when accessLevel >= addCommentsLevel     then 1 else 0 end,
      canUpdateComments = Case when accessLevel >= updateCommentsLevel  then 1 else 0 end,
      canSplit          = Case when accessLevel >= splitLevel           then 1 else 0 end,
      canOverlap        = Case when accessLevel >= overlapLevel         then 1 else 0 end
 	 
select es.event_id, es.group_id, es.accessLevel, es.pu_id, es.canCreate, es.canRead, es.canUpdate, es.canDelete, es.canAddComments, es.canUpdateComments, es.canSplit, es.canOverlap from @eventSec es order by event_id

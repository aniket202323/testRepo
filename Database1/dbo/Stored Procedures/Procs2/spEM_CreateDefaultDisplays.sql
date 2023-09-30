--    spEM_CreateDefaultDisplays 'dz',1,1,1
CREATE   PROCEDURE dbo.spEM_CreateDefaultDisplays
@NodeType nVarChar(2),
@Id int,
@Override Int,
@UserId 	 Int
AS
/*
Administrator node types
dz - Department
ad - Line
ae - unit
*/
Create Table #ErrorLog(
 	 msgId int NOT NULL IDENTITY (1, 1),
 	 Message VarChar(4000))
Declare  	 @SheetId Int,
 	  	  	 @PU_Id 	 Int,
 	  	  	 @PU_Desc 	 nvarchar(50),
 	  	  	 @LineDesc 	 nvarchar(50),
 	  	  	 @SheetDesc 	 nvarchar(50),
 	  	  	 @PUGDesc 	 nvarchar(50),
 	  	  	 @SheetGroupId 	 Int,
 	  	  	 @LastTitle 	  	 nvarchar(50),
 	  	  	 @VarOrder 	  	 Int,
 	  	  	 @VarId 	  	  	 Int,
 	  	  	 @Interval 	  	 Int,
 	  	  	 @SamplingInterval 	 Int,
 	  	  	 @OVCreated 	  	  	 Int,
 	  	  	 @SVSheetId 	  	  	 Int,
 	  	  	 @PathId 	  	  	  	 Int
Create Table #Units(PU_Id Int,PU_Desc nvarchar(50))
Create Table #SheetGroups(Sheet_Group_Id Int,Sheet_Group_Desc nvarchar(50))
Select @OVCreated = 0
If @NodeType = 'dz'
  Begin
 	 Insert Into #Units (PU_Id,PU_Desc)
 	  	 Select pu.PU_Id,pu.PU_Desc
 	  	 From Prod_Units pu
 	  	 Join Prod_Lines Pl on pl.PL_Id = Pu.PL_Id
 	  	 Join Departments d on d.Dept_Id = pl.Dept_Id and d.Dept_Id = @Id
 	  	 Where pu.Master_Unit is null and pu_Id <> 0
  End 	  	 
If @NodeType = 'ad'
  Begin
 	 Insert Into #Units (PU_Id,PU_Desc)
 	  	 Select pu.PU_Id,pu.PU_Desc
 	  	 From Prod_Units pu
 	  	 Where pu.Master_Unit is null and pu_Id <> 0 and Pu.PL_Id = @Id
  End 	  	 
If @NodeType = 'ae'
  Begin
 	 Insert Into #Units (PU_Id,PU_Desc) 
 	  	 Select pu.PU_Id,pu.PU_Desc
 	  	 From Prod_Units pu
 	  	 Where Pu.PU_Id = @Id
  End 	  	 
Insert Into #ErrorLog(Message) Values('Starting Display Creation')
Declare Unit_Cursor Cursor
 	 For Select PU_Id,PU_Desc From #Units
Open Unit_Cursor
Unit_Cursor_Loop:
Fetch Next From Unit_Cursor into @PU_Id,@PU_Desc
If @@Fetch_Status = 0
 	 Begin
 	  	 Select @LineDesc = Pl_Desc
 	  	  From Prod_Lines PL
 	  	  Join Prod_Units pu on pu.Pl_Id = pl.PL_Id
 	  	  Where PU_Id = @PU_Id
 	  	 Select @SheetGroupId = Null
 	  	 Select @SheetGroupId = Sheet_Group_Id from Sheet_Groups where Sheet_Group_Desc = @LineDesc
 	  	 If @SheetGroupId is null
 	  	  	 Begin
 	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating a new display group [' + @LineDesc + ']')
 	  	  	  	 Execute spEM_CreateSheetGroup  @LineDesc,@UserId, @SheetGroupId OUTPUT
 	  	  	  	 If @SheetGroupId is null
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Unable to create display group [' + @LineDesc + ']')
 	  	  	  	  	 Return
 	  	  	  	   End
 	  	  	  	 Insert into #SheetGroups(Sheet_Group_Id ,Sheet_Group_Desc) Values (@SheetGroupId,@LineDesc)
 	  	  	 End
 	  	 If (Select Count(*) from variables where Event_Type = 0 and PU_Id In (Select PU_Id From Prod_Units where pu_Id = @PU_Id or master_Unit = @PU_Id)) > 0 -- Time
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null,@Interval = 1440
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![Time!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc  ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing Autolog Time display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
/*Find Unique Name*/
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[Time]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating an Autolog Time display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc, 1,0,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Select @LastTitle = '',@VarOrder = 1
 	  	  	  	  	  	 Declare Time_Variable_Cursor Cursor For
 	  	  	  	  	  	  	 Select v.Var_Id,pug.PUG_Desc,pu.PU_Desc,isnull(v.Sampling_Interval,1440)
 	  	  	  	  	  	  	 From Variables v
 	  	  	  	  	  	  	 Join PU_Groups pug on pug.pug_id = v.pug_id
 	  	  	  	  	  	  	 Join Prod_Units pu on (pu.pu_Id = @PU_Id or pu.master_Unit = @PU_Id) and v.pu_Id = pu.PU_Id
 	  	  	  	  	  	  	 Where  Event_Type = 0 
 	  	  	  	  	  	  	 Order by pu.PU_Desc,pug.PUG_Order,v.PUG_Order
 	  	  	  	  	  	 Open Time_Variable_Cursor
 	  	  	  	  	  	 Time_Variable_Cursor_Loop:
 	  	  	  	  	  	 Fetch Next From Time_Variable_Cursor Into @VarId,@PUGDesc,@PU_Desc,@SamplingInterval
 	  	  	  	  	  	 If @@Fetch_Status = 0
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 If @SamplingInterval = 0 Select @SamplingInterval = 1440
 	  	  	  	  	  	  	  	 If @SamplingInterval < @Interval Select @Interval = @SamplingInterval
 	  	  	  	  	  	  	  	 If @LastTitle <> @PUGDesc
 	  	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  	 Insert Into Sheet_Variables (Sheet_Id,Var_Id,Var_Order,Title) Values (@SheetId,Null,@VarOrder,@PUGDesc)
 	  	  	  	  	  	  	  	  	  	 Select @VarOrder = @VarOrder + 1
 	  	  	  	  	  	  	  	  	  	 Select @LastTitle = @PUGDesc
 	  	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	  	 Insert Into Sheet_Variables (Sheet_Id,Var_Id,Var_Order,Title) Values (@SheetId,@VarId,@VarOrder,Null)
 	  	  	  	  	  	  	  	 Select @VarOrder = @VarOrder + 1
 	  	  	  	  	  	  	  	 GoTo Time_Variable_Cursor_Loop
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Close Time_Variable_Cursor
 	  	  	  	  	  	 Deallocate Time_Variable_Cursor
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,Null,Null,@Interval,0,48,48,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	   End
 	  	  	 End
 	  	 If (Select Count(*) from variables where Event_Type = 1 and PU_Id In (Select PU_Id From Prod_Units where pu_Id = @PU_Id or master_Unit = @PU_Id)) > 0 -- Production Event
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![Production!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing Autolog Production Event display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[Production]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating an Autolog Production Event display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,2,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Select @LastTitle = '',@VarOrder = 1
 	  	  	  	  	  	 Declare Event_Variable_Cursor Cursor For
 	  	  	  	  	  	  	 Select v.Var_Id,pug.PUG_Desc,pu.PU_Desc
 	  	  	  	  	  	  	 From Variables v
 	  	  	  	  	  	  	 Join PU_Groups pug on pug.pug_id = v.pug_id
 	  	  	  	  	  	  	 Join Prod_Units pu on (pu.pu_Id = @PU_Id or pu.master_Unit = @PU_Id) and v.pu_Id = pu.PU_Id
 	  	  	  	  	  	  	 Where  Event_Type = 1
 	  	  	  	  	  	  	 Order by pu.PU_Desc,pug.PUG_Order,v.PUG_Order
 	  	  	  	  	  	 Open Event_Variable_Cursor
 	  	  	  	  	  	 Event_Variable_Cursor_Loop:
 	  	  	  	  	  	 Fetch Next From Event_Variable_Cursor Into @VarId,@PUGDesc,@PU_Desc
 	  	  	  	  	  	 If @@Fetch_Status = 0
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 If @LastTitle <> @PUGDesc
 	  	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  	 Insert Into Sheet_Variables (Sheet_Id,Var_Id,Var_Order,Title) Values (@SheetId,Null,@VarOrder,@PUGDesc)
 	  	  	  	  	  	  	  	  	  	 Select @VarOrder = @VarOrder + 1
 	  	  	  	  	  	  	  	  	  	 Select @LastTitle = @PUGDesc
 	  	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	  	 Insert Into Sheet_Variables (Sheet_Id,Var_Id,Var_Order,Title) Values (@SheetId,@VarId,@VarOrder,Null)
 	  	  	  	  	  	  	  	 Select @VarOrder = @VarOrder + 1
 	  	  	  	  	  	  	  	 GoTo Event_Variable_Cursor_Loop
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Close Event_Variable_Cursor
 	  	  	  	  	  	 Deallocate Event_Variable_Cursor
 	  	  	  	  	  	 Declare @EventPrompt nVarChar(25)
 	  	  	  	  	  	 Select @EventPrompt = Event_Subtype_Desc
 	  	  	  	  	  	  	 From event_Subtypes es
 	  	  	  	  	  	  	 Join Event_Configuration ec On ec.pu_Id = @PU_Id and es.Event_Subtype_Id = ec.Event_Subtype_Id and ec.ET_Id = 1
 	  	  	  	  	  	 Select @EventPrompt = isnull(@EventPrompt,'Event Prompt')
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,11,'True',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,10,'HH:mm:ss',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,190,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,@PU_Id,@EventPrompt,0,0,48,48,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	   End
 	  	  	 End
 	  	 If (Select Count(*) from Event_Configuration where Et_Id = 2 and PU_Id = @PU_Id ) > 0 -- Downtime
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![DownTime!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing DownTime display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[DownTime]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating a DownTime display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,5,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,169,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,@PU_Id,null,0,0,48,48,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	   End
 	  	  	 End
 	  	 If (Select Count(*) from Event_Configuration where Et_Id = 3 and PU_Id = @PU_Id) > 0 -- Waste Event
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![Waste!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing Waste display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[Waste]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating a Waste display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,4,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,@PU_Id,null,0,0,48,48,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	   End
 	  	  	 End
 	  	 If (Select Count(*) from Event_Configuration where Et_Id = 1 and PU_Id = @PU_Id) > 0 -- Production Event
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![SOE!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing SOE display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[SOE]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating a SOE display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,14,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,Null,null,0,0,48,48,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetUnits @SheetId,1,@PU_Id,1,1,@UserId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	  	  	 Declare @sEvent_Subtype_Id nVarChar(10)
 	  	  	  	  	  	 Select @sEvent_Subtype_Id = Convert(nVarChar(10),es.Event_Subtype_Id)
 	  	  	  	  	  	  	 From event_Subtypes es
 	  	  	  	  	  	  	 Join Event_Configuration ec On ec.pu_Id = @PU_Id and es.Event_Subtype_Id = ec.Event_Subtype_Id and ec.ET_Id = 1
 	  	  	  	  	  	 If @sEvent_Subtype_Id is not Null
 	  	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,44,@sEvent_Subtype_Id,@UserId
 	  	  	  	  	 
 	  	  	  	   End
 	  	  	 End
 	  	 If (Select Count(*) from prdexec_inputs where PU_Id = @PU_Id ) > 0 -- Has an Input
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![GV!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing Genealogy View display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[GV]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating a Genealogy View display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,10,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,@PU_Id,null,0,0,24,24,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	   End
 	  	  	 End
 	  	 If ((Select Count(*) from PrdExec_Path_Units where PU_Id = @PU_Id )  > 0)  and (@OVCreated = 0) -- Is in a path
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null,@OVCreated = 1,@PathId = Null
 	  	  	  	 Select @PathId = Min(Path_Id) From PrdExec_Path_Units Where PU_Id = @PU_Id
 	  	  	  	 Select @SheetDesc = @PU_Desc + '![Overview!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing Overview display for [' + @PU_Desc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @PU_Desc + '[Overview]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating an Overview display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,8,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,@PU_Id,null,0,0,24,24,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Insert Into Sheet_Unit (Sheet_Id,PU_Id)
 	  	  	  	  	  	  	 Select @SheetId,PU_Id
 	  	  	  	  	  	  	 From PrdExec_Path_Units
 	  	  	  	  	  	  	 Where Path_Id = @PathId
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	   End
 	  	  	 End
 	  	 If (Select Count(*) from PrdExec_Path_Units ppu Join PrdExec_Paths p On p.Path_Id = ppu.Path_Id and p.Schedule_Control_Type = 0  where PU_Id = @PU_Id )  > 0 -- Is in a path
 	  	  	 Begin
 	  	  	  	 Select @SheetId = Null,@PathId = Null
 	  	  	  	 Select @PathId = Min(ppu.Path_Id) From PrdExec_Path_Units ppu Join PrdExec_Paths p On p.Path_Id = ppu.Path_Id  and p.Schedule_Control_Type = 0 Where PU_Id = @PU_Id 
 	  	  	  	 Select @SheetDesc = @LineDesc + '![SV!]%'
 	  	  	  	 Select @SheetId = Sheet_Id From Sheets Where Sheet_Desc Like @SheetDesc ESCAPE '!' and Sheet_Group_Id = @SheetGroupId
 	  	  	  	 If @SheetId is Not Null and @Override = 1 and @SVSheetId is null
 	  	  	  	   Begin
 	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Removing Schedule View display for [' + @LineDesc + ']')
 	  	  	  	  	 Execute spEM_DropSheet  @SheetId, @UserId
 	  	  	  	  	 Select @SheetId = Null
 	  	  	  	   End
 	  	  	  	 If @SheetId is Null and @SVSheetId is null
 	  	  	  	   Begin
 	  	  	  	  	  	 Select @SheetDesc = @LineDesc + '[SV]'
 	  	  	  	  	  	 Execute spEM_FindUniqueSheetName  @SheetDesc Output
 	  	  	  	  	  	 Insert Into #ErrorLog(Message) Values('Creating a Schedule View display for [' + @SheetDesc + ']')
 	  	  	  	  	  	 Execute spEM_CreateSheet @SheetDesc,17,1,@SheetGroupId,@UserId,@SheetId OUTPUT
 	  	  	  	  	  	 Execute spEM_PutSheetDisplayOptions @SheetId,229,'1',@UserId
 	  	  	  	  	  	 Execute spEM_PutSheetData    @SheetId,@PU_Id,null,0,0,24,24,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,Null,0,0,Null,Null,0,Null,@UserId
 	  	  	  	  	  	 Insert Into Sheet_Paths (Sheet_Id,Path_Id) values (@SheetId,@PathId)
 	  	  	  	  	  	 Execute spEM_ActivateSheet 	 @SheetId,1,@UserId
 	  	  	  	  	  	 Select @SVSheetId = @SheetId
 	  	  	  	   End
 	  	  	  	 If @SVSheetId is not null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (select count(*) from Sheet_Paths where Sheet_Id = @SheetId and Path_Id = @PathId) = 0
 	  	  	  	  	  	  	 Insert Into Sheet_Paths (Sheet_Id,Path_Id) values (@SheetId,@PathId)
 	  	  	  	  	 End
 	  	  	 End
 	  	 GoTo Unit_Cursor_Loop
 	 End
Close Unit_Cursor
Deallocate Unit_Cursor
Drop Table #Units
Insert Into #ErrorLog(Message) Values('Finished Display Creation')
Select * From #SheetGroups
Select Message From #ErrorLog order by msgId
Drop Table #ErrorLog

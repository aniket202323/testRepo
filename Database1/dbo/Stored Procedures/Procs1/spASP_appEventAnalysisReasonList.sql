create procedure [dbo].[spASP_appEventAnalysisReasonList]
--declare 
@EventType int,
@EventSubtype int,
@Units nvarchar(1000),
@IsCause int,
@RequestedLevel int,
@Level0Filter int,
@Level1Filter int,
@Level2Filter int,
@Level3Filter int,
@Level4Filter int
AS
/***************************
-- For Testing
--***************************
Select @EventType = 11
Select @EventSubtype = null
Select @Units = '2'
Select @IsCause = 0
Select @RequestedLevel = 1
Select @Level0Filter = 10
Select @Level1Filter = NULL
Select @Level2Filter = NULL
Select @Level3Filter = NULL
Select @Level4Filter = NULL
--***************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
Create Table #List (
  Id int,
  Description nVarChar(100)
)
Create Table #Units (
  ItemOrder int,
  Item int 
)
Insert Into #Units (Item, ItemOrder)
  execute ('Select Distinct PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + ''''+ ',1)  From Prod_Units Where PU_Id in (' + @Units + ')' + ' and pu_id <> 0')
Declare @@UnitId int
Declare @TreeId int
declare @SQL nvarchar(3000)
Declare Unit_Cursor Insensitive Cursor 
  For (Select Distinct Item From #Units)
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin
    --**************************
    -- Locations
    --**************************
    If @EventType in (2,3) and @RequestedLevel = 0
      Begin
         Insert Into #List 
           Select Id = pu_id, Description = pu_desc
             From prod_units 
             where pu_id = @@UnitId or master_unit = @@UnitId
      End
    --**************************
    -- Alarm Variables
    --**************************
    Else If @EventType = 11 and @RequestedLevel = 0
      Begin
         Insert Into #List 
  	          Select Distinct Id = v.Var_Id, Description = v.var_desc 
 	  	  	  	  	    From variables v  
 	  	  	  	  	    Join Prod_units pu on pu.pu_id = v.pu_id and (pu.pu_id = @@UnitId or pu.master_unit = @@UnitId)
 	            Join #Units u on u.Item = pu.pu_id
 	  	  	  	  	    Join alarm_template_var_data a on a.var_id = v.var_id      
      End
    Else If ((@EventType not in (2,3,11)) or (@IsCause = 0 and @EventType <> 11)) and @RequestedLevel > 0
 	     --*********************************************
 	     -- These Trees ARE NOT Location, Variable Dependant
 	     --*********************************************
      Begin 
 	  	     --*********************************************
 	  	     -- Action For Downtime, Waste
 	  	     --*********************************************
 	       If @EventType in (2,3) and @IsCause = 0 
 	  	       Begin
 	  	         Select @TreeId = NULL
 	  	  	  	  	  	 Select @TreeId = Action_Tree_Id
 	  	  	  	  	  	   From Prod_Events
 	  	  	  	  	  	   Where PU_Id = @@UnitId and
 	  	  	  	  	  	         Event_Type = @EventType
 	  	 
 	  	 
 	  	       End
 	  	     --*********************************************
 	  	     -- Actions For User Defined Events
 	  	     --*********************************************
 	  	     Else If @EventType = 14 and @EventsubType Is Not Null and @IsCause = 0 
 	  	       Begin
 	  	         Select @TreeId = NULL
 	  	  	  	  	  	 Select @TreeId =  	 Action_Tree_id
 	  	  	  	  	  	   From event_subtypes 
 	  	  	  	  	  	   Where event_subtype_id = @EventSubType
 	  	 
 	  	       End
 	  	     --*********************************************
 	  	     -- Cause For User Defined Events
 	  	     --*********************************************
 	  	     Else If @EventType = 14 and @EventsubType Is Not Null and @IsCause = 1 
 	  	       Begin
 	  	         Select @TreeId = NULL
 	  	  	  	  	  	 Select @TreeId =  	 Cause_Tree_id
 	  	  	  	  	  	   From event_subtypes 
 	  	  	  	  	  	   Where event_subtype_id = @EventSubType
 	  	 
 	  	       End
 	       Select @SQL =  'Select Distinct Id = r.Event_Reason_Id, Description = r.Event_Reason_Name ' + 
 	           'From Event_Reason_Tree_Data rt ' + 
 	           'Join Event_Reasons r on r.Event_Reason_Id = rt.Event_Reason_Id ' + 
 	           'Where rt.Tree_Name_Id = ' + convert(nvarchar(20),@TreeId) + ' and ' + 
 	                 'rt.Event_Reason_Level = ' + convert(nvarchar(20),@RequestedLevel) + ' '
        If @RequestedLevel = 2 and @Level1Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level1Filter)
        Else If @RequestedLevel = 3 and @Level2Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level2Filter)
        Else If @RequestedLevel = 4 and @Level3Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level3Filter)
        Insert into #List 
          Exec (@SQL)
      End
    Else If @EventType in (2,3) and @IsCause = 1 and @RequestedLevel > 0
 	     --*********************************************
 	     -- These Trees ARE Location Dependant
 	     --*********************************************
      Begin
        If @Level0Filter Is Not Null
          Begin
            -- A Location Has Been Specified
 	  	         Select @TreeId = NULL
 	  	  	  	  	  	 Select @TreeId = Name_Id
 	  	  	  	  	  	   From Prod_Events
 	  	  	  	  	  	   Where PU_Id = @Level0Filter and
 	  	  	  	  	  	         Event_Type = @EventType
 	  	  	       Select @SQL =  'Select Distinct Id = r.Event_Reason_Id, Description = r.Event_Reason_Name ' + 
 	  	  	           'From Event_Reason_Tree_Data rt ' + 
 	  	  	           'Join Event_Reasons r on r.Event_Reason_Id = rt.Event_Reason_Id ' + 
 	  	  	           'Where rt.Tree_Name_Id = ' + convert(nvarchar(20),@TreeId) + ' and ' + 
 	  	  	                 'rt.Event_Reason_Level = ' + convert(nvarchar(20),@RequestedLevel) + ' '
          End
        Else
          Begin
 	  	  	       Select @SQL =  'Select Distinct Id = r.Event_Reason_Id, Description = r.Event_Reason_Name ' + 
 	  	  	           'From Event_Reason_Tree_Data rt ' + 
 	  	  	           'Join Event_Reasons r on r.Event_Reason_Id = rt.Event_Reason_Id ' + 
                'Join Prod_Events pe on pe.Name_id = rt.tree_name_id and pe.event_type = ' +  convert(nvarchar(20),@EventType) + ' ' +
                'Join Prod_Units pu on pu.pu_id = pe.pu_id and (pu.pu_id = ' + convert(nvarchar(20),@@UnitId) + ' or pu.master_unit = ' + convert(nvarchar(20),@@UnitId) + ')' +
 	  	  	           'Where rt.Event_Reason_Level = ' + convert(nvarchar(20),@RequestedLevel) + ' '            
          End
        If @RequestedLevel = 2 and @Level1Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level1Filter)
        Else If @RequestedLevel = 3 and @Level2Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level2Filter)
        Else If @RequestedLevel = 4 and @Level3Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level3Filter)
        Insert into #List 
          Exec (@SQL)
      End
    Else If @EventType = 11 and @RequestedLevel > 0
 	     --*********************************************
 	     -- These Trees ARE Variable Dependant
 	     --*********************************************
      Begin
        If @Level0Filter Is Not Null
          Begin
 	  	  	  	  	  	 Select @SQL = 'Select Distinct Id = r.Event_Reason_Id, Description = r.Event_Reason_Name ' + 
 	  	  	  	  	  	   'From Event_Reason_Tree_Data rt  ' + 
 	  	  	  	  	  	   'Join Event_Reasons r on r.Event_Reason_Id = rt.Event_Reason_Id ' +
 	  	  	  	  	  	   'Join Alarm_Templates t on ' + case when @IsCause = 1 Then 't.cause_tree_id' Else 't.action_tree_id' End + ' = rt.tree_name_id ' +
 	  	  	  	  	  	   'Join Alarm_Template_Var_data vd on vd.var_id = ' + convert(nvarchar(20),@Level0Filter) + ' and vd.at_id = t.at_id ' +
 	  	  	  	  	  	   'Where rt.Event_Reason_Level = ' + + convert(nvarchar(20),@RequestedLevel) + ' '            
          End
        Else
          Begin
 	  	  	  	  	  	 Select @SQL = 'Select Distinct Id = r.Event_Reason_Id, Description = r.Event_Reason_Name ' + 
 	  	  	  	  	  	   'From Event_Reason_Tree_Data rt  ' + 
 	  	  	  	  	  	   'Join Event_Reasons r on r.Event_Reason_Id = rt.Event_Reason_Id ' +
 	  	  	  	  	  	   'Join Alarm_Templates t on ' + case when @IsCause = 1 Then 't.cause_tree_id' Else 't.action_tree_id' End + ' = rt.tree_name_id ' +
 	  	  	  	  	  	   'Join Alarm_Template_Var_data vd on vd.at_id = t.at_id ' +
 	  	  	  	  	  	   'Join variables v on v.var_id = vd.var_id and v.Pu_Id <> 0 ' +
 	  	  	  	  	  	   'Join prod_units pu on pu.pu_id = ' + convert(nvarchar(20),@@UnitId) + ' or pu.master_unit = ' + convert(nvarchar(20),@@UnitId) + ' '+
 	  	  	  	  	  	   'Where rt.Event_Reason_Level = ' + + convert(nvarchar(20),@RequestedLevel) + ' '            
          End
        If @RequestedLevel = 2 and @Level1Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level1Filter)
        Else If @RequestedLevel = 3 and @Level2Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level2Filter)
        Else If @RequestedLevel = 4 and @Level3Filter Is Not Null
          Select @SQL = @SQL + ' and rt.Parent_Event_Reason_Id = ' + convert(nvarchar(20),@Level3Filter)
        Insert into #List 
          Exec (@SQL)
      End
    Else 
      Begin
        -- An Invalid Request Has Been Made
        Select Id = 0, Description = dbo.fnTranslate(@LangId, 34585, 'Invalid Request')
        Goto EndProcedure
      End
 	  	 Fetch Next From Unit_Cursor Into @@UnitId
  End
Select distinct Id, Description
  From #List
  Order By Description
EndProcedure:
Close Unit_Cursor
Deallocate Unit_Cursor  
Drop Table #List
Drop Table #Units

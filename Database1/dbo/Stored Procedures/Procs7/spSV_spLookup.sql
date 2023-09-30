CREATE Procedure dbo.spSV_spLookup 
@Field_Id int,
@LookupId int,
@LookUpString nvarchar(500) = Null,
@Sheet_Id int = NULL
AS
If @Field_Id = -4 --Control Type
  select [Id] = control_type_id, [Desc] = control_type_desc from control_type Order By control_type_desc asc
Else If @Field_Id = -5 --Order Type
  select [Id] = pp_type_id, [Desc] = pp_type_name from production_plan_types Order By pp_type_name asc
Else If @Field_Id = -6 --Product
  select [Id] = p.Prod_Id, [Desc] = p.Prod_Desc + ' - [' + p.Prod_Code + ']'
    from Products p 
    Join PrdExec_Path_Products pepp on pepp.Prod_Id = p.Prod_Id
    Where pepp.Path_Id = @Sheet_Id
    Order By [Desc]
Else If @Field_Id = 8 --Sampling Type
  select [Id] = st_id, [Desc] = st_desc from sampling_type Order By st_desc asc
Else If @Field_Id = 9 --Unit Id
  select [Id] = pu_id, [Desc] = pu_desc from prod_units Where PU_Id <> 0 Order By pu_desc asc
Else If @Field_Id = 10 --Variable Id
  select [Id] = var_id, [Desc] = var_desc from variables Where PU_Id <> 0 Order By var_desc asc
Else If @Field_Id = 13 --Type
  select [Id] = WET_Id, [Desc] = WET_Name from Waste_Event_Type Order By WET_Name asc
Else If @Field_Id = 14 --Measure
  select [Id] = WEMT_Id, [Desc] = WEMT_Name from Waste_Event_Meas Order By WEMT_Name asc
Else If @Field_Id = 15 --Reason
  select [Id] = Event_Reason_Id, [Desc] = Event_Reason_Name from Event_reasons Order By Event_Reason_Name asc
Else if @Field_Id = 16 --Production Status
  select [Id] = prodstatus_id, [Desc] = prodstatus_desc from production_status Order By prodstatus_desc asc
Else If @Field_Id = 23 --Characteristic
  select [Id] = Char_id, [Desc] = Char_desc From Characteristics Where Prop_Id = @LookupId Order By Char_desc asc
Else If @Field_Id = 24 --Color Scheme
  Select [Id] = CS_Id, [Desc] = CS_Desc From color_scheme Order By CS_Desc asc
Else If @Field_Id = 25 --Binary-.WAV File
  Select [Id] = Binary_Id, [Desc] = Binary_Desc From binaries Where Field_Type_Id = 25 Order By Binary_Desc asc
Else If @Field_Id = 27 --Event Type
    Execute spCmn_GetEventSubEventByUnit null, @LookUpString,1
--@Field_Id = 28 --Grid Font (See Below)
Else If @Field_Id = 29 --Tree Statistics
  BEGIN
    Select [Id] = Tree_Statistic_Id, [Desc] = Tree_Statistic_Desc
      From Tree_Statistics
  END
Else If @Field_Id = 30 --Access Level
  Select [Id] = AL_Id, [Desc] = AL_Desc   From access_level Order By AL_Desc asc
--@Field_Id = 31 --Fill Patterns (See Below)
--@Field_Id = 32 --Duration Format (See Below)
Else If @Field_Id = 33 --AutoLog Event-Based Displays
  Select [Id] = Sheet_Id, [Desc] = Sheet_Desc   From Sheets where sheet_Type = 2 or (Sheet_Type is null and Event_Type = 1) Order By Sheet_Desc asc
Else If @Field_Id = 34 --Colors
  Select [Id] = Color_Id, [Desc] = Color_Desc   From Colors  Order by Color_Desc asc
--@Field_Id = 38 --Threading Types (See Below)
Else If @Field_Id = 39 --Reason Tree
  select [Id] = Tree_Name_Id, [Desc] = Tree_Name from Event_Reason_Tree Order by Tree_Name asc
Else If @Field_Id = 40 --Reason By Tree
  select [Id] = er.Event_Reason_Id, [Desc] = Event_Reason_Name from Event_Reason_Tree_Data ertd
      Join Event_Reasons er on er.Event_Reason_Id = ertd.Event_Reason_Id
        Where Tree_Name_Id = @LookupId and ertd.Event_Reason_Level = 1 Order by Event_Reason_Name asc
Else If @Field_Id = 50 --SOE Event Types
  select [Id] = ET_Id, [Desc] = ET_Desc from Event_Types Where IncludeOnSoe = 1 Order by ET_Desc asc
Else If @Field_Id = 51 -- Stored Procedures
  select [Id] = id, [Desc] = Name from Sysobjects Where name like 'spLocal_%' and type = 'P' Order by Name
Else If @Field_Id = 52 -- Schedule View StartUp Mode
  Begin
    Declare @DisplayUnboundOrders bit
    Select @DisplayUnboundOrders = Value
      From Sheet_Display_Options
      Where Sheet_Id = @Sheet_Id
      And Display_Option_Id = 47
    Create Table #ScheduleFilters (SF_Id int, SF_Desc nvarchar(100), SF_Key_Id int, SF_Type nvarchar(50))
    Insert Into #ScheduleFilters (SF_Id, SF_Desc, SF_Key_Id, SF_Type)
      exec spSV_GetSchedFilters @Sheet_Id, NULL, NULL, NULL, @DisplayUnboundOrders
    select [Id] = SF_Key_Id, [Desc] = SF_Desc from #ScheduleFilters Order by SF_Desc asc
    Drop Table #ScheduleFilters
  End
Else If @Field_Id = 53 -- Language Desc
  select [Id] = Language_Id, [Desc] = Language_Desc from Languages Where Enabled = 1
Else If @Field_Id = 28 or @Field_Id = 31 or @Field_Id = 32 or @Field_Id = 38 or @Field_Id = 41 or
        @Field_Id = 42 or @Field_Id = 43 or @Field_Id = 44 or @Field_Id = 45 or @Field_Id = 46 or 
        @Field_Id = 47 or @Field_Id = 48 or @Field_Id = 49
  BEGIN
    Select [Id] = Field_Id, [Desc] = Field_Desc
      From ED_FieldType_ValidValues
      Where ED_Field_Type_Id = @Field_Id
      Order By Field_Desc asc
  END
Else
  Select [Id] = 1, [Desc] = 'spSV_spLookup - Lookup Error'

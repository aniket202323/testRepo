Create Procedure dbo.spRC_PreloadByMasterUnit
@pPu_id int,
@TreeType tinyint
AS
/*
Public Enum eReasonTreeTypes
  DowntimeCause = 1
  DowntimeAction = 2
  WasteCause = 3
  WasteAction = 4
  AlarmCause = 5
  AlarmAction = 6
  UDECause = 7
  UDEAction = 8
  ComplaintCause = 9
  ComplaintAction = 10
End Enum
*/
Create Table #UnitLists (
  ListName nvarchar(25),
  Id int,
  Description nvarchar(100),
  LinkNumber real NULL,
  LinkID int NULL
)
If @TreeType = 1 -- Downtime Cause
  Begin
    -- Return Units Resultset
    If (Select count(p.pu_id)
      From prod_units p
      Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 2   
      where ((master_unit = @pPu_id) or 
             (p.pu_id = @pPu_Id)) and 
             timed_event_association > 0 and 
             timed_event_association is not null) = 0
      Select 0 as PU_Id, '' as PU_Desc, 0 as Flags, 0 as Tree_Name_Id
    Else
      Select p.pu_id, p.pu_desc, Flags = 0, Tree_Name_Id = t.Name_Id
        From prod_units p
        Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 2   
        where ((master_unit = @pPu_id) or 
               (p.pu_id = @pPu_Id)) and 
               timed_event_association > 0 and 
               timed_event_association is not null
               order by master_unit
    -- Get Fault List
    If (Select count(*) From Timed_Event_Fault Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = TEFault_Id, Description = TEFault_Name
          From Timed_Event_Fault
          Where PU_Id = @pPU_Id
    -- Get Status List
    If (Select count(*) From Timed_Event_Status Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Status', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Status', Id = TEStatus_Id, Description = TEStatus_Name
          From Timed_Event_Status
          Where PU_Id = @pPU_Id
    Select * From #UnitLists order by ListName,Description
  End
Else If @TreeType = 2 -- Downtime Action
  Begin
    -- Return Units Resultset
    If (Select count(p.pu_id)
      From prod_units p
      Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 2   
      where ((master_unit = @pPu_id) or 
             (p.pu_id = @pPu_Id)) and 
             Action_Reason_Enabled = 1 and
             timed_event_association > 0 and 
             timed_event_association is not null) = 0
      Select 0 as PU_Id, '' as PU_Desc, 0 as Flags, 0 as Tree_Name_Id
    Else
      Select p.pu_id, p.pu_desc, Flags = 0, Tree_Name_Id = t.Action_Tree_Id
        From prod_units p
        Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 2   
        where ((master_unit = @pPu_id) or 
               (p.pu_id = @pPu_Id)) and 
               Action_Reason_Enabled = 1 and
               timed_event_association > 0 and 
               timed_event_association is not null
               order by master_unit
    -- Get Fault List
    If (Select count(*) From Timed_Event_Fault Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = TEFault_Id, Description = TEFault_Name
          From Timed_Event_Fault
          Where PU_Id = @pPU_Id
    -- Get Status List
    If (Select count(*) From Timed_Event_Status Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Status', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Status', Id = TEStatus_Id, Description = TEStatus_Name
          From Timed_Event_Status
          Where PU_Id = @pPU_Id
    Select * From #UnitLists order by ListName,Description
  End
Else If @TreeType = 3  -- Waste Cause
  Begin
    -- Return Units Resultset
    Select p.pu_id, p.pu_desc, Flags = p.waste_event_association, Tree_Name_Id = t.Name_Id
      From prod_units p
      Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 3
      where ((master_unit = @pPu_id) or 
             (p.pu_id = @pPu_Id)) and 
             waste_event_association > 0 and 
             waste_event_association is not null
             order by master_unit
    -- Get Fault List
    If (Select count(*) From Waste_Event_Fault Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = WEFault_Id, Description = WEFault_Name
          From Waste_Event_Fault
          Where PU_Id = @pPU_Id
    -- Get Type List
    If (Select count(*) From Waste_Event_Type) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Type', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Type', Id = WET_Id, Description = WET_Name
          From Waste_Event_Type
    -- Get Measurement List
    If (Select count(*) From Waste_Event_Meas Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Measurement', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description, LinkNumber, LinkId)
        Select ListName = 'Measurement', Id = WEMT_Id, Description = WEMT_Name, Conversion, Conversion_Spec
          From Waste_Event_Meas
         	 Where PU_Id = @pPU_Id
    Select * From #UnitLists order by ListName,Description
  End
Else If @TreeType = 4  -- Waste Action
  Begin
    -- Return Units Resultset
    Select p.pu_id, p.pu_desc, Flags = p.waste_event_association, Tree_Name_Id = t.Action_Tree_Id
      From prod_units p
      Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 3
      where ((master_unit = @pPu_id) or 
             (p.pu_id = @pPu_Id)) and 
             Action_Reason_Enabled = 1 and
             waste_event_association > 0 and 
             waste_event_association is not null
             order by master_unit
    -- Get Fault List
    If (Select count(*) From Waste_Event_Fault Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Fault', Id = WEFault_Id, Description = WEFault_Name
          From Waste_Event_Fault
          Where PU_Id = @pPU_Id
    -- Get Type List
    If (Select count(*) From Waste_Event_Type) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Type', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Type', Id = WET_Id, Description = WET_Name
          From Waste_Event_Type
    -- Get Measurement List
    If (Select count(*) From Waste_Event_Meas Where PU_Id = @pPU_Id) = 0
      Insert Into #UnitLists (ListName, ID, Description)
        Select ListName = 'Measurement', Id = 0, Description = ''
    Else
      Insert Into #UnitLists (ListName, ID, Description, LinkNumber, LinkId)
        Select ListName = 'Measurement', Id = WEMT_Id, Description = WEMT_Name, Conversion, Conversion_Spec
          From Waste_Event_Meas
         	 Where PU_Id = @pPU_Id
    Select * From #UnitLists order by ListName,Description
  End
Drop Table #UnitLists

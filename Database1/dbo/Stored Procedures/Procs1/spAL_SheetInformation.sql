--     spAL_SheetInformation 'ude'
Create Procedure dbo.spAL_SheetInformation 
  @SheetDesc nvarchar(50),
  @GetOptions int = NULL 
 AS
Declare @Sheet_Id int, @EventPrompt nVarchar(50), @Sheet_Type int, @PU_Id int
DECLARE @Ackrequired Int,@EventSubtypeId Int
SELECT @Sheet_Type = Sheet_Type, @PU_Id = Master_Unit, @EventPrompt = Event_Prompt,@Sheet_Id = Sheet_Id,
 	 @EventSubtypeId = s.Event_Subtype_Id 
  FROM Sheets s WHERE Sheet_Desc = @SheetDesc
--ECR#23751 - lookup EventSubType_Desc for Waste/Downtime Displays
If @Sheet_Type = 4 or @Sheet_Type = 5
  Begin
    SELECT @EventPrompt = Coalesce(Event_Subtype_Desc, @EventPrompt) FROM Event_Subtypes es
      join Event_Configuration ec on ec.Event_Subtype_Id = es.Event_Subtype_Id
        WHERE es.ET_id = 1 and ec.PU_Id = @PU_Id
  End
--ECR#23751 - lookup EventSubType_Desc for Waste/Downtime Displays
  SET @Ackrequired = 0
  If @Sheet_Type = 25
  Begin
    SELECT @Ackrequired = Coalesce(es.Ack_Required, 0) 
 	  	 FROM Event_Subtypes es
        WHERE es.Event_Subtype_Id = @EventSubtypeId
  End
SELECT 
  Sheet_Id,
  Sheet_Desc,
  Is_Active,
  Event_Type,
  Event_Subtype_Id,
  Master_Unit = 
    CASE
      WHEN Sheet_Type = 25 then Master_Unit
      WHEN Event_Type = 0 THEN NULL 
      WHEN Event_Type IS NULL THEN NULL 
      ELSE Master_Unit
    END,
  Event_Prompt = @EventPrompt,
  Interval,
  Offset,
  Initial_Count,
  Maximum_Count,
  Row_Headers,
  Column_Headers,
  Row_Numbering,
  Column_Numbering,
  Display_Event,
  Display_Date,
  Display_Time,
  Display_Grade,
  Display_Var_Order,
  Display_Data_Type,
  Display_Data_Source,
  Display_Spec,
  Display_Prod_Line,
  Display_Prod_Unit,
  Display_Description,
  Display_EngU,
  Group_Id = Coalesce(s.Group_Id, s1.Group_Id),
  Display_Spec_Win,
  Comment_Id,
  Sheet_Type,
  External_Link,
  Display_Comment_Win,
  Dynamic_Rows,
  Max_Edit_Hours,
  Wrap_Product,
  Max_Inventory_Days,
  s.Sheet_Group_Id,
  Auto_Label_Status,
  Display_Spec_Column,
  PL_Id,
  PEI_Id,
  Fault_Prompt = Event_Prompt,
  AckReq = @Ackrequired
 FROM sheets s -- (index=Sheets_By_Description) 
    Left Outer Join Sheet_Groups s1 on s1.Sheet_Group_Id = s.Sheet_Group_Id
    WHERE sheet_desc = @SheetDesc
If @GetOptions Is Not Null
  Begin
  Create Table #Display_Options (
    Display_Option_Id int, 
    Display_Option_Desc nvarchar(100),
    Value nvarchar(100)
    )
  Insert into #Display_Options (Display_Option_Id, Display_Option_Desc, Value)
  SELECT do.Display_Option_Id, do.Display_Option_Desc, sdo.Value
    FROM Sheet_Display_Options sdo
    Join Display_Options do on do.Display_Option_Id = sdo.Display_Option_Id
    WHERE sdo.Sheet_Id = @Sheet_id and COALESCE(sdo.Value, '') <> ''
  Insert into #Display_Options (Display_Option_Id, Display_Option_Desc, Value)
  SELECT stdo.Display_Option_Id, do.Display_Option_Desc, stdo.Display_Option_Default
    FROM Sheet_Type_Display_Options stdo
    Join Display_Options do on do.Display_Option_Id = stdo.Display_Option_Id
    WHERE stdo.Display_Option_Id not in (SELECT Display_Option_Id FROM #Display_Options)
      and stdo.Sheet_Type_Id = @Sheet_Type
      and stdo.Display_Option_Default is not NULL
  SELECT Display_Option_Id, Display_Option_Desc, Value FROM #Display_Options order by Display_Option_Desc
  Drop Table #Display_Options
  SELECT Testing_Status,Testing_Status_Desc FROM Test_Status 
  End

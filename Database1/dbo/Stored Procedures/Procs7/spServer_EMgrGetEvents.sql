CREATE PROCEDURE dbo.spServer_EMgrGetEvents    
AS
Declare
  @MaxECId int
Select @MaxECId = NULL
Select @MaxECId = Max(EC_Id) From Event_Configuration
If (@MaxECId Is NULL)
  Select @MaxECId = 1
Else
  Select @MaxECId = @MaxECId + 1
Declare @EventCfg Table(
 	 EC_Id int,
 	 PU_Id int NULL,
 	 PL_Id int NULL,
 	 PEI_Id int NULL,
 	 EC_Desc nVarChar(100) COLLATE DATABASE_DEFAULT NULL,
 	 Model_Num int,
 	 Field_Order int NULL,
 	 Field_Desc nVarChar(100) COLLATE DATABASE_DEFAULT NULL,
 	 ED_Field_Type_Id int NULL,
 	 Optional int NULL,
 	 Max_Instances int NULL,
 	 Alias nVarChar(100) COLLATE DATABASE_DEFAULT NULL,
 	 AliasPrecision int NULL,
 	 ECD_PU_Id int NULL,
 	 ED_Attribute_Id int NULL,
 	 ST_Id int NULL,
 	 IsTrigger int NULL,
 	 Sampling_Offset int NULL,
 	 Value text NULL,
 	 PUOrder int NULL,
 	 Excludes nVarChar(255) COLLATE DATABASE_DEFAULT NULL,
 	 TimedEventsAssociated int NULL,
 	 Priority int NULL,
 	 DebugMode int NULL,
 	 Event_SubType_Id int NULL,
 	 Event_SubType_Desc nVarChar(100) COLLATE DATABASE_DEFAULT NULL,
 	 Max_Run_Time int NULL,
 	 Model_Group int NULL,
 	 External_Time_Zone nVarChar(100) COLLATE DATABASE_DEFAULT NULL
)
Insert Into @EventCfg (EC_Id,PU_Id,PEI_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,AliasPrecision,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,PUOrder,Excludes,TimedEventsAssociated,Priority,DebugMode,Event_SubType_Id,Event_SubType_Desc,Max_Run_Time,Model_Group,External_Time_Zone)
(Select a.EC_Id,a.PU_Id,a.PEI_Id,a.EC_Desc,
        ModelNum = Case 
                     When b.Derived_From Is NULL Then b.Model_Num
                     When b.Derived_From = 0 Then b.Model_Num
                     Else b.Derived_From
                   End,
 	 FieldOrder = COALESCE(c.Field_Order,1),
 	 c.Field_Desc,
 	 FieldType = COALESCE(c.ED_Field_Type_Id,1),
 	 Optional = COALESCE(c.Optional,1),
 	 MaxInstances = COALESCE(c.Max_Instances,1),
 	 d.Alias,d.Input_Precision,d.PU_Id,d.ED_Attribute_Id,d.ST_Id,d.IsTrigger,d.Sampling_Offset ,
 	 e.Value,
 	 f.PU_Order,
 	 a.Exclusions,
 	 f.Timed_Event_Association,
 	 a.Priority,
 	 a.Debug,
 	 a.Event_SubType_Id,
 	 s.Event_Subtype_Desc,
 	 a.Max_Run_Time,
 	 a.Model_Group,
 	 a.External_Time_Zone
  From Event_Configuration a
  Join ED_Models b on (a.ED_Model_Id = b.ED_Model_Id)
  Left Outer Join ED_Fields c on (c.ED_Model_Id = a.ED_Model_Id)
  Left Outer Join Event_Configuration_Data d on (d.EC_Id = a.EC_Id) And (d.ED_Field_Id = c.ED_Field_Id)
  Left Outer Join Event_Configuration_Values e on (e.ECV_Id = d.ECV_Id)
  Left Outer Join Prod_Units_Base f on f.PU_Id = d.PU_Id
 	 Left Outer Join Event_Subtypes s on s.Event_SubType_Id = a.Event_SubType_Id
  Where (a.Is_Active = 1))
Delete @EventCfg Where (ED_Field_Type_Id Between 17 and 20) and Value is null 
Insert Into @EventCfg (
EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value, AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2000,1,'Input Tag',3,0,1,'',0,0,0,0,0,'PT:' + a.Input_Tag, a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And 
        (a.Sampling_Type = 19) And 
        (a.Input_Tag Is Not NULL) And
        (a.Event_Type = 1) And
        (a.DS_Id = 3) And
        (a.ShouldArchive = 1))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2000,2,'Var Id',10,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.Var_Id), a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And 
        (a.Sampling_Type = 19) And 
        (a.Input_Tag Is Not NULL) And
        (a.Event_Type = 1) And
        (a.DS_Id = 3) And
        (a.ShouldArchive = 1))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value, AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2000,3,'Extended Info',3,0,1,'',0,0,0,0,0,a.Extended_Info,a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And 
        (a.Sampling_Type = 19) And 
        (a.Input_Tag Is Not NULL) And
        (a.Event_Type = 1) And
        (a.DS_Id = 3) And
        (a.ShouldArchive = 1))
Insert Into @EventCfg (
EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2001,1,'Input Tag',3,0,1,'',0,0,0,0,0,'PT:' + a.Input_Tag,a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And 
        (a.Sampling_Type = 28) And 
        (a.Input_Tag Is Not NULL) And
        (a.DS_Id = 3))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2001,2,'Var Id',10,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.Var_Id),a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And 
        (a.Sampling_Type = 28) And 
        (a.Input_Tag Is Not NULL) And
        (a.DS_Id = 3))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2001,3,'Should Archive',2,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.ShouldArchive),a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And 
        (a.Sampling_Type = 28) And 
        (a.Input_Tag Is Not NULL) And
        (a.DS_Id = 3))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2002,1,'Var Id',10,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.Var_Id),a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And (a.Event_Dimension Is Not NULL) And (Event_Type = 1))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2002,2,'Dimension',2,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.Event_Dimension),a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And (a.Event_Dimension Is Not NULL) And (Event_Type = 1))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2003,1,'Var Id',10,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.Var_Id),a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And (a.Event_Dimension Is Not NULL) And (Event_Type = 17))
Insert Into @EventCfg (EC_Id,PU_Id,EC_Desc,Model_Num,Field_Order,Field_Desc,ED_Field_Type_Id,Optional,Max_Instances,Alias,ECD_PU_Id,ED_Attribute_Id,ST_Id,IsTrigger,Sampling_Offset,Value,AliasPrecision)
(Select @MaxECId + a.Var_Id,
        	 PUId = Case When b.Master_Unit Is NULL Then b.PU_Id Else b.Master_Unit End,
 	 a.Var_Desc,2003,2,'Dimension',2,0,1,'',0,0,0,0,0,Convert(nVarChar(100),a.Event_Dimension),a.var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Where (a.Is_Active = 1) And (a.Event_Dimension Is Not NULL) And (Event_Type = 17))
Update @EventCfg set Max_Run_Time = 0 where Max_Run_Time is NULL
Update @EventCfg set Model_Group = 0 where Model_Group is NULL
Select 	 a.EC_Id,
 	 a.PU_Id,
 	 a.EC_Desc,
 	 a.Model_Num,
 	 a.Field_Order,
 	 a.Field_Desc,
 	 a.ED_Field_Type_Id,
 	 a.Optional,
 	 a.Max_Instances,
 	 a.Alias,
 	 a.ECD_PU_Id,
 	 a.ED_Attribute_Id,
 	 a.ST_Id,
 	 a.IsTrigger,
 	 a.Sampling_Offset,
 	 a.Value,
  a.PUOrder,
  a.PEI_Id,
  a.Excludes,
 	 a.TimedEventsAssociated,
 	 a.AliasPrecision,
  b.PL_Id,
  a.DebugMode,
 	 a.Event_SubType_Id,
 	 a.Event_SubType_Desc,
 	 a.Max_Run_Time,
 	 a.Model_Group,
  dbo.fnServer_GetTimeZone(a.PU_Id),
 	 a.External_Time_Zone
  From @EventCfg a
  Join Prod_Units_Base b on (b.PU_Id = a.PU_Id)
  Order By a.Priority,a.Model_Num,a.EC_Id,a.Field_Order,a.Alias

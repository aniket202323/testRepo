CREATE Procedure dbo.spEMED_spLookup 
@Field_Id int,
@LookupId int,
@LookUpString nvarchar(500) = Null,
@Sheet_Id int = NULL
AS
/* ##### spEMED_spLookup #####
Description 	 : Returns data for user defined parameters used for a particular unit along with other properties
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	 Added condition for FieldId = 78
*/
If @Field_Id = 8 --Sampling Type
  select [Id] = st_id, [Desc] = st_desc from sampling_type Where ST_Id <> 48 Order By st_desc asc
Else If @Field_Id = 9 --Unit Id
  select [Id] = pu_id, [Desc] = pu_desc from prod_units Where PU_Id <> 0 Order By pu_desc asc
Else If @Field_Id = 10 --Variable Id
  select [Id] = var_id, [Desc] = var_desc from variables Where PU_Id <> 0 Order By var_desc asc
Else If @Field_Id = 13 --Type
  select [Id] = WET_Id, [Desc] = WET_Name from Waste_Event_Type Order By WET_Name asc
Else If @Field_Id = 14 --Measure
 	 BEGIN
 	  	 IF @LookupId is null or @LookupId = 0
 	  	  	 select [Id] = WEMT_Id, [Desc] = WEMT_Name from Waste_Event_Meas Order By WEMT_Name asc
 	  	 ELSE
 	  	  	 select [Id] = WEMT_Id, [Desc] = WEMT_Name from Waste_Event_Meas Where PU_Id =  @LookUpString and Conversion =  @LookupId Order By WEMT_Name asc
 	 END
Else If @Field_Id = 15 --Reason
  select [Id] = Event_Reason_Id, [Desc] = Event_Reason_Name from Event_reasons Order By Event_Reason_Name asc
Else if @Field_Id = 16 --Production Status
  select [Id] = prodstatus_id, [Desc] = prodstatus_desc from production_status Order By prodstatus_desc asc
Else If @Field_Id = 23
 	 IF 	 @LookupId is null or @LookupId = 0
 	   select [Id] = Char_id, [Desc] = '[' + Prop_Desc + '] ' +  Char_desc  
 	  	 From Characteristics a
 	  	 Join Product_Properties b on a.Prop_Id = b.prop_Id
 	  	  Order By Prop_Desc,Char_desc asc
 	 ELSE
 	  	 select [Id] = Char_id, [Desc] = Char_desc 
 	  	  	 From Characteristics Where Prop_Id = @LookupId 
 	  	  	 Order By Char_desc asc
Else If @Field_Id = 23 --Characteristic
  select [Id] = Char_id, [Desc] = '[' + Prop_Desc + '] ' +  Char_desc  
 	 From Characteristics a
 	 Join Product_Properties b on a.Prop_Id = b.prop_Id
 	  Order By Char_desc asc
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
  Select [Id] = Color_Id, [Desc] = Color_Desc, Color From Colors  Order by Color_Desc asc
Else If @Field_Id = 35 -- Customer
  select [Id] = Customer_Id, [Desc] = Customer_Code from Customer Order by Customer_Code
Else If @Field_Id = 36 -- Products
  select [Id] = Prod_Id, [Desc] = Prod_Code from Products Order by Prod_Code
Else If @Field_Id = 37 -- Product Group
  select [Id] = Product_Grp_Id, [Desc] = Product_Grp_Desc from Product_Groups Order by Product_Grp_Desc
Else If @Field_Id = 39 --Reason Tree
  select [Id] = Tree_Name_Id, [Desc] = Tree_Name from Event_Reason_Tree Order by Tree_Name asc
Else If @Field_Id = 40 --Reason By Tree
  IF  @LookupId = 0
  Begin
  select [Id] = er.Event_Reason_Id, [Desc] = Event_Reason_Name from Event_Reason_Tree_Data ertd
      Join Event_Reasons er on er.Event_Reason_Id = ertd.Event_Reason_Id
        Where Tree_Name_Id = @LookupId and ertd.Event_Reason_Level = 1 Order by Event_Reason_Name asc
 End
 ELSE
 BEGIN
  select [Id] = er.Event_Reason_Id, [Desc] = '[' + a.Tree_Name  + '] ' + er.Event_Reason_Name 
 	 from Event_Reason_Tree_Data ertd
      Join Event_Reasons er on er.Event_Reason_Id = ertd.Event_Reason_Id
      Join Event_Reason_Tree a on a.Tree_Name_Id = ertd.Tree_Name_Id
        Where  ertd.Event_Reason_Level = 1 Order by a.Tree_Name,Event_Reason_Name asc
 END
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
    Create Table #ScheduleFilters (SF_Id int, SF_Desc nVarChar(100), SF_Key_Id int, SF_Type nvarchar(50))
    Insert Into #ScheduleFilters (SF_Id, SF_Desc, SF_Key_Id, SF_Type)
      exec spSV_GetSchedFilters @Sheet_Id, NULL, NULL, NULL, @DisplayUnboundOrders
    select [Id] = SF_Key_Id, [Desc] = SF_Desc from #ScheduleFilters Order by SF_Desc asc
    Drop Table #ScheduleFilters
  End
Else If @Field_Id = 53 -- Language Desc
  select [Id] = Language_Id, [Desc] = Language_Desc from Languages Where Enabled = 1
Else If @Field_Id = 57 --Email Groups
  select [Id] = EG_Id, [Desc] = EG_Desc from Email_Groups Where EG_Id <> 50 Order by EG_Desc asc
Else If @Field_Id in( 28,31,32,38,41,42,43,44,45,46,47,48,49,55,56,60,62,64,65,70,74,76,77,78,79,81,82,83,84)
  BEGIN
    Select [Id] = Field_Id, [Desc] = Field_Desc
      From ED_FieldType_ValidValues
      Where ED_Field_Type_Id = @Field_Id
      Order By Field_Desc asc
  END
Else If @Field_Id = 59 -- Paths
  select [Id] = Path_Id, [Desc] = Path_Desc from PrdExec_Paths Order by Path_Desc
Else If @Field_Id = 61 -- Product Family
  select [Id] = Product_Family_Id, [Desc] = Product_Family_Desc from product_family Order by Product_Family_Desc
Else If @Field_Id = 63 -- Data Source
  select [Id] = DS_Id, [Desc] = DS_Desc from Data_Source Where DS_Id <> 50000 and Active = 1 Order by DS_Desc
Else If @Field_Id = 75 -- Test Status
  select [Id] = Testing_Status, [Desc] = Testing_Status_Desc from Test_Status Order by Testing_Status_Desc
Else If @Field_Id = 80 --Master Unit Id
  select [Id] = pu_id, [Desc] = pu_desc from prod_units Where PU_Id <> 0 and Master_Unit is null Order By pu_desc asc
Else
  Select [Id] = 1, [Desc] = 'spEMED_spLookup - Lookup Error'

CREATE Procedure dbo.spSupport_MultiLingual_Add 
 	 @Password  	 Varchar(100)
As
  If @Password <> 'Proficy' Return(0) /*This sp is called from the install, password is used to protect it from being called manually */
 	 /* Set Multi-Lingual Enabled parameter to True */
 	 Update Site_Parameters set Value = 1 Where Parm_Id = 72
 	 If @@RowCount = 0 Insert into Site_Parameters (Parm_Id,Hostname,Value,Parm_Required) values (72,'',1,0)
 	 
 	 /****** Production Status ******/
    /****** Production Plan Statuses ******/
    if Not exists (select * from sys.syscolumns where name = 'PP_Status_Desc_Local' and id = object_id(N'[Production_Plan_Statuses]'))
    Begin
            Execute spSupport_CreateCalculatedColumn 'Production_Plan_Statuses', 'PP_Status_Desc', 'VarChar(50)', 'PP_Statuses_UC_PPStatus_Desc'
    End
 	 /****** Waste Event Type ******/
 	 if Not exists (select * from sys.syscolumns where name = 'WET_Name_Local' and id =  object_id(N'[Waste_Event_Type]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Waste_Event_Type','WET_Name','VarChar(100)','WasteEventType_UC_Name'
 	 End
 	 /******Event Reasons ******/
 	 /******Event Reasons Tree ******/
 	 /****** Sheet Groups ******/
 	 if Not exists (select * from sys.syscolumns where name = 'Sheet_Group_Desc_Local' and id =  object_id(N'[Sheet_Groups]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Sheet_Groups','Sheet_Group_Desc','VarChar_Desc','SheetGrps_UC_ShtGrpDesc'
 	 End
 	 /****** Views ******/
 	 /****** Product Family ******/
 	 /****** Characteristic Groups ******/
 	 if Not exists (select * from sys.syscolumns where name = 'Characteristic_Grp_Desc_Local' and id =  object_id(N'[Characteristic_Groups]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Characteristic_Groups','Characteristic_Grp_Desc','VarChar_Desc','CharGroups_UC_GrpDescPropId','Prop_Id'
 	 End
 	 /****** PU Groups ******/
 	 /****** Sheets ******/
 	 /****** Product Groups ******/
 	 if Not exists (select * from sys.syscolumns where name = 'Product_Grp_Desc_Local' and id =  object_id(N'[Product_Groups]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Product_Groups','Product_Grp_Desc','VarChar_Desc','ProductGroups_By_Description'
 	 End
 	 /****** Product Description ******/
 	 /****** Product Properties ******/
 	 /****** Characteristics ******/
 	 if Not exists (select * from sys.syscolumns where name = 'Char_Desc_Local' and id =  object_id(N'[Characteristics]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Characteristics','Char_Desc','VarChar_Desc','Char_UC_CharDescPropId','Prop_Id'
 	 End
 	 /****** Specifications ******/
 	 /****** Prod_Lines ******/
 	 /****** Prod_Units ******/
 	 /****** Variables ******/
 	 /****** Event_Reason_Catagories ******/
 	 if Not exists (select * from sys.syscolumns where name = 'Level_Name_Local' and id =  object_id(N'[Event_Reason_Level_Headers]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Event_Reason_Level_Headers','Level_Name','VarChar(100)'
 	 End
 	 /****** Departments ******/
 	 if Not exists (select * from sys.syscolumns where name = 'View_Group_Desc_Local' and id =  object_id(N'[View_Groups]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'View_Groups','View_Group_Desc','Varchar(50)','ViewGrps_UC_ViewGrpDesc'
 	 End
 	 if Not exists (select * from sys.syscolumns where name = 'WEMT_Name_Local' and id =  object_id(N'[Waste_Event_Meas]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Waste_Event_Meas','WEMT_Name','Varchar(100)'
 	 End
 	 if Not exists (select * from sys.syscolumns where name = 'Shortcut_Name_Local' and id =  object_id(N'[Reason_Shortcuts]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Reason_Shortcuts','Shortcut_Name','Varchar(25)'
 	 End
 	 if Not exists (select * from sys.syscolumns where name = 'WEFault_Name_Local' and id =  object_id(N'[Waste_Event_Fault]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Waste_Event_Fault','WEFault_Name','Varchar(100)'
 	 End
 	 if Not exists (select * from sys.syscolumns where name = 'TEStatus_Name_Local' and id =  object_id(N'[Timed_Event_Status]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Timed_Event_Status','TEStatus_Name','Varchar(100)'
 	 End
 	 if Not exists (select * from sys.syscolumns where name = 'TEFault_Name_Local' and id =  object_id(N'[Timed_Event_Fault]'))
 	 Begin
 	  	 Execute spSupport_CreateCalculatedColumn 'Timed_Event_Fault','TEFault_Name','Varchar(100)'
 	 End

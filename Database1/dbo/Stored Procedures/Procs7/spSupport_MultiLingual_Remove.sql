CREATE Procedure dbo.spSupport_MultiLingual_Remove 
 	 @Password  	 Varchar(100)
As
  If @Password <> 'Proficy' Return(0) /*Password is used to protect it from being called manually */
 	 /* Set Multi-Lingual Enabled parameter to False */
 	 Update Site_Parameters set Value = 0 Where Parm_Id = 72
 	 
        /****** Production Plan Statuses ******/
    if Exists (select * from sys.syscolumns where name = 'PP_Status_Desc_Local' and id = object_id(N'[Production_Plan_Statuses]'))
    Begin
            Execute spSupport_DropCalculatedColumn 'Production_Plan_Statuses', 'PP_Status_Desc', 'VarChar(50)', 'PP_Statuses_UC_PPStatus_Desc'
    End
 	 /****** Waste Event Type ******/
 	 if Exists (select * from sys.syscolumns where name = 'WET_Name_Local' and id =  object_id(N'[Waste_Event_Type]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Waste_Event_Type','WET_Name','VarChar(100)','WasteEventType_UC_Name'
 	 End
 	 --/******Event Reasons ******/
 	 --if Exists (select * from sys.syscolumns where name = 'Event_Reason_Name_Local' and id =  object_id(N'[Event_Reasons]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Event_Reasons','Event_Reason_Name','VarChar(100)','Event_Reasons_UC_Name'
 	 --End
 	 /******Event Reasons Tree ******/
 	 --if Exists (select * from sys.syscolumns where name = 'Tree_Name_Local' and id =  object_id(N'[Event_Reason_Tree]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Event_Reason_Tree','Tree_Name','VarChar_Desc','Evt_Rsn_Tree_UC_TreeName'
 	 --End
 	 /****** Sheet Groups ******/
 	 if Exists (select * from sys.syscolumns where name = 'Sheet_Group_Desc_Local' and id =  object_id(N'[Sheet_Groups]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Sheet_Groups','Sheet_Group_Desc','VarChar_Desc','SheetGrps_UC_ShtGrpDesc'
 	 End
 	 /****** Views ******/
 	 --if Exists (select * from sys.syscolumns where name = 'View_Desc_Local' and id =  object_id(N'[Views]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Views','View_Desc','VarChar_Desc','Views_UC_ViewDesc'
 	 --End
 	 
 	 /****** Product Family ******/
 	 --If Exists (select * from sys.syscolumns where name = 'Product_Family_Desc_Local' and id =  object_id(N'[Product_Family]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Product_Family','Product_Family_Desc','VarChar_Desc','ProductFamily_UC_ProdDesc'
 	 --End
 	 
 	 /****** Characteristic Groups ******/
 	 if Exists (select * from sys.syscolumns where name = 'Characteristic_Grp_Desc_Local' and id =  object_id(N'[Characteristic_Groups]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Characteristic_Groups','Characteristic_Grp_Desc','VarChar_Desc','CharGroups_UC_GrpDescPropId','Prop_Id'
 	 End
 	 
 	 /****** Sheets ******/
 	 --if Exists (select * from sys.syscolumns where name = 'Sheet_Desc_Local' and id =  object_id(N'[Sheets]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Sheets','Sheet_Desc','VarChar_Desc','Sheets_By_Description'
 	 --End
 	 /****** Product Groups ******/
 	 if Exists (select * from sys.syscolumns where name = 'Product_Grp_Desc_Local' and id =  object_id(N'[Product_Groups]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Product_Groups','Product_Grp_Desc','VarChar_Desc','ProductGroups_By_Description'
 	 End
 	 /****** Product Properties ******/
 	 --if Exists (select * from sys.syscolumns where name = 'Prop_Desc_Local' and id =  object_id(N'[Product_Properties]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Product_Properties','Prop_Desc','VarChar_Desc','ProdProps_UC_PropDesc'
 	 --End
 	 /****** Characteristics ******/
 	 if Exists (select * from sys.syscolumns where name = 'Char_Desc_Local' and id =  object_id(N'[Characteristics]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Characteristics','Char_Desc','VarChar_Desc','Char_UC_CharDescPropId','Prop_Id'
 	 End
 	 /****** Specifications ******/
 	 --if Exists (select * from sys.syscolumns where name = 'Spec_Desc_Local' and id =  object_id(N'[Specifications]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Specifications','Spec_Desc','VarChar_Desc','Specs_UC_PropIdSpecDesc','Prop_Id'
 	 -- 	 CREATE  INDEX [Specifications_By_Desc] ON [dbo].[Specifications]([Spec_Desc])
 	 --End
 	 --if exists (select * from sys.syscolumns where name = 'ERC_Desc_Local' and id =  object_id(N'[Event_Reason_Catagories]'))
 	 --Begin
 	 -- 	 Execute spSupport_DropCalculatedColumn 'Event_Reason_Catagories','ERC_Desc','VarChar_Desc','EvtRsnCat_UC_ERCDesc'
 	 --End
 	 if exists (select * from sys.syscolumns where name = 'Level_Name_Local' and id =  object_id(N'[Event_Reason_Level_Headers]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Event_Reason_Level_Headers','Level_Name','VarChar(100)'
 	 End
 	 if Exists (select * from sys.syscolumns where name = 'View_Group_Desc_Local' and id =  object_id(N'[View_Groups]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'View_Groups','View_Group_Desc','Varchar(50)','ViewGrps_UC_ViewGrpDesc'
 	 End
 	 if Exists (select * from sys.syscolumns where name = 'WEMT_Name_Local' and id =  object_id(N'[Waste_Event_Meas]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Waste_Event_Meas','WEMT_Name','Varchar(100)'
 	 End
 	 if Exists (select * from sys.syscolumns where name = 'Shortcut_Name_Local' and id =  object_id(N'[Reason_Shortcuts]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Reason_Shortcuts','Shortcut_Name','Varchar(25)'
 	 End
 	 if Exists (select * from sys.syscolumns where name = 'WEFault_Name_Local' and id =  object_id(N'[Waste_Event_Fault]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Waste_Event_Fault','WEFault_Name','Varchar(100)'
 	 End
 	 if Exists (select * from sys.syscolumns where name = 'TEStatus_Name_Local' and id =  object_id(N'[Timed_Event_Status]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Timed_Event_Status','TEStatus_Name','Varchar(100)'
 	 End
 	 if Exists (select * from sys.syscolumns where name = 'TEFault_Name_Local' and id =  object_id(N'[Timed_Event_Fault]'))
 	 Begin
 	  	 Execute spSupport_DropCalculatedColumn 'Timed_Event_Fault','TEFault_Name','Varchar(100)'
 	 End

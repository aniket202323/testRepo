CREATE    Procedure dbo.spSupport_FixEdModels
@Password VarChar(10)
As
If @Password <> 'EdModel' 
 Begin 
  Print 'Failed - Password Incorrect'
  Return
 End
if exists (select * from sys.sysobjects where id = object_id(N'[Old_Event_Configuration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  Begin
 	 Print 'Failed - Old_Event_Configuration already exists'
 	 Return
  End
if exists (select * from sys.sysobjects where id = object_id(N'[Old_Event_Configuration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  Begin
 	 Print 'Failed - Old_Event_Configuration_Data already exists' 
 	 Return
  End
if exists (select * from sys.sysobjects where id = object_id(N'[Old_Event_Configuration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  Begin
 	 Print 'Failed - Old_Event_Configuration_Values already exists' 
 	 Return
  End
Set NoCount ON
CREATE TABLE [Old_Event_Configuration] (
 	 [EC_Id] [int] NULL ,
 	 [PEI_Id] [int] NULL ,
 	 [Event_Subtype_Id] [int] NULL ,
 	 [Comment_Id] [int] NULL ,
 	 [PU_Id] [int] NULL ,
 	 [ED_Model_Id] [int] NULL ,
 	 [ET_Id] [tinyint] NULL ,
 	 [Is_Active] [tinyint]  NULL ,
 	 [EC_Desc] [varchar] (50)  NULL ,
 	 [Extended_Info] [varchar] (255)  NULL ,
 	 [Exclusions] [varchar] (255)  NULL,
 	 [Model_Num] [int] NULL  	  
) 
Insert Into Old_Event_Configuration (EC_Id,PEI_Id,Event_Subtype_Id,Comment_Id,PU_Id,
 	  	  	 ED_Model_Id,ET_Id,Is_Active,EC_Desc,Extended_Info,Exclusions,Model_Num)
 Select ec.EC_Id,ec.PEI_Id,ec.Event_Subtype_Id,ec.Comment_Id,ec.PU_Id,
 	 ec.ED_Model_Id,ec.ET_Id,ec.Is_Active,ec.EC_Desc,ec.Extended_Info,ec.Exclusions,em.Model_Num
 From Event_Configuration ec
 Left Join ED_Models em on em.ED_Model_Id = ec.ED_Model_Id
CREATE TABLE [Old_Event_Configuration_Data] (
 	 [ECV_Id] [int]  NULL ,
 	 [ED_Field_Id] [int]  NULL ,
 	 [Sampling_Offset] [int] NULL ,
 	 [PEI_Id] [int] NULL ,
 	 [PU_Id] [int] NULL ,
 	 [ED_Attribute_Id] [int] NULL ,
 	 [EC_Id] [int]  NULL ,
 	 [ST_Id] [tinyint] NULL ,
 	 [IsTrigger] [tinyint] NULL ,
 	 [Input_Precision] [tinyint]  NULL ,
 	 [Alias] [varchar] (50)  NULL,
 	 [Field_Order] [int]  NULL ) 
Insert into Old_Event_Configuration_Data (ECV_Id,ED_Field_Id,Sampling_Offset,PEI_Id,
 	  	  	 PU_Id,ED_Attribute_Id,EC_Id,ST_Id,IsTrigger,Input_Precision,Alias,Field_Order)
  Select ecd.ECV_Id,ecd.ED_Field_Id,ecd.Sampling_Offset,ecd.PEI_Id,ecd.PU_Id,ecd.ED_Attribute_Id,
 	 ecd.EC_Id,ecd.ST_Id,ecd.IsTrigger,ecd.Input_Precision,ecd.Alias,ef.Field_Order
  From Event_Configuration_Data ecd
  Left Join ED_Fields ef On ef.ED_Field_Id = ecd.ED_Field_Id
CREATE TABLE [Old_Event_Configuration_Values] (
 	 [ECV_Id] [int]   NULL ,
 	 [Value] [text]   NULL ) 
Insert Into Old_Event_Configuration_Values (ECV_Id,Value)
 Select ECV_Id,Value 
  From Event_Configuration_Values
Print '****************************'
Print 'Make sure you have the current verify scripts from MSI before continuing.'
Print '****************************'
Print ''
Print 'Success - If There are no errors above this and you have the current verifies '
Print 'it is okay to run spSupport_FixEdModels2'
Set NoCount OFF

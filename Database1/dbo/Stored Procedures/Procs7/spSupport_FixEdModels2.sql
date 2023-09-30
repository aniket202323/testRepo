CREATE    Procedure dbo.spSupport_FixEdModels2
@Password VarChar(10)
As
Set NoCount ON
If @Password <> 'EdModel' 
 Begin 
  Print 'Failed - Password Incorrect'
  Return
 End
if Not exists (select * from sys.sysobjects where id = object_id(N'[Old_Event_Configuration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  Begin
 	 Print 'Failed - Old_Event_Configuration does not exist'
 	 Return
  End
if Not exists (select * from sys.sysobjects where id = object_id(N'[Old_Event_Configuration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  Begin
 	 Print 'Failed - Old_Event_Configuration_Data does not exist' 
 	 Return
  End
if Not exists (select * from sys.sysobjects where id = object_id(N'[Old_Event_Configuration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
  Begin
 	 Print 'Failed - Old_Event_Configuration_Values does not exist' 
 	 Return
  End
Delete From  Event_Configuration_Values Where Ecv_Id Not IN  (Select Ecv_Id From Event_Configuration_Data Where Ec_Id  IN (Select EC_Id From  Event_Configuration Where Ed_Model_Id > 50000 or ED_Model_Id Is Null))
Delete From  Event_Configuration_Data Where Ec_Id Not IN (Select EC_Id From  Event_Configuration Where Ed_Model_Id > 50000 or ED_Model_Id Is Null)
Delete From  Event_Configuration Where Ed_Model_Id < 50000 or ED_Model_Id Is Null
Delete From Ed_Fields Where ED_Model_Id < 50000
Delete From ED_Models Where Ed_Model_Id < 50000
Print '***********************'
Print 'Run the verifies now'
Print '***********************'
Print ''
Print 'After the Verifies are complete run spSupport_FixEdModels3'
Set NoCount OFF

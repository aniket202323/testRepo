Create Procedure dbo.spEMAC_UpdateSPCTriggers
@AT_Id int,
@Alarm_SPC_Rule_Id int,
@Alarm_SPC_Rule_Property_Id int,
@nValue nVarChar(25),
@mValue nVarChar(25),
@Firing_Priority smallint,
@AP_Id int,
@SPC_Group_Variable_Type_Id int,
@Operation int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateSPCTriggers',
             Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@Alarm_SPC_Rule_Id) + ','  + 
             Convert(nVarChar(10),@Alarm_SPC_Rule_Property_Id) + ','  + 
 	  	  	  	      @nValue + ','  + @mValue + ',' +
             Convert(nVarChar(10),@Firing_Priority) + ','  + 
             Convert(nVarChar(10),@AP_Id) + ','  + 
             Convert(nVarChar(10),@SPC_Group_Variable_Type_Id) + ','  + 
             Convert(nVarChar(10),@Operation) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
-- Operations
-- 1 = Check
-- 2 = UnCheck
-- 3 = Move Up
-- 4 = Move Down
Declare @Exists int
Declare @Next_Firing_Priority tinyint
Declare @This_Firing_Priority int
Declare @Adjacent_Firing_Priority int
Declare @This_ATSRD_Id int
If @SPC_Group_Variable_Type_Id is NULL
  Begin
 	  	 Select @This_Firing_Priority = Firing_Priority
 	  	   From Alarm_Template_SPC_Rule_Data 
 	  	   Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null
  End
Else
  Begin
 	  	 Select @This_Firing_Priority = Firing_Priority
 	  	   From Alarm_Template_SPC_Rule_Data 
 	  	   Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id
  End
if @Operation = 1
  Begin
 	  	 If @SPC_Group_Variable_Type_Id is NULL
 	  	   Begin
        Select @Exists = count(*) from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null
      End
    Else
 	  	   Begin
        Select @Exists = count(*) from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id
      End
    if @Exists = 0
      Begin
        Select @Next_Firing_Priority = max(Firing_Priority) From Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id
        If @Next_Firing_Priority Is Null 
          Select @Next_Firing_Priority = 1
        Else 
          Select @Next_Firing_Priority = @Next_Firing_Priority + 1
        Insert into Alarm_Template_SPC_Rule_Data (AT_Id, Alarm_SPC_Rule_Id, Firing_Priority, AP_Id, SPC_Group_Variable_Type_Id) values (@AT_Id, @Alarm_SPC_Rule_Id, @Next_Firing_Priority, @AP_Id, @SPC_Group_Variable_Type_Id)
        Select @This_ATSRD_Id = Scope_Identity()
        Insert into Alarm_Template_SPC_Rule_Property_Data (ATSRD_Id, Alarm_SPC_Rule_Property_Id, Value,mValue) values (@This_ATSRD_Id, @Alarm_SPC_Rule_Property_Id, @nValue,@mValue)
 	  	  	  	 --Create the Var_Data rows that link SPC Group variables to this new Rule
        If Not @SPC_Group_Variable_Type_Id is NULL
          Begin
            If @SPC_Group_Variable_Type_Id = 5 or @SPC_Group_Variable_Type_Id = 6
              Begin
 	  	  	  	  	  	  	   Insert into Alarm_Template_Var_Data (AT_Id, Var_Id, ATSRD_Id)
 	  	  	  	  	  	  	     Select @AT_Id, v.Var_Id, @This_ATSRD_Id From Variables v
 	  	                 Join Alarm_Template_Var_Data atv on atv.Var_Id = v.Var_Id and atv.AT_Id = @AT_Id
 	  	                 Where v.SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id and atv.ATSRD_Id is NULL
              End
            Else
              Begin  --Variable_Types 1,2,3 and 4 are child variables of the Variable that actually assigned to the template
 	  	  	  	  	  	  	   Insert into Alarm_Template_Var_Data (AT_Id, Var_Id, ATSRD_Id)
 	  	  	  	  	  	  	     Select @AT_Id, v.Var_Id, @This_ATSRD_Id From Variables v
                    Join Variables v2 on v2.Var_Id = v.Var_Id
 	  	                 Join Alarm_Template_Var_Data atv on atv.Var_Id = v2.PVar_Id and atv.AT_Id = @AT_Id
 	  	                 Where v.SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id and atv.ATSRD_Id is NULL
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
      End
    else
      Begin
 	  	  	  	 If @SPC_Group_Variable_Type_Id is NULL
 	  	  	  	   Begin
 	  	         Update Alarm_Template_SPC_Rule_Data set Firing_Priority = @Firing_Priority, AP_Id = @AP_Id
 	  	         Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null
 	  	         Update Alarm_Template_SPC_Rule_Property_Data set Value = @nValue, mValue = @mValue
 	  	         Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id) 
 	  	         and Alarm_SPC_Rule_Property_Id = @Alarm_SPC_Rule_Property_Id
          End
        Else
 	  	  	  	   Begin
 	  	         Update Alarm_Template_SPC_Rule_Data set Firing_Priority = @Firing_Priority, AP_Id = @AP_Id
 	  	         Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id
 	  	         Update Alarm_Template_SPC_Rule_Property_Data set Value = @nValue, mValue = @mValue
 	  	         Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id) 
 	  	         and Alarm_SPC_Rule_Property_Id = @Alarm_SPC_Rule_Property_Id
          End
      End
  End
else if @Operation = 2
  Begin
/*
    'ATSRD_Id not being populated yet...
    Delete from Alarm_History
    Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id)
*/
/*
    Delete from Alarm_History
    Where Alarm_Id in (select Alarm_Id from Alarms Where ATSRD_Id in (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id))
*/
    If @SPC_Group_Variable_Type_Id is Null
      Begin
 	  	     Delete from Alarms
 	  	     Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null)
 	  	     Delete from Alarm_Template_SPC_Rule_Property_Data
 	  	     Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null)
 	  	     and Alarm_SPC_Rule_Property_Id = @Alarm_SPC_Rule_Property_Id
        Delete from Alarm_Template_Var_Data where AT_Id = @AT_Id and ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null)
 	       Delete from Alarm_Template_SPC_Rule_Data where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id is Null
      End
    Else
 	  	   Begin
 	  	     Delete from Alarms
 	  	     Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id)
 	  	     Delete from Alarm_Template_SPC_Rule_Property_Data
 	  	     Where ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id)
 	  	     and Alarm_SPC_Rule_Property_Id = @Alarm_SPC_Rule_Property_Id
        Delete from Alarm_Template_Var_Data where AT_Id = @AT_Id and ATSRD_Id = (select ATSRD_Id from Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id)
 	       Delete from Alarm_Template_SPC_Rule_Data where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id
      End
  End
else
  Begin
    If @Operation = 3 --Move Up
      Select @Adjacent_Firing_Priority = max(Firing_Priority) From Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Firing_Priority < @This_Firing_Priority
    else              --Move Down
      Select @Adjacent_Firing_Priority = min(Firing_Priority) From Alarm_Template_SPC_Rule_Data Where AT_Id = @AT_Id and Firing_Priority > @This_Firing_Priority
    -- Update The Implied Sequence
    if @Adjacent_Firing_Priority is Not Null
      Begin
        Update Alarm_Template_SPC_Rule_Data
          Set Firing_Priority = @This_Firing_Priority 
          Where Firing_Priority = @Adjacent_Firing_Priority
          and AT_Id = @AT_Id
        If @SPC_Group_Variable_Type_Id is Null
          Begin
 	  	         Update Alarm_Template_SPC_Rule_Data
 	  	           Set Firing_Priority = @Adjacent_Firing_Priority
 	  	           Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id 
 	  	           and SPC_Group_Variable_Type_Id is Null
          End
        Else
          Begin
 	  	         Update Alarm_Template_SPC_Rule_Data
 	  	           Set Firing_Priority = @Adjacent_Firing_Priority
 	  	           Where AT_Id = @AT_Id and Alarm_SPC_Rule_Id = @Alarm_SPC_Rule_Id 
 	  	           and SPC_Group_Variable_Type_Id = @SPC_Group_Variable_Type_Id
          End
      End
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

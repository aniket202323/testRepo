CREATE   Procedure dbo.spSupport_FixEdModels3 
@Password VarChar(10)
As
Set NoCount On
If @Password <> 'EdModel' 
 Begin 
  Print 'Failed - Password Incorrect'
  Return
 End
Declare @EC_Id   Int,
 	 @PEI_Id  Int,
 	 @Event_Subtype_Id   Int,
 	 @Comment_Id   Int,
 	 @PU_Id   Int,
 	 @ED_Model_Id   Int,
 	 @ET_Id   Int,
 	 @Is_Active   Int,
 	 @EC_Desc   VarChar(50),
 	 @Extended_Info   VarChar(255),
 	 @Exclusions   VarChar(255),
 	 @Model_Num   Int,
 	 @New_Id  	 Int
Declare @ECD_ECV_Id 	  	 Int,
 	 @ECD_ED_Field_Id 	 Int,
 	 @ECD_Sampling_Offset  	 Int,
 	 @ECD_PEI_Id 	  	 Int,
 	 @ECD_PU_Id 	  	 Int,
 	 @ECD_ED_Attribute_Id  	 Int,
 	 @ECD_EC_Id 	  	 Int,
 	 @ECD_ST_Id 	  	 Int,
 	 @ECD_IsTrigger 	   	 Int,
 	 @ECD_Input_Precision  	 Int,
 	 @ECD_Alias 	  	 Varchar(7000),
 	 @ECD_Field_Order 	 Int
Declare @Value Varchar(7000),
 	 @NewECV 	 Int,
 	 @FO 	 Int
Declare EC Cursor For 
  Select EC_Id,PEI_Id,Event_Subtype_Id,Comment_Id,PU_Id,ED_Model_Id,ET_Id,Is_Active,EC_Desc,Extended_Info,Exclusions,Model_Num
   From Old_Event_Configuration
Open EC
ECLoop:
 Fetch Next From EC INto @EC_Id,@PEI_Id,@Event_Subtype_Id,@Comment_Id,@PU_Id,@ED_Model_Id,@ET_Id,
 	 @Is_Active,@EC_Desc,@Extended_Info,@Exclusions,@Model_Num
 If @@Fetch_Status = 0
   Begin
 	 Select @ED_Model_Id = Null 
 	 Select @ED_Model_Id = ED_Model_Id From Ed_Models Where Model_Num = @Model_Num
 	 If  (@ED_Model_Id Is Null) Or  (@ED_Model_Id < 50000)
 	   Begin
 	     Insert Into Event_Configuration (PEI_Id,Event_Subtype_Id,Comment_Id,PU_Id,
 	  	  	 ED_Model_Id,ET_Id,Is_Active,EC_Desc,Extended_Info,Exclusions)
 	     Values (@PEI_Id,@Event_Subtype_Id,@Comment_Id,@PU_Id,@ED_Model_Id,@ET_Id,
 	  	      @Is_Active,@EC_Desc,@Extended_Info,@Exclusions)
 	     Select @New_Id =  Scope_Identity()
 	     Select @FO = 0
 	     Declare ECD Cursor For 
   	     Select ECV_Id,ED_Field_Id,Sampling_Offset,PEI_Id,PU_Id,ED_Attribute_Id,
 	  	 EC_Id,ST_Id,IsTrigger,Input_Precision,Alias,Field_Order
    	     From Old_Event_Configuration_Data
 	     Where EC_Id = @EC_Id
 	     Order By Field_Order
 	     Open ECD
ECDLoop:
  	     Fetch Next From ECD INto @ECD_ECV_Id,@ECD_ED_Field_Id,@ECD_Sampling_Offset,
 	  	 @ECD_PEI_Id,@ECD_PU_Id,@ECD_ED_Attribute_Id,@ECD_EC_Id,@ECD_ST_Id,
 	  	 @ECD_IsTrigger,@ECD_Input_Precision,@ECD_Alias,@ECD_Field_Order
 	     If @@Fetch_Status = 0
 	        Begin
 	         Select @FO = @FO + 1
 	         Select @Value = Value From Old_Event_Configuration_Values
 	  	     Where ECV_Id = @ECD_ECV_Id
 	         Insert Into Event_Configuration_Values (Value) Values (@Value)
 	   	    select @NewECV = IDENT_CURRENT('event_configuration_values')
 	         Insert Into Event_Configuration_Data (ECV_Id,ED_Field_Id,Sampling_Offset,
 	  	     PEI_Id,PU_Id,ED_Attribute_Id,EC_Id,ST_Id,IsTrigger,Input_Precision,Alias)
 	  	 Select @NewECV,ED_Field_Id,@ECD_Sampling_Offset,@ECD_PEI_Id,@ECD_PU_Id,
 	  	  	 @ECD_ED_Attribute_Id,@New_Id,@ECD_ST_Id,@ECD_IsTrigger,@ECD_Input_Precision,
 	  	  	 @ECD_Alias
 	  	 From Ed_Fields
 	  	  Where Ed_Model_Id = @ED_Model_Id and Field_Order = @FO
 	         Goto ECDLoop
 	       End
 	     Close ECD
 	     Deallocate ECD
 	   End --(If (@ED_Model_Id Is Null) Or  (@ED_Model_Id < 50000))
        Goto ECLoop
   End
Close EC
Deallocate EC
Update CXS_Service Set Reload_Flag = 2,Time_Stamp = Getdate() Where Proficy_Service_Name = 'PREventMgr'
Print 'Updates Complete'
Set NoCount OFF

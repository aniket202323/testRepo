CREATE PROCEDURE dbo.spEM_IEImportDisplays
 	 @Sheet_Group_Desc  	 nVarChar(100),
 	 @Sheet_Desc  	  	 nVarChar(100),
 	 @Sheet_Type_Desc  	 nVarChar(100),
 	 @PU_Desc  	  	  	 nVarChar(100),
 	 @Event_Prompt  	  	 nVarChar(100),
 	 @sInterval  	  	 nVarChar(10),
 	 @sOffset  	  	  	 nVarChar(10),
 	 @sInitialCount 	  	 nVarChar(10),
 	 @sMaximumCount  	 nVarChar(10),
 	 @sMaxEditHours  	 nVarChar(10),
 	 @sRowHeaders  	  	 nVarChar(10),
 	 @sColumnHeaders  	 nVarChar(10),
 	 @sRowNumbering  	 nVarChar(10),
 	 @sColumnNumbering  	 nVarChar(10),
 	 @sDisplaySpecWin  	 nVarChar(10),
 	 @sDisplaySpecColumn nVarChar(10),
 	 @sDisplayCommentWin nVarChar(10),
 	 @sDisplayEvent  	 nVarChar(10),
 	 @sDisplayDate  	  	 nVarChar(10),
 	 @sDisplayTime  	  	 nVarChar(10),
 	 @sDisplayGrade  	 nVarChar(10),
 	 @sDisplayVarOrder  	 nVarChar(10),
 	 @sDisplayDataType  	 nVarChar(10),
 	 @sDisplayDataSource nVarChar(10),
 	 @sDisplaySpec  	  	 nVarChar(10),
 	 @sDisplayProdLine  	 nVarChar(10),
 	 @sDisplayProdUnit  	 nVarChar(10),
 	 @sSecurityGroup  	 nVarChar(100),
 	 @sDisplayDesc  	  	 nVarChar(10),
 	 @sDisplayEngUnit 	 nVarChar(10),
 	 @sDynamicRows 	  	 nVarChar(10),
 	 @sWrapProduct 	  	 nVarChar(10),
 	 @sAuto_Label_Status nVarChar(100),
 	 @sMaxInvDays 	  	 nVarChar(10),
 	 @sProd_Line 	  	 nVarChar(100),
 	 @sInputDesc 	  	 nVarChar(100),
 	 @sEventSubType 	  	 nVarChar(100),
 	 @User_Id  	  	  	 int
As
Declare 	 @PU_Id  	  	  	  	 int, 
 	  	 @Master_Unit  	  	 int,
 	  	 @Sheet_Type 	  	  	 int,
 	  	 @Event_Type 	  	  	 int,
 	  	 @Sheet_Group_Id 	  	 int,
 	  	 @Interval  	  	  	 int,
 	  	 @Offset  	  	  	 int,
 	  	 @Initial_Count  	  	 int,
 	  	 @Maximum_Count  	  	 int,
 	  	 @Max_Edit_Hours  	 int,
 	  	 @Row_Headers  	  	 int,
 	  	 @Column_Headers  	 int,
 	  	 @Row_Numbering  	  	 int,
 	  	 @Column_Numbering  	 int,
 	  	 @Display_Spec_Win  	 int,
 	  	 @Display_Spec_Column int,
 	  	 @Display_Comment_Win int,
 	  	 @Display_Event 	  	 int,
 	  	 @Display_Date 	  	 int,
 	  	 @Display_Time 	  	 int,
 	  	 @Display_Grade 	  	 int,
 	  	 @Display_Var_Order  	 int,
 	  	 @Display_Data_Type  	 int,
 	  	 @Display_Data_Source 	 int,
 	  	 @Display_Spec  	  	 int,
 	  	 @Display_Prod_Line  	 int,
 	  	 @Display_Prod_Unit  	 int,
 	  	 @DisplayDesc 	  	 Int,
 	  	 @DisplayEngU 	  	 Int,
 	  	 @DynamicRows 	  	 Int,
 	  	 @WrapProduct 	  	 Int,
 	  	 @Auto_Label_Status 	 Int,
 	  	 @MaxInvDays 	  	  	 Int,
 	  	 @Prod_Line 	  	  	 Int,
 	  	 @PEI_Id 	  	  	  	 Int,
 	  	 @Sheet_Id  	  	  	 Int,
 	  	 @Security_Group_Id 	 Int,
 	  	 @IsDefault 	  	  	 Int,
 	  	 @EventSubTypeId 	  	 Int,
 	  	 @Warn 	  	  	  	 nvarchar(255)
/* Initialization */
Select 	 @Sheet_Id = Null,
 	  	 @Event_Type = 0,
 	  	 @Sheet_Group_Id = Null,
 	  	 @Warn 	 = Null,
 	  	 @IsDefault = 0 -- Not imported
Select @Event_Prompt  	  	 = LTrim(RTrim(@Event_Prompt))
Select @Sheet_Group_Desc  	 = LTrim(RTrim(@Sheet_Group_Desc))
Select @Sheet_Desc  	  	  	 = LTrim(RTrim(@Sheet_Desc))
Select @Sheet_Type_Desc  	 = LTrim(RTrim(@Sheet_Type_Desc))
Select @sInterval  	  	  	 = LTrim(RTrim(@sInterval))
Select @sOffset  	  	  	 = LTrim(RTrim(@sOffset))
Select @sInitialCount  	  	 = LTrim(RTrim(@sInitialCount))
Select @sMaximumCount  	  	 = LTrim(RTrim(@sMaximumCount))
Select @sMaxEditHours  	  	 = LTrim(RTrim(@sMaxEditHours))
Select @sRowHeaders  	  	 = LTrim(RTrim(@sRowHeaders))
Select @sColumnHeaders  	  	 = LTrim(RTrim(@sColumnHeaders))
Select @sRowNumbering  	  	 = LTrim(RTrim(@sRowNumbering))
Select @sColumnNumbering 	 = LTrim(RTrim(@sColumnNumbering))
Select @sDisplaySpecWin  	 = LTrim(RTrim(@sDisplaySpecWin))
Select @sDisplaySpecColumn  	 = LTrim(RTrim(@sDisplaySpecColumn))
Select @sDisplayCommentWin  	 = LTrim(RTrim(@sDisplayCommentWin))
Select @sDisplayEvent  	  	 = LTrim(RTrim(@sDisplayEvent))
Select @sDisplayDate  	  	 = LTrim(RTrim(@sDisplayDate))
Select @sDisplayTime  	  	 = LTrim(RTrim(@sDisplayTime))
Select @sDisplayGrade  	  	 = LTrim(RTrim(@sDisplayGrade))
Select @sDisplayVarOrder  	 = LTrim(RTrim(@sDisplayVarOrder))
Select @sDisplayDataType  	 = LTrim(RTrim(@sDisplayDataType))
Select @sDisplayDataSource  	 = LTrim(RTrim(@sDisplayDataSource))
Select @sDisplaySpec  	  	 = LTrim(RTrim(@sDisplaySpec))
Select @sDisplayProdLine  	 = LTrim(RTrim(@sDisplayProdLine))
Select @sDisplayProdUnit  	 = LTrim(RTrim(@sDisplayProdUnit))
Select @sDisplayDesc  	  	 = LTrim(RTrim(@sDisplayDesc))
Select @sDisplayEngUnit  	 = LTrim(RTrim(@sDisplayEngUnit))
Select @sDynamicRows  	  	 = LTrim(RTrim(@sDynamicRows))
Select @sWrapProduct  	  	 = LTrim(RTrim(@sWrapProduct))
Select @sAuto_Label_Status  	 = LTrim(RTrim(@sAuto_Label_Status))
Select @sMaxInvDays  	  	 = LTrim(RTrim(@sMaxInvDays))
Select @sProd_Line 	  	  	 = LTrim(RTrim(@sProd_Line))
Select @sInputDesc 	  	  	 = LTrim(RTrim(@sInputDesc))
Select @sSecurityGroup 	  	 = LTrim(RTrim(@sSecurityGroup))
Select @sEventSubType 	  	 = LTrim(RTrim(@sEventSubType))
If @sEventSubType = '' Select @sEventSubType = Null
If  @Event_Prompt = '' Select @Event_Prompt = Null
If @sInterval = '' or @sInterval IS NULL
  Select @Interval = 0
Else
  If Isnumeric(@sInterval) <> 0
   	 Select @Interval = Convert(Int,@sInterval)
  Else
 	 Begin
 	   Select 'Failed - Incorrect Interval'
       RETURN (-100)
 	 End
 	 
If @sOffset = '' or @sOffset IS NULL
     Select @Offset = 0
Else
  If Isnumeric(@sOffset) <> 0
   	 Select @Offset = Convert(Int,@sOffset)
  Else
 	 Begin
 	   Select 'Failed - Incorrect Offset'
       RETURN (-100)
 	 End
If @sInitialCount = '' or @sInitialCount IS NULL  
     Select @Initial_Count = 0
Else
  If Isnumeric(@sInitialCount) <> 0
   	 Select @Initial_Count = Convert(Int,@sInitialCount)
  Else
 	 Begin
 	   Select 'Failed - Incorrect Inital Count'
       RETURN (-100)
 	 End
If @sMaximumCount = '' or @sMaximumCount IS NULL  
     Select @Maximum_Count = 0
Else
  If Isnumeric(@sMaximumCount) <> 0
   	 Select @Maximum_Count = Convert(Int,@sMaximumCount)
  Else
 	 Begin
 	   Select 'Failed - Incorrect Maximum Count'
       RETURN (-100)
 	 End
If @sMaxEditHours = '' or @sMaxEditHours IS NULL  
     Select @Max_Edit_Hours = 0
Else
  If Isnumeric(@sMaxEditHours) <> 0
   	 Select @Max_Edit_Hours = Convert(Int,@sMaxEditHours)
  Else
 	 Begin
 	   Select 'Failed - Max Edit Hours'
       RETURN (-100)
 	 End
If @sRowHeaders = '1'       	  	 Select @Row_Headers = 1  	  	 Else Select @Row_Headers = 0
If @sColumnHeaders = '1'    	  	 Select @Column_Headers = 1  	  	 Else Select @Column_Headers = 0
If @sRowNumbering = '1'     	  	 Select @Row_Numbering = 1  	  	 Else Select @Row_Numbering = 0
If @sColumnNumbering = '1'  	  	 Select @Column_Numbering = 1 	 Else Select @Column_Numbering = 0
If @sDisplaySpecWin = '1'   	  	 Select @Display_Spec_Win = 1 	 Else Select @Display_Spec_Win = 0
If @sDisplaySpecColumn = '1'    Select @Display_Spec_Column = 1 	 Else Select @Display_Spec_Column = 0
If @sDisplayCommentWin = '1' 	 Select @Display_Comment_Win = 1 	 Else Select @Display_Comment_Win = 0  
If @sDisplayEvent = '1' 	  	  	 Select @Display_Event = 1 	  	 Else Select @Display_Event = 0  
If @sDisplayDate = '1' 	  	  	 Select @Display_Date = 1 	  	 Else Select @Display_Date = 0  
If @sDisplayTime = '1' 	  	  	 Select @Display_Time = 1 	  	 Else Select @Display_Time = 0  
If @sDisplayGrade = '1' 	  	  	 Select @Display_Grade = 1 	  	 Else Select @Display_Grade = 0  
If @sDisplayVarOrder = '1' 	  	 Select @Display_Var_Order = 1 	 Else Select @Display_Var_Order = 0  
If @sDisplayDataType = '1' 	  	 Select @Display_Data_Type = 1 	 Else Select @Display_Data_Type = 0  
If @sDisplayDataSource = '1' 	 Select @Display_Data_Source = 1 	 Else Select @Display_Data_Source = 0
If @sDisplaySpec = '1' 	  	  	 Select @Display_Spec = 1 	  	 Else Select @Display_Spec = 0  
If @sDisplayProdLine = '1' 	  	 Select @Display_Prod_Line = 1 	 Else Select @Display_Prod_Line = 0 
If @sDisplayProdUnit = '1' 	  	 Select @Display_Prod_Unit = 1 	 Else Select @Display_Prod_Unit = 0  
If @sDisplayDesc = '1' 	  	  	 Select @DisplayDesc = 1 	  	  	 Else Select @DisplayDesc = 0  
If @sDisplayEngUnit = '1' 	  	 Select @DisplayEngU = 1 	  	  	 Else Select @DisplayEngU = 0  
If @sDynamicRows = '1' 	  	  	 Select @DynamicRows = 1 	  	  	 Else Select @DynamicRows = 0  
If @sWrapProduct = '1' 	  	  	 Select @WrapProduct = 1 	  	  	 Else Select @WrapProduct = 0  
If @sMaxInvDays = '' or @sMaxInvDays IS NULL  
     Select @MaxInvDays = 0
Else
  If Isnumeric(@sMaxInvDays) <> 0
   	 Select @MaxInvDays = Convert(Int,@sMaxInvDays)
  Else
 	 Begin
 	   Select 'Failed - Max Inventory days'
       RETURN (-100)
 	 End
If @sAuto_Label_Status = ''
     Select @Auto_Label_Status = Null
Else
  Begin
 	 Select @Auto_Label_Status = ProdStatus_Id From Production_status Where ProdStatus_Desc = @sAuto_Label_Status
  End
/* Build Sheet Group */
Select @Sheet_Group_Id = Sheet_Group_Id
From Sheet_Groups
Where Sheet_Group_Desc = @Sheet_Group_Desc
If @Sheet_Group_Id Is Null
  Begin
     Execute spEM_CreateSheetGroup  @Sheet_Group_Desc,@User_Id,@Sheet_Group_Id OUTPUT
 	  If @Sheet_Group_Id is null
 	   Begin
 	  	 Select 'Failed - could not create Display Group.'
 	  	 return (-100)
 	   End
  End
/* Build Sheet */
Select @Sheet_Id = Sheet_Id 
  From Sheets 
  Where Sheet_Desc = @Sheet_Desc
Select @Sheet_Type = Sheet_Type_Id 
  From Sheet_Type
  Where Sheet_Type_Desc = @Sheet_Type_Desc and Is_Active = 1
If @Sheet_Type IS NULL 
     BEGIN
        Select 'Failed - Invalid Display Type'
        RETURN (-100)
     END
Select @Prod_Line = Null
If @Sheet_Type = 15   -- Line Down
  Begin
   Select @Prod_Line = PL_Id from Prod_Lines where PL_desc = @sProd_Line
   If @Prod_Line is null
 	 Begin
        Select 'Failed - Product Line not found'
        RETURN (-100)
 	 End
  End
If  @Sheet_Type IN (8,27) and @sProd_Line is not Null-- OverView/nonproductive time
  Begin
   Select @Prod_Line = PL_Id from Prod_Lines where PL_desc = @sProd_Line
   If @Prod_Line is null
 	 Begin
        Select 'Failed - Product Line [' + @sProd_Line + '] not found'
        RETURN (-100)
 	 End
  End
If @Sheet_Type = 2 Or  	 -- AutoLog Event-Based
   @Sheet_Type = 3 Or  	 -- genealogy log (Extended client)
   @Sheet_Type = 4 Or  	 -- Waste Entry
   @Sheet_Type = 5 Or  	 -- Downtime
   @Sheet_Type = 8 Or  	 -- overview
   @Sheet_Type = 10 Or 	 -- Genealogy
   @Sheet_Type = 11 Or 	 -- Alarm
   @Sheet_Type = 12 Or 	 -- Complaint
   @Sheet_Type = 13 Or 	 -- Report
   @Sheet_Type = 14 Or 	 -- SOE
   @Sheet_Type = 17 Or 	 -- ScheduleView
   @Sheet_Type = 18 Or 	 -- SPC TREND
   @Sheet_Type = 19 Or 	 -- AutoLog Genealogy (event Component)
   @Sheet_Type = 27  -- Non Productive Time
 Select @Event_Type = 1
/* 
 	 Or 	 -- SOE
   @Sheet_Type = 16 	 Or 	 -- Autolog Product-Time
   @Sheet_Type = 20 	 Or 	 -- Autolog Downtime
   @Sheet_Type = 21 	 Or 	 -- Autolog Process Order
   @Sheet_Type = 22 	 Or 	 -- Autolog Process Order/Time
   @Sheet_Type = 23 	 Or 	 -- Autolog Product Change
   @Sheet_Type = 24 	 Or 	 -- Autolog Uptime
   @Sheet_Type = 25 	 Or 	 -- Autolog User-Defined Event
   @Sheet_Type = 26 	  	 -- Autolog Waste
*/
If @Sheet_Type = 2 Or @Sheet_Type = 4 Or  @Sheet_Type = 5 Or  @Sheet_Type = 7 Or  @Sheet_Type = 10 or  @Sheet_Type = 16 or @Sheet_Type = 19 or 
   @Sheet_Type = 20  Or @Sheet_Type = 21 Or @Sheet_Type = 22 Or @Sheet_Type = 23 Or @Sheet_Type = 24 Or @Sheet_Type = 25 Or @Sheet_Type = 26
BEGIN
 	 Select @Prod_Line = PL_Id from Prod_Lines where PL_desc = @sProd_Line
 	 If @Prod_Line is null
 	 BEGIN
 	  	 If (Select Count(*) From Prod_Units Where PU_Desc = @PU_Desc) = 1
 	  	  	 Select @Master_Unit = PU_Id From Prod_Units Where PU_Desc = @PU_Desc
 	  	 If @Master_Unit Is null
 	  	 BEGIN
 	         Select 'Failed - master unit [' + convert(nVarChar(10),@Master_Unit) + '] not found - No Line specified'
 	         RETURN (-100)
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @Master_Unit = PU_Id
 	  	  	 From Prod_Units pu 
 	  	  	 Where PU_Desc = @PU_Desc and PL_Id = @Prod_Line
 	  	 If @Master_Unit Is null
 	  	 BEGIN
 	         Select 'Failed - master unit [' + convert(nVarChar(10),@Master_Unit) + '] not found'
 	         RETURN (-100)
 	  	 END
 	 END
 	 SElECT @Prod_Line = Null
END
If @Sheet_Type = 19 and  @Master_Unit is not Null  -- Event Component
  Begin
   Select @PEI_Id = Null
   Select @PEI_Id = PEI_Id from Prdexec_Inputs where Input_Name = @sInputDesc and PU_Id = @Master_Unit
   If @PEI_Id is null
 	 Begin
        Select 'Failed - Input [' + @sInputDesc + '] not found'
        RETURN (-100)
 	 End
  End
else
 	 Select @PEI_Id = Null
If @Sheet_Type = 25
BEGIN
   If @sEventSubType Is Null
   BEGIN
 	 Select 'Failed - Event subtype found'
 	 RETURN (-100)
   END
   Select @EventSubTypeId = Null
   Select @EventSubTypeId = Event_Subtype_Id from Event_Subtypes where Event_Subtype_Desc = @sEventSubType
   If @EventSubTypeId is null
   BEGIN
        Select 'Failed - Event subtype  [' + @sEventSubType + '] not found'
        RETURN (-100)
   End
END
ELSE
 	 Select @EventSubTypeId = Null
If @Sheet_Id is null
  Begin
 	 Execute spEM_CreateSheet  @Sheet_Desc,@Sheet_Type,@Event_Type,@Sheet_Group_Id,@User_Id,@Sheet_Id OUTPUT
 	 If @Sheet_Id is null
 	   Begin
 	  	 Select 'Failed - could not create Display.'
 	  	 return (-100)
 	   End
  End
Else
  Begin
 	 Select 'Failed - Sheet already exists.'
 	 return (-100)
   End
Execute spEM_PutSheetData  @Sheet_Id,@Master_Unit,@Event_Prompt,@Interval,@Offset,@Initial_Count,@Maximum_Count,@Row_Headers,@Column_Headers,
    @Row_Numbering,@Column_Numbering,@Display_Event,@Display_Date,@Display_Time,@Display_Grade,@Display_Var_Order,@Display_Data_Type,@Display_Data_Source,
    @Display_Spec,@Display_Prod_Line,@Display_Prod_Unit,@DisplayDesc,@DisplayEngU,
 	 @Display_Spec_Win,@DynamicRows,@Max_Edit_Hours,@WrapProduct,@Display_Comment_Win,@Auto_Label_Status,@Display_Spec_Column,
 	 @MaxInvDays,@Prod_Line,@PEI_Id,@IsDefault,@EventSubTypeId,@User_Id
If @sSecurityGroup <> '' and @sSecurityGroup is not null
 Begin 
 	 Select @Security_Group_Id = Group_Id From Security_Groups where Group_Desc = @sSecurityGroup
 	 If @Security_Group_Id is null
 	   Begin 
 	  	 Select @Warn = 'Warning - security group not found'
 	   End
 	 Else
 	  Execute spEM_PutSecuritySheet @Sheet_Id,@Security_Group_Id,@User_Id
 End
If @Warn is null
  Execute spEM_ActivateSheet  @Sheet_Id,1,@User_Id
Else
  Begin
   	 Execute spEM_ActivateSheet  @Sheet_Id,0,@User_Id
 	 Select @Warn
  End
RETURN(0)

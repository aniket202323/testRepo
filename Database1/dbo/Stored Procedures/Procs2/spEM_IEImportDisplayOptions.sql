CREATE PROCEDURE dbo.spEM_IEImportDisplayOptions
@Sheet_Desc 	  	 nVarChar(100),
@Display_Option 	 nVarChar(100),
@Value 	  	  	 nvarchar(4000),
@User_Id 	  	 int
/*
Change History
2018-08-07 	 Vincent Rouleau 	  	 Add case for handling Unit Id data type (Field Type Id 9)
*/
As
Declare @Sheet_Id  	  	 Int,
 	  	 @DisplayOptId 	 Int,
 	  	 @FieldId 	  	 Int,
 	  	 @SheetType 	  	 Int,
 	  	 @STDO_Id 	  	 Int,
 	  	 @SaveValue 	  	 nvarchar(4000),
 	  	 @PL_Id 	  	  	 Int,
 	  	 @PU_Id 	  	  	 Int,
 	  	 @Desc 	  	  	 nvarchar(50),
 	  	 @Count 	  	  	 Int
/* Initialization */
Select 	 @Sheet_Id = Null,
 	  	 @DisplayOptId 	 = Null,
 	  	 @FieldId 	  	 = Null,
 	  	 @STDO_Id 	  	 = Null
Select @Sheet_Desc 	  	 = LTrim(RTrim(@Sheet_Desc))
Select @Display_Option 	 = LTrim(RTrim(@Display_Option))
Select @Value 	  	  	 = LTrim(RTrim(@Value))
If  @Sheet_Desc = '' or @Sheet_Desc IS NULL 
    BEGIN
      Select 'Failed - missing display description'
      Return(-100)
    END
/* Get Sheet_Id */
Select @Sheet_Id = Sheet_Id,@SheetType = Sheet_Type
From Sheets
Where Sheet_Desc = @Sheet_Desc
If @Sheet_Id Is Null
    BEGIN
      Select 'Failed - Unable to find display'
      Return(-100)
    END
/* Check Display_Option */
Select @DisplayOptId = Display_Option_Id,@FieldId = Field_Type_Id
 From Display_Options
Where Display_Option_Desc = @Display_Option  AND display_option_category_id NOT in (23,24)  -- 23 and 24 are the webUI
If @DisplayOptId is Null
    BEGIN
      Select 'Failed - Unable to find display Option'
      Return(-100)
    END
Select @STDO_Id = STDO_Id
 From Sheet_Type_Display_Options 
 Where Display_Option_Id = @DisplayOptId and Sheet_Type_Id = @SheetType
If @STDO_Id is Null
    BEGIN
      Select 'Failed - invalid display Option for given display'
      Return(-100)
    END
If @Value <> '' and @Value is not null
  Begin
 	 If @FieldId = 27
 	 BEGIN
 	    	 Create Table #Temp ([Id] Int,[Desc] nVarChar(4000))
 	  	 DECLARE @PUET Table
 	  	  ( EventSubTypeId int,
 	  	   EventSubTypeDesc nvarchar(4000) Null )
 	  	 Insert Into @PUET  (EventSubTypeId,EventSubTypeDesc)
 	  	  	 Select Distinct ES.Event_SubType_Id, ES.Event_SubType_Desc
 	  	  	 From Event_Types ET
 	  	  	 Join Event_Configuration ec on ec.et_Id = et.Et_Id
 	  	  	 Join Event_SubTypes ES On es. Event_Subtype_Id = ec.Event_Subtype_Id
 	  	  	 Where ET.IncludeOnSoe = 1 And ET.SubTypes_Apply = 1
 	  	 Insert Into @PUET  (EventSubTypeId,EventSubTypeDesc)
 	  	  	 Select  Distinct (-1* ET.ET_Id), ET.ET_Desc 
 	  	  	 From Event_Types ET
 	  	  	 Where ET.IncludeOnSoe = 1    And ET.SubTypes_Apply = 0   And et.ET_Id Not In (11,2,3)
 	  	 Insert Into @PUET  (EventSubTypeId,EventSubTypeDesc)
 	  	  	 Select Distinct (-1* ET.ET_Id) , ET.ET_Desc 
 	  	  	 From Prod_Events PE
 	  	  	 Join Event_Types ET On PE.Event_Type = et.ET_Id  
 	  	  	 Where ET.IncludeOnSoe = 1    And ET.SubTypes_Apply = 0  And et.ET_Id in (2,3) 
 	  	  If (Select IncludeOnSoe From Event_Types Where ET_Id = 11) = 1
 	  	   Begin
 	  	  	 Declare @AlarmEventDescription nVarChar(100)
 	  	  	 Select @AlarmEventDescription = Et_Desc From Event_Types Where ET_ID = 11
 	  	  	 Insert Into @PUET  (EventSubTypeId,EventSubTypeDesc)
 	  	  	  	 Select  Distinct -10000, @AlarmEventDescription + ' Low'
 	  	  	 Insert Into @PUET  (EventSubTypeId,EventSubTypeDesc)
 	  	  	  	 Select Distinct -10001, @AlarmEventDescription + ' Medium'
 	  	  	 Insert Into @PUET  (EventSubTypeId,EventSubTypeDesc)
 	  	  	  	 Select  Distinct -10002, @AlarmEventDescription + ' High'
 	  	   End 
 	  	   Insert INto  #Temp  ([Id] ,[Desc])
 	  	  	  	 Select DISTINCT
 	  	  	  	   EventSubTypeId ,  EventSubTypeDesc
 	  	  	  	  from @PUET
 	  	  	 select @SaveValue =  Convert(nVarChar(10),Id) From #Temp Where [Desc] = @Value
 	  	   Drop Table #Temp
 	    End
 	 Else If @FieldId = 31 
 	   Begin
 	  	 Create Table #Conf (ID int, Conf_Desc nvarchar(20))
 	     Insert Into #Conf(ID,Conf_Desc) Values(6,'Cross')
 	     Insert Into #Conf(ID,Conf_Desc) Values(7,'Diagonal Cross')
 	     Insert Into #Conf(ID,Conf_Desc) Values(5,'Downward Diagonal')
 	     Insert Into #Conf(ID,Conf_Desc) Values(2,'Horizontal')
 	     Insert Into #Conf(ID,Conf_Desc) Values(1,'Transparent')
 	     Insert Into #Conf(ID,Conf_Desc) Values(4,'Upward Diagonal')
 	     Insert Into #Conf(ID,Conf_Desc) Values(3,'Vertical')
 	  	 select @SaveValue =  Convert(nVarChar(10),Id) From #Conf Where Conf_Desc = @Value
 	  	 Drop Table #Conf
      End
 	 Else If @FieldId = 10 
 	   Begin
 	  	 Declare @Start 	 Int,
 	  	  	  	 @End 	 Int
 	  	 
 	  	 Select @Desc = Null
 	  	 Select @End = charindex('|',@Value)
 	  	 If @End = 0
 	       BEGIN
 	         Select 'Failed - invalid display Option value'
 	         Return(-100)
 	       END
 	  	 Select @Desc = substring(@Value,1,@End - 1)
 	  	 Select @Value = substring(@Value,@End + 1,4000)
 	  	 Select @PL_Id = PL_Id From Prod_Lines where PL_Desc = @Desc
 	  	 If @PL_Id is Null
      	   BEGIN
 	         Select 'Failed - invalid display Option value (Production Line)'
 	         Return(-100)
 	       END
 	  	 Select @Desc = Null,@End = null
 	  	 Select @End = charindex('|',@Value)
 	  	 Select @Desc = substring(@Value,1,@End - 1)
 	  	 Select @Value = substring(@Value,@End + 1,4000)
 	  	 If @End = 0
 	       BEGIN
 	         Select 'Failed - invalid display Option value'
 	         Return(-100)
 	       END
 	  	 Select @PU_Id = PU_Id From Prod_Units where PU_Desc = @Desc and PL_Id = @PL_Id
 	  	 If @PU_Id is Null
      	   BEGIN
 	         Select 'Failed - invalid display Option value (Production Unit)'
 	         Return(-100)
 	       END
 	  	 Select @SaveValue = Convert(nVarChar(10),Var_Id)
 	  	  	  From Variables where Var_Desc = @Value and PU_Id = @PU_Id
 	  	 If @SaveValue is Null or @SaveValue = ''
      	   BEGIN
 	         Select 'Failed - invalid display Option value (Variable)'
 	         Return(-100)
 	       END
 	  End
 	 Else If @FieldId in (80, 9)
 	  Begin 
 	  	 SET @Count = (Select COUNT(PU_Id) From Prod_Units_Base Where PU_Desc = @Value)
 	  	 IF @Count = 0
 	  	 BEGIN
 	  	  	 IF ISNUMERIC(@Value) = 1 
 	  	  	 BEGIN
 	  	  	  	 IF EXISTS (SELECT PU_Id FROM dbo.Prod_Units_Base WHERE PU_Id = CONVERT(int, @Value))
 	  	  	  	 BEGIN
 	  	  	  	  	 SET @SaveValue = @Value
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 'Failed - Unit Id not found'
 	  	  	  	  	 RETURN(-100)
 	  	  	  	 END
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 SELECT 'Failed - Unit Name not found'
 	  	  	  	 RETURN(-100)
 	  	  	 END
 	  	 END
 	  	 ELSE IF @Count > 1
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Multiple Units share this name, use the Unit Id'
 	  	  	 RETURN(-100)
 	  	 END
 	  	 ELSE
 	  	  	 SET @SaveValue = (Select Convert(nVarChar(10),PU_Id) From Prod_Units_Base Where PU_Desc = @Value)
 	  End
 	 Else
 	 Select @SaveValue = Case 
 	  	  	 When  @FieldId = 6 and @Value = '1'  Then 'TRUE'
 	  	  	 When  @FieldId = 6 and @Value = '0' Then 'FALSE'
 	       When  @FieldId = 16 Then (Select Convert(nVarChar(10),ProdStatus_Id) From Production_Status Where ProdStatus_Desc = @Value)
 	       When  @FieldId = 24 Then (Select Convert(nVarChar(10),CS_Id) From Color_Scheme Where CS_Desc = @Value)
 	       When  @FieldId = 29 Then (Select Convert(nVarChar(10),Tree_Statistic_Id) From Tree_Statistics Where Tree_Statistic_Desc = @Value)
 	       When  @FieldId = 30 Then (Select Convert(nVarChar(10),Al_Id) From Access_Level Where AL_Desc = @Value)
  	       When  @FieldId = 34 Then (Select Convert(nVarChar(10),Color_Id) From Colors Where Color_Desc = @Value)
  	       When  @FieldId = 39 Then (Select Convert(nVarChar(10),Tree_Name_Id) From Event_Reason_Tree Where Tree_Name = @Value)
 	       When  @FieldId = 40 Then (Select Convert(nVarChar(10),Event_Reason_Id) From Event_Reasons Where Event_Reason_Name = @Value)
 	       Else  @Value
 	  	 End
 	 If @SaveValue is null or @SaveValue = ''
 	     BEGIN
 	       Select 'Failed - invalid display Option value'
 	       Return(-100)
 	     END
  End
  Execute spEM_PutSheetDisplayOptions 	 @Sheet_Id,@DisplayOptId,@SaveValue,@User_Id
Return(0)

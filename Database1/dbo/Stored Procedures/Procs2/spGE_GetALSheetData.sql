/* NOT CALLED ANYMORE */
Create Procedure dbo.spGE_GetALSheetData 
@EventId 	 int,
@SheetId 	 Int,
@DecimalSep     nvarchar(2) = '.'
 AS
SET NOCOUNT ON
Select @DecimalSep = COALESCE(@DecimalSep, '.')
Declare @TimeStamp 	   	 Datetime,
 	 @StartTime 	  	 DateTime,
 	 @MasterPU 	  	 Int,
 	 @GenealogySheetId 	 Int,
 	 @Prod_Id 	  	 Int,
 	 @ParentEvent 	  	 Int,
 	 @SheetPU 	  	 Int,
 	 @SheetDesc 	  	 nvarchar(50),
 	 @EventNum 	  	 nvarchar(25),
 	 @ProdCode 	  	 nvarchar(25),
 	 @StatusDesc 	  	 nvarchar(25),
 	 @EventDesc 	  	 nvarchar(100),
 	 @DimXDesc 	  	 nvarchar(100),
 	 @DimYDesc 	  	 nvarchar(100),
 	 @DimZDesc 	  	 nvarchar(100),
 	 @DimADesc 	  	 nvarchar(100),
 	 @DimX 	  	  	 nvarchar(100),
 	 @DimY 	  	  	 nvarchar(100),
 	 @DimZ 	  	  	 nvarchar(100),
 	 @DimA 	  	  	 nvarchar(100),
 	 @ProcessOrder 	  	 nvarchar(100),
 	 @CustomerOrder 	  	 nvarchar(100),
 	 @AEnabled 	  	 Int,
 	 @YEnabled 	  	 Int,
 	 @ZEnabled 	  	 Int,
 	 @CsId 	  	  	 Int,
 	 @Exclusive 	  	 bit,
 	 @UseStartTime 	 Int
select @Exclusive = coalesce(convert(int,Value),1) From site_parameters where parm_Id = 13
Select @MasterPU = coalesce(p.master_Unit,p.pu_Id)
 	 From events e
 	 join prod_units p on p.pu_Id = e.PU_Id
 	 Where e.Event_Id = @EventId
Select @GenealogySheetId = sgd.Display_Sheet_Id,@SheetPU = s.Master_Unit,
  @EventDesc = Coalesce(Event_Prompt,'Number'),
  @SheetDesc = s.Sheet_Desc
  From Sheet_Genealogy_Data sgd
  Join Sheets s on s.sheet_Id = sgd.Display_Sheet_Id
  Where sgd.Sheet_Id = @SheetId and sgd.PU_Id = @MasterPU
Select @CsId = convert(int,value)
  From Sheet_Display_Options where sheet_Id = @GenealogySheetId and Display_Option_Id = 31
select @CsId = coalesce(@CsId,1)
Select  	 @DimADesc = Coalesce(Dimension_A_Name,'<none>'),
 	 @DimXDesc = Coalesce(Dimension_X_Name,'<none>'),
 	 @DimYDesc = Coalesce(Dimension_Y_Name,'<none>'),
 	 @DimZDesc = Coalesce(Dimension_Z_Name,'<none>'),
 	 @AEnabled = Coalesce(Dimension_A_Enabled,0),
 	 @YEnabled = Coalesce(Dimension_Y_Enabled,0),
 	 @ZEnabled = Coalesce(Dimension_Z_Enabled,0)
 From Event_Configuration e
 Join Event_subtypes es On es.Event_Subtype_Id = e.Event_Subtype_Id
 Where e.PU_Id =  @MasterPU and e.Et_ID = 1
Select @SheetDesc = Coalesce(@SheetDesc,'<none>')
Select @EventDesc = Coalesce(@EventDesc,'Item')
Create Table #HeaderData (Caption nvarchar(100),Data nvarchar(100),ColumnNo Int)
/* Find Correct event (for Timestamp) (look thru genealogy links)*/
 If @SheetPU <> @MasterPU
  Begin
    Create Table #Events (Event_Id Int,PU_Id Int) 	 
    Create Table #Event1 (Event_Id Int) 	 
    Insert InTo #Event1 (Event_Id) Values (@EventId)
ELoop:
    Insert Into #Events (Event_Id,PU_Id)
      Select ec.Source_Event_Id,coalesce(p.master_Unit,p.pu_Id)
      From Event_Components ec
      Join Events e on e.Event_Id = ec.Source_Event_Id
      Join prod_units p on p.pu_Id = e.PU_Id
      Where ec.Event_Id in (select Event_Id from #Event1)
    Select @ParentEvent = NUll
    Select @ParentEvent = Max(Event_Id) from #Events Where PU_Id = @SheetPU
    If (select Count(*) From #Events )  > 0 and @ParentEvent is Null
      Begin
       Delete From #Event1
       Insert Into #Event1 Select Event_Id From #Events
       Delete From #Events
       GoTo ELoop
      End
  End
Else
 Begin
    Select @ParentEvent = @EventID
 End 
If @ParentEvent is null
   Begin
/* Header Description, Header column,value,value column */
--  Select [DisplayName] = @SheetDesc,
-- 	  [Event_Num] = '<none>',
-- 	  [TimeStamp] = '',
-- 	  [Grade] = '',
-- 	  [Status] = '' 
    Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Display Name',@SheetDesc,1)
    Insert Into #HeaderData (Caption,Data,ColumnNo) Values (@EventDesc,'<none>',1)
    Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Start Time',' ',1)
    Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('End Time',' ',1)
    Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Product',' ',1)
    Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Status',' ',1)
    Select * from #HeaderData
    Select [Title] = 'Title',0,0,3,0, 
 	  [Description] = 'Description',0,0,3,0,
 	  [Eng Units] = 'Eng Units',0,0,3,0,
 	  [LE] = 'LE',0,0,3,0,
 	  [LR] = 'LR',0,0,3,0,
 	  [LW] = 'LW',0,0,3,0,
 	  [LU] = 'LU',0,0,3,0,
 	  [TGT] = 'TGT',0,0,3,0,
 	  [UU] = 'UU',0,0,3,0,
 	  [UW] = 'UW',0,0,3,0,
 	  [UR] = 'UR',0,0,3,0,
 	  [UE] = 'UE',0,0,3,0,
 	  [Result] = 'Result', 0,0,3,0
 	 Where 0 = 1
     Return
    End
Select @DimX = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_X),'<none>'),
       @DimY = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_Y),'<none>'),
       @DimZ = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_Z),'<none>'),
       @DimA = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_A),'<none>'),
       @ProcessOrder = Coalesce(co.Plant_Order_Number,'<na>')
 	 From events e
 	 Left Join Event_Details ed On ed.Event_Id = e.Event_Id
        Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
        Left Join Customer_Orders co on col.Order_Id = co.Order_Id
 	 Where e.Event_Id = @ParentEvent
Select @TimeStamp = timestamp,@MasterPU = coalesce(pu.master_Unit,pu.pu_Id),@ProdCode = p.Prod_Code,@StartTime = Start_Time,
       @Prod_Id = Applied_Product,@EventNum = Event_Num,@StatusDesc = ProdStatus_Desc,@UseStartTime = coalesce(pu.Uses_Start_Time,0)
 	 From events e
 	 join prod_units pu on pu.pu_Id = e.PU_Id
 	 Join Production_Status ps on ps.ProdStatus_Id = e.Event_Status
 	 left Join Products p on p.Prod_Id = e.Applied_Product
 	 Where Event_Id = @ParentEvent
  If @UseStartTime = 0
 	   Select @StartTime = Max(timestamp) From Events where PU_Id = @MasterPU and timestamp < @TimeStamp
  If @Prod_Id is null
    Select @Prod_Id = ps.Prod_Id,@ProdCode = p.Prod_Code
 	 From Production_Starts ps
 	 Join Products p on ps.prod_Id = p.prod_Id
 	 Where PU_Id = @MasterPU and ((Start_Time <= @TimeStamp) and ((End_Time > @TimeStamp) or (End_Time Is NUll)))
Declare @TimeString nvarchar(25)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Display Name',@SheetDesc,1)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values (@EventDesc,@EventNum,1)
  Select @TimeString = ''
  If Datepart(month,@StartTime) < 10  Select @TimeString = '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(month,@StartTime))  + '-'
  If Datepart(Day,@StartTime) < 10  Select @TimeString = @TimeString + '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(Day,@StartTime)) + '-'
  Select @TimeString = @TimeString + convert(nVarChar(4),Datepart(year,@StartTime))  + ' '
  If Datepart(Hour,@StartTime) < 10  Select @TimeString = @TimeString + '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(Hour,@StartTime)) + ':'
  If Datepart(Minute,@StartTime) < 10  Select @TimeString = @TimeString + '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(Minute,@StartTime))
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Start Time',@TimeString,1)
  Select @TimeString = ''
  If Datepart(month,@TimeStamp) < 10  Select @TimeString = '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(month,@TimeStamp))  + '-'
  If Datepart(Day,@TimeStamp) < 10  Select @TimeString = @TimeString + '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(Day,@TimeStamp)) + '-'
  Select @TimeString = @TimeString + convert(nVarChar(4),Datepart(year,@TimeStamp))  + ' '
  If Datepart(Hour,@TimeStamp) < 10  Select @TimeString = @TimeString + '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(Hour,@TimeStamp)) + ':'
  If Datepart(Minute,@TimeStamp) < 10  Select @TimeString = @TimeString + '0'
  Select @TimeString = @TimeString + convert(nvarchar(2),Datepart(Minute,@TimeStamp))
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('End Time',@TimeString,1)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Product',@ProdCode,1)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Status',@StatusDesc,1)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values (@DimXDesc,@DimX,2)
If @YEnabled = 1
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values (@DimYDesc,@DimY,2)
If @ZEnabled = 1
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values (@DimZDesc,@DimZ,2)
If @AEnabled = 1
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values (@DimADesc,@DimA,2)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('Process Order',@ProcessOrder,2)
  Insert Into #HeaderData (Caption,Data,ColumnNo) Values ('','',2)
  Select * from #HeaderData
Create Table #Data 
  (Title nvarchar(50),
   Title_FG int, 
   Description nvarchar(50), 
   Desc_FG int, 
   Desc_BG int, 
   [Eng Units] nVarChar(15), 
   EngU_FG int, 
   EngU_BG int, 
   Result nvarchar(25),
   Result_FG int, 
   Result_DataType int, 
   Result_Precision int, 
   [LE] nvarchar(25),
   LEntry_FG int,
   LEntry_BG int,
   [LR] nvarchar(25),
   LReject_FG int,
   LReject_BG int,
   [LW] nvarchar(25),
   LWarning_FG int,
   LWarning_BG int,
   [LU] nvarchar(25),
   LUser_FG int,
   LUser_BG int,
   [TGT] nvarchar(25),
   Target_FG int,
   Target_BG int,
   [UU] nvarchar(25),
   UUser_FG int,
   UUser_BG int,
   [UW] nvarchar(25),
   UWarning_FG int,
   UWarning_BG int,
   [UR] nvarchar(25),
   UReject_FG int,
   UReject_BG int,
   [UE] nvarchar(25),
   UEntry_FG int,
   UEntry_BG int,
)
If @Exclusive = 1
  Insert Into #Data (Title,Title_FG,
   Description,Desc_FG,Desc_BG,
   [Eng Units],EngU_FG,EngU_BG,
   Result,
    Result_FG, 
    Result_DataType ,Result_Precision, 
   LE, LEntry_FG,LEntry_BG,
   LR, LReject_FG, LReject_BG,
   LW, LWarning_FG, LWarning_BG, 
   LU, LUser_FG,LUser_BG, 
   TGT, Target_FG, Target_BG, 
   UU, UUser_FG, UUser_BG, 
   UW, UWarning_FG, UWarning_BG, 
   UR, UReject_FG, UReject_BG, 
   UE, UEntry_FG, UEntry_BG) 
  Select [Title] = sv.Title,Header_FG,
         [Description] = v.Var_Desc,Header_FG,Row_Header_BG,
 	  [Eng Units] = v.Eng_units,Header_FG,Column_Header_BG,
 	  [Result] = t.Result,
 	  Case When v.data_Type_Id in (1,2,6,7) then
 	    Case When Convert(float,t.Result) < Convert(float,vs.L_Entry) Then Entry_FG
 	  	 When Convert(float,t.Result) < Convert(float,vs.L_Reject) Then Reject_FG
 	  	 When Convert(float,t.Result) < Convert(float,vs.L_Warning) Then Warning_FG
 	  	 When Convert(float,t.Result) < Convert(float,vs.L_User) Then User_FG
 	  	 When Convert(float,t.Result) > Convert(float,vs.U_Entry) Then Entry_FG
 	  	 When Convert(float,t.Result) > Convert(float,vs.U_Reject) Then Reject_FG
 	  	 When Convert(float,t.Result) > Convert(float,vs.U_Warning) Then Warning_FG
 	  	 When Convert(float,t.Result) > Convert(float,vs.U_User) Then User_FG
 	  	 When t.Result is null Then 0
 	  	 Else Target_FG
 	  	 End
 	   When  v.data_Type_Id < 50 or (v.data_Type_Id > 50 and isnumeric(Left(t.Result,1))= 0) then
 	     Case When t.Result = vs.L_Entry Then Entry_FG
 	  	 When t.Result = vs.L_Reject Then Reject_FG
 	  	 When t.Result = vs.L_Warning Then Warning_FG
 	  	 When t.Result = vs.L_User Then User_FG
 	  	 When t.Result = vs.U_Entry Then Entry_FG
 	  	 When t.Result = vs.U_Reject Then Reject_FG
 	  	 When t.Result = vs.U_Warning Then Warning_FG
 	  	 When t.Result = vs.U_User Then User_FG
 	  	 When t.Result = vs.Target Then Target_FG
 	  	 Else 0
 	  	 End
 	    Else 0
 	  End,v.Data_Type_Id,v.Var_Precision,
 	  [LE] = vs.L_Entry, Entry_FG, Column_Header_BG,
 	  [LR] = vs.L_Reject, Reject_FG, Column_Header_BG,
 	  [LW] = vs.L_Warning, Warning_FG, Column_Header_BG,
 	  [LU] = vs.L_User, User_FG, Column_Header_BG,
 	  [TGT] = vs.Target, Target_FG, Column_Header_BG,
 	  [UU] = vs.U_User, User_FG, Column_Header_BG,
 	  [UW] = vs.U_Warning, Warning_FG, Column_Header_BG,
 	  [UR] = vs.U_Reject, Reject_FG, Column_Header_BG,
 	  [UE] = vs.U_Entry, Entry_FG, Column_Header_BG
      FROM color_scheme,Sheets s
      Join Sheet_Variables sv on sv.Sheet_Id = s.Sheet_Id
      Left Join Variables v on v.var_Id = sv.var_Id 
      Left Join Var_Specs vs on vs.var_Id = sv.Var_Id and (vs.Effective_Date < @TimeStamp) and ((vs.Expiration_Date >= @TimeStamp) or (vs.Expiration_Date is Null)) and vs.Prod_Id = @Prod_Id 
      Left Join Tests t on t.var_Id = sv.Var_Id and Result_On = @TimeStamp
    where s.Sheet_Id  = @GenealogySheetId and CS_Id = @CsId
    Order BY sv.Var_Order
Else
  Insert Into #Data (Title,Title_FG,
   Description,Desc_FG,Desc_BG,
   [Eng Units],EngU_FG,EngU_BG,
   Result,
    Result_FG, 
    Result_DataType ,Result_Precision, 
   LE, LEntry_FG,LEntry_BG,
   LR, LReject_FG, LReject_BG,
   LW, LWarning_FG, LWarning_BG, 
   LU, LUser_FG,LUser_BG, 
   TGT, Target_FG, Target_BG, 
   UU, UUser_FG, UUser_BG, 
   UW, UWarning_FG, UWarning_BG, 
   UR, UReject_FG, UReject_BG, 
   UE, UEntry_FG, UEntry_BG) 
  Select [Title] = sv.Title,Header_FG,
         [Description] = v.Var_Desc,Header_FG,Row_Header_BG,
 	  [Eng Units] = v.Eng_units,Header_FG,Column_Header_BG,
 	  [Result] = t.Result,
 	  Case When v.data_Type_Id in (1,2,6,7) then
 	    Case When Convert(float,t.Result) <= Convert(float,vs.L_Entry) Then Entry_FG
 	  	 When Convert(float,t.Result) <= Convert(float,vs.L_Reject) Then Reject_FG
 	  	 When Convert(float,t.Result) <= Convert(float,vs.L_Warning) Then Warning_FG
 	  	 When Convert(float,t.Result) <= Convert(float,vs.L_User) Then User_FG
 	  	 When Convert(float,t.Result) >= Convert(float,vs.U_Entry) Then Entry_FG
 	  	 When Convert(float,t.Result) >= Convert(float,vs.U_Reject) Then Reject_FG
 	  	 When Convert(float,t.Result) >= Convert(float,vs.U_Warning) Then Warning_FG
 	  	 When Convert(float,t.Result) >= Convert(float,vs.U_User) Then User_FG
 	  	 When t.Result is null Then 0
 	  	 Else Target_FG
 	  	 End
 	   When v.data_Type_Id < 50  or (v.data_Type_Id > 50 and isnumeric(Left(t.Result,1))= 0) then
 	     Case When t.Result = vs.L_Entry Then Entry_FG
 	  	 When t.Result = vs.L_Reject Then Reject_FG
 	  	 When t.Result = vs.L_Warning Then Warning_FG
 	  	 When t.Result = vs.L_User Then User_FG
 	  	 When t.Result = vs.U_Entry Then Entry_FG
 	  	 When t.Result = vs.U_Reject Then Reject_FG
 	  	 When t.Result = vs.U_Warning Then Warning_FG
 	  	 When t.Result = vs.U_User Then User_FG
 	  	 When t.Result = vs.Target Then Target_FG
 	  	 Else 0
 	  	 End
 	    Else 0
 	  End,v.Data_Type_Id,v.Var_Precision,
 	  [LE] = vs.L_Entry, Entry_FG, Column_Header_BG,
 	  [LR] = vs.L_Reject, Reject_FG, Column_Header_BG,
 	  [LW] = vs.L_Warning, Warning_FG, Column_Header_BG,
 	  [LU] = vs.L_User, User_FG, Column_Header_BG,
 	  [TGT] = vs.Target, Target_FG, Column_Header_BG,
 	  [UU] = vs.U_User, User_FG, Column_Header_BG,
 	  [UW] = vs.U_Warning, Warning_FG, Column_Header_BG,
 	  [UR] = vs.U_Reject, Reject_FG, Column_Header_BG,
 	  [UE] = vs.U_Entry, Entry_FG, Column_Header_BG
      FROM color_scheme,Sheets s
      Join Sheet_Variables sv on sv.Sheet_Id = s.Sheet_Id
      Left Join Variables v on v.var_Id = sv.var_Id 
      Left Join Var_Specs vs on vs.var_Id = sv.Var_Id and (vs.Effective_Date < @TimeStamp) and ((vs.Expiration_Date >= @TimeStamp) or (vs.Expiration_Date is Null)) and vs.Prod_Id = @Prod_Id 
      Left Join Tests t on t.var_Id = sv.Var_Id and Result_On = @TimeStamp
    where s.Sheet_Id  = @GenealogySheetId and CS_Id = @CsId
    Order BY sv.Var_Order
Declare @Result nvarchar(25),@LE nvarchar(25),@LR nvarchar(25),@LW nvarchar(25),@LU nvarchar(25),@TGT nvarchar(25),@UU nvarchar(25)
Declare @UW nvarchar(25),@UR nvarchar(25),@UE nvarchar(25)
Declare @Limit Int,@LimitValue nvarchar(25)
Declare @fResult float,@fValue Float
Declare Enum  Cursor For
  Select Result,LE,LR,LW,LU,TGT,UU,UW,UR,UE From #Data Where Result_DataType > 50 and isnumeric(Left(Result,1))= 1
 for update
Open enum 
EnumLoop:
Fetch Next from enum into @Result,@LE,@LR,@LW,@LU,@TGT,@UU,@UW,@UR,@UE
If @@Fetch_Status = 0
  Begin
 	 Execute spGE_StripNumeric @Result output
 	 Select @fResult = Convert(Float, @Result)
 	 Select @Limit = 1
 	 While @Limit < 9
 	   Begin
 	  	 Select @LimitValue = Case When @Limit = 1 Then @LE
 	  	  	  	  	  	  	  When @Limit = 2 Then @LR
 	  	  	  	  	  	  	  When @Limit = 3 Then @LW
 	  	  	  	  	  	  	  When @Limit = 4 Then @LU
 	  	  	  	  	  	  	  When @Limit = 5 Then @UU
 	  	  	  	  	  	  	  When @Limit = 6 Then @UW
 	  	  	  	  	  	  	  When @Limit = 7 Then @UR
 	  	  	  	  	  	  	  When @Limit = 8 Then @UE
 	  	  	  	  	  	  	 End
 	  	 If isnumeric(left(@LimitValue,1)) = 1
 	  	  	 Begin
 	  	  	   Execute spGE_StripNumeric @LimitValue output
 	  	  	   Select @fValue = Convert(Float, @LimitValue)
 	  	  	   If @Exclusive = 1
 	  	  	    Begin
 	  	  	  	  If (@Limit < 5 and  @fResult < @fValue) or (@Limit > 4 and  @fResult > @fValue )
 	  	  	  	   Begin
 	  	  	  	  	 Update #Data set Result_FG = Case When @Limit = 1 Then LEntry_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 2 Then LReject_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 3 Then LWarning_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 4 Then LUser_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 5 Then UUser_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 6 Then UWarning_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 7 Then UReject_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 8 Then UEntry_FG
 	  	  	  	  	  	  	  	  	  	  	  	  End
 	  	  	  	  	  	  	  	  	  	  	  	  Where Current of Enum
 	  	  	  	  	  	  	  	  	  	  	  	  
 	  	  	  	  	 Goto EnumLoop
 	  	  	  	   End
 	  	  	  	 End
 	  	  	   Else
 	  	  	  	 Begin
 	  	  	  	  If(@Limit < 5 and  @fResult <= @fValue) or (@Limit > 4 and  @fResult >= @fValue)
 	  	  	  	   Begin
 	  	  	  	  	 Select 'here'
 	  	  	  	  	 Update #Data set Result_FG = Case When @Limit = 1 Then LEntry_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 2 Then LReject_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 3 Then LWarning_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 4 Then LUser_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 5 Then UUser_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 6 Then UWarning_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 7 Then UReject_FG
 	  	  	  	  	  	  	  	  	  	  	  	  When @Limit = 8 Then UEntry_FG
 	  	  	  	  	  	  	  	  	  	  	  	  End
 	  	  	  	  	  	  	  	  	  	  	  	  Where Current of Enum
 	  	  	  	  	 Goto EnumLoop
 	  	  	  	   End
 	  	  	   End
 	  	  	 End
 	  	 Select @Limit = @Limit + 1
 	   End
 	 Goto EnumLoop
  End
   If @DecimalSep != '.' 
     BEGIN
       Update #Data Set Result = REPLACE(Result, '.', @DecimalSep) Where Result_DataType = 2 
     END
   Select Title,Title_FG,15132390,3,0, 
     Description,Desc_FG,Desc_BG,3,0,
     [Eng Units],EngU_FG,EngU_BG,3,0,
     Result,Result_FG, 16777215,Result_DataType ,Result_Precision, 
   LE , LEntry_FG ,LEntry_BG ,Result_DataType ,Result_Precision,LR , LReject_FG , LReject_BG ,Result_DataType ,Result_Precision,LW , LWarning_FG , LWarning_BG ,Result_DataType ,Result_Precision, LU , LUser_FG ,LUser_BG, Result_DataType ,Result_Precision, 
   TGT , Target_FG , Target_BG ,Result_DataType ,Result_Precision, UU , UUser_FG , UUser_BG ,Result_DataType ,Result_Precision, UW, UWarning_FG , UWarning_BG,Result_DataType ,Result_Precision, UR , UReject_FG, UReject_BG ,Result_DataType ,Result_Precision, UE,UEntry_FG, UEntry_BG,Result_DataType ,Result_Precision
    From #Data 
  Drop table #HeaderData
  Drop table #Data
SET NOCOUNT OFF

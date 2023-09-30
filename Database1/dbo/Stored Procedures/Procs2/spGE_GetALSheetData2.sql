Create Procedure dbo.spGE_GetALSheetData2
@EventId 	 int,
@SheetId 	 Int,
@IsEventComp Tinyint,
@DecimalSep     nvarchar(2) = '.',
@LanguageNumber Int = 0
 AS
SET NOCOUNT ON
Select @DecimalSep = COALESCE(@DecimalSep, '.')
Select @LanguageNumber = COALESCE(@LanguageNumber, 0)
Declare @TimeStamp 	   	 Datetime,
 	 @SheetTimeStamp 	   	 Datetime,
 	 @StartTime 	  	 DateTime,
 	 @MasterPU 	  	 Int,
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
 	 @UseStartTime 	 Int,
 	 @TempString nvarchar(100),
 	 @Stime nvarchar(100),
 	 @Etime nvarchar(100),
 	 @Product nvarchar(100),
 	 @Status nvarchar(100),
 	 @POrder nvarchar(100),
 	 @None nvarchar(100),
 	 @Item nvarchar(100)
--Translations
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24116
Select @Stime = coalesce(@TempString,'Start Time') 
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24117
Select @Etime = coalesce(@TempString,'End Time') 
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24108
Select @Product = coalesce(@TempString,'Product') 
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24061
Select @Status = coalesce(@TempString,'Status') 
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 24148
Select @POrder = coalesce(@TempString,'Process Order') 
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 34079
Select @None = coalesce(@TempString,'<none>') 
Select @TempString = NULL
Select @TempString = Prompt_String 
  From Language_Data
  Where Language_Id = @LanguageNumber and Prompt_Number = 34797
Select @Item = coalesce(@TempString,'Item') 
Select @MasterPU = coalesce(p.master_Unit,p.pu_Id)
 	 From events e
 	 join prod_units p on p.pu_Id = e.PU_Id
 	 Where e.Event_Id = @EventId
If @IsEventComp = 0
  Begin
 	 Select @SheetPU = s.Master_Unit,
 	   @SheetDesc = s.Sheet_Desc
 	   From Sheet_Genealogy_Data sgd
 	   Join Sheets s on s.sheet_Id = sgd.Display_Sheet_Id
 	   Where sgd.Sheet_Id = @SheetId and sgd.PU_Id = @MasterPU
 	 
 	 If @SheetDesc is null
 	   Select @SheetDesc = s.Sheet_Desc,@SheetPU = pu.pu_Id
 	    	 From Prod_Units pu
 	     Join Sheets s on s.sheet_Id = pu.Def_Event_Sheet_Id
 	  	 Where pu.pu_Id = @MasterPU
  End
Else
  Begin
 	 Declare @PEI_Id int
 	 Select @PEI_Id = Pei_Id from PrdExec_Input_Event_History Where Event_Id = @EventId
 	   Select @SheetDesc = s.Sheet_Desc,@SheetPU = pei.PU_Id
 	    	 From PrdExec_inputs  pei
 	     Join Sheets s on s.Sheet_Id = pei.Def_Event_Comp_Sheet_Id
 	  	 Where pei.PEI_Id = @PEI_Id
  End
Select  	 @DimADesc = Coalesce(Dimension_A_Name,@None),
 	 @DimXDesc = Coalesce(Dimension_X_Name,@None),
 	 @DimYDesc = Coalesce(Dimension_Y_Name,@None),
 	 @DimZDesc = Coalesce(Dimension_Z_Name,@None),
 	 @AEnabled = Coalesce(Dimension_A_Enabled,0),
 	 @YEnabled = Coalesce(Dimension_Y_Enabled,0),
 	 @ZEnabled = Coalesce(Dimension_Z_Enabled,0),
    @EventDesc = Coalesce(Event_Subtype_Desc,@Item)
 From Event_Configuration e
 Join Event_subtypes es On es.Event_Subtype_Id = e.Event_Subtype_Id
 Where e.PU_Id =  @MasterPU and e.Et_ID = 1
Select @SheetDesc = Coalesce(@SheetDesc,'<none>') -- Do not translate this
Select @EventDesc = Coalesce(@EventDesc,@Item)
Create Table #HeaderData (Caption nvarchar(100),Data nvarchar(100),BlankSpace TinyInt,Forecolor Int)
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
Select @DimX = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_X),@None),
       @DimY = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_Y),@None),
       @DimZ = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_Z),@None),
       @DimA = Coalesce(Convert(nvarchar(25),ed.Final_Dimension_A),@None),
       @ProcessOrder = Coalesce(ppp.Process_Order, ppp2.Process_Order, 'N/A')
 	 From events e
 	 Left Join Event_Details ed On ed.Event_Id = e.Event_Id
        Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
        Left Join Customer_Orders co on col.Order_Id = co.Order_Id
 	  	     Left Join Production_Plan ppp on ed.PP_Id = ppp.PP_Id
 	  	     Left Join Production_Plan_Starts pps on (pps.Start_Time <= e.timestamp and  (pps.End_time > e.Timestamp or  pps.End_time is null))  and pps.pu_id = e.pu_id
 	  	     Left Join Production_Plan ppp2 on ppp2.PP_Id = pps.PP_Id
 	 Where e.Event_Id = @EventID
If @ProcessOrder = 'N/A'
BEGIN
 	 Select @TempString = NULL
 	 Select @TempString = Prompt_String 
 	   From Language_Data
 	   Where Language_Id = @LanguageNumber and Prompt_Number = 24310
 	 Select @ProcessOrder = coalesce(@TempString,'N/A') 
END
Select @TimeStamp = timestamp,@MasterPU = coalesce(pu.master_Unit,pu.pu_Id),@ProdCode = p.Prod_Code,@StartTime = Start_Time,
       @Prod_Id = Applied_Product,@EventNum = Event_Num,@StatusDesc = ProdStatus_Desc,@UseStartTime = coalesce(pu.Uses_Start_Time,0)
 	 From events e
 	 join prod_units pu on pu.pu_Id = e.PU_Id
 	 Join Production_Status ps on ps.ProdStatus_Id = e.Event_Status
 	 left Join Products p on p.Prod_Id = e.Applied_Product
 	 Where Event_Id = @ParentEvent
  Select @SheetTimeStamp = @TimeStamp
  If @IsEventComp = 1
 	 Select @SheetTimeStamp = Max(timestamp) From Event_Components where Event_Id = @EventID
  If @UseStartTime = 0 or @StartTime is null
 	   Select @StartTime = Max(timestamp) From Events where PU_Id = @MasterPU and timestamp < @TimeStamp
  If @Prod_Id is null
    Select @Prod_Id = ps.Prod_Id,@ProdCode = p.Prod_Code
 	 From Production_Starts ps
 	 Join Products p on ps.prod_Id = p.prod_Id
 	 Where PU_Id = @MasterPU and ((Start_Time <= @TimeStamp) and ((End_Time > @TimeStamp) or (End_Time Is NUll)))
DECLARE @DateFields Table (Data DateTime)
Insert Into @DateFields (Data)
 	 Select @StartTime
Insert Into @DateFields (Data)
 	 Select @TimeStamp
Select Data From @DateFields
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@EventDesc,@EventNum,0,0)
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@Stime,'|Time|',1,0)
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@Etime,'|Time|',0,0)
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@Product,@ProdCode,1,0)
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@Status,@StatusDesc,0,255)
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@DimXDesc,@DimX,0,0)
 	 If @YEnabled = 1
 	  	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@DimYDesc,@DimY,0,0)
 	 If @ZEnabled = 1
 	   Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@DimZDesc,@DimZ,0,0)
 	 If @AEnabled = 1
 	   Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@DimADesc,@DimA,0,0)
 	 Insert Into #HeaderData (Caption,Data,BlankSpace,Forecolor) Values (@POrder,@ProcessOrder,0,0)
 	 Select * from #HeaderData
 	 Drop table #HeaderData
  If @SheetTimeStamp is null 
 	 Select @SheetDesc = '<none>' -- do not translate this
  Select Sheet_Desc = @SheetDesc,Timestamp = @SheetTimeStamp
  Select @EventDesc As Event_Title
SET NOCOUNT OFF

CREATE PROCEDURE dbo.spGE_GetRollNumbers
  @PU_Id 	 Int,
  @EndTime 	 DateTime = Null,
  @Interval 	 Int = 24
  AS
DECLARE @Prev_Id  	  	 Int,
 	 @Ts       	  	 Datetime,
        @Next_Id  	  	 Int,
 	 @RecordsFound  	  	 Int,
 	 @LastRecordCount  	 Int,
 	 @PEIS 	  	  	 Int,
 	 @Starttime 	  	 DateTime,
 	 @CursorPU 	  	 Int,
 	 @IsSource 	  	 Int
Declare @Vs Int
If @EndTime Is Null
 	 Select @EndTime = dbo.fnServer_CmnGetDate(GetUTCDate())
set nocount on
Select @Starttime = DateAdd(Hour,-1 * @Interval,@EndTime)
-- Get Valid Events Id's
Create Table #ChildEvents
(EventId  Int,
 PEventId Int,
 IsSource Int)
Create Table #Output( 	 Event_Id 	  	 Int,
 	  	  	 Event_Num  	  	 nvarchar(50),
 	  	  	 Event_Status 	  	 Int,
 	  	  	 TimeStamp 	  	 DateTime,
 	  	  	 Final_Dimension_X  	 Real,
 	  	  	 Parent_Event_Id 	  	 Int,
 	  	  	 Parent_Event_Number     nvarchar(50),
 	  	  	 Parent_Event_Status 	 Int,
 	  	  	 Parent_DimX  	  	 Real,
 	  	  	 Parent_Height 	  	 Real,
 	  	  	 Parent_Comment_Id 	 Int,
 	  	  	 ChildWidth 	  	 Real Null,
 	  	  	 Conformance 	  	 Int,
 	  	  	 Parent_Conformance 	 Int,
 	  	  	 ProductCode 	  	 nvarchar(50) Null,
 	  	  	 OrderNumber 	  	 nvarchar(25) Null,
 	  	  	 Parent_Timestamp 	 DateTime,
 	  	  	 IsSource 	  	 Int,
 	  	  	 PU_Id 	  	  	 Int,
 	  	  	 Comment_Id 	  	 Int,
 	  	  	 StartPosition 	 Real Null,
 	  	  	 Prod_Id 	  	  	 Int,
 	  	  	 Order_Id 	  	 Int,
 	  	  	 AppProdId 	  	 Int,
 	  	  	 Final_Dimension_Y  	 Real,
 	  	  	 Final_Dimension_Z  	 Real,
 	  	  	 Final_Dimension_A  	 Real,
 	  	  	 Process_Order 	   	 nvarchar(50) Null
)
   Select Distinct ps.PU_ID,ps.PEIS_Id into #PUs
 	  	  	 From PrdExec_Inputs pei
 	  	  	 Join PrdExec_Input_Sources ps On ps.PEI_Id = pei.PEI_Id
 	  	  	 Where pei.pu_Id = @PU_Id
PathLoop:
Declare PU_Cursor Cursor For Select PU_Id,PEIS_Id From #Pus
Open PU_Cursor
pLoop:
Fetch Next From PU_Cursor Into @CursorPU,@PEIS
If @@Fetch_Status = 0
  Begin
    Declare vsc Cursor 
      For select Valid_Status From PrdExec_Input_Source_Data Where PEIS_Id  =  @PEIS
    Open vsc
    sLoop:
    Fetch Next From vsc into @Vs
    If @@Fetch_status = 0
      Begin
 	 Insert Into #ChildEvents
          Select e.Event_Id,Coalesce(Source_Event_Id,e.Event_Id),1
           From  Events e  WITH (Index(event_By_PU_And_Status))
           Left  Join Event_Components s on s.Event_Id = e.Event_Id
           Where  e.Event_Status = @Vs and e.PU_Id = @CursorPU and e.event_Id not in (Select PEventId From #ChildEvents)
       Goto sLoop
      End 
    Close vsc
    Deallocate vsc
    Goto pLoop
  End
  Close PU_Cursor
  Deallocate PU_Cursor
Drop Table #PUs
Insert Into #ChildEvents
  Select Event_Id,Source_Event_Id,1
  From Event_Components 
  Where Source_Event_Id in (Select EventId From #ChildEvents) and Event_Id Not IN (Select EventId From #ChildEvents)
  Select PEventId  Into #Dups
 	 From #ChildEvents
 	 group by  PEventId
 	 having count(*) > 1
Delete From #ChildEvents where eventId in (select PEventId From #Dups)
Drop Table #Dups
Insert Into #ChildEvents
 Select e.Event_Id,Coalesce(Source_Event_Id,e.Event_Id),0
 From Events e
 Left Outer Join Event_Components s on s.Event_Id = e.Event_Id
 Where PU_Id = @PU_Id and e.Timestamp Between  @StartTime and @EndTime and e.Event_Id Not IN (Select EventId From #ChildEvents)
Insert Into #ChildEvents
  Select ec.Event_Id,ec.Source_Event_Id,0
  From Event_Components ec
  Where ec.Source_Event_Id in (Select PEventId From #ChildEvents) 
   and ec.Event_Id Not IN (Select EventId From #ChildEvents)
Insert InTo #Output (Event_Id,Event_Num,Event_Status,TimeStamp,Parent_Event_Id,
 	  	      Parent_Event_Number,Parent_Event_Status,Parent_DimX,Conformance,Parent_Height,Parent_Conformance,
 	  	      Parent_Timestamp,IsSource,PU_Id,StartPosition,AppProdId,
                     Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Final_Dimension_A,Parent_Comment_Id,Comment_Id)
 Select e.Event_Id,e.event_num,e.Event_Status,e.TimeStamp,
  Parent_Event_Id = PEventId,Parent_Event_Number = e2.Event_num,Parent_Event_Status = e2.Event_Status,
  Parent_DimX = Coalesce(ed2.Final_Dimension_Z,0),Conformance = coalesce(e.Conformance,0),
  Parent_Height = coalesce(ed2.Final_Dimension_Y,0),
  Parent_Conformance = coalesce(e2.Conformance,0),e2.Timestamp,IsSource,e.PU_Id,
  StartPosition = coalesce(ec.Dimension_Z,0),AppProdId = Coalesce(e.Applied_Product,0), 
  Final_Dimension_X = Coalesce(ed.Final_Dimension_X,0),
  Final_Dimension_Y = Coalesce(ed.Final_Dimension_Y,0),
  Final_Dimension_Z = Coalesce(ed.Final_Dimension_Z,0),
  Final_Dimension_A = Coalesce(ed.Final_Dimension_A,0),
  Parent_Comment_Id = Coalesce(e2.Comment_Id,0),
  Comment_Id = Coalesce(e.Comment_Id,0)
 From #ChildEvents c
 Join events e On e.Event_Id = c.EventId
 Join Events e2 On e2.Event_Id = c.PEventId
 left Join Event_Details ed On  ed.Event_Id = c.EventId
 left Join Event_Details ed2 On  ed2.Event_Id = c.PEventId
 left Join Event_Components  ec On  ec.Event_Id = c.EventId
--select * from Event_Details
/*
Loop Through to update Product,Child Widths, and Order #
*/
Create Table #DefectTable(Defect_Detail_Id Int,Event_Id Int,Final_Dimension_Y real,Start_X Real Null,End_X Real Null,Start_Y Real Null,End_Y Real Null)
Declare @Event 	  	 Int,
 	 @PEvent 	  	 Int,
 	 @TimeS 	  	 DateTime,
 	 @PU 	  	 Int,
 	 @ProdId 	  	 Int,
 	 @OrderId  	 Int,
 	 @AppProd 	 Int,
 	 @OrderNum 	 nvarchar(50),
 	 @ProcessOrder 	 nvarchar(50)
 	 
Declare O  cursor 
 	 For select Event_Id,Parent_Event_Id,Timestamp,PU_ID,AppProdId,IsSource
 	 From #Output
Open O
OPLoop:
  Fetch Next From O InTo @Event,@PEvent,@TimeS,@PU,@AppProd,@IsSource
  If @@Fetch_Status = 0
    Begin
      Update #Output Set ChildWidth =  (Select Sum(Coalesce(e.Final_Dimension_Z,0))
 	  	  From #ChildEvents c
 	  	  Join event_Details e on e.event_Id = c.EventId
   	   	  Where c.PEventId = @PEvent)
 	 Where Current of O
       Select @ProdId = Null
       Select @ProdId = Prod_Id
 	 From  Production_Starts s
 	 Where (s.Start_Time <= @TimeS) and  (s.End_time > @TimeS or  s.End_time is null)  and (s.pu_id = @PU)
       If @AppProd = 0
         Update #Output Set ProductCode = (Select Prod_Code From Products Where Prod_Id = @ProdId)
 	    Where Current of O
       Else
          Update #Output Set ProductCode = (Select Prod_Code From Products Where Prod_Id = @AppProd)
 	    Where Current of O
       Update #Output Set Prod_Id = @ProdId
 	    Where Current of O
       Update #Output Set AppProdId = @AppProd
 	    Where Current of O
     Select @OrderId = 0
     Select @OrderId = Coalesce(Order_Line_Id,0)
 	  	 From Event_Details 
 	  	 Where Event_Id = @Event
 	  Select @OrderId = Coalesce(@OrderId,0)
     Update #Output Set Order_Id = @OrderId
 	 Where Current of O
    Select @OrderNum = '<na>'
    Select @OrderNum =  Coalesce(co.Customer_Order_Number,'<na>')
     	  	 From Customer_Order_Line_Items col
                Left Join Customer_Orders co on col.Order_Id = co.Order_Id
                Where Order_Line_Id = @OrderId
     Update #Output Set OrderNumber = @OrderNum 	 Where Current of O
     Select @OrderId = null
     Select @OrderId = PP_Id
 	  	 From Event_Details 
 	  	 Where Event_Id = @Event
 	   If @OrderId is null
 	  	 Begin
 	  	  	 Select @OrderId = PP_Id
 	  	  	  	 From Production_Plan_starts
 	  	  	 Where Start_Time <= @TimeS and  (End_time > @TimeS or  End_time is null)  and pu_id = @PU
 	  	 End
 	  Select @OrderId = Coalesce(@OrderId,0)
     Select @ProcessOrder = '<na>'
     Select @ProcessOrder =  Coalesce(pp.Process_Order,'<na>')
     	  	 From production_Plan pp
            Where PP_Id = @OrderId
     Update #Output Set Process_Order = @ProcessOrder 	 Where Current of O
 	 Insert Into #DefectTable Execute spGE_PopulateDefects @PEvent
     GoTo OPLoop
    End
Close O
Deallocate O
Drop Table #ChildEvents
Select distinct o.*,Defect_Id = dd.Defect_Detail_Id,Defect_Start_X = dd.Start_X,
 	 Defect_Start_Y = dd.Start_Y,Defect_End_X = dd.End_X,Defect_End_Y = dd.End_Y,
 	 Defect_Desc = coalesce(dt.Defect_Name,''), Severity = coalesce(d.Severity,0),
        GenealogyId = coalesce(ec.Source_Event_Id,o.Parent_Event_Id),Component_Id = Coalesce(ec2.Component_Id,0)
from #output o
Left Join #DefectTable dd On dd.Event_Id = o.Parent_Event_Id
Left Join Defect_Details d On d.Defect_Detail_Id = dd.Defect_Detail_Id
Left Join Defect_Types dt on dt.Defect_Type_Id = d.Defect_Type_Id
Left Join Event_Components ec on ec.Event_Id = o.Parent_Event_Id
Left Join Event_Components ec2 On ec2.Event_Id = o.Event_Id
where IsSource = 1
order by Parent_Timestamp desc,Parent_Event_Id,StartPosition Asc
Select distinct o.*,Defect_Id = dd.Defect_Detail_Id,Defect_Start_X = dd.Start_X,
 	 Defect_Start_Y = dd.Start_Y,Defect_End_X = dd.End_X,Defect_End_Y = dd.End_Y,
 	 Defect_Desc = coalesce(dt.Defect_Name,''), Severity = coalesce(d.Severity,0),
 	 GenealogyId = coalesce(ec.Source_Event_Id,o.Parent_Event_Id),Component_Id = Coalesce(ec2.Component_Id,0)
from #output o
Left Join #DefectTable dd On dd.Event_Id = o.Parent_Event_Id
Left Join Defect_Details d On d.Defect_Detail_Id = dd.Defect_Detail_Id
Left Join Defect_Types dt on  dt.Defect_Type_Id = d.Defect_Type_Id
Left Join Event_Components ec on ec.Event_Id = o.Parent_Event_Id
Left Join Event_Components ec2 On ec2.Event_Id = o.Event_Id
where IsSource = 0
order by Parent_Timestamp desc,Parent_Event_Id,StartPosition Asc
-- Child Defects
Select dd.Event_Id,Defect_Id = dd.Defect_Detail_Id,Defect_Start_X = dd.Start_Position_X,
 	 Defect_Start_Y = dd.Start_Position_Y,Defect_End_X = dd.End_Position_X,
 	 Defect_End_Y = dd.End_Position_Y,Defect_Type_Id,PU_Id = coalesce(PU_Id,0),
 	 Severity = coalesce(dd.Severity,0)
From  Defect_Details dd
where dd.Event_Id in (select Distinct event_Id from #output)
Drop Table #Output
Drop Table #DefectTable
set nocount Off

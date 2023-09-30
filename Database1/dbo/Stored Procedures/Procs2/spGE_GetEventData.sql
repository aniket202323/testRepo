CREATE PROCEDURE dbo.spGE_GetEventData
  @EventId 	  	 Int,
  @SheetPUId 	 Int,
  @EventPUId 	 Int,
  @EventStatus 	 Int
  AS
Declare @ParentId  	  	 Int,
 	  	 @ParentStatus 	 Int,
 	  	 @ParentEventPU 	 Int,
 	  	 @AboveCommit  	 Int
 -- Check parent Status for above or below line
Select @AboveCommit  = 1
If @EventPUId = @SheetPUId
  Begin
    Select @ParentId = null
    Select @ParentId = ec.Source_event_Id,@ParentStatus = e.Event_Status,@ParentEventPU = e.PU_Id
      From Event_Components ec
 	   Join Events e on e.Event_Id = ec.Source_event_Id
 	   Where ec.Event_Id = @EventId
 	   If @ParentStatus is null 
 	  	 Select @AboveCommit = 1
 	   Else
 	    	 If  (Select Count(*)
 	  	  	 From PrdExec_Inputs pei
 	  	  	 Join PrdExec_Input_Sources ps On ps.PEI_Id = pei.PEI_Id
 	  	  	 Join PrdExec_Input_Source_Data psd On psd.PEIS_Id = ps.PEIS_Id
 	  	  	 Where pei.pu_Id = @SheetPUId and ps.PU_Id  =  @ParentEventPU and  Valid_Status = @ParentStatus) > 0  	 
         	 Select @AboveCommit = 1
       	 Else
 	  	  	 Select @AboveCommit  = 0
  End
Select AboveCommit = @AboveCommit
 	  	 
DECLARE @Prev_Id 	  	  	 Int,
 	  	 @Ts       	  	  	 Datetime,
        @Next_Id  	  	  	 Int,
 	  	 @RecordsFound 	   	 Int,
 	  	 @LastRecordCount 	 Int,
 	  	 @IsSource 	  	  	 Int
set nocount On
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
 	  	  	 ChildWidth 	  	 Real Null,
 	  	  	 Conformance 	  	 Int,
 	  	  	 Parent_Conformance 	 Int,
 	  	  	 ProductCode 	  	 nvarchar(50) Null,
 	  	  	 OrderNumber 	  	 nvarchar(25) Null,
 	  	  	 Parent_Timestamp 	 DateTime,
 	  	  	 Parent_Comment_Id 	 Int,
 	  	  	 Comment_Id 	  	 Int,
 	  	  	 IsSource 	  	 Int,
 	  	  	 PU_Id 	  	  	 Int,
 	  	  	 StartPosition 	  	 Real Null,
 	  	  	 Prod_Id 	  	  	 Int,
 	  	  	 Order_Id 	  	 Int,
 	  	  	 AppProdId 	  	 Int,
 	  	  	 Final_Dimension_Y  	 Real,
 	  	  	 Final_Dimension_Z  	 Real,
 	  	  	 Final_Dimension_A  	 Real,
 	  	  	 Process_Order 	   	 nvarchar(50) Null
)
Select @Prev_Id = Null
select  @Prev_Id = Source_event_Id from Event_Components where Event_ID = @EventId
If @Prev_Id is Not NUll 
 	 Select @EventId =   @Prev_Id
Insert Into #ChildEvents 
 Select e.Event_Id,Coalesce(Source_Event_Id,e.Event_Id),1
 From Events e
 Left Outer Join Event_Components s on s.Event_Id = e.Event_Id
 Where e.Event_Id = @EventId
Insert Into #ChildEvents
  Select Event_Id,Source_Event_Id,0
  From Event_Components Where Source_Event_Id in (Select EventId From #ChildEvents) and Event_Id Not IN (Select EventId From #ChildEvents)
Insert InTo #Output (Event_Id,Event_Num,Event_Status,TimeStamp,Parent_Event_Id,
 	  	      Parent_Event_Number,Parent_Event_Status,Parent_DimX,Conformance,Parent_Height,Parent_Conformance,
 	  	      Parent_Timestamp,IsSource,PU_Id,StartPosition,AppProdId,Final_Dimension_X,
 	  	      Final_Dimension_Y,Final_Dimension_Z,Final_Dimension_A,Parent_Comment_Id,Comment_Id)
 Select e.Event_Id,e.event_num,e.Event_Status,e.TimeStamp,
  Parent_Event_Id = PEventId,Parent_Event_Number = e2.Event_num,Parent_Event_Status = e2.Event_Status,
  Parent_DimX = Coalesce(ed2.Final_Dimension_Z,0),Conformance = coalesce(e.Conformance,0),
  Parent_Height = Coalesce(ed2.Final_Dimension_Y,0),
  Parent_Conformance = coalesce(e2.Conformance,0),e2.Timestamp,IsSource,e.PU_Id,
  StartPosition = coalesce(ec.Dimension_Z,0),AppProdId = Coalesce(e.Applied_Product,0),
  Final_Dimension_X = Coalesce(ed.Final_Dimension_X,0),
  Final_Dimension_Y = Coalesce(ed.Final_Dimension_Y,0),
  Final_Dimension_Z = Coalesce(ed.Final_Dimension_Z,0),
  Final_Dimension_A = Coalesce(ed.Final_Dimension_A,0),
  Parent_Comment_Id = coalesce(e2.Comment_Id,0),
  Comment_Id = Coalesce(e.Comment_Id,0)
 From #ChildEvents c
 Join events e On e.Event_Id = c.EventId
 Join Events e2 On e2.Event_Id = c.PEventId
 left Join Event_Details ed On  ed.Event_Id = c.EventId
 left Join Event_Details ed2 On  ed2.Event_Id = c.PEventId
 left Join Event_Components  ec On  ec.Event_Id = c.EventId
/*
Loop Through to update Product,Child Widths, and Order #
*/
Create Table #DefectTable(Defect_Detail_Id Int,Event_Id Int,Final_Dimension_Y real,Start_X Real Null,End_X Real Null,Start_Y Real Null,End_Y Real Null)
Declare @Event 	 Int,
 	 @PEvent 	 Int,
 	 @TimeS 	 DateTime,
 	 @PU 	 Int,
 	 @Ap  	 Int,
 	 @ProdId Int,
 	 @OrdId 	 Int,
 	 @OrdNum nvarchar(25),
 	 @ProcessOrd nvarchar(25)
Declare O  cursor 
 	 For select Event_Id,Parent_Event_Id,Timestamp,PU_ID,AppProdId,IsSource
 	 From #Output
Open O
OPLoop:
  Fetch Next From O InTo @Event,@PEvent,@TimeS,@PU,@Ap,@IsSource
  If @@Fetch_Status = 0
    Begin
      Update #Output Set ChildWidth =  (Select Sum(Coalesce(e.Final_Dimension_Z,0))
 	  	  From #ChildEvents c
 	  	  Join event_Details e on e.event_Id = c.EventId
   	   	  Where c.PEventId = @PEvent and c.IsSource = 0)
 	 Where Current of O
      Select @ProdId = Prod_Id
 	  	 From  Production_Starts s
 	  	 Where (s.Start_Time <= @TimeS and  (s.End_time > @TimeS or  s.End_time is null))  and s.pu_id = @PU
     Update #Output Set Prod_Id =  @ProdId
 	    Where Current of O
      If @Ap  = 0
          Update #Output Set ProductCode =  (select Prod_Code From Products Where Prod_Id = @ProdId) 	 
 	    Where Current of O
     Else
         Update #Output Set ProductCode =  (select Prod_Code From Products Where Prod_Id = @Ap) 	 
 	    Where Current of O
     Select @OrdId = null
     Select @OrdId = Coalesce(Order_Line_Id,0)
 	  	 From Event_Details 
 	  	 Where Event_Id = @Event
 	  Select @OrdId = Coalesce(@OrdId,0)
     Update #Output Set Order_Id = @OrdId 	 Where Current of O
    Select @OrdNum = '<na>'
    Select @OrdNum =  Coalesce(co.Customer_Order_Number,'<na>')
     	  	 From Customer_Order_Line_Items col
                Left Join Customer_Orders co on col.Order_Id = co.Order_Id
                Where Order_Line_Id = @OrdId
     Update #Output Set OrderNumber = @OrdNum 	 Where Current of O
     Select @OrdId = null
     Select @OrdId = PP_Id
 	  	 From Event_Details 
 	  	 Where Event_Id = @Event
 	   If @OrdId is null
 	  	 Begin
 	  	  	 Select @OrdId = PP_Id
 	  	  	  	 From Production_Plan_starts
 	  	  	 Where Start_Time <= @TimeS and  (End_time > @TimeS or  End_time is null)  and pu_id = @PU
 	  	 End
 	  Select @OrdId = Coalesce(@OrdId,0)
     Select @ProcessOrd = '<na>'
     Select @ProcessOrd =  Coalesce(pp.Process_Order,'<na>')
     	  	 From production_Plan pp
            Where PP_Id = @OrdId
     Update #Output Set Process_Order = @ProcessOrd 	 Where Current of O
     Insert Into #DefectTable Execute spGE_PopulateDefects @PEvent
      GoTo OPLoop
    End
Close O
Deallocate O
Drop Table #ChildEvents
Select distinct o.Event_Id,o.Event_Num,o.Event_Status,o.TimeStamp,o.Final_Dimension_X,
 	  	    o.Parent_Event_Id,o.Parent_Event_Number,o.Parent_Event_Status,
 	  	    o.Parent_DimX,o.Parent_Height,o.ChildWidth,o.Conformance,
 	  	    o.Parent_Conformance,o.ProductCode,o.OrderNumber,o.Parent_Timestamp,
 	  	    IsSource = @AboveCommit,o.PU_Id,o.StartPosition,o.Prod_Id,o.Order_Id,o.AppProdId,
 	  	    o.Final_Dimension_Y,o.Final_Dimension_Z,o.Final_Dimension_A,o.Process_Order,
 	  	    Defect_Id = dd.Defect_Detail_Id,Defect_Start_X = dd.Start_X,
 	 Defect_Start_Y = dd.Start_Y,Defect_End_X = dd.End_X,Defect_End_Y = dd.End_Y,
 	 Defect_Desc = Coalesce(dt.Defect_Name,''),Severity = Coalesce(d.Severity,0),
 	 GenealogyId = Coalesce(ec.Source_Event_Id,o.Parent_Event_Id),
 	 Component_Id = coalesce(ec2.Component_Id,0),o.Parent_Comment_Id,o.Comment_Id
   From #output o
   Left Join #DefectTable dd on dd.Event_Id = o.Parent_Event_Id
   Left Join Defect_Details d On d.Defect_Detail_Id = dd.Defect_Detail_Id
   Left Join Defect_Types dt on dt.Defect_Type_Id = d.Defect_Type_Id
   Left Join Event_Components ec On ec.Event_Id = o.Parent_Event_Id
   Left Join Event_Components ec2 On ec2.Event_Id = o.Event_Id
   where IsSource = 0
   order by IsSource desc,Parent_Timestamp desc,Parent_Event_Id,StartPosition Asc
-- Child Defects
Select dd.Event_Id,Defect_Id = dd.Defect_Detail_Id,Defect_Start_X = dd.Start_Position_X,
 	 Defect_Start_Y = dd.Start_Position_Y,Defect_End_X = dd.End_Position_X,
 	 Defect_End_Y = dd.End_Position_Y,Defect_Type_Id,PU_Id = coalesce(PU_Id,0),
 	 Severity = coalesce(dd.Severity,0)
From  Defect_Details dd
where dd.Event_Id in (select Distinct event_Id from #output)
Drop Table #Output
set nocount Off

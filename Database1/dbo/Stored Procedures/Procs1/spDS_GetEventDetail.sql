--  set nocount on  exec spDS_GetEventDetail 2248023,0
Create Procedure dbo.spDS_GetEventDetail
@EventId int,
@OutputType int= NULL,
@RegionalServer Int = 0
AS
 Declare      @SourceEvent int,
              @PUId int,
              @EventSubTypeId int,
              @ThisEventEndTime DateTime,
              @PreviousEventEndTime DateTime,
              @ProdId int,
              @PPId int
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Select @SourceEvent = NULL
 Select @PUId = NULL
 Select @EventSubTypeId = NULL
 Select @ThisEventEndTime = NULL
 Select @PreviousEventEndTime = NULL
 Select @ProdId = NULL
/*
 @OutputType=
 0 - Load Everything
 1 - Load Only Genealogy
 2 - Load Only Events
 3 - Load Only History
 4 - Load Everything but History and Events (include Genealogy)
 5 - Load Everything but Genealogy and History (include Events)
 6 - Load Everything but Genealogy and Events (include History)
*/
---------------------------------------------------------
-- Get Event info
--------------------------------------------------------
 Select @SourceEvent= Source_event, @PUId = PU_Id, @EventSubTypeId = Event_SubType_Id, @ThisEventEndTime = TimeStamp
  From Events
   Where Event_Id= @EventId
 Select @ProdId = Applied_Product from Events where Event_Id = @EventId
 If @ProdId is null
   Begin
     Select @ProdId = PS.Prod_Id from Events EV
               Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
               And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
       Where EV.Event_Id = @EventId
   End
----------------------------------------------------------
-- Get the single Event SubType for the PUId if it could not be found on the ProductionEvent record
----------------------------------------------------------
 If(@EventSubTypeId Is Null)
  Select @EventSubTypeId = Min(ES.EVent_SubType_Id)
--   From Event_SubTypes ES Inner Join Event_Config EC On ES.Event_SubType_Id = EC.Event_SubType_Id 
   From Event_SubTypes ES Inner Join Event_Configuration EC On ES.Event_SubType_Id = EC.Event_SubType_Id 
    Where ES.ET_Id = 1
     And EC.PU_Id = @PUId
If (@OutputType =0 Or @OutputType=4 Or @OutputType=5 Or @OutputType=6 Or @OutputType Is NULL) 
 Begin
--------------------------------------------------------------------
-- PrdExecTrans available the PUId
-------------------------------------------------------------------
  Select From_ProdStatus_Id As From_Status,To_ProdStatus_Id As  To_Status
   From prdExec_Trans
    Where Pu_Id = @PUId
 Select @PreviousEventEndTime = Max(TimeStamp) From Events Where PU_Id = @PUId and TimeStamp < @ThisEventEndTime
--------------------------------------------------------
-- General tab
--------------------------------------------------------
  Select EV.PU_Id, EV.Event_Num, PU.PU_Desc, EV.TimeStamp,  PR.Prod_Code, PS.Prod_Id as OriginalProdId, EV.Applied_Product as Applied_Product_Id, 
         PR2.Prod_Code as Applied_Product, EV.Event_Status, Coalesce(EV.Applied_Product, PS.Prod_Id) as ProdId,
         EV.Source_Event, @EventSubTypeId as EventSubTypeId, ST.ProdStatus_Desc, EV.Comment_Id,
         ES.Event_SubType_Desc as EventSubTypeDesc, ES.Dimension_Y_Enabled, ES.Dimension_Z_Enabled, Dimension_A_Enabled, 
         ED.Event_Id as Detail_Event_Id, EV.Start_Time as StartTime, Coalesce(PU.Uses_Start_Time, 0) as Uses_Start_Time,
         ER.Event_Reason_Name as User_Reason, ER2.Event_Reason_Name as Approver_Reason, PR3.Event_ESignature_Level
   From Events EV Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
                  Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
                   And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
                  Inner Join Products PR on PS.Prod_Id = PR.Prod_Id 
                  Left Outer Join Event_Details ED on EV.Event_id = ED.Event_Id
                  Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = @EventSubTypeId
                  Left Outer Join Customer_Orders OD on ED.Order_Id=OD.Order_Id
                  Left Outer Join Products PR2 on EV.Applied_Product = PR2.Prod_Id
                  Left Outer Join Production_Status ST on Ev.Event_Status = ST.ProdStatus_Id
                  Left Outer Join Event_Reasons ER on ER.Event_Reason_Id = EV.User_Reason_Id
                  Left Outer Join Event_Reasons ER2 on ER2.Event_Reason_Id = EV.Approver_Reason_Id
                  Inner Join Products PR3 on PR3.Prod_Id = @ProdId
    Where EV.EVent_Id = @EventId
End
If (@OutputType = 0 Or @OutputType =1 Or @OutputType=4)
 Begin
-------------------------------------------------------
-- Genealogy tab
-------------------------------------------------------
 Create Table #Parent (
  Event_Id Int,
  PU_Id int,
  Event_SubType_Id int NULL,
  Event_Num nVarChar(25) Null,
  TimeStamp DateTime,
  Comment_Id int NULL,
  Event_Status int NULL,
  Applied_Product_Code nVarChar(25) Null,
  PP_Id int NULL
  )
 Insert Into #Parent 
  Select EV.Event_Id, EV.PU_Id, NULL, EV.Event_Num, EV.TimeStamp, EV.Comment_Id, EV.Event_Status, PR.Prod_Code, ED.PP_Id
   From Event_Components EC
    Inner Join Events EV On EV.Event_Id = EC.Source_Event_Id
    Left Outer Join Event_Details ED on ED.Event_Id = EV.Event_Id
    Left Outer Join Products PR On EV.Applied_Product = PR.Prod_Id
    Where EC.Event_Id =  @EventId  
  Update #Parent set Event_SubType_Id = ES.Event_SubType_Id
   From Event_SubTypes ES Inner Join Event_Configuration EC On ES.Event_SubType_Id = EC.Event_SubType_Id 
    Where ES.ET_Id = 1
     And EC.PU_Id = #Parent.PU_Id
  Update #Parent set PP_Id = Coalesce(#Parent.PP_Id, PPS.PP_Id)
      From Events EV
          Join Production_Plan_Starts PPS on PPS.PU_Id = EV.PU_Id and
              (EV.Timestamp > PPS.Start_Time and (EV.Timestamp <= PPS.End_Time or PPS.End_Time is NULL))
          Where EV.Event_Id = #Parent.Event_Id
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T3 Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT2 Table  (HeaderTag Int,Idx Int)
 	 Insert into @T3(TimeColumns) Values ('TimeStamp')
 	 Insert into @CHT2(HeaderTag,Idx) Values (16334,1)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16312,2)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16335,3)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16164,4)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16313,5)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16304,6)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16319,7)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16336,8)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16337,9)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16338,10)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16339,11)
 	 Insert into @CHT2(HeaderTag,Idx) Values (16340,12)
 	 Select TimeColumns From @T3
 	 Select HeaderTag From @CHT2 Order by Idx
 	 Select  [Event Number] = EV.Event_Num,
 	  	  	 [Type] = ES.Event_SubType_Desc,
 	  	  	 [TimeStamp] = EV.TimeStamp,
 	  	  	 [Product] = Coalesce(EV.Applied_Product_Code, PR.Prod_Code),
 	  	  	 [Status] = ST.ProdStatus_Desc,
 	  	  	 [Unit] = PU.PU_Desc,
 	  	  	 [Comment] = EV.Comment_Id,
 	  	  	 [X] = Case When ED.Final_Dimension_X is Not Null and Dimension_X_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_X) + Dimension_X_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_X is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_X)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [Y] = Case When ED.Final_Dimension_Y is Not Null and Dimension_Y_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_Y) + Dimension_Y_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_Y is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_Y)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [Z] = Case When ED.Final_Dimension_Z is Not Null and Dimension_Z_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_Z) + Dimension_Z_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_Z is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_Z)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [A] = Case When ED.Final_Dimension_A is Not Null and Dimension_A_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_A) + Dimension_A_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_A is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_A)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [Process Order] = PP.Process_Order
 	 -- 	  	 [] = ES.Dimension_X_Name, 
 	 -- 	  	 [] = ES.Dimension_Y_Name,
 	 -- 	  	 [] = ES.Dimension_Z_Name,
 	 -- 	  	 [] = ES.Dimension_X_Eng_Units,
 	 -- 	  	 [] = ES.Dimension_Y_Eng_Units,
 	 -- 	  	 [] = ES.Dimension_Z_Eng_Units,
 	 -- 	  	 [] = ES.Dimension_A_Eng_Units
 	    From #Parent EV Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
 	  	  	  	  	    Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
 	  	  	  	  	  	 And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
 	  	  	  	  	   Inner Join Products PR On PS.Prod_Id = PR.Prod_Id
 	  	  	  	  	   Left Outer Join Production_Status ST on Ev.Event_Status = ST.ProdStatus_Id
 	  	  	  	  	   Left Outer Join Event_Details ED on EV.Event_id = ED.Event_Id
 	  	  	  	  	   Left Outer Join Customer_Orders OD on ED.Order_Id= OD.Order_Id
 	  	  	  	  	   Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = EV.Event_SubType_Id
 	  	  	  	  	   Left Outer Join Production_Plan PP on PP.PP_Id = EV.PP_Id
 	  	 Order by EV.Event_Id 
END
ELSE
BEGIN
  Select EV.Event_Num, EV.TimeStamp, Coalesce(EV.Applied_Product_Code, PR.Prod_Code) as Prod_Code, ST.ProdStatus_Desc, PU.PU_Desc, EV.Comment_Id,
         ED.Final_Dimension_X, ED.Final_Dimension_Y, ED.Final_Dimension_Z, ED.Final_Dimension_A, 
         PP.Process_Order,
         ES.Event_SubType_Desc as EventSubTypeDesc,  ES.Dimension_X_Name, 
         ES.Dimension_Y_Name, ES.Dimension_Z_Name, ES.Dimension_X_Eng_Units, ES.Dimension_Y_Eng_Units,
         ES.Dimension_Z_Eng_Units, ES.Dimension_A_Eng_Units
   From #Parent EV Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
                   Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
                    And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
                  Inner Join Products PR On PS.Prod_Id = PR.Prod_Id
                  Left Outer Join Production_Status ST on Ev.Event_Status = ST.ProdStatus_Id
                  Left Outer Join Event_Details ED on EV.Event_id = ED.Event_Id
                  Left Outer Join Customer_Orders OD on ED.Order_Id= OD.Order_Id
                  Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = EV.Event_SubType_Id
                  Left Outer Join Production_Plan PP on PP.PP_Id = EV.PP_Id
    Order by EV.Event_Id  
END 
Drop Table #Parent
Create Table #Child (
  Event_Id Int,
  PU_Id int,
  Event_SubType_Id int NULL,
  Event_Num nVarChar(25) Null,
  TimeStamp DateTime,
  Comment_Id int NULL,
  Event_Status int NULL,
  Applied_Product_Code nVarChar(25) Null,
  PP_Id int NULL
  )
 Insert Into #Child
  Select EV.Event_Id, EV.PU_Id, NULL, EV.Event_Num, EV.TimeStamp, EV.Comment_Id, EV.Event_Status, PR.Prod_Code, ED.PP_Id
   From Event_Components EC
    Inner Join Events EV On EV.Event_Id = EC.Event_Id
    Left Outer Join Event_Details ED on ED.Event_Id = EV.Event_Id
    Left Outer Join Products PR On EV.Applied_Product = PR.Prod_Id
    Where EC.Source_Event_Id =  @EventId  
  Update #Child set Event_SubType_Id = ES.Event_SubType_Id
   From Event_SubTypes ES Inner Join Event_Configuration EC On ES.Event_SubType_Id = EC.Event_SubType_Id 
    Where ES.ET_Id = 1
     And EC.PU_Id = #Child.PU_Id
  Update #Child set PP_Id = Coalesce(#Child.PP_Id, PPS.PP_Id)
      From Events EV
          Join Production_Plan_Starts PPS on PPS.PU_Id = EV.PU_Id and
              (EV.Timestamp > PPS.Start_Time and (EV.Timestamp <= PPS.End_Time or PPS.End_Time is NULL))
          Where EV.Event_Id = #Child.Event_Id
IF @RegionalServer = 1
BEGIN
 	 /* Same Field on Child */
 	 Select * From @T3
 	 Select HeaderTag From @CHT2 Order by Idx
 	 Select  [Event Number] = EV.Event_Num,
 	  	  	 [Type] = ES.Event_SubType_Desc,
 	  	  	 [TimeStamp] = EV.TimeStamp,
 	  	  	 [Product] = Coalesce(EV.Applied_Product_Code, PR.Prod_Code),
 	  	  	 [Status] = ST.ProdStatus_Desc,
 	  	  	 [Unit] = PU.PU_Desc,
 	  	  	 [Comment] = EV.Comment_Id,
 	  	  	 [X] = Case When ED.Final_Dimension_X is Not Null and Dimension_X_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_X) + Dimension_X_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_X is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_X)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [Y] = Case When ED.Final_Dimension_Y is Not Null and Dimension_Y_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_Y) + Dimension_Y_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_Y is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_Y)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [Z] = Case When ED.Final_Dimension_Z is Not Null and Dimension_Z_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_Z) + Dimension_Z_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_Z is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_Z)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [A] = Case When ED.Final_Dimension_A is Not Null and Dimension_A_Eng_Units is not null Then
 	  	  	  	  	  	 Convert(nVarChar(25),ED.Final_Dimension_A) + Dimension_A_Eng_Units
 	  	  	  	  	    WHEN ED.Final_Dimension_A is Not Null THEN Convert(nVarChar(25),ED.Final_Dimension_A)
 	  	  	  	  	 ELSE  ''
 	  	  	  	  	 END,
 	  	  	 [Process Order] = PP.Process_Order
 	    From #Child EV Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
 	  	  	  	  	   Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
 	  	  	  	  	    And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
 	  	  	  	  	   Inner Join Products PR On PS.Prod_Id = PR.Prod_Id
 	  	  	  	  	   Left Outer Join Production_Status ST on Ev.Event_Status = ST.ProdStatus_Id
 	  	  	  	  	   Left Outer Join Event_Details ED on EV.Event_id = ED.Event_Id
 	  	  	  	  	   Left Outer Join Customer_Orders OD on ED.Order_Id= OD.Order_Id
 	  	  	  	  	   Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = EV.Event_SubType_Id
 	  	  	  	  	   Left Outer Join Production_Plan PP on PP.PP_Id = EV.PP_Id
 	  	   Order by EV.Event_Id
END
ELSE
BEGIN
 	 Select EV.Event_Num, EV.TimeStamp, Coalesce(EV.Applied_Product_Code, PR.Prod_Code) as Prod_Code, ST.ProdStatus_Desc, PU.PU_Desc, EV.Comment_Id,
 	  	  ED.Final_Dimension_X, ED.Final_Dimension_Y, ED.Final_Dimension_Z, ED.Final_Dimension_A, 
 	  	  PP.Process_Order,
 	  	  ES.Event_SubType_Desc as EventSubTypeDesc,   ES.Dimension_X_Name, ES.Dimension_Y_Name,
 	  	  ES.Dimension_Z_Name ,ES.Dimension_X_Eng_Units, ES.Dimension_Y_Eng_Units,
 	  	  ES.Dimension_Z_Eng_Units, ES.Dimension_A_Eng_Units
 	 From #Child EV Inner Join Prod_Units PU On EV.PU_Id = PU.PU_Id
 	  	  	   Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
 	  	  	    And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
 	  	  	   Inner Join Products PR On PS.Prod_Id = PR.Prod_Id
 	  	  	   Left Outer Join Production_Status ST on Ev.Event_Status = ST.ProdStatus_Id
 	  	  	   Left Outer Join Event_Details ED on EV.Event_id = ED.Event_Id
 	  	  	   Left Outer Join Customer_Orders OD on ED.Order_Id= OD.Order_Id
 	  	  	   Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = EV.Event_SubType_Id
 	  	  	   Left Outer Join Production_Plan PP on PP.PP_Id = EV.PP_Id
 	 Order by EV.Event_Id
END
   Drop Table #Child
END
If (@OutputType = 0 Or @OutputType =2 Or @OutputType=5)
BEGIN
-------------------------------------------
-- Events tab.
--------------------------------------------
 Create table #EVENTS (KeyId int NULL,
                       StartTime dateTime NULL,                
                       EndTime dateTime NULL,
 	  	  	  	  	    EventType nVarChar(25),
                       PUId int,
                       Reason1 nVarChar(100) NULL,
                       Reason2 nVarChar(100) NULL,
                       Reason3 nVarChar(100) NULL,
                       Reason4 nVarChar(100) NULL,
                       Action1 nVarChar(100) NULL,
                       Action2 nVarChar(100) NULL,
                       Action3 nVarChar(100) NULL,
                       Action4 nVarChar(100) NULL
)
 Insert Into #EVENTS
  Select w.WED_Id, w.Timestamp, NULL, 'Waste', Coalesce(w.Source_PU_Id, w.PU_Id), er1.Event_Reason_Name, er2.Event_Reason_Name,
         er3.Event_Reason_Name, er4.Event_Reason_Name, er5.Event_Reason_Name, er6.Event_Reason_Name, er7.Event_Reason_Name,
         er8.Event_Reason_Name
    From Waste_Event_Details w
     Join Events e on w.Event_Id = e.Event_Id
     Left Outer Join Event_Reasons er1 on er1.Event_Reason_Id = w.Reason_Level1
     Left Outer Join Event_Reasons er2 on er2.Event_Reason_Id = w.Reason_Level2
     Left Outer Join Event_Reasons er3 on er3.Event_Reason_Id = w.Reason_Level3
     Left Outer Join Event_Reasons er4 on er4.Event_Reason_Id = w.Reason_Level4
     Left Outer Join Event_Reasons er5 on er5.Event_Reason_Id = w.Action_Level1
     Left Outer Join Event_Reasons er6 on er6.Event_Reason_Id = w.Action_Level2
     Left Outer Join Event_Reasons er7 on er7.Event_Reason_Id = w.Action_Level3
     Left Outer Join Event_Reasons er8 on er8.Event_Reason_Id = w.Action_Level4
       Where w.Event_Id = @EventId
--       Where w.PU_Id = @PUId and w.TimeStamp >= @PreviousEventEndTime and w.TimeStamp <= @ThisEventEndTime
 Select @PreviousEventEndTime = Max(TimeStamp) From Events Where PU_Id = @PUId and TimeStamp < @ThisEventEndTime
 Insert Into #EVENTS
  Select t.TEDet_Id, t.Start_Time, t.End_Time, 'Downtime', Coalesce(t.Source_PU_Id, t.PU_Id), er1.Event_Reason_Name, er2.Event_Reason_Name,
         er3.Event_Reason_Name, er4.Event_Reason_Name, er5.Event_Reason_Name, er6.Event_Reason_Name, er7.Event_Reason_Name,
         er8.Event_Reason_Name
    From Timed_Event_Details t
     Left Outer Join Event_Reasons er1 on er1.Event_Reason_Id = t.Reason_Level1
     Left Outer Join Event_Reasons er2 on er2.Event_Reason_Id = t.Reason_Level2
     Left Outer Join Event_Reasons er3 on er3.Event_Reason_Id = t.Reason_Level3
     Left Outer Join Event_Reasons er4 on er4.Event_Reason_Id = t.Reason_Level4
     Left Outer Join Event_Reasons er5 on er5.Event_Reason_Id = t.Action_Level1
     Left Outer Join Event_Reasons er6 on er6.Event_Reason_Id = t.Action_Level2
     Left Outer Join Event_Reasons er7 on er7.Event_Reason_Id = t.Action_Level3
     Left Outer Join Event_Reasons er8 on er8.Event_Reason_Id = t.Action_Level4
       Where t.PU_id = @PUId and t.Start_Time > @PreviousEventEndTime and t.Start_Time <= @ThisEventEndTime
 Insert Into #EVENTS
  Select a.Alarm_Id, a.Start_Time, a.End_Time, 'Alarm', a.Source_PU_Id, er1.Event_Reason_Name, er2.Event_Reason_Name,
         er3.Event_Reason_Name, er4.Event_Reason_Name, er5.Event_Reason_Name, er6.Event_Reason_Name, er7.Event_Reason_Name,
         er8.Event_Reason_Name
    From Alarms a
     Left Outer Join Event_Reasons er1 on er1.Event_Reason_Id = a.Cause1
     Left Outer Join Event_Reasons er2 on er2.Event_Reason_Id = a.Cause2
     Left Outer Join Event_Reasons er3 on er3.Event_Reason_Id = a.Cause3
     Left Outer Join Event_Reasons er4 on er4.Event_Reason_Id = a.Cause4
     Left Outer Join Event_Reasons er5 on er5.Event_Reason_Id = a.Action1
     Left Outer Join Event_Reasons er6 on er6.Event_Reason_Id = a.Action2
     Left Outer Join Event_Reasons er7 on er7.Event_Reason_Id = a.Action3
     Left Outer Join Event_Reasons er8 on er8.Event_Reason_Id = a.Action4
       Where a.Source_PU_Id = @PUId and a.Start_Time > @PreviousEventEndTime and a.Start_Time <= @ThisEventEndTime
 	 IF @RegionalServer = 1
 	 BEGIN
 	  	 DECLARE @T4 Table  (TimeColumns nVarChar(100))
 	  	 DECLARE @CHT4 Table  (HeaderTag Int,Idx Int)
 	  	 Insert into @T4(TimeColumns) Values ('Start Time')
 	  	 Insert into @T4(TimeColumns) Values ('End Time')
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16070,1)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16342,2)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16333,3)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16373,4)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16506,5)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16507,6)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16508,7)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16509,8)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16510,9)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16511,10)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16512,11)
 	  	 Insert into @CHT4(HeaderTag,Idx) Values (16513,12)
 	  	 Select TimeColumns From @T4
 	  	 Select HeaderTag From @CHT4 Order by Idx
 	  	  Select [Tag] = e.KeyId,
 	  	  	  	 [Event Type] = e.EventType,
 	  	  	  	 [Start Time] = e.StartTime,                
 	  	  	  	 [End Time] = e.EndTime,
 	  	  	  	 [Location] = p.PU_Desc,
 	  	  	  	 [Reason 1] = e.Reason1,
 	  	  	  	 [Reason 2] = e.Reason2,
 	  	  	  	 [Reason 3] = e.Reason3,
 	  	  	  	 [Reason 4] = e.Reason4,
 	  	  	  	 [Action 1] = e.Action1,
 	  	  	  	 [Action 2] = e.Action2,
 	  	  	  	 [Action 3] = e.Action3,
 	  	  	  	 [Action 4] = e.Action4
 	  	    From #EVENTS e
 	  	    Join Prod_Units p on p.PU_Id = e.PUId
 	  	  	  order by StartTime desc
 	 END
 	 ELSE
 	 BEGIN
 	  Select e.*, p.PU_Desc
 	    From #EVENTS e
 	    Join Prod_Units p on p.PU_Id = e.PUId
 	  	  order by StartTime desc
 	 END
 	 Drop Table #EVENTS
END
If (@OutputType = 0 Or @OutputType =3 Or @OutputType=6)
BEGIN
 	 -------------------------------------------
 	 -- History tab. This is by far, the slowest piece of the SP
 	 --------------------------------------------
 	 Create table #HIST (Event_Num nVarChar(25) NULL, 	  
 	  	      TimeStamp dateTime NULL,                
         Entry_On dateTime NULL,
 	  	  Event_Status int NULL,               
 	  	  Applied_Product int NULL,            
 	  	  User_Id int NULL,
         Second_User_Id int NULL,
         Signoff_User_Id int NULL,
         Approver_User_Id int NULL,
         Testing_Prct_Complete tinyint NULL,
         Conformance tinyint NULL,
         User_Reason_Id int NULL,
         Approver_Reason_Id int NULL)
 	 Insert Into #HIST
 	  	 Select E.Event_Num, E.TimeStamp, E.Entry_On, E.Event_Status, E.Applied_Product, ISNULL(ES.Perform_User_Id,E.User_Id), E.Second_User_Id, E.User_Signoff_Id, ES.Verify_User_Id, E.Testing_Prct_Complete, E.Conformance, ES.Perform_Reason_Id, ES.Verify_Reason_Id
 	  	 From Event_History E
 	  	 Left outer Join ESignature ES on ES.Signature_Id = e.Signature_Id
 	  	 Where E.Event_Id = @EventId
 	 IF @RegionalServer = 1
 	 BEGIN
 	  	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	  	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	  	 Insert into @T(TimeColumns) Values ('TimeStamp')
 	  	 Insert into @T(TimeColumns) Values ('Entered On')
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16334,1)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16345,2)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16335,3)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16412,4)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16343,5)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16344,6)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16313,7)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16409,8)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16515,9)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16408,10)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16410,11)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16411,12)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16413,13)
 	  	 Insert into @CHT(HeaderTag,Idx) Values (16414,14)
 	  	 Select TimeColumns From @T
 	  	 Select HeaderTag From @CHT Order by Idx
 	  	 Select [Event Number] = H.Event_Num, 
 	  	  	 [User] = US.UserName, 
 	  	  	 [TimeStamp] = H.TimeStamp, 
 	  	  	 [Entered On] = H.Entry_On, 
 	  	  	 [Original Product] = PR.Prod_Code, 
 	  	  	 [Applied Product] = PR2.Prod_Code, 
 	  	  	 [Status] = ST.ProdStatus_Desc, 
 	  	  	 [Second User] = US2.UserName,  
 	  	  	 [Signoff User Name] = US4.UserName,
 	  	  	 [Approver User] = US3.UserName,
 	  	  	 [Percent Complete] = H.Testing_Prct_Complete, 
 	  	  	 [Conformance] = H.Conformance, 
 	  	  	 [User Reason] = ER.Event_Reason_Name, 
 	  	  	 [Approver Reason] = ER2.Event_Reason_Name
 	   From #Hist H Inner Join Production_Starts PS On @PUId = PS.Pu_Id
 	  	  	  	    And  H.TimeStamp >= PS.Start_Time And (H.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
 	    Inner Join Products PR On PS.Prod_Id = PR.Prod_Id
 	    Left Outer Join Products PR2 on H.Applied_Product = PR2.Prod_Id
 	    Left Outer Join Production_Status ST on H.Event_Status = ST.ProdStatus_Id
 	    Left Outer Join Users US on H.User_Id = US.User_Id
 	    Left Outer Join Users US2 on H.Second_User_Id = US2.User_Id
 	    Left Outer Join Users US3 on H.Approver_User_Id = US3.User_Id
 	    Left Outer Join Users US4 on H.Signoff_User_Id = US4.User_Id
 	    Left Outer Join Event_Reasons ER on ER.Event_Reason_Id = H.User_Reason_Id
 	    Left Outer Join Event_Reasons ER2 on ER2.Event_Reason_Id = H.Approver_Reason_Id
 	  	  Order by H.Entry_On Desc
 	 END
 	 ELSE
 	 BEGIN
 	  	  Select H.Event_Num, H.TimeStamp, H.Entry_On, PR.Prod_Code, PR2.Prod_Code as Applied_Product, ST.ProdStatus_Desc, US.UserName,
 	  	  	  	 US2.UserName as SecondUserName, US3.UserName as ApproverUserName, US4.UserName as SignoffUserName,
 	  	  	  	 H.Testing_Prct_Complete, H.Conformance, ER.Event_Reason_Name as UserReason, ER2.Event_Reason_Name as ApproverReason
 	  	   From #Hist H Inner Join Production_Starts PS On @PUId = PS.Pu_Id
 	  	  	  	  	    And  H.TimeStamp >= PS.Start_Time And (H.TimeStamp < PS.End_Time Or PS.End_Time IS NULL)
 	  	    Inner Join Products PR On PS.Prod_Id = PR.Prod_Id
 	  	    Left Outer Join Products PR2 on H.Applied_Product = PR2.Prod_Id
 	  	    Left Outer Join Production_Status ST on H.Event_Status = ST.ProdStatus_Id
 	  	    Left Outer Join Users US on H.User_Id = US.User_Id
 	  	    Left Outer Join Users US2 on H.Second_User_Id = US2.User_Id
 	  	    Left Outer Join Users US3 on H.Approver_User_Id = US3.User_Id
 	  	    Left Outer Join Users US4 on H.Signoff_User_Id = US4.User_Id
 	  	    Left Outer Join Event_Reasons ER on ER.Event_Reason_Id = H.User_Reason_Id
 	  	    Left Outer Join Event_Reasons ER2 on ER2.Event_Reason_Id = H.Approver_Reason_Id
 	  	  	  Order by H.Entry_On Desc
 	 END
 	 Drop Table #HIST 	 
 	 Create table #HIST2 (Entered_On dateTime NULL,
 	  	  Final_Dimension_X real,
 	  	  Final_Dimension_Y real,
 	  	  Final_Dimension_Z real, 
 	  	  Final_Dimension_A real,
 	  	  Order_Id int,
 	  	  Shipment_Item_Id int)
 	 --Event Detail History
 	 Insert Into #HIST2
 	  	 Select E.Entered_On, E.Final_Dimension_X, E.Final_Dimension_Y, E.Final_Dimension_Z, 
 	  	  	  E.Final_Dimension_A, E.Order_Id, E.Shipment_Item_Id
 	  	 From Event_Detail_History E
 	  	 Where E.Event_Id = @EventId
 	 IF @RegionalServer = 1
 	 BEGIN
 	  	 DECLARE @T2 Table  (TimeColumns nVarChar(100))
 	  	 DECLARE @CHT3 Table  (HeaderTag Int,Idx Int)
 	  	 Insert into @T2(TimeColumns) Values ('Entered On')
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16412,1)
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16336,2)
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16337,3)
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16338,4)
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16339,5)
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16346,6)
 	  	 Insert into @CHT3(HeaderTag,Idx) Values (16148,7)
 	  	 Select TimeColumns From @T2
 	  	 Select HeaderTag From @CHT3 Order by Idx
 	  	 Select [Entered On] = Entered_On, 
 	  	  	 [X] = H.Final_Dimension_X, 
 	  	  	 [Y] = H.Final_Dimension_Y, 
 	  	  	 [Z] = H.Final_Dimension_Z, 
 	  	  	 [A] = H.Final_Dimension_A, 
 	  	  	 [Order #] = OD.Plant_Order_Number,
 	  	  	 [Shipment #] = SH.Shipment_Number
 	  	  	 From #Hist2 H 
 	  	  	 Left Outer Join Customer_Orders OD on H.Order_Id=OD.Order_Id
 	  	  	 Left Outer Join Shipment_Line_Items SI On H.Shipment_Item_Id = SI.Shipment_Item_Id
 	  	  	 Left Outer Join Shipment SH on SI.Shipment_Id = SH.Shipment_Id
 	  	  	  Order by H.Entered_On Desc
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select Entered_On, H.Final_Dimension_X, H.Final_Dimension_Y, 
 	  	  	 H.Final_Dimension_Z, H.Final_Dimension_A, OD.Plant_Order_Number,SH.Shipment_Number
 	  	 From #Hist2 H 
 	  	 Left Outer Join Customer_Orders OD on H.Order_Id=OD.Order_Id
 	  	 Left Outer Join Shipment_Line_Items SI On H.Shipment_Item_Id = SI.Shipment_Item_Id
 	  	 Left Outer Join Shipment SH on SI.Shipment_Id = SH.Shipment_Id
     Order by H.Entered_On Desc
 	 END
  Drop Table #HIST2
END

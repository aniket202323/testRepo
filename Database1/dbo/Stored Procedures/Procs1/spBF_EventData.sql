CREATE PROCEDURE dbo.spBF_EventData 
  @MasterUnit int,
  @Start_Time datetime,
  @End_Time datetime,
  @NumRowsToReturn tinyint = 0,
  @InTimeZone nVarChar(200) = null
AS 
--Convert incoming timestamps from TW from @InTimeZone to DB time
Select @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time, @InTimeZone)
Select @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time, @InTimeZone)
Declare @InprogressEventId Int
Declare @MaxTime DateTime
Declare @@EventId int,
 	 @@TimeStamp datetime,
 	 @@ProdId int,
 	 @@ProdDesc nvarchar(50),
 	 @@WasteAmount float
  -- Declare local variables.
  Declare  @Col Table(
     Result_On datetime,
     Start_Time datetime,
     Event_Id int,
     Shop_Order nvarchar(100),  	 --Event_Num
     Event_Status int,
     Event_Status_Desc nvarchar(50),
     Part_Number int, 	      	 --Product
     Part_Number_Desc nvarchar(100),
     Conformance tinyint,
     Testing_Prct_Complete tinyint,
     Quantity float,
     Quantity_Good float,
     Quantity_Bad float
         )
  Insert into @Col (Result_On,Start_Time,Event_Id,Shop_Order,Event_Status,Event_Status_Desc,Part_Number,
 	  	 Part_Number_Desc,Conformance,Testing_Prct_Complete,Quantity,Quantity_Good)
  SELECT e.TimeStamp, e.Start_Time, e.Event_Id, e.Event_Num, e.Event_Status, ps.ProdStatus_Desc, e.Applied_Product, p.Prod_Desc, 
 	   	 Coalesce(e.Conformance,0), Coalesce(e.Testing_Prct_Complete,0), Coalesce(ed.Initial_Dimension_X,0), Coalesce(ed.Final_Dimension_X,0)
 	  FROM events e
 	  LEFT Outer Join Products p on p.Prod_Id = e.Applied_Product
 	  LEFT Outer Join Event_Details ed on ed.Event_Id = e.Event_Id
 	  Join Production_Status ps on ps.ProdStatus_Id = e.Event_Status
  	  WHERE  	 (e.Pu_Id = @MasterUnit) AND
  	    	 (e.TimeStamp >= @Start_Time and e.TimeStamp <= @End_Time and e.Event_Status <> 16)
SELECT @MaxTime = Max(Timestamp) from events WHERE Pu_Id =  @MasterUnit
IF @MaxTime Is Not Null
BEGIN
 	 SELECT @InprogressEventId = event_id FROM events WHERE Pu_Id =  @MasterUnit and Timestamp = @MaxTime and event_status = 16
END
IF @InprogressEventId Is not null
BEGIN
  Insert into @Col (Result_On,Start_Time,Event_Id,Shop_Order,Event_Status,Event_Status_Desc,Part_Number,
 	  	 Part_Number_Desc,Conformance,Testing_Prct_Complete,Quantity,Quantity_Good)
   SELECT e.TimeStamp, e.Start_Time, e.Event_Id, e.Event_Num, e.Event_Status, ps.ProdStatus_Desc, e.Applied_Product, p.Prod_Desc, 
 	   	 Coalesce(e.Conformance,0), Coalesce(e.Testing_Prct_Complete,0), Coalesce(ed.Initial_Dimension_X,0), Coalesce(ed.Final_Dimension_X,0)
 	  FROM events e
 	  LEFT Outer Join Products p on p.Prod_Id = e.Applied_Product
 	  LEFT Outer Join Event_Details ed on ed.Event_Id = e.Event_Id
 	  Join Production_Status ps on ps.ProdStatus_Id = e.Event_Status
  	  WHERE  	 e.Event_Id  = @InprogressEventId
END
Declare Event_Cursor Insensitive Cursor
  For (Select Event_Id, Result_On from @Col)
  For Read Only
Open Event_Cursor
Fetch_Loop:
  Fetch Next From Event_Cursor Into @@EventId, @@TimeStamp
  If (@@FETCH_STATUS = 0)
    Begin
      Select @@ProdId = ps.Prod_Id, @@ProdDesc = p.Prod_Desc
        From Production_Starts ps
        Join Products p on p.Prod_Id = ps.Prod_Id
        Where ps.PU_Id = @MasterUnit and (Start_Time <= @@TimeStamp and (End_Time > @@TimeStamp or End_Time is NULL))
      Select @@WasteAmount = sum(wed.Amount) 
        From Waste_Event_Details wed 
        Where wed.Event_Id = @@EventId
      Update @Col Set Part_Number = Coalesce(Part_Number, @@ProdId), Part_Number_Desc = Coalesce(Part_Number_Desc, @@ProdDesc), Quantity_Bad = Coalesce(@@WasteAmount,0)
 	 Where Event_Id = @@EventId      
      Goto Fetch_Loop
    End
 Close Event_Cursor
 Deallocate Event_Cursor
 Set RowCount @NumRowsToReturn
 SELECT dbo.fnServer_CmnConvertFromDbTime(Result_On, @InTimeZone) as 'Result_On', dbo.fnServer_CmnConvertFromDbTime(Start_Time, @InTimeZone) as 'Start_Time', Event_Id,Shop_Order,Event_Status,Event_Status_Desc,
   Part_Number,Part_Number_Desc,Conformance,Testing_Prct_Complete,Quantity,Quantity_Good,Quantity_Bad,PU_Desc, PU_Desc AS Unit
 	 FROM @Col
 	   Join Prod_Units pu on pu.PU_id = @MasterUnit
 	 ORDER BY Result_On Desc

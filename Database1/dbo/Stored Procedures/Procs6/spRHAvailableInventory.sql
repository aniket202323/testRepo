CREATE PROCEDURE dbo.spRHAvailableInventory
@SourcePU_Id int,
@SheetName nvarchar(100) = NULL
AS
Declare @Sheet_Id int
Declare @ThisPU_Id int
Declare @MaxDays int
If @SheetName Is Not Null
  Begin
    Create Table #MyStatus (Event_Status int)
    Create Table #MyEvents (
      Event_Id int,
      TimeStamp datetime, 
      Event_Num nvarchar(50), 
      Event_Status_Name nvarchar(25) NULL, 
      Original_Product_Id int NULL, 
      Applied_Product_Id int NULL, 
      Product_Code nvarchar(100) NULL
     )
   Select @Sheet_Id = Sheet_Id, @ThisPU_Id = Master_Unit, @MaxDays = Case When Max_Inventory_Days Is Null Then 100 When Max_Inventory_Days = 0 Then 100 Else Max_Inventory_Days End
      From Sheets
      Where Sheet_Desc = @SheetName
    --Get Valid Statuses For This PU_Id
    Insert Into #MyStatus
      Select Distinct pxisd.Valid_Status
        From PrdExec_Input_Source_Data pxisd
        Join PrdExec_Input_Sources pxis on pxis.PEIS_Id = pxisd.PEIS_Id and pxis.PU_Id = @SourcePU_Id
        Join PrdExec_Inputs pxi on pxis.PEI_Id = pxi.PEI_Id and pxi.PU_Id = @ThisPU_Id
/* 
      Old Table Structure 
      Select Distinct Valid_Status
        From PrdExec_Path
        Where PU_Id = @ThisPU_Id and
                   Source_PU_Id = @SourcePU_Id 
*/
  If (select count(Event_Status) From #MyStatus Where Event_Status = 9) = 0 
      Insert Into #MyStatus (Event_Status) Values (9)
   --Get Events We Care About And Original Product
   Insert Into #MyEvents (Event_Id, TimeStamp, Event_Num, Event_Status_Name, Original_Product_id, Applied_Product_Id)
     Select e.Event_id, e.TimeStamp, e.Event_Num, s.ProdStatus_Desc, ps.Prod_Id, e.Applied_Product
       From Events e
       Join Production_Starts ps on ps.PU_Id = @SourcePU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
       Join Production_Status s on s.ProdStatus_Id = e.Event_Status 
       Where (e.PU_Id = @SourcePU_Id) and
                   (e.TimeStamp Between dateadd(day, -1 * @MaxDays, dbo.fnServer_CmnGetDate(getutcdate())) and dbo.fnServer_CmnGetDate(getutcdate()))  and
                   (e.Event_Status in (Select Event_Status From #MyStatus))   
    Update #MyEvents 
      Set Product_Code = (Select p.Prod_Code From Products p Where p.Prod_id = #MyEvents.Original_Product_Id)
    Update #MyEvents 
      Set Product_Code = (Select p.Prod_Code From Products p Where p.Prod_id = #MyEvents.Applied_Product_Id)
      Where Applied_Product_id Is Not Null
    select 
      Event_Id,  
      Event_Num,
      Event_Label = rtrim(convert(nvarchar(20),datediff(minute,timestamp,dbo.fnServer_CmnGetDate(getutcdate())) ) ) + ' Min' ,
      Event_Status_Name, 
      Product_Code,
      TimeStamp 
    from 
      #MyEvents  
    order by timestamp asc
    Drop Table #MyStatus
    Drop Table #MyEvents
  End
Else
  Begin
    select 
      Event_Id,  
      Event_Num,
      Event_Label = '(' + rtrim(convert(nvarchar(20),datediff(minute,timestamp,dbo.fnServer_CmnGetDate(getutcdate())) ) ) + ' Min)'
    from 
      Events  
    where 
      (pu_id = @SourcePU_Id) and
      (event_status = 9)
    order by timestamp asc
  End  

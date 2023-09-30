CREATE Procedure dbo.spMSITopic_InventoryUnitDetails
@Topic 	  	 Int,
@StartTime  	 DateTime,
@EndTime  	 DateTime,
@PUId  	  	 int
 AS
/************************************************************
-- For Testing
--************************************************************
Declare @StartTime DateTime,
 @EndTime   	 DateTime,
 @PUId 	  	 Int,
 @Topic  	 int
Select @StartTime = dateadd(day,-30,dbo.fnServer_CmnGetDate(getUTCdate()))
Select @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
Select @PUId = 2
--************************************************************/
Declare @sInventoryTotalCount  	 varchar(50)
Declare @sInventoryGoodPercent  	 varchar(50)
Declare @sInventoryTotalAmount  	 varchar(50)
Declare @sInventoryGoodAmount  	 varchar(50)
--**********************************************
-- Get Inventory Statistics
--**********************************************
Declare @iInventoryGoodCount  	 int
Declare @iInventoryBadCount  	 int
Declare @iInventoryGoodAmount real
Declare @iInventoryBadAmount  	 real
Select @iInventoryGoodCount = 0
Select @iInventoryBadCount = 0
Select @iInventoryGoodAmount = 0
Select @iInventoryBadAmount = 0
Select @iInventoryGoodCount = coalesce(count(e.event_id),@iInventoryGoodCount),
       @iInventoryGoodAmount = sum(coalesce(ed.final_dimension_x,0))
        From Events e WITH (index (Event_By_PU_And_Status))
 	  	  	  	 Join Production_Status p on e.Event_Status  = p.ProdStatus_Id and p.Status_Valid_For_Input = 1  and p.Count_For_Inventory = 1
        Left outer join event_details ed on ed.event_id = e.event_id
   	  	  	 Where e.pu_Id = @PUId and e.TimeStamp between '1/1/1970' and @EndTime
Select @iInventoryBadCount = coalesce(count(e.event_id),@iInventoryBadCount),
       @iInventoryBadAmount = sum(coalesce(ed.final_dimension_x,0))
        From Events e WITH (index (Event_By_PU_And_Status))
 	  	  	  	 Join Production_Status p on e.Event_Status  = p.ProdStatus_Id and p.Status_Valid_For_Input = 0  and p.Count_For_Inventory = 1
        Left outer join event_details ed on ed.event_id = e.event_id
   	  	  	 Where e.pu_Id = @PUId and e.TimeStamp between '1/1/1970' and @EndTime
--**********************************************
-- Prepare Lables, Etc
--**********************************************
Declare @iAmountEngineeringUnits varchar(25)
Declare @iItemEngineeringUnits varchar(25)
Select @iItemEngineeringUnits = s.event_subtype_desc,
       @iAmountEngineeringUnits = s.dimension_x_eng_units
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @PUId and 
        e.et_id = 1
Select @iItemEngineeringUnits = coalesce(@iItemEngineeringUnits,'Event')
Select @iAmountEngineeringUnits = coalesce(@iAmountEngineeringUnits,'Units')
--**********************************************
-- Calculate Return Strings, Etc
--**********************************************
-- inventory total count
Select @sInventoryTotalCount = convert(varchar(25),@iInventoryGoodCount + @iInventoryBadCount) + ' ' + @iItemEngineeringUnits
-- inventory good percent
Select @sInventoryGoodPercent = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 When @iInventoryGoodCount + @iInventoryBadCount = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 '100% Qual'
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar(25),convert(decimal(10,1),@iInventoryGoodCount / convert(real, @iInventoryGoodCount + @iInventoryBadCount) * 100.0)) + '% Qual'
                                End  	 
-- inventory total amount
Select @sInventoryTotalAmount = Case 
 	  	                               When @iInventoryGoodAmount +  @iInventoryBadAmount > 1000000 then
 	  	                                 convert(varchar(25),convert(decimal(10,2),(@iInventoryGoodAmount +  @iInventoryBadAmount) / 1000000.0)) + ' M' + @iAmountEngineeringUnits + ' Total'
 	  	                               When @iInventoryGoodAmount +  @iInventoryBadAmount > 1000 then
 	  	                                 convert(varchar(25),convert(decimal(10,1),(@iInventoryGoodAmount +  @iInventoryBadAmount) / 1000.0)) + ' k' + @iAmountEngineeringUnits + ' Total'
 	  	                               Else
 	  	                                 convert(varchar(25),convert(decimal(10,1),(@iInventoryGoodAmount +  @iInventoryBadAmount))) + ' ' + @iAmountEngineeringUnits + ' Total'
 	  	                             End
-- inventory good amount
Select @sInventoryGoodAmount = Case 
 	  	                               When @iInventoryGoodAmount > 1000000 then
 	  	                                 convert(varchar(25),convert(decimal(10,2),(@iInventoryGoodAmount) / 1000000.0)) + ' M' + @iAmountEngineeringUnits + ' Good'
 	  	                               When @iInventoryGoodAmount > 1000 then
 	  	                                 convert(varchar(25),convert(decimal(10,1),(@iInventoryGoodAmount) / 1000.0)) + ' k' + @iAmountEngineeringUnits + ' Good'
 	  	                               Else
 	  	                                 convert(varchar(25),convert(decimal(10,1),(@iInventoryGoodAmount))) + ' ' + @iAmountEngineeringUnits + ' Good'
 	  	                             End
--**********************************************
-- Build Output Resultset
--**********************************************
Create table #OutputData(FieldValue VarChar(50),ForeColor Int,Backcolor Int,Node_Key VarChar(2))
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sInventoryTotalCount,0,9894650,'jp')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sInventoryGoodPercent,0,9894650,'jq')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sInventoryTotalAmount,0,9894650,'jr')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sInventoryGoodAmount,0,9894650,'js')
--**********************************************
-- Return Topic
--**********************************************
Select Type =4, 	 
 	 Topic 	  	  	 = @Topic,
 	 KeyValue 	  	 = @PUId,
 	 PUId 	  	  	 = @PUId,
 	 StartTime  	  	 = convert(VarChar(25),@StartTime,120),
 	 EndTime 	  	 = convert(VarChar(25),@EndTime,120),*
from #OutputData
Drop Table #OutputData

CREATE Procedure dbo.spMSITopic_ProductionUnitDetails
@StartTime DateTime,
@EndTime   	 DateTime,
@PU_Id 	  	 Int,
@Topic  	 int
AS
/************************************************************
-- For Testing
--************************************************************
Declare @StartTime DateTime,
 @EndTime   	 DateTime,
 @PU_Id 	  	 Int,
 @Topic  	 int
Select @StartTime = dateadd(day,-30,dbo.fnServer_CmnGetDate(getUTCdate()))
Select @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
Select @PU_Id = 2
--************************************************************/
Declare @HighAlarmCount  	  	  	  	 int
Declare @MediumAlarmCount  	  	  	 int
Declare @LowAlarmCount  	  	  	  	  	 int
Declare @DowntimeCurrentStatus  	 int
Declare @sInventoryTotalCount  	 varchar(50)
Declare @sInventoryGoodPercent  	 varchar(50)
Declare @sProductCode  	  	  	  	  	 varchar(50)
Declare @sProcessOrder  	  	  	  	  	 varchar(50)
Declare @sProductionRate  	  	  	  	 varchar(50)
Declare @sProductionRatePercent varchar(50)
Declare @sProductionAmount  	  	  	 varchar(50)
Declare @sProductionTotalCount  	 varchar(50)
Declare @sProductionGoodCount  	 varchar(50)
Declare @sDowntimeMinutes  	  	  	 varchar(50)
Declare @sDowntimePercent  	  	  	 varchar(50)
Declare @sWasteAmount  	  	  	  	  	 varchar(50)
Declare @sWastePercent  	  	  	  	  	 varchar(50)
Declare @sOEEPercent  	  	  	  	  	  	 varchar(50)
Declare @iProductionAmountColor int
Declare @iDowntimePercentColor  int
Declare @iWastePercentColor 	  	  	 int
Declare @iOEEPercentColor 	  	  	  	 int
Select @iProductionAmountColor = 0
Select @iDowntimePercentColor = 0
Select @iWastePercentColor = 0
Select @iOEEPercentColor = 0
--**********************************************
-- Get Alarm Statistics
--**********************************************
Declare @@AlarmPriority int
Select @HighAlarmCount = 0
Select @MediumAlarmCount = 0
Select @LowAlarmCount = 0
Declare @ASum table (ATVRD_Id int, AP_Id int)
Declare @ASumGroup table (AP_Id int, CountAP_Id int)
Insert into @ASum (ATVRD_Id, AP_Id)
  Select Distinct atvrd.ATVRD_Id, atvrd.AP_Id 
    From Alarm_Template_Var_Data atd 
    Join Variables v on v.Var_Id = atd.Var_Id and v.PU_Id = @PU_Id
 	 JOIN Alarm_Template_Variable_Rule_Data atvrd on atd.ATVRD_Id = atvrd.ATVRD_Id
Insert into @ASumGroup (AP_Id, CountAP_Id)
  Select Ap_Id, COUNT(AP_Id)
    from Alarms a
    Join @ASum atd on atd.ATVRD_Id = a.ATVRD_Id
    Where Start_Time <= @EndTime and (End_Time >  @StartTime or End_Time Is Null) and Source_PU_Id = @PU_Id
    Group by AP_Id
Select @LowAlarmCount    = CountAP_Id From @ASumGroup Where AP_Id = 1
Select @MediumAlarmCount = CountAP_Id From @ASumGroup Where AP_Id = 2
Select @HighAlarmCount   = CountAP_Id From @ASumGroup Where AP_Id = 3
--**********************************************
-- Get Inventory Statistics
--**********************************************
Declare @iInventoryGoodCount  	 int
Declare @iInventoryBadCount  	 int
Select @iInventoryGoodCount = (Select Count(*) From Events e WITH (index(Event_By_PU_And_Status))
 	  	  	  	 Join Production_Status p on e.Event_Status  = p.ProdStatus_Id and p.Status_Valid_For_Input = 1  and p.Count_For_Inventory = 1
   	  	  	  	 Where pu_Id = @PU_Id and TimeStamp between '1/1/1970' and @EndTime)
Select @iInventoryBadCount = (Select Count(*) From Events e WITH (index(Event_By_PU_And_Status))
 	  	  	  	 Join Production_Status p on e.Event_Status  = p.ProdStatus_Id and p.Status_Valid_For_Input = 0 and p.Count_For_Inventory = 1
   	  	  	  	 Where pu_Id = @PU_Id and TimeStamp between '1/1/1970' and @EndTime)
--**********************************************
-- Get Product Code & Process Order
--**********************************************
Select @sProductCode = coalesce(p.Prod_Code, '<None>')
  From Production_Starts ps
  Join Products  p on p.Prod_Id = ps.Prod_Id
  Where End_Time Is Null and ps.PU_Id = @PU_Id
Select @sProcessOrder = coalesce(pp.process_order, '<None>')
  From Production_Plan_Starts pps
  Join Production_Plan pp on pp.pp_id = pps.pp_id
  Where pps.PU_Id = @PU_Id and
        pps.Start_Time <= @EndTime and
        (pps.End_Time > @EndTime or pps.End_Time Is Null) 
--**********************************************
-- Get Basic Production Statistics
--**********************************************
Declare @iIdealProduction real,  
@iIdealYield real,  
@iActualProduction real,
@iActualQualityLoss real,
@iActualYieldLoss real,
@iActualSpeedLoss real,
@iActualDowntimeLoss real,
@iActualDowntimeMinutes real,
@iActualRuntimeMinutes real,
@iActualUnavailableMinutes real,
@iActualSpeed real,
@iActualPercentOEE real,
@iActualTotalItems int,
@iActualGoodItems int,
@iActualBadItems int,
@iActualConformanceItems int,
@iTargetProduction real,
@iWarningProduction real,  
@iRejectProduction real,  
@iTargetQualityLoss real,
@iWarningQualityLoss real,
@iRejectQualityLoss real,
@iTargetDowntimeLoss real,
@iWarningDowntimeLoss real,
@iRejectDowntimeLoss real,
@iTargetSpeed real,
@iTargetDowntimeMinutes real,
@iWarningDowntimeMinutes real,
@iRejectDowntimeMinutes real,
@iTargetPercentOEE real,
@iWarningPercentOEE real,
@iRejectPercentOEE real,
@iAmountEngineeringUnits varchar(25),
@iItemEngineeringUnits varchar(25),
@iTimeEngineeringUnits int,
@iStatus int,
@iActualDowntimeCount int
execute spCMN_GetUnitStatistics
 	  	 @PU_Id,
 	  	 @StartTime,
 	  	 @EndTime,
 	  	 @iIdealProduction OUTPUT,  
 	  	 @iIdealYield OUTPUT,  
 	  	 @iActualProduction OUTPUT,
 	  	 @iActualQualityLoss OUTPUT,
 	  	 @iActualYieldLoss OUTPUT,
 	  	 @iActualSpeedLoss OUTPUT,
 	  	 @iActualDowntimeLoss OUTPUT,
 	  	 @iActualDowntimeMinutes OUTPUT,
 	  	 @iActualRuntimeMinutes OUTPUT,
 	  	 @iActualUnavailableMinutes OUTPUT,
 	  	 @iActualSpeed OUTPUT,
 	  	 @iActualPercentOEE OUTPUT,
 	  	 @iActualTotalItems OUTPUT,
 	  	 @iActualGoodItems OUTPUT,
 	  	 @iActualBadItems OUTPUT,
 	  	 @iActualConformanceItems OUTPUT,
 	  	 @iTargetProduction OUTPUT,
 	  	 @iWarningProduction OUTPUT,  
 	  	 @iRejectProduction OUTPUT,  
 	  	 @iTargetQualityLoss OUTPUT,
 	  	 @iWarningQualityLoss OUTPUT,
 	  	 @iRejectQualityLoss OUTPUT,
 	  	 @iTargetDowntimeLoss OUTPUT,
 	  	 @iWarningDowntimeLoss OUTPUT,
 	  	 @iRejectDowntimeLoss OUTPUT,
 	  	 @iTargetSpeed OUTPUT,
 	  	 @iTargetDowntimeMinutes OUTPUT,
 	  	 @iWarningDowntimeMinutes OUTPUT,
 	  	 @iRejectDowntimeMinutes OUTPUT,
 	  	 @iTargetPercentOEE OUTPUT,
 	  	 @iWarningPercentOEE OUTPUT,
 	  	 @iRejectPercentOEE OUTPUT,
 	  	 @iAmountEngineeringUnits OUTPUT,
 	  	 @iItemEngineeringUnits OUTPUT,
 	  	 @iTimeEngineeringUnits OUTPUT,
 	  	 @iStatus OUTPUT,
    @iActualDowntimeCount OUTPUT
--**********************************************
-- Prepare Lables, Etc
--**********************************************
Select @iItemEngineeringUnits = coalesce(@iItemEngineeringUnits,'Event')
Select @iAmountEngineeringUnits = coalesce(@iAmountEngineeringUnits,'Units')
Select @iTimeEngineeringUnits = coalesce(@iTimeEngineeringUnits,1)
--**********************************************
-- Calculate Return Strings, Etc
--**********************************************
-- downtime status
Select @DowntimeCurrentStatus = @iStatus
-- inventory total count
Select @sInventoryTotalCount = convert(varchar(25),@iInventoryGoodCount + @iInventoryBadCount) + ' ' + @iItemEngineeringUnits
-- inventory good percent
Select @sInventoryGoodPercent = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 When @iInventoryGoodCount + @iInventoryBadCount = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 '100% Qual'
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar(25),round(@iInventoryGoodCount / convert(real,@iInventoryGoodCount + @iInventoryBadCount) * 100.0, 0)) + '% Qual'
                                End  	 
-- production rate
Select @sProductionRate = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	   When @iTimeEngineeringUnits = 0 Then -- /hour
                              convert(varchar(25),convert(decimal(10,1),@iActualSpeed / 60.0)) + ' ' + @iAmountEngineeringUnits + '/hr' 
 	  	  	  	  	  	  	  	  	  	  	  	  	   When @iTimeEngineeringUnits = 2 Then -- /second
                              convert(varchar(25),convert(decimal(10,1),@iActualSpeed * 60.0)) + ' ' + @iAmountEngineeringUnits + '/sec' 
 	  	  	  	  	  	  	  	  	  	  	  	  	   When @iTimeEngineeringUnits = 3 Then -- /day
                              convert(varchar(25),convert(decimal(10,1),@iActualSpeed / 1440.0)) + ' ' + @iAmountEngineeringUnits + '/day' 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Else -- /min
                              convert(varchar(25),convert(decimal(10,1),@iActualSpeed)) + ' ' + @iAmountEngineeringUnits + '/min' 
 	  	  	  	  	  	  	  	  	  	  	  	  	 End  	  	  	  	 
-- production rate percent target
If @iTargetSpeed = 0
 	 Select @sProductionRatePercent =  '0% Rate'
Else
  Select @sProductionRatePercent  = convert(varchar(25),convert(decimal(10,1),@iActualSpeed / @iTargetSpeed * 100)) + '% Rate'
-- production amount (with limit check)
Select @sProductionAmount = Case 
                              When @iActualProduction > 1000000 then
                                convert(varchar(25),convert(decimal(10,2),@iActualProduction / 1000000.0)) + ' M' + @iAmountEngineeringUnits
                              When @iActualProduction > 1000 then
                                convert(varchar(25),convert(decimal(10,1),@iActualProduction / 1000.0)) + ' k' + @iAmountEngineeringUnits
                              Else
                                convert(varchar(25),convert(decimal(10,1),@iActualProduction)) + ' ' + @iAmountEngineeringUnits
                            End
Select @iProductionAmountColor = Case
                                   When @iActualProduction < @iRejectProduction then 255
                                   Else 0
                                 End   	  	  	 
-- production items total
Select @sProductionTotalCount = convert(varchar(25),@iActualTotalItems) + @iItemEngineeringUnits
-- production good items
Select @sProductionGoodCount = convert(varchar(25),@iActualGoodItems) + ' Good ' + @iItemEngineeringUnits
-- downtime minutes
Select @sDowntimeMinutes = convert(varchar(10),floor(@iActualDowntimeMinutes / 60.0)) + ':' + right('0' + convert(varchar(10),convert(int,round(@iActualDowntimeMinutes,0)) % 60),2) + ' ' + 'Down'
-- downtime percent (with limit check)
Select @sDowntimePercent = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 When @iActualRuntimeMinutes + @iActualDowntimeMinutes = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 '<N/A>'
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar(25),round(@iActualDowntimeMinutes / (@iActualDowntimeMinutes + @iActualRuntimeMinutes) * 100.0, 1)) + '% Down'
                            End  	 
Select @iDowntimePercentColor = Case
                                   When @iActualDowntimeMinutes > @iRejectDowntimeMinutes then 255
                                   Else 0
                                 End   	  	  	 
-- waste amount
Select @sWasteAmount = Case 
                              When @iActualQualityLoss > 1000000 then
                                convert(varchar(25),convert(decimal(10,2),@iActualQualityLoss / 1000000.0)) + ' M' + @iAmountEngineeringUnits + ' ' + 'Waste'
                              When @iActualQualityLoss > 1000 then
                                convert(varchar(25),convert(decimal(10,1),@iActualQualityLoss / 1000.0)) + ' k' + @iAmountEngineeringUnits + ' ' + 'Waste'
                              Else
                                convert(varchar(25),convert(decimal(10,1),@iActualQualityLoss)) + ' ' + @iAmountEngineeringUnits + ' ' + 'Waste'
                            End
-- waste percent (with limit check)
Select @sWastePercent = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	 When @iActualQualityLoss + @iActualProduction = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 '<N/A>'
 	  	  	  	  	  	  	  	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar(25),round(@iActualQualityLoss / (@iActualQualityLoss + @iActualProduction) * 100.0, 1)) + '% Waste'
                        End  	 
Select @iWastePercentColor = Case
                               When @iActualQualityLoss > @iRejectQualityLoss then 255
                               Else 0
                             End   	  	  	 
-- OEE percent (with limit check)
Select  @sOEEPercent = convert(varchar(25),convert(decimal(10,1),@iActualPercentOEE)) + '% Eff' 
Select @iOEEPercentColor = Case
                             When @iActualPercentOEE > @iRejectPercentOEE then 255
                             Else 0
                           End   	  	  	 
--**********************************************
-- Build Output Resultset
--**********************************************
Declare @OutputData table (FieldValue VarChar(50),ForeColor Int,Backcolor Int,Node_Key VarChar(2))
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sInventoryTotalCount,0,13158550,'ja')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sInventoryGoodPercent,0,13158550,'jb')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductCode,0,9894650,'jc')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProcessOrder,0,9894650,'jd')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionRate,0,9894650,'je')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionAmount,@iProductionAmountColor,9894650,'jf')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionTotalCount,0,9894650,'jg')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionGoodCount,0,9894650,'jh')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sDowntimeMinutes,0,9894650,'ji')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sDowntimePercent,@iDowntimePercentColor,9894650,'jj')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sWasteAmount,0,9894650,'jk')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sWastePercent,@iWastePercentColor,9894650,'jl')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sOEEPercent,@iOEEPercentColor,9894650,'jm')
Insert into @OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionRatePercent,0,9894650,'jn')
--**********************************************
-- Return Topic
--**********************************************
Select Type =4, 	 
 	 Topic 	  	  	 = @Topic,
 	 KeyValue 	  	 = @PU_Id,
 	 High_Alarm 	  	 = @HighAlarmCount,
 	 Medium_Alarm 	  	 = @MediumAlarmCount,
 	 Low_Alarm 	  	 = @LowAlarmCount,
 	 DownTime_Status 	 = Case @DowntimeCurrentStatus
                      When 1 then 0
                      When 0 Then 1
                      Else 2
                    End,
 	 DowntimeCount 	 = coalesce(@iActualDowntimeCount,0),  -- need to fix
 	 Pu_Id 	  	  	 = @PU_Id,
 	 StartTime  	  	 = convert(VarChar(25),@StartTime,120),
 	 EndTime  	  	 = convert(VarChar(25),@EndTime,120),* 
from @OutputData

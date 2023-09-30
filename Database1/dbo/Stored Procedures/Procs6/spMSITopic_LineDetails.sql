CREATE Procedure dbo.spMSITopic_LineDetails
@Topic 	  	 Int,
@StartTime  	 DateTime,
@EndTime  	 DateTime,
@PLId  	  	 int
AS
/************************************************************
-- For Testing
--************************************************************
Declare @StartTime DateTime,
 @EndTime   	 DateTime,
 @PLId 	  	 Int,
 @Topic  	 int
Select @StartTime = dateadd(day,-30,dbo.fnServer_CmnGetDate(getUTCdate()))
Select @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
Select @PLId = 1
execute spMSITopic_LineDetails 101,@StartTime,@EndTime,@PLId
--************************************************************/
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
@iActualTotalMinutes real,
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
@iScheduleDeviationMinutes real,
@iActualDowntimeCount int
execute spCMN_GetLineStatistics
 	  	 @PLId,
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
    @iActualTotalMinutes OUTPUT,
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
    @iScheduleDeviationMinutes OUTPUT,
    @iActualDowntimeCount OUTPUT
--**********************************************
-- Prepare Lables, Etc
--**********************************************
Select @iItemEngineeringUnits = coalesce(@iItemEngineeringUnits,'Events')
Select @iAmountEngineeringUnits = coalesce(@iAmountEngineeringUnits,'Units')
Select @iTimeEngineeringUnits = coalesce(@iTimeEngineeringUnits,1)
--**********************************************
-- Calculate Return Strings, Etc
--**********************************************
-- production rate
If @iActualSpeed > 10000000
 	 Select @sProductionRate = 'N/A'
Else
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
If @iTargetSpeed =  0
 	 Select @sProductionRatePercent = 'N/A'
Else
 	 Select @sProductionRatePercent  = convert(varchar(25),convert(decimal(10,1),@iActualSpeed / @iTargetSpeed * 100)) + '% Rate'
-- production amount (with limit check)
If @iActualProduction > 1000000000
 	 Select @sProductionAmount = 'N/A'
Else
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
Select @sDowntimeMinutes = convert(varchar(10),floor(@iActualDowntimeMinutes / 60.0)) + ':' + right('0' + convert(varchar(10),convert(int,round(@iActualDowntimeMinutes,0)) % 60),2) + ' Down'
-- downtime percent (with limit check)
Select @sDowntimePercent = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 When @iActualRuntimeMinutes + @iActualDowntimeMinutes = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 'N/A'
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
                                convert(varchar(25),convert(decimal(10,2),@iActualQualityLoss / 1000000.0)) + ' M' + @iAmountEngineeringUnits + ' Waste'
                              When @iActualQualityLoss > 1000 then
                                convert(varchar(25),convert(decimal(10,1),@iActualQualityLoss / 1000.0)) + ' k' + @iAmountEngineeringUnits + ' Waste'
                              Else
                                convert(varchar(25),convert(decimal(10,1),@iActualQualityLoss)) + ' ' + @iAmountEngineeringUnits + ' Waste'
                            End
-- waste percent (with limit check)
Select @sWastePercent = Case
 	  	  	  	  	  	  	  	  	  	  	  	  	 When @iActualQualityLoss + @iActualProduction = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 'N/A'
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
Create table #OutputData(FieldValue VarChar(50),ForeColor Int,Backcolor Int,Node_Key VarChar(2))
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionRate,0,9894650,'jt')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionAmount,@iProductionAmountColor,9894650,'ju')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionTotalCount,0,9894650,'jv')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionGoodCount,0,9894650,'jw')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sDowntimeMinutes,0,9894650,'jx')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sDowntimePercent,@iDowntimePercentColor,9894650,'jy')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sWasteAmount,0,9894650,'jz')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sWastePercent,@iWastePercentColor,9894650,'ka')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sOEEPercent,@iOEEPercentColor,9894650,'kb')
Insert into #OutputData (FieldValue,ForeColor,BackColor,Node_Key) Values (@sProductionRatePercent,0,9894650,'kc')
--**********************************************
-- Return Topic
--**********************************************
Select Type =4, 	 
 	 Topic 	  	  	 = @Topic,
 	 KeyValue 	  	 = @PLId,
 	 PLId 	  	  	 = @PLId,
 	 StartTime  	  	 = convert(VarChar(25),@StartTime,120),
 	 EndTime 	  	 = convert(VarChar(25),@EndTime,120),*
from #OutputData
Drop Table #OutputData

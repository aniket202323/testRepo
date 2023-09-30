/*********Called during install after all em sps are installed ***********/
Create Procedure dbo.spSupport_AddSampleData
As 
Set nocount on
If (Select Count(*) from Event_Reasons) = 0
 	 Begin
 	  	 /* Tree 1 */
 	  	 Execute spEM_IEImportReasonTrees 'Sample_Downtime_Cause',Null,'Type','Reason','Detail',Null,1
 	  	 /* Tree 2*/
 	  	 Execute spEM_IEImportReasonTrees 'Sample_Alarm_Cause',Null,'Area','Type','Reason','Detail',1
 	  	 /* Tree 3*/
 	  	 Execute spEM_IEImportReasonTrees 'Sample_Alarm_Action',Null,'Action','Type',Null,Null,1
 	  	 /* Tree 4*/
 	  	 Execute spEM_IEImportReasonTrees 'Sample_Waste_Cause',Null,'Type','Reason','Detail',Null,1
 	  	 
 	  	 /* Add Trees */
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unscheduled Time','Force Majeure (Acts of God)','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unscheduled Time','No Resources','Personnel','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unscheduled Time','No Resources','Materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unscheduled Time','No Orders','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unscheduled Time','Other','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Not Scheduled','Plant is closed','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Electrical','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Engineering','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Mechanical','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Operations','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Electrical','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Engineering','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Mechanical','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Operations','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unit Restraint','Starved','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Unit Restraint','Blocked','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Machine Jam','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','No raw materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop for required adjustment ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop for Quality','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Slow down time','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop required for Lubrication','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop required for Overheating','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Major Component Failure','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Part(s) failure','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Adjustment required','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Operating procedure advice','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Stop required for Overheating','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Lubrication','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Machine Jam','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','No raw materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop for required adjustment ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop for Quality','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Slow down time','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop required for Lubrication','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop required for Overheating','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Setup & Adjustments','Product Change','CIP','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Setup & Adjustments','Product Change','Configuration','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Setup & Adjustments','Quality Change','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Setup & Adjustments','Adjustments required','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Setup & Adjustments','Shift Maintenance/Daily cleaning','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Startup/Shutdown','Ramping Up','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Startup/Shutdown','Shutting down','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Waiting','No or bad raw material','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Waiting','No Personnel/Operator','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Downtime_Cause','Waiting','No approval to  proceed','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Lab','Failed lab test','Process as alternate product','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Lab','Failed lab test','Destroy','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Lab','Failed lab test','Recyle','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Lab','Failed lab test','Recyle some & destroy some','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Lab','Lab Test sample','Hold for testing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Failed field instrument test','Process as alternate product','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Failed field instrument test','Destroy','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Failed field instrument test','Recyle','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Failed field instrument test','Recyle some & destroy some','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Loss caused by equipment','Breakage, bad fitment, jam','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Cutting losses','Destroy','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Cutting losses','Recyle','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Material handling loss','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Process','Inventory reconciliation','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Inspection','Failed operator test','Destroy','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Inspection','Failed operator test','Recyle','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Inspection','Failed operator test','Recyle some & destroy some','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Inspection','Failed operator test','Process as alternate product','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Inspection','Operator test sample','Hold for testing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Customer','Customer return','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Waste_Cause','Customer','Warehouse return','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Maintenance','Shift Report','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Maintenance','Oral','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Maintenance','Written','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Production Team','Shift Report','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Production Team','Oral','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Production Team','Written','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Supervisor','Oral','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Alerted Supervisor','Written','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Calibrated equipment','','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Adjusted Operating procedure','','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Increased crew count','','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Asked for help','Operations','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Asked for help','Maintenance','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Asked for help','Engineering','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','No action required','','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Increased Speed','','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Recommended changes','Shift Report','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Recommended changes','Oral','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Recommended changes','Written','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Requested additional  training','Oral','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Action','Requested additional  training','Written','','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Colour','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Density','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Dirt','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Height','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Length','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','ph','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Taste','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Temperature ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Weight','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Width','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Warning ','Tensile strength','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Colour','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Density','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Dirt','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Height','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Length','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','ph','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Taste','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Temperature ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Weight','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Width','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Laboratory Test','Quality Reject','Tensile strength','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Field instrument ','Quality Warning ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Field instrument ','Quality Reject','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Field instrument ','Failed instrument','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Field instrument ','Instrument maintenance alert','Failing instrument','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Raw Materials','Field instrument ','Instrument maintenance advisory','Suspect instrument problem','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Power Supply','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Operator Rotation','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Shift Difference','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Seasonal Effect','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Fatigue','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Maintenance Schedules','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Change of guages','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Change of sampling ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Sudden Shift','Component irregularity','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Cycles','Warm up ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Cycles','Warm down','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Freaks or Outliers','Omitted operation','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Freaks or Outliers','Broken part or tool','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Freaks or Outliers','Damage','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Freaks or Outliers','Variation in sample size','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Freaks or Outliers','Measurement error','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Drifts or Trends','Tool Wear','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Drifts or Trends','Bath depletion','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Drifts or Trends','Fatigue','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Drifts or Trends','Temperature change','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Drifts or Trends','Gradual loosening','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Drifts or Trends','Contamination drift','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Bunching or Clusters','Change in Material','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Bunching or Clusters','Change in Calibration','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Bunching or Clusters','Change in Inspector','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Bunching or Clusters','Change in Classification technique','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Mixture','Two or more different processes','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Mixture','Mixture of different quality material','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Mixture','Data from different conditions','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Mixture','Different lots or suppliers','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Mixture','Non-Random Sampling','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Mixture','Inconsistent Screening','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Unstable','Over-Adjustment','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Unstable','Erratic test equipment','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Unstable','Mixed lots of  material','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Unstable','Untrained personnel','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Unstable','Variation in sample size maintenance','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Stratified','Non-Random Sampling','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Stratified','Screening ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Stratified','Control limits not updated','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Stratified','Deception','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','It is out of control','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','8 consec pts not within +/- 1 sigma','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','4 of 5 consec pts > 1 sigma on same side of mean','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','Consistent increases/decreases','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','12 of 14 consec pts on same side of mean','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','9 of 10 pts on same side of mean','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','7 consec pts above or below mean','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','2 of 3 pts between 2 and 3 sigma on same side','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','SPC - Out of Control','1 pt outside of control limits','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Power Supply','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Operator Rotation','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Shift Difference','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Seasonal Effect','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Fatigue','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Maintenance Schedules','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Change of guages','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Change of sampling ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Sudden Shift','Component irregularity','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Cycles','Warm up ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Cycles','Warm down','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Freaks or Outliers','Omitted operation','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Freaks or Outliers','Broken part or tool','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Freaks or Outliers','Damage','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Freaks or Outliers','Variation in sample size','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Freaks or Outliers','Measurement error','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Drifts or Trends','Tool Wear','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Drifts or Trends','Bath depletion','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Drifts or Trends','Fatigue','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Drifts or Trends','Temperature change','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Drifts or Trends','Gradual loosening','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Drifts or Trends','Contamination drift','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Bunching or Clusters','Change in Material','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Bunching or Clusters','Change in Calibration','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Bunching or Clusters','Change in Inspector','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Bunching or Clusters','Change in Classification technique','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Mixture','Two or more different processes','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Mixture','Mixture of different quality material','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Mixture','Data from different conditions','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Mixture','Different lots or suppliers','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Mixture','Non-Random Sampling','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Mixture','Inconsistent Screening','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Unstable','Over-Adjustment','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Unstable','Erratic test equipment','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Unstable','Mixed lots of  material','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Unstable','Untrained personnel','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Unstable','Variation in sample size maintenance','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Stratified','Non-Random Sampling','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Stratified','Screening ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Stratified','Control limits not updated','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Stratified','Deception','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n Points > Each Other (Consecutive)','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n Points < Each Other (Consecutive)','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points > URL','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points < LRL','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points > Target','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points < Target','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points < LCL','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points > UCL','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points > Control Target','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','SPC - Out of Control','n out of m points < Control Target','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Colour','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Density','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Dirt','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Height','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Length','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','ph','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Taste','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Temperature ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Weight','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Width','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Warning ','Tensile strength','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Colour','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Density','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Dirt','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Height','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Length','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','ph','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Taste','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Temperature ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Weight','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Width','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Laboratory Test','Quality Reject','Tensile strength','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Field instrument ','Quality Warning ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Field instrument ','Quality Reject','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Field instrument ','Failed instrument','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Field instrument ','Instrument maintenance alert','Failing instrument','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Field instrument ','Instrument maintenance advisory','Suspect instrument problem','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Lots of Adjustments','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Lots of Waiting','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Machine Failures','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Personnel Absent','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Product ChangeOver','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Shutting Down','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Startup Problems','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Availability Rate','Target rates need reviewing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','Planned Maintenance','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','Planned Engineering','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','No orders','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','No raw materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','Crew shortage','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','No Utilities','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','Act of God','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Not scheduled','Plant Closed','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Unit or Line Restraints','Upstream','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Unit or Line Restraints','Downstream','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Process Problem','Failures at high speed','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Process Problem','Waiting on Downstream Process ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Process Problem','Waiting on Upstream Process ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Low Crew Count ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Safety','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Speed limited by current Product','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Lots of Minor Stops','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Performance Rate','Target rates need reviewing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Quality Rate','Bad raw materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Quality Rate','Machine needs adjustment','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Quality Rate','Can''t produce to spec','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Quality Rate','Speed causes low quality','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Quality Rate','Data entry timing issue','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','Quality Rate','Target rates need reviewing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','OEE Rate','Availability is low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','OEE Rate','Performance is low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','OEE Rate','Qualtiy is low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Process','OEE Rate','Two or more metrics are low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Lots of Adjustments','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Lots of Waiting','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Machine Failures','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Personnel Absent','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Product ChangeOver','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Shutting Down','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Startup Problems','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Availability Rate','Target rates need reviewing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','Planned Maintenance','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','Planned Engineering','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','No orders','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','No raw materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','Crew shortage','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','No Utilities','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','Act of God','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Not scheduled','Plant Closed','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Unit or Line Restraints','Upstream','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Unit or Line Restraints','Downstream','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Process Problem','Failures at high speed','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Process Problem','Waiting on Downstream Process ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Process Problem','Waiting on Upstream Process ','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Low Crew Count ','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Safety','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Speed limited by current Product','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Lots of Minor Stops','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Performance Rate','Target rates need reviewing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Quality Rate','Bad raw materials','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Quality Rate','Machine needs adjustment','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Quality Rate','Can''t produce to spec','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Quality Rate','Speed causes low quality','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Quality Rate','Data entry timing issue','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','Quality Rate','Target rates need reviewing','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','OEE Rate','Availability is low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','OEE Rate','Performance is low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','OEE Rate','Qualtiy is low','','1',1
 	  	 Execute spEM_IEImportEventReasonTree 'Sample_Alarm_Cause','Packaging','OEE Rate','Two or more metrics are low','','1',1
 	  	 
 	  	 /* Add Categories */ 
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unscheduled Time','Force Majeure (Acts of God)','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unscheduled Time','No Resources','Personnel','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unscheduled Time','No Resources','Materials','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unscheduled Time','No Orders','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unscheduled Time','Other','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Not Scheduled','Plant is closed','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Electrical','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Engineering','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Mechanical','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Operations','','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Electrical','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Engineering','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Mechanical','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Planned Downtime','Major Maintenance','Operations','','Unavailable Time',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unit Restraint','Starved','','','Outside Area',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Unit Restraint','Blocked','','','Outside Area',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Machine Jam','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','No raw materials','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop for required adjustment ','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop for Quality','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Slow down time','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop required for Lubrication','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Operator Assist','Stop required for Overheating','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Major Component Failure','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Part(s) failure','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Adjustment required','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Operating procedure advice','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Stop required for Overheating','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Machine Failures','Maintenance Assist','Lubrication','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Machine Jam','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','No raw materials','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop for required adjustment ','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop for Quality','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Slow down time','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop required for Lubrication','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Minor Stops','Operator Assist','Stop required for Overheating','','Performance Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Setup & Adjustments','Product Change','CIP','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Setup & Adjustments','Product Change','Configuration','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Setup & Adjustments','Quality Change','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Setup & Adjustments','Adjustments required','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Setup & Adjustments','Shift Maintenance/Daily cleaning','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Startup/Shutdown','Ramping Up','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Startup/Shutdown','Shutting down','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Waiting','No or bad raw material','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Waiting','No Personnel/Operator','','','Unplanned Downtime',1
 	  	 Execute spEM_IEImportReasonCategory 'Sample_Downtime_Cause','Waiting','No approval to  proceed','','','Unplanned Downtime',1
 	 End
If (Select Count(*) from event_subtypes) = 0
 	 Begin
 	  	 Declare @CommentId Int
 	  	 Insert into comments(comment,CS_Id,User_id,Modified_On) Select 'Batch',1,1,Getdate()
 	  	 Select @CommentId = Scope_Identity()
 	  	 Insert into event_subtypes(Event_Subtype_Desc,Cause_Required, Action_Required,Ack_Required,Duration_Required,
 	  	  	  	 Dimension_Y_Enabled,Dimension_Z_Enabled,Dimension_A_Enabled,
 	  	  	    ET_Id,Event_Mask,Dimension_X_Name,Dimension_Y_Name,Dimension_Z_Name,Dimension_A_Name,
            Dimension_X_Eng_Units,Dimension_Y_Eng_Units,Dimension_Z_Eng_Units,Dimension_A_Eng_Units,Comment_Id)
 	  	 Values ('Batch',0,0,0,0,0,0,0,1,'','Weight',Null,Null,Null,'Kg',Null,Null,Null,@CommentId)
 	  	 Insert into comments(comment,CS_Id,User_id,Modified_On) Select 'lot',1,1,Getdate()
 	  	 Select @CommentId = Scope_Identity()
 	  	 Insert into event_subtypes(Event_Subtype_Desc,Cause_Required, Action_Required,Ack_Required,Duration_Required,
 	  	  	  	 Dimension_Y_Enabled,Dimension_Z_Enabled,Dimension_A_Enabled,
 	  	  	    ET_Id,Event_Mask,Dimension_X_Name,Dimension_Y_Name,Dimension_Z_Name,Dimension_A_Name,
            Dimension_X_Eng_Units,Dimension_Y_Eng_Units,Dimension_Z_Eng_Units,Dimension_A_Eng_Units,Comment_Id)
 	  	 Values ('Lot',0,0,0,0,0,0,0,1,'','Count',Null,Null,Null,'#',Null,Null,Null,@CommentId)
 	  	 Insert into comments(comment,CS_Id,User_id,Modified_On) Select 'Reel',1,1,Getdate()
 	  	 Select @CommentId = Scope_Identity()
 	  	 Insert into event_subtypes(Event_Subtype_Desc,Cause_Required, Action_Required,Ack_Required,Duration_Required,
 	  	  	  	 Dimension_Y_Enabled,Dimension_Z_Enabled,Dimension_A_Enabled,
 	  	  	    ET_Id,Event_Mask,Dimension_X_Name,Dimension_Y_Name,Dimension_Z_Name,Dimension_A_Name,
            Dimension_X_Eng_Units,Dimension_Y_Eng_Units,Dimension_Z_Eng_Units,Dimension_A_Eng_Units,Comment_Id)
 	  	 Values ('Reel',0,0,0,0,1,1,1,1,'','Weight','Length','Width','Diameter','Kg','meters','cm','cm',@CommentId)
 	  	 Insert into comments(comment,CS_Id,User_id,Modified_On) Select 'Roll',1,1,Getdate()
 	  	 Select @CommentId = Scope_Identity()
 	  	 Insert into event_subtypes(Event_Subtype_Desc,Cause_Required, Action_Required,Ack_Required,Duration_Required,
 	  	  	  	 Dimension_Y_Enabled,Dimension_Z_Enabled,Dimension_A_Enabled,
 	  	  	    ET_Id,Event_Mask,Dimension_X_Name,Dimension_Y_Name,Dimension_Z_Name,Dimension_A_Name,
            Dimension_X_Eng_Units,Dimension_Y_Eng_Units,Dimension_Z_Eng_Units,Dimension_A_Eng_Units,Comment_Id)
 	  	 Values ('Roll',0,0,0,0,1,1,1,1,'','Weight','Length','Width','Diameter','Kg','meters','cm','cm',@CommentId)
 	 End
Set nocount off

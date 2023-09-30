Create Procedure dbo.spcmn_UnitStatistics
    @Language_Id int,
 	 @DecimalSep     nvarchar(2) = '.'
  AS
set nocount on
Declare @mnuDesc nvarchar(100),@FormCaption nvarchar(100)
Create Table #Details ( 	 mnuName nvarchar(50),
 	  	  	  	  	  	 IsCommand tinyInt,
 	  	  	  	  	  	 mnuDesc nvarchar(100),
 	  	  	  	  	  	 IsEnabled TinyInt,
 	  	  	  	  	  	 HasState TinyInt,
 	  	  	  	  	  	 ToolType TinyInt,
 	  	  	  	  	  	 ToolOrder TinyInt,
 	  	  	  	  	  	 SpToRun nvarchar(50),
 	  	  	  	  	  	 Caption nvarchar(50),
 	  	  	  	  	  	 TaskId Int,
 	  	  	  	  	  	 NodeKey nvarchar(2),
 	  	  	  	  	  	 DateRangeId 	 Int,
 	  	  	  	  	  	 WebPage 	 nvarchar(100))
--*********************************************
/** Unit Details**/
--*********************************************
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24224 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28040 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewInventory',1,coalesce(@mnuDesc,'View Inventory Total Items'),1,0,1,1,'spCMN_InventoryReport',coalesce(@FormCaption,'Inventory Details'),0,'ja',30,'Inventory Listing')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24225 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28040 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewInventoryQuality',1,coalesce(@mnuDesc,'View Inventory Percent Good Items'),1,0,1,2,'spCMN_InventoryReport',coalesce(@FormCaption,'Inventory Details'),0,'jb',30,'Inventory Listing')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24226 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewAlarmCounts',1,coalesce(@mnuDesc,'View Alarm Counts'),1,0,1,3,'','',1,'',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24227 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28049 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductCode',1,coalesce(@mnuDesc,'View Product Code'),1,0,1,4,'spCMN_ProductChangeReport',coalesce(@FormCaption,'Product Change Details'),0,'jc',26,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24228 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28050 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProcessOrder',1,coalesce(@mnuDesc,'View Process Order'),0,0,1,5,'spCMN_ScheduleReport',coalesce(@FormCaption,'Schedule Details'),0,'jd',26,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24229 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionRate',1,coalesce(@mnuDesc,'View Unit Production Rate'),0,0,1,6,'spCMN_ProductionReport',coalesce(@FormCaption,'Production Details'),0,'je',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24230 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionAmount',1,coalesce(@mnuDesc,'View Unit Production Amount'),1,0,1,7,'spCMN_ProductionReport',coalesce(@FormCaption,'Production Details'),0,'jf',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24231 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionUnits',1,coalesce(@mnuDesc,'View Unit Production Total Items'),1,0,1,8,'spCMN_ProductionReport',coalesce(@FormCaption,'Production Details'),0,'jg',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24232 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionQuality',1,coalesce(@mnuDesc,'View Unit Production Good Items'),0,0,1,9,'spCMN_ProductionReport',coalesce(@FormCaption,'Production Details'),0,'jh',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24233 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28051 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewDowntimeMinutes',1,coalesce(@mnuDesc,'View Unit Downtime Minutes'),1,0,1,10,'spCMN_DowntimeReport',coalesce(@FormCaption,'Downtime Details'),0,'ji',30,'Downtime Analysis')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24234 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28051 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewDownEfficiency',1,coalesce(@mnuDesc,'View Unit Downtime Percent'),0,0,1,11,'spCMN_DowntimeReport',coalesce(@FormCaption,'Downtime Details'),0,'jj',30,'Downtime Analysis')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24235 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28052 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewWasteAmount',1,coalesce(@mnuDesc,'View Unit Waste Amount'),1,0,1,12,'spCMN_WasteReport',coalesce(@FormCaption,'Waste Details'),0,'jk',30,'Waste Analysis')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24236 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28052 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewWasteEfficiency',1,coalesce(@mnuDesc,'View Unit Waste Percent'),0,0,1,13,'spCMN_WasteReport',coalesce(@FormCaption,'Waste Details'),0,'jl',30,'Waste Analysis')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24237 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28053 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewOverallEfficiency',1,coalesce(@mnuDesc,'View Unit Efficiency Percent'),1,0,1,14,'spCMN_EfficiencyReport',coalesce(@FormCaption,'Efficiency Details'),0,'jm',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24238 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28053 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewPercentOfRate',1,coalesce(@mnuDesc,'View Unit Production Rate Percent'),1,0,1,15,'spCMN_EfficiencyReport',coalesce(@FormCaption,'Efficiency Details'),0,'jn',30,'')
--*********************************************
/** Inventory Details**/
--*********************************************
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24224 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28040 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewInventoryItemInv',1,coalesce(@mnuDesc,'View Inventory Total Items'),1,0,2,1,'spCMN_InventoryReport',coalesce(@FormCaption,'Inventory Details'),0,'jp',30,'Inventory Listing')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24225 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28040 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewInventoryQualityItemInv',1,coalesce(@mnuDesc,'View Inventory Percent Good Items'),1,0,2,2,'spCMN_InventoryReport',coalesce(@FormCaption,'Inventory Details'),0,'jq',30,'Inventory Listing')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24239 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28040 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewInventoryAmountInv',1,coalesce(@mnuDesc,'View Inventory Total Amount'),1,0,2,3,'spCMN_InventoryReport',coalesce(@FormCaption,'Inventory Details'),0,'jr',30,'Inventory Listing')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24240 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28040 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewInventoryQualityAmountInv',1,coalesce(@mnuDesc,'View Inventory Percent Good Amount'),1,0,2,4,'spCMN_InventoryReport',coalesce(@FormCaption,'Inventory Details'),0,'js',30,'Inventory Listing')
--*********************************************
/** Line Details**/
--*********************************************
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24241 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionRateLine',1,coalesce(@mnuDesc,'View Line Production Rate'),0,0,3,1,'','',0,'jt',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24242 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionAmountLine',1,coalesce(@mnuDesc,'View Line Production Amount'),1,0,3,2,'','',0,'ju',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24243 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionUnitsLine',1,coalesce(@mnuDesc,'View Line Production Total Items'),1,0,3,3,'','',0,'jv',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24244 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28038 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewProductionQualityLine',1,coalesce(@mnuDesc,'View Line Production Good Items'),0,0,3,4,'','',0,'jw',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24245 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28051 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewDowntimeMinutesLine',1,coalesce(@mnuDesc,'View Line Downtime Minutes'),1,0,3,5,'','',0,'jx',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24246 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28051 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewDownEfficiencyLine',1,coalesce(@mnuDesc,'View Line Downtime Percent'),0,0,3,6,'','',0,'jy',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24247 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28052 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewWasteAmountLine',1,coalesce(@mnuDesc,'View Line Waste Amount'),1,0,3,7,'','',0,'jz',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24248 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28052 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewWasteEfficiencyLine',1,coalesce(@mnuDesc,'View Line Waste Percent'),0,0,3,8,'','',0,'ka',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24249 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28053 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewOverallEfficiencyLine',1,coalesce(@mnuDesc,'View Line Efficiency Percent'),1,0,3,9,'','',0,'kb',30,'')
Select @mnuDesc =  Prompt_String from Language_Data ld Where Prompt_Number = 24250 and Language_Id = @Language_Id
Select @FormCaption =  Prompt_String from Language_Data ld Where Prompt_Number = 28053 and Language_Id = @Language_Id
Insert Into #Details (mnuName,IsCommand,mnuDesc,IsEnabled,HasState,ToolType,ToolOrder,SpToRun,Caption,TaskId,NodeKey,DateRangeId,WebPage)
 	 Values ('ViewPercentOfRateLine',1,coalesce(@mnuDesc,'View Line Production Rate Percent'),1,0,3,10,'','',0,'kc',30,'')
Select * From #Details Order by ToolType,ToolOrder
set nocount off

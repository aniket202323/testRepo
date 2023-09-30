CREATE Procedure dbo.spBF_AddDowntimeModels
 	  @ReturnStatus int = null OUTPUT
 	 ,@ReturnMessage nvarchar(255) = null OUTPUT
 	 ,@EConfig_Id Int = null
AS
/* Check to see if the automatic model s active) */
SET @ReturnStatus = 1
SET @ReturnMessage = ''
DECLARE  @Class nVarChar(50) = 'Downtime' 
DECLARE  @ClassName nVarChar(50) = 'STATE' 
DECLARE  @FaultClassName nVarChar(50) = 'FAULTSTATE'
DECLARE @Product_Family_Desc nVarChar(100)
DECLARE @SpecDesc nVarChar(100) = 'Rate'
DECLARE @ShiftInterval nVarChar(100) = '720'
DECLARE @ShiftOffset nVarChar(100) = '480'
DECLARE @DowntimeModelDesc nVarChar(100) = 'EfficiencyAnalyzer Faults Occur On Single Location'
DECLARE @WasteModelDesc nVarChar(100) = 'EfficiencyAnalyzer Waste Model'
DECLARE @ProductionModelDesc nVarChar(100) = 'EfficiencyAnalyzer Production Event Model'
DECLARE 	 @ProductChangeModelDesc nVarChar(100) = 'EfficiencyAnalyzer Product Change Model'
DECLARE @TreeName nVarChar(100) = 'Downtime'
DECLARE @WETName nVarChar(100) = 'Part'
Declare @EquipmentWithDowntimeTags Table (Id Int identity(1,1)
 	  	  	  	  	  	  	  	  	  	  	 ,EquipmentId UniqueIdentifier
 	  	  	  	  	  	  	  	  	  	  	 ,S95Id nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PAId Int
 	  	  	  	  	  	  	  	  	  	  	 ,HistorianRunning 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,HistorianFault 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,RunningTag nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,FaultTag nVarChar(100))
 	  	  	  	  	  	  	  	  	  	  	 
DECLARE @Start Int,@End Int,@ECId Int,@PuId INt,@RunningTag nVarChar(200),@FaultTag nVarChar(200)
DECLARE @HasDTModel INT,@HasPEModel Int,@HasWasteModel int
DECLARE @HistorianRun nVarChar(200),@HistorianFault nVarChar(200)
DECLARE @HistAliasName nvarchar(100), @HistId Int,@Counter Int
DECLARE @ECVDID Int
DECLARE @WETID Int
DECLARE @EDFieldId Int
DECLARE @UserId Int 
DECLARE @ReloadSetback DateTime
DECLARE @CommentId Int
DECLARE @PFId Int,@propId Int,@specid Int
DECLARE      @Extended_Info nvarchar(255)
             ,@External_Link nvarchar(255)
             ,@Equipment_Type nvarchar(50)
             ,@Sheet_Id Int
             ,@Production_Variable Int
             ,@Production_Rate_TimeUnits Int
             ,@Production_Rate_Specification Int
             ,@Production_Alarm_Interval Int
             ,@Production_Alarm_Window Int
             ,@Waste_Percent_Specification Int
             ,@Waste_Percent_Alarm_Interval Int
             ,@Waste_Percent_Alarm_Window Int
             ,@Downtime_Scheduled_Category Int
             ,@Downtime_External_Category Int
             ,@Downtime_Percent_Specification Int
             ,@Downtime_Percent_Alarm_Interval Int
             ,@Downtime_Percent_Alarm_Window Int
             ,@Efficiency_Calculation_Type Int
             ,@Efficiency_Variable Int
             ,@Efficiency_Percent_Specification Int
             ,@Efficiency_Percent_Alarm_Interval Int
             ,@Efficiency_Percent_Alarm_Window Int
             ,@Delete_Child_Events Int
             ,@Performance_Downtime_Category Int
             ,@Non_Productive_Category Int
             ,@Non_Productive_Reason_Tree Int
             ,@DefaultPathId Int
DECLARE @CurrentDecativatedPAUnits Table(Id Int Identity(1,1),PUId Int)
DECLARE @UnitsWithAutoConfigModels Table(Id Int Identity(1,1),PUId Int)
SELECT @ReloadSetback = dbo.fnServer_CmnConvertToDbTime(GETUTCDATE(),'UTC')
set @ReloadSetback = dateadd(hour,-datepart(hour,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(minute,-datepart(minute,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(second,-datepart(second,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(millisecond,-datepart(millisecond,@ReloadSetback),@ReloadSetback)
SET @UserId = 1
DECLARE @CheckTable table(id int,msg nvarchar(max))
SELECT @ECId = ec_Id FROM Event_Configuration WHERE ED_Model_Id = 49100
IF @ECId Is Null
BEGIN
 	 EXECUTE spEMEC_CreateNewEC   0,1,'EfficiencyAnalyzer Auto Model',7,null,@UserId,@ECId output,@CommentId Output
 	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,49100,@UserId
 	 EXECUTE spEMSEC_PutECData   2882,@ECId, 0,'TINT:1', 1,Null,@UserId,null
 	 EXECUTE spEMSEC_PutECData  2883,@ECId,0,'spBF_AddDownTimeModels',1,Null,@UserId,Null
 	 EXECUTE spEMEC_UpdateIsActive  @ECId,1,@UserId
 	 EXECUTE spEM_ReloadService   4,@ReloadSetback,2, @UserId,NULL
 	 /* Shift Offset */
 	 EXECUTE spEMPE_EditParameters    1,0,16,'',@UserId,@ShiftInterval,null,Null
 	 EXECUTE spEMPE_EditParameters    1,0,17,'',@UserId,@ShiftOffset,null,Null
 	 SELECT @WetId = WET_ID FROM Waste_Event_Type WHERE WET_Name = @WETName
 	 IF @WetId Is Null
 	  	 EXECUTE spEMEC_UpdateWasteTypes    null,@WETName,1,@UserId
END
EXECUTE dbo.spBF_AddWasteModels
EXECUTE dbo.spBF_AddProductChangeModels
EXECUTE dbo.spBF_AddProductionModels
Insert into @EquipmentWithDowntimeTags(EquipmentId,S95Id,PaId,RunningTag,HistorianRunning)
 SELECT  a.EquipmentId,b.S95Id,c.PU_Id,
 	   SUBSTRING( d.Name,CHARINDEX('.',d.name)+1,LEN(d.name)),
 	   SUBSTRING( d.Name,1,CHARINDEX('.',d.name)-1)
 	 
 from Property_Equipment_EquipmentClass  a
 Join Equipment b on b.EquipmentId = a.EquipmentId
 Left Join PAEquipment_Aspect_SOAEquipment c on c.Origin1EquipmentId = b.EquipmentId
 Left Join BinaryItem d on d.ItemId = a.ItemId 
 where Class = @Class and a.ItemId is not null and a.Name = @ClassName
SELECT @End = @@ROWCOUNT 
UPDATE  @EquipmentWithDowntimeTags SET FaultTag =  SUBSTRING( e.Name,CHARINDEX('.',e.name)+1,LEN(e.name)),
 	  	  	  	 HistorianFault = SUBSTRING( e.Name,1,CHARINDEX('.',e.name)-1)
 	 FROM @EquipmentWithDowntimeTags a
 	 Join Property_Equipment_EquipmentClass  b on a.EquipmentId = b.EquipmentId
 	 Left Join BinaryItem e on e.ItemId = b.ItemId 
 where b.Class = @Class and b.ItemId is not null and b.Name = @FaultClassName
SET  @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = PaId,
 	  	  	 @RunningTag = RunningTag,
 	  	  	 @FaultTag = Coalesce(FaultTag,RunningTag),
 	  	  	 @HistorianRun = HistorianRunning,
 	  	  	 @HistorianFault = Coalesce(HistorianFault,HistorianRunning)
 	  	 FROM @EquipmentWithDowntimeTags WHERE id =  @Start
      EXECUTE spBF_GetProdFamilyId @PUId,@UserId,@PFId Output,@SpecId Output
/*  Waste */
 	 SET @HasWasteModel = NULL
 	 SELECT @HasWasteModel =  ec_id  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 3
 	 IF @HasWasteModel Is Null 
 	 BEGIN
 	  	 EXECUTE spEMEC_CreateNewEC @PuId, 0,@WasteModelDesc, 3,null,@UserId,@ECId output,@CommentId Output
 	  	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,304,@UserId
 	 END
/*  Production */
 	 SET @HasPEModel = NULL
 	 SELECT @HasPEModel =  ec_id  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 1
 	 IF @HasPEModel Is Null 
 	 BEGIN
 	  	 EXECUTE spEMEC_CreateNewEC @PuId, 0,@ProductionModelDesc, 1,2,@UserId,@ECId output,@CommentId Output
 	  	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,800,@UserId
 	 END
 	 /*  Downtime */
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @HistorianRun,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @RunningTag = 'PT:\\' + @HistAliasName + '\' +  @RunningTag
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @HistorianFault,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @FaultTag = 'PT:\\' + @HistAliasName + '\' +  @FaultTag
 	 SET @HasDTModel = NULL
 	 SELECT @HasDTModel =  ec_id  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 2
 	 IF @HasDTModel Is Null and @FaultTag is not Null and @RunningTag is not Null
 	 BEGIN /* Add Downtime */
 	  	 EXECUTE spBF_CreateModel210  @PUId, @TreeName,  @UserId, @RunningTag, Null, @FaultTag, Null,@ECId OUTPUT
 	  	 Insert Into @CheckTable(id,msg) 	 EXECUTE spEMSEC_ActiveCheck  @ECId,@UserId
 	  	 IF (SELECT COUNT(*) FROM @CheckTable) != 0
 	  	 BEGIN
 	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	  	 END
 	  	 ELSE
 	  	 BEGIN /* Add Downtime Success */
 	  	  	 EXECUTE spEMEC_UpdateIsActive @ECId, 1,@UserId
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,3,@UserId,NULL 
 	  	  	 /******** Set Unit Properties  ********* */
 	  	  	 SELECT @Extended_Info = a.Extended_Info 
 	  	  	  	  	  ,@External_Link = a.External_Link
 	  	  	  	  	  ,@Equipment_Type = a.Equipment_Type 
 	  	  	  	  	  ,@Sheet_Id = a.Sheet_Id 
 	  	  	  	  	  ,@Production_Variable = a.Production_Variable 
 	  	  	  	  	  ,@Production_Alarm_Interval = a.Production_Alarm_Interval 
 	  	  	  	  	  ,@Production_Alarm_Window = a.Production_Alarm_Window 
 	  	  	  	  	  ,@Waste_Percent_Specification = a.Waste_Percent_Specification 
 	  	  	  	  	  ,@Waste_Percent_Alarm_Interval = a.Waste_Percent_Alarm_Interval 
 	  	  	  	  	  ,@Waste_Percent_Alarm_Window = a.Waste_Percent_Alarm_Window 
 	  	  	  	  	  ,@Downtime_Percent_Specification = a.Downtime_Percent_Specification 
 	  	  	  	  	  ,@Downtime_Percent_Alarm_Interval = a.Downtime_Percent_Alarm_Interval 
 	  	  	  	  	  ,@Downtime_Percent_Alarm_Window = a.Downtime_Percent_Alarm_Window
 	  	  	  	  	  ,@Efficiency_Variable = a.Efficiency_Variable 
 	  	  	  	  	  ,@Efficiency_Percent_Specification = a.Efficiency_Percent_Specification 
 	  	  	  	  	  ,@Efficiency_Percent_Alarm_Interval = a.Efficiency_Percent_Alarm_Interval 
 	  	  	  	  	  ,@Efficiency_Percent_Alarm_Window = a.Efficiency_Percent_Alarm_Window 
 	  	  	  	  	  ,@Non_Productive_Category = a.Non_Productive_Category
 	  	  	  	  	  ,@Non_Productive_Reason_Tree = a.Non_Productive_Reason_Tree
 	  	  	  	  	  ,@DefaultPathId = a.Default_Path_Id 
 	  	  	  	  	  ,@Efficiency_Calculation_Type = coalesce(a.Efficiency_Calculation_Type,0)
 	  	  	  	  	  ,@Production_Rate_TimeUnits = coalesce(a.Production_Rate_TimeUnits,3) 
 	  	  	  	  	  ,@Production_Rate_Specification = @specid
 	  	  	  	  	  ,@Downtime_Scheduled_Category = coalesce(a.Downtime_Scheduled_Category,3)
 	  	  	  	  	  ,@Downtime_External_Category = coalesce(a.Downtime_External_Category,1)
 	  	  	  	  	  ,@Delete_Child_Events = coalesce(a.Delete_Child_Events,0)
 	  	  	  	  	  ,@Performance_Downtime_Category = coalesce(a.Performance_Downtime_Category,6)
 	  	  	  FROM  Prod_units a
 	  	  	  WHERE PU_Id = @PuId
 	  	  
 	  	  	 EXECUTE spEMUP_PutUnitProperties 
 	  	  	  	  	   @Tab = 3
 	  	  	  	  	  ,@PU_Id = @PuId
 	  	  	  	  	  ,@Extended_Info = @Extended_Info
 	  	  	  	  	  ,@External_Link = @External_Link
 	  	  	  	  	  ,@Unit_Type_Id = 1
 	  	  	  	  	  ,@Equipment_Type = @Equipment_Type
 	  	  	  	  	  ,@Sheet_Id = @Sheet_Id
 	  	  	  	  	  ,@Production_Type = 0
 	  	  	  	  	  ,@Production_Variable = @Production_Variable 
 	  	  	  	  	  ,@Production_Rate_TimeUnits = @Production_Rate_TimeUnits
 	  	  	  	  	  ,@Production_Rate_Specification = @Production_Rate_Specification
 	  	  	  	  	  ,@Production_Alarm_Interval = @Production_Alarm_Interval
 	  	  	  	  	  ,@Production_Alarm_Window = @Production_Alarm_Window
 	  	  	  	  	  ,@Waste_Percent_Specification = @Waste_Percent_Specification
 	  	  	  	  	  ,@Waste_Percent_Alarm_Interval = @Waste_Percent_Alarm_Interval
 	  	  	  	  	  ,@Waste_Percent_Alarm_Window = @Waste_Percent_Alarm_Window
 	  	  	  	  	  ,@Downtime_Scheduled_Category = @Downtime_Scheduled_Category
 	  	  	  	  	  ,@Downtime_External_Category = @Downtime_External_Category
 	  	  	  	  	  ,@Downtime_Percent_Specification = @Downtime_Percent_Specification
 	  	  	  	  	  ,@Downtime_Percent_Alarm_Interval = @Downtime_Percent_Alarm_Interval
 	  	  	  	  	  ,@Downtime_Percent_Alarm_Window = @Downtime_Percent_Alarm_Window
 	  	  	  	  	  ,@Efficiency_Calculation_Type = @Efficiency_Calculation_Type
 	  	  	  	  	  ,@Efficiency_Variable = @Efficiency_Variable
 	  	  	  	  	  ,@Efficiency_Percent_Specification = @Efficiency_Percent_Specification
 	  	  	  	  	  ,@Efficiency_Percent_Alarm_Interval = @Efficiency_Percent_Alarm_Interval
 	  	  	  	  	  ,@Efficiency_Percent_Alarm_Window = @Efficiency_Percent_Alarm_Window
 	  	  	  	  	  ,@Delete_Child_Events = @Delete_Child_Events
 	  	  	  	  	  ,@User_Id = @UserId 
 	  	  	  	  	  ,@Performance_Downtime_Category = @Performance_Downtime_Category
 	  	  	  	  	  ,@OldParm = null
 	  	  	  	  	  ,@Non_Productive_Category = @Non_Productive_Category
 	  	  	  	  	  ,@Non_Productive_Reason_Tree = @Non_Productive_Reason_Tree
 	  	  	  	  	  ,@DefaultPathId = @DefaultPathId
 	  	 END
 	 END
 	 IF @HasDTModel IS NOT NULL And @FaultTag is not Null and @RunningTag is not Null /* Tag Changed  Update*/
 	 BEGIN
 	  	 SET @ECVDID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 30 and Field_Order = 2
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasDTModel and b.ED_Field_Id = @EDFieldId and Alias = 'RUNTAG') <> @RunningTag
 	  	 BEGIN
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasDTModel and ED_Field_Id = @EDFieldId and  Alias = 'RUNTAG'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasDTModel,@PUID,'RUNTAG',1,@RunningTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID output
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	  	 SET @ECVDID = Null 
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasDTModel and b.ED_Field_Id = @EDFieldId and Alias = 'FAULTTAG') <> @FaultTag
 	  	 BEGIN
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasDTModel and ED_Field_Id = @EDFieldId and  Alias = 'FAULTTAG'
 	  	  	 EXECUTE spEMSEC_PutInputData @HasDTModel,@PUID,'FAULTTAG',1,@FaultTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID output
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	 END
 	 SET @Start = @Start + 1
END
/**** Cleanup removed Bad config****/
INSERT INTO @CurrentDecativatedPAUnits(PUId)
 	 SELECT pu_Id From Event_Configuration a WHERE a.EC_Desc = @DowntimeModelDesc
 	 and PU_Id not in (SELECT PaId FROM @EquipmentWithDowntimeTags WHERE RunningTag Is Not Null)
SELECT @End = @@ROWCOUNT 
SET @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = puId
 	  	 FROM @CurrentDecativatedPAUnits  WHERE id =  @Start
 	 SET @ECId = Null
 	 SELECT @ECId = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @DowntimeModelDesc
 	 IF @ECId Is Not Null
  	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	 SET @Start = @Start + 1
END
/* set model Priorities */
DECLARE @PEventEC_Id Int
DECLARE @PCEC_Id Int
DECLARE @WasteEC_Id 	 Int
DECLARE @DownEC_Id 	 Int
INSERT INTO @UnitsWithAutoConfigModels(PUId)
 	 SELECT Distinct pu_Id From Event_Configuration a WHERE a.EC_Desc in(@DowntimeModelDesc,@WasteModelDesc,@ProductionModelDesc)
SELECT @End = @@ROWCOUNT 
SET @Start = 1
WHILE @Start <= @End
BEGIN
 	 SET @DownEC_Id = Null 	 
 	 SET @WasteEC_Id = Null 	 
 	 SET @PEventEC_Id = Null
 	 SET @PCEC_Id = Null
 	 SET @PuId = Null
 	 SELECT 	 @PuId = puId FROM @UnitsWithAutoConfigModels  WHERE id =  @Start
 	 SELECT @DownEC_Id = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @DowntimeModelDesc and Is_Active = 1
 	 SELECT @WasteEC_Id = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @WasteModelDesc and Is_Active = 1
 	 SELECT @PEventEC_Id = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @ProductionModelDesc and Is_Active = 1
 	 SELECT @PCEC_Id = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @ProductChangeModelDesc and Is_Active = 1
 	 IF @DownEC_Id Is Not Null and @PEventEC_Id Is Null
 	  	 UPDATE Prod_Units_Base Set Chain_Start_Time = 0,Uses_Start_Time = 1 WHERE pu_Id = @PuId and (Chain_Start_Time != 0 or Uses_Start_Time != 1)
 	 IF @PCEC_Id IS Not NULL
 	 BEGIN 
 	  	 IF Not EXISTS(SELECT 1 FROM Event_Configuration WHERE EC_Id = @PCEC_Id and Priority = 1)
 	  	 BEGIN
 	  	  	 UPDATE Event_Configuration SET  Priority = 1 WHERE EC_Id = @PCEC_Id
 	  	 END
 	 END
 	 IF @PEventEC_Id IS Not NULL
 	 BEGIN 
 	  	 UPDATE Prod_Units_Base Set Chain_Start_Time = 1,Uses_Start_Time = 1 WHERE pu_Id = @PuId and (Chain_Start_Time != 1 or Uses_Start_Time != 1)
 	  	 IF Not EXISTS(SELECT 1 FROM Event_Configuration WHERE EC_Id = @PEventEC_Id and Priority = 2)
 	  	 BEGIN
 	  	  	 UPDATE Event_Configuration SET  Priority = 2 WHERE EC_Id = @PEventEC_Id
 	  	 END
 	 END
 	 IF @WasteEC_Id IS Not NULL
 	 BEGIN 
 	  	 IF Not EXISTS(SELECT 1 FROM Event_Configuration WHERE EC_Id = @WasteEC_Id and Priority = 3)
 	  	 BEGIN
 	  	  	 UPDATE Event_Configuration SET  Priority = 3 WHERE EC_Id = @WasteEC_Id
 	  	 END
 	 END
 	 IF @DownEC_Id IS Not NULL
 	 BEGIN 
 	  	 IF Not EXISTS(SELECT 1 FROM Event_Configuration WHERE EC_Id = @DownEC_Id and Priority = 4)
 	  	 BEGIN
 	  	  	 UPDATE Event_Configuration SET  Priority = 4 WHERE EC_Id = @DownEC_Id
 	  	 END
 	 END
 	 SET @Start = @Start + 1
END

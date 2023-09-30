CREATE Procedure dbo.spBF_AddWasteModels
AS
DECLARE  @Class nVarChar(50) = 'Downtime' 
DECLARE  @WasteClassName nVarChar(50) = 'WASTEAMOUNT' 
DECLARE @WasteModelDesc nVarChar(100) = 'EfficiencyAnalyzer Waste Model'
DECLARE @TreeName nVarChar(100) = 'Sample_Waste_Cause'
DECLARE @TreeId Int
DECLARE @WETName nVarChar(100) = 'Part'
Declare @EquipmentWithWasteTags Table (Id Int identity(1,1)
 	  	  	  	  	  	  	  	  	  	  	 ,EquipmentId UniqueIdentifier
 	  	  	  	  	  	  	  	  	  	  	 ,S95Id nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PAId Int
 	  	  	  	  	  	  	  	  	  	  	 ,Historian 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,WasteTag nVarChar(100))
 	  	  	  	  	  	  	  	  	  	  	 
DECLARE @Start Int,@End Int,@ECId Int,@PuId INt,@WasteTag nVarChar(200)
DECLARE @HasWasteModel int
DECLARE @Historian nVarChar(200)
DECLARE @HistAliasName nvarchar(100), @HistId Int,@Counter Int
DECLARE @ECVDID Int
DECLARE @ECVID Int
DECLARE @WETID Int
DECLARE @EDFieldId Int
DECLARE @UserId Int 
DECLARE @ReloadSetback DateTime
DECLARE @CommentId Int
DECLARE @IsActive Int 
DECLARE @LocationScript nVarChar(100)
SELECT @TreeId = Tree_Name_Id FROM Event_Reason_Tree WHERE Tree_Name = @TreeName
DECLARE @CurrentDecativatedPAUnits Table(Id Int Identity(1,1),PUId Int)
SELECT @ReloadSetback = dbo.fnServer_CmnConvertToDbTime(GETUTCDATE(),'UTC')
set @ReloadSetback = dateadd(hour,-datepart(hour,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(minute,-datepart(minute,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(second,-datepart(second,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(millisecond,-datepart(millisecond,@ReloadSetback),@ReloadSetback)
SET @UserId = 1
DECLARE @CheckTable table(id int,msg nvarchar(max))
Insert into @EquipmentWithWasteTags(EquipmentId,S95Id,PaId,WasteTag,Historian)
 SELECT  a.EquipmentId,b.S95Id,c.PU_Id,
 	   SUBSTRING( d.Name,CHARINDEX('.',d.name)+1,LEN(d.name)),
 	   SUBSTRING( d.Name,1,CHARINDEX('.',d.name)-1)
 from Property_Equipment_EquipmentClass  a
 Join Equipment b on b.EquipmentId = a.EquipmentId
 Left Join PAEquipment_Aspect_SOAEquipment c on c.Origin1EquipmentId = b.EquipmentId
 Left Join BinaryItem d on d.ItemId = a.ItemId 
 where Class = @Class and a.ItemId is not null and a.Name = @WasteClassName
SELECT @End = @@ROWCOUNT 
SET  @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = PaId,
 	  	  	 @WasteTag = WasteTag,
 	  	  	 @Historian = Historian
 	 FROM @EquipmentWithWasteTags WHERE id =  @Start
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @Historian,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @WasteTag = 'PT:\\' + @HistAliasName + '\' +  @WasteTag
 	 SET @HasWasteModel = NULL
 	 SELECT @HasWasteModel =  ec_id,@IsActive = Is_Active  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 3 and a.EC_Desc = @WasteModelDesc
 	 IF @HasWasteModel is not Null and @IsActive = 0  and @WasteTag is not Null
 	 BEGIN
 	  	 EXECUTE spEMEC_DELETEEC    @HasWasteModel,2,@UserId,0
 	  	 SET @HasWasteModel = Null
 	 END
 	 IF @HasWasteModel Is Null and @WasteTag is not Null
 	 BEGIN /* Add Waste */
 	  	 EXECUTE spEMEC_UpdateWasteMeas Null,'lb',1,Null,@PuId,@UserId
 	  	 IF NOT EXISTS(SELECT 1 FROM Prod_Events a WHERE a.Event_Type = 3 and a.PU_Id =  @PuId and a.Name_Id is not null)
 	  	 BEGIN
 	  	  	 EXECUTE spEMSEC_PutEventConfigInfo @PuId,3,@TreeId,null,0,2,@UserId /* Add a Tree*/
 	  	 END
 	  	 SELECT @CommentId = Null,@ECId = Null
 	  	 EXECUTE spEMEC_CreateNewEC @PuId, 0,@WasteModelDesc, 3,null,@UserId,@ECId output,@CommentId Output
 	  	 UPDATE Comments Set Comment_Text = 'Auto Created Based on DownTime Class attatchment'
 	  	  	 WHERE Comment_Id = @CommentId
 	  	 UPDATE Comments Set Comment = 'Auto Created Based on DownTime Class attatchment'
 	  	  	 WHERE Comment_Id = @CommentId
 	  	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,304,@UserId
 	  	 EXECUTE spEMSEC_PutECData    2822,@ECId,@PUID,'1',1,NULL,@UserId,@ECVID output  --Field_Order = 1
 	  	 SET @ECVDID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 2 --InputTags
 	  	 EXECUTE spEMSEC_PutInputData     @ECId,@PUID,'AMOUNTTAG',1,@WasteTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 3 --AmountScript
 	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'Amount = AMOUNTTAG',1,NULL,@UserId,@ECVID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @LocationScript = 'Location = ' + Convert(nvarchar(10),@PUID)
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 4 --LocationScript
 	  	 EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,@LocationScript,1,NULL,@UserId,@ECVID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 5 --FaultScript
 	  	 EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'''Enter your fault script here.',1,NULL,@UserId,@ECVID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 6 --TypeScript
 	  	 EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'WasteType = "Part"',1,NULL,@UserId,@ECVID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 7 --MeasurementScript
 	  	 EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'Measure = "Lb"',1,NULL,@UserId,@ECVID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 8 --Automatically Add Missing Faults
 	  	 EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'0',1,NULL,@UserId,@ECVID output
 	  	 SET @ECVID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 9 --Value Change Only
 	  	 EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'0',1,NULL,@UserId,@ECVID output
 	  	 Insert Into @CheckTable(id,msg) 	 EXECUTE spEMSEC_ActiveCheck  @ECId,@UserId
 	  	 
 	  	 IF (SELECT COUNT(*) FROM @CheckTable) != 0
 	  	 BEGIN
 	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	  	  	 RETURN
 	  	 END
 	  	 ELSE
 	  	 BEGIN /* Add Waste Success */
 	  	  	 EXECUTE spEMEC_UpdateIsActive @ECId, 1,@UserId
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,3,@UserId,NULL 
 	  	 END
 	 END
 	 IF @HasWasteModel IS NOT NULL And @WasteTag is not Null /* Check Tag Changed  Update*/
 	 BEGIN
 	  	 SET @ECVDID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5401 and Field_Order = 2
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasWasteModel and b.ED_Field_Id = @EDFieldId and Alias = 'AMOUNTTAG') <> @WasteTag
 	  	 BEGIN
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasWasteModel and ED_Field_Id = @EDFieldId and  Alias = 'AMOUNTTAG'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasWasteModel,@PUID,'AMOUNTTAG',1,@WasteTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID output
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	 END
 	 SET @Start = @Start + 1
END
/**** Cleanup removed Bad config****/
INSERT INTO @CurrentDecativatedPAUnits(PUId)
 	 SELECT pu_Id From Event_Configuration a WHERE a.EC_Desc = @WasteModelDesc
 	 and PU_Id not in (SELECT PaId FROM @EquipmentWithWasteTags WHERE WasteTag Is Not Null)
SELECT @End = @@ROWCOUNT 
SET @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = puId
 	  	 FROM @CurrentDecativatedPAUnits  WHERE id =  @Start
 	 SET @ECId = Null
 	 SELECT @ECId = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @WasteModelDesc
 	 IF @ECId Is Not Null
  	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	 SET @Start = @Start + 1
END

CREATE Procedure dbo.spBF_AddProductionModels
AS
DECLARE 	 @Class nVarChar(50) = 'Downtime' 
DECLARE 	 @PartCountClassName nVarChar(50) = 'PRODAMOUNT' 
DECLARE 	 @SerialNumberClassName nVarChar(50) = 'PRODEVENTNUMBER' 
DECLARE 	 @TriggerClassName nVarChar(50) = 'PRODEVENTTRIGGER' 
DECLARE 	 @PartNumberClassName nVarChar(50) = 'PRODCODE' 
DECLARE 	 @ProductionEventChangeModelDesc nVarChar(100) = 'EfficiencyAnalyzer Production Event Model'
DECLARE @PFIdString  nvarchar(10)
DECLARE @PFId Int,   @specid Int 
Declare @EquipWithProductionEventTags Table (Id Int identity(1,1)
 	  	  	  	  	  	  	  	  	  	  	 ,EquipmentId UniqueIdentifier
 	  	  	  	  	  	  	  	  	  	  	 ,S95Id nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PAId Int
 	  	  	  	  	  	  	  	  	  	  	 ,PCHistorian 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PCTag nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PTHistorian 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PTTag nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,SNHistorian 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,SNTag nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PNHistorian 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PNTag nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 )
 	  	  	  	  	  	  	  	  	  	  	 
DECLARE @Start Int,@End Int,@ECId Int,@PuId INt,@NextStart Int
DECLARE @PCTag nVarChar(200)
DECLARE @PCHistorian nVarChar(200)
DECLARE @SNTag nVarChar(200)
DECLARE @SNHistorian nVarChar(200)
DECLARE @PNTag nVarChar(200)
DECLARE @PNHistorian nVarChar(200)
DECLARE @PTTag nVarChar(200)
DECLARE @PTHistorian nVarChar(200)
DECLARE @HasProductionEventChangeModel int
DECLARE @HistAliasName nvarchar(100), @HistId Int,@Counter Int
DECLARE @ECVDID Int
DECLARE @ECVID Int
DECLARE @WETID Int
DECLARE @EDFieldId Int
DECLARE @EDFieldId2 Int
DECLARE @UserId Int 
DECLARE @ReloadSetback DateTime
DECLARE @CommentId Int
DECLARE @IsActive Int
DECLARE @CurrentDecativatedPAUnits Table(Id Int Identity(1,1),PUId Int)
SELECT @ReloadSetback = dbo.fnServer_CmnConvertToDbTime(GETUTCDATE(),'UTC')
set @ReloadSetback = dateadd(hour,-datepart(hour,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(minute,-datepart(minute,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(second,-datepart(second,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(millisecond,-datepart(millisecond,@ReloadSetback),@ReloadSetback)
SET @UserId = 1
DECLARE @CheckTable table(id int,msg nvarchar(max))
Insert into @EquipWithProductionEventTags(EquipmentId,S95Id,PaId,PTTag,PTHistorian)
 SELECT  a.EquipmentId,b.S95Id,c.PU_Id,
 	   SUBSTRING( d.Name,CHARINDEX('.',d.name)+1,LEN(d.name)),
 	   SUBSTRING( d.Name,1,CHARINDEX('.',d.name)-1)
 from Property_Equipment_EquipmentClass  a
 Join Equipment b on b.EquipmentId = a.EquipmentId
 Left Join PAEquipment_Aspect_SOAEquipment c on c.Origin1EquipmentId = b.EquipmentId
 Left Join BinaryItem d on d.ItemId = a.ItemId 
 where Class = @Class and a.ItemId is not null and a.Name = @TriggerClassName
 UPDATE  @EquipWithProductionEventTags SET SNTag =  SUBSTRING( e.Name,CHARINDEX('.',e.name)+1,LEN(e.name)),
 	  	  	  	 SNHistorian = SUBSTRING( e.Name,1,CHARINDEX('.',e.name)-1)
 	 FROM @EquipWithProductionEventTags a
 	 Join Property_Equipment_EquipmentClass  b on a.EquipmentId = b.EquipmentId
 	 Left Join BinaryItem e on e.ItemId = b.ItemId 
 where b.Class = @Class and b.ItemId is not null and b.Name = @SerialNumberClassName
 UPDATE  @EquipWithProductionEventTags SET PNTag =  SUBSTRING( e.Name,CHARINDEX('.',e.name)+1,LEN(e.name)),
 	  	  	  	 PNHistorian = SUBSTRING( e.Name,1,CHARINDEX('.',e.name)-1)
 	 FROM @EquipWithProductionEventTags a
 	 Join Property_Equipment_EquipmentClass  b on a.EquipmentId = b.EquipmentId
 	 Left Join BinaryItem e on e.ItemId = b.ItemId 
 where b.Class = @Class and b.ItemId is not null and b.Name = @PartNumberClassName
 UPDATE  @EquipWithProductionEventTags SET PCTag =  SUBSTRING( e.Name,CHARINDEX('.',e.name)+1,LEN(e.name)),
 	  	  	  	 PCHistorian = SUBSTRING( e.Name,1,CHARINDEX('.',e.name)-1)
 	 FROM @EquipWithProductionEventTags a
 	 Join Property_Equipment_EquipmentClass  b on a.EquipmentId = b.EquipmentId
 	 Left Join BinaryItem e on e.ItemId = b.ItemId 
 where b.Class = @Class and b.ItemId is not null and b.Name = @PartCountClassName
DELETE FROM @EquipWithProductionEventTags WHERE PNTag is Null
DELETE FROM @EquipWithProductionEventTags WHERE PTTag is Null
DELETE FROM @EquipWithProductionEventTags WHERE SNTag is Null
SET @Start = 1
SET @End = 0
SELECT   @Start = MIN(Id),@End = MAX(Id)
 	  FROM @EquipWithProductionEventTags
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = PaId,
 	  	  	 @PCTag = PCTag,
 	  	  	 @PCHistorian = PCHistorian,
 	  	  	 @SNTag = SNTag,
 	  	  	 @SNHistorian = SNHistorian,
 	  	  	 @PTTag = PTTag,
 	  	  	 @PTHistorian = PTHistorian,
 	  	  	 @PNTag = PNTag,
 	  	  	 @PNHistorian = PNHistorian
 	 FROM @EquipWithProductionEventTags WHERE id =  @Start
 	 EXECUTE spBF_GetProdFamilyId @PUId,@UserId,@PFId Output,@specid Output 
 	 SET @PFIdString = Convert(nvarchar(10),@PFId)
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @PCHistorian,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @PCTag = 'PT:\\' + @HistAliasName + '\' +  @PCTag
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @SNHistorian,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @SNTag = 'PT:\\' + @HistAliasName + '\' +  @SNTag
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @PNHistorian,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @PNTag = 'PT:\\' + @HistAliasName + '\' +  @PNTag
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @PTHistorian,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @PTTag = 'PT:\\' + @HistAliasName + '\' +  @PTTag
 	 SELECT @HasProductionEventChangeModel = Null,@IsActive = Null
 	 SELECT @HasProductionEventChangeModel =  ec_id,@IsActive = Is_Active  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 1 and a.EC_Desc = @ProductionEventChangeModelDesc
 	 IF @HasProductionEventChangeModel is not Null and @IsActive = 0  and @PTTag is not Null
 	 BEGIN
 	  	 EXECUTE spEMEC_DELETEEC    @HasProductionEventChangeModel,2,@UserId,0
 	  	 SET @HasProductionEventChangeModel = Null
 	 END
 	 IF @HasProductionEventChangeModel Is Null and @PTTag is not Null
 	 BEGIN /* Add Product Event */
 	  	 SELECT @CommentId = Null,@ECId = Null
 	  	 EXECUTE spEMEC_CreateNewEC @PuId, 0,@ProductionEventChangeModelDesc, 1,2,@UserId,@ECId output,@CommentId Output
 	  	 UPDATE Comments Set Comment_Text = 'Auto Created Based on DownTime Class attatchment'
 	  	  	 WHERE Comment_Id = @CommentId
 	  	 UPDATE Comments Set Comment = 'Auto Created Based on DownTime Class attatchment'
 	  	  	 WHERE Comment_Id = @CommentId
 	  	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,800,@UserId
 	  	 EXECUTE spEMEC_UsesStartTime @PuId,@UserId,1,1
 	  	 SET @ECVDID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 1 --InputTags
 	  	 EXECUTE spEMSEC_PutInputData @ECId,@PUID,'EVENTTAG',1,@PTTag,2,12,0,0,@EDFieldId,@UserId,Null
 	  	 EXECUTE spEMSEC_PutInputData @ECId,@PUID,'PRODTAG',0,@PNTag,1,12,0,0,@EDFieldId,@UserId,Null
 	  	 IF @PCTag Is Not NUll 
 	  	  	 EXECUTE spEMSEC_PutInputData @ECId,@PUID,'DIMXTAG',0,@PCTag,1,12,0,0,@EDFieldId,@UserId,Null
 	  	 EXECUTE spEMSEC_PutInputData @ECId,@PUID,'A',0,@SNTag,1,12,0,0,@EDFieldId,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 3 --Define Event Number
 	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'EventNum = A',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 4 --Define Product
 	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'ProdCode = ProdTag',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 5 --Define Event Status
 	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'EventStatus = "Complete"',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 6 --Define Dimension X
 	  	 IF @PCTag Is Not NUll  
 	  	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'DimX = DimXTag',1,NULL,@UserId,Null
 	  	 ELSE
 	  	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'DimX = ""',1,NULL,@UserId,Null 	  	 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 7 --Define State
 	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'State = "INSERT"',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 8 --Auto Create Applied Products
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,'1',1,NULL,@UserId,Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 9 --Add Applied Product to Path
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,'0',1,NULL,@UserId,Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 10 --Default Product Family
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,@PFIdString,1,NULL,@UserId,Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 11 --Append yymmdd to duplicate events
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,'1',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 12 --Auto Create Statuses
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,'0',1,NULL,@UserId,Null
 	  	 Insert Into @CheckTable(id,msg) 	 EXECUTE spEMSEC_ActiveCheck  @ECId,@UserId
 	  	 IF (SELECT COUNT(*) FROM @CheckTable) != 0
 	  	 BEGIN
 	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	  	  	 RETURN
 	  	 END
 	  	 ELSE
 	  	 BEGIN /* Add ProductChange Success */
 	  	  	 EXECUTE spEMEC_UpdateIsActive @ECId, 1,@UserId
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,3,@UserId,NULL 
 	  	 END
 	 END
 	 IF @HasProductionEventChangeModel IS NOT NULL And @PTTag is not Null /* Check Tag Changed  Update*/
 	 BEGIN
 	  	 SET @ECVDID = Null 
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 1 --InputTags 	 
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasProductionEventChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'EVENTTAG') <> @PTTag
 	  	 BEGIN
 	  	  	 SET @ECVDID = Null
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId and  Alias = 'EVENTTAG'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasProductionEventChangeModel,@PUID,'EVENTTAG',1,@PTTag,2,12,0,0,@EDFieldId,@UserId,@ECVDID
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasProductionEventChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'PRODTAG') <> @PNTag
 	  	 BEGIN
 	  	  	 SET @ECVDID = Null
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId and  Alias = 'PRODTAG'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasProductionEventChangeModel,@PUID,'PRODTAG',0,@PNTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	  	 IF @PCTag Is Not Null
 	  	 BEGIN
 	  	  	 IF NOT EXISTS(SELECT 1 FROM Event_Configuration_Data b 
 	  	  	   where b.EC_Id = @HasProductionEventChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'DIMXTAG')
 	  	  	 BEGIN
 	  	  	  	 EXECUTE spEMSEC_PutInputData @HasProductionEventChangeModel,@PUID,'DIMXTAG',0,@PCTag,1,12,0,0,@EDFieldId,@UserId,Null
 	  	  	  	 SET @EDFieldId2 = Null
 	  	  	  	 SELECT @EDFieldId2 = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 6 --Define Dimension X
 	  	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId2
 	  	  	  	 EXECUTE spEMSEC_PutECData  @EDFieldId2,@HasProductionEventChangeModel,@PUID,'DimX = DimXTag',1,NULL,@UserId,@ECVDID
 	  	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	  	 END
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 IF EXISTS(SELECT 1 FROM Event_Configuration_Data b 
 	  	  	   where b.EC_Id = @HasProductionEventChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'DIMXTAG')
 	  	  	 BEGIN
 	  	  	  	 SET @ECVDID = Null
 	  	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId and  Alias = 'DIMXTAG'
 	  	  	  	 EXECUTE spEMSEC_PutInputData Null,@PUID,'DIMXTAG',0,@PCTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID --Delete
 	  	  	  	 SET @EDFieldId2 = Null
 	  	  	  	 SELECT @EDFieldId2 = ED_Field_Id from ED_Fields where ED_Model_Id = 5402 and Field_Order = 6 --Define Dimension X
 	  	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId2
 	  	  	  	 EXECUTE spEMSEC_PutECData  @EDFieldId2,@HasProductionEventChangeModel,@PUID,'DimX = ""',1,NULL,@UserId,@ECVDID
 	  	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	  	 END 	  	  	 
 	  	 END
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasProductionEventChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'DIMXTAG') <> @PCTag
 	  	 BEGIN
 	  	  	 SET @ECVDID = Null
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId and  Alias = 'DIMXTAG'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasProductionEventChangeModel,@PUID,'DIMXTAG',0,@PCTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasProductionEventChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'A') <> @SNTag
 	  	 BEGIN
 	  	  	 SET @ECVDID = Null
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductionEventChangeModel and ED_Field_Id = @EDFieldId and  Alias = 'A'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasProductionEventChangeModel,@PUID,'A',0,@SNTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	 END
 	 SET @NextStart = Null
 	 SELECT   @NextStart = MIN(Id)
 	    FROM @EquipWithProductionEventTags WHERE Id > @Start 
 	   IF @NextStart Is Not Null
 	  	 SET @Start = @NextStart
 	   ELSE
 	  	 SET @Start = @End + 1
END
/**** Cleanup removed Bad config****/
INSERT INTO @CurrentDecativatedPAUnits(PUId)
 	 SELECT pu_Id From Event_Configuration a WHERE a.EC_Desc = @ProductionEventChangeModelDesc and Is_Active = 1
 	 and PU_Id not in (SELECT PaId FROM @EquipWithProductionEventTags WHERE PTTag Is Not Null)
SELECT @End = @@ROWCOUNT 
SET @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = puId
 	  	 FROM @CurrentDecativatedPAUnits  WHERE id =  @Start
 	 SET @ECId = Null
 	 SELECT @ECId = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @ProductionEventChangeModelDesc
 	 IF @ECId Is Not Null
  	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	 SET @Start = @Start + 1
END

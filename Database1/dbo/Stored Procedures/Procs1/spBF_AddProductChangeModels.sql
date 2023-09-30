CREATE Procedure dbo.spBF_AddProductChangeModels
AS
-- spBF_AddProductChangeModels 8
DECLARE 	 @Class nVarChar(50) = 'Downtime' 
DECLARE 	 @ProductChangeClassName nVarChar(50) = 'PRODCHANGE' 
DECLARE 	 @ProductChangeModelDesc nVarChar(100) = 'EfficiencyAnalyzer Product Change Model'
DECLARE @PFId Int,@SpecId Int
DECLARE @PFIdString  nvarchar(10)
Declare @EquipWithProductChangeTags Table (Id Int identity(1,1)
 	  	  	  	  	  	  	  	  	  	  	 ,EquipmentId UniqueIdentifier
 	  	  	  	  	  	  	  	  	  	  	 ,S95Id nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,PAId Int
 	  	  	  	  	  	  	  	  	  	  	 ,Historian 	 nVarChar(100)
 	  	  	  	  	  	  	  	  	  	  	 ,ProductChangeTag nVarChar(100))
 	  	  	  	  	  	  	  	  	  	  	 
DECLARE @Start Int,@End Int,@ECId Int,@PuId INt,@ProductChangeTag nVarChar(200)
DECLARE @HasProductChangeModel int
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
DECLARE @CurrentDecativatedPAUnits Table(Id Int Identity(1,1),PUId Int)
SELECT @ReloadSetback = dbo.fnServer_CmnConvertToDbTime(GETUTCDATE(),'UTC')
set @ReloadSetback = dateadd(hour,-datepart(hour,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(minute,-datepart(minute,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(second,-datepart(second,@ReloadSetback),@ReloadSetback)
set @ReloadSetback = dateadd(millisecond,-datepart(millisecond,@ReloadSetback),@ReloadSetback)
SET @UserId = 1
DECLARE @CheckTable table(id int,msg nvarchar(max))
Insert into @EquipWithProductChangeTags(EquipmentId,S95Id,PaId,ProductChangeTag,Historian)
 SELECT  a.EquipmentId,b.S95Id,c.PU_Id,
 	   SUBSTRING( d.Name,CHARINDEX('.',d.name)+1,LEN(d.name)),
 	   SUBSTRING( d.Name,1,CHARINDEX('.',d.name)-1)
 from Property_Equipment_EquipmentClass  a
 Join Equipment b on b.EquipmentId = a.EquipmentId
 Left Join PAEquipment_Aspect_SOAEquipment c on c.Origin1EquipmentId = b.EquipmentId
 Left Join BinaryItem d on d.ItemId = a.ItemId 
 where Class = @Class and a.ItemId is not null and a.Name = @ProductChangeClassName
SELECT @End = @@ROWCOUNT 
SET  @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = PaId,
 	  	  	 @ProductChangeTag = ProductChangeTag,
 	  	  	 @Historian = Historian
 	 FROM @EquipWithProductChangeTags WHERE id =  @Start
 	 EXECUTE spBF_GetProdFamilyId @PUId,@UserId,@PFId Output,@specid Output 
 	 SET @PFIdString = Convert(nvarchar(10),@PFId)
 	 SELECT @HistAliasName = Null
 	 EXECUTE spBF_AutoCreateHistorian @Historian,@UserId ,@HistAliasName  OUTPUT
 	 SELECT @ProductChangeTag = 'PT:\\' + @HistAliasName + '\' +  @ProductChangeTag
 	 SET @HasProductChangeModel = NULL
 	 SELECT @HasProductChangeModel =  ec_id  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 4
 	 SELECT @HasProductChangeModel =  ec_id,@IsActive = Is_Active  FROM Event_Configuration a WHERE PU_Id = @PuId and ET_Id = 3 and a.EC_Desc = @ProductChangeModelDesc
 	 IF @HasProductChangeModel is not Null and @IsActive = 0  and @ProductChangeTag is not Null
 	 BEGIN
 	  	 EXECUTE spEMEC_DELETEEC    @HasProductChangeModel,2,@UserId,0
 	  	 SET @HasProductChangeModel = Null
 	 END
 	 IF @HasProductChangeModel Is Null and @ProductChangeTag is not Null
 	 BEGIN /* Add ProductChange */
 	  	 SELECT @CommentId = Null,@ECId = Null
 	  	 EXECUTE spEMEC_CreateNewEC @PuId, 0,@ProductChangeModelDesc, 4,null,@UserId,@ECId output,@CommentId Output
 	  	 UPDATE Comments Set Comment_Text = 'Auto Created Based on DownTime Class attatchment'
 	  	  	 WHERE Comment_Id = @CommentId
 	  	 UPDATE Comments Set Comment = 'Auto Created Based on DownTime Class attatchment'
 	  	  	 WHERE Comment_Id = @CommentId
 	  	 EXECUTE spEMSEC_UpdateEventConfiguration  @ECId,803,@UserId
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5405 and Field_Order = 1 --InputTags
 	  	 EXECUTE spEMSEC_PutInputData     @ECId,@PUID,'PCodeTag',1,@ProductChangeTag,1,12,0,0,@EDFieldId,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5405 and Field_Order = 2 --Define Product Code Script
 	  	 EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'ProductCode = PCodeTag',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5405 and Field_Order = 3 --Automatically Create Missing Products
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,'1',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5405 and Field_Order = 4 --Automatically Add Products to Paths
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,'1',1,NULL,@UserId,Null
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5405 and Field_Order = 5 --Default Product Family
 	  	 EXECUTE spEMSEC_PutECData    @EDFieldId,@ECId,@PUID,@PFIdString,1,NULL,@UserId,Null
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
 	 IF @HasProductChangeModel IS NOT NULL And @ProductChangeTag is not Null /* Check Tag Changed  Update*/
 	 BEGIN
 	  	 SET @EDFieldId = Null
 	  	 SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 5405 and Field_Order = 1
 	  	 IF (select SUBSTRING(value,1,255) 
 	  	  	   FROM Event_Configuration_Values a
 	  	  	   JOIN Event_Configuration_Data b on a.ECV_Id = b.ECV_Id 
 	  	  	   where b.EC_Id = @HasProductChangeModel and b.ED_Field_Id = @EDFieldId and Alias = 'PCodeTag') <> @ProductChangeTag
 	  	 BEGIN
 	  	  	 SELECT @ECVDID = Null
 	  	  	 SELECT @ECVDID = ECV_Id FROM  Event_Configuration_Data WHERE EC_Id = @HasProductChangeModel and ED_Field_Id = @EDFieldId and  Alias = 'PCodeTag'
 	  	  	 EXECUTE spEMSEC_PutInputData     @HasProductChangeModel,@PUID,'PCodeTag',1,@ProductChangeTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID OUTPUT
 	  	  	 EXECUTE spEM_ReloadService  4,@ReloadSetback,2,@UserId,NULL 
 	  	 END
 	 END
 	 SET @Start = @Start + 1
END
/**** Cleanup removed Bad config****/
INSERT INTO @CurrentDecativatedPAUnits(PUId)
 	 SELECT pu_Id From Event_Configuration a WHERE a.EC_Desc = @ProductChangeModelDesc
 	 and PU_Id not in (SELECT PaId FROM @EquipWithProductChangeTags WHERE ProductChangeTag Is Not Null)
SELECT @End = @@ROWCOUNT 
SET @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT 	 @PuId = puId
 	  	 FROM @CurrentDecativatedPAUnits  WHERE id =  @Start
 	 SET @ECId = Null
 	 SELECT @ECId = EC_Id FROM Event_Configuration where PU_Id = @PuId and EC_Desc =  @ProductChangeModelDesc
 	 IF @ECId Is Not Null
  	  	  	 EXECUTE spEMEC_DELETEEC    @ECId,2,@UserId,0
 	 SET @Start = @Start + 1
END

CREATE PROCEDURE spEM_EnableRouteOnLine
 	 @Pl_Id int,
 	 @User_id int
AS
BEGIN
SET NOCOUNT ON
DECLARE @Getdate Datetime 
DECLARE @Pu_desc nvarchar(100),@Pl_desc nvarchar(100),@Dept_Desc nvarchar(100)
DECLARE @Pu_Id int
DECLARE @EC_Id int
DECLARE @Comment_Id int,@WasteEC_Id int,@WasteComment_Id int
DECLARE @p8 Int
DECLARE @IsEventActive tinyint
DECLARE @Path_Id int
DECLARE @PEPU_Id int
DECLARE @TempEC_Id int,@TempUDEId int,@udecomment_id int
DECLARE @ECV_Id int,@CntVirtualUnit int
DECLARE @ErrorCode Int, @ErrorMessage nvarchar(2000)
DECLARE @FailedUnits Varchar(max)
DECLARE @CancelStatusId int,@ScrappedStatusId int
DECLARE @ECVID int
DECLARE @WEMTId int,@WETId int
DECLARE @Path_Desc nvarchar(50),@Path_Code nvarchar(50)
DECLARE @pathCnt Int, @UnitCntOnPath Int
DECLARE @OutputMsg nVarChar(100)
DECLARE @how_Many int
DECLARE @OperationEventSubTypeId int, @DefaultUDEStatus int
DECLARE @IsFailedUnit bit
DECLARE @ET_Subtype_ID int
BEGIN TRY
SELECT @Pu_desc = '<'+D.Dept_Desc+':'+Pl.PL_Desc+'>',@Pl_desc = pl_desc, @Dept_Desc = Dept_Desc FROM Prod_lines Pl join Departments D on D.Dept_Id = Pl.Dept_Id
WHERE Pl.PL_Id = @Pl_Id
SET @OutputMsg = 'Creating Virtual Unit'
IF NOT EXISTS (SELECT 1 FROM Prod_Units WHERE pu_desc = @Pu_desc OR (Extended_Info ='BATCH:' AND  Pl_Id = @Pl_Id)) 
BEGIN
 	 
 	 EXEC spEM_CreateProdUnit @Pu_desc,@Pl_Id,@User_Id,@Pu_Id output
End
ELSE
BEGIN
 	 
 	 SELECT @CntVirtualUnit = count(0) FROM Prod_units WHERE pu_desc = @Pu_desc OR (Extended_Info ='BATCH:'AND Pl_Id = @Pl_Id)
 	  
 	 IF @CntVirtualUnit = 1 
 	 BEGIN
 	  	 SELECT @Pu_Id = pu_id FROM Prod_units WHERE pu_desc = @Pu_desc OR (Extended_Info ='BATCH:'AND Pl_Id = @Pl_Id)
 	 END
 	 ELSE
 	 BEGIN
 	  	  --THROW 51000, 'More than one Virtual units exist', 0;
 	  	  SELECT @errorcode = 1,@ErrorMessage = 'There is more than 1 virtual unit on the line. Please check the configuration and retry.'  
 	  	  --Return 
 	  	  GOTO MODEL49000
 	 END
END
  SET @OutputMsg = 'Setting Virtual Unit Properties'
EXEC spEMUP_PutUnitProperties 1,@Pu_Id,'BATCH:',NULL,1,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL 
--Restart the services
SET @Getdate = Getdate()
EXEC spEM_ReloadService 17,@GetDate,2,@User_Id,NULL
SET @Getdate = Getdate()
EXEC spEM_ReloadService 8,@Getdate,2,@User_Id,NULL
SET @Getdate = Getdate()
EXEC spEM_ReloadService 22,@Getdate,2,@User_Id,NULL
-- Add new production Statuses if they don't exist
/* Cancelled
 	 Description = Cancelled
 	 Status = bad
 	 Production = no
 	 inventory = no
 	 icon = orange flag
 	 color = orange
- scrapped
 	 description = scrapped
 	 status = bad
 	 production = no
 	 inventory = no
 	 icon = red flag
 	 color = red
 	 */
 	 
 	 SELECT @CancelStatusId= coalesce(ProdStatus_Id,null) FROM dbo.Production_Status WHERE ProdStatus_Desc = 'Cancelled'
 	 SELECT @ScrappedStatusId= coalesce(ProdStatus_Id,null) FROM dbo.Production_Status WHERE ProdStatus_Desc = 'Scrapped'
 	 IF @CancelStatusId IS NULL
 	  	 BEGIN
 	  	  	 EXEC spEMPSC_ProductionStatusConfigUpdate NULL,87,8,0,0,0,'Cancelled',0,0
 	  	  	 SELECT @CancelStatusId= coalesce(ProdStatus_Id,null) FROM dbo.Production_Status WHERE ProdStatus_Desc = 'Cancelled'
 	  	 END
 	 IF @ScrappedStatusId IS NULL
 	  	 BEGIN
 	  	  	 EXEC spEMPSC_ProductionStatusConfigUpdate NULL,83,3,1,0,0,'Scrapped',0,0
 	  	  	 SELECT @ScrappedStatusId= coalesce(ProdStatus_Id,null) FROM dbo.Production_Status WHERE ProdStatus_Desc = 'Scrapped'
 	  	 END
--Setting Cancelled  and scrapped as Valid Status for virtual Unit
 	 IF NOT EXISTS (SELECT 1 FROM dbo.PrdEXEC_Status WHERE pu_id =@Pu_Id AND  Valid_Status = @CancelStatusId)
 	  	 BEGIN
 	  	  	 EXEC spEMEPC_EXECPathConfig_TableMod 20,@Pu_Id,0,@CancelStatusId,0,'',@User_id
 	  	 END
 	 IF NOT EXISTS (SELECT 1 FROM dbo.PrdEXEC_Status WHERE pu_id =@Pu_Id AND  Valid_Status = @ScrappedStatusId)
 	  	 BEGIN
 	  	  	 EXEC spEMEPC_EXECPathConfig_TableMod 20,@Pu_Id,0,@ScrappedStatusId,0,'',@User_id
 	  	 END
SET @OutputMsg = 'Configuring Production Event on Virtual Unit'
--Adding 118 Production Event model.
IF NOT EXISTS (SELECT 1 FROM event_configuration WHERE pu_id = @Pu_Id AND  EC_Desc ='Batch Import')
BEGIN 
 	 EXEC spEMEC_CreateNewEC @Pu_Id,0,'Batch Import',1,2,1,@EC_Id output,@Comment_Id output
END
ELSE
BEGIN
 	 IF NOT EXISTS(SELECT 1 FROM event_configuration WHERE pu_id = @Pu_Id AND  EC_Desc ='Batch Import')
 	 BEGIN
 	  	 SELECT @errorcode = 5, @ErrorMessage = 'Production event model on virtual unit is other than 118 model. Please check the configuration and retry.'
 	  	 --Return
 	  	 GOTO MODEL49000
 	 END
 	 SELECT @EC_Id = EC_Id,@IsEventActive = Is_Active FROM event_configuration WHERE pu_id = @Pu_Id AND EC_Desc ='Batch Import'
 	 IF @IsEventActive = 1
 	 BEGIN
 	  	 EXEC spEMEC_UpdateIsActive @EC_Id,0,@User_Id
 	 END
END
EXEC spEMSEC_UpdateEventConfiguration @EC_Id,118,@User_Id
--update properties while adding a model/event
IF NOT EXISTS (SELECT * FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id AND ED_Field_Id = 2767)
BEGIN
 	 EXEC spEMSEC_PutECData 2767,@EC_Id,@Pu_Id,@Dept_Desc,1,NULL,1,@p8 output
END
ELSE
BEGIN
 	 SELECT @ECV_Id = ECV_Id FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id AND ED_Field_Id = 2767
 	 EXEC spEMSEC_PutECData 2767,@EC_Id,@Pu_Id,@Dept_Desc,1,NULL,1,@ECV_Id output
END 
SET @p8 = NULL
IF NOT EXISTS (SELECT * FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id AND ED_Field_Id = 2768)
BEGIN
 	 EXEC spEMSEC_PutECData 2768,@EC_Id,@Pu_Id,@Pl_desc,1,NULL,1,@p8 output
END
ELSE
BEGIN
 	 SELECT @ECV_Id = ECV_Id,@EC_Id = EC_Id FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id AND ED_Field_Id = 2768
 	 EXEC spEMSEC_PutECData 2768,@EC_Id,@Pu_Id,@Pl_desc,1,NULL,1,@ECV_Id output
END
SET @p8 = NULL
IF NOT EXISTS (SELECT * FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id AND ED_Field_Id = 2769)
BEGIN
EXEC spEMSEC_PutECData 2769,@EC_Id,@Pu_Id,@Pu_desc,1,NULL,1,@p8 output
END
ELSE
BEGIN
 	 SELECT @ECV_Id = ECV_Id,@EC_Id = EC_Id FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id AND ED_Field_Id = 2769
 	 EXEC spEMSEC_PutECData 2769,@EC_Id,@Pu_Id,@Pu_desc,1,NULL,1,@ECV_Id output
END
SET @OutputMsg = 'Configuring Waste Event on Virtual Unit'
--Adding Time Based Waste Event model.
IF NOT EXISTS (SELECT 1 FROM event_configuration WHERE pu_id = @Pu_Id AND ET_Id = 3 )--EC_Desc ='Waste Occurs On Single Location')
BEGIN
 	 EXEC spEMEC_CreateNewEC @Pu_Id,0,'Waste Occurs On Single Location',3,NULL,1,@WasteEC_Id output,@WasteComment_Id output 	 
 	 EXEC spEMSEC_UpdateEventConfiguration @WasteEC_Id,304,@User_id
 	 EXEC spEMSEC_PutECData 2822,@WasteEC_Id,@Pu_Id,'1',1,NULL,1,@ECVID output -- set the event to be Event Based Waste (Exact Time)
END 
--Adding Waste Measurement 
IF NOT EXISTS (SELECT 1 FROM dbo.Waste_Event_Meas WHERE PU_Id = @Pu_Id AND WEMT_Name = 'Lot')
BEGIN
 EXEC spEMSEC_PutWasteMeas 'Lot',1,NULL,@Pu_Id,@User_id,@WEMTId output
END
--adding Waste Type
IF NOT EXISTS (SELECT 1 FROM dbo.Waste_Event_Type WHERE WET_Name = 'NCM-Waste')
BEGIN
 EXEC spEMSEC_PutWasteType 'NCM-Waste',0,@User_id,@WETId output
END
SET @Getdate = Getdate()
EXEC spEM_ReloadService 4,@Getdate,2,@User_id,NULL
--Path configuration
--Add Path
SET @OutputMsg = 'Configuring Production Execution Path on line'
SELECT @Path_Desc = 'Route Enabled:'+@Pl_desc, @Path_Code = 'RE:'+@Pl_desc
IF NOT EXISTS (SELECT 1 FROM PrdEXEC_Paths  WHERE  pl_Id = @Pl_Id) 
BEGIN 
 	 EXEC spEMEPC_PutEXECPaths @Pl_Id,@Path_Desc,@Path_Code,0,NULL,0,0,@User_Id,@Path_Id output
 	 EXEC spEMEPC_PutPathUnits @pu_ID,@Path_Id,1,1,1,@User_Id,@PEPU_Id output
 	 DELETE FROM Production_Plan_Status WHERE Path_Id = @Path_Id AND  FROM_PPStatus_Id = 1 AND  To_PPStatus_Id in (2,3,-2)
 	 EXEC spEMEPC_GetSchedTransitions @Path_Id,@User_Id,1,2,0
 	 EXEC spEMEPC_GetSchedTransitions @Path_Id,@User_Id,1,3,0
 	 --Adding Cancelled as valid transitions for pending status
 	 EXEC spEMEPC_GetSchedTransitions @Path_Id,@User_Id,1,-2,0
 	 
 	 EXEC spEMEPC_GetSchedStatusDetail @Path_Id,@User_Id,3,1000,1,2,4,NULL,0
END
ELSE
BEGIN
 	 --1. Multiple paths exist with same virtual unit . fail the EXECution
 	 SELECT @pathCnt = COUNT(DISTINCT PP.Path_Id) FROM PrdEXEC_Paths PP JOIN PrdEXEC_Path_Units PPU ON PPU.Path_Id = PP.Path_Id WHERE PP.PL_Id = @Pl_Id AND PPU.PU_Id = @Pu_Id 
 	 IF @pathCnt > 1
 	 BEGIN
 	  	 --THROW 51000, 'Multiple paths exists for one virtual unit', 0;
 	  	 SELECT @errorcode = 2, @ErrorMessage = 'There is more than 1 path configured on the line that contains the virtual unit. Please check the configuration and retry.'
 	  	 --Return
 	  	 GOTO MODEL49000
 	 END 	 
 	 
 	 --2. One path exists with same virtual unit and it has non-virtual units too . fail the EXECution
 	 SELECT 
 	  	 @UnitCntOnPath = Count(0) 
 	 FROM 
 	  	 PrdEXEC_Path_Units A Join PrdEXEC_Paths B On B.Path_Id = A.Path_Id
 	 WHERE B.pl_Id = @Pl_Id
 	 AND EXISTS (SELECT 1 FROM PrdEXEC_Path_Units WHERE path_id = A.Path_Id AND pu_id = @Pu_Id)
 	 IF @pathCnt = 1 AND @UnitCntOnPath > 1
 	 BEGIN 
 	  	 --THROW 51000, 'Path has more than one unit including one virtual unit', 0;
 	  	 SELECT @errorcode = 3, @ErrorMessage = 'There is path that contains a virtual unit and there is more than the virtual unit on the path. Please check the configuration and retry.'
 	  	 --Return
 	  	 GOTO MODEL49000
 	 END
 	 
 	 IF NOT EXISTS (SELECT 1 FROM  PrdEXEC_Path_Units WHERE Path_Id in (SELECT Path_Id FROM PrdEXEC_Paths WHERE PL_Id = @Pl_Id) AND  Pu_id = @Pu_Id)
 	 BEGIN
 	  	 SET @Path_Id = NULL
 	  	 SET @PEPU_Id = NULL
 	  	 EXEC spEMEPC_PutEXECPaths @Pl_Id,@Path_Desc,@Path_Code,0,NULL,0,0,@User_Id,@Path_Id output
 	  	 EXEC spEMEPC_PutPathUnits @pu_ID,@Path_Id,1,1,1,@User_Id,@PEPU_Id output
 	 END
 	 SELECT @Path_Id = Path_Id FROM PrdEXEC_Paths A WHERE PL_Id = @Pl_Id AND EXISTS (SELECT 1 FROM PrdEXEC_Path_Units WHERE Path_Id = A.Path_Id AND  Pu_Id = @Pu_Id)
 	 UPDATE PrdEXEC_Paths
 	 SET 
 	  	 Is_Line_Production = 0,Is_Schedule_Controlled = 0, Create_Children = 0,Schedule_Control_Type =NULL
 	 WHERE 
 	  	 Path_id = @Path_Id
 	 UPDATE PrdEXEC_Path_Units
 	 SET 
 	  	 Unit_Order = 1, Is_Production_Point = 1, Is_Schedule_Point = 1
 	 WHERE 
 	  	 Path_id = @Path_Id
 	  	 AND PU_Id = @Pu_Id
 	 DELETE FROM Production_Plan_Status WHERE Path_Id = @Path_Id AND  FROM_PPStatus_Id = 1  AND  To_PPStatus_Id in (2,3,-2)
 	 EXEC spEMEPC_GetSchedTransitions @Path_Id,@User_Id,1,2,0
 	 EXEC spEMEPC_GetSchedTransitions @Path_Id,@User_Id,1,3,0
 	 --Adding Cancelled as valid transitions for pending status
 	 
 	 EXEC spEMEPC_GetSchedTransitions @Path_Id,@User_Id,1,-2,0
 	 SELECT @how_Many = How_Many FROM PrdEXEC_Path_Status_Detail WHERE Path_Id = @Path_Id AND  PP_Status_Id = 3
 	 
 	 --SET @how_Many = CASE WHEN @how_Many IS ISNULL(@how_Many,1000)
 	 
 	 --Check if how_many value is other than 1000 and a valid value , then don't update
 	 EXEC spEMEPC_GetSchedStatusDetail @Path_Id,@User_Id,3,@how_Many,1,2,4,NULL,0
 	  	 
END
SET @getdate = getdate()
EXEC spEM_ReloadService 22,@getdate,2,@User_Id,NULL
--check if user defined event of subtype Operation exists or not 
--if not create one
SET @OutputMsg = 'Configuring/Verifying event configuration on other units in the line'
SELECT @OperationEventSubTypeId = Coalesce(Event_Subtype_Id,NULL)  FROM dbo.Event_Subtypes WHERE et_id =14 AND  Event_Subtype_Desc = 'Operation'
 	 IF @OperationEventSubTypeId IS NULL
 	  	 BEGIN
 	  	  	 EXEC spEMEC_UpdateUDEEvent NULL,'Operation',121,0,0,0,0,0,1,@OperationEventSubTypeId output,@DefaultUDEStatus output
 	  	 END
--Create production event for all the units in the line if no production event is created.
DECLARE @Cnt int, @total Int, @TempPu_Id int,@TempPu_desc nvarchar(100) 
Create Table #TempUnits(RowId int Identity(1,1), Pu_Id int, Pu_desc nvarchar(100))
Insert into #TempUnits(Pu_Id,Pu_desc)
SELECT Pu_Id,Pu_desc FROM Prod_Units WHERE pl_Id = @pl_Id AND  pu_Id <> @pu_Id
SET @total = @@rowcount
SET @Cnt = 1
WHILE @Cnt <=@total
BEGIN
 	 SELECT @TempPu_Id = Pu_Id, @TempPu_desc = Pu_desc FROM #TempUnits WHERE RowId = @Cnt
 	 SET @IsFailedUnit = 0
 	 --Setting Cancelled as Valid Status @CancelStatusId
 	 IF NOT EXISTS (SELECT 1 FROM dbo.PrdEXEC_Status WHERE pu_id =@TempPu_Id AND  Valid_Status = @CancelStatusId)
 	  	 BEGIN
 	  	  	 EXEC spEMEPC_EXECPathConfig_TableMod 20,@TempPu_Id,0,@CancelStatusId,0,'',@User_id
 	  	 END
 	 -- Configuring the production events 
 	 IF NOT EXISTS (SELECT 1 FROM event_configuration WHERE pu_id = @TempPu_Id AND  ET_ID = 1)
 	 BEGIN  	  	 
 	  	 EXEC spEMEC_CreateNewEC @TempPu_Id,0,'Batch Import',1,2,1,@TempEC_Id output,@Comment_Id output --subtype lot
 	  	 
 	  	 EXEC spEMSEC_UpdateEventConfiguration @TempEC_Id,118,@User_Id
 	  	 SET @p8 = NULL
 	  	 IF NOT EXISTS (SELECT 1 FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2767)
 	  	 EXEC spEMSEC_PutECData 2767,@TempEC_Id,@TempPu_Id,@Dept_Desc,1,NULL,1,@p8 output
 	  	 SET @p8 = NULL
 	  	 IF NOT EXISTS (SELECT 1 FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2768)
 	  	 EXEC spEMSEC_PutECData 2768,@TempEC_Id,@TempPu_Id,@Pl_desc,1,NULL,1,@p8 output
 	  	 SET @p8 = NULL
 	  	 IF NOT EXISTS (SELECT 1 FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2769)
 	  	 EXEC spEMSEC_PutECData 2769,@TempEC_Id,@TempPu_Id,@TempPu_desc,1,NULL,1,@p8 output
 	  	 SET @p8 = NULL
 	  	 EXEC spEMEC_UpdateIsActive @TempEC_Id,0,@User_Id
 	 END
 	 IF EXISTS (SELECT 1 FROM event_configuration WHERE pu_id = @TempPu_Id AND  EC_Desc ='Batch Import')
 	 BEGIN
 	  	 SELECT @TempEC_Id = EC_Id , @ET_Subtype_ID = Event_Subtype_Id FROM event_configuration WHERE pu_id = @TempPu_Id AND  EC_Desc ='Batch Import'
 	  	 -- change event subtype to lot if it is not
 	  	 IF @ET_Subtype_ID <>2
 	  	 BEGIN
 	  	 UPDATE dbo.Event_Configuration SET Event_Subtype_Id = 2 WHERE ec_id =@TempEC_Id
 	  	 END
 	  	 IF NOT EXISTS (SELECT * FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2767)
 	  	 BEGIN
 	  	  	 EXEC spEMSEC_PutECData 2767,@TempEC_Id,@TempPu_Id,@Dept_Desc,1,NULL,1,@p8 output
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	  
 	  	  	 SELECT @ECV_Id = ECV_Id  FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2767
 	  	  	 EXEC spEMSEC_PutECData 2767,@TempEC_Id,@TempPu_Id,@Dept_Desc,1,NULL,1,@ECV_Id output
 	  	 END 
 	  	 SET @p8 = NULL
 	  	 IF NOT EXISTS (SELECT * FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2768)
 	  	 BEGIN
 	  	  	 EXEC spEMSEC_PutECData 2768,@TempEC_Id,@TempPu_Id,@Pl_desc,1,NULL,1,@p8 output
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @ECV_Id = ECV_Id  FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2768
 	  	  	 EXEC spEMSEC_PutECData 2768,@TempEC_Id,@TempPu_Id,@Pl_desc,1,NULL,1,@ECV_Id output
 	  	 END
 	  	 SET @p8 = NULL
 	  	 IF NOT EXISTS (SELECT * FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2769)
 	  	 BEGIN
 	  	  	 EXEC spEMSEC_PutECData 2769,@TempEC_Id,@TempPu_Id,@TempPu_desc,1,NULL,1,@p8 output
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @ECV_Id = ECV_Id  FROM Event_Configuration_Data WHERE Ec_Id = @TempEC_Id AND  ED_Field_Id = 2769
 	  	  	 EXEC spEMSEC_PutECData 2769,@TempEC_Id,@TempPu_Id,@TempPu_desc,1,NULL,1,@ECV_Id output
 	  	 END 	  	 
 	 END
 	 IF EXISTS(SELECT 1 FROM event_configuration WHERE pu_id = @TempPu_Id AND  EC_Desc <>'Batch Import' AND  ET_Id = 1)
 	 BEGIN
 	  	 SET @FailedUnits = COALESCE(@FailedUnits + ',', '') + cast(@TempPu_Id as varchar)
 	  	 SET @IsFailedUnit = 1
 	 END
 	 --END of production events
 	 IF (@IsFailedUnit = 0)
 	 BEGIN
 	 --Configuring the User defined events 
 	 IF NOT EXISTS (SELECT 1 FROM event_configuration WHERE pu_id = @TempPu_Id AND  ET_ID = 14 AND  Event_Subtype_Id = @OperationEventSubTypeId)
 	 BEGIN 
 	  	 EXEC spEMEC_CreateNewEC @TempPu_Id,0,'User Defined Event - Script',14,@OperationEventSubTypeId,1,@TempUDEId output,@udecomment_id output
 	  	 EXEC spEMSEC_UpdateEventConfiguration @TempUDEId,802,@User_Id
 	 END
 	 --END of user defined events
 	 END
 	 SET @Cnt = @Cnt + 1  
END
 	 IF ISNULL(@FailedUnits,'') <> ''
 	 BEGIN
 	 
 	  	 SELECT @errorcode = 4, @ErrorMessage = 'Unit(s) ['+@FailedUnits+'] has a production event model <> 118. It can not be used for Route configuration.'
 	  	 --Return
 	  	 GOTO MODEL49000
 	 END
 	 
SET @OutputMsg = 'Configuring Schedule View'
--Create schedule View on the unit
DECLARE @Sheet_Id int, @SheetName nvarchar(50),@WasteSheet_Id int, @WasteSheetName nvarchar(50)
SET @SheetName = 'RESchedVw'+@Pu_desc
--SET @WasteSheetName = 'REWasteVw'+@Pu_desc
SELECT 
 	 @Sheet_Id = S.Sheet_Id 
FROM 
 	 Sheets S
 	 Join Sheet_Paths Sp on Sp.Sheet_Id = S.Sheet_Id AND  sp.Path_Id = @Path_Id
WHERE S.Event_Type = 1 AND  S.Sheet_Type = 17
/*SELECT 
 	 @WasteSheet_Id = S.Sheet_Id 
FROM 
 	 Sheets S
WHERE S.Event_Type = 1 And S.Sheet_Type = 4 And S.Master_Unit = @Pu_Id */
DECLARE @SheetGroupId int
IF @Sheet_Id IS NULL
BEGIN
 	 Delete FROM Sheets WHERE Sheet_Desc =@SheetName
 	 SELECT @SheetGroupId = Sheet_Group_Id FROM Sheet_Groups WHERE Sheet_Group_Desc = @Pl_Desc
 	 IF @SheetGroupId IS NULL
 	 BEGIN
 	  	 EXEC spEM_CreateSheetGroup @Pl_Desc,@User_Id, @SheetGroupId Output
 	 END
 	 EXEC spEM_CreateSheet @SheetName,17,1,@SheetGroupId,@User_Id,@Sheet_Id output --What should be the sheet group for the sheet? How we should choose one Sheet Group?
 	 --DE143407
 	 --EXEC spEM_PutSecuritySheet @Sheet_Id,1,@User_Id
 	 EXEC spEM_PutSheetData @Sheet_Id,NULL,NULL,0,0,24,24,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,default,0,0,NULL,NULL,0,NULL,@User_Id
 	 EXEC spEM_PutSheetUnits @Sheet_Id,1,@Path_Id,1,1,@User_Id---Islast,IsFirst, Id, Order
 	 EXEC spEM_ActivateSheet @Sheet_Id,1,@User_Id
END
/*
IF @WasteSheet_Id IS NULL
BEGIN
 	 SELECT @SheetGroupId = Sheet_Group_Id FROM Sheet_Groups WHERE Sheet_Group_Desc = @Pl_Desc
 	 EXEC spEM_CreateSheet @WasteSheetName,4,1,@SheetGroupId,@User_Id,@WasteSheet_Id output --What should be the sheet group for the sheet? How we should choose one Sheet Group?
 	 EXEC spEM_PutSecuritySheet @WasteSheet_Id,1,@User_Id
 	 SET @getdate = getdate()
 	 EXEC spEM_PutSheetData @WasteSheet_Id,@Pu_Id,NULL,0,0,24,24,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,default,0,0,NULL,NULL,0,NULL,@User_Id
 	 EXEC spEM_ActivateSheet @WasteSheet_Id,1,@User_Id
 	 EXEC spEM_ReloadService 8,@getdate,2,@User_id,NULL
END */
--Check for 49000 model.
SET @OutputMsg = 'Configuring Batch Import model'
 	 DECLARE @EC_Id_Model49000 Int, @ECV_Id2773 Int, @ECV_Id2774 Int
IF NOT EXISTS (SELECT 1 FROM Event_Configuration WHERE  ED_Model_Id  =49000)
BEGIN
 	 INSERT INTO Event_Configuration (Comment_Id,Debug,EC_Desc,ED_Model_Id,ESignature_Level,ET_Id,Event_Subtype_Id,Exclusions,Extended_Info,External_Time_Zone,Is_Active,Is_Calculation_Active,Max_Run_Time,Model_Group,Move_EndTime_Interval,PEI_Id,Priority,PU_Id,Retention_Limit)
 	 SELECT 10,0,NULL,49000,NULL,7,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,1,0,NULL
 	 SELECT @EC_Id_Model49000 = EC_Id,@IsEventActive = Is_Active  FROM event_Configuration WHERE ED_Model_Id = 49000
 	 Insert Into Event_Configuration_Values(Value)
 	 SELECT 'spBatch_CheckEventTable'-- WHERE NOT EXISTS ( 	 SELECT 1 FROM  Event_Configuration_Values WHERE Cast(Value as varchar(max)) = 'spBatch_CheckEventTable')
 	 Select @ECV_Id2774 = Scope_Identity()
 	 
 	 Insert Into Event_Configuration_Values(Value) 
 	 SELECT 'TINTSEC:1'-- WHERE NOT EXISTS (SELECT 1 FROM  Event_Configuration_Values WHERE Cast(Value as varchar(max)) = 'TINTSEC:1')
 	 Select @ECV_Id2773 = Scope_Identity()
 	 
 	 Insert Into Event_Configuration_Data (Alias,EC_Id,ECV_Id,ED_Attribute_Id,ED_Field_Id,Input_Precision,IsTrigger,PEI_Id,PU_Id,Sampling_Offset,ST_Id)
 	 SELECT NULL,@EC_Id_Model49000,@ECV_Id2773,NULL,2773,0,NULL,NULL,0,NULL,NULL 
 	 WHERE Not Exists (SELECT 1 FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id_Model49000 AND  ED_Field_Id = 2773)
 	 UNION
 	 SELECT NULL,@EC_Id_Model49000,@ECV_Id2774,NULL,2774,0,NULL,NULL,0,NULL,NULL
 	 WHERE Not Exists (SELECT 1 FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id_Model49000 AND  ED_Field_Id = 2774)
END
 	 MODEL49000:
 	 SELECT @EC_Id_Model49000 = EC_Id,@IsEventActive = Is_Active  FROM event_Configuration WHERE ED_Model_Id = 49000
 	 SELECT @ECV_Id2773 = ECV_Id FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id_Model49000 AND  ED_Field_Id = 2773
 	 SELECT @ECV_Id2774 = ECV_Id FROM Event_Configuration_Data WHERE Ec_Id = @EC_Id_Model49000 AND  ED_Field_Id = 2774
 	 
 	 UPDATE Event_Configuration_Values SET VALUE = 'TINTSEC:1' WHERE ECV_Id = @ECV_Id2773
 	 UPDATE Event_Configuration_Values SET VALUE = 'spBatch_CheckEventTable' WHERE ECV_Id = @ECV_Id2774
 	 
 	 IF @IsEventActive = 0
 	 BEGIN
 	  	 EXEC spEMEC_UpdateIsActive @EC_Id_Model49000,1,@User_Id
 	 END
 	 SET @OutputMsg = 'Reading the purge related site parameters'
 	 -- Append display message to user about their current purge parameters X
 	 DECLARE @purgeOrphanRecords Int,@purgeProcessedRecords Int, @purgeMsg varchar(Max)
 	 SELECT @purgeOrphanRecords = value FROM Site_Parameters WHERE parm_id = 501 
 	 SELECT @purgeProcessedRecords = value FROM Site_Parameters WHERE parm_id = 502
 	 SELECT @purgeMsg = 'Purge parameters are set as following: PurgeOrphanRecords = '+ Convert(nVarChar(10),@purgeOrphanRecords) +' ; PurgeProcessedRecords = '+ 
 	 Convert(nVarChar(10),@purgeProcessedRecords)+'. Refer to Site parameters section of PA help to update these values.'
 	 SET @OutputMsg = 'Updating ISRouteEnabled user defined parameter'
--update the UDP value 
  DECLARE @RouteEnableUDP Int,@UDPValue Int
  SELECT @RouteEnableUDP = Table_Field_Id FROM dbo.Table_Fields WHERE tableid = 18 AND  Table_Field_Desc = 'IsRouteEnabled'
  SELECT @UDPValue =  CASE WHEN @ErrorCode IS NULL THEN 1 ELSE 0 END
 	  	 IF Exists ( SELECT 1 FROM dbo.Table_Fields_Values WHERE keyid = @Pl_Id AND  Table_Field_Id = @RouteEnableUDP AND  TableId = 18)
 	  	  	  	 BEGIN
 	  	  	  	  	 Update dbo.Table_Fields_Values set value = @UDPValue WHERE keyid = @Pl_Id AND  Table_Field_Id = @RouteEnableUDP AND  TableId = 18
 	  	  	  	 END
 	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 Insert into dbo.Table_Fields_Values (KeyId,Table_Field_Id,TableId,Value) Values (@Pl_Id,@RouteEnableUDP,18,@UDPValue)
 	  	  	 END
 	  	  	 
 	 SELECT 
 	  	  	 @ErrorCode =  CASE WHEN @ErrorCode IS NULL THEN 6 ELSE @ErrorCode END,
 	  	  	 @ErrorMessage =  CASE WHEN @ErrorMessage IS NULL THEN 'Route enabled successfully on '+ @Pl_desc +'. Please refresh the server.' + @purgeMsg  ELSE @ErrorMessage END
 	 SELECT @ErrorCode ErrorCode, @ErrorMessage ErrorMessage
 	 
 	 SET @getdate = getdate()
  	 EXEC spEM_ReloadService 4,@getdate,2,@User_id,NULL
 	 EXEC spEM_ReloadService 5,@getdate,2,@User_id,NULL
 	 EXEC spEM_ReloadService 6,@getdate,2,@User_id,NULL
 	 EXEC spEM_ReloadService 8,@getdate,2,@User_id,NULL
 	 EXEC spEM_ReloadService 7,@getdate,2,@User_id,NULL
 	 --there is a sheet but path is not set...how to handle this scenario.
DROP TABLE #TempUnits
END TRY
BEGIN CATCH
 SELECT @ErrorCode = 7 , @ErrorMessage = @OutputMsg + ' failed.'
 SELECT @ErrorCode ErrorCode, @ErrorMessage ErrorMessage
END CATCH
END

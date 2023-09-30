CREATE PROCEDURE dbo.spEM_IEImportProdExecPathStatusDetail
@PathCode 	  	 nVarChar(100),
@ScheduleStatus nVarChar(100),
@ToStatus 	  	 nVarChar(100),
@FromStatus 	  	 nVarChar(100),
@SortOrder 	  	 nVarChar(100),
@HowMany 	  	 nVarChar(100),
@SortWithStatus 	 nVarChar(100),
@UserId 	  	 Int
AS
Declare @PathId 	  	  	 Int,
 	  	 @StatusId  	  	 Int,
 	  	 @ToId 	  	  	 Int,
 	  	 @FromId  	  	 Int,
 	  	 @SortWithId  	 Int,
 	  	 @iHowMany  	  	 Int,
 	  	 @iSortOrder  	 Int,
 	  	 @PPSDId 	  	  	 Int
/* Clean and verIFy arguments */
SELECT  	 @PathCode 	  	  	 = ltrim(rtrim(@PathCode)),
 	  	 @ScheduleStatus 	  	 = ltrim(rtrim(@ScheduleStatus)),
 	  	 @ToStatus  	  	  	 = ltrim(rtrim(@ToStatus)),
 	  	 @FromStatus  	  	 = ltrim(rtrim(@FromStatus)),
 	  	 @SortOrder  	  	  	 = ltrim(rtrim(@SortOrder)),
 	  	 @HowMany  	  	  	 = ltrim(rtrim(@HowMany)),
 	  	 @SortWithStatus  	 = ltrim(rtrim(@SortWithStatus))
IF @PathCode = '' 	  	 SELECT @PathCode = Null
IF @ScheduleStatus = '' 	 SELECT @ScheduleStatus = Null
IF @ToStatus = '' 	  	 SELECT @ToStatus = Null
IF @FromStatus = '' 	  	 SELECT @FromStatus = Null
IF @SortOrder = '' 	  	 SELECT @SortOrder = Null
IF @HowMany = '' 	  	 SELECT @HowMany = Null
IF @SortWithStatus = '' 	 SELECT @SortWithStatus = Null
IF @PathCode Is Null 
BEGIN
 	 SELECT 'Failed - Path Code missing'
 	 Return (-100)
END
IF @ScheduleStatus Is Null 
BEGIN
 	 SELECT 'Failed - From Schedule status missing'
 	 Return (-100)
END
SELECT @PathId = Path_Id FROM PrdExec_Paths WHERE Path_Code = @PathCode
IF @PathId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find Path'
 	 Return (-100)
END
SELECT @StatusId = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @ScheduleStatus
IF @StatusId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find Schedule status'
 	 Return (-100)
END
IF @FromStatus Is Not Null
BEGIN
 	 SELECT @FromId = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @FromStatus
 	 IF @FromId Is null
 	 BEGIN
 	  	 SELECT 'Failed - Unable to Find From status'
 	  	 Return (-100)
 	 END
END
IF @ToStatus Is Not Null
BEGIN
 	 SELECT @ToId = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @ToStatus
 	 IF @ToId Is null
 	 BEGIN
 	  	 SELECT 'Failed - Unable to Find To status'
 	  	 Return (-100)
 	 END
END
IF @SortWithStatus Is Not Null
BEGIN
 	 SELECT @SortWithId = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @SortWithStatus
 	 IF @SortWithId Is null
 	 BEGIN
 	  	 SELECT 'Failed - Unable to Find sort with status'
 	  	 Return (-100)
 	 END
END
IF isnumeric(@SortOrder) = 1
 	 SELECT @iSortOrder = Convert(Int,@SortOrder)
ELSE
 	 SELECT @iSortOrder = 1
IF isnumeric(@HowMany) = 1
 	 SELECT @iHowMany = Convert(Int,@HowMany)
ELSE
 	 SELECT @iHowMany = Null
SELECT @PPSDId = PPSD_Id
 	 FROM PrdExec_Path_Status_Detail
 	 WHERE Path_Id = @PathId And PP_Status_Id = @StatusId 
IF @PPSDId Is Null
BEGIN
    INSERT Into PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, How_Many, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, Sort_Order, SortWith_PPStatusId) 
        VALUES (@PathId, @StatusId, @iHowMany, @FromId, @ToId, @iSortOrder, @SortWithId)
 	 SELECT @PPSDId = PPSD_Id
 	  	 FROM PrdExec_Path_Status_Detail
 	  	 WHERE Path_Id = @PathId And PP_Status_Id = @StatusId 
 	 IF @PPSDId Is null
 	 BEGIN
 	  	 SELECT 'Failed - Unable to create Status Transition'
 	  	 Return (-100)
 	 END
END
ELSE
BEGIN
 	 UPDATE PrdExec_Path_Status_Detail SET 	 How_Many = @iHowMany,
 	  	  	  	  	  	  	  	  	  	  	 AutoPromoteFrom_PPStatusId = @FromId,
 	  	  	  	  	  	  	  	  	  	  	 AutoPromoteTo_PPStatusId = @ToId,
 	  	  	  	  	  	  	  	  	  	  	 Sort_Order = @iSortOrder,
 	  	  	  	  	  	  	  	  	  	  	 SortWith_PPStatusId =  @SortWithId
 	 WHERE PPSD_Id = @PPSDId
END

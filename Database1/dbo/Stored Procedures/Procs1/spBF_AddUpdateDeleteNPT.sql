CREATE PROCEDURE dbo.spBF_AddUpdateDeleteNPT
 	  	 @NptId 	  	 Int,
        @startTime datetime,
        @endTime datetime,
        @machineId int,
        @reasonId int,
        @commentText text,
 	  	 @ModifyUserId Int = 1,
 	  	 @TransType 	 Int,
 	  	 @IsReasonTreeData Int = 0
AS
IF @TransType =  1
BEGIN
 	 EXECUTE dbo.spBF_calCreateNonProductive     @startTime,@endTime,@machineId,@reasonId,@commentText,@ModifyUserId,@IsReasonTreeData
END
ELSE IF @TransType =  2
BEGIN
 	 EXECUTE dbo.spBF_calUpdateNonProductive     @NptId,@startTime,@endTime,@machineId,@reasonId,@commentText,@ModifyUserId,@IsReasonTreeData
END
ELSE IF @TransType =  3
BEGIN
 	 delete NonProductive_Detail where NPDet_Id = @NptId
 	 Select 'Success'
END

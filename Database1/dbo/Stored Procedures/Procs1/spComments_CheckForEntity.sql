

CREATE PROCEDURE [dbo].[spComments_CheckForEntity]
		@TableId	Int,
		@EntityId   Int 
AS
/* @UserId  @TableId and @UnitId not used for sucurity on a get at this time*/
DECLARE @MAPPED_ENTITY_ID INT,@MaterialLotStatus INT;

IF @TableId IS  NULL  OR @EntityId IS NULL
	BEGIN
		SELECT ERROR='Required Parameter missing';
		RETURN;
	END

IF @TableId IS NOT NULL  AND @EntityId IS NOT NULL
BEGIN
	IF @TableId = 81  --WorkOrder
		BEGIN
			SELECT @MAPPED_ENTITY_ID = PP_Id,@TableId = 35 FROM Workorder.workorders WHERE Id = @EntityId And @TableId =81
	 IF(@MAPPED_ENTITY_ID IS NULL OR @MAPPED_ENTITY_ID<=0)
		BEGIN
		SELECT ERROR='ENTITY_ID NOT FOUND';
		RETURN;
		END
	ELSE
		BEGIN
			SELECT @MAPPED_ENTITY_ID AS EntityId 
		END
		END
	ELSE IF @TableId = 83  --Serial Number
    BEGIN
		WITH S AS (
				SELECT M.Id MAterialLotActualId,[Status] FROM WorkOrder.MaterialLotActuals M Where M.id = @EntityId 
			),S1 AS (SELECT 'DISC:'+CAST(MAterialLotActualId AS nVARCHAR) LotIdentifier_EventNum,[Status] from S )
			SELECT @MAPPED_ENTITY_ID= Event_Id ,@MaterialLotStatus=[Status],@TableId=4 FROM Events E Join S1 ON S1.LotIdentifier_EventNum = E.Event_Num 

	IF EXISTS(SELECT 1 FROM WorkOrder.MaterialLotActuals WHERE Status=21 AND ID=@EntityId)
			Begin
				SELECT ERROR = 'Serial Number Not Started';
                 RETURN;
			End
			
	IF(@MAPPED_ENTITY_ID IS NULL OR @MAPPED_ENTITY_ID<=0)
		BEGIN
			SELECT ERROR='ENTITY_ID NOT FOUND';
		RETURN;
		END
	ELSE
		BEGIN
			SELECT @MAPPED_ENTITY_ID AS EntityId
		END
	 END
END
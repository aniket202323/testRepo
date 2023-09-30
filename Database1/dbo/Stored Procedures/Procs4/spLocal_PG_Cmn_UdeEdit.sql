CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_UdeEdit]
@op_uidErrorId UNIQUEIDENTIFIER NULL OUTPUT, @op_vchErrorMessage VARCHAR (1000) NULL OUTPUT, @p_bitWriteDirect BIT NULL, @p_intTransactionType INT NULL, @p_intUserId INT NULL, @op_intUDEId INT NULL OUTPUT, @p_vchUDEDesc VARCHAR (1000) NULL, @p_intPUId INT NULL, @p_intSubTypeId INT NULL, @p_dtmStartTime DATETIME NULL, @p_dtmEndTime DATETIME NULL, @p_intEventId INT NULL, @p_intParentUDEId INT NULL, @p_intCommentId INT NULL, @p_bitAck BIT NULL, @p_dtmAckOn DATETIME NULL, @p_intAckBy INT NULL, @p_intCause1 INT NULL, @p_intCause2 INT NULL, @p_intCause3 INT NULL, @p_intCause4 INT NULL, @p_intCauseCommentId INT NULL, @p_intAction1 INT NULL, @p_intAction2 INT NULL, @p_intAction3 INT NULL, @p_intAction4 INT NULL, @p_intActionCommentId INT NULL, @p_vchNewValue VARCHAR (25) NULL, @p_intResearchCommentId INT NULL, @p_bitCoalesceOff BIT NULL, @p_intEventStatus INT NULL, @p_TemporalAccuracy INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



CREATE PROCEDURE [dbo].[spLocal_E2P_RMUI_FPP_Reject]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_FPPId INT NULL, @p_Username VARCHAR (50) NULL, @p_Section VARCHAR (255) NULL, @p_Comment VARCHAR (1000) NULL, @p_IsManual BIT NULL, @p_BearerToken VARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



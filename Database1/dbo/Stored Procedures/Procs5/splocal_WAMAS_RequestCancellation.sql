CREATE PROCEDURE [dbo].[splocal_WAMAS_RequestCancellation]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_WAMASReturnCode INT NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_RequestId VARCHAR (50) NULL, @p_RequestTime DATETIME NULL, @p_LocationId VARCHAR (50) NULL, @p_LineId VARCHAR (50) NULL, @p_PrimaryGCas VARCHAR (50) NULL, @p_AlternateGCas VARCHAR (50) NULL, @p_Quantity INT NULL, @p_UoM VARCHAR (50) NULL, @p_UserId INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



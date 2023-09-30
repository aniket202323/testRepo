CREATE PROCEDURE [dbo].[splocal_PrIME_MaterialReturn]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_PrIMEReturnCode INT NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_SAPBatchNumber VARCHAR (50) NULL, @p_ReturnTarget VARCHAR (50) NULL, @p_LocationId VARCHAR (50) NULL, @p_ULID VARCHAR (50) NULL, @p_GCAS VARCHAR (50) NULL, @p_Quantity DECIMAL (19, 5) NULL, @p_UoM VARCHAR (50) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END



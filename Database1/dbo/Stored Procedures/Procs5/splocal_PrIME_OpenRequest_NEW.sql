﻿CREATE PROCEDURE [dbo].[splocal_PrIME_OpenRequest_NEW]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_PrIMEReturnCode INT NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_RequestId VARCHAR (50) NULL, @p_RequestTimestamp DATETIME NULL, @p_LocationId VARCHAR (50) NULL, @p_PrimaryGCas VARCHAR (50) NULL, @p_AlternateGCas VARCHAR (50) NULL, @p_Quantity INT NULL, @p_UoM VARCHAR (50) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


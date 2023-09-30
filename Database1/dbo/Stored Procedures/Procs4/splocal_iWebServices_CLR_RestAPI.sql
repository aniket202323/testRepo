CREATE PROCEDURE [dbo].[splocal_iWebServices_CLR_RestAPI]
@p_URL NVARCHAR (MAX) NULL, @p_Method NVARCHAR (100) NULL, @p_Payload XML NULL, @op_ReturnMessage XML NULL OUTPUT, @op_Cookies NVARCHAR (MAX) NULL OUTPUT, @op_RawResponse NVARCHAR (MAX) NULL OUTPUT, @op_HTTPResponseCode INT NULL=NULL OUTPUT, @p_ContentType NVARCHAR (100) NULL=NULL, @p_Dataformat NVARCHAR (100) NULL=N'JSON', @p_Username NVARCHAR (1000) NULL=N'', @p_Password NVARCHAR (1000) NULL=N'', @p_Headers NVARCHAR (4000) NULL=N''
AS EXTERNAL NAME [iWebServices.CLR].[CLR.GlobalCLR].[splocal_iWebServices_CLR_RestAPI]


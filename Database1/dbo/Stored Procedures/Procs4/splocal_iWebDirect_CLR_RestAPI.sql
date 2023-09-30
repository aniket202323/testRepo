CREATE PROCEDURE [dbo].[splocal_iWebDirect_CLR_RestAPI]
@p_URL NVARCHAR (MAX) NULL, @p_Method NVARCHAR (100) NULL, @p_Payload NVARCHAR (MAX) NULL, @op_ReturnMessage NVARCHAR (MAX) NULL OUTPUT, @op_Cookies NVARCHAR (MAX) NULL OUTPUT, @op_HTTPResponseCode INT NULL=NULL OUTPUT, @p_ContentType NVARCHAR (100) NULL=NULL, @p_Dataformat NVARCHAR (100) NULL=N'JSON', @p_Username NVARCHAR (1000) NULL=N'', @p_Password NVARCHAR (1000) NULL=N''
AS EXTERNAL NAME [iWebDirect.CLR].[CLR.GlobalCLR].[splocal_iWebDirect_CLR_RestAPI]


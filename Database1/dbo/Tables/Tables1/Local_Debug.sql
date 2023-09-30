CREATE TABLE [dbo].[Local_Debug] (
    [Id]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [Timestamp]    DATETIME       NULL,
    [CallingSP]    VARCHAR (255)  NULL,
    [Message]      VARCHAR (2000) NULL,
    [Msg]          VARCHAR (500)  NULL,
    [LD_Timestamp] DATETIME       NULL,
    [SP_Name]      VARCHAR (250)  NULL,
    [SP_Param]     VARCHAR (250)  NULL,
    [SP_Text]      VARCHAR (5000) NULL
);


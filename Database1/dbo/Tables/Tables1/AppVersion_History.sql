CREATE TABLE [dbo].[AppVersion_History] (
    [AppVersion_History_Id]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [App_Id]                  INT           NULL,
    [App_Name]                VARCHAR (100) NULL,
    [App_Version]             VARCHAR (25)  NULL,
    [AppVersions_Modified_On] DATETIME      NULL,
    [App_ValidationKey]       VARCHAR (255) NULL,
    [Concurrent_Users]        VARCHAR (255) NULL,
    [Max_Prompt]              INT           NULL,
    [Min_Prompt]              INT           NULL,
    [Module_Check_Digit]      VARCHAR (255) NULL,
    [Module_Id]               TINYINT       NULL,
    [Modified_On]             DATETIME      NULL,
    [DBTT_Id]                 TINYINT       NULL,
    [Column_Updated_BitMask]  VARCHAR (15)  NULL,
    CONSTRAINT [AppVersion_History_PK_Id] PRIMARY KEY NONCLUSTERED ([AppVersion_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [AppVersionHistory_IX_AppIdModifiedOn]
    ON [dbo].[AppVersion_History]([App_Id] ASC, [Modified_On] ASC);


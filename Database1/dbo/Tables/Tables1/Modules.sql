CREATE TABLE [dbo].[Modules] (
    [Concurrent_Users]             VARCHAR (255)        NULL,
    [Configure_By_Number_Of_Users] INT                  NULL,
    [Installed_Version]            VARCHAR (25)         NULL,
    [Is_Enabled]                   TINYINT              NULL,
    [Min_Client_Version]           VARCHAR (25)         NULL,
    [Modified_On]                  DATETIME             NULL,
    [Module_Desc]                  [dbo].[Varchar_Desc] NOT NULL,
    [Module_Id]                    TINYINT              NOT NULL,
    [Validation_Key]               VARCHAR (255)        NULL,
    CONSTRAINT [Modules_PK] PRIMARY KEY NONCLUSTERED ([Module_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Modules_UC_Desc]
    ON [dbo].[Modules]([Module_Desc] ASC);


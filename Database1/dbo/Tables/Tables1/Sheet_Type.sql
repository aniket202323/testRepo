CREATE TABLE [dbo].[Sheet_Type] (
    [Sheet_Type_Id]   TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [App_Id]          INT                  NULL,
    [App_Version]     VARCHAR (10)         NULL,
    [Is_Active]       TINYINT              NULL,
    [Sheet_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    [Et_Id]           TINYINT              NULL,
    CONSTRAINT [SheetType_PK_ShtTypeId] PRIMARY KEY CLUSTERED ([Sheet_Type_Id] ASC),
    CONSTRAINT [Sheet_Type_FK_ETId] FOREIGN KEY ([Et_Id]) REFERENCES [dbo].[Event_Types] ([ET_Id]),
    CONSTRAINT [SheetType_FK_AppVersions] FOREIGN KEY ([App_Id]) REFERENCES [dbo].[AppVersions] ([App_Id]),
    CONSTRAINT [SheetType_UC_ShtTypeDesc] UNIQUE NONCLUSTERED ([Sheet_Type_Desc] ASC)
);


CREATE TABLE [dbo].[AppVersions] (
    [App_Id]             INT           NOT NULL,
    [App_Name]           VARCHAR (100) NOT NULL,
    [App_ValidationKey]  VARCHAR (255) NULL,
    [App_Version]        VARCHAR (25)  NOT NULL,
    [Concurrent_Users]   VARCHAR (255) NULL,
    [Max_Prompt]         INT           NULL,
    [Min_Prompt]         INT           NULL,
    [Modified_On]        DATETIME      CONSTRAINT [DF_AppVersions_Modified_On] DEFAULT (getdate()) NOT NULL,
    [Module_Check_Digit] VARCHAR (255) NULL,
    [Module_Id]          TINYINT       NULL,
    CONSTRAINT [AppVersions_PK_AppId] PRIMARY KEY CLUSTERED ([App_Id] ASC),
    CONSTRAINT [Appversions_FK_Modules] FOREIGN KEY ([Module_Id]) REFERENCES [dbo].[Modules] ([Module_Id])
);


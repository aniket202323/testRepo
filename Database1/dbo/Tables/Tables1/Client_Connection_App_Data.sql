CREATE TABLE [dbo].[Client_Connection_App_Data] (
    [App_Id]               INT          NOT NULL,
    [Client_Connection_Id] INT          NOT NULL,
    [Counter]              INT          CONSTRAINT [CliConnAD_DF_Counter] DEFAULT ((1)) NOT NULL,
    [Version]              VARCHAR (50) NOT NULL,
    CONSTRAINT [CliConnAppData_PK_CCIdAppId] PRIMARY KEY CLUSTERED ([Client_Connection_Id] ASC, [App_Id] ASC),
    CONSTRAINT [CliConnAD_AppId] FOREIGN KEY ([App_Id]) REFERENCES [dbo].[AppVersions] ([App_Id])
);


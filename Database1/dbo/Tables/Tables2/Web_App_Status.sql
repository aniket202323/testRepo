CREATE TABLE [dbo].[Web_App_Status] (
    [WAS_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [WAS_Code] VARCHAR (50)  NULL,
    [WAS_Desc] VARCHAR (255) NOT NULL,
    [WAT_Id]   INT           NOT NULL,
    CONSTRAINT [PK_Web_App_Status] PRIMARY KEY NONCLUSTERED ([WAS_Id] ASC),
    CONSTRAINT [WAS_WA] FOREIGN KEY ([WAT_Id]) REFERENCES [dbo].[Web_App_Types] ([WAT_Id])
);


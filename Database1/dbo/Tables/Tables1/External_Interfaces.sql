CREATE TABLE [dbo].[External_Interfaces] (
    [Interface_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]     INT          NULL,
    [Interface_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [ExtIntface_PK_InterfaceId] PRIMARY KEY CLUSTERED ([Interface_Id] ASC),
    CONSTRAINT [ExtIntface_UC_InterfaceDesc] UNIQUE NONCLUSTERED ([Interface_Desc] ASC)
);


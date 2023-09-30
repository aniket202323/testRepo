CREATE TABLE [dbo].[Linkable_Remote_Servers] (
    [Linked_Server_Id]         INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Linked_Server_Desc]       VARCHAR (25) NOT NULL,
    [Linked_Server_Desc_Alias] VARCHAR (35) NULL,
    [Linked_Server_IsLinked]   BIT          CONSTRAINT [LinkableRemoteServers_DF_LinkedServerIsLinked] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [LinkableRemoteServers_PK_LinkedServerId] PRIMARY KEY CLUSTERED ([Linked_Server_Id] ASC),
    CONSTRAINT [LinkableRemoteServers_UC_LinkedServerDesc] UNIQUE NONCLUSTERED ([Linked_Server_Desc] ASC)
);


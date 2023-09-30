CREATE TABLE [dbo].[CXS_Leaf] (
    [Buffer_To_Disk]   BIT                      NOT NULL,
    [Memory_List_Size] [dbo].[Smallint_Natural] NOT NULL,
    [Permenant]        BIT                      NOT NULL,
    [RG_Id]            SMALLINT                 NOT NULL,
    [Service_Id]       SMALLINT                 NOT NULL,
    CONSTRAINT [CXS_Leaf_PK_ServiceId] PRIMARY KEY CLUSTERED ([Service_Id] ASC, [RG_Id] ASC),
    CONSTRAINT [CXS_Leaf_FK_RGId] FOREIGN KEY ([RG_Id]) REFERENCES [dbo].[CXS_Route_Group] ([RG_Id]),
    CONSTRAINT [CXS_Leaf_FK_ServiceId] FOREIGN KEY ([Service_Id]) REFERENCES [dbo].[CXS_Service] ([Service_Id])
);


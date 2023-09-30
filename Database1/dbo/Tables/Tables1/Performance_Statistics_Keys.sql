CREATE TABLE [dbo].[Performance_Statistics_Keys] (
    [Key_Id]        INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Counter_Id]    INT          NULL,
    [Instance_Name] VARCHAR (50) NULL,
    [modified_on]   DATETIME     NULL,
    [Object_Id]     INT          NULL,
    [Service_Id]    INT          NULL,
    [Start_Time]    DATETIME     NULL,
    CONSTRAINT [PK_Performance_Statistics_Keys] PRIMARY KEY NONCLUSTERED ([Key_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Performance_Statistics_Keys_IDX_KeyId]
    ON [dbo].[Performance_Statistics_Keys]([Key_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Performance_Statistics_Keys_IDX_1]
    ON [dbo].[Performance_Statistics_Keys]([Service_Id] ASC, [Counter_Id] ASC, [Object_Id] ASC, [Instance_Name] ASC, [Start_Time] ASC);


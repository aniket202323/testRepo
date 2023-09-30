CREATE TABLE [dbo].[Performance_Statistics] (
    [Performance_Statistics_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Key_Id]                    INT          NULL,
    [Modified_On]               DATETIME     NULL,
    [Value]                     VARCHAR (20) NULL,
    CONSTRAINT [PK_Performance_Statistics] PRIMARY KEY NONCLUSTERED ([Performance_Statistics_Id] ASC),
    CONSTRAINT [Performance_Statistics_FK_KeyId] FOREIGN KEY ([Key_Id]) REFERENCES [dbo].[Performance_Statistics_Keys] ([Key_Id])
);

